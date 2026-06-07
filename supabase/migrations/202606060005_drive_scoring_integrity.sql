alter table public.drive_points
  add column if not exists is_mocked boolean not null default false;

create index if not exists drive_points_session_recorded_idx
  on public.drive_points (drive_session_id, recorded_at);

create index if not exists drive_sessions_user_status_started_idx
  on public.drive_sessions (user_id, status, started_at desc);

with ranked_scores as (
  select
    ctid,
    row_number() over (
      partition by drive_session_id
      order by created_at desc, id desc
    ) as row_number
  from public.drive_scores
)
delete from public.drive_scores as score
using ranked_scores
where score.ctid = ranked_scores.ctid
  and ranked_scores.row_number > 1;

create unique index if not exists drive_scores_drive_session_id_uidx
  on public.drive_scores (drive_session_id);
