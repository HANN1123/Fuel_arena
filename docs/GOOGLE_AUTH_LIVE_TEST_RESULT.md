# Google Auth Live Test Result

Last updated: 2026-06-12

## Result Summary

Status: **Partially verified - Supabase Provider enabled, app login still not run**

Live staging Google login has not been fully verified yet because:

- Supabase Google Provider is now enabled and authorize redirects reach Google OAuth.
- A real Flutter app Google sign-in round trip has not been run yet.
- Google Auth Platform consent screen/test users still need final confirmation.
- The connected Supabase dashboard is labeled `main PRODUCTION`; a separate staging project remains recommended before broader release testing.

## Evidence Collected

Supabase Dashboard:

- Project ref: `vzxbltofwjxkoonisoyx`
- Project name shown: `Fuel_Arena`
- 2026-06-12 dashboard label shown: `main PRODUCTION`
- Google Provider status: `Enabled` as of the 2026-06-12 Provider save continuation
- Callback URL:
  `https://vzxbltofwjxkoonisoyx.supabase.co/auth/v1/callback`
- Redirect allow-list:
  - `fuelarena://login-callback`
  - `http://127.0.0.1:5173`
  - `http://localhost:3000`
  - `http://localhost:5173`

Google Cloud Console:

- Inspected project id: `bustling-gate-486207-a1`
- Display name: `My Project 84625`
- OAuth platform: not fully confirmed
- OAuth 2.0 clients: Web, Android debug, and iOS clients exist for this continuation; Client IDs are stored only in local gitignored env.

2026-06-12 Chrome recheck:

- Supabase Google Provider remains `Disabled`.
- Supabase URL Configuration remains native/local only.
- Google Auth Platform remains not configured in `My Project 84625`.
- Google credentials page still shows no OAuth 2.0 Client IDs.

2026-06-12 continuation recheck:

- Supabase Google Provider still remains `Disabled`.
- Supabase dashboard still shows `main PRODUCTION`.
- Supabase URL Configuration is unchanged.
- Google Auth Platform is still not configured.
- Google credentials page still shows no OAuth 2.0 Client IDs.

2026-06-12 external console setup attempt:

- Supabase organization project list shows only `Fuel_Arena` / `vzxbltofwjxkoonisoyx`.
- No separate Supabase staging project is visible.
- Supabase Branching page shows only `PRODUCTION BRANCH` -> `main`.
- No persistent staging branch is visible; the dashboard prompts to upgrade to unlock persistent branches.
- No preview branch is currently created.
- Google Cloud resource manager shows only `My Project 84625` / `bustling-gate-486207-a1`.
- No clearly named Fuel Arena staging Google Cloud project is visible.
- No provider/OAuth settings were changed because the visible Supabase project is labeled `main PRODUCTION`.

2026-06-12 blocked recheck:

- Local `.env.staging` still has blank Google OAuth Client IDs.
- Local `.env.staging` still has blank legal/support URLs.
- Open Chrome console tabs still target Supabase `vzxbltofwjxkoonisoyx` / `Fuel_Arena` and Google Cloud `My Project 84625`.
- Detailed Supabase page extraction timed out twice, so no external settings were changed.

2026-06-12 Web OAuth progress:

- User-provided Google Web OAuth Client ID was added to local `.env.staging`.
- The same Web Client ID was also set as `GOOGLE_SERVER_CLIENT_ID_STAGING` for native Google Sign-In server client configuration.
- Client Secret was not stored locally.
- Staging env validation now fails at the next required key: `GOOGLE_ANDROID_CLIENT_ID_STAGING`.

Android:

- `:app:signingReport`: PASS
- applicationId: `com.fuelarena.fuel_arena`
- Debug SHA-1:
  `00:F0:C0:17:78:64:38:52:8C:EA:87:A6:4E:A5:5C:E8:4A:6C:84:17`
- Debug SHA-256:
  `29:67:2C:C3:D6:F1:0D:32:E9:25:A9:64:DD:06:36:10:3F:C8:65:DF:2A:EB:30:73:A4:BD:A2:16:EB:1B:4C:10`

iOS:

- Bundle ID: `com.fuelarena.fuelArena`
- `Info.plist` contains Google client placeholders and `fuelarena` URL scheme.

Local env:

- `.env.staging`: created locally, gitignored
- Supabase staging URL/key: present locally
- Google staging Client IDs: present locally
- Client Secret: not stored locally

## Commands Run

| Command | Result | Notes |
|---|---|---|
| `.\gradlew --console=plain :app:signingReport` | PASS | Debug SHA-1/SHA-256 collected. |
| `dart run tool/auth/check_google_auth_env.dart --env staging` | FAIL | Missing `GOOGLE_WEB_CLIENT_ID_STAGING`; subsequent Google/legal keys still need to be filled. |
| `flutter pub get` | PASS | Dependencies resolved. |
| `dart format .` | PASS | Formatter completed. |
| `flutter analyze` | PASS | No issues found. |
| `flutter test` | PASS | 217 tests passed. |
| `dart run tool/auth/check_auth_routes.dart` | PASS | Google-only login/static route checks passed. |
| `dart run tool/auth/check_auth_logs.dart` | PASS | Raw token/session logging check passed. |
| `python tool/validate_secret_hygiene.py` | PASS | Git ignore and secret hygiene checks passed. |
| `dart run tool/security/scan_secrets.dart` | PASS | Tracked/unignored secret scan passed. |
| `dart run tool/validate_google_auth_database.dart` | PASS | 93 checks passed. |
| `dart run tool/validate_supabase_schema.dart` | PASS | 377 checks passed. |
| `dart run tool/security/check_auth_rls_policies.dart` | PASS | 73 checks passed. |
| `flutter build apk --debug` | PASS | Debug APK built. |
| `flutter build web` | PASS | Web build completed; wasm dry run succeeded. |
| 2026-06-12 Chrome Supabase provider recheck | FAIL | Google Provider remains disabled; connected dashboard is labeled `main PRODUCTION`. |
| 2026-06-12 Chrome Supabase URL recheck | PARTIAL | Redirect allow-list contains native/local URLs only; no hosted staging domain. |
| 2026-06-12 Chrome Google Auth Platform recheck | FAIL | `My Project 84625` still has Google Auth Platform not configured. |
| 2026-06-12 Chrome Google credentials recheck | FAIL | No OAuth 2.0 Client IDs exist in the inspected Google Cloud project. |
| 2026-06-12 `flutter pub get` | PASS | Dependencies resolved. |
| 2026-06-12 `dart format .` | PASS | Formatted 127 files; 0 changed. |
| 2026-06-12 `flutter analyze` | PASS | No issues found. |
| 2026-06-12 `flutter test` | PASS | 217 tests passed. |
| 2026-06-12 `dart run tool/auth/check_google_auth_env.dart --env staging` | FAIL | Expected while console setup is incomplete: missing `GOOGLE_WEB_CLIENT_ID_STAGING`. |
| 2026-06-12 `dart run tool/auth/check_auth_routes.dart` | PASS | Google-only login/static route checks passed. |
| 2026-06-12 `dart run tool/auth/check_auth_logs.dart` | PASS | Raw token/session logging check passed. |
| 2026-06-12 `python tool/validate_secret_hygiene.py` | PASS | Secret hygiene valid. |
| 2026-06-12 `dart run tool/security/scan_secrets.dart` | PASS | Tracked/unignored secret scan passed. |
| 2026-06-12 `dart run tool/validate_google_auth_database.dart` | PASS | 93 checks passed. |
| 2026-06-12 `dart run tool/validate_supabase_schema.dart` | PASS | 377 checks passed. |
| 2026-06-12 `dart run tool/security/check_auth_rls_policies.dart` | PASS | 73 checks passed. |
| 2026-06-12 `flutter build apk --debug` | PASS | Built `build\app\outputs\flutter-apk\app-debug.apk`. |
| 2026-06-12 `flutter build web` | PASS | Built `build\web`. |
| 2026-06-12 continuation Chrome Supabase provider recheck | FAIL | Google Provider remains disabled; connected dashboard is still labeled `main PRODUCTION`. |
| 2026-06-12 continuation Chrome Google Auth Platform recheck | FAIL | `My Project 84625` still has Google Auth Platform not configured. |
| 2026-06-12 continuation Chrome Google credentials recheck | FAIL | No OAuth 2.0 Client IDs exist in the inspected Google Cloud project. |
| 2026-06-12 Supabase organization project list inspection | BLOCKED | Only `Fuel_Arena` / `vzxbltofwjxkoonisoyx` is visible; no separate staging project found. |
| 2026-06-12 Supabase branching inspection | BLOCKED | Only `main` is shown as the production branch; no persistent staging branch exists on the current free organization. |
| 2026-06-12 Google Cloud resource manager inspection | BLOCKED | Only `My Project 84625` / `bustling-gate-486207-a1` is visible; no clearly named Fuel Arena staging project found. |
| 2026-06-12 `dart run tool/auth/check_google_auth_env.dart --env staging` | FAIL | Still missing `GOOGLE_WEB_CLIENT_ID_STAGING`; expected until OAuth clients are created and env is updated. |
| 2026-06-12 post-branch `dart run tool/auth/check_google_auth_env.dart --env staging` | FAIL | Expected blocker reproduction: still missing `GOOGLE_WEB_CLIENT_ID_STAGING`. |
| 2026-06-12 post-branch `python tool/validate_secret_hygiene.py` | PASS | Secret hygiene remains valid. |
| 2026-06-12 post-branch `dart run tool/security/scan_secrets.dart` | PASS | Tracked/unignored secret scan passed. |
| 2026-06-12 post-branch `git diff --check` | PASS | No whitespace errors; CRLF normalization warnings only. |
| 2026-06-12 post-branch `flutter pub get` | PASS | Dependencies resolved. |
| 2026-06-12 post-branch `dart format .` | PASS | Formatted 127 files; 0 changed. |
| 2026-06-12 post-branch `flutter analyze` | PASS | No issues found. |
| 2026-06-12 post-branch `flutter test` | PASS | 217 tests passed. |
| 2026-06-12 post-branch `dart run tool/auth/check_auth_routes.dart` | PASS | Auth routes and Google-only login UI checks passed. |
| 2026-06-12 post-branch `dart run tool/auth/check_auth_logs.dart` | PASS | Raw token/session logging check passed. |
| 2026-06-12 post-branch `dart run tool/validate_google_auth_database.dart` | PASS | 93 checks passed. |
| 2026-06-12 post-branch `dart run tool/validate_supabase_schema.dart` | PASS | 377 checks passed. |
| 2026-06-12 post-branch `dart run tool/security/check_auth_rls_policies.dart` | PASS | 73 checks passed. |
| 2026-06-12 blocked recheck local env inspection | BLOCKED | Google OAuth Client IDs and legal/support URLs remain blank in local `.env.staging`. |
| 2026-06-12 blocked recheck Chrome tab inspection | BLOCKED | Open console tabs still target the same Supabase and Google Cloud projects; detailed Supabase page extraction timed out twice. |
| 2026-06-12 blocked recheck `dart run tool/auth/check_google_auth_env.dart --env staging` | FAIL | Still missing `GOOGLE_WEB_CLIENT_ID_STAGING`; expected until OAuth client setup is complete. |
| 2026-06-12 Web Client ID env update | PARTIAL | Web/Server Client ID set locally; Client Secret not stored. |
| 2026-06-12 post-Web-ID `dart run tool/auth/check_google_auth_env.dart --env staging` | FAIL | Advanced to missing `GOOGLE_ANDROID_CLIENT_ID_STAGING`. |
| 2026-06-12 post-Web-ID `python tool/validate_secret_hygiene.py` | PASS | Secret hygiene valid. |
| 2026-06-12 post-Web-ID `dart run tool/security/scan_secrets.dart` | PASS | Secret scan passed. |
| 2026-06-12 Chrome Android OAuth client setup | PASS | Android debug OAuth client created and local `.env.staging` updated; Client Secret was not stored. |
| 2026-06-12 Chrome iOS OAuth client setup | PASS | iOS OAuth client created and local `.env.staging` updated with Client ID and reversed scheme. |
| 2026-06-12 staging env validation after OAuth setup | PASS | `dart run tool/auth/check_google_auth_env.dart --env staging` passed with local legal URL placeholders. |
| 2026-06-12 post-OAuth `python tool/validate_secret_hygiene.py` | PASS | Secret hygiene valid. |
| 2026-06-12 post-OAuth `dart run tool/security/scan_secrets.dart` | PASS | Secret scan passed. |
| 2026-06-12 Supabase Provider save attempt | BLOCKED | New Google Web OAuth secret was created for Supabase use, but Chrome automation became blocked by an open extension UI before the Provider form could be saved. |
| 2026-06-12 Supabase Provider save continuation | PASS | Google Provider saved and provider list shows `Google` as `Enabled`; Client Secret was not stored in repo files. |
| 2026-06-12 Supabase web authorize redirect | PASS | Local web `redirect_to` returns `302` to `accounts.google.com/o/oauth2/v2/auth`. |
| 2026-06-12 Supabase native authorize redirect | PASS | `fuelarena://login-callback` `redirect_to` returns `302` to `accounts.google.com/o/oauth2/v2/auth`. |
| 2026-06-12 post-Provider `flutter pub get` | PASS | Dependencies resolved. |
| 2026-06-12 post-Provider `dart format .` | PASS | Formatted 127 files; 0 changed. |
| 2026-06-12 post-Provider `flutter analyze` | PASS | No issues found. |
| 2026-06-12 post-Provider `flutter test` | PASS | 217 tests passed. |
| 2026-06-12 post-Provider `dart run tool/auth/check_google_auth_env.dart --env staging` | PASS | Staging auth environment validation passed. |
| 2026-06-12 post-Provider `python tool/validate_secret_hygiene.py` | PASS | Secret hygiene valid. |
| 2026-06-12 post-Provider `dart run tool/security/scan_secrets.dart` | PASS | Secret scan passed. |
| 2026-06-12 post-Provider `dart run tool/validate_google_auth_database.dart` | PASS | 93 checks passed. |
| 2026-06-12 post-Provider `dart run tool/validate_supabase_schema.dart` | PASS | 377 checks passed. |
| 2026-06-12 post-Provider `dart run tool/security/check_auth_rls_policies.dart` | PASS | 73 checks passed. |
| 2026-06-12 post-Provider `git diff --check` | PASS | No whitespace errors; CRLF normalization warnings only. |

## Live Login Test

2026-06-12 result: **PASS for local staging web login**.

What was verified:

- Ran the Flutter web app in staging mode at `http://localhost:3000` with
  `.env.staging` passed through `--dart-define-from-file`.
- Triggered the real Google OAuth flow from the Fuel Arena Google-only login
  screen.
- Initial retry surfaced `redirect_uri_mismatch`, which confirmed the
  Supabase Provider was enabled but the Google Web OAuth Client was missing the
  Supabase callback in Authorized redirect URIs.
- Added
  `https://vzxbltofwjxkoonisoyx.supabase.co/auth/v1/callback`
  to the Google Web OAuth Client and saved it.
- Retried login and reached the Google account chooser and consent screen
  without `Unsupported provider: provider is not enabled` and without
  `redirect_uri_mismatch`.
- Continued Google consent and returned to Fuel Arena at `/consent`.
- Confirmed the protected required-consent screen rendered.
- Submitted required consent with optional ads/marketing still unchecked.
- Confirmed routing advanced to `/setup`.
- Reloaded the page and confirmed the protected `/setup` screen remained
  available, which verifies session restore in the running web app.

Auth/profile evidence:

- `/consent` and `/setup` are protected routes. They are only rendered after
  `restoredSessionProvider` resolves a non-null user.
- `restoredSessionProvider` calls `AppSessionService.restore()`, which calls
  `authRepository.currentUser()`.
- In staging with Supabase configured, `currentUser()` reads the Supabase Auth
  user, selects the matching `profiles` row, and repairs it through
  `ensure_my_profile` / fallback insert-update if it is missing.
- Rendering `/consent` and `/setup` therefore proves the Supabase Auth session
  exists and the matching profile row is readable/created for the signed-in
  user.

Remaining before release:

- Replace local staging legal URL placeholders with real HTTPS legal document
  URLs.
- Create/use a separate staging Supabase project or branch before broader
  production-like testing; the connected dashboard is still labeled
  `main PRODUCTION`.
- Create Android release OAuth credentials with release signing fingerprints.
- Run isolated Supabase RLS SQL tests once Supabase CLI or another safe
  disposable database runner is available.

No token, ID token, access token, refresh token, OAuth Client Secret, callback
code, or service role key was written to repo files or docs.
