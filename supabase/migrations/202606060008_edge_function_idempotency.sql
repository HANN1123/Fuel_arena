create table if not exists public.edge_function_idempotency_keys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  function_name text not null,
  idempotency_key text not null,
  request_hash text not null,
  status text not null default 'processing',
  response jsonb,
  error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (user_id, function_name, idempotency_key)
);

create index if not exists edge_function_idempotency_user_function_idx
  on public.edge_function_idempotency_keys (user_id, function_name, created_at desc);

with ranked_coupons as (
  select
    id,
    row_number() over (
      partition by user_id, coupon_id
      order by issued_at asc, id asc
    ) as row_rank
  from public.user_coupons
)
delete from public.user_coupons target
using ranked_coupons ranked
where target.id = ranked.id
  and ranked.row_rank > 1;

create unique index if not exists user_coupons_user_coupon_uidx
  on public.user_coupons (user_id, coupon_id);

create index if not exists ad_rewards_user_claimed_at_idx
  on public.ad_rewards (user_id, claimed_at desc);

alter table public.edge_function_idempotency_keys enable row level security;

drop policy if exists "edge_function_idempotency_self_select" on public.edge_function_idempotency_keys;
create policy "edge_function_idempotency_self_select" on public.edge_function_idempotency_keys
  for select using (auth.uid() = user_id);

drop policy if exists "edge_function_idempotency_admin_select" on public.edge_function_idempotency_keys;
create policy "edge_function_idempotency_admin_select" on public.edge_function_idempotency_keys
  for select using (public.is_admin_user());

create or replace function public.claim_mission_reward(
  target_user_id uuid,
  target_mission_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mission record;
  v_progress record;
  v_reward_xp integer := 0;
begin
  select id, target, reward_xp
  into v_mission
  from public.season_missions
  where id = target_mission_id;

  if not found then
    raise exception 'mission_not_found';
  end if;

  select id, progress, reward_claimed
  into v_progress
  from public.mission_progress
  where user_id = target_user_id
    and mission_id = target_mission_id
  for update;

  if not found then
    raise exception 'season_reward_not_ready';
  end if;

  if v_progress.progress < v_mission.target then
    raise exception 'season_reward_not_ready';
  end if;

  v_reward_xp := coalesce(v_mission.reward_xp, 0);

  if v_progress.reward_claimed then
    return jsonb_build_object(
      'claimed', true,
      'alreadyClaimed', true,
      'userId', target_user_id,
      'missionId', target_mission_id,
      'progressId', v_progress.id,
      'progress', v_progress.progress,
      'target', v_mission.target,
      'rewardXp', v_reward_xp
    );
  end if;

  update public.mission_progress
  set reward_claimed = true,
      updated_at = now()
  where id = v_progress.id;

  update public.profiles
  set season_score = coalesce(season_score, 0) + v_reward_xp,
      updated_at = now()
  where id = target_user_id;

  return jsonb_build_object(
    'claimed', true,
    'alreadyClaimed', false,
    'userId', target_user_id,
    'missionId', target_mission_id,
    'progressId', v_progress.id,
    'progress', v_progress.progress,
    'target', v_mission.target,
    'rewardXp', v_reward_xp
  );
end;
$$;

insert into public.app_settings (key, value, description, is_public)
values
  (
    'season_promotion_target_score',
    '{"value": 3000}',
    '시즌 승급 목표 점수',
    true
  )
on conflict (key) do update set
  value = excluded.value,
  description = excluded.description,
  is_public = excluded.is_public,
  updated_at = now();
