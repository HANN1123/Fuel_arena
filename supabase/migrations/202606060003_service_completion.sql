create or replace function public.is_admin_user()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and is_admin = true
  );
$$;

alter table public.notifications
  add column if not exists notification_type text not null default 'general',
  add column if not exists target_route text,
  add column if not exists held_during_drive boolean not null default false;

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category text not null,
  title text not null,
  description text not null,
  status text not null default 'open',
  priority text not null default 'normal',
  related_user_id uuid references public.profiles(id) on delete set null,
  related_drive_session_id uuid references public.drive_sessions(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.support_ticket_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  sender_id uuid references public.profiles(id) on delete set null,
  message text not null,
  is_admin_reply boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null default '{}',
  description text not null default '',
  is_public boolean not null default false,
  updated_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);

create table if not exists public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  event_name text not null,
  properties jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.user_local_sync_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  item_type text not null,
  item_id text not null,
  sync_status text not null default 'pending',
  error_message text,
  created_at timestamptz not null default now(),
  synced_at timestamptz
);

create table if not exists public.vehicle_catalog_change_logs (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid references public.profiles(id) on delete set null,
  entity_type text not null,
  entity_id text not null,
  action text not null,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.consent_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  terms_accepted boolean not null default false,
  privacy_accepted boolean not null default false,
  location_accepted boolean not null default false,
  personalized_ads_accepted boolean not null default false,
  marketing_accepted boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.app_release_notes (
  id uuid primary key default gen_random_uuid(),
  version text not null,
  title text not null,
  body text not null,
  is_public boolean not null default false,
  published_at timestamptz
);

create index if not exists support_tickets_user_id_created_at_idx
  on public.support_tickets (user_id, created_at desc);

create index if not exists support_ticket_messages_ticket_id_created_at_idx
  on public.support_ticket_messages (ticket_id, created_at);

create index if not exists analytics_events_event_name_created_at_idx
  on public.analytics_events (event_name, created_at desc);

create index if not exists user_local_sync_logs_user_status_idx
  on public.user_local_sync_logs (user_id, sync_status);

alter table public.support_tickets enable row level security;
alter table public.support_ticket_messages enable row level security;
alter table public.app_settings enable row level security;
alter table public.analytics_events enable row level security;
alter table public.user_local_sync_logs enable row level security;
alter table public.vehicle_catalog_change_logs enable row level security;
alter table public.consent_logs enable row level security;
alter table public.app_release_notes enable row level security;

drop policy if exists "support_tickets_self_select_or_admin" on public.support_tickets;
create policy "support_tickets_self_select_or_admin" on public.support_tickets
  for select using (auth.uid() = user_id or public.is_admin_user());

drop policy if exists "support_tickets_self_insert" on public.support_tickets;
create policy "support_tickets_self_insert" on public.support_tickets
  for insert with check (auth.uid() = user_id);

drop policy if exists "support_tickets_self_update_or_admin" on public.support_tickets;
create policy "support_tickets_self_update_or_admin" on public.support_tickets
  for update using (auth.uid() = user_id or public.is_admin_user())
  with check (auth.uid() = user_id or public.is_admin_user());

drop policy if exists "support_messages_ticket_participant_select" on public.support_ticket_messages;
create policy "support_messages_ticket_participant_select" on public.support_ticket_messages
  for select using (
    public.is_admin_user()
    or exists (
      select 1 from public.support_tickets t
      where t.id = ticket_id
        and t.user_id = auth.uid()
    )
  );

drop policy if exists "support_messages_ticket_participant_insert" on public.support_ticket_messages;
create policy "support_messages_ticket_participant_insert" on public.support_ticket_messages
  for insert with check (
    public.is_admin_user()
    or exists (
      select 1 from public.support_tickets t
      where t.id = ticket_id
        and t.user_id = auth.uid()
        and sender_id = auth.uid()
    )
  );

drop policy if exists "app_settings_public_read" on public.app_settings;
create policy "app_settings_public_read" on public.app_settings
  for select using (is_public = true or public.is_admin_user());

drop policy if exists "app_settings_admin_write" on public.app_settings;
create policy "app_settings_admin_write" on public.app_settings
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "analytics_events_self_insert" on public.analytics_events;
create policy "analytics_events_self_insert" on public.analytics_events
  for insert with check (user_id is null or auth.uid() = user_id);

drop policy if exists "analytics_events_admin_select" on public.analytics_events;
create policy "analytics_events_admin_select" on public.analytics_events
  for select using (public.is_admin_user());

drop policy if exists "user_local_sync_logs_self" on public.user_local_sync_logs;
create policy "user_local_sync_logs_self" on public.user_local_sync_logs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "vehicle_catalog_change_logs_admin" on public.vehicle_catalog_change_logs;
create policy "vehicle_catalog_change_logs_admin" on public.vehicle_catalog_change_logs
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "consent_logs_self_insert" on public.consent_logs;
create policy "consent_logs_self_insert" on public.consent_logs
  for insert with check (auth.uid() = user_id);

drop policy if exists "consent_logs_self_select_or_admin" on public.consent_logs;
create policy "consent_logs_self_select_or_admin" on public.consent_logs
  for select using (auth.uid() = user_id or public.is_admin_user());

drop policy if exists "app_release_notes_public_read" on public.app_release_notes;
create policy "app_release_notes_public_read" on public.app_release_notes
  for select using (is_public = true or public.is_admin_user());

drop policy if exists "app_release_notes_admin_write" on public.app_release_notes;
create policy "app_release_notes_admin_write" on public.app_release_notes
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "vehicle_manufacturers_admin_write" on public.vehicle_manufacturers;
create policy "vehicle_manufacturers_admin_write" on public.vehicle_manufacturers
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "vehicle_models_admin_write" on public.vehicle_models;
create policy "vehicle_models_admin_write" on public.vehicle_models
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "vehicle_model_years_admin_write" on public.vehicle_model_years;
create policy "vehicle_model_years_admin_write" on public.vehicle_model_years
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "vehicle_variants_admin_write" on public.vehicle_variants;
create policy "vehicle_variants_admin_write" on public.vehicle_variants
  for all using (public.is_admin_user()) with check (public.is_admin_user());

insert into public.app_settings (key, value, description, is_public)
values
  ('reward_ad_daily_limit', '{"value": 3}', '하루 리워드 광고 최대 시청 횟수', true),
  ('reward_ads_enabled', '{"value": true}', '리워드 광고 사용 여부', true),
  ('new_user_ad_protection_days', '{"value": 3}', '신규 사용자 광고 보호 기간', true),
  ('season_ending_soon_days', '{"value": 3}', '시즌 종료 임박 표시 기준', true),
  ('official_drive_min_distance_km', '{"value": 1.0}', '공식 주행 최소 거리', true),
  ('official_drive_min_duration_seconds', '{"value": 180}', '공식 주행 최소 시간', true),
  ('abnormal_speed_kmh', '{"value": 180}', '이상 속도 검토 기준', true),
  ('allow_custom_vehicle_official_ranking', '{"value": false}', '직접 입력 차량 공식 랭킹 허용 여부', true),
  ('split_plug_in_hybrid_league', '{"value": true}', '플러그인 하이브리드 별도 리그 운영 여부', true),
  ('friendly_battle_enabled', '{"value": true}', '친선 배틀 사용 여부', true),
  ('premium_price_label', '{"text": "월 4,900원"}', '프리미엄 가격 표시 문구', true),
  ('coupons_enabled', '{"value": true}', '쿠폰 기능 사용 여부', true)
on conflict (key) do update set
  value = excluded.value,
  description = excluded.description,
  is_public = excluded.is_public,
  updated_at = now();
