# Google Auth Console Checklist

Last updated: 2026-06-12

## Supabase Dashboard

Project:

- Ref: `vzxbltofwjxkoonisoyx`
- Dashboard path:
  `https://supabase.com/dashboard/project/vzxbltofwjxkoonisoyx`
- 2026-06-12 dashboard label: `main PRODUCTION`

Do not enable or change providers on this project until it is confirmed to be the staging target, or until a separate staging Supabase project is selected.

Google Provider:

- Page:
  `https://supabase.com/dashboard/project/vzxbltofwjxkoonisoyx/auth/providers`
- Current status: **Disabled**
- 2026-06-12 recheck: still **Disabled**
- Callback URL:
  `https://vzxbltofwjxkoonisoyx.supabase.co/auth/v1/callback`
- Required values:
  - Web OAuth Client ID from Google Cloud
  - Web OAuth Client Secret from Google Cloud
- Never enter Android or iOS Client IDs into the Client Secret field.
- Never store the Web Client Secret in Flutter `.env` files.

URL Configuration:

- Page:
  `https://supabase.com/dashboard/project/vzxbltofwjxkoonisoyx/auth/url-configuration`
- Current redirect URLs:
  - `fuelarena://login-callback`
  - `http://127.0.0.1:5173`
  - `http://localhost:3000`
  - `http://localhost:5173`
- 2026-06-12 recheck: unchanged
- Add the hosted staging URL when available.

## Google Cloud Console

Inspected project:

- Project id: `bustling-gate-486207-a1`
- Display name: `My Project 84625`
- Current status:
  - Google Auth Platform not configured
  - OAuth 2.0 Client IDs: none
- 2026-06-12 recheck:
  - Google Auth Platform still not configured
  - Credentials page still shows no OAuth 2.0 Client IDs

Before creating clients, confirm this is the intended Fuel Arena staging Google Cloud project.

### OAuth Consent Screen

Use Google Auth Platform:

- Overview: `https://console.cloud.google.com/auth/overview`
- Branding: `https://console.cloud.google.com/auth/branding`
- Audience: `https://console.cloud.google.com/auth/audience`
- Data Access: `https://console.cloud.google.com/auth/scopes`

Required settings:

- App name: `Fuel Arena`
- User support email: user-selected account email
- Developer contact email: user-selected account email
- Audience: External for public Gmail testers
- Test users: add staging Google test accounts while publishing status is Testing
- Scopes: only `openid`, `email`, and `profile`

### Web OAuth Client

Page: `https://console.cloud.google.com/apis/credentials`

- Type: Web application
- Suggested name: `Fuel Arena Staging Web OAuth Client`
- Authorized redirect URI:
  `https://vzxbltofwjxkoonisoyx.supabase.co/auth/v1/callback`
- Suggested local origins:
  - `http://localhost:3000`
  - `http://localhost:5173`
  - `http://127.0.0.1:5173`
- Add real staging origin when deployed.

After creation:

- Put Web Client ID in `.env.staging`.
- Put Web Client Secret only in Supabase Google Provider.

### Android OAuth Client

- Type: Android
- Package name: `com.fuelarena.fuel_arena`
- Debug SHA-1:
  `00:F0:C0:17:78:64:38:52:8C:EA:87:A6:4E:A5:5C:E8:4A:6C:84:17`
- Debug SHA-256:
  `29:67:2C:C3:D6:F1:0D:32:E9:25:A9:64:DD:06:36:10:3F:C8:65:DF:2A:EB:30:73:A4:BD:A2:16:EB:1B:4C:10`

Add release and Play App Signing certificates separately before production.

### iOS OAuth Client

- Type: iOS
- Bundle ID: `com.fuelarena.fuelArena`
- Configure `GOOGLE_IOS_CLIENT_ID_STAGING` and `GOOGLE_REVERSED_IOS_CLIENT_ID_STAGING` locally.
- `ios/Runner/Info.plist` already uses:
  - `$(GOOGLE_IOS_CLIENT_ID)`
  - `$(GOOGLE_SERVER_CLIENT_ID)`
  - `$(GOOGLE_REVERSED_IOS_CLIENT_ID)`
  - `fuelarena`

## Verification Commands

Run after console setup and local env update:

```powershell
flutter pub get
dart format .
flutter analyze
flutter test
dart run tool/auth/check_google_auth_env.dart --env staging
dart run tool/auth/check_auth_routes.dart
dart run tool/auth/check_auth_logs.dart
python tool/validate_secret_hygiene.py
dart run tool/security/scan_secrets.dart
dart run tool/validate_google_auth_database.dart
dart run tool/validate_supabase_schema.dart
dart run tool/security/check_auth_rls_policies.dart
flutter build apk --debug
flutter build web
```
