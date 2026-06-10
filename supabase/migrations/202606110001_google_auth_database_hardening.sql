create extension if not exists "pgcrypto";

alter table public.profiles
  add column if not exists google_subject text,
  add column if not exists status text not null default 'active',
  add column if not exists deleted_at timestamptz,
  add column if not exists last_login_at timestamptz;

alter table public.profiles
  alter column tier set default 'bronze',
  alter column auth_provider set default 'google',
  alter column selected_fuel_league drop not null,
  alter column selected_vehicle_class drop not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_auth_provider_check'
  ) then
    alter table public.profiles
      add constraint profiles_auth_provider_check
      check (auth_provider in ('google', 'mock', 'admin_import')) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'profiles_status_check'
  ) then
    alter table public.profiles
      add constraint profiles_status_check
      check (status in ('active', 'suspended', 'deletion_requested', 'deleted')) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'profiles_tier_check'
  ) then
    alter table public.profiles
      add constraint profiles_tier_check
      check (
        tier ~* '^(bronze|silver|gold|platinum|diamond|master)(\s+(i|ii|iii))?$'
      ) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'profiles_nickname_length_check'
  ) then
    alter table public.profiles
      add constraint profiles_nickname_length_check
      check (char_length(btrim(nickname)) between 2 and 16) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'profiles_score_non_negative_check'
  ) then
    alter table public.profiles
      add constraint profiles_score_non_negative_check
      check (
        total_score >= 0
        and season_score >= 0
        and current_streak >= 0
        and best_streak >= 0
      ) not valid;
  end if;
end;
$$;

create or replace function public.profile_nickname_from_metadata(
  p_metadata jsonb,
  p_email text
)
returns text
language sql
immutable
as $$
  with raw_value as (
    select coalesce(
      nullif(btrim(p_metadata->>'name'), ''),
      nullif(btrim(p_metadata->>'full_name'), ''),
      nullif(btrim(p_metadata->>'display_name'), ''),
      nullif(btrim(p_metadata->>'preferred_username'), ''),
      nullif(btrim(split_part(coalesce(p_email, p_metadata->>'email', ''), '@', 1)), ''),
      'Fuel Driver'
    ) as value
  )
  select case
    when char_length(value) < 2 then 'Fuel Driver'
    when char_length(value) > 16 then left(value, 16)
    else value
  end
  from raw_value;
$$;

create or replace function public.profile_avatar_from_metadata(p_metadata jsonb)
returns text
language sql
immutable
as $$
  select nullif(coalesce(
    nullif(btrim(p_metadata->>'avatar_url'), ''),
    nullif(btrim(p_metadata->>'picture'), '')
  ), '');
$$;

create or replace function public.profile_google_subject_from_metadata(
  p_metadata jsonb
)
returns text
language sql
immutable
as $$
  select nullif(coalesce(
    nullif(btrim(p_metadata->>'sub'), ''),
    nullif(btrim(p_metadata->>'provider_id'), ''),
    nullif(btrim(p_metadata->>'user_id'), '')
  ), '');
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(auth.jwt()->'app_metadata'->>'role', '') = 'admin'
    or coalesce(auth.jwt()->'user_metadata'->>'role', '') = 'admin'
    or exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.is_admin = true
        and p.status = 'active'
    );
$$;

create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select case
    when auth.uid() is null then 'anonymous'
    when public.is_admin() then 'admin'
    when exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.is_premium = true
        and p.status = 'active'
    ) then 'premium'
    else 'authenticated'
  end;
$$;

create or replace function public.upsert_auth_user_profile(
  p_user_id uuid,
  p_email text,
  p_metadata jsonb,
  p_provider text default 'google'
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := nullif(btrim(coalesce(p_email, p_metadata->>'email', '')), '');
  v_nickname text := public.profile_nickname_from_metadata(p_metadata, p_email);
  v_avatar_url text := public.profile_avatar_from_metadata(p_metadata);
  v_google_subject text := public.profile_google_subject_from_metadata(p_metadata);
  v_provider text := case
    when p_provider in ('google', 'mock', 'admin_import') then p_provider
    else 'google'
  end;
  v_profile public.profiles;
begin
  perform set_config('app.profile_protected_update', 'on', true);

  insert into public.profiles (
    id,
    email,
    nickname,
    avatar_url,
    auth_provider,
    google_subject,
    status,
    last_login_at,
    updated_at
  )
  values (
    p_user_id,
    v_email,
    v_nickname,
    v_avatar_url,
    v_provider,
    v_google_subject,
    'active',
    now(),
    now()
  )
  on conflict (id) do update
    set email = coalesce(excluded.email, public.profiles.email),
        avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url),
        google_subject = coalesce(excluded.google_subject, public.profiles.google_subject),
        auth_provider = case
          when public.profiles.auth_provider in ('google', 'mock', 'admin_import')
            then public.profiles.auth_provider
          else excluded.auth_provider
        end,
        nickname = case
          when btrim(coalesce(public.profiles.nickname, '')) = ''
            then excluded.nickname
          else public.profiles.nickname
        end,
        status = case
          when public.profiles.status = 'deleted' then public.profiles.status
          else 'active'
        end,
        last_login_at = now(),
        updated_at = now()
  returning * into v_profile;

  insert into public.auth_audit_logs (
    user_id,
    event_type,
    provider,
    metadata
  )
  values (
    p_user_id,
    'profile_bootstrapped',
    v_provider,
    jsonb_build_object('source', 'auth.users trigger')
  )
  on conflict do nothing;

  return v_profile;
end;
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.upsert_auth_user_profile(
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data, '{}'::jsonb),
    coalesce(new.raw_app_meta_data->>'provider', 'google')
  );
  return new;
end;
$$;

create or replace function public.handle_new_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.upsert_auth_user_profile(
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data, '{}'::jsonb),
    coalesce(new.raw_app_meta_data->>'provider', 'google')
  );
  return new;
end;
$$;

create or replace function public.handle_auth_user_login_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.upsert_auth_user_profile(
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data, '{}'::jsonb),
    coalesce(new.raw_app_meta_data->>'provider', 'google')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

drop trigger if exists on_auth_user_login_updated on auth.users;
create trigger on_auth_user_login_updated
  after update of last_sign_in_at, raw_user_meta_data on auth.users
  for each row
  when (
    old.last_sign_in_at is distinct from new.last_sign_in_at
    or old.raw_user_meta_data is distinct from new.raw_user_meta_data
  )
  execute function public.handle_auth_user_login_update();

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending',
  reason text,
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  processed_by uuid references public.profiles(id) on delete set null,
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint account_deletion_requests_status_check
    check (status in ('pending', 'processing', 'completed', 'rejected', 'canceled'))
);

create table if not exists public.data_export_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending',
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  processed_by uuid references public.profiles(id) on delete set null,
  download_url text,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint data_export_requests_status_check
    check (status in ('pending', 'processing', 'completed', 'rejected', 'canceled'))
);

create table if not exists public.auth_audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  event_type text not null,
  provider text,
  environment text,
  platform text,
  app_version text,
  ip_hash text,
  user_agent text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  constraint auth_audit_logs_event_type_check
    check (event_type in (
      'google_login_succeeded',
      'google_login_failed',
      'profile_bootstrapped',
      'session_restored',
      'sign_out',
      'account_deletion_requested',
      'data_export_requested',
      'consent_completed',
      'consent_revoked'
    )),
  constraint auth_audit_logs_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table if not exists public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid references public.profiles(id) on delete set null,
  action text not null,
  target_table text,
  target_id text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  constraint admin_audit_logs_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

alter table public.consent_logs
  add column if not exists consent_type text not null default 'terms_of_service',
  add column if not exists consent_version text not null default 'legacy',
  add column if not exists accepted boolean not null default true,
  add column if not exists accepted_at timestamptz not null default now(),
  add column if not exists revoked_at timestamptz,
  add column if not exists ip_hash text,
  add column if not exists user_agent text,
  add column if not exists app_version text,
  add column if not exists platform text;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'consent_logs_type_check'
  ) then
    alter table public.consent_logs
      add constraint consent_logs_type_check
      check (consent_type in (
        'terms_of_service',
        'privacy_policy',
        'location_policy',
        'driving_data_collection',
        'vehicle_data_collection',
        'ad_personalization',
        'marketing',
        'sponsor_benefits'
      )) not valid;
  end if;
end;
$$;

create index if not exists profiles_google_subject_idx
  on public.profiles (google_subject)
  where google_subject is not null;

create index if not exists account_deletion_requests_user_requested_idx
  on public.account_deletion_requests (user_id, requested_at desc);

create unique index if not exists account_deletion_requests_active_uidx
  on public.account_deletion_requests (user_id)
  where status in ('pending', 'processing');

create index if not exists data_export_requests_user_requested_idx
  on public.data_export_requests (user_id, requested_at desc);

create unique index if not exists data_export_requests_active_uidx
  on public.data_export_requests (user_id)
  where status in ('pending', 'processing');

create index if not exists auth_audit_logs_user_created_idx
  on public.auth_audit_logs (user_id, created_at desc);

create index if not exists auth_audit_logs_event_created_idx
  on public.auth_audit_logs (event_type, created_at desc);

create index if not exists admin_audit_logs_admin_created_idx
  on public.admin_audit_logs (admin_user_id, created_at desc);

do $$
declare
  target_table text;
begin
  foreach target_table in array array[
    'profiles',
    'vehicles',
    'user_vehicles',
    'league_memberships',
    'support_tickets',
    'app_settings',
    'custom_vehicle_requests',
    'account_deletion_requests',
    'data_export_requests'
  ]
  loop
    if exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = target_table
        and column_name = 'updated_at'
    ) then
      execute format(
        'drop trigger if exists set_%I_updated_at on public.%I',
        target_table,
        target_table
      );
      execute format(
        'create trigger set_%I_updated_at before update on public.%I for each row execute function public.set_updated_at()',
        target_table,
        target_table
      );
    end if;
  end loop;
end;
$$;

create or replace function public.prevent_profile_protected_field_update()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_setting('app.profile_protected_update', true) = 'on'
     or auth.role() = 'service_role'
     or public.is_admin() then
    return new;
  end if;

  if old.id is distinct from new.id
    or old.email is distinct from new.email
    or old.auth_provider is distinct from new.auth_provider
    or old.google_subject is distinct from new.google_subject
    or old.is_admin is distinct from new.is_admin
    or old.is_premium is distinct from new.is_premium
    or old.tier is distinct from new.tier
    or old.total_score is distinct from new.total_score
    or old.season_score is distinct from new.season_score
    or old.current_streak is distinct from new.current_streak
    or old.best_streak is distinct from new.best_streak
    or old.representative_vehicle_id is distinct from new.representative_vehicle_id
    or old.selected_fuel_league is distinct from new.selected_fuel_league
    or old.selected_vehicle_class is distinct from new.selected_vehicle_class
    or old.status is distinct from new.status
    or old.deleted_at is distinct from new.deleted_at
    or old.consent_completed is distinct from new.consent_completed
    or old.last_login_at is distinct from new.last_login_at then
    raise exception 'profile protected fields can be changed only by secure RPC, admin, or service role'
      using errcode = '42501';
  end if;

  new.nickname = public.profile_nickname_from_metadata(
    jsonb_build_object('name', new.nickname),
    new.email
  );
  return new;
end;
$$;

drop trigger if exists prevent_profile_protected_field_update on public.profiles;
create trigger prevent_profile_protected_field_update
  before update on public.profiles
  for each row execute function public.prevent_profile_protected_field_update();

create or replace function public.ensure_my_profile()
returns public.profiles
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user auth.users;
  v_profile public.profiles;
begin
  if auth.uid() is null then
    raise exception 'login required' using errcode = '28000';
  end if;

  select * into v_user
  from auth.users
  where id = auth.uid();

  if not found then
    raise exception 'auth user not found' using errcode = '28000';
  end if;

  v_profile := public.upsert_auth_user_profile(
    v_user.id,
    v_user.email,
    coalesce(v_user.raw_user_meta_data, '{}'::jsonb),
    coalesce(v_user.raw_app_meta_data->>'provider', 'google')
  );

  return v_profile;
end;
$$;

create or replace function public.update_my_profile(
  p_nickname text,
  p_avatar_url text default null
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nickname text := public.profile_nickname_from_metadata(
    jsonb_build_object('name', p_nickname),
    null
  );
  v_profile public.profiles;
begin
  if auth.uid() is null then
    raise exception 'login required' using errcode = '28000';
  end if;

  update public.profiles
  set nickname = v_nickname,
      avatar_url = nullif(btrim(coalesce(p_avatar_url, '')), ''),
      updated_at = now()
  where id = auth.uid()
  returning * into v_profile;

  if v_profile.id is null then
    raise exception 'profile not found' using errcode = 'P0002';
  end if;

  return v_profile;
end;
$$;

create or replace function public.set_my_profile_vehicle(
  p_vehicle_id uuid
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_vehicle_name text;
  v_fuel_league text;
  v_vehicle_class text;
  v_profile public.profiles;
begin
  if v_user_id is null then
    raise exception 'login required' using errcode = '28000';
  end if;

  perform set_config('app.profile_protected_update', 'on', true);

  if p_vehicle_id is null then
    update public.profiles
    set representative_vehicle_id = null,
        representative_vehicle_name = '',
        selected_fuel_league = null,
        selected_vehicle_class = null,
        vehicle_setup_completed = false,
        updated_at = now()
    where id = v_user_id
    returning * into v_profile;
    return v_profile;
  end if;

  select
    btrim(concat_ws(' ', nullif(v.manufacturer, ''), nullif(v.model_name, ''), v.model_year::text)),
    v.fuel_league,
    v.vehicle_class
  into v_vehicle_name, v_fuel_league, v_vehicle_class
  from public.vehicles v
  where v.id = p_vehicle_id
    and v.user_id = v_user_id;

  if v_vehicle_name is null then
    select
      coalesce(
        nullif(uv.nickname, ''),
        btrim(concat_ws(' ', vc.manufacturer_name, vc.model_name, vc.year::text)),
        '대표 차량'
      ),
      uv.fuel_league,
      uv.vehicle_class
    into v_vehicle_name, v_fuel_league, v_vehicle_class
    from public.user_vehicles uv
    left join public.vehicle_catalog_view vc on vc.id = uv.vehicle_variant_id
    where uv.id = p_vehicle_id
      and uv.user_id = v_user_id;
  end if;

  if v_vehicle_name is null then
    raise exception 'owned vehicle not found' using errcode = 'P0002';
  end if;

  update public.profiles
  set representative_vehicle_id = p_vehicle_id,
      representative_vehicle_name = v_vehicle_name,
      selected_fuel_league = v_fuel_league,
      selected_vehicle_class = v_vehicle_class,
      vehicle_setup_completed = true,
      additional_setup_completed = true,
      updated_at = now()
  where id = v_user_id
  returning * into v_profile;

  return v_profile;
end;
$$;

create or replace function public.record_auth_event(
  p_event_type text,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb)
    - array[
      'token',
      'idToken',
      'id_token',
      'accessToken',
      'access_token',
      'refreshToken',
      'refresh_token',
      'authorization',
      'client_secret',
      'oauth_client_secret',
      'email'
    ];
  v_id uuid;
begin
  if jsonb_typeof(v_metadata) <> 'object' then
    v_metadata := '{}'::jsonb;
  end if;

  insert into public.auth_audit_logs (
    user_id,
    event_type,
    provider,
    environment,
    platform,
    app_version,
    ip_hash,
    user_agent,
    metadata
  )
  values (
    auth.uid(),
    p_event_type,
    nullif(v_metadata->>'provider', ''),
    nullif(v_metadata->>'environment', ''),
    nullif(v_metadata->>'platform', ''),
    nullif(v_metadata->>'app_version', ''),
    nullif(v_metadata->>'ip_hash', ''),
    nullif(v_metadata->>'user_agent', ''),
    v_metadata
  )
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.record_my_consent(
  p_payload jsonb
)
returns public.app_consents
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_terms boolean := coalesce((p_payload->>'terms_accepted')::boolean, false);
  v_privacy boolean := coalesce((p_payload->>'privacy_accepted')::boolean, false);
  v_location boolean := coalesce((p_payload->>'location_accepted')::boolean, false);
  v_ads boolean := coalesce((p_payload->>'personalized_ads_accepted')::boolean, false);
  v_marketing boolean := coalesce((p_payload->>'marketing_accepted')::boolean, false);
  v_terms_version text := coalesce(nullif(p_payload->>'terms_version', ''), 'current');
  v_privacy_version text := coalesce(nullif(p_payload->>'privacy_version', ''), 'current');
  v_location_version text := coalesce(nullif(p_payload->>'location_version', ''), 'current');
  v_ads_version text := coalesce(nullif(p_payload->>'ads_version', ''), 'current');
  v_marketing_version text := coalesce(nullif(p_payload->>'marketing_version', ''), 'current');
  v_app_version text := nullif(p_payload->>'app_version', '');
  v_platform text := nullif(p_payload->>'platform', '');
  v_user_agent text := nullif(p_payload->>'user_agent', '');
  v_ip_hash text := nullif(p_payload->>'ip_hash', '');
  v_consent public.app_consents;
begin
  if v_user_id is null then
    raise exception 'login required' using errcode = '28000';
  end if;

  insert into public.app_consents (
    user_id,
    terms_accepted,
    privacy_accepted,
    location_accepted,
    personalized_ads_accepted,
    marketing_accepted,
    updated_at
  )
  values (
    v_user_id,
    v_terms,
    v_privacy,
    v_location,
    v_ads,
    v_marketing,
    now()
  )
  on conflict (user_id) do update
    set terms_accepted = excluded.terms_accepted,
        privacy_accepted = excluded.privacy_accepted,
        location_accepted = excluded.location_accepted,
        personalized_ads_accepted = excluded.personalized_ads_accepted,
        marketing_accepted = excluded.marketing_accepted,
        updated_at = now()
  returning * into v_consent;

  insert into public.consent_logs (
    user_id,
    consent_type,
    consent_version,
    accepted,
    accepted_at,
    ip_hash,
    user_agent,
    app_version,
    platform,
    terms_accepted,
    privacy_accepted,
    location_accepted,
    personalized_ads_accepted,
    marketing_accepted
  )
  values
    (v_user_id, 'terms_of_service', v_terms_version, v_terms, now(), v_ip_hash, v_user_agent, v_app_version, v_platform, v_terms, v_privacy, v_location, v_ads, v_marketing),
    (v_user_id, 'privacy_policy', v_privacy_version, v_privacy, now(), v_ip_hash, v_user_agent, v_app_version, v_platform, v_terms, v_privacy, v_location, v_ads, v_marketing),
    (v_user_id, 'location_policy', v_location_version, v_location, now(), v_ip_hash, v_user_agent, v_app_version, v_platform, v_terms, v_privacy, v_location, v_ads, v_marketing),
    (v_user_id, 'ad_personalization', v_ads_version, v_ads, now(), v_ip_hash, v_user_agent, v_app_version, v_platform, v_terms, v_privacy, v_location, v_ads, v_marketing),
    (v_user_id, 'marketing', v_marketing_version, v_marketing, now(), v_ip_hash, v_user_agent, v_app_version, v_platform, v_terms, v_privacy, v_location, v_ads, v_marketing);

  perform set_config('app.profile_protected_update', 'on', true);
  update public.profiles
  set consent_completed = (v_terms and v_privacy and v_location),
      updated_at = now()
  where id = v_user_id;

  perform public.record_auth_event(
    case
      when v_terms and v_privacy and v_location then 'consent_completed'
      else 'consent_revoked'
    end,
    jsonb_build_object('source', 'record_my_consent')
  );

  return v_consent;
end;
$$;

create or replace function public.revoke_my_consent(
  p_consent_type text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'login required' using errcode = '28000';
  end if;

  if p_consent_type not in (
    'terms_of_service',
    'privacy_policy',
    'location_policy',
    'driving_data_collection',
    'vehicle_data_collection',
    'ad_personalization',
    'marketing',
    'sponsor_benefits'
  ) then
    raise exception 'unsupported consent type' using errcode = '22023';
  end if;

  insert into public.consent_logs (
    user_id,
    consent_type,
    consent_version,
    accepted,
    revoked_at
  )
  values (
    v_user_id,
    p_consent_type,
    'current',
    false,
    now()
  );

  if p_consent_type in ('terms_of_service', 'privacy_policy', 'location_policy') then
    perform set_config('app.profile_protected_update', 'on', true);
    update public.profiles
    set consent_completed = false,
        updated_at = now()
    where id = v_user_id;
  end if;

  perform public.record_auth_event(
    'consent_revoked',
    jsonb_build_object('consent_type', p_consent_type)
  );
end;
$$;

create or replace function public.request_account_deletion(
  p_reason text default null
)
returns public.account_deletion_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_request public.account_deletion_requests;
begin
  if v_user_id is null then
    raise exception 'login required' using errcode = '28000';
  end if;

  select * into v_request
  from public.account_deletion_requests
  where user_id = v_user_id
    and status in ('pending', 'processing')
  order by requested_at desc
  limit 1;

  if v_request.id is null then
    insert into public.account_deletion_requests (
      user_id,
      reason
    )
    values (
      v_user_id,
      nullif(btrim(coalesce(p_reason, '')), '')
    )
    returning * into v_request;
  end if;

  insert into public.privacy_requests (
    user_id,
    request_type,
    description,
    status
  )
  select
    v_user_id,
    'account_deletion',
    coalesce(nullif(btrim(coalesce(p_reason, '')), ''), 'Fuel Arena 계정 삭제와 탈퇴 처리를 요청합니다.'),
    'open'
  where not exists (
    select 1
    from public.privacy_requests pr
    where pr.user_id = v_user_id
      and pr.request_type = 'account_deletion'
      and pr.status in ('open', 'review')
  );

  perform set_config('app.profile_protected_update', 'on', true);
  update public.profiles
  set status = 'deletion_requested',
      updated_at = now()
  where id = v_user_id
    and status <> 'deleted';

  perform public.record_auth_event(
    'account_deletion_requested',
    jsonb_build_object('source', 'request_account_deletion')
  );

  return v_request;
end;
$$;

create or replace function public.request_data_export()
returns public.data_export_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_request public.data_export_requests;
begin
  if v_user_id is null then
    raise exception 'login required' using errcode = '28000';
  end if;

  select * into v_request
  from public.data_export_requests
  where user_id = v_user_id
    and status in ('pending', 'processing')
  order by requested_at desc
  limit 1;

  if v_request.id is null then
    insert into public.data_export_requests (user_id)
    values (v_user_id)
    returning * into v_request;
  end if;

  insert into public.privacy_requests (
    user_id,
    request_type,
    description,
    status
  )
  select
    v_user_id,
    'data_download',
    'Fuel Arena 데이터 내보내기를 요청합니다.',
    'open'
  where not exists (
    select 1
    from public.privacy_requests pr
    where pr.user_id = v_user_id
      and pr.request_type = 'data_download'
      and pr.status in ('open', 'review')
  );

  perform public.record_auth_event(
    'data_export_requested',
    jsonb_build_object('source', 'request_data_export')
  );

  return v_request;
end;
$$;

create or replace function public.get_my_auth_state()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.profiles;
  v_consent public.app_consents;
begin
  if auth.uid() is null then
    return jsonb_build_object('authenticated', false);
  end if;

  v_profile := public.ensure_my_profile();

  select * into v_consent
  from public.app_consents
  where user_id = auth.uid();

  return jsonb_build_object(
    'authenticated', true,
    'profile', to_jsonb(v_profile) - array['email', 'google_subject', 'deleted_at'],
    'consent', coalesce(to_jsonb(v_consent), '{}'::jsonb),
    'role', public.current_user_role()
  );
end;
$$;

alter table public.account_deletion_requests enable row level security;
alter table public.data_export_requests enable row level security;
alter table public.auth_audit_logs enable row level security;
alter table public.admin_audit_logs enable row level security;

drop policy if exists "profiles_select_self" on public.profiles;
create policy "profiles_select_self" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "profiles_admin_select" on public.profiles;
create policy "profiles_admin_select" on public.profiles
  for select using (public.is_admin());

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "profiles_admin_update" on public.profiles;
create policy "profiles_admin_update" on public.profiles
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self" on public.profiles
  for insert with check (
    auth.uid() = id
    and coalesce(is_admin, false) = false
    and coalesce(is_premium, false) = false
    and coalesce(total_score, 0) = 0
    and coalesce(season_score, 0) = 0
    and coalesce(current_streak, 0) = 0
    and coalesce(best_streak, 0) = 0
    and coalesce(status, 'active') = 'active'
    and coalesce(nullif(tier, ''), 'bronze') ~* '^(bronze|bronze i)$'
  );

drop policy if exists "consent_logs_self_insert" on public.consent_logs;
create policy "consent_logs_self_insert" on public.consent_logs
  for insert with check (auth.uid() = user_id);

drop policy if exists "consent_logs_self_select_or_admin" on public.consent_logs;
create policy "consent_logs_self_select_or_admin" on public.consent_logs
  for select using (auth.uid() = user_id or public.is_admin());

drop policy if exists "account_deletion_requests_self_select" on public.account_deletion_requests;
create policy "account_deletion_requests_self_select" on public.account_deletion_requests
  for select using (auth.uid() = user_id);

drop policy if exists "account_deletion_requests_self_insert" on public.account_deletion_requests;
create policy "account_deletion_requests_self_insert" on public.account_deletion_requests
  for insert with check (
    auth.uid() = user_id
    and status = 'pending'
    and processed_at is null
    and processed_by is null
  );

drop policy if exists "account_deletion_requests_admin_select" on public.account_deletion_requests;
create policy "account_deletion_requests_admin_select" on public.account_deletion_requests
  for select using (public.is_admin());

drop policy if exists "account_deletion_requests_admin_update" on public.account_deletion_requests;
create policy "account_deletion_requests_admin_update" on public.account_deletion_requests
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "data_export_requests_self_select" on public.data_export_requests;
create policy "data_export_requests_self_select" on public.data_export_requests
  for select using (auth.uid() = user_id);

drop policy if exists "data_export_requests_self_insert" on public.data_export_requests;
create policy "data_export_requests_self_insert" on public.data_export_requests
  for insert with check (
    auth.uid() = user_id
    and status = 'pending'
    and processed_at is null
    and processed_by is null
  );

drop policy if exists "data_export_requests_admin_select" on public.data_export_requests;
create policy "data_export_requests_admin_select" on public.data_export_requests
  for select using (public.is_admin());

drop policy if exists "data_export_requests_admin_update" on public.data_export_requests;
create policy "data_export_requests_admin_update" on public.data_export_requests
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "auth_audit_logs_self_select" on public.auth_audit_logs;
create policy "auth_audit_logs_self_select" on public.auth_audit_logs
  for select using (auth.uid() = user_id);

drop policy if exists "auth_audit_logs_admin_select" on public.auth_audit_logs;
create policy "auth_audit_logs_admin_select" on public.auth_audit_logs
  for select using (public.is_admin());

drop policy if exists "admin_audit_logs_admin_select" on public.admin_audit_logs;
create policy "admin_audit_logs_admin_select" on public.admin_audit_logs
  for select using (public.is_admin());

drop policy if exists "admin_audit_logs_admin_insert" on public.admin_audit_logs;
create policy "admin_audit_logs_admin_insert" on public.admin_audit_logs
  for insert with check (public.is_admin() and auth.uid() = admin_user_id);

create or replace view public.public_profiles_view as
select
  left(replace(p.id::text, '-', ''), 12) as public_id,
  p.nickname,
  p.avatar_url,
  p.tier,
  p.is_premium,
  p.representative_vehicle_name as representative_vehicle_summary,
  p.selected_fuel_league,
  p.selected_vehicle_class
from public.profiles p
where p.status = 'active';

create or replace view public.public_rankings_view as
select
  r.id as ranking_id,
  left(replace(p.id::text, '-', ''), 12) as public_user_id,
  p.nickname,
  p.avatar_url,
  p.tier,
  r.score,
  r.rank,
  r.previous_rank,
  r.fuel_league,
  r.vehicle_class,
  null::text as season_id,
  r.percentile
from public.rankings r
join public.profiles p on p.id = r.user_id
where p.status = 'active';

create or replace view public.public_user_primary_vehicle_view as
select
  left(replace(uv.user_id::text, '-', ''), 12) as public_user_id,
  vc.manufacturer_name,
  vc.model_name,
  vc.year as model_year,
  uv.fuel_league,
  uv.vehicle_class,
  uv.verification_status
from public.user_vehicles uv
left join public.vehicle_catalog_view vc on vc.id = uv.vehicle_variant_id
where uv.is_primary = true;

revoke insert on public.profiles from anon, authenticated;
revoke update on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant insert (
  id,
  nickname,
  avatar_url,
  onboarding_completed,
  additional_setup_completed,
  vehicle_setup_completed,
  updated_at
) on public.profiles to authenticated;
grant update (
  nickname,
  avatar_url,
  onboarding_completed,
  additional_setup_completed,
  vehicle_setup_completed,
  updated_at
) on public.profiles to authenticated;

grant select, insert on public.consent_logs to authenticated;
revoke update, delete on public.consent_logs from anon, authenticated;

grant select, insert, update on public.account_deletion_requests to authenticated;
grant select, insert, update on public.data_export_requests to authenticated;
grant select on public.auth_audit_logs to authenticated;
revoke insert, update, delete on public.auth_audit_logs from anon, authenticated;
grant select, insert on public.admin_audit_logs to authenticated;
revoke update, delete on public.admin_audit_logs from anon, authenticated;

grant select on public.public_profiles_view to anon, authenticated;
grant select on public.public_rankings_view to anon, authenticated;
grant select on public.public_user_primary_vehicle_view to anon, authenticated;

revoke all on function public.ensure_my_profile() from public;
revoke all on function public.update_my_profile(text, text) from public;
revoke all on function public.set_my_profile_vehicle(uuid) from public;
revoke all on function public.record_my_consent(jsonb) from public;
revoke all on function public.revoke_my_consent(text) from public;
revoke all on function public.request_account_deletion(text) from public;
revoke all on function public.request_data_export() from public;
revoke all on function public.record_auth_event(text, jsonb) from public;
revoke all on function public.get_my_auth_state() from public;

grant execute on function public.is_admin() to anon, authenticated;
grant execute on function public.current_user_role() to anon, authenticated;
grant execute on function public.ensure_my_profile() to authenticated;
grant execute on function public.update_my_profile(text, text) to authenticated;
grant execute on function public.set_my_profile_vehicle(uuid) to authenticated;
grant execute on function public.record_my_consent(jsonb) to authenticated;
grant execute on function public.revoke_my_consent(text) to authenticated;
grant execute on function public.request_account_deletion(text) to authenticated;
grant execute on function public.request_data_export() to authenticated;
grant execute on function public.record_auth_event(text, jsonb) to authenticated;
grant execute on function public.get_my_auth_state() to authenticated;

insert into public.fuel_leagues (
  key,
  name_ko,
  description,
  fuel_type,
  is_active,
  sort_order
)
values
  ('gasoline', '가솔린', '가솔린 차량 리그', 'gasoline', true, 10),
  ('diesel', '디젤', '디젤 차량 리그', 'diesel', true, 20),
  ('hybrid', '하이브리드', '하이브리드 차량 리그', 'hybrid', true, 30),
  ('plug_in_hybrid', '플러그인 하이브리드', 'PHEV 차량 리그', 'plug_in_hybrid', true, 40),
  ('electric', '전기차', '전기차 리그', 'electric', true, 50),
  ('lpg', 'LPG', 'LPG/LPI 차량 리그', 'lpg', true, 60),
  ('hydrogen', '수소전기', '수소전기차 리그', 'hydrogen', true, 70),
  ('other', '기타', '기타 연료 리그', 'other', true, 90)
on conflict (key) do update
  set name_ko = excluded.name_ko,
      description = excluded.description,
      fuel_type = excluded.fuel_type,
      is_active = excluded.is_active,
      sort_order = excluded.sort_order;

insert into public.app_settings (
  key,
  value,
  description,
  is_public
)
values
  ('required_terms_version', '{"version":"2026.06"}', 'Required Terms of Service version for consent completion.', true),
  ('required_privacy_version', '{"version":"2026.06"}', 'Required Privacy Policy version for consent completion.', true),
  ('required_location_version', '{"version":"2026.06"}', 'Required Location Policy version for consent completion.', true),
  ('google_auth_enabled', '{"enabled":true}', 'Enable Google-only Supabase Auth login.', true),
  ('mock_auth_allowed_dev_only', '{"enabled":true}', 'Mock auth is allowed only in dev builds without production OAuth settings.', false),
  ('account_deletion_enabled', '{"enabled":true}', 'Enable user account deletion request queue.', true),
  ('data_export_enabled', '{"enabled":true}', 'Enable user data export request queue.', true)
on conflict (key) do update
  set value = excluded.value,
      description = excluded.description,
      is_public = excluded.is_public,
      updated_at = now();

comment on table public.account_deletion_requests is
  'Dedicated account deletion queue. Users create their own pending request; admins or Edge Functions process it.';
comment on table public.data_export_requests is
  'Dedicated data export queue. Users create their own pending request; admins or Edge Functions publish an expiring download URL.';
comment on table public.auth_audit_logs is
  'Authentication and privacy-event audit log. Tokens, OAuth secrets, refresh tokens, and full email values must not be stored in metadata.';
comment on table public.admin_audit_logs is
  'Admin-only audit log for catalog, moderation, privacy, and settings actions.';
comment on function public.handle_new_auth_user() is
  'Bootstraps public.profiles from auth.users after Google Supabase Auth creates a user.';
comment on function public.ensure_my_profile() is
  'Repairs or refreshes the current authenticated user profile and last_login_at.';
comment on function public.prevent_profile_protected_field_update() is
  'Blocks authenticated clients from directly changing protected profile fields; secure RPCs set a transaction-local bypass.';
comment on view public.public_profiles_view is
  'Safe public profile projection with no email, google subject, admin flag, status, last_login_at, or deleted_at.';
comment on view public.public_rankings_view is
  'Safe public ranking projection with no email, raw route, drive_points, or full private profile fields.';
