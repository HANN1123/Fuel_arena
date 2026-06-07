create or replace function public.get_admin_dashboard_metrics()
returns table (
  id text,
  label text,
  value text,
  unit text,
  healthy boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_total_users bigint := 0;
  v_dau bigint := 0;
  v_mau bigint := 0;
  v_premium_users bigint := 0;
  v_drive_sessions bigint := 0;
  v_completed_drives bigint := 0;
  v_drive_scores bigint := 0;
  v_verified_scores bigint := 0;
  v_pending_scores bigint := 0;
  v_active_battles bigint := 0;
  v_ad_rewards_today bigint := 0;
  v_user_coupons bigint := 0;
  v_used_coupons bigint := 0;
  v_open_support bigint := 0;
  v_open_reports bigint := 0;
  v_pending_fraud bigint := 0;
  v_verified_purchases bigint := 0;
  v_admin_actions_24h bigint := 0;
  v_completion_pct numeric := 0;
  v_verified_pct numeric := 0;
  v_premium_pct numeric := 0;
  v_coupon_use_pct numeric := 0;
begin
  if not public.is_admin_user() then
    return;
  end if;

  select count(*) into v_total_users
  from public.profiles;

  select count(*) into v_premium_users
  from public.profiles
  where is_premium = true;

  select count(distinct user_id) into v_dau
  from (
    select user_id
    from public.analytics_events
    where created_at >= now() - interval '1 day'
      and user_id is not null
    union
    select user_id
    from public.drive_sessions
    where created_at >= now() - interval '1 day'
  ) activity;

  select count(distinct user_id) into v_mau
  from (
    select user_id
    from public.analytics_events
    where created_at >= now() - interval '30 days'
      and user_id is not null
    union
    select user_id
    from public.drive_sessions
    where created_at >= now() - interval '30 days'
  ) activity;

  select
    count(*),
    count(*) filter (
      where ended_at is not null
         or status in ('completed', 'finished', 'ended', 'verified')
    )
  into v_drive_sessions, v_completed_drives
  from public.drive_sessions;

  select
    count(*),
    count(*) filter (where verification_status = 'verified'),
    count(*) filter (
      where verification_status in ('pending_review', 'review', 'pending')
    )
  into v_drive_scores, v_verified_scores, v_pending_scores
  from public.drive_scores;

  select count(*) into v_active_battles
  from public.battles
  where status not in ('completed', 'cancelled', '종료')
    and end_at >= now();

  select count(*) into v_ad_rewards_today
  from public.ad_rewards
  where claimed_at >= now() - interval '1 day';

  select
    count(*),
    count(*) filter (where used_at is not null or status in ('used', 'redeemed'))
  into v_user_coupons, v_used_coupons
  from public.user_coupons;

  select count(*) into v_open_support
  from public.support_tickets
  where status in ('open', 'review', 'pending', 'pending_review');

  select count(*) into v_open_reports
  from public.report_items
  where status in ('open', 'review', 'pending', 'pending_review');

  select count(*) into v_pending_fraud
  from public.fraud_reviews
  where status in ('pending_review', 'review', 'pending');

  select count(*) into v_verified_purchases
  from public.purchase_verifications
  where status = 'verified';

  select count(*) into v_admin_actions_24h
  from public.admin_action_logs
  where created_at >= now() - interval '1 day';

  v_completion_pct := case
    when v_drive_sessions = 0 then 0
    else round(v_completed_drives::numeric * 100 / v_drive_sessions, 1)
  end;
  v_verified_pct := case
    when v_drive_scores = 0 then 0
    else round(v_verified_scores::numeric * 100 / v_drive_scores, 1)
  end;
  v_premium_pct := case
    when v_total_users = 0 then 0
    else round(v_premium_users::numeric * 100 / v_total_users, 1)
  end;
  v_coupon_use_pct := case
    when v_user_coupons = 0 then 0
    else round(v_used_coupons::numeric * 100 / v_user_coupons, 1)
  end;

  return query
  select *
  from (
    values
      ('dau', 'DAU', v_dau::text, '명', true),
      ('mau', 'MAU', v_mau::text, '명', true),
      ('users', '전체 사용자', v_total_users::text, '명', true),
      ('drives', '총 주행 수', v_drive_sessions::text, '건', true),
      ('completion', '주행 완료율', v_completion_pct::text, '%', v_completion_pct >= 70 or v_drive_sessions = 0),
      ('verification', '검증 승인율', v_verified_pct::text, '%', v_verified_pct >= 70 or v_drive_scores = 0),
      ('battles', '진행 중 배틀', v_active_battles::text, '건', true),
      ('ad_rewards', '오늘 광고 보상', v_ad_rewards_today::text, '건', true),
      ('premium', '프리미엄 전환율', v_premium_pct::text, '%', v_premium_pct >= 3 or v_total_users = 0),
      ('coupon_use', '쿠폰 사용률', v_coupon_use_pct::text, '%', v_coupon_use_pct >= 20 or v_user_coupons = 0),
      ('support', '미처리 문의', v_open_support::text, '건', v_open_support < 50),
      ('reports', '미처리 신고', v_open_reports::text, '건', v_open_reports < 50),
      ('fraud', '검토 대기 기록', (v_pending_scores + v_pending_fraud)::text, '건', (v_pending_scores + v_pending_fraud) < 50),
      ('purchase_verified', '검증된 구매', v_verified_purchases::text, '건', true),
      ('admin_actions', '24시간 운영 액션', v_admin_actions_24h::text, '건', true)
  ) as metrics(id, label, value, unit, healthy);
end;
$$;

revoke all on function public.get_admin_dashboard_metrics() from public;
grant execute on function public.get_admin_dashboard_metrics() to authenticated;
