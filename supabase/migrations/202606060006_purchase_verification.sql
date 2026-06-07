create table if not exists public.purchase_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null,
  product_id text not null,
  transaction_id text not null,
  purchase_token_hash text not null,
  status text not null default 'pending',
  plan_id text references public.subscription_plans(id),
  expires_at timestamptz,
  raw_response jsonb not null default '{}'::jsonb,
  error_code text,
  created_at timestamptz not null default now()
);

create unique index if not exists purchase_verifications_provider_tx_uidx
  on public.purchase_verifications (provider, transaction_id);

create index if not exists purchase_verifications_user_created_idx
  on public.purchase_verifications (user_id, created_at desc);

alter table public.user_subscriptions
  add column if not exists provider text,
  add column if not exists product_id text,
  add column if not exists transaction_id text,
  add column if not exists verified_at timestamptz;

create unique index if not exists user_subscriptions_user_plan_uidx
  on public.user_subscriptions (user_id, plan_id);

alter table public.purchase_verifications enable row level security;

drop policy if exists "purchase_verifications_self_select" on public.purchase_verifications;
create policy "purchase_verifications_self_select" on public.purchase_verifications
  for select using (auth.uid() = user_id);
