# RLS Policy Notes

## 원칙
사용자 개인 데이터는 본인만 접근한다. 공개 경쟁 화면은 제한된 public view 또는 ranking row만 사용한다.

## 보호 데이터
- drive_points: 정확한 좌표 raw path, 본인만 접근
- drive_sessions: 본인 주행 상세, 본인만 접근
- app_consents: 본인 현재 동의 상태, 본인만 조회/갱신
- user_vehicles: 본인 차량과 검증 상태, 본인만 접근
- league_memberships: 본인 활성 리그, 본인만 접근
- ad_rewards, user_coupons, user_subscriptions, purchase_verifications: 본인만 조회하고 보상 지급과 결제 검증 변경은 Edge Function에서 처리
- support_tickets, support_ticket_messages: 본인 문의와 관리자만 접근한다. 사용자는 본인 티켓의 추가 메시지를 남길 수 있고, 관리자는 `is_admin_reply` 메시지와 상태 변경으로 답변/처리 흐름을 운영한다.
- privacy_requests: 사용자는 본인 데이터 다운로드/삭제/계정 삭제 요청만 생성/조회하고, 관리자는 요청 목록 조회와 상태 변경을 수행한다.
- report_items: 신고자는 본인 신고를 생성/조회하고, 관리자는 신고 목록 조회와 상태 변경을 수행한다.
- crews, crew_members: 같은 크루 소속자와 관리자만 조회한다. 닉네임을 포함한 앱 표시 데이터는 `get_my_crew_summary`, `get_my_crew_members` RPC로 제한해 제공한다.
- consent_logs: 본인 동의 변경 감사 로그, 본인과 관리자만 조회하고 insert는 본인 변경 흐름에서만 허용
- user_local_sync_logs: 본인과 관리자만 접근

## 공개 데이터
fuel_leagues와 vehicle catalog는 누구나 읽을 수 있다. rankings와 battles는 공개 경쟁에 필요한 제한 정보만 읽을 수 있다. 위치 좌표와 이메일은 공개하지 않는다.

sponsors, sponsor_challenges, advertisements, coupons는 공개 콘텐츠지만 RLS를 켠다. 일반 사용자는 활성 상태, 노출 기간, 쿠폰 만료 조건을 통과한 row만 읽고, 생성/수정/삭제는 관리자 정책으로 제한한다.

public_rankings view는 닉네임, 티어, 점수, 차급, 연료 리그만 제공한다. raw drive_points와 정확한 좌표는 어떤 공개 view에도 포함하지 않는다.

app_settings는 `is_public = true` 항목만 일반 사용자에게 공개한다. 비공개 운영 설정은 관리자만 조회한다.

badges와 achievements 정의는 모든 로그인 사용자가 읽을 수 있고, 사용자별 `user_badges`, `user_achievements` 진행률은 본인만 읽는다. 정의 변경은 관리자만 수행한다.

subscription_plans는 공개 가격/혜택 안내에 필요하므로 누구나 읽을 수 있지만, 생성/수정/삭제는 관리자 정책으로 제한한다.

## Admin
관리자 작업은 `profiles.is_admin` 또는 admin claim을 확인하는 Edge Function과 admin 전용 view로 확장한다.
`analytics_events`, `vehicle_catalog_change_logs`, `admin_action_logs`, app settings write, 차량 카탈로그 write는 관리자 전용 정책으로 보호한다.

## Profile self-write hardening
Authenticated clients may insert/update only safe profile columns: identity text,
onboarding/consent/setup flags, representative vehicle fields, selected league
fields, and `updated_at`.

`profiles.tier`, `total_score`, `season_score`, `current_streak`,
`best_streak`, `is_premium`, `is_admin`, and `created_at` are server-controlled.
New profile inserts must keep score, premium, and admin fields at safe defaults.

`202606110001_google_auth_database_hardening.sql` tightens this by adding
`prevent_profile_protected_field_update()`. Authenticated clients may directly
change only `nickname` and `avatar_url`; protected updates for consent, vehicle
selection, status, `last_login_at`, score, premium, admin, and Google identity
must go through secure RPCs or Edge Functions. The supported client RPCs are
`ensure_my_profile()`, `update_my_profile()`, `record_my_consent()`,
`revoke_my_consent()`, `set_my_profile_vehicle()`,
`request_account_deletion()`, and `request_data_export()`.

## Auth audit and privacy request queues
`auth_audit_logs` stores authentication and privacy events through
`record_auth_event()`. The RPC strips token, ID token, access token, refresh
token, authorization, OAuth client secret, and full email metadata keys before
insert.

`account_deletion_requests` and `data_export_requests` are dedicated user
request queues. Users can create/select only their own pending requests;
admins can select/update all rows. The legacy `privacy_requests` table remains
the app-facing operations queue and is mirrored by the request RPCs.

## Public/private views
`public_profiles_view`, `public_rankings_view`, and
`public_user_primary_vehicle_view` are safe public projections. They do not
expose email, Google subject, admin flag, status/deleted markers,
`last_login_at`, exact location, raw `drive_points`, IP, user agent, or full
private profile rows.

## service_role
service_role key는 Flutter 앱에 포함하지 않는다. 서버 권한 작업은 Edge Function에서 처리한다.
`recompute_rankings(text)`와 `claim_mission_reward(uuid, uuid)`는 앱 사용자가 직접 호출할 수 없도록 public, anon, authenticated execute 권한을 회수하고 service_role에만 execute 권한을 부여한다.

## 정적 검증
`dart run tool/validate_supabase_schema.dart`는 필수 table 생성, RLS 활성화, self/admin/public policy, public view privacy, RPC security definer/search_path, Edge 전용 RPC grant/revoke, 중복 방지 index를 검사한다. Google auth DB 보강은 `dart run tool/validate_google_auth_database.dart`와 `dart run tool/security/check_auth_rls_policies.dart`가 추가로 검사한다.

