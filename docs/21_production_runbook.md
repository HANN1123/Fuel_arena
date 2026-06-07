# Production Runbook

## 1. 환경변수
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_ANDROID_CLIENT_ID`
- `GOOGLE_IOS_CLIENT_ID`
- `GOOGLE_SERVER_CLIENT_ID`
- `GOOGLE_REVERSED_IOS_CLIENT_ID`
- `APP_AUTH_REDIRECT_SCHEME`
- `APP_AUTH_REDIRECT_HOST`
- `ADMOB_ANDROID_APP_ID`
- `ADMOB_IOS_APP_ID`
- `ADMOB_REWARDED_ANDROID_UNIT_ID`
- `ADMOB_REWARDED_IOS_UNIT_ID`
- `ADMOB_NATIVE_ANDROID_UNIT_ID`
- `ADMOB_NATIVE_IOS_UNIT_ID`
- `ADMOB_INTERSTITIAL_ANDROID_UNIT_ID`
- `ADMOB_INTERSTITIAL_IOS_UNIT_ID`
- `IAP_PREMIUM_MONTHLY_ID`
- `IAP_PREMIUM_YEARLY_ID`
- `IAP_SEASON_PASS_ID`
- `IAP_PREMIUM_BUNDLE_ID`

service role key는 Flutter 앱에 넣지 않는다. Edge Function secret으로만 설정한다.

결제 검증 secret도 Flutter 앱에 넣지 않는다. Supabase Edge Function secret으로만 설정한다.

production의 `SUPABASE_URL`은 `https://<project-ref>.supabase.co` 형식이어야 한다. 형식이 잘못되거나 초기화가 실패하면 앱은 시작 단계에서 설정 오류 화면을 표시한다.
`SUPABASE_ANON_KEY`는 role claim이 `anon`인 3-part JWT여야 하며, IAP 상품 ID 네 개는 `subscription_plans` seed의 `fuel_arena_premium_monthly`, `fuel_arena_premium_yearly`, `fuel_arena_season_pass`, `fuel_arena_premium_bundle`와 정확히 일치해야 한다.

스토어 제출 전 공개 URL도 production env에 채운다.

- `PUBLIC_PRIVACY_POLICY_URL`
- `PUBLIC_LOCATION_NOTICE_URL`
- `PUBLIC_ACCOUNT_DELETION_URL`
- `PUBLIC_TERMS_URL`

Flutter client env와 Edge Function secret을 분리해 프리플라이트를 실행한다.

```bash
cp .env.production.example .env.production
cp .env.edge.production.example .env.edge.production
python tool/validate_release_environment.py --env-file .env.production --edge-secrets-file .env.edge.production
python tool/validate_release_environment.py --env-file .env.production --client-only --check-public-urls
python tool/validate_release_environment.py --env-file .env.production --edge-secrets-file .env.edge.production --check-public-urls --check-supabase-live
python tool/validate_release_example_placeholders.py
```

`--check-supabase-live`는 public REST seed/RLS, Edge Function CORS, Google OAuth provider, production web origin, `fuelarena://login-callback` redirect allow-list를 실제 Supabase endpoint로 확인한다.

로컬 릴리즈 게이트는 `.env.production.example`과 `.env.edge.production.example`이 placeholder 상태로는 반드시 실패하는지도 검사한다. 예제 파일이 통과한다면 실제 출시용 `.env.production`과 혼동될 위험이 있으므로 게이트를 실패로 처리한다.

`.env.production`에는 anon/public 값만 넣고, service role key, App Store private key, ranking job secret은 넣지 않는다. `.env.edge.production`은 로컬 검증용 secret 파일이며 저장소에 커밋하지 않는다.

```bash
supabase secrets set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON='<service-account-json-with-type-service_account>'
supabase secrets set APP_STORE_CONNECT_ISSUER_ID='<issuer-uuid>'
supabase secrets set APP_STORE_CONNECT_KEY_ID='<10-uppercase-key-id>'
supabase secrets set APP_STORE_CONNECT_PRIVATE_KEY='<p8-private-key>'
supabase secrets set APP_STORE_BUNDLE_ID='com.fuelarena.fuelArena'
supabase secrets set APP_STORE_ENV='production'
supabase secrets set ALLOW_MOCK_PURCHASE_VERIFICATION='false'
supabase secrets set RANKING_JOB_SECRET='<strong-random-secret>'
```

## 2. Supabase 적용
```bash
supabase link --project-ref <project-ref>
supabase db push
supabase functions deploy finish_drive_session
supabase functions deploy calculate_drive_score
supabase functions deploy verify_drive_session
supabase functions deploy update_rankings
supabase functions deploy settle_battle
supabase functions deploy grant_ad_reward
supabase functions deploy claim_season_reward
supabase functions deploy issue_coupon
supabase functions deploy update_mission_progress
supabase functions deploy process_fraud_review
supabase functions deploy assign_vehicle_league
supabase functions deploy review_custom_vehicle
supabase functions deploy verify_purchase
supabase functions deploy send_notification
```

## 3. 차량 카탈로그 import
```bash
dart run tool/validate_vehicle_catalog.dart
dart run tool/import_vehicle_catalog.dart --out supabase/seed_vehicle_catalog.sql
```

생성된 SQL을 production DB에 적용한 뒤 관리자 화면에서 제조사/모델/연식/파워트레인 variant 수를 확인한다. `supabase/seed_vehicle_catalog.sql`을 갱신하면 `supabase/migrations/202606060002_vehicle_catalog_seed.sql`도 같은 2008-2026 catalog seed로 동기화해야 한다.

## 4. 운영자 계정 생성
1. Google 로그인으로 운영자 계정 생성.
2. Supabase SQL editor에서 해당 profile의 `is_admin = true` 설정.
3. `/admin` 접속 후 full width dashboard 확인.
4. Users, Drive Sessions, Drive Scores, Support Tickets, Privacy Requests 섹션에서 페이지 이동과 상세 drawer를 확인.

## 5. RLS 검증
- 먼저 `dart run tool/validate_supabase_schema.dart`로 migration 묶음의 필수 table, RLS, policy, public view privacy, RPC 보안 속성, Edge 전용 RPC 권한, 중복 방지 index를 정적 검증한다.
- 일반 사용자가 타인의 `drive_points`를 읽지 못해야 한다.
- 안전 모드 종료 후 `drive_points`가 본인 세션에만 저장되고 공개 화면에는 좌표가 표시되지 않는지 확인한다.
- `drive_scores`는 세션당 1개만 생성되어야 하며, 결과 화면 새로고침 시 점수가 중복 누적되지 않아야 한다.
- `finish_drive_session`은 `app_settings.official_drive_min_distance_km`, `official_drive_min_duration_seconds`, `abnormal_speed_kmh`를 읽어 검증 기준으로 사용해야 한다.
- `finish_drive_session`으로 verified score 생성 후 `ranking_update_jobs`가 pending으로 생성되어야 한다.
- 같은 period에 pending/running `ranking_update_jobs`가 중복 생성되지 않고 하나의 active job으로 합쳐지는지 확인한다.
- `update_rankings` 호출 후 `ranking_update_jobs.status = completed`와 `public_rankings` 갱신을 확인한다.
- 보상/쿠폰/미션/배틀 Edge Function은 `Authorization: Bearer <jwt>`와 `x-idempotency-key`를 함께 보내 같은 요청 재시도 시 같은 응답을 반환하는지 확인한다.
- `grant_ad_reward`, `update_mission_progress`, `claim_season_reward`, `issue_coupon`, `settle_battle`는 성공 응답 후 관련 운영 테이블과 analytics event를 SQL editor에서 샘플 확인한다.
- `recompute_rankings(text)`, `claim_mission_reward(uuid, uuid)`는 public/anon/authenticated execute가 revoke되고 service_role execute만 허용되는지 확인한다.
- 네트워크 차단 상태에서 주행 포인트 업로드 실패 후 홈 진입/온라인 복귀 시 offline queue가 비워지는지 확인한다.
- 일반 사용자가 `vehicle_catalog_change_logs`를 읽지 못해야 한다.
- 관리자는 support tickets, reports, catalog change logs를 조회할 수 있어야 한다.
- 사용자가 `/support/review-request` 또는 주행 결과의 검토 요청 CTA로 제출한 이의제기가 Support Tickets와 Reports 양쪽에 생성되는지 확인한다.
- 관리자 Reports 섹션의 검토 완료 액션이 `report_items.status = resolved`로 저장되고 감사 로그가 남는지 확인한다.
- 관리자는 privacy_requests를 조회하고 데이터/계정 요청 상태를 변경할 수 있어야 한다.
- 관리자 Privacy Requests 섹션의 검토 시작, 완료 처리, 보류 처리 액션이 각각 `review`, `completed`, `rejected` 상태로 저장되는지 확인한다.
- 진행 중인 같은 유형의 privacy_requests는 `privacy_requests_active_type_uidx`로 중복 생성되지 않아야 한다.
- `custom_vehicle_requests`는 본인과 관리자만 조회 가능해야 한다.
- `custom_vehicle_requests_self_insert`는 `user_vehicle_id`를 필수로 요구하고 해당 row가 요청자의 `user_vehicles`인지 확인해야 하며, 연결 ID가 없거나 다른 사용자의 차량 ID를 연결한 insert는 거부되어야 한다.
- 관리자 차량 카탈로그 검수 큐에서 직접 입력 차량 승인/반려가 `review_custom_vehicle`을 호출하고 `custom_vehicle_requests.user_vehicle_id`와 검수 대상 `user_vehicles.id`, 요청 사용자와 차량 소유자 일치 여부를 검증한 뒤 `custom_vehicle_requests.status`, `user_vehicles.verification_status`, `notifications.notification_type = vehicle_review` row를 함께 갱신해야 한다.
- 관리자 repository pagination은 `.range()` 쿼리로 동작하므로 테이블별 admin select policy를 수동 검증한다.

## Profile self-write hardening
- Confirm authenticated clients cannot insert or update `tier`, `total_score`,
  `season_score`, `current_streak`, `best_streak`, `is_premium`, `is_admin`,
  or `created_at` on `profiles`.
- Those fields are server-controlled and must only be changed by Edge
  Functions, admin operations, or trusted backend jobs.

## 6. Google OAuth
- Supabase Google provider에 Web client id/secret을 등록하고 Google provider를 활성화.
- Web은 Supabase OAuth redirect를 사용하므로 production/staging Web origin과 로컬 검증 URL을 Supabase Redirect URL allow list에 등록.
- Android/iOS는 Google ID token/access token을 Supabase `signInWithIdToken(OAuthProvider.google)`로 교환하는지 실제 계정으로 확인.
- release preflight의 `--check-supabase-live`가 web origin과 `fuelarena://login-callback` authorize URL 모두에서 `accounts.google.com` redirect를 확인해야 한다.
- Android package `com.fuelarena.fuel_arena`와 SHA-1/SHA-256 등록.
- iOS Bundle ID `com.fuelarena.fuelArena`와 reversed client id URL scheme 등록.
- `ios/Flutter/FuelArenaSecrets.xcconfig.example`를 `FuelArenaSecrets.xcconfig`로 복사하고 `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID`, `GOOGLE_REVERSED_IOS_CLIENT_ID`, `ADMOB_IOS_APP_ID`를 채운다.
- 실제 `FuelArenaSecrets.xcconfig` 파일은 git에 커밋하지 않는다.

## 7. AdMob
- Android release signing은 `android/key.properties.example`를 `android/key.properties`로 복사한 뒤 실제 upload keystore 경로와 비밀번호를 채워 설정한다.
- `android/key.properties`, `.jks`, `.keystore` 파일은 저장소에 커밋하지 않는다.
- Release 빌드는 `ADMOB_ANDROID_APP_ID`를 Gradle property 또는 환경 변수로 전달해야 한다.
- debug placeholder를 release에 남기지 않는다.
- 주행 중 광고가 표시되지 않는지 QA한다.
- 광고 실패 시 기본 보상이 지급되는지 확인한다.

- Android/iOS 실제 기기에서 AdMob 리워드 광고 완료 콜백(`onUserEarnedReward`)을 받은 뒤에만 `grant_ad_reward`가 호출되고, 중도 종료/로드 실패/단위 ID 누락 시 보상 지급이 막히는지 확인한다.

## 8. IAP
- `subscription_plans` seed에는 `fuel_arena_premium_monthly`, `fuel_arena_premium_yearly`, `fuel_arena_season_pass`, `fuel_arena_premium_bundle`가 모두 있어야 한다. 스토어 상품 ID, release env, Edge Function 검증 값은 이 ID들과 일치해야 한다.
- 상품 id를 Play Console/App Store Connect에 등록한다.
- purchase restore와 subscription expiration을 실제 store sandbox에서 검증한다.
- `verify_purchase`는 Google Play Android Publisher API와 App Store Server API를 호출하므로 provider secret과 product id 매칭을 먼저 확인한다. Google Play package name은 Edge Function의 서버 고정값 `com.fuelarena.fuel_arena`를 사용하고, 클라이언트가 보낸 package name은 신뢰하지 않는다.

## 9. 장애 대응
- Supabase 장애: 앱은 dev/mock fallback이 아니라 production 오류/재시도 UI를 보여준다.
- Edge Function 장애: 점수/보상 확정은 pending 상태로 보류하고 재시도 큐에 남긴다.
- drive_points 업로드 장애: 앱은 batch를 local offline queue에 저장하고, 연결 복구 후 성공 항목만 제거한다.
- `finish_drive_session` 장애: production에서는 mock score로 화면 흐름을 유지하지 않고 결과 화면을 오류/재시도 상태로 남긴다. 운영 로그와 `drive_sessions.status`를 우선 확인한다.
- 차량 import 오류: `tool/validate_vehicle_catalog.dart` 결과와 `vehicle_catalog_change_logs`를 우선 확인한다.

## 10. 롤백
- DB migration은 Supabase backup/PITR 기준으로 롤백한다.
- Edge Function은 이전 배포 아티팩트를 재배포한다.
- 앱 release는 스토어 staged rollout을 중단하고 이전 빌드로 되돌린다.
## Production Failure Policy
- production에서 `finish_drive_session` 장애 또는 공식 세션 누락이 발생하면 mock score로 화면 흐름을 유지하지 않는다. 결과 화면은 오류/재시도 상태로 남기고 운영 로그와 `drive_sessions.status`를 확인한다.
- production에서 사용자별 프로필/통계 조회가 실패하면 mock 사용자 데이터를 표시하지 않는다. dev/staging에서만 mock fallback을 허용한다.

## Production Auth Consent Fallback
- production에서 Google OAuth, Supabase Auth, `app_consents`, `consent_logs` 저장이 실패하면 mock 로그인/동의 데이터를 표시하거나 저장하지 않는다. 설정 오류 화면, 로그인 오류, 동의 저장 실패 상태로 노출하고 Supabase Auth provider, Google OAuth client ID, RLS, migration 적용 상태를 확인한다.

## Production Vehicle Catalog Fallback
- production에서 차량 설정이 실패하면 mock 차량 카탈로그 seed로 대체하지 않는다. `vehicle_manufacturers`, `vehicle_models`, `vehicle_model_years`, `vehicle_variants`, `vehicle_manufacturer_catalog_view`, `vehicle_catalog_view`, `fuel_leagues`, `custom_vehicle_requests`, `user_vehicles` migration/seed 적용 상태와 RLS 정책을 확인하고, `dart run tool/validate_vehicle_catalog.dart`, `dart run tool/validate_supabase_schema.dart`를 다시 실행한다.

## Production Core Experience Fallback
- production에서 홈, 시즌, 주행 기록/점수, 대표 차량, 오늘의 미션 조회가 실패하면 mock 홈/시즌/주행 데이터를 표시하지 않는다. 실제 데이터가 비어 있으면 빈 상태용 중립 데이터를 보여주고, 인증 누락 또는 Supabase 쿼리 실패는 오류/재시도 상태로 확인한다.

## Production Operational Data Fallback
- production에서 스폰서 챌린지, 쿠폰, 알림, 고객지원, 신고, 개인정보 요청, 크루, 관리자 운영 데이터가 조회/저장 실패하면 mock 운영/콘텐츠 데이터를 표시하지 않는다. Supabase seed, RLS, Edge Function 배포, 관리자 권한을 먼저 확인하고 dev/staging에서만 mock fallback을 허용한다.

## Staging Runtime Policy
- staging은 production 전 배포 검증 환경이므로 Supabase URL과 anon key가 필수다. Supabase가 없는 mock repository 실행은 dev mode에서만 허용한다.

## Premium Plan Fallback Policy
- production에서는 `subscription_plans` 조회 실패 또는 빈 결과를 mock 프리미엄 요금제로 대체하지 않는다. 결제 화면이 빈 상태를 보여주면 Supabase seed/RLS와 스토어 상품 ID를 먼저 확인한다.
