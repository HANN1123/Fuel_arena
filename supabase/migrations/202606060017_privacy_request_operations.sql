create table if not exists public.privacy_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  request_type text not null,
  description text not null,
  status text not null default 'open',
  admin_note text,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint privacy_requests_type_check
    check (request_type in (
      'data_download',
      'data_delete',
      'account_deletion',
      'consent_withdrawal'
    )),
  constraint privacy_requests_status_check
    check (status in ('open', 'review', 'completed', 'rejected'))
);

create index if not exists privacy_requests_user_created_at_idx
  on public.privacy_requests (user_id, created_at desc);

create index if not exists privacy_requests_status_updated_at_idx
  on public.privacy_requests (status, updated_at desc);

create unique index if not exists privacy_requests_active_type_uidx
  on public.privacy_requests (user_id, request_type)
  where status in ('open', 'review');

alter table public.privacy_requests enable row level security;

drop policy if exists "privacy_requests_self_select_or_admin"
  on public.privacy_requests;
create policy "privacy_requests_self_select_or_admin"
  on public.privacy_requests
  for select
  using (auth.uid() = user_id or public.is_admin_user());

drop policy if exists "privacy_requests_self_insert"
  on public.privacy_requests;
create policy "privacy_requests_self_insert"
  on public.privacy_requests
  for insert
  with check (
    auth.uid() = user_id
    and status = 'open'
  );

drop policy if exists "privacy_requests_admin_update"
  on public.privacy_requests;
create policy "privacy_requests_admin_update"
  on public.privacy_requests
  for update
  using (public.is_admin_user())
  with check (public.is_admin_user());

comment on table public.privacy_requests is
  'User privacy, data export, data deletion, and account deletion requests reviewed by admins.';
