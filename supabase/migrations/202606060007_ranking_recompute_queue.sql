create table if not exists public.ranking_update_jobs (
  id uuid primary key default gen_random_uuid(),
  period text not null default 'season',
  status text not null default 'pending',
  requested_by uuid references public.profiles(id) on delete set null,
  related_drive_score_id uuid references public.drive_scores(id) on delete set null,
  started_at timestamptz,
  finished_at timestamptz,
  result jsonb not null default '{}'::jsonb,
  error_message text,
  created_at timestamptz not null default now()
);

create index if not exists ranking_update_jobs_status_period_idx
  on public.ranking_update_jobs (status, period, created_at desc);

create unique index if not exists ranking_update_jobs_active_period_uidx
  on public.ranking_update_jobs (period)
  where status in ('pending', 'running');

create index if not exists rankings_period_league_class_rank_idx
  on public.rankings (period, fuel_league, vehicle_class, rank);

alter table public.ranking_update_jobs enable row level security;

drop policy if exists "ranking_update_jobs_admin_select" on public.ranking_update_jobs;
create policy "ranking_update_jobs_admin_select" on public.ranking_update_jobs
  for select using (public.is_admin_user());

drop policy if exists "ranking_update_jobs_admin_write" on public.ranking_update_jobs;
create policy "ranking_update_jobs_admin_write" on public.ranking_update_jobs
  for all using (public.is_admin_user()) with check (public.is_admin_user());

create or replace function public.recompute_rankings(target_period text default 'season')
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_period text := coalesce(nullif(target_period, ''), 'season');
  v_rows integer := 0;
begin
  create temporary table if not exists pg_temp.previous_rankings_snapshot (
    user_id uuid,
    vehicle_class text,
    fuel_league text,
    previous_rank integer
  ) on commit drop;

  truncate table pg_temp.previous_rankings_snapshot;

  insert into pg_temp.previous_rankings_snapshot (
    user_id,
    vehicle_class,
    fuel_league,
    previous_rank
  )
  select
    user_id,
    vehicle_class,
    fuel_league,
    rank
  from public.rankings
  where period = v_period;

  delete from public.rankings
  where period = v_period;

  with verified_scores as (
    select
      ds.user_id,
      coalesce(nullif(v.vehicle_class, ''), '기타') as vehicle_class,
      coalesce(nullif(v.fuel_type, ''), 'Other') as fuel_type,
      coalesce(nullif(v.fuel_league, ''), public.fuel_league_for_type(v.fuel_type)) as fuel_league,
      sum(score.total_score)::integer as score
    from public.drive_scores score
    join public.drive_sessions ds on ds.id = score.drive_session_id
    left join public.vehicles v on v.id = ds.vehicle_id
    where score.verification_status = 'verified'
    group by
      ds.user_id,
      coalesce(nullif(v.vehicle_class, ''), '기타'),
      coalesce(nullif(v.fuel_type, ''), 'Other'),
      coalesce(nullif(v.fuel_league, ''), public.fuel_league_for_type(v.fuel_type))
  ),
  ranked_scores as (
    select
      verified_scores.*,
      row_number() over (
        partition by fuel_league, vehicle_class
        order by score desc, user_id
      )::integer as next_rank,
      count(*) over (
        partition by fuel_league, vehicle_class
      )::integer as cohort_size
    from verified_scores
  )
  insert into public.rankings (
    user_id,
    vehicle_class,
    fuel_type,
    fuel_league,
    tier,
    score,
    rank,
    previous_rank,
    percentile,
    period
  )
  select
    ranked.user_id,
    ranked.vehicle_class,
    ranked.fuel_type,
    ranked.fuel_league,
    coalesce(nullif(profile.tier, ''), 'Bronze I') as tier,
    ranked.score,
    ranked.next_rank,
    coalesce(previous.previous_rank, ranked.next_rank) as previous_rank,
    case
      when ranked.cohort_size <= 1 then 1
      else greatest(
        1,
        least(
          99,
          round(((ranked.next_rank - 1)::numeric / (ranked.cohort_size - 1)) * 100)::integer
        )
      )
    end as percentile,
    v_period
  from ranked_scores ranked
  join public.profiles profile on profile.id = ranked.user_id
  left join pg_temp.previous_rankings_snapshot previous
    on previous.user_id = ranked.user_id
   and previous.vehicle_class = ranked.vehicle_class
   and previous.fuel_league = ranked.fuel_league;

  get diagnostics v_rows = row_count;

  return jsonb_build_object(
    'period', v_period,
    'rankingsUpdated', v_rows
  );
end;
$$;
