# Supabase Plan

Fuel Arena는 Supabase Auth, Postgres, Realtime, Storage, Edge Functions, Row Level Security를 전제로 설계한다. 첫 구현에서는 Mock Repository를 사용하고 Supabase 구현체는 mock fallback으로 동작하도록 유지한다.

## 환경변수

클라이언트에 허용되는 값:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

금지:

- `service_role` key는 클라이언트에 절대 포함하지 않는다.

## 보안 원칙

- RLS를 기본 전제로 한다.
- 민감한 주행 데이터는 본인만 접근할 수 있어야 한다.
- 공개 랭킹에는 닉네임, 티어, 점수, 차량 클래스, 연료 타입 정도만 노출한다.
- 정확한 위치 경로는 공개하지 않는다.
- 점수 계산은 클라이언트가 아니라 Edge Function 또는 서버 신뢰 영역에서 처리한다.
- 클라이언트 점수 제출은 검증 대기 상태로 저장하고 서버 검증 후 랭킹에 반영한다.

## 테이블 계획

### profiles

사용자 공개 프로필과 게임 진행 상태.

- id
- nickname
- avatar_url
- tier
- total_score
- season_score
- current_streak
- best_streak
- representative_vehicle_id
- is_premium
- created_at
- updated_at

### vehicles

사용자 차량 정보.

- id
- user_id
- manufacturer
- model_name
- model_year
- fuel_type
- vehicle_class
- nickname
- is_primary
- created_at

### drive_sessions

주행 세션 원본 메타데이터.

- id
- user_id
- vehicle_id
- started_at
- ended_at
- distance_km
- duration_seconds
- average_speed
- fuel_efficiency
- verification_status
- created_at

### drive_scores

서버 계산 후 저장되는 점수.

- id
- drive_session_id
- user_id
- total_score
- efficiency_score
- stability_score
- class_percentile
- acceleration_penalty
- braking_penalty
- idle_penalty
- distance_bonus
- consistency_bonus
- verification_status
- calculated_at

### rankings

공개 랭킹 뷰 또는 materialized table.

- id
- user_id
- season_id
- rank_scope
- rank
- previous_rank
- score
- vehicle_class
- fuel_type
- region_code
- updated_at

### battles

배틀 메타 정보.

- id
- title
- battle_type
- status
- rule_type
- start_at
- end_at
- reward_summary
- created_by

### battle_participants

배틀 참가자와 점수.

- id
- battle_id
- user_id
- score
- result
- joined_at

### seasons

시즌 정보.

- id
- name
- starts_at
- ends_at
- current_league
- promotion_target_score
- reward_progress

### season_missions

시즌/일일/주간 미션 정의.

- id
- season_id
- title
- description
- mission_type
- target_value
- reward_xp
- starts_at
- ends_at

### user_mission_progress

사용자 미션 진행 상태.

- id
- user_id
- mission_id
- current_value
- completed_at
- reward_claimed_at

### badges

배지 정의.

- id
- name
- description
- rarity
- icon_url

### user_badges

사용자 획득 배지.

- id
- user_id
- badge_id
- equipped
- earned_at

### achievements

업적 정의.

- id
- title
- description
- target_value
- reward_summary

### user_achievements

사용자 업적 진행 상태.

- id
- user_id
- achievement_id
- progress
- completed_at

### rivalries

라이벌 관계.

- id
- user_id
- rival_user_id
- status
- created_at

### crews

크루 정보.

- id
- name
- owner_id
- description
- created_at

### crew_members

크루 멤버.

- id
- crew_id
- user_id
- role
- joined_at

### notifications

앱 알림.

- id
- user_id
- title
- body
- notification_type
- read_at
- created_at

### sponsors

스폰서 정보.

- id
- name
- logo_url
- status

### sponsor_challenges

스폰서 챌린지.

- id
- sponsor_id
- title
- description
- reward_summary
- starts_at
- ends_at

### advertisements

광고 메타 정보.

- id
- placement
- reward_type
- daily_limit
- is_active

### ad_rewards

광고 보상 지급 로그.

- id
- user_id
- advertisement_id
- reward_type
- reward_value
- claimed_at

### coupons

쿠폰 정의.

- id
- sponsor_id
- title
- description
- expires_at

### user_coupons

사용자 쿠폰함.

- id
- user_id
- coupon_id
- status
- issued_at
- used_at

### subscriptions

프리미엄 구독 상태.

- id
- user_id
- provider
- plan_id
- status
- started_at
- expires_at

### consent_logs

약관 및 데이터 활용 동의 로그.

- id
- user_id
- consent_type
- version
- agreed
- created_at

### fraud_reviews

비정상 기록 검토.

- id
- user_id
- drive_session_id
- reason
- status
- reviewed_by
- reviewed_at

### reports

신고 및 이의 제기.

- id
- reporter_user_id
- target_type
- target_id
- reason
- status
- created_at

## Edge Function 후보

- `calculate_drive_score`
- `verify_drive_session`
- `update_rankings`
- `match_battle_opponent`
- `claim_ad_reward`
- `claim_mission_reward`

## Realtime 후보

- 배틀 점수 업데이트
- 랭킹 변경 알림
- 라이벌 추월 알림
- 크루 챌린지 진행도
