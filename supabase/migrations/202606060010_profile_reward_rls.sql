alter table public.badges enable row level security;
alter table public.achievements enable row level security;

drop policy if exists "badges_read_all" on public.badges;
create policy "badges_read_all" on public.badges
  for select using (true);

drop policy if exists "badges_admin_write" on public.badges;
create policy "badges_admin_write" on public.badges
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "achievements_read_all" on public.achievements;
create policy "achievements_read_all" on public.achievements
  for select using (true);

drop policy if exists "achievements_admin_write" on public.achievements;
create policy "achievements_admin_write" on public.achievements
  for all using (public.is_admin_user()) with check (public.is_admin_user());
