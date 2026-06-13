# Release Checklist

## Android
- 앱 이름 Fuel Arena 확인
- applicationId `com.fuelarena.fuel_arena` 출시용 확정 여부 확인
- Android v2 embedding `MainActivity`와 launcher activity 확인
- 위치 권한, 인터넷 권한, Android 13+ 알림 권한 확인
- `tool/generate_brand_assets.py`로 생성한 Fuel Arena launcher icon과 launch splash 적용 확인
- AdMob production App ID 설정 확인
- Android release build에 `ADMOB_ANDROID_APP_ID`를 Gradle property 또는 환경 변수로 전달
- debug placeholder `ca-app-pub-3940256099942544~3347511713`이 release에 남지 않는지 확인
- debug signing과 release signing 분리
- Play Console 업로드 전 `android/key.properties`를 실제 upload keystore, key alias, password로 채우고 release APK/AAB 서명 확인
- Google OAuth Web/Android/iOS/Server client ID를 production env에 등록하고 Android client에 package name, release SHA-1, release SHA-256 등록
- `.env.production`의 `GOOGLE_ANDROID_RELEASE_PACKAGE_NAME`, `GOOGLE_ANDROID_RELEASE_SHA1`, `GOOGLE_ANDROID_RELEASE_SHA256`가 Google Cloud Console Android OAuth client와 일치하는지 확인
- Android OAuth callback intent filter가 `APP_AUTH_REDIRECT_SCHEME`/`APP_AUTH_REDIRECT_HOST`로 `fuelarena://login-callback`을 받는지 확인
- `package_info_plus` Kotlin Gradle Plugin 경고가 남아 있으면 upstream fixed version 확인 후 의존성 갱신

## iOS
- 앱 이름 Fuel Arena 확인
- bundle id 출시용 확정
- App Store Bundle ID `com.fuelarena.fuelArena`와 Xcode `PRODUCT_BUNDLE_IDENTIFIER` 일치 확인
- `ios/Runner.xcodeproj`, `ios/Runner.xcworkspace`, `Runner/Info.plist` 표준 Flutter scaffold 확인
- Fuel Arena AppIcon asset과 LaunchScreen 브랜드 배경/이미지 확인
- `ios/Flutter/FuelArenaSecrets.xcconfig.example`를 `FuelArenaSecrets.xcconfig`로 복사하고 실제 Google/AdMob 값 설정
- `FuelArenaSecrets.xcconfig`가 git에 포함되지 않는지 확인
- 위치 권한 설명 확인
- Google reversed iOS client ID URL scheme 확인. `GOOGLE_REVERSED_IOS_CLIENT_ID`는 `GOOGLE_IOS_CLIENT_ID`의 `.apps.googleusercontent.com` 앞부분을 `com.googleusercontent.apps.` 뒤에 붙인 값과 일치해야 한다.
- Google iOS client ID, server client ID, AdMob iOS App ID가 Xcode build setting에 주입되는지 확인
- `fuelarena` custom URL scheme 확인
- 광고 추적 안내 필요 여부 확인
- App Store 인앱결제 상품 ID 확인

## Web/PWA
- `web/manifest.json`의 name, short_name, description이 Fuel Arena 제품 정보인지 확인
- `web/index.html`의 title, description, apple-mobile-web-app-title이 Fuel Arena로 설정됐는지 확인
- Web/PWA icon, maskable icon, favicon이 Flutter 기본 아이콘이 아니라 Fuel Arena 브랜드 아이콘인지 확인
- Flutter template 문구 `A new Flutter project.`와 `fuel_arena` 표시명이 남지 않았는지 확인

## 개인정보와 위치정보
- 개인정보 처리방침 URL 준비: Web 배포 후 `/legal/privacy/` 연결 확인
- 위치정보 이용 고지 준비: Web 배포 후 `/legal/location/` 연결 확인
- 계정 및 데이터 삭제 안내 URL 준비: Web 배포 후 `/legal/account-deletion/` 연결 확인
- 서비스 이용약관 URL 준비: Web 배포 후 `/legal/terms/` 연결 확인
- 회원 탈퇴와 데이터 삭제 요청 UI 확인
- drive_points 공개 노출 차단 확인
- 분석 이벤트에 location, latitude, longitude, drive_points 키가 저장되지 않는지 확인
- 권한 거부 후 앱 설정 안내 화면이 정상 동작하는지 확인

## 광고와 결제
- test ad unit 제거
- live ad ID 설정
- IAP 상품 ID와 가격 확인
- dev 구매 검증 fallback이 production에서 비활성화되고 실제 스토어 결제로 전환되는지 확인
- 리워드 광고 daily limit와 enabled 설정이 app_settings 원격 설정과 일치하는지 확인
- `verify_purchase` Edge Function에 Google Play service account, App Store Connect key, bundle id, sandbox/live env secret 설정 확인
- Google Play sandbox subscription, App Store sandbox subscription 구매/복원/만료/환불 검증

## Supabase
- production migration 적용
- Google Auth Provider와 redirect URL 설정 확인
- 2008-2026 vehicle catalog seed와 fuel_leagues seed 적용 확인
- service completion migration 적용 확인
- RLS 활성화 확인
- `drive_points.is_mocked`와 `drive_scores_drive_session_id_uidx` migration 적용 확인
- `purchase_verifications`와 `user_subscriptions_user_plan_uidx` migration 적용 확인
- `ranking_update_jobs`와 `recompute_rankings` migration 적용 확인
- `edge_function_idempotency_keys` migration 적용 확인
- Edge Function secrets 설정
- service_role key 클라이언트 미포함 확인
- support_tickets, analytics_events, app_settings RLS 수동 테스트 완료
- finish_drive_session, calculate_drive_score, verify_drive_session, update_rankings, settle_battle, grant_ad_reward, claim_season_reward, issue_coupon, update_mission_progress, process_fraud_review, send_notification 배포 확인
- assign_vehicle_league, review_custom_vehicle, verify_purchase 배포 확인
- Supabase backup, PITR 또는 주기 백업 정책 확인

## 차량과 리그
- 현대 아반떼 2026 1.6 가솔린, 1.6 하이브리드, 1.6 LPi 선택 경로 확인
- 제조사 선택에서 전체/국산/수입 필터가 각각 국내 제조사와 수입 제조사를 올바르게 나누는지 확인
- 기아 → 가솔린 → 승용 → K3 경로에서 K3 GT가 별도 모델이 아니라 `K3 GT 1.6T 가솔린 DCT` 트림/파워트레인으로 보이는지 확인
- 2008년식 차량 선택 경로와 파워트레인 단위 리그 배정 확인
- `vehicle_manufacturer_catalog_view`에서 제조사별 `model_count`, `min_year`, `max_year`가 채워지는지 확인
- 대표 차량 변경 시 내 연료 리그와 차급이 함께 변경되는지 확인
- 가솔린, 디젤, 하이브리드, 전기차, LPG, 플러그인 하이브리드 리그 분리 확인
- 직접 입력 차량은 `custom_vehicle_requests.user_vehicle_id`와 연결된 검수 대기 상태로 저장되고, 관리자 검수 시 요청 row와 차량 row의 연결/소유자가 일치할 때만 공식 랭킹 전 검수되는지 확인
- `user_vehicle_id`가 없거나 다른 사용자의 `user_vehicle_id`를 넣은 직접 입력 차량 요청 insert가 `custom_vehicle_requests_self_insert` RLS에서 거부되는지 확인
- 관리자 차량 카탈로그 화면에서 제조사 검색, 검수 정책, 직접 입력 차량 승인/반려 큐가 실제 상태를 변경하고 사용자 알림함에 `vehicle_review` 결과 알림을 남기는지 확인
- 관리자 대시보드 Users, Drive Sessions, Drive Scores, Support Tickets에서 페이지 이동과 상세 drawer 확인

## 앱 흐름과 복구
- Splash에서 온보딩, 동의, 활성 주행 세션 복구가 정상 라우팅되는지 확인
- 오프라인 주행 시작 시 로컬 큐 저장과 동기화 배너가 표시되는지 확인
- 주행 중 안전 모드에서 광고, 팝업, 도전장, 알림이 표시되지 않는지 확인
- 모의 위치, 비정상 속도, GPS 정확도 낮음 주행이 `pending_review`로 떨어지는지 확인
- verified 주행 완료 후 `ranking_update_jobs`가 생성되고 `update_rankings` 호출 후 `public_rankings`가 갱신되는지 확인
- 같은 시즌의 pending/running `ranking_update_jobs`가 하나로 합쳐져 큐가 중복 누적되지 않는지 확인
- 알림 목록에서 전체 읽음 처리와 target route 이동이 동작하는지 확인
- 보상/쿠폰/미션/배틀 Edge Function을 같은 `x-idempotency-key`로 두 번 호출했을 때 중복 처리 없이 같은 응답이 반환되는지 확인
- `grant_ad_reward` 호출 후 `ad_rewards` row와 `analytics_events.event_name = ad_reward_granted`가 생성되는지 확인
- `update_mission_progress`와 `claim_season_reward` 호출 후 `mission_progress`와 `profiles.season_score`가 기대대로 변경되는지 확인
- `issue_coupon` 호출 후 같은 사용자의 같은 쿠폰이 중복 발급되지 않는지 확인
- `settle_battle` 호출 후 `battle_participants.result`와 `battles.status = completed`가 갱신되는지 확인

## 고객지원과 신고
- 문의 접수 입력 검증, 카테고리 선택, 티켓 생성이 동작하는지 확인
- 관리자 Reports 섹션에서 신고/이의제기 row를 실제 `report_items` 큐에서 읽고 검토 완료 액션이 `resolved` 상태를 저장하는지 확인
- 데이터 다운로드/삭제/탈퇴 요청이 개인정보 설정에서 `privacy_requests`로 접수되고 관리자 Privacy Requests 섹션에서 처리되는지 확인
- 관리자 Privacy Requests 섹션에서 `open`, `review`, `completed`, `rejected` 필터와 검토 시작/완료 처리/보류 처리 액션이 실제 요청 상태를 변경하는지 확인
- 진행 중인 같은 유형의 개인정보 요청은 하나만 허용되고, 앱이 중복 접수 대신 요청 내역 확인 안내를 표시하는지 확인
- 부정 기록 신고가 공정성 센터에서 연결되는지 확인

## 검증 명령
- `python tool/run_local_release_gate.py`
- `python tool/run_local_release_gate.py --quick`
- `flutter pub get`
- `python -m pip install -r requirements-dev.txt`
- `dart format .`
- `flutter analyze`
- `dart run tool/validate_vehicle_catalog.dart`
- `dart run tool/validate_edge_functions.dart`
- `dart run tool/validate_supabase_schema.dart`
- `dart run tool/validate_product_invariants.dart`
- `python tool/validate_store_submission_assets.py`
- `python tool/validate_store_privacy_disclosures.py`
- `python tool/validate_secret_hygiene.py`
- `python tool/validate_release_environment_selftest.py`
- `python tool/validate_release_native_sources.py`
- `python tool/validate_release_example_placeholders.py`
- `.env.production.example`을 `.env.production`으로 복사 후 실제 client/public 값 입력
- `.env.edge.production.example`을 `.env.edge.production`으로 복사 후 Edge secret 값 입력
- `ios/Flutter/FuelArenaSecrets.xcconfig.example`을 `ios/Flutter/FuelArenaSecrets.xcconfig`로 복사 후 iOS Google/AdMob 값 입력
- `android/key.properties.example`을 `android/key.properties`로 복사 후 실제 Android upload keystore 값 입력
- `python tool/validate_release_environment.py --env-file .env.production --edge-secrets-file .env.edge.production --ios-xcconfig ios/Flutter/FuelArenaSecrets.xcconfig --ios-info-plist ios/Runner/Info.plist --android-key-properties android/key.properties --android-manifest android/app/src/main/AndroidManifest.xml`
- `python tool/validate_release_environment.py --env-file .env.production --client-only --ios-xcconfig ios/Flutter/FuelArenaSecrets.xcconfig --ios-info-plist ios/Runner/Info.plist --android-key-properties android/key.properties --android-manifest android/app/src/main/AndroidManifest.xml --check-public-urls`
- `python tool/validate_release_environment.py --env-file .env.production --edge-secrets-file .env.edge.production --ios-xcconfig ios/Flutter/FuelArenaSecrets.xcconfig --ios-info-plist ios/Runner/Info.plist --android-key-properties android/key.properties --android-manifest android/app/src/main/AndroidManifest.xml --check-public-urls --check-supabase-live`
- `--check-supabase-live`는 public REST seed/RLS, 공개 legal URL origin 기준 Edge Function CORS, Google OAuth provider와 web/native redirect allow-list가 실제로 동작하는지 확인한다.
- `flutter test`
- `flutter build apk --debug`
- `flutter build web --wasm`
- `flutter build web`
- `python tool/run_web_smoke.py --port 5173`
- `python tool/serve_web.py --directory build/web --port 5173`
- `python tool/verify_web_render.py`
- `python tool/verify_web_core_routes.py`

Web runtime은 현재 Flutter 3.44 Wasm/Skwasm 조합의 blank render 회귀를 피하기 위해 CanvasKit/dart2js 경로로 고정한다. `web/index.html`은 `renderer: 'canvaskit'`, 로컬 `canvasKitBaseUrl`, `wasmAllowList` 비활성화를 유지하고, `tool/serve_web.py`는 Wasm/CanvasKit 검증을 위해 COOP/COEP/CORP 헤더를 함께 제공한다.

`tool/run_web_smoke.py`는 `tool/serve_web.py`를 실행하고 포트 준비를 기다린 뒤 `tool/verify_web_render.py`와 `tool/verify_web_core_routes.py`를 순서대로 실행한다. CI와 로컬 릴리즈 게이트는 고정 sleep 대신 이 runner를 사용한다.

`tool/verify_web_render.py`는 Chrome/Edge headless screenshot으로 Flutter Web 본문이 실제로 보이는지 확인한다. Chrome 자동 탐지가 실패하면 `CHROME_PATH`를 설정한다.

`tool/verify_web_core_routes.py`는 로그인, 동의, 차량 설정, 홈, 랭킹, 프로필, 프리미엄, 공정성 센터, 고객지원 route를 390px 모바일 폭으로 열고, `/admin`, `/admin/vehicles`는 1440px 데스크톱 폭으로 열어 각 화면이 초록 배경이 아니라 본문 UI를 렌더링하는지 확인한다.

`tool/validate_release_environment.py`는 production `SUPABASE_URL`, Web/Android/iOS/Server Google OAuth client ID 형식, iOS reversed client ID 짝, iOS xcconfig의 Google/AdMob build setting 일치, AdMob live App/Unit ID, IAP product ID, store legal URL, Edge Function 구매 검증 secret을 검사한다. Public legal URL은 HTTPS이면서 같은 origin의 `/legal/privacy/`, `/legal/location/`, `/legal/account-deletion/`, `/legal/terms/` 정적 경로를 정확히 가리켜야 하고 query/fragment를 포함하지 않는다. `--check-public-urls`는 각 URL이 200 응답뿐 아니라 Fuel Arena legal 페이지 본문과 문서별 핵심 한국어 문구를 포함하는지도 확인한다. Flutter client env에는 `SUPABASE_SERVICE_ROLE_KEY`, App Store private key, ranking secret을 넣지 않는다. `--check-supabase-live`는 Edge Function CORS를 그 public origin으로 preflight하고, `/auth/v1/authorize?provider=google`가 web origin과 `fuelarena://login-callback`에서 `accounts.google.com`으로 redirect되는지도 확인한다.

`tool/validate_store_submission_assets.py`는 스토어 등록 문구, feature graphic, 휴대폰 스크린샷의 크기·용량·색상 복잡도·UI 대비, Web legal 정적 페이지를 검사한다. 배포 도메인 연결 후에는 `--base-url`로 실제 공개 URL이 Fuel Arena legal 본문과 문서별 핵심 한국어 문구를 포함하는지도 확인한다.

`tool/validate_store_privacy_disclosures.py`는 `assets/store/privacy_disclosures_ko.json`, iOS `PrivacyInfo.xcprivacy`, Android `AD_ID` 권한, ATT 고지 문구를 함께 검사한다. Play Console 데이터 보안과 App Store 개인정보 라벨 제출 전 실행한다.

`tool/validate_secret_hygiene.py`는 production env, Android keystore/key.properties, iOS secret xcconfig, Google service plist/json, App Store `.p8` key/provisioning profile이 git 추적 대상이나 unignored untracked 대상에 들어오지 않았고 `git check-ignore` 기준으로 실제 ignore되는지 확인한다.

`tool/run_local_release_gate.py`는 CI와 같은 validator, format, analyze, test, Android debug build, Web/Wasm build, Web smoke를 로컬에서 순서대로 실행한다. 기본 smoke 포트는 기존 개발 서버와 섞이지 않도록 `6173`이며, `--quick`은 빌드를 제외한 빠른 게이트로 사용한다. 게이트는 `.env.production.example`과 `.env.edge.production.example`이 명확한 placeholder로 남아 있어 `validate_release_environment.py`에서 실패하는지도 확인해, 예제 값이 실수로 출시 가능한 값처럼 통과하지 못하게 한다.

