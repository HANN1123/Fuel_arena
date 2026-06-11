# Agent Blockers: External Console Configurations

The following setup tasks can only be completed via the Google Cloud Console and Supabase Dashboard. 

## Staging & Production Active Blockers

| Blocker ID | Description | Required Action | Status |
|---|---|---|---|
| AUTH_CON_01 | Supabase Staging API Keys | Configure `SUPABASE_URL_STAGING` and `SUPABASE_ANON_KEY_STAGING` in local `.env.staging` | Partially Done - copied from local Supabase config |
| AUTH_CON_02 | Google OAuth Android Client ID | Generate Android Client ID in Google Cloud Console using debug/release SHA-1 | Done for debug staging |
| AUTH_CON_03 | Google OAuth iOS Client ID | Generate iOS Client ID in Google Cloud Console and set Reversed Scheme | Done for staging |
| AUTH_CON_04 | Supabase Auth Google Provider Setup | Input Web Client ID and Client Secret in Supabase Dashboard | Done |
| AUTH_CON_05 | Google Auth Platform Setup | Configure OAuth consent screen, audience, scopes, and test users in the staging Google Cloud project | Partially Verified - live consent works for local staging; release-grade branding/test-user review remains |
| AUTH_CON_06 | Google OAuth Web Client | Create Web OAuth Client and register `https://vzxbltofwjxkoonisoyx.supabase.co/auth/v1/callback` as redirect URI | Done and live login verified |
| AUTH_CON_07 | Staging Legal URLs | Fill `TERMS_OF_SERVICE_URL`, `PRIVACY_POLICY_URL`, and `LOCATION_POLICY_URL` in local `.env.staging` | Done with local staging placeholders |
| AUTH_CON_08 | Staging project confirmation | Connected Supabase dashboard for `vzxbltofwjxkoonisoyx` is labeled `main PRODUCTION`; confirm it is safe to use as staging or select a separate staging project before provider changes | Accepted for this continuation; separate staging project remains recommended |
| AUTH_CON_09 | Supabase staging project missing | Supabase organization currently shows only `Fuel_Arena` / `vzxbltofwjxkoonisoyx`; create/select a separate staging project if the visible project is production | Pending User |
| AUTH_CON_10 | Google Cloud staging project confirmation | Google Cloud currently shows only `My Project 84625` / `bustling-gate-486207-a1`; confirm it may be used for Fuel Arena staging or create/select the intended project | Pending User |
| AUTH_CON_11 | Supabase persistent staging branch unavailable | Branching page shows only `main` as the production branch; persistent branches require an upgrade and no preview branch exists | Pending User |
| DB_TOOL_01 | Supabase CLI not available on PATH | Install/login Supabase CLI locally before running `supabase db reset`, `supabase db push`, or `supabase migration list` from this machine | Pending Environment |
| DB_VERIFY_01 | Disposable/staging RLS SQL tests | Run `supabase/tests/google_auth_rls_tests.sql` with real isolated test users | Pending Environment |

## Code Fallbacks / Mock Workarounds
- Staging mode will support `STAGING_ALLOW_MOCK_AUTH=true` as a temporary fallback to allow running tests/widget verification without valid credentials.
- Dev mode automatically falls back to `MockAuthRepository` when keys are blank.
- DB/RLS migrations were applied to the connected Supabase project with the Dashboard SQL Editor on 2026-06-11; Supabase CLI-based reset/push/list remains unavailable on this machine.

## 2026-06-12 Blocked Audit

The same live Google auth blocker was rechecked through Chrome across repeated goal continuations:

- Supabase Google Provider is still disabled.
- Connected Supabase dashboard is still labeled `main PRODUCTION`.
- Google Auth Platform in `bustling-gate-486207-a1` / `My Project 84625` is still not configured.
- Google credentials page still has no OAuth 2.0 clients.
- Supabase organization project list shows no separate staging project.
- Supabase Branching shows only production `main`; no persistent staging branch is available on the current plan.
- Google Cloud resource manager shows no clearly named Fuel Arena staging project.
- Local `.env.staging` still has blank Google Client IDs and legal/support URLs.
- The latest continuation could only confirm the same console tabs and local env state; detailed Supabase page extraction timed out twice, and no settings were changed.

2026-06-12 update: Web/Server Client ID has been added locally. Remaining env blockers are Android Client ID, iOS Client ID, Reversed iOS Client ID, and legal/support URLs. Supabase Google Provider still needs the Web Client ID and Client Secret entered in the dashboard.

2026-06-12 Chrome continuation update: Android and iOS OAuth clients were created in Google Cloud and their Client IDs were added to local `.env.staging`. Local staging legal URL placeholders were filled from the static Web legal pages, and `dart run tool/auth/check_google_auth_env.dart --env staging` now passes. A new Google Web OAuth client secret was created for Supabase Provider use but was not stored in any repo file. Supabase Provider save remains blocked because Chrome automation is currently blocked by an open extension UI over the Supabase page. Keep the Google Web client details tab open until the Provider is saved, then dismiss the extension UI and continue the Supabase save step.

2026-06-12 Provider save update: Supabase Google Provider is now saved and shows `Google` as `Enabled`. Supabase authorize redirects for both local web and `fuelarena://login-callback` now return `302` to Google OAuth. The Google OAuth Client Secret was not stored in repo files.

2026-06-12 live login update: Local staging web login was verified end to end. The first OAuth attempt exposed `redirect_uri_mismatch`; the Supabase callback URL was added to the Google Web OAuth Client Authorized redirect URIs. The retry completed Google account selection and consent, returned to Fuel Arena `/consent`, saved required consent with optional ads/marketing unchecked, advanced to `/setup`, and restored `/setup` after reload. No tokens, callback code, OAuth Client Secret, refresh token, ID token, or service role key were written to repo files.

The remaining blockers are release-grade Google Auth Platform branding/audience/test-user review, real HTTPS legal URLs, production Android release OAuth credentials, isolated RLS SQL testing, and production-grade staging/release project separation.
