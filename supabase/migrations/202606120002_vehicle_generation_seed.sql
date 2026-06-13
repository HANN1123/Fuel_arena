-- Initial generation seed for the generation-based vehicle selection flow.
-- This keeps model_years for backend mapping while exposing generations in UI.

insert into public.vehicle_generations (
  id,
  model_id,
  generation_order,
  generation_name_ko,
  generation_name_en,
  generation_code,
  platform_code,
  start_year,
  start_month,
  end_year,
  end_month,
  display_period,
  is_current,
  is_upcoming,
  market_region,
  source_status,
  confidence_score,
  source_name,
  source_url,
  source_file_name,
  last_verified_at,
  is_selectable,
  is_deprecated,
  updated_at
) values
  (
    'generation-hyundai-avante-cn7',
    'model-hyundai-001-kr',
    7,
    '7세대',
    'Seventh generation',
    'CN7',
    null,
    2020,
    4,
    null,
    null,
    '2020.4~현재',
    true,
    false,
    'KR',
    'unverified',
    0.35,
    null,
    null,
    null,
    null,
    true,
    false,
    now()
  ),
  (
    'generation-kia-k3-bd',
    'model-kia-013-k3',
    2,
    '2세대',
    'Second generation',
    'BD',
    'BD',
    2018,
    2,
    2024,
    null,
    '2018.2~2024',
    false,
    false,
    'KR',
    'verified_admin',
    0.78,
    '기아 보도자료/기아 커넥트/기아 공식 가격표',
    'https://www.newswire.co.kr/newsRead.php?no=865190',
    'price_k3gt.pdf',
    '2026-06-12',
    true,
    false,
    now()
  )
on conflict (id) do update set
  model_id = excluded.model_id,
  generation_order = excluded.generation_order,
  generation_name_ko = excluded.generation_name_ko,
  generation_name_en = excluded.generation_name_en,
  generation_code = excluded.generation_code,
  platform_code = excluded.platform_code,
  start_year = excluded.start_year,
  start_month = excluded.start_month,
  end_year = excluded.end_year,
  end_month = excluded.end_month,
  display_period = excluded.display_period,
  is_current = excluded.is_current,
  is_upcoming = excluded.is_upcoming,
  market_region = excluded.market_region,
  source_status = excluded.source_status,
  confidence_score = excluded.confidence_score,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  source_file_name = excluded.source_file_name,
  last_verified_at = excluded.last_verified_at,
  is_selectable = excluded.is_selectable,
  is_deprecated = excluded.is_deprecated,
  updated_at = now();

update public.vehicle_model_years
set
  generation_id = 'generation-hyundai-avante-cn7',
  production_year_label = '2020.4~현재'
where model_id = 'model-hyundai-001-kr'
  and year between 2020 and 2026;

update public.vehicle_model_years
set
  generation_id = 'generation-kia-k3-bd',
  production_year_label = '2018.2~2024'
where model_id = 'model-kia-013-k3'
  and year between 2018 and 2024;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select
  'generation-hyundai-avante-cn7',
  id,
  year
from public.vehicle_model_years
where model_id = 'model-hyundai-001-kr'
  and year between 2020 and 2026
on conflict (generation_id, model_year_id) do nothing;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select
  'generation-kia-k3-bd',
  id,
  year
from public.vehicle_model_years
where model_id = 'model-kia-013-k3'
  and year between 2018 and 2024
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set generation_id = vmy.generation_id
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.generation_id in (
    'generation-hyundai-avante-cn7',
    'generation-kia-k3-bd'
  );

update public.vehicle_variants
set
  valid_from_year = 2020,
  valid_to_year = null
where id = 'variant-hyundai-avante-2024-gasoline';

update public.vehicle_variants
set
  valid_from_year = 2018,
  valid_to_year = 2024,
  is_verified = true,
  source_status = 'verified_official',
  confidence_score = 0.92,
  is_selectable = true,
  is_deprecated = false
where id = 'variant-kia-k3-gt-2024-16t-7dct';

update public.vehicle_variants
set
  is_verified = true,
  source_status = 'verified_official',
  confidence_score = 0.92,
  is_selectable = true,
  is_deprecated = false
where id = 'variant-kia-k3-2024-16-ivt';

insert into public.vehicle_data_sources (
  id,
  source_type,
  source_name,
  source_url,
  source_file_name,
  published_at,
  license_note,
  reliability_level
) values (
  '20260612-0002-4000-8000-000000000001',
  'manufacturer_spec',
  '기아 공식 K3/K3 GT 가격표',
  'https://www.kia.com/content/dam/kwp/kr/ko/vehicles/pdf/price/price_k3gt.pdf',
  'price_k3gt.pdf',
  null,
  '기아 공식 가격표/제원표를 카탈로그 검수 근거로만 사용',
  5
)
on conflict (id) do update set
  source_type = excluded.source_type,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  source_file_name = excluded.source_file_name,
  published_at = excluded.published_at,
  license_note = excluded.license_note,
  reliability_level = excluded.reliability_level;

insert into public.vehicle_powertrain_sources (
  powertrain_id,
  source_id,
  field_name,
  source_value,
  normalized_value,
  confidence_score
)
select
  source_rows.powertrain_id,
  '20260612-0002-4000-8000-000000000001'::uuid,
  null,
  source_rows.source_value,
  source_rows.normalized_value,
  0.92
from (
  values
    (
      'variant-kia-k3-2024-16-ivt',
      'K3 1.6 가솔린 Smartstream G1.6 IVT 15.2km/L',
      '1.6 가솔린 · Smartstream G1.6 · IVT · 15.2km/L'
    ),
    (
      'variant-kia-k3-gt-2024-16t-7dct',
      'K3 GT 1.6T 가솔린 Gamma 1.6 T-GDi 7단 DCT 12.1km/L',
      'K3 GT 1.6T 가솔린 DCT · Gamma 1.6 T-GDi · 7단 DCT · 12.1km/L'
    )
) as source_rows(powertrain_id, source_value, normalized_value)
where exists (
    select 1
    from public.vehicle_variants vv
    where vv.id = source_rows.powertrain_id
  )
  and not exists (
    select 1
    from public.vehicle_powertrain_sources vps
    where vps.powertrain_id = source_rows.powertrain_id
      and vps.source_id = '20260612-0002-4000-8000-000000000001'::uuid
      and vps.field_name is null
  );
