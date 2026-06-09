# Agent Blockers: External Console Configurations

The following setup tasks can only be completed via the Google Cloud Console and Supabase Dashboard. 

## Staging & Production Active Blockers

| Blocker ID | Description | Required Action | Status |
|---|---|---|---|
| AUTH_CON_01 | Supabase Staging API Keys | Configure `SUPABASE_URL_STAGING` and `SUPABASE_ANON_KEY_STAGING` in `.env` | Pending User |
| AUTH_CON_02 | Google OAuth Android Client ID | Generate Android Client ID in Google Cloud Console using release SHA-1 | Pending User |
| AUTH_CON_03 | Google OAuth iOS Client ID | Generate iOS Client ID in Google Cloud Console and set Reversed Scheme | Pending User |
| AUTH_CON_04 | Supabase Auth Google Provider Setup | Input Web Client ID and Client Secret in Supabase Dashboard | Pending User |

## Code Fallbacks / Mock Workarounds
- Staging mode will support `STAGING_ALLOW_MOCK_AUTH=true` as a temporary fallback to allow running tests/widget verification without valid credentials.
- Dev mode automatically falls back to `MockAuthRepository` when keys are blank.
