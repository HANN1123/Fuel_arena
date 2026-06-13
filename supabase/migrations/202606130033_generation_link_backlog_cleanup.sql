-- Link the remaining seeded placeholder variants to official-source generation rows.
-- This does not promote any powertrain to selectable or verified status.

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
    'generation-hyundai-avante-ad',
    'model-hyundai-001-kr',
    6,
    '6세대',
    'Sixth generation',
    'AD',
    'AD',
    2015,
    null,
    2020,
    4,
    '2015~2020.4',
    false,
    false,
    'KR',
    'verified_admin',
    0.68,
    'Hyundai Motor official Avante history and software version list',
    'https://update.hyundai.com/KR/KO/updateNoticeView/software-version',
    null,
    '2026-06-13'::timestamptz,
    true,
    false,
    now()
  ),
  (
    'generation-kia-k3-yd',
    'model-kia-013-k3',
    1,
    '1세대',
    'First generation',
    'YD',
    'YD',
    2015,
    null,
    2018,
    2,
    '2015~2018.2',
    false,
    false,
    'KR',
    'verified_admin',
    0.66,
    'Kia official software version list',
    'https://update.kia.com/KR/KO/updateNoticeView/software-version',
    null,
    '2026-06-13'::timestamptz,
    true,
    false,
    now()
  ),
  (
    'generation-bmw-5series-f10',
    'model-bmw-055-5',
    6,
    '6세대',
    'Sixth generation',
    'F10 LCI',
    'F10',
    2015,
    null,
    2016,
    null,
    '2015~2016',
    false,
    false,
    'KR',
    'verified_admin',
    0.66,
    'BMW Korea PressClub F10 LCI 5 Series release',
    'https://www.press.bmwgroup.com/korea/article/detail/T0233602KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-520d-m-%EC%97%90%EC%96%B4%EB%A1%9C%EB%8B%A4%EC%9D%B4%EB%82%B4%EB%AF%B9-%EC%8A%A4%ED%8E%98%EC%85%9C-%EC%97%90%EB%94%94%EC%85%98-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
    '2026-06-13'::timestamptz,
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
  generation_id = 'generation-hyundai-avante-ad',
  production_year_label = '2015~2020.4'
where model_id = 'model-hyundai-001-kr'
  and year between 2015 and 2019;

update public.vehicle_model_years
set
  generation_id = 'generation-kia-k3-yd',
  production_year_label = '2015~2018.2'
where model_id = 'model-kia-013-k3'
  and year between 2015 and 2017;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-5series-f10',
  production_year_label = '2015~2016'
where model_id = 'model-bmw-055-5'
  and year between 2015 and 2016;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select
  vmy.generation_id,
  vmy.id,
  vmy.year
from public.vehicle_model_years vmy
where (
    vmy.model_id = 'model-hyundai-001-kr'
    and vmy.year between 2015 and 2019
  )
  or (
    vmy.model_id = 'model-kia-013-k3'
    and vmy.year between 2015 and 2017
  )
  or (
    vmy.model_id = 'model-bmw-055-5'
    and vmy.year between 2015 and 2016
  )
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set generation_id = vmy.generation_id
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.generation_id in (
    'generation-hyundai-avante-ad',
    'generation-kia-k3-yd',
    'generation-bmw-5series-f10'
  );
