# Supabase Setup

1. Supabase 프로젝트를 생성한다.
2. `.env`에 active `APP_ENV`에 맞는 `SUPABASE_URL_<ENV>`과 `SUPABASE_ANON_KEY_<ENV>`를 설정한다.
3. Supabase Authentication Providers에서 Google을 활성화한다.
4. `supabase db push` 또는 Dashboard SQL editor로 migration을 적용한다.
5. `supabase functions deploy calculate_drive_score`처럼 각 Edge Function을 배포한다.
6. Storage bucket `vehicle-images`를 생성한다.
7. service_role key는 Edge Function secrets에만 저장하고 Flutter 앱에는 넣지 않는다.

## 실행 모드
- dev: Supabase 또는 Google 키가 없어도 mock repository 사용
- staging: Supabase와 Google OAuth 설정 필수. 누락 시 설정 오류 화면 표시
- production: Supabase와 Web/Android/iOS/Server Google OAuth client, iOS reversed client ID, `fuelarena://login-callback` callback 설정 필수. live ad와 실제 IAP 상품 필요

## Google OAuth 값

`.env.example`의 값을 실제 콘솔 설정에서 채운다.

```bash
APP_ENV=dev
SUPABASE_URL_DEV=
SUPABASE_ANON_KEY_DEV=
GOOGLE_WEB_CLIENT_ID_DEV=
GOOGLE_ANDROID_CLIENT_ID_DEV=
GOOGLE_IOS_CLIENT_ID_DEV=
GOOGLE_SERVER_CLIENT_ID_DEV=
GOOGLE_REVERSED_IOS_CLIENT_ID_DEV=

SUPABASE_URL_PRODUCTION=
SUPABASE_ANON_KEY_PRODUCTION=
GOOGLE_WEB_CLIENT_ID_PRODUCTION=
GOOGLE_ANDROID_CLIENT_ID_PRODUCTION=
GOOGLE_ANDROID_RELEASE_PACKAGE_NAME=com.fuelarena.fuel_arena
GOOGLE_ANDROID_RELEASE_SHA1=
GOOGLE_ANDROID_RELEASE_SHA256=
GOOGLE_IOS_CLIENT_ID_PRODUCTION=
GOOGLE_SERVER_CLIENT_ID_PRODUCTION=
GOOGLE_REVERSED_IOS_CLIENT_ID_PRODUCTION=
AUTH_REDIRECT_SCHEME=fuelarena
AUTH_REDIRECT_HOST=login-callback
```

Android/iOS는 Google ID token/access token을 Supabase `signInWithIdToken(OAuthProvider.google)`로 교환한다. Android는 Google Cloud Console에 package name, release SHA-1, release SHA-256을 등록하고 같은 값을 `.env.production`의 `GOOGLE_ANDROID_RELEASE_PACKAGE_NAME`, `GOOGLE_ANDROID_RELEASE_SHA1`, `GOOGLE_ANDROID_RELEASE_SHA256`에 기록한다. release preflight는 package name과 fingerprint 형식을 검사한다. Android manifest는 `APP_AUTH_REDIRECT_SCHEME`/`APP_AUTH_REDIRECT_HOST` placeholder로 `fuelarena://login-callback` OAuth callback을 받는다. 앱 런타임은 `AUTH_REDIRECT_SCHEME`/`AUTH_REDIRECT_HOST`를 우선 읽고, 기존 native placeholder와 release preflight를 위해 `APP_AUTH_REDIRECT_*` alias도 유지할 수 있다. iOS는 bundle ID와 reversed client ID를 등록하고 `ios/Flutter/FuelArenaSecrets.xcconfig.example`를 `FuelArenaSecrets.xcconfig`로 복사해 `GIDClientID`, `GIDServerClientID`, `CFBundleURLTypes`, `ADMOB_IOS_APP_ID`에 들어갈 build setting 값을 채운다. `GOOGLE_REVERSED_IOS_CLIENT_ID`는 `GOOGLE_IOS_CLIENT_ID`의 `.apps.googleusercontent.com` 앞부분과 정확히 짝이어야 한다.

Web은 Supabase OAuth redirect를 사용한다. Supabase Redirect URL allow list에는 `fuelarena://login-callback`, production Web origin, staging Web origin, 로컬 확인용 `http://127.0.0.1:5173`을 추가한다. Google Cloud Web OAuth client에는 Supabase Auth callback URL을 등록하고, Supabase Google provider에는 Web client id/secret을 설정한다. 앱 초기화는 Supabase Auth `AuthFlowType.pkce`와 `detectSessionInUri: true`를 명시해 Web/native callback 진입 시 세션 복구가 켜져 있어야 한다.

Google OAuth client secret은 Supabase Dashboard에만 입력한다. Flutter 앱 `.env`에는 Google OAuth client secret, Supabase service role key, refresh token을 넣지 않는다.

## Profile bootstrap

`202606090002_google_auth_profile_bootstrap.sql`은 `auth.users`에 Google 사용자가 생성되면 `public.profiles` row를 자동 생성하는 trigger를 추가한다. `202606110001_google_auth_database_hardening.sql`은 이 흐름을 `handle_new_auth_user()`, `handle_auth_user_login_update()`, `ensure_my_profile()`로 보강해 기존 auth user의 누락 profile도 복구하고 `last_login_at`을 갱신한다.

클라이언트는 `update_my_profile()`, `record_my_consent()`, `set_my_profile_vehicle()`, `request_account_deletion()`, `request_data_export()` RPC를 우선 사용한다. `prevent_profile_protected_field_update()` trigger는 `tier`, `total_score`, `season_score`, `current_streak`, `best_streak`, `is_premium`, `is_admin`, `status`, `deleted_at`, Google subject, 대표 차량/리그 선택 같은 보호 필드의 직접 변경을 차단한다.

## Google Auth DB hardening 확인 SQL

```sql
select tgname from pg_trigger
where tgname in ('on_auth_user_created', 'on_auth_user_login_updated');

select id, email, nickname, auth_provider, last_login_at
from public.profiles
order by created_at desc
limit 5;

select policyname, tablename
from pg_policies
where schemaname = 'public'
  and tablename in ('profiles', 'consent_logs', 'account_deletion_requests', 'data_export_requests', 'auth_audit_logs');

select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'public_rankings_view';
```

## 차량 카탈로그와 리그

`202606060001_google_vehicle_leagues.sql`은 profiles onboarding 컬럼, fuel_leagues, 차량 카탈로그, user_vehicles, league_memberships, ranking/battle 리그 컬럼을 추가한다. `202606060002_vehicle_catalog_seed.sql`은 `assets/data/vehicle_catalog_kr_seed.json` 기준의 2008-2026 제조사/모델/연식/파워트레인 카탈로그와 fuel_leagues seed를 채운다.

