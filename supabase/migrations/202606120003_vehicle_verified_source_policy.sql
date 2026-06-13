-- Verification policy hardening.
-- is_verified means official/admin verified with source evidence.
-- is_selectable controls whether users can still pick an unverified catalog row.

update public.vehicle_variants
set
  source_status = coalesce(nullif(source_status, ''), 'unverified'),
  is_verified = false
where source_status not in ('verified_official', 'verified_admin');

update public.vehicle_variants vv
set is_verified = false
where vv.source_status in ('verified_official', 'verified_admin')
  and not exists (
    select 1
    from public.vehicle_powertrain_sources vps
    join public.vehicle_data_sources vds on vds.id = vps.source_id
    where vps.powertrain_id = vv.id
      and coalesce(vds.source_name, vds.source_url, vds.source_file_name) is not null
  );

update public.vehicle_variants
set
  source_status = 'pending_review',
  is_verified = false,
  is_selectable = false,
  confidence_score = 0.10
where exists (
    select 1
    from public.vehicle_model_years vmy
    join public.vehicle_models vm on vm.id = vmy.model_id
    join public.vehicle_manufacturers vmf on vmf.id = vm.manufacturer_id
    where vmy.id = vehicle_variants.model_year_id
      and vmf.name_ko = 'BMW'
  )
  and not exists (
    select 1
    from public.vehicle_powertrain_sources vps
    join public.vehicle_data_sources vds on vds.id = vps.source_id
    where vps.powertrain_id = vehicle_variants.id
      and coalesce(vds.source_name, vds.source_url, vds.source_file_name) is not null
  );
