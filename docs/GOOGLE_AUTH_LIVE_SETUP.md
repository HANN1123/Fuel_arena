# Google Auth Live Setup

Last updated: 2026-06-12

## Current State

- Target Supabase project ref: `vzxbltofwjxkoonisoyx`
- Supabase project URL: `https://vzxbltofwjxkoonisoyx.supabase.co`
- Supabase dashboard inspected: `Fuel_Arena` in `HANN1123's Org`
- Supabase callback URL for Google OAuth:
  `https://vzxbltofwjxkoonisoyx.supabase.co/auth/v1/callback`
- Supabase Google Provider state: **Enabled**
- Supabase URL allow-list currently contains:
  - `fuelarena://login-callback`
  - `http://127.0.0.1:5173`
  - `http://localhost:3000`
  - `http://localhost:5173`
- Google Cloud project opened in Chrome:
  - Project id: `bustling-gate-486207-a1`
  - Display name shown by console: `My Project 84625`
  - OAuth platform state: **not configured**
  - OAuth 2.0 clients: **none**
- 2026-06-12 Chrome recheck:
  - Supabase dashboard still shows project `Fuel_Arena` / ref `vzxbltofwjxkoonisoyx`
  - Dashboard branch/environment label shown: `main PRODUCTION`
  - Google Provider list row still shows **Disabled**
  - URL Configuration still contains only the native/local redirect URLs listed above
  - Google Cloud project still shows Google Auth Platform **not configured**
  - Google Cloud credentials page still shows **no OAuth 2.0 clients**
- 2026-06-12 continuation recheck:
  - Supabase Google Provider remains **Disabled**
  - Supabase dashboard still shows `main PRODUCTION`
  - Supabase URL Configuration remains unchanged
  - Google Auth Platform remains **not configured** in `My Project 84625`
  - Google Cloud credentials still show **no OAuth 2.0 clients**
- 2026-06-12 external console setup attempt:
  - Supabase organization project list shows only `Fuel_Arena` pointing to ref `vzxbltofwjxkoonisoyx`
  - No separate Supabase staging project is visible in the organization
  - Google Cloud resource manager shows only `My Project 84625` / `bustling-gate-486207-a1`
  - No Google Cloud project with an obvious Fuel Arena or staging name is visible
- 2026-06-12 Branching console recheck:
  - Supabase Branching page shows only `PRODUCTION BRANCH` -> `main`
  - No persistent staging branch exists.
  - Persistent branches are locked behind an upgrade prompt on the current free organization.
  - Preview branches are available as short-lived environments, but no preview branch has been created.
  - Provider settings were not changed because the only visible branch/project is still labeled `main PRODUCTION`.

Because the connected Supabase dashboard is labeled `main PRODUCTION`, do not change provider settings there until this project is explicitly confirmed as the staging target or a separate staging project is selected.

The same external console blocker has now been observed across repeated goal continuations. Further live Google login verification requires user action in Supabase/Google Cloud before code-side work can proceed.

External setup is paused before changing settings because no staging Supabase project is identifiable and the only visible Supabase project is labeled `main PRODUCTION`.

2026-06-12 blocked recheck: local `.env.staging` still lacks all Google OAuth client IDs and legal/support URLs. Open Chrome console tabs still point to Supabase `Fuel_Arena` / `vzxbltofwjxkoonisoyx` and Google Cloud `My Project 84625`. Detailed Supabase page extraction timed out twice during this continuation, so provider settings were not changed.

2026-06-12 Web OAuth progress: the user provided a Google Web OAuth Client ID. It was added to local `.env.staging` as `GOOGLE_WEB_CLIENT_ID_STAGING` and `GOOGLE_SERVER_CLIENT_ID_STAGING`. The value is intentionally not recorded in this document. `dart run tool/auth/check_google_auth_env.dart --env staging` now advances to the next missing key: `GOOGLE_ANDROID_CLIENT_ID_STAGING`.

2026-06-12 Chrome OAuth client setup continuation: Android and iOS OAuth clients were created in the logged-in Google Cloud project. Their Client IDs and the derived iOS reversed client ID were added to local `.env.staging` only. Staging legal URLs were filled with local static Web legal page URLs until a real HTTPS deployment domain exists. `dart run tool/auth/check_google_auth_env.dart --env staging`, `python tool/validate_secret_hygiene.py`, and `dart run tool/security/scan_secrets.dart` now pass. A new Google Web OAuth client secret was created for Supabase Provider use; it was not written to Flutter env files, docs, source, or logs. Supabase Provider save is still pending because Chrome automation became blocked by an open Chrome extension UI before the Provider form could be saved.

2026-06-12 Supabase Provider save continuation: Supabase Google Provider was saved with Web/Android/iOS Client IDs and the latest Web OAuth Client Secret. The provider list now shows Google as enabled. Supabase authorize endpoints for local web and `fuelarena://login-callback` both return `302` to Google OAuth. The Client Secret was not written to Flutter env files, docs, source, or logs.

2026-06-12 live web login continuation: The local staging web app was run at `http://localhost:3000` with `.env.staging` passed through `--dart-define-from-file`. The first real OAuth attempt reached Google but failed with `redirect_uri_mismatch`, so the Supabase callback URL was added to the Google Web OAuth Client's Authorized redirect URIs. After retry, Google account selection and consent completed, Fuel Arena returned to `/consent`, required consent was saved with optional ads/marketing unchecked, routing advanced to `/setup`, and a page reload restored the authenticated `/setup` route. No token, callback code, or OAuth Client Secret was recorded in docs or source.

## Local Environment State

- `.env.staging` exists locally and is gitignored.
- `.env.staging` has:
  - `APP_ENV=staging`
  - `STAGING_ALLOW_MOCK_AUTH=false`
  - `SUPABASE_URL_STAGING` copied from local Supabase config
  - `SUPABASE_ANON_KEY_STAGING` copied from local Supabase config
  - Web, Android, iOS, Server, and reversed iOS Google OAuth client values for staging
  - local Web legal URLs for terms/privacy/location policy placeholders
- Client Secret is not stored in Flutter env files.
- `service_role` key is not required by, and must not be added to, the Flutter app.

## Required External Console Work

Complete these in the staging Google Cloud project and Supabase project. Do not paste Client Secret, access tokens, ID tokens, refresh tokens, or service role keys into chat, docs, logs, or source files.

1. Confirm the Google Cloud project to use for Fuel Arena staging.
2. Configure Google Auth Platform / OAuth consent screen:
   - App name: `Fuel Arena`
   - Audience: External, unless this is a Workspace-internal test app
   - Scopes: `openid`, `email`, `profile` only
   - Add staging test Google accounts
3. Create a Web OAuth Client:
   - Type: Web application
   - Authorized redirect URI:
     `https://vzxbltofwjxkoonisoyx.supabase.co/auth/v1/callback`
   - Add local/staging JavaScript origins as needed.
4. In Supabase Dashboard, Authentication > Sign In / Providers > Google:
   - Done for this continuation: Google is enabled with Web/Android/iOS Client IDs and Web Client Secret.
5. Create Android OAuth Client:
   - Package name: `com.fuelarena.fuel_arena`
   - Debug SHA-1: `00:F0:C0:17:78:64:38:52:8C:EA:87:A6:4E:A5:5C:E8:4A:6C:84:17`
   - Debug SHA-256: `29:67:2C:C3:D6:F1:0D:32:E9:25:A9:64:DD:06:36:10:3F:C8:65:DF:2A:EB:30:73:A4:BD:A2:16:EB:1B:4C:10`
6. Create iOS OAuth Client:
   - Bundle ID: `com.fuelarena.fuelArena`
   - Put the generated iOS Client ID and Reversed Client ID into local env only.
7. Update local `.env.staging`:
   - `GOOGLE_WEB_CLIENT_ID_STAGING`
   - `GOOGLE_ANDROID_CLIENT_ID_STAGING`
   - `GOOGLE_IOS_CLIENT_ID_STAGING`
   - `GOOGLE_SERVER_CLIENT_ID_STAGING`
   - `GOOGLE_REVERSED_IOS_CLIENT_ID_STAGING`
   - legal/support URLs

## Current P0/P1 Issues

### P0

- Supabase Google Provider is enabled on the connected project.
- Connected Supabase dashboard is labeled `main PRODUCTION`; a separate staging project is still recommended before broader release testing.
- Supabase organization currently shows no separate staging project.
- Supabase Branching currently shows only `main` as the production branch; no persistent staging branch is available on the current plan.
- Google Cloud currently shows no clearly named Fuel Arena staging project.
- Google Cloud OAuth Web/Android/iOS clients now exist in the inspected project for staging continuation.
- Google Web OAuth Client now includes the Supabase callback redirect URI.
- `.env.staging` now has Google OAuth client IDs and local legal URL placeholders.
- Supabase authorize redirects now reach Google OAuth for local web and native callback.
- Staging Google login was verified on local web through consent, setup routing, and session restore.
- Google Auth Platform release-grade branding/audience/test-user review still needs confirmation before wider testing.

### P1

- Android OAuth Client is confirmed for debug staging; release SHA/client still needs production setup later.
- iOS OAuth Client is confirmed for staging.
- Supabase redirect allow-list lacks a real hosted staging domain.
- Live local staging web login has been run successfully.
