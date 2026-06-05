# 데이터 스키마

Supabase schema는 `supabase/migrations/202606050001_initial_schema.sql`에 정의되어 있다.

## 주요 테이블
profiles, app_consents, vehicles, drive_sessions, drive_points, drive_scores, rankings, battles, battle_participants, seasons, season_missions, mission_progress, badges, user_badges, achievements, user_achievements, crews, notifications, sponsors, sponsor_challenges, advertisements, ad_rewards, coupons, user_coupons, subscription_plans, user_subscriptions, fraud_reviews, report_items.

## 민감 데이터
drive_points는 private table이며 사용자 본인만 접근한다. 공개 랭킹은 public_rankings view를 통해 제한 정보만 제공한다.

## Edge Functions
calculate_drive_score, verify_drive_session, update_rankings, settle_battle, grant_ad_reward, claim_season_reward, issue_coupon, update_mission_progress, process_fraud_review, send_notification.

