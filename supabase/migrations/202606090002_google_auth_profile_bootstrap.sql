alter table public.profiles
  add column if not exists last_login_at timestamptz;

create or replace function public.handle_new_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  metadata jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  email_value text := coalesce(nullif(new.email, ''), metadata->>'email', '');
  nickname_value text := coalesce(
    nullif(metadata->>'name', ''),
    nullif(metadata->>'full_name', ''),
    nullif(metadata->>'display_name', ''),
    nullif(metadata->>'preferred_username', ''),
    nullif(split_part(coalesce(nullif(new.email, ''), metadata->>'email', ''), '@', 1), ''),
    'Fuel Driver'
  );
  avatar_value text := coalesce(nullif(metadata->>'avatar_url', ''), metadata->>'picture', '');
begin
  insert into public.profiles (
    id,
    email,
    nickname,
    avatar_url,
    auth_provider,
    last_login_at,
    updated_at
  )
  values (
    new.id,
    email_value,
    nickname_value,
    nullif(avatar_value, ''),
    'google',
    now(),
    now()
  )
  on conflict (id) do update
    set email = case
          when excluded.email is not null and excluded.email <> ''
            then excluded.email
          else public.profiles.email
        end,
        avatar_url = case
          when coalesce(public.profiles.avatar_url, '') = ''
            then excluded.avatar_url
          else public.profiles.avatar_url
        end,
        auth_provider = 'google',
        last_login_at = now(),
        updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
  after insert on auth.users
  for each row execute function public.handle_new_auth_user_profile();

drop policy if exists "profiles_select_self" on public.profiles;
create policy "profiles_select_self" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

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
    and coalesce(nullif(tier, ''), 'Bronze I') = 'Bronze I'
  );

revoke insert on public.profiles from anon, authenticated;
revoke update on public.profiles from anon, authenticated;

grant insert (
  id,
  email,
  nickname,
  avatar_url,
  representative_vehicle_id,
  representative_vehicle_name,
  auth_provider,
  onboarding_completed,
  consent_completed,
  additional_setup_completed,
  vehicle_setup_completed,
  selected_fuel_league,
  selected_vehicle_class,
  last_login_at,
  updated_at
) on public.profiles to authenticated;

grant update (
  email,
  nickname,
  avatar_url,
  representative_vehicle_id,
  representative_vehicle_name,
  auth_provider,
  onboarding_completed,
  consent_completed,
  additional_setup_completed,
  vehicle_setup_completed,
  selected_fuel_league,
  selected_vehicle_class,
  last_login_at,
  updated_at
) on public.profiles to authenticated;

comment on function public.handle_new_auth_user_profile() is
  'Creates a safe default profile row when Supabase Auth creates a Google user.';
comment on column public.profiles.last_login_at is
  'Last successful Supabase Auth login observed by trigger or client profile repair.';
