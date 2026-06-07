alter table public.sponsors enable row level security;
alter table public.sponsor_challenges enable row level security;
alter table public.advertisements enable row level security;
alter table public.coupons enable row level security;

drop policy if exists "sponsors_active_read" on public.sponsors;
create policy "sponsors_active_read" on public.sponsors
  for select using (is_active = true or public.is_admin_user());

drop policy if exists "sponsors_admin_write" on public.sponsors;
create policy "sponsors_admin_write" on public.sponsors
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "sponsor_challenges_active_read" on public.sponsor_challenges;
create policy "sponsor_challenges_active_read" on public.sponsor_challenges
  for select using (
    public.is_admin_user()
    or (
      is_active = true
      and starts_at <= now()
      and ends_at > now()
    )
  );

drop policy if exists "sponsor_challenges_admin_write" on public.sponsor_challenges;
create policy "sponsor_challenges_admin_write" on public.sponsor_challenges
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "advertisements_active_read" on public.advertisements;
create policy "advertisements_active_read" on public.advertisements
  for select using (
    public.is_admin_user()
    or (
      is_active = true
      and (starts_at is null or starts_at <= now())
      and (ends_at is null or ends_at > now())
    )
  );

drop policy if exists "advertisements_admin_write" on public.advertisements;
create policy "advertisements_admin_write" on public.advertisements
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "coupons_active_read" on public.coupons;
create policy "coupons_active_read" on public.coupons
  for select using (public.is_admin_user() or expires_at > now());

drop policy if exists "coupons_admin_write" on public.coupons;
create policy "coupons_admin_write" on public.coupons
  for all using (public.is_admin_user()) with check (public.is_admin_user());
