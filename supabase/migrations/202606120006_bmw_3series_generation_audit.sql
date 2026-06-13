-- BMW 3 Series generation audit.
-- Adds official-source F30/G20 generation mapping while keeping model_years
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
    'generation-bmw-3series-f30',
    'model-bmw-053-3',
    6,
    '6세대',
    'Sixth generation',
    'F30',
    'F30',
    2012,
    null,
    2018,
    null,
    '2012~2018',
    false,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Korea PressClub 3 Series history',
    'https://www.press.bmwgroup.com/korea/article/detail/T0264213KO/%EC%95%9E%EC%84%A0-%EA%B8%B0%EC%88%A0%EA%B3%BC-%ED%98%81%EC%8B%A0%EC%9D%84-%EC%9D%B4%EC%96%B4%EC%98%A8-bmw-3%EC%8B%9C%EB%A6%AC%EC%A6%88%EC%9D%98-%EC%97%AD%EC%82%AC?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-3series-g20',
    'model-bmw-053-3',
    7,
    '7세대',
    'Seventh generation',
    'G20',
    'G20',
    2019,
    3,
    null,
    null,
    '2019.3~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Group PressClub 3 Series G20 launch',
    'https://www.press.bmwgroup.com/global/article/detail/T0285128EN/the-all-new-bmw-3-series-sedan?language=en',
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
  generation_id = 'generation-bmw-3series-f30',
  production_year_label = '2012~2018'
where model_id = 'model-bmw-053-3'
  and year between 2015 and 2018;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-3series-g20',
  production_year_label = '2019.3~현재'
where model_id = 'model-bmw-053-3'
  and year between 2019 and 2026;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select generation_id, id, year
from public.vehicle_model_years
where generation_id in (
  'generation-bmw-3series-f30',
  'generation-bmw-3series-g20'
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
  and vmy.model_id = 'model-bmw-053-3'
  and vmy.generation_id in (
    'generation-bmw-3series-f30',
    'generation-bmw-3series-g20'
  );

update public.vehicle_variants vv
set drivetrain = 'RWD'
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id = 'model-bmw-053-3'
  and vv.drivetrain = 'FWD';
