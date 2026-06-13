-- BMW electric model generation audit.
-- Keeps legacy model_year rows for backend compatibility, but deprecates
-- pre-launch placeholder variants and links sourced generation ranges.

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
    'generation-bmw-i4-g26',
    'model-bmw-061-i4',
    1,
    '1세대',
    'First generation',
    'G26',
    'G26',
    2022,
    4,
    null,
    null,
    '2022.4~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.72,
    'BMW Group PressClub Korea i4 release',
    'https://www.press.bmwgroup.com/korea/photo/detail/P90456990/BMW-Korea-to-officially-release-the-BMW-i4-the-brand%E2%80%99s-first-all-electric-gran-coupe-04-2022?forceSitePreference=DESKTOP',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-i5-g60',
    'model-bmw-062-i5',
    1,
    '1세대',
    'First generation',
    'G60',
    'G60',
    2024,
    3,
    null,
    null,
    '2024.3~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.72,
    'BMW Group PressClub i5 xDrive40 production note',
    'https://www.press.bmwgroup.com/canada/article/detail/T0437821EN/market-launch-of-the-new-bmw-5-series-sedan-and-the-first-bmw-i5?language=en',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-ix-i20',
    'model-bmw-063-ix',
    1,
    '1세대',
    'First generation',
    'i20',
    'i20',
    2022,
    null,
    null,
    null,
    '2022~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.72,
    'BMW Group PressClub Korea iX/iX3 release',
    'https://www.press.bmwgroup.com/korea/photo/detail/P90445396/BMW-Korea-to-officially-release-new-pure-electric-models-the-BMW-iX-and-iX3-in-Korea-11-2021?forceSitePreference=DESKTOP',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-ix3-g08',
    'model-bmw-064-ix3',
    1,
    '1세대',
    'First generation',
    'G08',
    'G08',
    2022,
    null,
    null,
    null,
    '2022~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.72,
    'BMW Group PressClub Korea iX/iX3 release',
    'https://www.press.bmwgroup.com/korea/photo/detail/P90445396/BMW-Korea-to-officially-release-new-pure-electric-models-the-BMW-iX-and-iX3-in-Korea-11-2021?forceSitePreference=DESKTOP',
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
  generation_id = 'generation-bmw-i4-g26',
  production_year_label = '2022.4~현재'
where model_id = 'model-bmw-061-i4'
  and year between 2022 and 2026;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-i5-g60',
  production_year_label = '2024.3~현재'
where model_id = 'model-bmw-062-i5'
  and year between 2024 and 2026;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-ix-i20',
  production_year_label = '2022~현재'
where model_id = 'model-bmw-063-ix'
  and year between 2022 and 2026;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-ix3-g08',
  production_year_label = '2022~현재'
where model_id = 'model-bmw-064-ix3'
  and year between 2022 and 2026;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select generation_id, id, year
from public.vehicle_model_years
where generation_id in (
  'generation-bmw-i4-g26',
  'generation-bmw-i5-g60',
  'generation-bmw-ix-i20',
  'generation-bmw-ix3-g08'
)
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set generation_id = vmy.generation_id
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.generation_id in (
    'generation-bmw-i4-g26',
    'generation-bmw-i5-g60',
    'generation-bmw-ix-i20',
    'generation-bmw-ix3-g08'
  );

update public.vehicle_variants vv
set
  source_status = 'deprecated',
  is_verified = false,
  is_selectable = false,
  is_deprecated = true,
  confidence_score = 0.05
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and (
    (vmy.model_id = 'model-bmw-061-i4' and vmy.year < 2022)
    or (vmy.model_id = 'model-bmw-062-i5' and vmy.year < 2024)
    or (vmy.model_id = 'model-bmw-063-ix' and vmy.year < 2022)
    or (vmy.model_id = 'model-bmw-064-ix3' and vmy.year < 2022)
  );
