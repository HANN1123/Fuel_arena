# Supabase Setup

1. Supabase 프로젝트를 생성한다.
2. `.env`에 `SUPABASE_URL`과 `SUPABASE_ANON_KEY`를 설정한다.
3. Supabase Authentication Providers에서 Google을 활성화한다.
4. `supabase db push` 또는 Dashboard SQL editor로 migration을 적용한다.
5. `supabase functions deploy calculate_drive_score`처럼 각 Edge Function을 배포한다.
6. Storage bucket `vehicle-images`를 생성한다.
7. service_role key는 Edge Function secrets에만 저장하고 Flutter 앱에는 넣지 않는다.

## 실행 모드
- dev: Supabase 또는 Google 키가 없어도 mock repository 사용
- staging: Supabase 필수, Google OAuth 권장, test ad unit 사용
- production: Supabase와 Google OAuth 필수, live ad와 실제 IAP 상품 필요

## Google OAuth 값

`.env.example`의 값을 실제 콘솔 설정에서 채운다.

```bash
GOOGLE_WEB_CLIENT_ID=
GOOGLE_ANDROID_CLIENT_ID=
GOOGLE_IOS_CLIENT_ID=
GOOGLE_SERVER_CLIENT_ID=
GOOGLE_REVERSED_IOS_CLIENT_ID=
APP_AUTH_REDIRECT_SCHEME=fuelarena
APP_AUTH_REDIRECT_HOST=login-callback
```

Android/iOS는 Google ID token/access token을 Supabase `signInWithIdToken(OAuthProvider.google)`로 교환한다. Android는 Google Cloud Console에 package name, SHA-1, SHA-256을 등록한다. Android manifest는 `APP_AUTH_REDIRECT_SCHEME`/`APP_AUTH_REDIRECT_HOST` placeholder로 `fuelarena://login-callback` OAuth callback을 받는다. iOS는 bundle ID와 reversed client ID를 등록하고 `ios/Flutter/FuelArenaSecrets.xcconfig.example`를 `FuelArenaSecrets.xcconfig`로 복사해 `GIDClientID`, `GIDServerClientID`, `CFBundleURLTypes`, `ADMOB_IOS_APP_ID`에 들어갈 build setting 값을 채운다.

Web은 Supabase OAuth redirect를 사용한다. Supabase Redirect URL allow list에는 `fuelarena://login-callback`, production Web origin, staging Web origin, 로컬 확인용 `http://127.0.0.1:5173`을 추가한다. Google Cloud Web OAuth client에는 Supabase Auth callback URL을 등록하고, Supabase Google provider에는 Web client id/secret을 설정한다.

## 차량 카탈로그와 리그

`202606060001_google_vehicle_leagues.sql`은 profiles onboarding 컬럼, fuel_leagues, 차량 카탈로그, user_vehicles, league_memberships, ranking/battle 리그 컬럼을 추가한다. `202606060002_vehicle_catalog_seed.sql`은 `assets/data/vehicle_catalog_kr_seed.json` 기준의 2008-2026 제조사/모델/연식/파워트레인 카탈로그와 fuel_leagues seed를 채운다.

