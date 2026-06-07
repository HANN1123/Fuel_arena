create table if not exists public.admin_action_logs (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid references public.profiles(id) on delete set null,
  section text not null,
  action text not null,
  target_table text,
  target_id text,
  target_title text,
  target_status text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists admin_action_logs_admin_created_at_idx
  on public.admin_action_logs (admin_user_id, created_at desc);

create index if not exists admin_action_logs_section_created_at_idx
  on public.admin_action_logs (section, created_at desc);

alter table public.admin_action_logs enable row level security;

drop policy if exists "admin_action_logs_admin_select" on public.admin_action_logs;
create policy "admin_action_logs_admin_select" on public.admin_action_logs
  for select using (public.is_admin_user());

drop policy if exists "admin_action_logs_admin_insert" on public.admin_action_logs;
create policy "admin_action_logs_admin_insert" on public.admin_action_logs
  for insert with check (
    public.is_admin_user()
    and admin_user_id = auth.uid()
  );
