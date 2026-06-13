# Fuel Arena

Fuel Arena는 연비와 주행 효율을 경쟁 점수로 바꾸는 게임형 드라이빙 플랫폼입니다.

> 기름값을 아끼는 앱이 아니라, 이기고 싶어서 자연스럽게 아끼게 만드는 앱.

## 기술 스택

Flutter, Dart, go_router, flutter_riverpod, Supabase Auth/Postgres/Realtime/Storage/Edge Functions/RLS, google_mobile_ads, in_app_purchase, geolocator.

## 현재 구현

- Splash → Onboarding → Google Login → Consent → Additional Setup → Home 흐름
- 차량 설정은 로그인 직후 강제하지 않고 `/setup/vehicle` 또는 설정에서 진행
- 제조사 → 연료 타입 → 넓은 범주 → 모델 → 세대 → 엔진·미션 파워트레인 → 확인 스텝퍼 차량 선택
- 가솔린, 디젤, 하이브리드, 전기차, LPG, 플러그인 하이브리드, 기타 리그 분리
- 하단 5개 탭: 홈, 배틀, 랭킹, 시즌, 프로필
- 주행 시작, 안전 모드, 주행 결과, 점수 분석, 광고 보상 선택
- 랭킹, 배틀 생성/상세/결과, 시즌패스, 미션, 라이벌, 크루
- 리워드 지갑, 스폰서 챌린지, 프리미엄 구매 검증 fallback, 공정성 센터, 설정
- 오프라인 상태 배너, 로컬 주행 큐, Splash 상태 복구
- 권한 안내, 알림 읽음 처리, 고객지원/신고/이의제기 접수
- `/admin` 운영자 대시보드와 `/admin/vehicles` 차량 카탈로그 운영 화면
- Supabase schema, RLS, seed, Edge Functions
- dev/mock fallback

## 환경변수

`.env.example`을 복사해 `.env`를 만들고 필요한 값을 채웁니다. 런타임은 `APP_ENV`에 맞는 scoped key를 먼저 읽고, 기존 generic key를 fallback으로 읽습니다. dev mode에서는 Supabase 또는 Google OAuth 설정이 비어 있으면 mock repository/mock auth로 실행됩니다.

```bash
APP_ENV=dev
SUPABASE_URL_DEV=
SUPABASE_ANON_KEY_DEV=
SUPABASE_URL_STAGING=
SUPABASE_ANON_KEY_STAGING=
SUPABASE_URL_PRODUCTION=
SUPABASE_ANON_KEY_PRODUCTION=
GOOGLE_WEB_CLIENT_ID_DEV=
GOOGLE_ANDROID_CLIENT_ID_DEV=
GOOGLE_IOS_CLIENT_ID_DEV=
GOOGLE_SERVER_CLIENT_ID_DEV=
GOOGLE_REVERSED_IOS_CLIENT_ID_DEV=
GOOGLE_WEB_CLIENT_ID_STAGING=
GOOGLE_ANDROID_CLIENT_ID_STAGING=
GOOGLE_IOS_CLIENT_ID_STAGING=
GOOGLE_SERVER_CLIENT_ID_STAGING=
GOOGLE_REVERSED_IOS_CLIENT_ID_STAGING=
GOOGLE_WEB_CLIENT_ID_PRODUCTION=
GOOGLE_ANDROID_CLIENT_ID_PRODUCTION=
GOOGLE_IOS_CLIENT_ID_PRODUCTION=
GOOGLE_SERVER_CLIENT_ID_PRODUCTION=
GOOGLE_REVERSED_IOS_CLIENT_ID_PRODUCTION=
AUTH_REDIRECT_SCHEME=fuelarena
AUTH_REDIRECT_HOST=login-callback
SUPPORT_EMAIL=
TERMS_OF_SERVICE_URL=
PRIVACY_POLICY_URL=
LOCATION_POLICY_URL=
GOOGLE_ANDROID_RELEASE_PACKAGE_NAME=com.fuelarena.fuel_arena
GOOGLE_ANDROID_RELEASE_SHA1=
GOOGLE_ANDROID_RELEASE_SHA256=
```

staging/production mode에서는 Supabase URL, anon key, Web/Android/iOS/Server Google OAuth client ID, iOS reversed client ID, `fuelarena://login-callback` callback 설정, 공개 약관/개인정보/위치정보 URL이 모두 필수입니다. service_role key와 Google OAuth client secret은 Flutter 앱에 넣지 않습니다.

## 실행

```bash
flutter create . --project-name fuel_arena --platforms android,ios,web
flutter pub get
python -m pip install -r requirements-dev.txt
flutter run
```

## 테스트

```bash
dart run tool/validate_vehicle_catalog.dart
dart run tool/validate_edge_functions.dart
dart run tool/validate_supabase_schema.dart
dart run tool/validate_google_auth_database.dart
dart run tool/security/check_auth_rls_policies.dart
dart run tool/validate_product_invariants.dart
python -m pip install -r requirements-dev.txt
python tool/validate_store_submission_assets.py
python tool/validate_store_privacy_disclosures.py
python tool/validate_secret_hygiene.py
python tool/validate_release_environment_selftest.py
python tool/validate_release_native_sources.py
python tool/validate_release_example_placeholders.py
flutter test
flutter analyze
```

CI와 같은 흐름을 로컬에서 한 번에 돌리려면 아래 게이트를 사용합니다. 기본 포트는
기존 개발 서버와 충돌하지 않도록 `6173`을 사용합니다.

```bash
python tool/run_local_release_gate.py
python tool/run_local_release_gate.py --quick
```

`validate_supabase_schema.dart`는 필수 public table, RLS 활성화, 핵심 정책, public view privacy, RPC 보안 속성, Edge 전용 RPC 권한, 중복 방지 index를 정적으로 검사한다. `validate_product_invariants.dart`는 service role 노출, `.env` 번들링, 사용자 화면 430px 제한 우회, 모바일 레이아웃 토큰, compact 제조사 카드, core route smoke coverage, 직접 `Scaffold` 사용, placeholder/dev 문구 재도입, lib 앱 소스의 mojibake/CJK 깨짐 문자, 주행 중 팝업/광고/알림 차단, 공개 화면 좌표/raw drive_points 노출, 공개 랭킹 privacy, drive_points RLS, 구조화 로그의 민감 키 제거, runtime fallback 차량 카탈로그의 현재 파워트레인 ID, 브랜드 아이콘/스플래시 자산, 플랫폼 권한 선언, Android release signing/AdMob gate, CI 명령, 릴리스 문서, runbook Edge Function deploy 목록과 `.env.example` 필수 키를 함께 검사한다.

`validate_store_submission_assets.py`는 스토어 등록용 한국어 문구가 UTF-8/Hangul 상태인지, feature graphic과 휴대폰 스크린샷 크기·용량·색상 복잡도·UI 대비가 맞는지, `/legal/*` 정적 고지 페이지와 배포 URL이 Fuel Arena legal 본문과 문서별 핵심 한국어 문구를 포함하는지 검사한다.

`validate_store_privacy_disclosures.py`는 Play Console 데이터 보안 섹션, App Store 개인정보 라벨, iOS `PrivacyInfo.xcprivacy`, Android 광고 ID 권한, ATT 고지 문구가 현재 앱의 위치/광고/결제/고객지원 데이터 흐름과 맞는지 검사한다.

`validate_secret_hygiene.py`는 `.env.production`, `.env.edge.production`, Android keystore, `android/key.properties`, iOS `FuelArenaSecrets.xcconfig`, Google service plist/json, App Store `.p8` key/provisioning profile 같은 로컬 비밀 파일이 git 추적 대상이나 unignored untracked 대상이 아니며 `git check-ignore`로 실제 ignore되는지 검사한다.

production 제출 전에는 Flutter client env와 Edge Function secret을 분리해 프리플라이트를 실행합니다.

```bash
cp .env.production.example .env.production
cp .env.edge.production.example .env.edge.production
cp ios/Flutter/FuelArenaSecrets.xcconfig.example ios/Flutter/FuelArenaSecrets.xcconfig
cp android/key.properties.example android/key.properties
python tool/validate_release_environment.py --env-file .env.production --edge-secrets-file .env.edge.production --ios-xcconfig ios/Flutter/FuelArenaSecrets.xcconfig --ios-info-plist ios/Runner/Info.plist --android-key-properties android/key.properties --android-manifest android/app/src/main/AndroidManifest.xml
python tool/validate_release_environment.py --env-file .env.production --client-only --ios-xcconfig ios/Flutter/FuelArenaSecrets.xcconfig --ios-info-plist ios/Runner/Info.plist --android-key-properties android/key.properties --android-manifest android/app/src/main/AndroidManifest.xml --check-public-urls
python tool/validate_release_environment.py --env-file .env.production --edge-secrets-file .env.edge.production --ios-xcconfig ios/Flutter/FuelArenaSecrets.xcconfig --ios-info-plist ios/Runner/Info.plist --android-key-properties android/key.properties --android-manifest android/app/src/main/AndroidManifest.xml --check-public-urls --check-supabase-live
```

`--ios-xcconfig` checks that iOS Google/AdMob build settings are present and that the iOS client ID/reversed client ID match `.env.production`. `--ios-info-plist` and `--android-manifest` check that native Google/AdMob placeholders and OAuth callback URL schemes are wired into the platform source files. `--android-key-properties` checks that Android release signing uses a real upload keystore file instead of placeholder/debug values. `--check-public-urls` fetches the public legal URLs and verifies Fuel Arena legal page content, while `--check-supabase-live` checks public REST seed/RLS visibility, Edge Function CORS preflight from the public legal URL origin, and Supabase Google OAuth `/auth/v1/authorize?provider=google` redirects for the production web origin plus `fuelarena://login-callback`.

`.env.production`에는 Flutter client에 들어갈 anon/public 값만 두고, service role key, purchase private key, ranking secret은 `.env.edge.production` 또는 Supabase secrets에만 둡니다.

## 빌드

```bash
flutter build apk --debug
flutter build web --wasm
flutter build web
```

빌드된 Web 화면이 초록 배경만 보이는 회귀를 잡으려면 별도 터미널에서
정적 서버를 띄운 뒤 smoke 검증을 실행합니다.

```bash
python tool/run_web_smoke.py --port 5173
python tool/serve_web.py --directory build/web --port 5173
python tool/verify_web_render.py
python tool/verify_web_core_routes.py
```

`run_web_smoke.py`는 정적 서버를 띄운 뒤 포트가 열릴 때까지 기다리고, 로그인 화면과 핵심 route smoke를 실행한 뒤 서버를 종료합니다. Chrome 자동 탐지가 실패하면 `CHROME_PATH`에 Chrome 또는 Edge 실행 파일 경로를 지정합니다.

Android release APK/AAB는 `android/key.properties.example`을
`android/key.properties`로 복사해 실제 keystore 값을 채운 뒤 빌드합니다. 실제
`key.properties`, `.jks`, `.keystore` 파일은 git에 포함하지 않습니다.
Release 빌드는 테스트 AdMob App ID를 허용하지 않으므로
`ADMOB_ANDROID_APP_ID`를 Gradle property(`-PADMOB_ANDROID_APP_ID=...`) 또는
환경 변수로 제공해야 합니다.

iOS는 표준 Flutter Runner project와 `Runner/Info.plist`를 포함합니다. App
Store 빌드는 macOS/Xcode 환경에서 Bundle ID, Team, Google iOS client,
`GOOGLE_REVERSED_IOS_CLIENT_ID`, `ADMOB_IOS_APP_ID`를 채운 뒤 검증합니다.
로컬 iOS 빌드 설정은 `ios/Flutter/FuelArenaSecrets.xcconfig.example`를
`ios/Flutter/FuelArenaSecrets.xcconfig`로 복사해 채웁니다. 실제
`FuelArenaSecrets.xcconfig`는 git에 포함하지 않습니다.

## 차량 카탈로그

dev/mock 차량 카탈로그는 `assets/data/vehicle_catalog_kr_seed.json`을 우선 사용합니다. 현재 seed는 제조사, 모델, 세대, 연식, 파워트레인 variant를 포함합니다. 사용자 선택 축은 판매 트림/휠 인치가 아니라 제조사, 연료 타입, EV/승용/SUV/RV/상용 같은 넓은 범주, 모델, 세대, 엔진·미션 파워트레인입니다. K3 GT는 별도 모델이 아니라 K3의 GT 트림/파워트레인으로 관리합니다. production 제조사 카드 통계는 `vehicle_manufacturer_catalog_view`, 파워트레인 목록은 `vehicle_catalog_view`, 세대 필터는 `vehicle_generations`/`vehicle_generation_filter_view`를 사용합니다.

```bash
dart run tool/generate_vehicle_catalog_seed.dart
dart run tool/validate_vehicle_catalog.dart
dart run tool/import_vehicle_catalog.dart --out supabase/seed_vehicle_catalog.sql
```

production import와 운영 절차는 `docs/16_vehicle_catalog_guide.md`, `docs/19_vehicle_catalog_import_format.md`, `docs/21_production_runbook.md`를 기준으로 진행합니다.

## Supabase

```bash
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
supabase functions deploy send_notification
supabase functions deploy assign_vehicle_league
supabase functions deploy review_custom_vehicle
supabase functions deploy verify_purchase
```

Edge Function의 `SUPABASE_SERVICE_ROLE_KEY`는 `supabase secrets set`으로만 설정하고 Flutter 앱 `.env`에는 넣지 않습니다.

Google 로그인 이후 DB 보안은 `202606110001_google_auth_database_hardening.sql`이 담당합니다. 이 migration은 `auth.users` → `profiles` 자동 생성/복구 trigger, `last_login_at` 갱신, 보호 필드 방어 trigger, 동의 로그 RPC, 계정 삭제/데이터 export 전용 queue, 인증/관리자 감사 로그, 안전한 공개 profile/ranking view를 추가합니다. 적용 후 아래 검증을 함께 실행합니다.

```bash
dart run tool/validate_google_auth_database.dart
dart run tool/security/check_auth_rls_policies.dart
```

## 개발 모드와 프로덕션 모드

- dev: 외부 키가 없어도 mock repository, mock ads, 구매 검증 fallback으로 실제 흐름 검증
- staging: Supabase 필수, test ads 사용
- production: Supabase와 Google OAuth 필수, live ads, 실제 IAP 상품 ID 필요

## Google 로그인

앱 로그인 화면은 Google 계정만 제공합니다. dev mode에서 Supabase 또는 Google OAuth 설정이 없으면 MockAuthRepository로 로그인 흐름을 통과하고, staging/production mode에서 Web/Android/iOS/Server Google OAuth client와 callback 값 중 하나라도 빠지거나 형식이 맞지 않으면 설정 오류 화면을 표시합니다.

Android/iOS는 `google_sign_in`에서 받은 Google ID token/access token을 Supabase `signInWithIdToken(OAuthProvider.google)`로 교환합니다. Web은 Google Sign-In SDK의 앱 버튼 인증을 쓰지 않고 Supabase OAuth redirect로 이동한 뒤, 앱 재진입 시 Splash가 Supabase 세션을 복구합니다. iOS의 `GOOGLE_REVERSED_IOS_CLIENT_ID`는 `GOOGLE_IOS_CLIENT_ID`의 앞부분을 `com.googleusercontent.apps.` 뒤에 붙인 값이어야 합니다.

Supabase Dashboard의 Authentication Provider에서 Google을 활성화하고, Google Cloud OAuth client와 Supabase callback URL을 연결합니다. Web 배포 도메인과 로컬 확인 URL(`http://127.0.0.1:5173` 등)은 Supabase Auth redirect allow list에 등록합니다. Android는 package name과 release SHA-1/SHA-256을 Google Cloud Console에 등록하고 같은 값을 `.env.production`의 `GOOGLE_ANDROID_RELEASE_*`에 기록해 preflight로 검증합니다. iOS는 reversed client ID를 연결합니다. 앱 커스텀 redirect는 `fuelarena://login-callback`을 사용합니다. Android manifest는 `APP_AUTH_REDIRECT_SCHEME`/`APP_AUTH_REDIRECT_HOST` placeholder로 이 URI를 받으며, iOS URL scheme은 `GOOGLE_REVERSED_IOS_CLIENT_ID`와 `fuelarena`를 등록합니다.

Before release, run `--check-supabase-live`; Google OAuth provider and redirect allow-list are considered ready only when both the web origin and `fuelarena://login-callback` authorize URLs redirect to `accounts.google.com`.

로그아웃은 설정 화면과 프로필 화면에서 모두 제공하며 `AppSessionService.signOut()`을 통해 Google SDK 캐시, Supabase 세션, 보안 세션 힌트, 사용자별 로컬 주행 큐와 설정 힌트를 함께 정리합니다.

## Legal disclosure URLs

Web build에는 스토어 제출과 공개 고지를 위한 정적 legal 페이지가 포함됩니다. 배포 도메인이 정해지면 아래 경로를 개인정보 처리방침, 위치정보 이용 고지, 계정 삭제 안내 URL로 사용할 수 있습니다.

- `/legal/privacy/`
- `/legal/location/`
- `/legal/account-deletion/`
- `/legal/terms/`
