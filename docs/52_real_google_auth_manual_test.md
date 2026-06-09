# 실제 구글 로그인 수동 테스트 시나리오 (Google Auth Manual Test Cases)

본 문서는 Fuel Arena의 구글 로그인 연동이 정상적으로 작동하는지 빌드 레벨 및 플랫폼별로 수동 확인하기 위한 전체 검증 매뉴얼입니다.

---

## Scenario A: dev mock login (개발 모드 모의 로그인)
- **사전 조건**:
  - `.env`에 `APP_ENV=dev` 설정. Google Client ID 및 Supabase 설정이 비어 있거나 없는 상태.
- **절차**:
  - 앱을 기동합니다 (`flutter run`).
  - 로그인 화면에 노출되는 `dev mock 로그인` 배지를 확인합니다.
  - `Google로 시작하기` 버튼을 탭합니다.
- **기대 결과**:
  - Native 동의 화면 호출 없이 모의 유저 데이터가 생성되어 `/consent` (동의화면)으로 즉시 라우팅됩니다.
  - 로그아웃 버튼을 눌러 다시 로그인 화면으로 정상 복귀되는지 확인합니다.
- **실패 시 확인할 대상**:
  - [app_config.dart](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/lib/app/app_config.dart) 내 `canUseMockRepositories` 결정 조건
  - [repository_providers.dart](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/lib/shared/providers/repository_providers.dart)의 `authRepositoryProvider`

---

## Scenario B: staging real Google login (스테이징 실제 로그인)
- **사전 조건**:
  - `.env`에 `APP_ENV=staging` 및 `STAGING_ALLOW_MOCK_AUTH=false` 설정.
  - Staging용 Supabase URL, Anon key, Google Client ID(Web/Android/iOS) 전체 구성 완료.
- **절차**:
  - 앱을 기동합니다 (`flutter run --dart-define=APP_ENV=staging`).
  - `Google로 시작하기`를 탭하고 구글 어카운트를 하나 선택해 동의합니다.
- **기대 결과**:
  - 실제 구글 계정으로 로그인 후 Supabase 세션 토큰이 클라이언트에 안전하게 내려오며, `/consent` 또는 대표 차량 설정이 안 되어 있다면 `/setup` 화면으로 진입합니다.
- **실패 시 확인할 대상**:
  - Google Cloud OAuth Consent Screen 설정 상태
  - Supabase Dashboard Google Provider 활성화 및 Web Client ID/Secret 정확성

---

## Scenario C: production missing config (운영 모드 설정 누락 차단)
- **사전 조건**:
  - `.env`에 `APP_ENV=production` 설정.
  - `GOOGLE_WEB_CLIENT_ID_PRODUCTION` 등 필수 설정 중 하나를 의도적으로 비우거나 비정상적인 포맷으로 주입.
- **절차**:
  - 앱을 빌드 및 구동합니다.
- **기대 결과**:
  - 앱이 메인 화면이나 로그인 화면으로 조용히 실패하지 않고, `ConfigErrorScreen` 카드를 띄워 시작을 완벽히 차단해야 합니다.
  - 화면 하단에 민감한 실제 주입값이나 API Key의 정보가 마스킹 처리되어 있음을 확인합니다.
- **실패 시 확인할 대상**:
  - [startup_checks.dart](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/lib/app/startup_checks.dart)
  - [config_error_screen.dart](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/lib/core/widgets/config_error_screen.dart)

---

## Scenario D: token leakage check (토큰 유출 여부 검사)
- **사전 조건**:
  - 로컬 환경 및 에뮬레이터에서 Staging/Production 실 로그인을 수행하는 상태.
- **절차**:
  - 로그인 및 세션 갱신을 번갈아 유도하면서 IDE의 디버그 콘솔 및 터미널의 Logcat 출력을 확인합니다.
- **기대 결과**:
  - `idToken`, `accessToken`, `refreshToken` 문자열이 로깅되거나 출력되는 구문이 전혀 없어야 합니다.
- **실패 시 확인할 대상**:
  - `tool/auth/check_auth_logs.dart` 스크립트를 재구동하여 잔존 print문 스캔
  - [safe_logger.dart](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/lib/core/utils/safe_logger.dart) 작동 여부

---

## Scenario E: profile bootstrap (프로필 자동 연동 검증)
- **사전 조건**:
  - Supabase DB에 마이그레이션이 반영되어 있는 Staging/Production 실제 Google 로그인.
- **절차**:
  - 처음 가입하는 구글 신규 계정으로 로그인을 시도합니다.
- **기대 결과**:
  - DB의 `auth.users` 테이블에 신규 UUID가 할당됨과 동시에 `public.profiles` 테이블에 동일 ID의 프로필이 자동 인서트되고, 관리자 플래그(`is_admin`, `is_premium`)는 기본값인 `false`로 격리되어 있어야 합니다.
- **실패 시 확인할 대상**:
  - DB Migration SQL 트리거 및 RLS Insert 정책 정의부

---

## Scenario F: session restore (세션 자동 복구 검증)
- **사전 조건**:
  - 실제 구글 계정으로 로그인 완료되어 메인 화면에 진입해 있는 상태.
- **절차**:
  - 앱을 완전히 종료(Task Kill) 처리합니다.
  - 다시 앱을 구동시킵니다.
- **기대 결과**:
  - 스플래시 화면을 거친 후 로그인 화면으로 떨어지지 않고, 백그라운드 세션 복원(`restoredSessionProvider`)을 통해 바로 메인 홈 화면(`/home`)으로 진구되어야 합니다.
- **실패 시 확인할 대상**:
  - [app_services.dart](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/lib/shared/services/app_services.dart) 내 `AppSessionService.restore()` 로직

---

## Scenario G: sign out (로그아웃 세션 클리어)
- **사전 조건**:
  - 앱에 유효한 구글/Supabase 세션이 수립되어 있는 상태.
- **절차**:
  - 설정 -> `로그아웃`을 선택하거나 `개발자 인증 진단` -> `로그아웃 테스트`를 탭합니다.
- **기대 결과**:
  - 로컬의 세션 힌트, 주행 큐, 캐시가 초기화되고, Supabase 세션이 null 처리된 후 `/auth/login` 화면으로 이동해야 합니다.
  - 다시 로그인 시도 시 구글 SSO 계정 선택 동의 팝업이 다시 정상적으로 로출되어야 합니다.
- **실패 시 확인할 대상**:
  - `AppSessionService.signOut()` 호출 결과 및 `google_sign_in` 패키지의 `signOut()` 호출 예외 발생 여부.

---

## Scenario H: account deletion request (계정 삭제 요청 프로세스)
- **사전 조건**:
  - 로그인에 성공한 상태.
- **절차**:
  - 설정 -> `권한과 데이터` -> `계정 삭제(탈퇴) 요청`을 진행합니다.
- **기대 결과**:
  - 탈퇴 요청 시 `user_privacy_requests` 테이블에 삭제 요청 레코드가 등록되고, 즉시 로그아웃되어 로그인 화면으로 차단되어야 합니다.
- **실패 시 확인할 대상**:
  - `public.user_privacy_requests` RLS Insert 정책
