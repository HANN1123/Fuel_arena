alter table public.support_ticket_messages
  add column if not exists is_admin_reply boolean not null default false;

alter table public.support_tickets
  drop constraint if exists support_tickets_status_check;

alter table public.support_tickets
  add constraint support_tickets_status_check
  check (status in ('open', 'review', 'resolved', 'closed'))
  not valid;

alter table public.support_tickets
  validate constraint support_tickets_status_check;

create index if not exists support_tickets_status_updated_at_idx
  on public.support_tickets (status, updated_at desc);

create index if not exists support_ticket_messages_admin_reply_idx
  on public.support_ticket_messages (ticket_id, is_admin_reply, created_at);

comment on column public.support_ticket_messages.is_admin_reply is
  'True when the message was written by an administrator for user-facing support replies.';
