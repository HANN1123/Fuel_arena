# Google Auth Implementation Audit

작성일: 2026-06-09

## 현재 로그인 화면 파일
- `lib/features/auth/presentation/login_screen.dart`
- Google 로그인 CTA만 노출한다.
- 이메일/비밀번호 입력 필드는 초기 버전에서 표시하지 않는다.
- 로그인 성공 후 `consentCompleted`, `vehicleSetupCompleted` 상태에 따라 `/consent`, `/setup`, `/home`으로 이동한다.

## 현재 AuthRepository 구조
- 실제 인터페이스와 구현은 `lib/shared/repositories/fuel_arena_repositories.dart`에 있다.
- `lib/features/auth/data/auth_repository.dart`는 shared repository의 auth 타입을 re-export한다.
- `AuthRepository`는 Google 로그인, 현재 사용자 복구, auth state stream, 로그아웃, 계정 삭제 요청 큐 진입을 제공한다.
- `SupabaseGoogleAuthRepository`는 `google_sign_in` 7.2 API의 `GoogleSignIn.instance.initialize()`와 `authenticate()`를 사용한다.
- native Google `idToken`과 `accessToken`을 Supabase `signInWithIdToken(OAuthProvider.google)`로 전달한다.
- Web은 Google SDK 직접 토큰 흐름 대신 Supabase OAuth redirect를 사용한다.

## MockAuthRepository
- `MockAuthRepository`가 존재한다.
- dev 환경에서 Supabase 또는 Google OAuth 설정이 빠지면 mock Google 로그인으로 fallback한다.
- staging/production에서는 mock auth repository를 선택하지 않고 startup config error로 막는다.

## Supabase 초기화 구조
- `lib/app/bootstrap.dart`에서 `AppConfig`와 `StartupChecks`를 거친 뒤 `Supabase.initialize()`를 호출한다.
- Supabase URL/anon key가 없으면 dev에서는 mock 흐름을 허용하고 staging/production에서는 앱 시작을 막는다.
- `lib/supabase/supabase_client_provider.dart`는 설정된 Supabase client를 Provider로 노출한다.

## .env 처리 방식
- `lib/app/app_config.dart`가 `.env` 또는 `--dart-define` 값을 읽는다.
- 환경별 키(`SUPABASE_URL_DEV`, `SUPABASE_URL_STAGING`, `SUPABASE_URL_PRODUCTION` 등)를 우선 사용한다.
- 기존 release preflight 호환을 위해 공통 alias(`SUPABASE_URL`, `GOOGLE_WEB_CLIENT_ID` 등)를 fallback으로 유지한다.
- Flutter client에는 anon key와 OAuth client ID만 사용한다.
- `SUPABASE_SERVICE_ROLE_KEY`, Google OAuth client secret, refresh token은 Flutter 앱에 넣지 않는다.

## Google 로그인 패키지
- `pubspec.yaml`에 `google_sign_in: ^7.2.0`이 포함되어 있다.
- `supabase_flutter`, `flutter_dotenv`, `flutter_secure_storage`, `shared_preferences`, `go_router`, `flutter_riverpod`도 포함되어 있다.

## Profile 생성 방식
- 클라이언트는 Google 로그인 성공 후 `profiles` row를 조회하고 없으면 안전한 identity/setup 컬럼만 insert한다.
- 기존 row가 있으면 nickname은 비어 있을 때만 Google metadata로 채우고, 점수/권한 컬럼은 쓰지 않는다.
- `supabase/migrations/202606090002_google_auth_profile_bootstrap.sql`이 `auth.users` insert trigger로 최초 profile row를 자동 생성한다.
- `last_login_at`은 trigger와 클라이언트 profile repair에서 갱신한다.

## Session restore
- `AppSessionService.restore()`가 `authRepository.currentUser()`로 Supabase session/current user를 복구한다.
- profile row가 없으면 `ensureProfileAfterGoogleLogin()`으로 복구한다.
- 완료 상태는 server profile과 local hint를 함께 반영한다.

## Logout / delete account
- 로그아웃은 Google SDK signOut과 Supabase signOut을 모두 호출한다.
- 로그아웃 후 local session hint, offline queue, 사용자별 provider cache를 정리한다.
- 직접 계정 삭제 API는 즉시 삭제하지 않고 개인정보 요청 큐로 안내한다.
- `deleteAccountRequest()`와 개인정보 설정 화면은 `privacy_requests.account_deletion` 요청을 생성한다.

## 이메일/비밀번호 UI 위치
- `/auth/login`과 `/auth/signup` 모두 `LoginScreen`을 사용한다.
- 현재 로그인 화면에는 이메일/비밀번호 필드가 없다.
- legacy `loginWithEmail`/`signUp` 메서드는 초기 버전에서 UnsupportedError로 막는다.

## 수정 대상 파일 목록
- `lib/app/app_config.dart`
- `lib/app/app_environment.dart`
- `lib/app/bootstrap.dart`
- `lib/app/startup_checks.dart`
- `lib/core/errors/config_exception.dart`
- `lib/core/widgets/config_error_screen.dart`
- `lib/features/auth/presentation/login_screen.dart`
- `lib/shared/models/fuel_arena_models.dart`
- `lib/shared/providers/repository_providers.dart`
- `lib/shared/repositories/fuel_arena_repositories.dart`
- `.env.example`
- `.env.production.example`
- `supabase/migrations/202606090002_google_auth_profile_bootstrap.sql`
- `docs/07_supabase_setup.md`
- `docs/44_google_oauth_setup_guide.md`

## P0 이슈
- 실제 Google Cloud OAuth client ID와 Supabase Google Provider 설정은 외부 콘솔에서 완료해야 한다.
- production Supabase migration 적용 후 trigger와 RLS policy를 SQL editor에서 검증해야 한다.
- Android release SHA-1/SHA-256과 iOS reversed client ID가 실제 배포 인증서와 일치해야 한다.
- Flutter SDK PATH가 없는 환경에서는 `flutter analyze`/`flutter test`가 실패할 수 있으므로 CI와 로컬 SDK 절대 경로 검증이 필요하다.

## P1 이슈
- Web OAuth redirect allow list에는 배포 origin과 로컬 검증 origin을 명시해야 한다.
- 계정 삭제 요청 처리 SLA와 관리자 처리 화면 운영 절차를 runbook에 계속 보강해야 한다.
- auth state stream 기반 guard로 전환할 수 있지만, 현재는 기존 `restoredSessionProvider` 라우팅을 유지해 회귀 위험을 줄였다.
