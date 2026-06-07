alter table public.ad_rewards enable row level security;
alter table public.subscription_plans enable row level security;

drop policy if exists "ad_rewards_self_select" on public.ad_rewards;
create policy "ad_rewards_self_select" on public.ad_rewards
  for select using (auth.uid() = user_id);

drop policy if exists "ad_rewards_admin_select" on public.ad_rewards;
create policy "ad_rewards_admin_select" on public.ad_rewards
  for select using (public.is_admin_user());

drop policy if exists "subscription_plans_public_read" on public.subscription_plans;
create policy "subscription_plans_public_read" on public.subscription_plans
  for select using (true);

drop policy if exists "subscription_plans_admin_write" on public.subscription_plans;
create policy "subscription_plans_admin_write" on public.subscription_plans
  for all using (public.is_admin_user()) with check (public.is_admin_user());
