-- Fuel Arena Google Auth / RLS verification script.
-- Run against a disposable Supabase local database after migrations.
-- This file is intentionally self-contained SQL so it can be copied into
-- psql or Supabase SQL editor. It assumes the auth helper functions installed
-- by Supabase are available.

begin;

-- Test principals. In local Supabase, create matching auth.users rows first or
-- replace the UUIDs below with real test users from auth.users.
select '00000000-0000-0000-0000-0000000000a1'::uuid as user_a_id \gset
select '00000000-0000-0000-0000-0000000000b2'::uuid as user_b_id \gset
select '00000000-0000-0000-0000-0000000000ad'::uuid as admin_id \gset

-- anonymous cannot select profiles directly
reset role;
select count(*) as anonymous_profile_rows from public.profiles;

-- Seed rows with service role privileges in a disposable database.
set local role service_role;
insert into public.profiles (id, email, nickname, auth_provider, is_admin)
values
  (:'user_a_id', 'user-a@example.invalid', 'User A', 'google', false),
  (:'user_b_id', 'user-b@example.invalid', 'User B', 'google', false),
  (:'admin_id', 'admin@example.invalid', 'Admin', 'google', true)
on conflict (id) do update
  set nickname = excluded.nickname,
      is_admin = excluded.is_admin,
      updated_at = now();

insert into public.drive_sessions (id, user_id, vehicle_id, status)
select
  '00000000-0000-0000-0000-00000000d0b2'::uuid,
  :'user_b_id',
  v.id,
  'recording'
from public.vehicles v
where v.user_id = :'user_b_id'
limit 1
on conflict do nothing;

-- Switch to user_a JWT simulation.
reset role;
set local role authenticated;
set local request.jwt.claim.sub = :'user_a_id';
set local request.jwt.claim.role = 'authenticated';

-- user_a can select own profile
select id, nickname from public.profiles where id = :'user_a_id';

-- user_a cannot select user_b profile private fields
select id, email from public.profiles where id = :'user_b_id';

-- user_a can update own nickname
update public.profiles
set nickname = 'Driver A'
where id = :'user_a_id';

-- user_a cannot update is_admin
update public.profiles
set is_admin = true
where id = :'user_a_id';

-- user_a cannot update is_premium
update public.profiles
set is_premium = true
where id = :'user_a_id';

-- user_a cannot update total_score
update public.profiles
set total_score = 999999
where id = :'user_a_id';

-- user_a can insert own consent_logs
insert into public.consent_logs (
  user_id,
  consent_type,
  consent_version,
  accepted
)
values (
  :'user_a_id',
  'privacy_policy',
  'test',
  true
);

-- user_a cannot select user_b consent_logs
select * from public.consent_logs where user_id = :'user_b_id';

-- user_a can request account deletion
select public.request_account_deletion('rls smoke test');

-- user_a cannot select user_b account deletion request
select * from public.account_deletion_requests where user_id = :'user_b_id';

-- user_a cannot select user_b drive_points
select * from public.drive_points where user_id = :'user_b_id';

-- public_rankings_view exposes no email
select *
from public.public_rankings_view
limit 5;

-- vehicle catalog read succeeds
select id, manufacturer_name, model_name
from public.vehicle_catalog_view
limit 5;

-- vehicle catalog write fails for non-admin
insert into public.vehicle_manufacturers (id, name_ko)
values ('rls-test-maker', 'RLS 테스트');

-- Switch to admin JWT simulation.
reset role;
set local role authenticated;
set local request.jwt.claim.sub = :'admin_id';
set local request.jwt.claim.role = 'authenticated';

-- admin can update app_settings
update public.app_settings
set value = jsonb_set(value, '{rls_test}', 'true'::jsonb, true)
where key = 'google_auth_enabled';

-- admin can review custom vehicle requests
select * from public.custom_vehicle_requests limit 5;

rollback;
