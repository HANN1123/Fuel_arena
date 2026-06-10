# Google Auth Database RLS Test Plan

## Purpose
Google 로그인 후 DB가 일반 사용자, 관리자, 공개 view를 명확히 분리하는지 검증한다. 테스트 SQL은 `supabase/tests/google_auth_rls_tests.sql`에 있다.

## Scenarios
1. anonymous cannot select profiles directly.
2. `user_a` can select own profile.
3. `user_a` cannot select `user_b` private profile fields.
4. `user_a` can update own nickname.
5. `user_a` cannot update `is_admin`.
6. `user_a` cannot update `is_premium`.
7. `user_a` cannot update `total_score`.
8. `user_a` can insert own `consent_logs`.
9. `user_a` cannot select `user_b` consent logs.
10. `user_a` can request account deletion through RPC.
11. `user_a` cannot select `user_b` account deletion request.
12. `user_a` cannot select `user_b` `drive_points`.
13. `public_rankings_view` is readable and exposes no email, route, or drive point data.
14. Vehicle catalog view read succeeds.
15. Vehicle catalog write fails for non-admin.
16. Admin can review `custom_vehicle_requests`.
17. Admin can update `app_settings`.
18. 일반 사용자는 `app_settings.is_public = true` row만 읽는다.

## How To Run
1. Apply migrations to a disposable Supabase local database.
2. Create or map three auth users for `user_a`, `user_b`, and `admin`.
3. Run `supabase/tests/google_auth_rls_tests.sql` in `psql` or Supabase SQL editor.
4. Expected result: read scenarios return allowed rows only; forbidden update/insert statements fail with RLS or protected field exceptions.

## Static Gates
Run:

```bash
dart run tool/validate_google_auth_database.dart
dart run tool/validate_supabase_schema.dart
dart run tool/security/check_auth_rls_policies.dart
python tool/validate_secret_hygiene.py
```

## Manual SQL Checks
```sql
select tgname from pg_trigger where tgname in ('on_auth_user_created', 'on_auth_user_login_updated');
select * from information_schema.columns where table_schema = 'public' and table_name = 'profiles';
select schemaname, tablename, policyname from pg_policies where schemaname = 'public';
select column_name from information_schema.columns where table_schema = 'public' and table_name = 'public_rankings_view';
```
