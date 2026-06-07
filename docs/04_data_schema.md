# 데이터 스키마

Supabase schema는 `supabase/migrations/202606050001_initial_schema.sql`을 기반으로 하고, Google/차량 리그 확장은 `202606060001_google_vehicle_leagues.sql`, 2008-2026 제조사/모델/연식/파워트레인 catalog seed는 `202606060002_vehicle_catalog_seed.sql`에 정의되어 있다.

## 주요 테이블
profiles, app_consents, consent_logs, vehicles, fuel_leagues, vehicle_manufacturers, vehicle_models, vehicle_model_years, vehicle_variants, user_vehicles, league_memberships, custom_vehicle_requests, drive_sessions, drive_points, drive_scores, rankings, ranking_update_jobs, battles, battle_participants, seasons, season_missions, mission_progress, badges, user_badges, achievements, user_achievements, crews, crew_members, notifications, sponsors, sponsor_challenges, advertisements, ad_rewards, coupons, user_coupons, subscription_plans, user_subscriptions, purchase_verifications, fraud_reviews, report_items, support_tickets, support_ticket_messages, app_settings, app_release_notes, analytics_events, user_local_sync_logs, vehicle_catalog_change_logs, admin_action_logs, privacy_requests, edge_function_idempotency_keys.

## 인증/온보딩
profiles는 `auth_provider`, `onboarding_completed`, `consent_completed`, `additional_setup_completed`, `vehicle_setup_completed`, `selected_fuel_league`, `selected_vehicle_class`를 가진다. Flutter 앱에는 Supabase anon key만 들어가며 service_role key는 Edge Function에서만 사용한다.

`profiles.tier`, `total_score`, `season_score`, `current_streak`, `best_streak`, `is_premium`, `is_admin`, `created_at`은 서버 제어 컬럼이다. authenticated client는 Google 로그인 복구와 설정 흐름에 필요한 identity/setup 컬럼만 insert/update할 수 있다.

`app_consents`는 사용자별 현재 약관, 개인정보, 위치, 맞춤형 광고, 마케팅 동의 상태를 저장한다. 최초 필수 동의 화면과 설정의 광고 동의 화면은 같은 repository를 사용해 `app_consents`를 갱신하고, 모든 변경은 `consent_logs`에 별도 감사 로그로 남긴다.

## 차량 카탈로그
vehicle_manufacturers → vehicle_models → vehicle_model_years → vehicle_variants 순서로 차량을 선택한다. variant는 판매 트림/휠 인치가 아니라 차종, 연식, 파워트레인 단위이며 user_vehicles는 사용자가 선택한 variant와 닉네임, 대표 차량 여부, 검증 상태, 연료 리그, 차급을 저장한다. 제조사 선택 카드는 `vehicle_manufacturer_catalog_view`의 `model_count`, `min_year`, `max_year`로 모델 수와 지원 연식 범위를 표시하고, variant 선택은 `vehicle_catalog_view`를 사용한다. 직접 입력 차량은 `custom_vehicle_requests.user_vehicle_id`로 검수 대상 `user_vehicles` row와 연결한다. `custom_vehicle_requests_self_insert` RLS는 `user_vehicle_id`를 필수로 요구하고 요청 사용자와 차량 소유자가 일치할 때만 연결 요청을 허용한다.

## 리그
fuel_leagues는 gasoline, diesel, hybrid, electric, lpg, plug_in_hybrid, other를 가진다. league_memberships는 대표 user_vehicle 기준의 활성 리그를 저장하며, rankings와 battles에도 fuel_league 조건을 보존한다.

## 민감 데이터
drive_points는 private table이며 사용자 본인만 접근한다. `is_mocked`는 모의 위치 신호 검증용 private field로만 사용한다. 공개 랭킹은 public_rankings view를 통해 제한 정보만 제공한다.

사용자 주행 기록/분석 화면은 `drive_sessions`와 `drive_scores`의 요약 row만 읽는다. 경로 재현에 필요한 `drive_points`의 좌표, 속도 샘플, 정확도 값은 분석 화면에 직접 노출하지 않는다.

## 공개 콘텐츠
sponsors, sponsor_challenges, advertisements, coupons는 public content로 분류하되 RLS를 켠다. 일반 사용자는 활성 기간과 만료 조건을 통과한 row만 읽고, 쓰기는 관리자 정책 또는 service role Edge Function으로 제한한다.

## Edge Functions
finish_drive_session, calculate_drive_score, verify_drive_session, update_rankings, settle_battle, grant_ad_reward, claim_season_reward, issue_coupon, update_mission_progress, process_fraud_review, send_notification, assign_vehicle_league, review_custom_vehicle, verify_purchase.

`finish_drive_session`은 로그인 사용자의 세션 ID와 요약 수치만 받아 private `drive_points`를 다시 읽고 거리, 시간, 속도, GPS 정확도, 모의 위치 신호를 서버에서 검증한다. 공식 주행 최소 거리/시간과 이상 속도 기준은 공개 `app_settings`에서 읽고, 검증 결과로 `drive_sessions`와 `drive_scores`를 service role 환경에서 갱신한다. `profiles.season_score`는 `verified` 점수일 때만 누적한다. Flutter 앱에는 `SUPABASE_SERVICE_ROLE_KEY`를 넣지 않는다.

`verify_purchase`는 앱이 받은 store verification data를 Edge Function으로 보내고, Edge Function이 Google Play Android Publisher API 또는 App Store Server API를 호출한다. `purchase_verifications`에는 raw receipt가 아니라 token hash, transaction id, 검증 상태, provider response summary만 저장한다.

`update_rankings`는 `ranking_update_jobs`를 만들거나 처리하고, 같은 기간의 pending/running job은 하나로 합쳐 운영 큐가 폭주하지 않게 한다. `recompute_rankings(period)` DB function은 verified `drive_scores`를 집계해 기간별 랭킹을 트랜잭션으로 재생성한다. 공개 화면은 계속 `public_rankings` view만 사용한다.

보상, 쿠폰, 미션, 배틀 정산 계열 Edge Function은 `x-idempotency-key` 또는 `idempotencyKey` 요청 값을 필수로 받아 `edge_function_idempotency_keys`에 저장한다. 같은 사용자, 함수, key, 요청 본문으로 재시도되면 저장된 응답을 반환하고, 같은 key가 다른 본문으로 재사용되면 409를 반환한다.

`grant_ad_reward`는 `app_settings.reward_ads_enabled`, `reward_ad_daily_limit`를 확인한 뒤 `ad_rewards`와 `analytics_events`를 기록한다. `update_mission_progress`는 `mission_progress`를 upsert하고, `claim_season_reward`는 완료된 미션의 `reward_claimed`를 변경한 뒤 `profiles.season_score`를 갱신한다. 시즌 승급 목표는 공개 `app_settings.season_promotion_target_score`로 조정한다. `issue_coupon`은 만료되지 않은 `coupons`를 `user_coupons`에 발급하고, `settle_battle`은 `battle_participants` 점수/결과와 `battles.status`를 갱신한다.

`send_notification`은 로그인 사용자의 알림 또는 관리자 대상 사용자 알림을 `notifications`에 저장한다. `isDriving = true` 요청은 `held_during_drive = true`로 저장해 앱이 주행 중 즉시 노출하지 않고 주행 종료 후 알림함에서 확인하도록 한다.

`crews`, `crew_members`는 RLS를 켜고 크루 소속자 또는 관리자만 읽을 수 있다. Flutter 앱은 `profiles` 전체 row를 직접 읽지 않고 `get_my_crew_summary`, `get_my_crew_members` RPC를 통해 본인 크루의 요약과 닉네임/역할/주간 기여도만 받는다.

`admin_action_logs`는 관리자 대시보드 액션 요청을 섹션, 액션, 대상 테이블/레코드, 당시 상태, 메타데이터와 함께 저장한다. 일반 사용자는 접근할 수 없고 관리자는 Supabase range query로 조회한다.

`get_admin_dashboard_metrics`는 관리자 전용 RPC로 DAU/MAU, 사용자, 주행 완료율, 검증 승인율, 배틀, 광고 보상, 프리미엄, 쿠폰, 문의/신고/부정 기록, 구매 검증, 운영 액션 집계를 제한된 metric row로 반환한다.

`report_items`는 사용자/주행/일반 공정성 신고와 주행 기록 이의제기 큐를 저장한다. 사용자는 본인 신고를 생성/조회하고, 관리자는 Reports 운영 섹션에서 조회/상태 변경한다. 신고 접수 화면과 검토 요청 화면은 고객지원 티켓을 남기면서 `report_items`도 함께 생성한다.

`support_tickets`는 사용자 문의 제목, 분류, 설명, 상태를 저장하고 `support_ticket_messages`는 사용자 추가 메시지와 관리자 답변을 저장한다. 관리자 답변은 `is_admin_reply = true`로 구분하며, 사용자 앱의 문의 상세 화면에서 같은 대화 타임라인으로 표시한다.

`privacy_requests`는 데이터 다운로드, 데이터 삭제, 계정 삭제, 동의 철회 요청을 별도 운영 큐로 저장한다. 사용자는 본인 요청만 생성/조회하고, 관리자는 Privacy Requests 섹션에서 `open`, `review`, `completed`, `rejected` 상태로 처리한다. 진행 중인 같은 유형의 개인정보 요청은 하나만 허용하며 `privacy_requests_active_type_uidx`가 `open`, `review` 중복을 막는다.

`app_settings`의 공개 seed는 `AppRemoteConfig`가 읽는 운영 설정이다. 광고 보상 일일 한도, 신규 유저 광고 보호 기간, 공식 주행 최소 거리/시간, 이상 속도 기준, 친선 배틀, 쿠폰 기능 플래그는 migration과 schema validator가 함께 누락을 검사한다.

## 스키마 검증
`dart run tool/validate_supabase_schema.dart`는 migration 묶음에서 필수 테이블, 생성된 모든 public table의 RLS 활성화, 핵심 정책, public view privacy, RPC 보안 속성, Edge 전용 RPC 권한, 중복 방지 index를 정적으로 검사한다.
