# Google Auth Database Audit

## Scope
Flutter Google Sign-In은 앱에서 처리하지만, 로그인 이후 Supabase DB는 `auth.users` 생성, `public.profiles` bootstrap, RLS, 동의 이력, 개인정보 요청, 감사 로그를 안전하게 보장해야 한다.

## Current Findings
1. `profiles` 테이블: `202606050001_initial_schema.sql`에 존재한다.
2. `auth.users` -> `profiles` trigger: `202606090002_google_auth_profile_bootstrap.sql`에 있었고, `202606110001_google_auth_database_hardening.sql`에서 `handle_new_auth_user()`와 login update trigger로 보강했다.
3. `profiles.last_login_at`: 존재하며 trigger/RPC가 갱신한다.
4. `profiles.auth_provider`: 존재하며 `google`, `mock`, `admin_import`으로 제한한다.
5. onboarding/setup flags: `onboarding_completed`, `consent_completed`, `additional_setup_completed`, `vehicle_setup_completed` 존재.
6. `profiles` RLS: 본인 select/update/insert와 admin select/update가 분리되어 있다.
7. protected field: 기존 column grant만으로는 부족했으나 `prevent_profile_protected_field_update()` trigger와 secure RPC로 보강했다.
8. `consent_logs`: 기존 boolean snapshot 테이블이 있었고, consent type/version/revoke metadata 컬럼과 `record_my_consent()`/`revoke_my_consent()` RPC를 추가했다.
9. `account_deletion_requests`: 신규 전용 queue 테이블을 추가했다.
10. `data_export_requests`: 신규 전용 queue 테이블을 추가했다.
11. `auth_audit_logs`: 신규 인증 감사 로그 테이블과 `record_auth_event()` RPC를 추가했다.
12. `admin_audit_logs`: 신규 관리자 감사 테이블을 추가했다. 기존 `admin_action_logs`는 앱 대시보드 호환용으로 유지한다.
13. public profile view: `public_profiles_view` 신규 추가.
14. public ranking view: 기존 `public_rankings` 외에 `public_rankings_view` 신규 추가.
15. admin helper: 기존 `is_admin_user()`에 더해 `is_admin()`과 `current_user_role()`을 추가했다.
16. public table RLS: 기존 schema validator가 모든 생성 public table의 RLS를 검사하고, 새 validator가 auth DB 핵심 테이블을 추가 검사한다.
17. `user_vehicles`, `drive_sessions`, `drive_points`, `notifications`, `user_subscriptions`: 기존 self RLS가 있으며 새 RLS validator가 필수 대상으로 검사한다.

## P0 Issues Fixed
- profiles 자동 생성 trigger 이름과 login update 보정 RPC 보강.
- 일반 사용자의 `is_admin`, `is_premium`, `tier`, score, streak, selected league/class, status, `last_login_at` 직접 변경 차단.
- 전용 `account_deletion_requests`, `data_export_requests`, `auth_audit_logs`, `admin_audit_logs` 추가.
- 공개 view에서 email, Google subject, last login, status/deleted marker, raw route/drive point 좌표 제외.
- token, idToken, accessToken, refreshToken, OAuth client secret, email metadata는 `record_auth_event()`에서 제거.

## P1 Beta Items
- Supabase local에서 `supabase/tests/google_auth_rls_tests.sql`을 실제 role/JWT fixture로 실행해 수동 결과를 캡처한다.
- Edge Function delete/export 처리기가 새 전용 queue와 기존 `privacy_requests`를 같이 읽도록 확장한다.
- 관리자 대시보드가 `admin_audit_logs`에도 액션을 기록하도록 후속 연결한다.

## Migration Added
- `supabase/migrations/202606110001_google_auth_database_hardening.sql`

## Validation Added
- `tool/validate_google_auth_database.dart`
- `tool/security/check_auth_rls_policies.dart`
- `supabase/tests/google_auth_rls_tests.sql`
