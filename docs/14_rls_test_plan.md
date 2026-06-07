# RLS Test Plan

## 테스트 계정
- `user_a`: 일반 사용자
- `user_b`: 일반 사용자
- `admin_a`: `profiles.is_admin = true`

## 본인 데이터
- `user_a`는 자신의 `profiles`, `app_consents`, `vehicles`, `user_vehicles`, `drive_sessions`, `drive_points`, `support_tickets`를 읽고 쓸 수 있어야 한다.
- `user_a`가 동의를 저장하면 자신의 `app_consents` 현재값이 갱신되고 `consent_logs`에 변경 로그가 추가되어야 한다.
- `user_a`는 `user_b`의 `drive_points`, `support_tickets`, `ad_rewards`, `user_subscriptions`, `purchase_verifications`, `user_coupons`를 읽을 수 없어야 한다.
- `user_a`는 자신의 문의 티켓에 메시지를 추가할 수 있어야 한다.
- `admin_a`는 문의 티켓에 `is_admin_reply = true` 메시지를 추가하고 상태를 `review` 또는 `resolved`로 변경할 수 있어야 한다.
- `user_a`는 자신의 `privacy_requests`를 생성/조회할 수 있고, `user_b`의 요청은 읽을 수 없어야 한다.
- `user_a`는 자신의 `user_vehicle_id`에 연결된 `custom_vehicle_requests`만 생성할 수 있고, `user_vehicle_id`가 없거나 `user_b`의 `user_vehicle_id`를 넣은 직접 입력 차량 요청은 RLS에서 거부되어야 한다.

## 공개 데이터
- 모든 로그인 사용자는 `fuel_leagues`, `vehicle_manufacturers`, `vehicle_models`, `vehicle_model_years`, `vehicle_variants`를 읽을 수 있어야 한다.
- 공개 랭킹 view는 닉네임, 티어, 점수, 차급, 연료 리그만 포함해야 한다.
- 공개 view에는 이메일, 정확한 좌표, raw `drive_points`가 없어야 한다.
- 일반 사용자는 활성 기간 안의 `sponsors`, `sponsor_challenges`, `advertisements`, 만료 전 `coupons`만 읽을 수 있어야 한다.
- 일반 사용자는 공개 콘텐츠 테이블을 insert/update/delete 할 수 없어야 한다.
- 모든 사용자는 `subscription_plans`를 읽을 수 있어야 하고, 일반 사용자는 생성/수정/삭제할 수 없어야 한다.
- 모든 로그인 사용자는 `badges`, `achievements` 정의를 읽을 수 있어야 한다.
- 일반 사용자는 본인의 `user_badges`, `user_achievements`만 읽고 타인의 진행률은 읽을 수 없어야 한다.

## 관리자 데이터
- `admin_a`는 `support_tickets`, `analytics_events`, `vehicle_catalog_change_logs`, `admin_action_logs`, 공개/비공개 `app_settings`를 조회할 수 있어야 한다.
- `admin_a`는 `consent_logs`를 조회할 수 있지만 일반 사용자는 타인의 동의 로그를 읽을 수 없어야 한다.
- `admin_a`는 `privacy_requests`를 조회하고 상태를 `review`, `completed`, `rejected`로 변경할 수 있어야 한다.
- `admin_a`만 차량 카탈로그 변경 로그, 관리자 액션 로그, app settings를 수정할 수 있어야 한다.
- 일반 사용자는 `vehicle_catalog_change_logs`, `admin_action_logs`, 비공개 `app_settings`를 읽거나 쓸 수 없어야 한다.
- `vehicle_catalog_change_logs.before_data`와 `after_data`는 관리자에게만 노출되어야 한다.
- `get_admin_dashboard_metrics`: 관리자는 metric row를 받을 수 있고, 일반 사용자는 빈 결과를 받아야 한다.
- `report_items`: 사용자는 본인 신고만 생성/조회할 수 있고, 관리자는 Reports 섹션에서 신고를 조회하고 상태를 업데이트할 수 있어야 한다.
- `ad_rewards`: 사용자는 본인 광고 보상 row만 읽고, 관리자는 운영 확인용으로 조회할 수 있어야 한다.

## 정적 검증
- `dart run tool/validate_supabase_schema.dart`가 필수 table, RLS, 정책, public view privacy, RPC 보안 속성, Edge 전용 RPC grant/revoke, 중복 방지 index를 통과해야 한다.

## Profile self-write hardening
- `user_a` can update nickname/avatar/setup state, but cannot insert or update
  `tier`, `total_score`, `season_score`, `current_streak`, `best_streak`,
  `is_premium`, `is_admin`, or `created_at`.

## Edge Functions
- 모든 함수는 `OPTIONS` CORS preflight와 `POST`만 허용하고, Web idempotency 요청용 `x-idempotency-key` header를 preflight에서 허용하는지 확인한다.
- 검증 실패 응답은 `{ error: { code, message } }` 형태여야 한다.
- `finish_drive_session`: 다른 사용자의 sessionId를 거부하고, 짧은 주행은 `pending_review`로 저장해야 한다.
- `finish_drive_session`: 모의 위치, 비정상 속도, GPS 정확도 낮음, GPS 포인트 없음은 `pending_review` 사유가 되어야 한다.
- `update_rankings`: 관리자 또는 `RANKING_JOB_SECRET` 호출만 허용하고, verified `drive_scores`만 rankings에 반영해야 한다.
- `calculate_drive_score`: 음수 거리, 음수 idle, 0 이하 classAverageEfficiency를 거부해야 한다.
- `verify_drive_session`: 짧은 주행은 `pending_review`로 내려야 한다.
- `send_notification`: 로그인 사용자의 알림을 `notifications`에 insert하고 `isDriving = true`이면 `heldDuringDrive = true`로 응답해야 한다.
- `send_notification`: 일반 사용자가 다른 `targetUserId`로 알림을 보내면 403을 반환하고, 관리자는 대상 사용자 알림을 생성할 수 있어야 한다.
- `notifications`: 사용자는 자신의 알림만 list/update할 수 있고 다른 사용자의 알림 row는 읽음 처리할 수 없어야 한다.
- `crews`, `crew_members`: 사용자는 본인이 속한 크루만 조회할 수 있고, 다른 크루 row는 읽을 수 없어야 한다.
- `get_my_crew_summary`, `get_my_crew_members`: 사용자 본인 크루의 요약/멤버만 반환하고, 다른 크루의 정확한 멤버 목록은 반환하지 않아야 한다.
- `assign_vehicle_league`: 로그인 사용자만 자신의 차량 리그를 배정할 수 있어야 한다.
- `review_custom_vehicle`: 관리자만 직접 입력 차량 검수 결과를 업데이트할 수 있어야 한다.
- `review_custom_vehicle`: 요청 row의 `user_vehicle_id`와 검수 대상 차량 ID, 요청 사용자와 차량 소유자가 일치하지 않으면 거부해야 한다.
- `verify_purchase`: 로그인 사용자만 구매 검증을 요청할 수 있어야 하며, service role key는 Edge Function secret에서만 사용한다.
- `verify_purchase`: production에서 mock provider는 거부되어야 하고, provider secret이 없으면 검증 실패가 기록되어야 한다.
- `grant_ad_reward`, `claim_season_reward`, `issue_coupon`, `update_mission_progress`, `settle_battle`: 로그인 사용자만 호출할 수 있어야 한다.
- 같은 사용자와 함수에서 같은 `x-idempotency-key`와 같은 body를 재전송하면 같은 응답이 반환되어야 하며, 같은 key를 다른 body로 재사용하면 409가 반환되어야 한다.
- `grant_ad_reward`: daily limit를 초과하면 429를 반환하고 `ad_rewards`가 추가되지 않아야 한다.
- `claim_season_reward`: 완료되지 않은 미션은 거부하고, 이미 받은 미션은 `alreadyClaimed = true`로 응답하면서 `profiles.season_score`를 다시 올리지 않아야 한다.
- `recompute_rankings(text)`, `claim_mission_reward(uuid, uuid)`: public/anon/authenticated execute 권한은 없어야 하고 service_role execute만 허용되어야 한다.
- `issue_coupon`: 만료된 쿠폰과 존재하지 않는 쿠폰은 거부하고, 같은 사용자/쿠폰 중복 발급은 기존 `user_coupons`를 반환해야 한다.
- `settle_battle`: 본인 참가 row만 임의로 조작 가능해야 하며, 완료 후 참가자 결과와 battle status가 일관되게 갱신되어야 한다.
