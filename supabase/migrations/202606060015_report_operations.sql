create index if not exists report_items_reporter_created_at_idx
  on public.report_items (reporter_id, created_at desc);

create index if not exists report_items_status_created_at_idx
  on public.report_items (status, created_at desc);

drop policy if exists "reports_admin_select" on public.report_items;
create policy "reports_admin_select" on public.report_items
  for select using (public.is_admin_user());

drop policy if exists "reports_admin_update" on public.report_items;
create policy "reports_admin_update" on public.report_items
  for update using (public.is_admin_user()) with check (public.is_admin_user());
