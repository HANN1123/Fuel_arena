# Agent Progress: Google Auth Database Hardening

## Current Phase
- Verification & Documentation (Completed)

## Completed
- Audited existing Supabase migrations, RLS notes, Flutter repository mappings, and env/docs.
- Added `202606110001_google_auth_database_hardening.sql`.
- Added `auth.users` bootstrap/update triggers:
  - `handle_new_auth_user()`
  - `handle_new_auth_user_profile()`
  - `handle_auth_user_login_update()`
- Added profile repair and safe client RPCs:
  - `ensure_my_profile()`
  - `update_my_profile()`
  - `set_my_profile_vehicle()`
  - `record_my_consent()`
  - `revoke_my_consent()`
  - `request_account_deletion()`
  - `request_data_export()`
  - `record_auth_event()`
  - `get_my_auth_state()`
- Added protected profile field trigger:
  - `prevent_profile_protected_field_update()`
- Added/expanded DB tables:
  - `account_deletion_requests`
  - `data_export_requests`
  - `auth_audit_logs`
  - `admin_audit_logs`
  - expanded `consent_logs`
- Added safe public views:
  - `public_profiles_view`
  - `public_rankings_view`
  - `public_user_primary_vehicle_view`
- Added validation and RLS test artifacts:
  - `tool/validate_google_auth_database.dart`
  - `tool/security/check_auth_rls_policies.dart`
  - `supabase/tests/google_auth_rls_tests.sql`
- Updated Flutter Supabase repositories to prefer secure RPCs for profile repair, consent save, representative vehicle sync, account deletion request, and data export request.
- Updated privacy request handling so dedicated `account_deletion_requests` / `data_export_requests` queue states map safely back into the existing settings UI and duplicate active request checks.
- Updated docs:
  - `docs/04_data_schema.md`
  - `docs/07_supabase_setup.md`
  - `docs/08_rls_policy_notes.md`
  - `docs/46_auth_rls_policy_matrix.md`
  - `docs/54_google_auth_database_audit.md`
  - `docs/55_google_auth_database_rls_test_plan.md`
  - `README.md`
  - `AGENTS.md`
- Applied the resume SQL to the connected Supabase project through Chrome/Supabase SQL Editor after fixing:
  - UTF-8-safe generated SQL concatenation for Korean seed text
  - `vehicle_catalog_view` recreation with `source_status`, `confidence_score`, `is_selectable`, and `is_deprecated`
  - `subscription_plans.benefits` JSONB casts

## Verification Results
- `flutter pub get`: PASS
- `dart format .`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, 217 tests passed
- `dart run tool/validate_google_auth_database.dart`: PASS, 93 checks
- `dart run tool/validate_supabase_schema.dart`: PASS, 377 checks
- `dart run tool/security/check_auth_rls_policies.dart`: PASS, 73 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/validate_product_invariants.dart`: PASS, 1896 checks
- `git diff --check`: PASS, CRLF normalization warnings only
- Supabase SQL Editor resume execution: PASS, `Success. No rows returned`
- Live Supabase schema smoke check: PASS, required auth/RLS objects exist and `public_tables_without_rls = 0`

## Blockers
- Supabase CLI is not available on PATH in this environment, so local `supabase db reset`, `supabase db push`, and `supabase migration list` were not run here.
- Google Cloud Console and Supabase Dashboard provider setup remain external configuration tasks.

## Next Actions
- Run `supabase/tests/google_auth_rls_tests.sql` against a disposable/staging database with real test users.
- Deploy/update Edge Functions that process `account_deletion_requests` and `data_export_requests`.
