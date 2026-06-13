-- BMW 4/7 Series generation audit.
-- Adds official-source generation mapping while keeping model_years
-- and pending-review placeholder powertrains for later detailed sourcing.

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
    'generation-bmw-4series-f32-f33-f36',
    'model-bmw-054-4',
    1,
    '1세대',
    'First generation',
    'F32/F33/F36',
    'F32/F33/F36',
    2013,
    10,
    2020,
    null,
    '2013.10~2020',
    false,
    false,
    'KR',
    'verified_admin',
    0.76,
    'BMW Korea PressClub 4 Series Coupe launch',
    'https://www.press.bmwgroup.com/korea/article/detail/T0152484KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EB%89%B4-4%EC%8B%9C%EB%A6%AC%EC%A6%88-%EC%BF%A0%ED%8E%98-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-4series-g22-g23-g26',
    'model-bmw-054-4',
    2,
    '2세대',
    'Second generation',
    'G22/G23/G26',
    'G22/G23/G26',
    2021,
    2,
    null,
    null,
    '2021.2~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Korea PressClub 4 Series G22/G23 launch',
    'https://www.press.bmwgroup.com/korea/article/detail/T0325769KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EB%89%B4-4%EC%8B%9C%EB%A6%AC%EC%A6%88-%EA%B5%AD%EB%82%B4-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-7series-g11-g12',
    'model-bmw-056-7',
    6,
    '6세대',
    'Sixth generation',
    'G11/G12',
    'G11/G12',
    2015,
    10,
    2022,
    null,
    '2015.10~2022',
    false,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Korea PressClub 6th generation 7 Series launch',
    'https://www.press.bmwgroup.com/korea/article/detail/T0239522KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-6%EC%84%B8%EB%8C%80-%EB%89%B4-7%EC%8B%9C%EB%A6%AC%EC%A6%88-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-7series-g70',
    'model-bmw-056-7',
    7,
    '7세대',
    'Seventh generation',
    'G70',
    'G70',
    2022,
    12,
    null,
    null,
    '2022.12~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Korea PressClub 7 Series G70 launch',
    'https://www.press.bmwgroup.com/korea/article/detail/T0407078KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EC%83%88%EB%A1%9C%EC%9A%B4-%EC%B0%A8%EC%9B%90%EC%9D%98-%EB%9F%AD%EC%85%94%EB%A6%AC-%ED%94%8C%EB%9E%98%EA%B7%B8%EC%8B%AD-%EC%84%B8%EB%8B%A8-%EB%89%B4-7%EC%8B%9C%EB%A6%AC%EC%A6%88%E2%80%99-%EA%B5%AD%EB%82%B4-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
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
  generation_id = 'generation-bmw-4series-f32-f33-f36',
  production_year_label = '2013.10~2020'
where model_id = 'model-bmw-054-4'
  and year between 2015 and 2020;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-4series-g22-g23-g26',
  production_year_label = '2021.2~현재'
where model_id = 'model-bmw-054-4'
  and year between 2021 and 2026;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-7series-g11-g12',
  production_year_label = '2015.10~2022'
where model_id = 'model-bmw-056-7'
  and year between 2015 and 2022;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-7series-g70',
  production_year_label = '2022.12~현재'
where model_id = 'model-bmw-056-7'
  and year between 2023 and 2026;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select generation_id, id, year
from public.vehicle_model_years
where generation_id in (
  'generation-bmw-4series-f32-f33-f36',
  'generation-bmw-4series-g22-g23-g26',
  'generation-bmw-7series-g11-g12',
  'generation-bmw-7series-g70'
)
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set
  generation_id = vmy.generation_id,
  drivetrain = case
    when vv.drivetrain = 'FWD' then 'RWD'
    else vv.drivetrain
  end
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in ('model-bmw-054-4', 'model-bmw-056-7')
  and vmy.generation_id in (
    'generation-bmw-4series-f32-f33-f36',
    'generation-bmw-4series-g22-g23-g26',
    'generation-bmw-7series-g11-g12',
    'generation-bmw-7series-g70'
  );

update public.vehicle_variants vv
set drivetrain = 'RWD'
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in ('model-bmw-054-4', 'model-bmw-056-7')
  and vv.drivetrain = 'FWD';
