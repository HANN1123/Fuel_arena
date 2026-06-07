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
  updated_at
) on public.profiles to authenticated;

comment on policy "profiles_insert_self" on public.profiles is
  'Users may create only their own profile row with score, premium, and admin fields at safe defaults.';
comment on table public.profiles is
  'Profile score, streak, premium, tier, and admin columns are server-controlled; authenticated clients may update only identity/onboarding/vehicle selection columns.';
