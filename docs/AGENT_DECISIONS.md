# Agent Decisions: Google Auth Transition

## Implementation Decisions

### 1. Staging Mock Auth Restriction with STAGING_ALLOW_MOCK_AUTH
- **Context**: In staging environment testing, real credentials might not be configured initially by the user, but we must protect production from mock fallbacks.
- **Decision**: Staging will default to throwing a `ConfigException` if credentials are missing, just like production. However, to facilitate local debugging without forcing full setup, a specific flag `STAGING_ALLOW_MOCK_AUTH=true` is introduced. If this is explicitly set, mock auth fallback is allowed in Staging. In Production, mock is *always* blocked, regardless of any flag.
- **Rationale**: Keeps staging close to production behavior by default while providing a safe, explicit escape hatch for internal staging tests.

### 2. Developer Diagnostics Screen Masking
- **Context**: Diagnostics UI is crucial for debugging client ID issues on device, but we must prevent credential leaks.
- **Decision**: Show only the environment keys, whether they are set/unset, and a masked version of Client IDs (showing only first 6 and last 8 characters). Access tokens and secrets are completely blocked from display or clipboard copies.
- **Rationale**: Balancing developer convenience with production security guidelines.
