create index if not exists consent_logs_user_id_created_at_idx
  on public.consent_logs (user_id, created_at desc);

create index if not exists consent_logs_created_at_idx
  on public.consent_logs (created_at desc);
