alter table public.vehicle_variants
  add column if not exists efficiency_unit text not null default 'km/L';

update public.vehicle_variants
set efficiency_unit = case
  when fuel_league = 'electric' then 'km/kWh'
  else 'km/L'
end
where efficiency_unit = 'km/L' or efficiency_unit is null;

create table if not exists public.custom_vehicle_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  user_vehicle_id uuid references public.user_vehicles(id) on delete set null,
  manufacturer_name text not null,
  model_name text not null,
  year integer not null,
  trim_name text not null,
  fuel_type text not null,
  fuel_league text not null references public.fuel_leagues(key),
  vehicle_class text not null,
  memo text not null default '',
  status text not null default 'pending_review',
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  review_note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.custom_vehicle_requests
  add column if not exists user_vehicle_id uuid references public.user_vehicles(id) on delete set null;

create index if not exists custom_vehicle_requests_user_created_at_idx
  on public.custom_vehicle_requests (user_id, created_at desc);

create index if not exists custom_vehicle_requests_status_created_at_idx
  on public.custom_vehicle_requests (status, created_at desc);

create index if not exists custom_vehicle_requests_user_vehicle_idx
  on public.custom_vehicle_requests (user_vehicle_id);

alter table public.custom_vehicle_requests enable row level security;

drop policy if exists "custom_vehicle_requests_self_select_or_admin" on public.custom_vehicle_requests;
create policy "custom_vehicle_requests_self_select_or_admin" on public.custom_vehicle_requests
  for select using (auth.uid() = user_id or public.is_admin_user());

drop policy if exists "custom_vehicle_requests_self_insert" on public.custom_vehicle_requests;
create policy "custom_vehicle_requests_self_insert" on public.custom_vehicle_requests
  for insert with check (
    auth.uid() = user_id
    and user_vehicle_id is not null
    and exists (
      select 1
      from public.user_vehicles uv
      where uv.id = user_vehicle_id
        and uv.user_id = auth.uid()
    )
  );

drop policy if exists "custom_vehicle_requests_admin_update" on public.custom_vehicle_requests;
create policy "custom_vehicle_requests_admin_update" on public.custom_vehicle_requests
  for update using (public.is_admin_user())
  with check (public.is_admin_user());

drop policy if exists "custom_vehicle_requests_admin_delete" on public.custom_vehicle_requests;
create policy "custom_vehicle_requests_admin_delete" on public.custom_vehicle_requests
  for delete using (public.is_admin_user());

create or replace view public.vehicle_catalog_view as
select
  vv.id,
  vv.model_year_id,
  vmf.name_ko as manufacturer_name,
  vm.name_ko as model_name,
  vmy.year,
  vv.trim_name,
  vv.engine_name,
  vv.fuel_type,
  vv.displacement_cc,
  vv.battery_kwh,
  vv.drivetrain,
  vv.transmission,
  vv.official_efficiency,
  vv.efficiency_unit,
  vv.vehicle_class,
  vv.fuel_league,
  vv.is_verified,
  lower(vmf.name_ko || ' ' || vmf.name_en || ' ' || vm.name_ko || ' ' || vm.name_en || ' ' || vmy.year || ' ' || vv.trim_name || ' ' || vv.fuel_type || ' ' || vv.vehicle_class) as search_text
from public.vehicle_variants vv
join public.vehicle_model_years vmy on vmy.id = vv.model_year_id
join public.vehicle_models vm on vm.id = vmy.model_id
join public.vehicle_manufacturers vmf on vmf.id = vm.manufacturer_id;

create or replace view public.vehicle_manufacturer_catalog_view
with (security_invoker = true) as
select
  vmf.id,
  vmf.name_ko,
  vmf.name_en,
  vmf.country,
  vmf.logo_url,
  vmf.is_popular,
  vmf.sort_order,
  count(distinct vm.id)::integer as model_count,
  coalesce(min(vmy.year), 0)::integer as min_year,
  coalesce(max(vmy.year), 0)::integer as max_year
from public.vehicle_manufacturers vmf
left join public.vehicle_models vm on vm.manufacturer_id = vmf.id
left join public.vehicle_model_years vmy on vmy.model_id = vm.id
group by
  vmf.id,
  vmf.name_ko,
  vmf.name_en,
  vmf.country,
  vmf.logo_url,
  vmf.is_popular,
  vmf.sort_order;
