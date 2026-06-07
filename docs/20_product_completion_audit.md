# Product Completion Audit

## 1. 현재 구현 완료된 기능
- Google 중심 로그인 화면, dev/mock Google login fallback, production 설정 오류 화면.
- 온보딩, 동의, 권한 안내, 추가 설정, 차량 설정, 홈 진입 흐름.
- 필수 동의와 광고/마케팅 선택 동의가 `app_consents` 현재값과 `consent_logs` 감사 로그로 저장되는 흐름.
- 사용자 앱 `MobileViewportShell` 기반 430px 이하 모바일 폭 제한.
- Flutter Web hash route(`#/home`)에서 AppScaffold/메인 탭 SafeArea 중첩으로 하단 탭만 보이고 본문이 비는 런타임 회귀를 수정했다. `AppScaffold`는 SafeArea 없이 viewport shell을 적용하고, 홈/배틀/랭킹/시즌/프로필 탭은 356px 이상에서 5개가 모두 보이는 앱 전용 compact bottom navigation으로 처리한다.
- 관리자 route `AdminViewportShell` 기반 full width 운영 화면.
- 제조사, 모델/파생모델, 기준 연식, 엔진·미션 파워트레인 선택과 직접 입력 차량 검토 요청 흐름.
- 연료 리그: 가솔린, 디젤, 하이브리드, 전기차, LPG, 플러그인 하이브리드, 기타.
- 홈, 주행 시작, 안전 모드, 주행 결과, 랭킹, 배틀, 시즌, 프로필, 통계, 리워드, 스폰서, 프리미엄, 설정, 공정성, 알림, 고객지원, 이의제기 화면.
- 오프라인/동기화/로컬 상태/보안 저장/앱 lifecycle 서비스와 주행 포인트 재시도 큐.
- Supabase repository와 mock fallback 분리.
- 알림 repository는 Supabase 설정 시 `notifications`를 읽고 개별/전체 읽음 처리를 수행하며 빈 상태 UI를 제공한다.
- 크루 화면은 본인 크루 요약과 크루원 주간 기여도를 repository/RPC 기반으로 렌더링한다.
- support tickets/messages, analytics events, app settings, vehicle catalog change logs migration/RLS.
- Edge Functions 공통 CORS, response, error, validator 구조. Web idempotency 요청을 위해 공통 CORS는 `x-idempotency-key` preflight header를 허용한다.
- Android debug APK와 Web build가 가능한 host scaffold.

## 2. 외부 설정과 운영 검증이 남은 기능
- Google OAuth, AdMob, IAP, Supabase production secrets는 외부 콘솔 설정 전까지 dev/mock 상태.
- 실제 위치 stream 기반 drive_points batch insert, 서버 측 GPS point filtering, 주행 종료 점수 확정, 업로드 실패 재시도 큐와 item 단위 `user_local_sync_logs` 운영 로그를 보강했다.
- 손상된 오프라인 주행 포인트 payload와 지원하지 않는 legacy queue item은 `discarded` 운영 로그로 남기고 queue에서 제거해 무한 재시도와 잘못된 uploaded 집계를 방지한다.
- 로컬 `offline_queue` 저장소가 깨진 경우 원본 raw 값을 `offline_queue_corrupt_backup`에 백업하고 정상 item만 살려 앱 시작/동기화 흐름이 중단되지 않게 했다.
- 결제 검증은 `verify_purchase` Edge Function에서 Google Play Android Publisher API와 App Store Server API를 호출하는 구조로 보강했다. Google Play package name은 서버 상수로 고정하고 App Store Bundle ID는 secret으로만 읽어 클라이언트 입력을 신뢰하지 않는다. 실제 sandbox/live 검증은 provider secret과 스토어 상품 설정 이후 확인해야 한다.
- 관리자 상세 drawer와 운영 목록 pagination은 repository 기반으로 보강했다. production에서는 Supabase RLS/admin policy 적용 후 주요 운영 테이블을 range query로 조회한다.
- 차량 공식 효율 값은 검증된 데이터가 없으면 null이며, 운영 import 후 보강해야 한다.

## 3. 실제 사용 흐름에서 끊기는 지점
- production Supabase migration/Edge Function deploy가 되지 않으면 실제 저장/정산 기능이 동작하지 않는다. dev/mock mode에서만 fallback으로 흐름을 유지한다.
- 차량 직접 입력은 검수 대기 상태로 저장되며, 운영자 승인 알림은 `send_notification` 배포 후 실제 알림 row 생성까지 확인해야 한다.
- 앱스토어/플레이스토어 결제 상품이 없으면 모바일 실결제는 시작할 수 없고, dev/mock 모드에서만 구매 검증 fallback이 동작한다.

## 4. 빈 화면 또는 placeholder 관리
- 차량 연식/variant 검색 결과 없음은 직접 입력 CTA로 보강했다.
- 관리자 카탈로그 import/export는 로컬 도구 명령 안내와 무결성 검사 진입점으로 보강했다.
- 문서와 release checklist에는 향후 작업 문구가 남아도 되지만 사용자 UI에는 단순 준비 중 화면을 남기지 않는 기준을 유지한다.

## 5. 버튼이 있지만 동작하지 않는 기능
- 주요 CTA는 route 이동, repository 호출, dialog, snackbar 중 하나를 수행한다.
- 외부 콘솔 설정이 필요한 광고/결제/운영 import는 mock 동작 또는 명령 안내 dialog로 연결했다.

## 6. Supabase 연결 상태
- Supabase가 설정되면 주요 repository가 SupabaseRepository로 전환된다.
- 직접 입력 차량 요청은 `custom_vehicle_requests`와 `user_vehicles` 검수 대기 insert 구조로 보강했다.
- 직접 입력 차량 요청은 `custom_vehicle_requests.user_vehicle_id`로 `user_vehicles`와 연결하고, insert RLS에서 연결 ID 필수 여부와 요청자 소유 여부를 확인한다. 관리자 차량 카탈로그 검수 큐에서 승인/반려 시 `review_custom_vehicle` Edge Function으로 요청 상태, 차량 검증 상태, 사용자 `vehicle_review` 알림을 함께 변경한다.
- 홈 화면 Supabase snapshot은 프로필/대표 차량/배틀뿐 아니라 현재 시즌, 미션 진행률, 최근 주행 점수, 스폰서 챌린지를 실제 repository/DB 조회로 조립한다.
- 통계 화면은 Supabase 설정 시 `drive_sessions`, `drive_scores`, `public_rankings`, `profiles.current_streak`를 기반으로 평균 연비, 검증 주행, 동급 백분위, 누적 거리, 연속 주행을 계산한다.
- 프로필 화면은 Supabase 설정 시 `user_badges`와 `badges`, `achievements`와 `user_achievements`를 조합해 실제 배지와 업적 진행률을 표시한다.
- 광고 보상, 쿠폰 발급, 미션 진행률/보상 수령, 배틀 정산은 Edge Function을 통해 관련 테이블과 analytics event를 갱신한다.
- 시즌 화면은 Supabase 현재 시즌, 미션, 사용자별 `mission_progress`를 읽고 완료 미션은 `claim_season_reward`로 수령한다.
- 구매 검증과 점수 확정은 앱이 직접 민감 테이블을 쓰지 않고 `verify_purchase`, `finish_drive_session`을 호출한다.
- 점수 확정은 dev/staging에서만 mock fallback을 허용한다. production에서는 공식 세션 또는 Edge Function 검증이 실패하면 mock 점수를 반환하지 않고 결과 화면의 재시도 오류 상태로 남긴다.
- 일반 알림 생성은 `send_notification` Edge Function이 담당하고, 직접 입력 차량 검수 결과는 `review_custom_vehicle`이 `vehicle_review` 알림 row를 남긴다. Flutter 앱은 자신의 `notifications` row만 읽음 처리한다.
- 크루 데이터는 앱이 `profiles` 전체 row를 읽지 않고 `get_my_crew_summary`, `get_my_crew_members` RPC로 제한된 필드만 조회한다.
- 관리자 metric card는 `get_admin_dashboard_metrics` RPC로 실제 운영 집계 row를 읽는다.
- 관리자 대시보드 액션은 `admin_action_logs`에 기록되고 Admin Actions 섹션에서 조회된다.
- 신고와 이의제기 제출은 고객지원 티켓과 `report_items`를 함께 생성하고, 관리자 Reports 섹션에서 range query로 조회한다.
- 동의 저장소는 Supabase 설정 시 `app_consents`를 upsert하고 `consent_logs`를 insert하며, dev/mock mode에서는 동일한 현재값과 감사 로그를 메모리 저장소로 검증한다.

## 7. Mock fallback을 유지하는 기능
- 관리자 운영 목록과 액션 감사 로그는 mock fallback과 Supabase range query를 함께 제공한다. 남은 항목은 production 권한 수동 검증이다.
- 프리미엄 구매는 `in_app_purchase` purchase stream과 Edge Function 검증 경로를 사용한다. 남은 항목은 store sandbox에서 restore, 만료, 환불 케이스를 검증하는 것이다.
- production에서는 IAP/스토어 영수증 검증 없이 mock premium을 활성화하지 않는다. dev/staging fallback만 mock 구매 UX를 유지한다.
- 광고 SDK, Google OAuth, 스토어 결제는 외부 콘솔 설정 전까지 dev/mock fallback으로 UX 흐름을 유지한다.

## 8. 테스트가 없는 핵심 기능
- 차량 카탈로그 asset integrity는 `tool/validate_vehicle_catalog.dart`로 검증한다.
- 직접 입력 차량 요청, 관리자 full-width layout, 356/390/430/1920 모바일 폭 제한, app bar/bottom bar 폭 제한, compact bottom navigation 5탭 표시, core route smoke, ErrorMapper 한국어 사용자 문구, 연료 타입별 입력값 검증, offline queue 보존/상한, 주요 mock repository 흐름은 widget/unit 테스트로 검증한다.
- Edge Function 공통 CORS/응답/error/idempotency 구조와 `x-idempotency-key` preflight header 허용 여부는 `tool/validate_edge_functions.dart` smoke validator로 검증한다.
- Supabase migration 묶음의 필수 table, RLS, 핵심 policy, public view privacy, RPC 보안 속성, Edge 전용 RPC 권한, 중복 방지 index, 직접 입력 차량 요청의 본인 차량 연결 정책은 `tool/validate_supabase_schema.dart`로 검증한다.
- service role 비밀값, `.env` 번들링 차단, 사용자 화면 폭 제한, `AppLayout`/`AppIconSize`/`AppCardSize` 토큰, compact manufacturer card, AppScaffold 우회 방지, core route smoke coverage, 사용자 presentation/widget placeholder 문구 방지, 사용자 주요 화면 빈 상태 복구 CTA, 공개 화면 좌표/raw drive_points 노출 방지, 비현금 배틀 보상, analytics 민감 키 제거, 공개 랭킹 privacy, drive_points RLS, 직접 의존성 version range, Android/iOS 권한 선언, Android release signing/AdMob gate, iOS scaffold와 secret xcconfig, CI 명령, 릴리스 문서, runbook Edge Function deploy 목록과 환경 변수 템플릿은 `tool/validate_product_invariants.dart`로 검증한다.
- 추가로 필요한 테스트: production Supabase 배포 후 RLS 수동/자동 검증, store sandbox/live 결제 검증.

## 9. RLS 보강 상태
- `custom_vehicle_requests`, `ad_rewards`, `subscription_plans` RLS를 추가했다.
- `custom_vehicle_requests_self_insert`는 연결 ID가 없거나 다른 사용자의 `user_vehicle_id`를 연결한 요청 insert를 차단하도록 보강했다.
- `profiles` self-write hardening migration을 추가해 authenticated client가 점수, streak, premium, admin, tier, created_at 컬럼을 직접 insert/update하지 못하게 하고, Google 로그인 프로필 복구는 안전한 identity/setup 컬럼만 쓰도록 제한했다.
- `tool/validate_supabase_schema.dart`가 생성된 모든 public table의 RLS 활성화를 검사하므로 새 table 추가 시 RLS 누락을 CI에서 차단한다.
- production 적용 후 `profiles.is_admin` 기반 admin policy와 service role 함수 동작을 Supabase SQL editor에서 수동 검증해야 한다.

## 10. Edge Function 운영 검증
- 기존 필수 함수는 존재한다.
- `grant_ad_reward`, `update_mission_progress`, `claim_season_reward`, `issue_coupon`, `settle_battle`은 idempotency key를 필수로 받고 실제 DB mutation을 수행한다.
- production 리워드 광고는 광고 시청 검증 없이 클라이언트가 바로 `grant_ad_reward`를 호출하지 않는다. dev/staging fallback에서만 직접 지급 UX를 유지하고, production은 광고 SDK/서버 검증 전까지 보상 버튼을 닫는다.
- `send_notification`은 로그인 사용자 알림 또는 관리자 대상 사용자 알림을 `notifications`에 저장하고 주행 중 보류 플래그를 응답한다.
- `tool/validate_edge_functions.dart`가 14개 함수의 CORS, `x-idempotency-key` preflight header, POST 제한, 공통 응답/error helper, service role 중앙화, idempotency 필수 함수 구조, `review_custom_vehicle`의 decision 검증, 요청-차량/소유자 무결성 검증, 결과 알림 생성, `finish_drive_session`의 app_settings 기반 검증 기준, 광고 보상 일일 한도 범위 제한, `verify_purchase`의 App Store Bundle ID secret 필수화와 Google Play package name 서버 고정을 정적 smoke test로 확인한다.
- 남은 항목: store sandbox/live 운영 검증, Supabase production deploy 검증.

## 11. 앱스토어/플레이스토어 출시 전 필요한 항목
- Android release upload keystore 생성 및 `android/key.properties` 로컬 설정, package name 확정, Google OAuth SHA-1/SHA-256, Android OAuth callback URI, production `ADMOB_ANDROID_APP_ID`.
- `package_info_plus` upstream KGP 직접 적용 경고가 해소된 버전이 나오면 의존성 갱신 후 Android build warning이 사라지는지 확인.
- iOS Bundle ID, URL scheme, Google iOS client, `FuelArenaSecrets.xcconfig`, 위치 권한 문구, ATT 필요 여부, App Store IAP.
- 개인정보 처리방침/위치정보 고지/계정 및 데이터 삭제/서비스 이용약관은 Web 정적 페이지와 앱 내부 legal route로 준비했으며, 실제 출시 전 배포 도메인 연결이 필요하다.
- `tool/validate_release_environment.py`로 production Flutter client env, store legal URL, Edge Function 구매 검증 secret, test AdMob ID/placeholder/service role key 혼입 여부를 제출 전에 확인한다.

## 12. 이번 작업에서 바로 수정한 항목
- 대형 차량 카탈로그 seed JSON/CSV 생성.
- 차량 catalog import/validate tool 추가.
- mock vehicle catalog repository가 asset seed를 읽도록 보강.
- `VehicleVariant.efficiencyUnit`과 전기차 `km/kWh` 표시 보강.
- 차량 variant 선택 화면에서 verified catalog만 노출하도록 조정했다. placeholder `스탠다드/프리미엄 + 연료 타입` variant는 숨기고, 2008-2026 연식 전체를 판매 트림이 아닌 파워트레인 단위로 구조화했다. 휠 인치수와 스마트/모던/프레스티지 같은 판매 등급은 공식 리그 분류명에 포함하지 않는다.
- 차량 기준 연식 선택은 연식 칩 그리드 대신 클릭 후 하단에서 펼쳐지는 피커/스크롤 리스트로 바꿨다. 사용자는 제조사와 K3/K3 GT 같은 모델·파생모델을 고른 뒤 기준 연식을 선택하고, 이후 1.6, 1.6 디젤, 1.6T, IVT, 7단 DCT ISG, 수동 6단처럼 엔진·미션 차이가 있는 파워트레인만 선택한다. 화면에는 `K3 세대` 같은 표현을 노출하지 않고, 모델명과 기준 연식, 파워트레인명만 보여준다.
- runtime fallback 차량 카탈로그와 mock 가입 테스트도 현재 아반떼 2026 파워트레인 ID로 맞췄고, product invariant validator가 오래된 `model-avante`, `variant-avante-2024-*`, 판매 트림형 아반떼 row의 재도입을 막는다.
- `tool/validate_vehicle_catalog.dart`는 verified variant에 판매 트림명, 배기량/배터리 누락, 변속기/구동방식 누락이 있으면 실패한다. 공식 효율은 확인된 항목만 값으로 보유하고 미확인 항목은 null을 허용한다.
- 차량 설정 widget test는 `기아 → K3 GT → 2024년식 → 1.6T 가솔린 DCT` 경로를 직접 검증하고, `세대`, `스마트`, `모던`, `인스퍼레이션`, `인치` 문구가 선택 축에 노출되지 않는지 확인한다.
- 직접 입력 차량 제출 화면과 route 추가.
- `custom_vehicle_requests` migration/RLS 추가.
- `finish_drive_session` Edge Function 추가 및 주행 결과 화면과 Supabase repository 연결.
- `finish_drive_session`이 공식 주행 최소 거리/시간과 이상 속도 기준을 하드코딩하지 않고 `app_settings`에서 읽도록 보강.
- `grant_ad_reward`가 원격 `reward_ad_daily_limit` 값을 0~20 범위에서만 사용하도록 보강.
- 안전 모드 GPS position stream, 거리 계산, private `drive_points` batch 저장 경로 추가.
- `drive_points.is_mocked`, 서버 측 거리/시간/속도/정확도/모의 위치 검증, `drive_scores` 세션별 중복 방지 migration 추가.
- 주행 포인트 업로드 실패 batch를 offline queue에 저장하고 온라인 복귀 후 repository로 재전송하는 `SyncService` 경로 추가.
- 오프라인 주행 시작은 `local-drive-*` 세션을 큐에 보관하고, 온라인 복귀 시 `uploadQueuedDriveSession`으로 서버 세션을 먼저 만든 뒤 뒤따르는 포인트 batch의 `drive_session_id`를 서버 ID로 재매핑한다. 세션 업로드 후 포인트 업로드가 실패해도 `offline_drive_session_id_map`에 매핑을 보존해 다음 동기화에서 같은 batch를 서버 세션 ID로 재시도하며, 로컬 포인트 ID는 Supabase uuid 컬럼과 충돌하지 않도록 서버 insert payload에서 제외한다.
- 관리자 운영 목록 `AdminRecordPage`, repository pagination, row detail drawer, page navigation 추가.
- `purchase_verifications` migration, provider transaction id 저장, Google Play/App Store receipt verification Edge Function, Premium 화면 IAP purchase stream, 구매 복원, productId 기반 plan 복구를 연결했다.
- `ranking_update_jobs`, `recompute_rankings` DB transaction, `update_rankings` job processor, verified score 랭킹 큐 enqueue 추가.
- 배틀 생성 화면이 선택한 상대/규칙/기간/대표 차량 조건으로 `battles`와 `battle_participants`를 생성하도록 repository 연결 추가.
- 배틀 결과 화면의 미정산 상태에서 `BattleRepository.settleBattle`을 통해 `settle_battle` Edge Function을 호출하고, 정산 성공 후 상세/목록 provider와 analytics 이벤트를 갱신하도록 연결했다.
- 홈 Supabase snapshot이 현재 시즌/미션/최근 주행/스폰서 챌린지를 실제 데이터로 조립하도록 보강.
- 통계 화면 Supabase repository를 실제 주행/점수/랭킹/프로필 데이터 기반 지표로 보강.
- 프로필 배지/업적 Supabase repository와 빈 상태 UI, badges/achievements read/admin-write RLS 추가.
- sponsors, sponsor_challenges, advertisements, coupons public content RLS와 관리자 write policy 추가.
- 차량 미설정 홈의 무동작 보조 CTA를 공정성 기준 화면으로 연결.
- 관리자 차량 카탈로그 full-width, import/export/integrity tooling panel 추가.
- public viewport shell 명명 추가: `MobileViewportShell`, `ResponsiveAppShell`, `AdminViewportShell`.
- `edge_function_idempotency_keys`, 중복 쿠폰 정리 후 unique index, 시즌 승급 목표 app setting 추가.
- 보상/쿠폰/미션/배틀 Edge Function을 idempotent 실제 mutation 흐름으로 보강.
- Supabase 시즌 repository가 현재 시즌, 미션 진행률을 읽고 완료 미션 보상 수령을 호출하도록 연결.
- 미션 카드에 완료/보상 완료 상태와 보상 수령 액션 추가.
- Supabase 알림 repository, 전체 읽음 처리, 주행 중 보류 표시, 빈 알림 상태, `send_notification` DB insert 흐름 추가.
- Supabase 크루 repository, 크루 RLS/RPC, 크루 화면 실제 데이터 렌더링, 크루 widget/unit 테스트 추가.
- 관리자 액션 로그 repository, `admin_action_logs` RLS/migration, Admin Actions 조회 섹션, 관리자 액션 widget/unit 테스트 추가.
- 관리자 metric repository, `get_admin_dashboard_metrics` RPC, 운영 지표 집계 문서/RLS 테스트 항목 추가.
- 신고 repository, `report_items` 관리자 RLS/migration, 주행 신고 대상 표시, 신고 unit/widget/migration smoke 테스트 추가.
- 관리자 Reports 섹션은 실제 report_items 큐를 읽고 검토 완료 액션으로 `resolved` 상태를 저장하도록 repository/UI/widget 테스트를 보강했다.
- 검토 요청 전용 화면, 주행 결과/공정성 센터 CTA, `review_request_submitted` 분석 이벤트, support ticket + report queue 제출 widget 테스트 추가.
- 고객지원 상세 route, 문의 메시지 타임라인, 관리자 `is_admin_reply` 답변/처리 완료 액션, 지원 티켓 operation migration, unit/widget/migration smoke 테스트 추가.
- 개인정보 설정 요청 접수 UI, `privacy_requests` repository/migration/RLS, 관리자 Privacy Requests 상태 처리, unit/widget/migration smoke 테스트 추가.
- 개인정보 설정에서 데이터 다운로드, 데이터 삭제, 계정 삭제, 동의 철회 요청을 모두 접수하도록 연결.
- 앱 내부 `/legal/:document` route와 Web 정적 `/legal/privacy/`, `/legal/location/`, `/legal/account-deletion/`, `/legal/terms/` 페이지를 추가해 개인정보 처리방침, 위치정보 이용 고지, 계정 삭제 안내, 서비스 이용약관을 앱과 스토어 제출 URL 양쪽에서 확인할 수 있게 했다.
- 진행 중인 같은 유형의 개인정보 요청은 하나만 허용하고, 앱 화면은 중복 접수 대신 진행 중 상태와 요청 내역 확인 안내를 표시하도록 repository/UI/migration/test를 보강했다.
- 관리자 Privacy Requests 섹션은 실제 개인정보 요청 큐를 읽고 `open`, `review`, `completed`, `rejected` 필터와 검토 시작/완료 처리/보류 처리 액션으로 상태를 변경하도록 연결했다.
- 동의 repository, 필수 동의 저장, 광고/마케팅 설정 저장, Consent Logs 관리자 섹션, unit/widget 테스트 추가.
- 사용자에게 보이는 `mock`, `준비 중`, `임시 저장` 표현을 제품 문구로 정리하고 광고 보상 화면을 실제 리워드 화면 명칭으로 변경.
- 설정 로그아웃이 `AppSessionService.signOut()`을 호출해 인증 세션, 보안 세션 힌트, 사용자별 동의/차량/랭킹/활성 주행/결과 캐시, 오프라인 동기화 queue, 세션 ID 매핑, 손상 queue 백업을 정리하도록 연결.
- `/drive/history`, `/drive/analysis/:sessionId`를 static 안내 화면에서 `DriveRepository` 기반 최근 주행/점수 분석 화면으로 교체하고, 검토 요청 CTA와 공개 제한 안내를 연결했다.
- `/ranking/detail`을 static 안내에서 대표 차량 기반 내 리그 랭킹 상세 화면으로 교체하고, 상위 랭커/내 주변 순위/공개 제한 안내를 연결했다.
- `/battle/detail/:battleId`, `/battle/result/:battleId`를 `BattleRepository.getBattleById` 기반 단일 조회 흐름으로 고정하고, dev/mock mode에서 생성한 배틀도 상세 화면으로 이어지도록 mock 저장소 상태를 유지한다.
- `/profile/:userId`를 static 안내에서 `public_rankings` 기반 공개 프로필 화면으로 교체하고, 이메일/정확한 위치/상세 경로/raw drive_points 미노출 안내와 배틀/신고 CTA를 연결했다.
- 라이벌 화면을 static 안내에서 공개 랭킹 기반 내 위치/추월 목표 화면으로 교체하고, 공개 랭킹 필드만 렌더링하도록 정리했다.
- 배틀 상세/결과와 스폰서 챌린지 상세가 사라진 ID를 첫 번째 데이터로 대체하지 않고 명확한 빈 상태와 목록 CTA를 표시하도록 고정했다.
- 상세 route가 path parameter 누락 시 `battle-001`, `user-001`, `sponsor-001` 같은 예시 ID를 주입하지 않고 빈 ID를 넘겨 명확한 복구 상태로 진입하도록 라우터와 invariant를 보강했다.
- 안전 모드 설정에서 주행 중 알림 보류, 광고 차단, 자동 안전 모드는 끌 수 없는 보호 정책으로 잠그고, 종료 확인은 로컬 설정에 따라 팝업 없이 인라인 2단계 버튼으로 처리한다.
- 차량 관리 화면에 보유 차량 목록, 대표 차량 지정, 삭제 확인 다이얼로그, 실제 repository 삭제, 프로필 대표 차량 필드 정리, provider 갱신 흐름을 연결.
- 직접 입력 차량 요청 화면의 pending review 생성, 관리자 차량 카탈로그 검수 큐 승인, 제출 후 홈 이동 widget 테스트 추가.
- 온보딩의 영어 CTA를 한국어 제품 문구로 정리했다.
- 프리미엄/안전 모드/고객지원 FAQ 화면의 사용자 배지와 app bar 라벨을 한국어 우선 문구로 정리하고, `Premium`, `Safety Mode`, `FAQ 보기` 같은 라벨형 영어가 재도입되지 않도록 widget test와 product invariant validator를 보강했다.
- 관리자 대시보드는 내부 section key를 유지하면서 사이드바, app bar, 검색 힌트, 차트, 상세 drawer의 표시명을 `관리자`, `운영 대시보드`, `시스템 개요`, `개인정보 요청`, `신고/이의제기` 같은 한국어 운영 문구로 매핑했다.
- Flutter 기본 아이콘을 Fuel Arena 전용 브랜드 마크로 교체했다. `tool/generate_brand_assets.py`가 원본 1024px 아이콘, Flutter splash asset, Android mipmap icon, Android launch mark, iOS app icon/launch image, Web/PWA icon과 favicon을 한 번에 생성하며, Android/iOS launch splash도 제품 배경색과 브랜드 마크를 사용한다.
- 통계, 리워드 지갑, 스폰서 챌린지, 프리미엄 화면의 빈 데이터/오류/로딩 상태를 분리하고 실제 route CTA와 widget 테스트로 복구 경로를 고정했다.
- 주행 준비 화면의 대표 차량/오늘의 미션/위치 권한 readiness Future를 State에 고정하고 오류 상태를 `MappedErrorStateView`로 분리해, 저장소나 권한 조회 실패가 무한 로딩처럼 보이지 않도록 했다.
- 리워드 지갑의 쿠폰 발급 버튼을 `CouponRepository.issueCoupon`과 analytics 이벤트에 연결하고, mock repository/widget 테스트로 dev mode 쿠폰 발급 흐름을 검증했다.
- 전역 Flutter/Platform/Zone 오류와 주행 완료 fallback을 `AppLogger` 구조화 로그로 연결하고, 로그 context에서 좌표, raw drive_points, 토큰, service role, secret 계열 키를 제거하도록 보강했다.
- production 주행 결과 확정이 mock score로 열리지 않도록 `SupabaseDriveRepository(allowMockFallback: !config.isProduction)` 정책과 invariant/unit 테스트를 추가했다.
- production 프리미엄 시작이 mock premium으로 열리지 않도록 `SupabaseSubscriptionRepository(allowMockFallback: !config.isProduction)` 정책과 invariant/unit 테스트를 추가했다.
- production 리워드 광고가 광고 시청 검증 없이 지급되지 않도록 `SupabaseAdsRepository(allowClientRewardGrant: !config.isProduction)` 정책을 유지하고, Android/iOS에서는 `RewardedAdService`가 AdMob `onUserEarnedReward` 콜백을 받은 뒤에만 `watchRewardAd(verifiedByAdSdk: true)`로 `grant_ad_reward`를 호출하도록 연결했다.
- production 광고 repository가 `reward_ad_daily_limit`는 공개 `app_settings`에서, native 광고 카드는 RLS가 적용된 `advertisements`에서 읽도록 연결했다. production 조회 실패 시 mock 광고 대신 보상 광고를 닫거나 빈 광고 목록으로 복구한다.
- production RemoteConfig는 공개 `app_settings`를 읽지 못하면 기본 운영값으로 조용히 후퇴하지 않고 오류 상태를 노출한다. 리워드 광고 화면은 설정 로딩/오류/비활성 상태를 분리하고, 설정 실패 시 광고 버튼을 열지 않는다.
- 프리미엄 화면의 결제 상품 조회, 구매 요청, 구매 복원, 영수증 검증 상태 문구를 정상 한국어로 정리하고, 사용자 presentation/widget 파일에 mojibake 문구가 재도입되면 product invariant가 실패하도록 보강했다.
- production 차량 설정이 mock 차량 카탈로그 seed로 열리지 않도록 `SupabaseVehicleCatalogRepository(allowMockFallback: !config.isProduction)`와 `SupabaseLeagueRepository(allowMockFallback: !config.isProduction)` 정책, invariant/unit 테스트를 추가했다.
- 356/390px 좁은 viewport, 430px 최대 폭, 1920px 데스크톱 미리보기의 모바일 폭 제한과 app bar/bottom bar 제한, compact bottom navigation 5탭 표시, 관리자 full-width shell 테스트를 추가했다.
- `AppLayout`, `AppIconSize`, `AppCardSize`, `AppButtonHeight` 토큰을 추가하고 제조사 grid를 고정 높이 compact card로 바꿔 큰 화면에서 카드가 비정상적으로 커지는 회귀를 차단했다.
- 제조사 선택 단계에 전체/국산/수입 필터를 추가하고, repository/provider/widget/unit 테스트로 `KR`과 `IMPORT` 필터 동작을 고정했다.
- app router fresh factory와 core route smoke 테스트를 추가해 `/home` 5개 탭, 차량 설정, 주행, 랭킹, 배틀, 설정, 차량 관리, 알림, 고객지원, 프리미엄 URL이 본문을 렌더링하는지 검증한다.
- `127.0.0.1:5173/#/home`과 `#/home?tab=profile` 웹 hash route에서 홈/프로필 본문이 렌더링되는 것을 캡처로 확인했고, nested SafeArea 재도입과 Web viewport meta 누락을 `tool/validate_product_invariants.dart`로 차단했다. 추가로 `tool/verify_web_render.py`를 만들어 `build/web`을 Chrome/Edge headless screenshot으로 열고 screenshot 크기, color bucket, UI pixel ratio가 낮으면 실패하도록 해 초록 배경만 보이는 Web 회귀를 릴리스 전에 잡는다.
- Edge Function smoke validator를 추가하고 GitHub Actions `flutter_ci.yml`에 연결했다.
- 제품 invariant validator를 추가하고 GitHub Actions `flutter_ci.yml`에 연결했다. 현재 1613 checks로 사용자 화면 폭 제한, 직접 `Scaffold` 우회, placeholder/dev 문구 재도입, Splash 세션 복구 실패 재시도 UI, 주행 준비 readiness 무한 로딩 회귀, 주행 결과 샘플 수치 fallback 차단과 요약 누락 복구 UI, 오프라인 주행 세션/포인트 재매핑과 매핑 영속 재시도, 오프라인 동기화 운영 로그와 손상 queue discard/격리 정책, 세션 복구의 서버 완료 상태 로컬 힌트 반영, 로그아웃 로컬 queue privacy 정리, 로그아웃 후 사용자별 provider cache 정리, 원격 로그아웃 실패 시에도 로컬 개인정보 정리 보장, 프로필 화면 로그아웃 후 Google 로그인 화면 복귀, Google 로그인 프로필 복구의 민감 컬럼 write 차단, 계정 삭제 요청의 확인 문구 입력, 직접 계정 삭제 API의 개인정보 요청 큐 이관, Web Google OAuth redirect의 SDK 초기화 우회, native Google OAuth token/platform client 완전성, Supabase 없는 dev Google 값 잔존 시 mock auth 유지, Google 로그인 성공 후 stale session 캐시 갱신과 완료 상태별 `/consent`/`/setup`/`/home` 라우팅, 로그인 전 legal 문서 접근, 보호 라우트의 미로그인 직접 진입 차단, 보호 라우트의 동의 미완료 직접 진입 차단, 동의 완료 후 세션 캐시 갱신과 저장 실패 복구 UI, 차량 설정 완료 후 세션/홈/프로필 캐시 갱신과 저장 실패 복구 UI, 관리자 라우트의 일반 사용자 직접 진입 차단, 관리자 Web route 데스크톱 smoke 포함 여부, 주행 결과 local-drive 세션 ID 해석, 주행 중 팝업/광고/알림 차단과 인라인 종료 확인, `.env` 번들링, production Supabase URL/초기화 설정 오류, 운영/스테이징 설정 오류 화면의 비-dev 안내, Supabase client provider URL 안전장치, RemoteConfig 파싱/범위 테스트와 문서, analytics 민감 키/user property 차단, 구조화 로그 민감 키 제거와 전역 오류 훅, production 주행 결과 mock score fallback 차단, production 프리미엄 mock 활성화 차단, production 리워드 광고 직접 지급 차단, production 리워드/쿠폰 설정 오류 시 CTA 차단, production 홈/시즌/주행 mock fallback 차단, production 운영/콘텐츠 mock fallback 차단, production 공정성 센터 mock fallback 차단, production 인증/동의 mock fallback 차단, production 차량 카탈로그 mock seed fallback 차단, 사용자 주요 화면 빈 상태 복구 CTA, 쿠폰 발급 UI/이벤트/테스트, 상세 화면 missing id 복구, 상세 route 예시 ID fallback 차단, 배틀 상세 단일 조회와 mock 생성 저장, 배틀 결과 정산 CTA/Edge 호출/analytics 이벤트, 주행 기록/분석 실제 화면과 privacy guard, 랭킹 상세 실제 화면, 공개 프로필 public_rankings 기반 조회, 라이벌 공개 랭킹 기반 비교, 공개 화면 좌표/raw drive_points 노출, runtime fallback 차량 카탈로그의 현재 파워트레인 ID, 차량 기준 연식 피커와 직접 연식 매핑, 직접 입력 차량 검수 큐와 관리자 승인/반려/요청-차량 무결성/결과 알림 흐름, Flutter Web 한글 폰트 번들링, Web runtime smoke 도구/문서, CanvasKit/dart2js 안정 런타임 고정, service worker/cache 정리, COOP/COEP 정적 서버 헤더, production release env preflight 도구/문서와 AdMob unit ID required 목록, OAuth redirect 고정 검증, Supabase Google OAuth live redirect 검증, App Store Bundle ID/Xcode bundle id 일치 검증, `verify_purchase` App Store Bundle ID secret 필수화와 Google Play package name 서버 고정, 프리미엄 상품 seed와 요금제 정렬, 프리미엄 상품 4종 카드/구매 복원/productId 기반 plan 복구, `.env.example` Edge-only App Store Bundle ID 주석 검증, store submission asset preflight 도구/문서, 브랜드 아이콘/스플래시 자산, legal disclosure route와 Web 정적 페이지, 이의제기 라우트/CTA/테스트/문서, Android OAuth callback manifest, Android release AdMob production gate, iOS Runner project/Info.plist 표준 key, iOS secret xcconfig, Web/PWA viewport/메타데이터와 Flutter Web host viewport CSS, CI 필수 명령, 로컬 릴리즈 게이트 도구, 릴리스 문서, runbook 필수 client env 전체 목록과 Edge Function deploy 목록, production Supabase live preflight 문서, release 문서 mojibake 방지, `.env.example`/`.env.production.example`/`.env.edge.production.example` 필수 키, release env example placeholder 거부까지 함께 검사한다.
- Supabase schema validator를 추가하고 GitHub Actions `flutter_ci.yml`에 연결했다. 현재 297 checks로 필수 table 생성, RLS 활성화, self/admin/public policy, profile self-write hardening, public ranking privacy, RPC security definer/search_path, Edge 전용 RPC grant/revoke, 공개 app_settings seed, 공정성 센터 공개 가이드 seed, 스토어 결제 상품 seed, 차량 카탈로그 seed 동기화, idempotency/unique index, 직접 입력 차량 요청과 `user_vehicles` 연결을 검사한다.
- 직접 의존성 `any`를 제거해 lockfile 기준 검증 버전대에서 재현 가능한 빌드를 유지하도록 보강했고, `flutter_local_notifications`를 22.0.0으로 올려 직접 dependency 기준 최신 해석 상태를 유지한다.
- Android manifest에 Android 13+ 알림 권한을 추가하고 플랫폼 권한 선언 검증을 자동화했다.
- Android release signing을 `android/key.properties` 기반으로 분리하고 debug signing 및 테스트 AdMob App ID release 회귀를 product invariant validator로 차단했다.
- production release preflight 도구를 추가해 `SUPABASE_URL`, Google OAuth, AdMob live App/Unit ID, IAP product ID, 공개 legal URL, Edge Function purchase/ranking secret을 검사하고, Flutter client env에 service role key나 App Store private key가 섞이면 실패하도록 했다. `--check-supabase-live`는 public REST seed/RLS, Edge CORS, Google OAuth provider와 web/native redirect가 `accounts.google.com`으로 이어지는지도 확인한다.
- 스토어 제출 자산 preflight 도구를 추가해 한국어 listing copy UTF-8/Hangul 상태, 1024x500 feature graphic, 1080x1920 휴대폰 스크린샷 5종, `/legal/*` 정적 고지 페이지를 제출 전 검사하도록 했다.
- 스토어 제출 이미지 preflight는 PNG 크기와 용량뿐 아니라 색상 bucket 수와 UI/text 대비 비율을 샘플링해 단색/빈 이미지 회귀를 차단한다.
- 스토어 개인정보 disclosure 자료를 추가해 Play Console 데이터 보안, App Store 개인정보 라벨, iOS `PrivacyInfo.xcprivacy`, Android 광고 ID 권한, ATT 고지 문구를 repo 안에서 함께 검증하도록 했다.

## 13. 추후 외부 설정이 필요한 항목
- Supabase production project migration/seed/function deploy.
- Google OAuth web/android/iOS client id와 redirect URL.
- AdMob production app id/ad unit id.
- Play Console/App Store IAP product id와 server verification secret.
- Web legal 페이지를 실제 도메인에 배포한 개인정보 처리방침 URL, 위치정보 이용 고지 URL, 계정 삭제 안내 URL.
## Production User Data Fallback
- production에서는 Supabase 인증 또는 사용자 row 조회 실패 시 mock 프로필/통계가 표시되지 않는다. 사용자별 프로필/통계 fallback은 dev/staging에서만 허용한다.

## Production Auth Consent Fallback
- production에서는 인증 설정 누락, Supabase 인증 실패, 동의 저장소 미설정, 동의 저장 실패를 mock 로그인/동의 데이터로 대체하지 않는다. 즉, production은 mock 로그인/동의 데이터를 표시하거나 저장하지 않는다. dev mode에서 Supabase가 없을 때만 mock 인증과 mock 동의 저장소를 허용한다.

## Production Vehicle Catalog Fallback
- production에서는 `vehicle_manufacturers`, `vehicle_models`, `vehicle_model_years`, `vehicle_catalog_view`, `custom_vehicle_requests`, `user_vehicles`, `fuel_leagues` 조회·저장 실패를 mock 차량 카탈로그 seed로 대체하지 않는다. 차량 설정, 직접 입력 요청, 리그 배정은 Supabase 오류/재시도 상태로 노출하고 dev/staging fallback만 seed 카탈로그를 허용한다.
- production 제조사 선택 카드의 모델 수와 지원 연식 범위는 `vehicle_manufacturer_catalog_view`의 `model_count`, `min_year`, `max_year`를 사용하고, 파워트레인 variant 조회는 `vehicle_catalog_view`를 사용한다.

## Production Core Experience Fallback
- production에서는 홈, 시즌, 주행 기록/점수, 대표 차량, 오늘의 미션 조회 실패를 mock 홈/시즌/주행 데이터로 대체하지 않는다. 즉, production은 mock 홈/시즌/주행 데이터를 표시하지 않는다. 실제 row가 비어 있는 경우에는 빈 상태용 중립 데이터를 표시하고, 쿼리 실패나 인증 누락은 오류/재시도 상태로 노출한다.

## Production Operational Data Fallback
- production에서는 스폰서 챌린지, 쿠폰, 알림, 고객지원, 신고, 개인정보 요청, 크루, 관리자 운영 데이터 조회/저장 실패를 mock 운영/콘텐츠 데이터로 대체하지 않는다. 즉, production은 mock 운영/콘텐츠 데이터를 표시하지 않는다. dev/staging에서만 mock fallback을 허용하며, production은 빈 상태 또는 오류/재시도 UI로 노출한다.

## Latest Verification Snapshot
- `flutter analyze`: no issues found.
- `dart run tool/validate_vehicle_catalog.dart`: 22 manufacturers, 164 models, 3098 years, 5079 variants.
- `dart run tool/validate_supabase_schema.dart`: 297 checks passed.
- `dart run tool/validate_edge_functions.dart`: 14 functions, 266 checks passed.
- `dart run tool/validate_product_invariants.dart`: 1613 checks passed.
- `flutter test`: 191 tests passed.
- `flutter build web`: built `build/web`.
- `flutter build web --wasm`: built `build/web`; Wasm compatibility smoke passed. Production Web runtime remains pinned to CanvasKit/dart2js for the current release path.
- `python tool/verify_web_render.py`: 로그인 화면과 프로필 탭 390x844 smoke 렌더링 통과.
- `python tool/verify_web_core_routes.py`: 로그인, 동의, 차량 설정, 홈, 랭킹, 프로필, 프리미엄, 공정성 센터, 고객지원 9개 모바일 route와 관리자 2개 데스크톱 route smoke 렌더링 통과.
- GitHub Actions는 `flutter build web --wasm` 산출물과 일반 `flutter build web` 산출물 각각에 대해 정적 서버를 띄우고 두 Web smoke 도구를 실행한다.
- `tool/run_web_smoke.py`를 추가해 CI와 로컬 게이트가 고정 `sleep` 대신 포트 준비를 기다린 뒤 Web render/core route smoke를 실행하도록 했다.
- `requirements-dev.txt`를 추가하고 CI/로컬 릴리즈 게이트에서 `python -m pip install -r requirements-dev.txt`를 실행해 Pillow 기반 screenshot/asset tooling 의존성을 명시적으로 설치한다.
- `python tool/validate_release_environment_selftest.py`: 13 checks passed.
- `python tool/validate_release_example_placeholders.py`: example env placeholder rejection passed.
- `python tool/validate_release_environment.py`: valid/invalid sample env 기준 통과/실패 동작 확인.
- `python tool/validate_store_submission_assets.py`: store submission assets valid.
- `python tool/validate_store_privacy_disclosures.py`: store privacy disclosures valid.
- `python tool/run_local_release_gate.py --quick`: validator, release env example placeholder rejection, format, analyze, test 빠른 게이트 통과.
- `python tool/run_local_release_gate.py`: Android debug build, Web/Wasm build, Web smoke 전체 로컬 릴리즈 게이트 통과.
- `dart pub outdated --no-dev-dependencies --no-transitive`: direct dependencies all up-to-date.
- Web legal pages `/legal/privacy/`, `/legal/location/`, `/legal/account-deletion/`, `/legal/terms/`: static build files included and local server returned 200.
- `flutter build apk --debug`: built `build/app/outputs/flutter-apk/app-debug.apk`.

## Staging Runtime Policy
- staging/production은 Supabase URL과 anon key가 없으면 시작 단계에서 설정 오류로 막는다. mock repository는 dev mode에서 Supabase가 없을 때만 허용한다.

## Production Premium Plan Fallback
- production에서는 Supabase `subscription_plans` 조회 실패 또는 빈 결과를 mock 프리미엄 요금제로 대체하지 않는다. 요금제 정보가 없으면 결제 화면은 고객지원 복구 CTA가 있는 빈 상태로 남긴다.
