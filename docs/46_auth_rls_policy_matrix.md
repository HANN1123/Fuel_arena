# Auth RLS Policy Matrix

| Surface | User Access | Admin Access | Public Access | Notes |
|---|---|---|---|---|
| `profiles` | own select; nickname/avatar direct update only | full select/update by `is_admin()` | none | protected trigger blocks score/tier/admin/premium/status changes |
| `public_profiles_view` | read | read | read | no email, Google subject, admin flag, status, last login |
| `app_consents` | own current consent | via admin policies/RPC as needed | none | current state only |
| `consent_logs` | own insert/select | select | none | append-only; revoke via RPC |
| `account_deletion_requests` | own pending insert/select | select/update/process | none | also mirrors existing `privacy_requests` queue |
| `data_export_requests` | own pending insert/select | select/update/process | none | Edge Function should publish expiring download URL |
| `auth_audit_logs` | own select | select | none | insert through secure RPC; token fields removed |
| `admin_audit_logs` | none | insert/select | none | admin dashboard audit trail |
| `user_vehicles` | own CRUD | admin as policy/RPC allows | none | catalog data is separate public read |
| `drive_sessions` | own records | review select via admin tools | none | no raw points in public views |
| `drive_points` | own only | limited admin/service review | none | exact coordinates remain private |
| `drive_scores` | own detail | server/admin scoring | no table read | public rankings expose aggregate score only |
| `public_rankings_view` | read | read | read | no email, full user id, route, drive point, IP, user agent |
| vehicle catalog | read | write | read | manufacturer/model/year/variant catalog is public content |
| `custom_vehicle_requests` | own insert/select | review update/delete | none | user cannot approve own request |
| `notifications` | own read/update | server/admin insert | none | driving state controls UI display |
| `user_coupons` | own | admin/service issue | none | coupon definition table is public active read |
| `user_subscriptions` | own select | service verified update | none | purchase verification is server controlled |
| `app_settings` | public rows read | write/read all | public rows read | private settings hidden by RLS |

Admin identity is resolved through `public.is_admin()`, which checks admin JWT metadata and `profiles.is_admin` with `security definer` and pinned search path.
