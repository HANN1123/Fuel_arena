# Agent Progress: Google Auth Database Hardening

## Current Phase
- Verification & Documentation (Completed)

## 2026-06-13 Vehicle Catalog Official Homepage Audit

### Completed
- Continued the vehicle generation selection/catalog audit without reverting the generation UX.
- Added official-homepage boundary migrations:
  - `202606130025_domestic_homepage_boundary_audit.sql`
  - `202606130026_hyundai_kia_homepage_boundary_audit.sql`
  - `202606130027_lexus_lx_ls500_official_model_audit.sql`
  - `202606130028_volvo_ex40_ec40_official_name_audit.sql`
- Locked Genesis, Chevrolet, Renault Korea, KGM, Hyundai, and Kia placeholder powertrains to `pending_review`, `is_selectable=false`, and null numeric specs unless a row has official/admin verification.
- Added Lexus LX as an official Korea model-page row and added LS 500 as an LS gasoline powertrain candidate from Lexus Korea official model navigation/JSON; both remain `pending_review`, `is_selectable=false`.
- Added Volvo EX40 and EC40 as official Korea rename/support rows for the 2025+ XC40 Recharge/C40 Recharge naming boundary; both remain `pending_review`, `is_selectable=false`.
- Preserved K3 GT as a K3 trim/powertrain, not a separate model.
- Preserved K3 split reference rows as pending/non-selectable while keeping their engine/transmission shape for audit continuity.
- Promoted the Avante CN7 2024 `1.6 가솔린 / Smartstream G1.6 / IVT` representative row to `verified_official` using the Hyundai official price PDF so the Avante CN7 example flow remains available.
- Regenerated:
  - `assets/data/vehicle_catalog_kr_seed.json`
  - `assets/data/vehicle_catalog_kr_sample.csv`
  - `supabase/seed_vehicle_catalog.sql`
- Current seed is 22 manufacturers, 241 models, 296 generations, 1671 model years, and 2818 variants.
- Selectable unverified variants are now 0; selectable rows are official/admin sourced only.

### Verification Results
- `dart run tool/validate_vehicle_catalog.dart`: PASS
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 1030 checks
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS
- `flutter test`: PASS, 227 tests
- `git diff --check`: PASS, LF/CRLF normalization warnings only

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

## 2026-06-11 Google Auth Live Setup Follow-up

### Completed
- Inspected local env/config/auth files for staging Google login readiness.
- Created local gitignored `.env.staging` with staging mode, Supabase staging URL/key copied from local config, and blank Google/legal slots for user-provided console values.
- Confirmed current local Supabase project ref is `vzxbltofwjxkoonisoyx`.
- Inspected Supabase Dashboard through Chrome:
  - Project: `Fuel_Arena`
  - Google Provider: disabled
  - Callback URL: `https://vzxbltofwjxkoonisoyx.supabase.co/auth/v1/callback`
  - Redirect allow-list: `fuelarena://login-callback`, `http://127.0.0.1:5173`, `http://localhost:3000`, `http://localhost:5173`
- Inspected Google Cloud Console through Chrome:
  - Current project id: `bustling-gate-486207-a1`
  - Display name: `My Project 84625`
  - Google Auth Platform: not configured
  - OAuth 2.0 clients: none
- Ran Android signing report and captured debug package/cert inputs:
  - package: `com.fuelarena.fuel_arena`
  - debug SHA-1/SHA-256 recorded in `docs/GOOGLE_AUTH_CONSOLE_CHECKLIST.md`
- Added live setup docs:
  - `docs/GOOGLE_AUTH_LIVE_SETUP.md`
  - `docs/GOOGLE_AUTH_CONSOLE_CHECKLIST.md`
  - `docs/GOOGLE_AUTH_LIVE_TEST_RESULT.md`
- Updated `tool/auth/check_google_auth_env.dart` to merge `.env` with `.env.staging` / `.env.production` before validating strict staging/production auth config.
- Added `tool/security/scan_secrets.dart` for tracked/unignored source secret pattern scanning.

### Current Blockers
- Supabase Google Provider cannot be enabled until the user creates or selects the correct Google Cloud OAuth project and provides Web Client ID/Secret in the Supabase Dashboard.
- The inspected Google Cloud project is not configured for Google Auth Platform and has no OAuth clients.
- `.env.staging` still needs Google Web/Android/iOS/Server Client IDs, Reversed iOS Client ID, and legal/support URLs.

## 2026-06-12 Google Auth Live Setup Recheck

### Completed
- Re-read the attached continuation request and rechecked open Chrome console tabs.
- Confirmed Supabase Dashboard project ref remains `vzxbltofwjxkoonisoyx`.
- Confirmed Supabase Dashboard displays `Fuel_Arena` with `main PRODUCTION` label.
- Confirmed Authentication > Sign In / Providers still lists Google as disabled.
- Confirmed URL Configuration redirect allow-list is unchanged:
  - `fuelarena://login-callback`
  - `http://127.0.0.1:5173`
  - `http://localhost:3000`
  - `http://localhost:5173`
- Confirmed Google Cloud project `bustling-gate-486207-a1` / `My Project 84625` still has Google Auth Platform not configured.
- Confirmed Google Cloud credentials page still has no OAuth 2.0 clients.

### Current Blockers
- Provider changes were not applied because the connected Supabase project is labeled `main PRODUCTION`; staging target confirmation or a separate staging project is required first.
- Google OAuth consent screen, Web OAuth Client, Android OAuth Client, iOS OAuth Client, test users, and local `.env.staging` client IDs remain pending.

### Verification
- `flutter pub get`: PASS
- `dart format .`: PASS, 0 files changed
- `flutter analyze`: PASS
- `flutter test`: PASS, 217 tests
- `dart run tool/auth/check_google_auth_env.dart --env staging`: FAIL as expected until Google OAuth client IDs are configured
- `dart run tool/auth/check_auth_routes.dart`: PASS
- `dart run tool/auth/check_auth_logs.dart`: PASS
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `dart run tool/validate_google_auth_database.dart`: PASS, 93 checks
- `dart run tool/validate_supabase_schema.dart`: PASS, 377 checks
- `dart run tool/security/check_auth_rls_policies.dart`: PASS, 73 checks
- `flutter build apk --debug`: PASS
- `flutter build web`: PASS

## 2026-06-12 Google Auth Live Continuation Recheck

### Completed
- Rechecked Supabase Auth Providers in Chrome: Google remains disabled.
- Rechecked Supabase URL Configuration in Chrome: native/local redirect URLs are unchanged.
- Rechecked Google Auth Platform in Chrome: `My Project 84625` remains not configured.
- Rechecked Google Cloud credentials in Chrome: no OAuth 2.0 clients exist.
- Rechecked Supabase organization project list: only `Fuel_Arena` / `vzxbltofwjxkoonisoyx` is visible.
- Rechecked Supabase Branching: only `main` is listed as `PRODUCTION BRANCH`.
- Confirmed no persistent staging branch exists; persistent branches require an upgrade on the current free organization.
- Confirmed no preview branch currently exists.
- Rechecked Google Cloud resource manager: only `My Project 84625` / `bustling-gate-486207-a1` is visible.
- Re-ran `dart run tool/auth/check_google_auth_env.dart --env staging`: still fails on missing `GOOGLE_WEB_CLIENT_ID_STAGING`.
- Re-ran code and DB/RLS verification after the branch inspection:
  - `flutter pub get`: PASS
  - `dart format .`: PASS, 0 files changed
  - `flutter analyze`: PASS
  - `flutter test`: PASS, 217 tests
  - `dart run tool/auth/check_auth_routes.dart`: PASS
  - `dart run tool/auth/check_auth_logs.dart`: PASS
  - `python tool/validate_secret_hygiene.py`: PASS
  - `dart run tool/security/scan_secrets.dart`: PASS
  - `dart run tool/validate_google_auth_database.dart`: PASS, 93 checks
  - `dart run tool/validate_supabase_schema.dart`: PASS, 377 checks
  - `dart run tool/security/check_auth_rls_policies.dart`: PASS, 73 checks
  - `git diff --check`: PASS, CRLF normalization warnings only

## 2026-06-12 Google Auth Live Blocked Recheck

### Completed
- Rechecked local `.env.staging` without printing secret values:
  - Supabase staging URL/key are present locally.
  - Google Web/Android/iOS/Server Client IDs remain blank.
  - Reversed iOS Client ID remains blank.
  - legal/support URLs remain blank.
- Rechecked open Chrome console tabs:
  - Supabase Provider tab is still on `vzxbltofwjxkoonisoyx`.
  - Supabase Branching tab is still on `Fuel_Arena`.
  - Supabase org Projects tab is still `HANN1123's Org`.
  - Google Cloud Credentials tab is still `My Project 84625`.
  - Google Cloud Resource Manager tab is still open.
- Detailed Supabase page extraction timed out twice during this continuation, so no production/provider setting was changed.
- Re-ran `dart run tool/auth/check_google_auth_env.dart --env staging`: FAIL, still missing `GOOGLE_WEB_CLIENT_ID_STAGING`.

### Blocked State
- The same blocker has repeated across the original external-console attempt and subsequent continuations.
- No safe staging target is identifiable without user action.
- The goal cannot proceed to Supabase Provider enablement or live Google login verification until the user creates/selects staging resources or explicitly authorizes the currently visible `main PRODUCTION` project to be used for staging.

## 2026-06-12 Web OAuth Client ID Received

### Completed
- Added the user-provided Google Web OAuth Client ID to local `.env.staging`.
- Set the same value as `GOOGLE_SERVER_CLIENT_ID_STAGING`.
- Did not store any Google OAuth Client Secret locally.
- Re-ran `dart run tool/auth/check_google_auth_env.dart --env staging`: FAIL, now missing `GOOGLE_ANDROID_CLIENT_ID_STAGING`.
- Re-ran secret checks:
  - `python tool/validate_secret_hygiene.py`: PASS
  - `dart run tool/security/scan_secrets.dart`: PASS

### Remaining
- Enable Supabase Google Provider with the Web Client ID and Web Client Secret in the Supabase dashboard.
- Create Android OAuth Client and add its Client ID to `.env.staging`.
- Create iOS OAuth Client and add Client ID/Reversed Client ID to `.env.staging`.
- Fill legal/support URLs.

### Blocked State
- The same external console blocker has repeated across multiple goal continuations.
- Further completion requires user action:
  - Confirm whether `vzxbltofwjxkoonisoyx` / `main PRODUCTION` may be used as staging, or provide a separate staging Supabase project.
  - If `vzxbltofwjxkoonisoyx` is production, create/select a separate Supabase staging project before provider changes.
  - Confirm whether `My Project 84625` may be used for Fuel Arena staging, or create/select the intended Google Cloud staging project.
  - Configure Google Auth Platform for the intended staging Google Cloud project.
  - Create Web/Android/iOS OAuth clients.
  - Enter the Web Client ID/Secret in Supabase Google Provider.
  - Add Client IDs and legal/support URLs to local `.env.staging`.

## 2026-06-12 Chrome OAuth Client Setup Continued

### Completed
- Used the logged-in Chrome Google Cloud session for `My Project 84625`.
- Confirmed the user-provided Web OAuth client exists.
- Created the Android OAuth client for the debug package/fingerprint and added its Client ID to local `.env.staging`.
- Created the iOS OAuth client for `com.fuelarena.fuelArena` and added its Client ID plus reversed iOS client ID to local `.env.staging`.
- Added local staging legal URLs pointing to the existing static Web legal pages. These are staging-only placeholders until a real HTTPS deployment domain exists.
- Re-ran `dart run tool/auth/check_google_auth_env.dart --env staging`: PASS.
- Re-ran secret hygiene checks:
  - `python tool/validate_secret_hygiene.py`: PASS
  - `dart run tool/security/scan_secrets.dart`: PASS
- Created a new Google Web OAuth client secret for Supabase Provider use. The secret was not written to Flutter env files, docs, source, or logs.

### Remaining
- Supabase Google Provider save is not complete. Chrome automation became blocked by an open Chrome extension UI while filling the Supabase Provider form.
- The Google Cloud Web client details tab should remain open until Supabase Provider is saved, because the newly created secret is only available in the live browser state and must not be recorded in repo files or chat.
- After the Chrome extension UI is dismissed, continue from Supabase Authentication > Sign In / Providers > Google and save:
  - Google Provider enabled
  - Client IDs: Web, Android, iOS
  - Client Secret: latest Web OAuth secret
  - Skip nonce checks: disabled
  - Allow users without an email: disabled

## 2026-06-12 Supabase Google Provider Saved

### Completed
- Reopened Supabase Authentication > Sign In / Providers > Google in a fresh Chrome-controlled tab for project `vzxbltofwjxkoonisoyx`.
- Saved the Google Provider with:
  - Google Provider enabled
  - Web, Android, and iOS Client IDs
  - the latest Google Web OAuth Client Secret
  - Skip nonce checks disabled
  - Allow users without an email disabled
- Confirmed the Supabase provider list now shows `Google` as `Enabled`.
- Confirmed Supabase authorize redirects:
  - `redirect_to=http://127.0.0.1:5173`: `302` to `accounts.google.com/o/oauth2/v2/auth`
  - `redirect_to=fuelarena://login-callback`: `302` to `accounts.google.com/o/oauth2/v2/auth`
- Did not write the Google OAuth Client Secret to Flutter env files, docs, source, logs, or local scripts.
- Re-ran verification after Provider save:
  - `flutter pub get`: PASS
  - `dart format .`: PASS, 0 changed
  - `flutter analyze`: PASS
  - `flutter test`: PASS, 217 tests
  - `dart run tool/auth/check_google_auth_env.dart --env staging`: PASS
  - `dart run tool/validate_google_auth_database.dart`: PASS, 93 checks
  - `dart run tool/validate_supabase_schema.dart`: PASS, 377 checks
  - `dart run tool/security/check_auth_rls_policies.dart`: PASS, 73 checks
  - `python tool/validate_secret_hygiene.py`: PASS
  - `dart run tool/security/scan_secrets.dart`: PASS
  - `git diff --check`: PASS, CRLF normalization warnings only

### Remaining
- Configure/confirm Google Auth Platform consent screen, audience, scopes, and test users in the connected Google Cloud project.
- Replace local staging legal URL placeholders with the real HTTPS deployment domain before release.
- Create release Android OAuth client with release SHA-1 before production distribution.

## 2026-06-12 Live Google Login Verified

### Completed
- Ran the local staging web app at `http://localhost:3000` using `.env.staging` via `--dart-define-from-file`.
- Started the real Google OAuth flow from the Fuel Arena Google-only login screen.
- Found and fixed the Google Web OAuth Client `redirect_uri_mismatch` by adding the Supabase callback URL to Authorized redirect URIs.
- Retried the login and completed Google account selection plus consent.
- Confirmed the app returned to Fuel Arena and rendered `/consent`, a protected route that requires a restored Supabase user/profile.
- Saved required consent with optional ads/marketing left unchecked.
- Confirmed routing advanced to `/setup`.
- Reloaded the page and confirmed `/setup` remained available, verifying session restore.
- Did not record tokens, callback code, OAuth Client Secret, refresh token, ID token, or service role key in docs, source, logs, or env files.
- Re-ran the required verification set after the live login:
  - `flutter pub get`: PASS
  - `dart format .`: PASS, 0 changed
  - `flutter analyze`: PASS
  - `flutter test`: PASS, 217 tests
  - `dart run tool/auth/check_google_auth_env.dart --env staging`: PASS
  - `dart run tool/validate_google_auth_database.dart`: PASS, 93 checks
  - `dart run tool/validate_supabase_schema.dart`: PASS, 377 checks
  - `dart run tool/security/check_auth_rls_policies.dart`: PASS, 73 checks
  - `python tool/validate_secret_hygiene.py`: PASS
  - `dart run tool/security/scan_secrets.dart`: PASS
  - `git diff --check`: PASS, CRLF normalization warnings only

### Remaining
- Confirm Google Auth Platform branding/audience/test-user settings before broader external testing.
- Replace local staging legal URL placeholders with real HTTPS legal document URLs before release.
- Create production Android OAuth credentials from release signing fingerprints.
- Use a separate staging Supabase project/branch before broader release-grade testing; the connected project is still labeled `main PRODUCTION`.
## 2026-06-13 Genesis/Renault/KGM Official Lineup Continued

### Completed
- Officialized the next domestic/high-impact catalog batch from manufacturer official pages:
  - Genesis: G70, G70 Shooting Brake, G80, Electrified G80, G90, GV60, GV70, Electrified GV70, GV80, GV80 Coupe.
  - Renault Korea: SM6, QM6, XM3, Arkana, Grand Koleos, Filante.
  - KG Mobility: Tivoli, Korando, Actyon, Actyon Hybrid, Torres, Torres Hybrid, Torres EVX, Rexton, Rexton Sports, Musso, Musso EV.
- Added explicit model IDs for split/current official lineup models, including Genesis Electrified models, Renault Arkana/Filante, KGM Actyon/Torres/Musso derivatives.
- Kept official-page-missing code names blank and kept older insufficiently sourced rows such as Renault SM6/QM6/XM3 and KGM Korando as `pending_review`.
- Added Supabase migration `202606130004_genesis_renault_kgm_official_lineup_audit.sql`.
- Regenerated JSON catalog, Supabase seed SQL, generation import templates, and coverage docs.

### Verification
- `dart run tool/validate_vehicle_catalog.dart`: PASS
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 691 checks
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, 166 generations and 65 models without generation
- `dart run tool/validate_product_invariants.dart`: PASS
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS
- `flutter test`: PASS, 227 tests
- `flutter build web --dart-define=APP_ENV=dev`: PASS
- `python tool/verify_web_core_routes.py --base-url http://127.0.0.1:6173`: PASS, 14 routes
- `git diff --check`: PASS, CRLF normalization warnings only

### Remaining
- Next official homepage coverage priorities by current report were Volkswagen, Toyota, Porsche, Lexus, Honda, Nissan, MINI, Peugeot, Jeep, Land Rover, and Polestar; this was continued in the next section.
- Detailed official powertrain specs for the newly added Genesis/Renault/KGM models still need a second pass before any `is_verified=true` powertrain promotion.

## 2026-06-13 Imported Official Lineup And Missing Models Continued

### Completed
- Connected the remaining imported/manufacturer seed models to conservative official-homepage `공식 라인업` generations for Volkswagen, Toyota, Lexus, Honda, Nissan, Tesla, Porsche, MINI, Peugeot, Jeep, Land Rover, and Polestar.
- Added explicit missing official-page models: Toyota Alphard, Lexus LM, MINI Aceman, Peugeot 408, Jeep Gladiator, Jeep Grand Cherokee L, Land Rover Discovery Sport, and Range Rover Velar.
- Kept the new official-lineup generations as `pending_review`; no unsupported data was promoted to `verified_official`.
- Added Supabase migrations `202606130005_remaining_imported_lineup_generation_audit.sql` and `202606130006_missing_official_lineup_models_generation_audit.sql`.
- Regenerated JSON catalog, Supabase seed SQL, generation import template, and coverage docs.

### Verification
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 184 models / 239 generations / 1723 years / 2897 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 783 checks
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 239 generation rows recognized
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, 227 tests
- `flutter build web --dart-define=APP_ENV=dev`: PASS
- `python tool/verify_web_core_routes.py --base-url http://127.0.0.1:6173`: PASS, 14 routes
- `git diff --check`: PASS, CRLF normalization warnings only

### Remaining
- Detailed generation code/platform and domestic powertrain spec audits are still pending for the broad `공식 라인업` imported rows.
- Continue official homepage/model page sweep for newly marketed derivatives before marking this catalog goal complete.

## 2026-06-13 BMW Official Lineup Gap Continued

### Completed
- Re-checked BMW Korea official model lineup and added missing official-page models: X2, X4, X6, XM, Z4, i7, iX1, iX2, and i3.
- Added explicit model IDs and conservative `공식 라인업` generation rows for the 2026 current lineup only, avoiding unsupported historical sales ranges.
- Kept BMW placeholder powertrains `pending_review` and `is_selectable=false`.
- Added Supabase migration `202606130007_bmw_missing_official_lineup_models.sql` with model/year/generation/powertrain placeholders.
- Regenerated JSON catalog, Supabase seed SQL, generation import template, and coverage docs.

### Verification
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 193 models / 248 generations / 1732 years / 2906 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 793 checks
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 248 generation rows recognized
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, 227 tests
- `flutter build web --dart-define=APP_ENV=dev`: PASS
- `python tool/verify_web_core_routes.py --base-url http://127.0.0.1:6173`: PASS, 14 routes
- `git diff --check`: PASS, CRLF normalization warnings only

### Remaining
- Continue the same official lineup gap pass for Mercedes-Benz, Audi, and Volvo current derivative models.
- BMW model code/platform/powertrain details remain pending until official spec sheets or BMW PressClub sources are audited model-by-model.

## 2026-06-13 Mercedes/Audi Official Lineup Gap Continued

### Completed
- Re-checked Mercedes-Benz Korea official model overview and added missing official-page model groups: S-Class Long, Mercedes-Maybach S-Class, EQE SUV, Mercedes-Maybach EQS SUV, GLB, GLC Coupé, GLE Coupé, Mercedes-Maybach GLS, G-Class, CLA Coupé, CLE Coupé, Mercedes-AMG GT Coupé, Mercedes-AMG GT 4-Door Coupé, CLE Cabriolet, SL Roadster, and Mercedes-Maybach SL Monogram Series.
- Re-checked Audi Korea official model overview and added missing current model groups: e-tron GT, A6 e-tron, and Q6 e-tron.
- Added explicit model IDs and conservative `공식 라인업` generation rows for 2026 current-lineup coverage only.
- Added a shared locked official-lineup placeholder policy so these newly added rows use `pending_review`, `is_selectable=false`, and no invented displacement/battery values until official domestic specification sheets are audited.
- Added Supabase migration `202606130008_mercedes_audi_official_lineup_gap_models.sql` and regenerated JSON catalog, Supabase seed SQL, generation import template, and coverage docs.

### Verification
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 212 models / 1751 years / 2930 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 267 generation rows recognized
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 212 models / 267 generations / 1751 years / 2930 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 814 checks
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, 227 tests
- `flutter build web --dart-define=APP_ENV=dev`: PASS
- `python tool/verify_web_core_routes.py --base-url http://127.0.0.1:6173`: PASS, 14 routes
- `git diff --check`: PASS, CRLF normalization warnings only

### Remaining
- Continue official homepage sweeps for any Volvo/Jeep/MINI body-style edge cases that are confirmed as model groups rather than trims.
- Mercedes-Benz/Audi detailed generation code/platform and official domestic powertrain spec audits remain pending before any row is promoted beyond `pending_review`.

## 2026-06-13 Volvo/MINI/Hyundai/Kia/Volkswagen/Lexus Official Lineup Gap Continued

### Completed
- Re-checked official Korea model/home pages for Volvo, Jeep, MINI, Hyundai, Kia, Chevrolet, Genesis edition pages, Volkswagen, Toyota, Honda, Porsche, and Lexus.
- Added official-page/current-lineup rows for Volvo EX30 Cross Country and ES90; MINI Cooper 5-Door, All-Electric MINI Cooper, All-Electric MINI Countryman, and John Cooper Works; Hyundai Venue, CASPER Electric, IONIQ 5 N, IONIQ 6 N, IONIQ 9, NEXO, STARIA Electric, and ST1; Kia EV4, EV5, PV5, and Tasman; Volkswagen Golf GTI, Atlas, and ID.5; Lexus LC and RC.
- Kept Jeep Trail Hunt, Carnival Hi-Limousine, Kia EV GT labels, and K3 GT as edition/trim/powertrain candidates rather than standalone verified model rows.
- Added hydrogen league support for NEXO with `fuel_league=hydrogen` and `efficiency_unit=km/kg`.
- Added Supabase migrations `202606130009_volvo_mini_official_lineup_gap_models.sql`, `202606130010_hyundai_kia_official_lineup_gap_models.sql`, `202606130011_volkswagen_official_lineup_gap_models.sql`, and `202606130012_lexus_official_model_page_gap_models.sql`.
- Regenerated JSON catalog, Supabase seed SQL, generation import template, and coverage docs.

### Verification
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 235 models / 1775 years / 2955 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 290 generation rows recognized / 2 powertrain links
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 235 models / 290 generations / 1775 years / 2955 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 878 checks
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, 290 generations, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, 227 tests

### Remaining
- Continue with official homepage sweeps for Toyota/Honda/Porsche model-page boundaries and domestic spec sheets.
- Do not promote newly added placeholder powertrains to `verified_official` until official 국내 제원표/가격표 evidence is attached.

## 2026-06-13 Toyota/Honda/Porsche Official Boundary Continued

### Completed
- Re-checked Toyota Korea and Honda Korea official pages. Toyota homepage/current model pages did not require a new model row in this pass, and Honda Korea's online showroom currently exposes Accord Hybrid, CR-V Hybrid, Odyssey, and Pilot only.
- Re-checked Porsche Korea Macan/Cayenne official pages and treated Macan Electric/Cayenne Electric as official model versions under the existing Macan/Cayenne app models, not standalone model rows.
- Added Supabase migration `202606130013_porsche_electric_powertrain_boundaries.sql` to remove pre-2026 Macan/Cayenne electric placeholders and keep only 2026 pending electric candidates with null specification values.
- Added generator and validator guards so Porsche Macan/Cayenne electric variants must not predate 2026.
- Regenerated JSON catalog, Supabase seed SQL, generation import template, and coverage docs.

### Verification
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 235 models / 1775 years / 2944 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 290 generation rows / 2 explicit powertrain links
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 235 models / 290 generations / 1775 years / 2944 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 886 checks
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, 227 tests

### Remaining
- Continue manufacturer-by-manufacturer official spec audits for newly added 2026 current-lineup rows before promoting any placeholder powertrain to `verified_official`.
- Detailed generation code/platform splits remain pending for imported official-lineup rows that only have homepage-level evidence.

## 2026-06-13 Tesla/Jeep/Polestar/Peugeot Official Gap Continued

### Completed
- Re-checked official Korea/current pages for Tesla, Peugeot, Jeep, Land Rover, Polestar, and Nissan-facing archive coverage.
- Added Tesla Cybertruck as a 2026 current official Korea page row. Tesla Model Y L appears inside the Model Y page as a model version, so it stays under Model Y rather than becoming a standalone model row.
- Added Jeep Avenger as a 2024~current official model row using the Jeep Avenger model page plus official EV battery information page.
- Added Polestar 5 as an upcoming 2026 Korea launch row with `is_upcoming=true`, `is_current=false`, `is_selectable=false`.
- Updated Peugeot 308/3008/5008/408 to include 2026 SMART HYBRID pending powertrain candidates from the official Peugeot Korea lineup page.
- Added Supabase migration `202606130014_tesla_jeep_polestar_peugeot_official_gap_models.sql`, updated generation import template, regenerated JSON catalog, Supabase seed SQL, and coverage docs.

### Verification
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 238 models / 1780 years / 2953 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 293 generation rows / 2 explicit powertrain links
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 238 models / 293 generations / 1780 years / 2953 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 902 checks
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, 227 tests

### Remaining
- Continue detailed official spec-sheet audits for imported/manufacturer rows before promoting any pending placeholder powertrain to `verified_official`.
- Nissan Korea is service/archive-heavy rather than an active new-car lineup source, so its existing rows remain conservative pending/archive coverage unless stronger current official evidence is found.

## 2026-06-13 Honda/Nissan Official Status Continued

### Completed
- Re-checked Honda Korea official online showroom and official notice page. The current showroom exposes Accord Hybrid, CR-V Hybrid, Odyssey, and Pilot; Civic and HR-V are therefore kept as Korea-unconfirmed placeholders with `is_current=false`, `is_selectable=false`, and locked non-selectable variants until domestic official evidence is found.
- Re-checked Nissan Korea official withdrawal notice and Leaf launch notice. Nissan Korea rows are no longer current: Altima/Maxima/Rogue are limited to 2015~2020 archive rows, Leaf is limited to 2019~2020, and Ariya is kept as a single 2026 Korea-unconfirmed non-selectable placeholder.
- Added Supabase migration `202606130015_honda_nissan_official_status_audit.sql` to deprecate old post-2020 Nissan placeholders, clear their generation links, and lock Honda Civic/HR-V plus Nissan Ariya placeholder variants.
- Added generator and validator guards so Nissan Korea rows cannot regenerate 2021~2026 years, Honda Civic/HR-V stay non-current/non-selectable, and Ariya remains non-selectable.
- Extended `generation_template.csv` and the generation importer with optional `is_selectable` support so manual generation imports do not reopen Korea-unconfirmed placeholders.
- Regenerated JSON catalog, Supabase seed SQL, CSV sample, and coverage docs.

### Verification
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 238 models / 1741 years / 2914 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- Honda/Nissan generated row inspection: PASS, Civic/HR-V/Ariya selectable variants 0; Nissan Altima/Maxima/Rogue years 2015~2020; Leaf years 2019~2020; Ariya year 2026 only.
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 293 generation rows / 2 explicit powertrain links
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 238 models / 293 generations / 1741 years / 2914 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 908 checks
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, 227 tests

### Remaining
- Continue manufacturer-by-manufacturer official spec-sheet audits before promoting any homepage/archive placeholder powertrain to `verified_official`.
- Honda Civic/HR-V and Nissan Ariya require domestic official model evidence before becoming selectable.

## 2026-06-13 Toyota/Lexus Official Powertrain Audit Continued

### Completed
- Re-checked Toyota Korea official model pages for Prius HEV/PHEV, Camry, RAV4 HEV/PHEV, Highlander, Sienna, Crown, Alphard, and GR86.
- Promoted only 2026 Toyota powertrain rows with official Toyota Korea fuel-economy/displacement evidence to `verified_official`, `is_selectable=true`.
- Locked Toyota 2025-and-earlier official-lineup placeholder variants as `pending_review`, `is_selectable=false`, with null numeric specification values until year-specific official audits are done.
- Re-checked Lexus Korea official electrified/model pages for ES 300h, LS 500h, NX 350h/450h+, RX 350h/500h/450h+, UX 300h, RZ 450e, and LM 500h.
- Replaced Lexus 2026 fake `1.6` placeholder rows with official model-name/displacement pending rows, but kept them `pending_review`, `is_selectable=false` because complete official fuel-economy/spec audit remains open.
- Added Supabase migration `202606130016_toyota_lexus_official_powertrain_audit.sql`, generator overrides, and validator guards so Toyota/Lexus audited rows cannot regress to invented placeholder specs.
- Regenerated JSON catalog, Supabase seed SQL, CSV sample, and coverage docs.

### Verification
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 238 models / 1741 years / 2920 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- Toyota/Lexus generated row inspection: PASS, Toyota 2026 official rows are selectable/verified with Toyota sources; Lexus 2026 rows are pending/non-selectable with Lexus sources; older Toyota/Lexus placeholders are locked pending with null specs.
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 293 generation rows / 2 explicit powertrain links
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 238 models / 293 generations / 1741 years / 2920 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 922 checks
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, 227 tests
- `git diff --check`: PASS, CRLF normalization warnings only

### Remaining
- Continue official spec audits for remaining imported manufacturers and for Lexus detailed fuel-economy pages before promoting Lexus rows to `verified_official`.
- Toyota drivetrain/transmission fields marked `공식 제원 확인` should be tightened when a per-trim spec table is fully parsed.

## 2026-06-13 Land Rover Official Powertrain Audit Continued

### Completed
- Re-checked Land Rover Korea official 2026 price pages for Defender, Discovery, Range Rover, Range Rover Sport, Range Rover Evoque, Discovery Sport, and Range Rover Velar.
- Replaced Land Rover 2026 fake generated specs with official engine-code pending rows: Defender D250/D300/P300/P400/P635, Discovery D350/P300/P360, Range Rover P530/P615/P550e, Range Rover Sport P360/P400/P635/P550e, Evoque P250, Discovery Sport P250, Velar P250/P400/P400e.
- Added Velar PHEV fuel coverage for 2026 based on the official P400e price page row.
- Removed current-year generated combinations not visible on the 2026 official price pages, while keeping historical placeholders locked pending for future year-specific audit.
- Locked every Land Rover powertrain as `pending_review`, `is_selectable=false`, with null numeric specs because the official pages checked in this pass did not provide enough fuel-economy/displacement data for verified competition rows.
- Added Supabase migration `202606130017_landrover_official_powertrain_audit.sql`, generator overrides, and validator/schema guards for the Land Rover official boundary.
- Regenerated JSON catalog, Supabase seed SQL, CSV sample, and coverage docs.

### Verification
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 238 models / 1741 years / 2925 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- Land Rover generated row inspection: PASS, 2026 rows use official engine-code pending IDs and sources; all Land Rover variants are pending/non-selectable with null numeric specs; Velar PHEV is 2026-only.
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 293 generation rows / 2 explicit powertrain links
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 238 models / 293 generations / 1741 years / 2925 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 932 checks
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, 227 tests

### Remaining
- Continue imported manufacturer official powertrain audits, especially Volkswagen/MINI/Jeep/Porsche/Tesla/Polestar where selectable unverified placeholders remain.
- Promote Land Rover rows only after official per-model fuel-economy and displacement data is attached.

## 2026-06-13 Volkswagen Official Powertrain Audit Continued

### Completed
- Re-checked Volkswagen Korea official current model list and model pages. The current list exposes Atlas, Touareg, Golf, Golf GTI, ID.4, and ID.5.
- Parsed official Volkswagen Korea price-list PDFs for Golf, Golf GTI, Atlas, Touareg FINAL EDITION, ID.4, and ID.5.
- Promoted only price-list backed 2026 rows to `verified_official`, `is_selectable=true`: Golf 2.0 TDI Premium/Prestige, Golf GTI 2.0 TSI, Touareg 3.0 TDI FINAL EDITION Prestige/R-Line, Atlas 2.0 TSI 7인승/6인승, ID.4 Pro Lite/Pro (MY25 price list), and ID.5 Pro Lite/Pro (MY26).
- Removed 2026 generation/powertrain rows for Jetta, Passat, Tiguan, and Arteon because they are not in the current Volkswagen Korea model list; older placeholders remain `pending_review`, `is_selectable=false`, with null numeric specs.
- Added Supabase migration `202606130018_volkswagen_official_powertrain_audit.sql`, generator overrides, validator guards, and schema guard tokens for the Volkswagen official audit.
- Regenerated JSON catalog, Supabase seed SQL, CSV sample, and coverage docs.

### Verification
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 238 models / 1737 years / 2912 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- Volkswagen generated row inspection: PASS, 2026 current official rows are selectable/verified with Volkswagen price-list sources; Jetta/Passat/Tiguan/Arteon have no 2026 rows and no selectable placeholder variants.
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 293 generation rows / 2 explicit powertrain links
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 238 models / 293 generations / 1737 years / 2912 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 945 checks
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, 227 tests
- `git diff --check`: PASS, CRLF normalization warnings only

### Remaining
- Continue imported manufacturer official powertrain audits, especially MINI/Jeep/Porsche/Tesla/Polestar/Peugeot where selectable unverified placeholders remain.
- Volkswagen ID.4 rows are selectable from the 2026 official price list, but retain `(MY25)` in trim names because the official PDF labels the technical specifications as MY25.

## 2026-06-13 Peugeot Official Powertrain Audit Continued

### Completed
- Re-checked Peugeot Korea official homepage/range page and confirmed the current official lineup exposes 5008 SMART HYBRID, 3008 SMART HYBRID, 408 SMART HYBRID, and 308 SMART HYBRID.
- Parsed the official Peugeot Korea model pages for 308/3008/5008/408 SMART HYBRID and promoted only page-backed 2026 Allure/GT rows to `verified_official`, `is_selectable=true`.
- Recorded model-specific official combined efficiency values: 308 15.2km/L, 3008 14.6km/L, 5008 13.3km/L, and 408 14.1km/L; all use 1,199cc Smart Hybrid, FWD, and 6단 듀얼 클러치 자동변속기(e-DCS6).
- Removed current-year selectable placeholders for 208/2008 because they are not present in the current Peugeot Korea model lineup; their older placeholder rows remain `pending_review`, `is_selectable=false`, with null numeric specs.
- Added Supabase migration `202606130019_peugeot_official_powertrain_audit.sql`, generator overrides, validator guards, schema guard tokens, and documentation for the Peugeot official audit.
- Regenerated JSON catalog, Supabase seed SQL, CSV sample, and coverage docs.

### Verification
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 238 models / 1699 years / 2824 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- Peugeot generated row inspection: PASS, 308/3008/5008/408 2026 Allure/GT rows are selectable `verified_official` with Peugeot Korea model-page sources; 208/2008 have no 2026 rows and no selectable placeholder variants.
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 293 generation rows / 2 explicit powertrain links
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 238 models / 293 generations / 1699 years / 2824 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 953 checks
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks

### Remaining
- Continue imported manufacturer official powertrain audits, especially MINI/Jeep/Porsche/Tesla/Polestar where selectable unverified placeholders remain.
- Peugeot 208/e-208 and 2008/e-2008 should only be reopened after an official current Korea lineup/model-page source is found.

## 2026-06-13 Tesla Official Efficiency Audit Continued

### Completed
- Re-checked Tesla Korea official model pages for Model 3, Model Y, Model S, Model X, and Cybertruck, plus Tesla Korea's official `한국공인연비` support page.
- Promoted only certified-efficiency rows present in the Tesla Korea official support table to `verified_official`, `is_selectable=true`: Model 3 Standard RWD/Premium Long Range RWD/Performance, Model Y Premium RWD/Premium Long Range AWD, Model S AWD/Plaid, and Model X AWD/Plaid.
- Derived `battery_kwh` from the official table's battery rated voltage and current capacity values (`V * Ah / 1000`) instead of using the old generated 64/90kWh placeholders.
- Kept Model Y L as `pending_review`, `is_selectable=false` because the Model Y page shows the version but the official certified-efficiency table does not yet include it.
- Kept Cybertruck `pending_review`, `is_selectable=false` because it is not present in the official Korea certified-efficiency table.
- Added Supabase migration `202606130020_tesla_official_efficiency_audit.sql`, generator overrides, validator guards, schema guard tokens, and documentation for the Tesla official audit.
- Regenerated JSON catalog, Supabase seed SQL, CSV sample, and coverage docs.

### Verification
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 238 models / 1699 years / 2830 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- Tesla generated row inspection: PASS, 2026 Model S/3/X/Y official rows are selectable `verified_official`; Model Y L and Cybertruck remain pending/non-selectable with null numeric efficiency.
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 293 generation rows / 2 explicit powertrain links
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 238 models / 293 generations / 1699 years / 2830 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 964 checks
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks

### Remaining
- Continue imported manufacturer official powertrain audits, especially MINI/Jeep/Porsche/Polestar where selectable unverified placeholders remain.
- Reopen Tesla Model Y L and Cybertruck only after Tesla Korea's official certified-efficiency table includes their domestic efficiency rows.

## 2026-06-13 Polestar Official Efficiency Audit Continued

### Completed
- Re-checked Polestar Korea official specifications pages for Polestar 2 and Polestar 4, plus official Polestar 3 and Polestar 5 pages.
- Promoted only official domestic efficiency rows to `verified_official`, `is_selectable=true`: Polestar 2 Standard range Single motor, Long range Single motor, Long range Dual motor, and Polestar 4 coupé Rear motor, Dual motor, Dual motor Performance package.
- Removed historical generated Polestar placeholder years outside the 2026 official audit window.
- Kept Polestar 3 `pending_review`, `is_selectable=false` because the official page marks it as `2026년 2분기 출시 예정`.
- Kept Polestar 5 `pending_review`, `is_selectable=false` because the official page marks it as `2026년 국내 출시 예정`.
- Added Supabase migration `202606130021_polestar_official_efficiency_audit.sql`, generator overrides, validator guards, schema guard tokens, and documentation for the Polestar official audit.
- Regenerated JSON catalog, Supabase seed SQL, CSV sample, and coverage docs.

### Verification
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 238 models / 1666 years / 2801 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- Polestar generated row inspection: PASS, 2026 Polestar 2/4 official rows are selectable `verified_official`; Polestar 3/5 remain pending/non-selectable.
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 293 generation rows / 2 explicit powertrain links
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 238 models / 293 generations / 1666 years / 2801 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 973 checks
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks

### Remaining
- Continue imported manufacturer official powertrain audits, especially MINI/Jeep/Porsche where selectable unverified placeholders remain.
- Reopen Polestar 3/5 only after their Korea official certified efficiency/spec rows are published.

## 2026-06-13 MINI Official Boundary Audit Continued

### Completed
- Re-checked MINI Korea official home/model range and John Cooper Works pages for current visible model groups.
- Confirmed the official pages are sufficient for model-group existence, but not sufficient for competition-ready domestic certified efficiency/battery/displacement values across MINI rows.
- Locked every MINI powertrain placeholder to `pending_review`, `is_selectable=false`, `is_verified=false`, with null official efficiency, displacement, and battery values.
- Added Supabase migration `202606130022_mini_official_boundary_audit.sql`, generator lock-list coverage, validator guards, schema guard tokens, and documentation for the MINI boundary audit.
- Regenerated JSON catalog and Supabase seed SQL.

### Verification
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 238 models / 1666 years / 2801 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- MINI generated row inspection: PASS, 102 MINI variants are all pending/non-selectable/unverified with null numeric specs.
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, 293 generation rows / 2 explicit powertrain links
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 238 models / 293 generations / 1666 years / 2801 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 982 checks

### Remaining
- Continue imported manufacturer official powertrain audits, especially Jeep/Porsche where selectable unverified placeholders remain.
- Reopen MINI variants only after model-specific MINI Korea official spec sheets or certified efficiency tables are found.

## 2026-06-13 Chevrolet/KGM Official Homepage Gap Continued

### Completed
- Re-checked Chevrolet Korea's official SUV lineup page and added the missing Equinox model row as a conservative 2026 official-homepage placeholder.
- Reopened Chevrolet Traverse and Tahoe through 2026 because the official Chevrolet Korea SUV page still exposes them, but kept their powertrains `pending_review`, `is_selectable=false`, with null numeric specs until row-level domestic specification evidence is audited.
- Re-checked KGM official Korean model list from the website bundle. Korando remains a 2019~2024 pending row because it is not in the current Korean `MODEL_LIST`; the newly exposed official cards are Rexton Summit, Torres Van, and Torres EVX Van.
- Added KGM rows for Rexton Summit, Torres Van, and Torres EVX Van as 2026 `pending_review`, `is_selectable=false` placeholders with null numeric specs.
- Added Supabase migrations `202606130029_chevrolet_kgm_homepage_gap_audit.sql` and `202606130030_kgm_korean_model_list_gap_audit.sql`, updated generator overrides, validator guards, schema guard tokens, and generation import template rows.
- Regenerated JSON catalog, Supabase seed SQL, CSV sample, and coverage docs.

### Verification
- `dart format tool/generate_vehicle_catalog_seed.dart tool/validate_vehicle_catalog.dart tool/vehicle_catalog/validate_vehicle_catalog.dart tool/validate_supabase_schema.dart`: PASS
- `dart analyze tool/generate_vehicle_catalog_seed.dart tool/validate_vehicle_catalog.dart tool/vehicle_catalog/validate_vehicle_catalog.dart tool/validate_supabase_schema.dart`: PASS
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 245 models / 1678 years / 2825 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- Chevrolet/KGM generated row inspection: PASS, Equinox/Traverse/Tahoe plus KGM Rexton Summit/Torres Van/Torres EVX Van rows are pending/non-selectable with null numeric specs and official homepage source URLs.
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 22 manufacturers / 245 models / 300 generations / 1678 years / 2825 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 1043 checks
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, inserted generations 2 / updated generations 298 / linked model years 2 / linked variants 2 / powertrain links 2
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, models without generation 0, powertrains without generation 26, P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, all 227 tests passed
- `git diff --check`: PASS, CRLF normalization warnings only

### Remaining
- Continue official homepage/model-list sweeps for brands with hidden current model pages or commercial/taxi variants.
- Promote Chevrolet/KGM rows only after official row-level fuel economy/displacement/battery evidence is attached.

## 2026-06-13 Renault/BMW Official Homepage Gap Continued

### Completed
- Re-checked Renault Korea official model pages, Scenic E-Tech price list, and Scenic E-Tech e-brochure; added Scenic E-Tech as a conservative 2025~current official-homepage generation placeholder.
- Re-checked BMW Korea official all-models page; added official model-card gaps for 2 Series Gran Coupe, 8 Series, M2, M3, M4, M5, M8, X5 M, and X6 M.
- Kept all newly added Renault/BMW powertrain rows `pending_review`, `is_selectable=false`, `is_verified=false`, with null numeric specs until row-level domestic specification evidence is audited.
- Kept BMW M cars as separate models only where BMW Korea exposes separate official model cards; the K3 GT rule remains unchanged as a K3 trim/powertrain, not a standalone model.
- Added Supabase migration `202606130031_renault_bmw_official_gap_models.sql`, updated generator seeds, Supabase seed SQL, CSV sample, model coverage documentation, catalog guide notes, quality reports, and generation import template rows.

### Verification
- `dart format tool/generate_vehicle_catalog_seed.dart`: PASS
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 255 models / 1689 years / 2836 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- Renault/BMW generated row inspection: PASS, new rows are `pending_review`, non-selectable at powertrain level, non-verified, and carry official source URLs.
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, inserted generations 2 / updated generations 308 / linked model years 2 / linked variants 2 / powertrain links 2
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 22 manufacturers / 255 models / 310 generations / 1689 years / 2836 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 1043 checks
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, verified 51 / pending_review 2785 / models without generation 0 / powertrains without generation 26 / P0 failures 0
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter pub get`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, all 227 tests passed
- `git diff --check`: PASS, CRLF normalization warnings only

### Remaining
- Continue official homepage/model-list sweeps for brands with hidden current model pages, commercial variants, taxi variants, and separate performance model cards.
- Promote Renault/BMW rows only after official row-level fuel economy/displacement/battery evidence is attached.

## 2026-06-13 Kia Official Card Powertrain Placeholder Continued

### Completed
- Re-checked Kia Korea official EV, PBV, and taxi/bus/commercial lineup pages after the user pointed out that many official homepage cards were missing.
- Kept EV3/EV4/EV5/EV6/EV9 GT, PV5 body/taxi cards, K8 Taxi, and Bongo commercial/EV body cards under the existing model rows as powertrain/trim candidates rather than standalone vehicle_models.
- Added 19 official-card 2026 powertrain placeholders: Ray EV; EV3/EV3 GT; EV4/EV4 GT; EV5/EV5 GT; EV6/EV6 GT; EV9/EV9 GT; PV5 Passenger/Cargo/WAV/Openbed/Passenger Taxi/WAV Taxi; K8 Taxi; Bongo truck/body/EV body cards.
- Kept every new Kia card row `pending_review`, `is_selectable=false`, `is_verified=false`, with null displacement, battery, and official efficiency until row-level official spec evidence is audited.
- Added Supabase migration `202606130032_kia_official_card_powertrain_placeholders.sql`, regenerated catalog JSON/CSV and Supabase seed SQL, and updated docs for the model-vs-trim boundary.

### Verification
- `dart format tool/generate_vehicle_catalog_seed.dart`: PASS
- `dart run tool/generate_vehicle_catalog_seed.dart`: PASS, 22 manufacturers / 255 models / 1689 years / 2850 variants
- `dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql`: PASS
- Kia generated row inspection: PASS, 19 official-card rows are pending/non-selectable/non-verified with null numeric specs and official source URLs.
- `dart run tool/validate_vehicle_catalog.dart`: PASS, 22 manufacturers / 255 models / 310 generations / 1689 years / 2850 variants
- `dart run tool/vehicle_catalog/validate_vehicle_catalog.dart`: PASS
- `dart run tool/validate_supabase_schema.dart`: PASS, 1043 checks
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`: PASS, verified 51 / pending_review 2799 / models without generation 0 / powertrains without generation 26 / P0 failures 0
- `dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv --dry-run`: PASS, inserted generations 2 / updated generations 308 / linked model years 2 / linked variants 2 / powertrain links 2
- `dart run tool/validate_product_invariants.dart`: PASS, 1933 checks
- `python tool/validate_secret_hygiene.py`: PASS
- `dart run tool/security/scan_secrets.dart`: PASS
- `flutter analyze`: PASS, no issues found
- `flutter test`: PASS, all 227 tests passed

### Remaining
- Continue official homepage sweeps for remaining hidden body-style/performance/taxi/commercial cards, but keep card-like trim/body variants under existing models unless the manufacturer exposes a clearly separate model identity and row-level source.
- Promote Kia card rows only after official row-level fuel economy/displacement/battery evidence is attached.
