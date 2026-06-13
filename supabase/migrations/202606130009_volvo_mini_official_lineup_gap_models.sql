-- Volvo/MINI official-lineup missing model audit.
-- Adds current official Korea model-overview entries that were absent from the
-- seed catalog. Powertrain placeholders are intentionally non-selectable until
-- domestic specification sheets are audited.

insert into public.vehicle_models (
  id,
  manufacturer_id,
  name_ko,
  name_en,
  body_type,
  available_fuel_types,
  is_popular,
  sort_order
)
values
  ('model-volvo-ex30-cross-country-kr', 'm-volvo', 'EX30 Cross Country', 'EX30 Cross Country', '전기 SUV', '{"전기차"}', false, 85),
  ('model-volvo-es90-kr', 'm-volvo', 'ES90', 'ES90', '전기 세단', '{"전기차"}', false, 86),
  ('model-mini-cooper-5-door-kr', 'm-mini', 'MINI Cooper 5-Door', 'MINI Cooper 5-Door', '해치백', '{"가솔린"}', false, 70),
  ('model-mini-electric-cooper-kr', 'm-mini', 'All-Electric MINI Cooper', 'All-Electric MINI Cooper', '전기차', '{"전기차"}', false, 80),
  ('model-mini-electric-countryman-kr', 'm-mini', 'All-Electric MINI Countryman', 'All-Electric MINI Countryman', '전기 SUV', '{"전기차"}', false, 90),
  ('model-mini-jcw-kr', 'm-mini', 'John Cooper Works', 'John Cooper Works', '스포츠카', '{"가솔린","전기차"}', false, 100)
on conflict (id) do update set
  manufacturer_id = excluded.manufacturer_id,
  name_ko = excluded.name_ko,
  name_en = excluded.name_en,
  body_type = excluded.body_type,
  available_fuel_types = excluded.available_fuel_types,
  is_popular = excluded.is_popular,
  sort_order = excluded.sort_order;

with official_lineup_generations (
  id,
  model_id,
  start_year,
  model_year_start,
  display_period,
  confidence_score,
  source_name,
  source_url
) as (
  values
    ('generation-volvo-ex30-cross-country-official-lineup', 'model-volvo-ex30-cross-country-kr', 2025, 2025, '2025~현재', 0.66, 'Volvo Cars Korea official EX30 Cross Country launch', 'https://www.volvocars.com/kr/news/culture/20250904-Launch-of-the-EX30-Cross-Country/'),
    ('generation-volvo-es90-official-lineup', 'model-volvo-es90-kr', 2026, 2026, '2026~현재', 0.64, 'Volvo Cars Korea official ES90 preorder notice', 'https://www.volvocars.com/kr/news/culture/20260611-Volvo-Car-Opens-ES90-Pre-Orders/'),
    ('generation-mini-cooper-5-door-official-lineup', 'model-mini-cooper-5-door-kr', 2026, 2026, '2026~현재', 0.62, 'MINI Korea official model range', 'https://www.mini.co.kr/ko_KR/home.html'),
    ('generation-mini-electric-cooper-official-lineup', 'model-mini-electric-cooper-kr', 2026, 2026, '2026~현재', 0.62, 'MINI Korea official model range', 'https://www.mini.co.kr/ko_KR/home.html'),
    ('generation-mini-electric-countryman-official-lineup', 'model-mini-electric-countryman-kr', 2026, 2026, '2026~현재', 0.62, 'MINI Korea official model range', 'https://www.mini.co.kr/ko_KR/home.html'),
    ('generation-mini-jcw-official-lineup', 'model-mini-jcw-kr', 2026, 2026, '2026~현재', 0.62, 'MINI Korea official John Cooper Works page', 'https://www.mini.co.kr/ko_KR/home/range/john-cooper-works.html')
)
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
)
select
  id,
  model_id,
  1,
  '공식 라인업',
  'Official lineup',
  '',
  '',
  start_year,
  null,
  null,
  null,
  display_period,
  true,
  false,
  'KR',
  'pending_review',
  confidence_score,
  source_name,
  source_url,
  null,
  '2026-06-13',
  true,
  false,
  now()
from official_lineup_generations
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

with official_lineup_years (
  model_id,
  generation_id,
  year,
  production_year_label
) as (
  values
    ('model-volvo-ex30-cross-country-kr', 'generation-volvo-ex30-cross-country-official-lineup', 2025, '2025~현재'),
    ('model-volvo-ex30-cross-country-kr', 'generation-volvo-ex30-cross-country-official-lineup', 2026, '2025~현재'),
    ('model-volvo-es90-kr', 'generation-volvo-es90-official-lineup', 2026, '2026~현재'),
    ('model-mini-cooper-5-door-kr', 'generation-mini-cooper-5-door-official-lineup', 2026, '2026~현재'),
    ('model-mini-electric-cooper-kr', 'generation-mini-electric-cooper-official-lineup', 2026, '2026~현재'),
    ('model-mini-electric-countryman-kr', 'generation-mini-electric-countryman-official-lineup', 2026, '2026~현재'),
    ('model-mini-jcw-kr', 'generation-mini-jcw-official-lineup', 2026, '2026~현재')
)
insert into public.vehicle_model_years (
  id,
  model_id,
  year,
  generation_id,
  production_year_label
)
select
  replace(model_id, 'model-', 'year-') || '-' || year,
  model_id,
  year,
  generation_id,
  production_year_label
from official_lineup_years
on conflict (id) do update set
  model_id = excluded.model_id,
  year = excluded.year,
  generation_id = excluded.generation_id,
  production_year_label = excluded.production_year_label;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select generation_id, id, year
from public.vehicle_model_years
where generation_id in (
  'generation-volvo-ex30-cross-country-official-lineup',
  'generation-volvo-es90-official-lineup',
  'generation-mini-cooper-5-door-official-lineup',
  'generation-mini-electric-cooper-official-lineup',
  'generation-mini-electric-countryman-official-lineup',
  'generation-mini-jcw-official-lineup'
)
on conflict (generation_id, model_year_id) do nothing;

with official_lineup_powertrains (
  model_id,
  year,
  fuel_type,
  efficiency_unit,
  vehicle_class,
  fuel_league,
  sort_order
) as (
  values
    ('model-volvo-ex30-cross-country-kr', 2025, '전기차', 'km/kWh', '소형 SUV', 'electric', 10),
    ('model-volvo-ex30-cross-country-kr', 2026, '전기차', 'km/kWh', '소형 SUV', 'electric', 10),
    ('model-volvo-es90-kr', 2026, '전기차', 'km/kWh', '대형', 'electric', 10),
    ('model-mini-cooper-5-door-kr', 2026, '가솔린', 'km/L', '소형', 'gasoline', 10),
    ('model-mini-electric-cooper-kr', 2026, '전기차', 'km/kWh', '소형', 'electric', 10),
    ('model-mini-electric-countryman-kr', 2026, '전기차', 'km/kWh', '소형 SUV', 'electric', 10),
    ('model-mini-jcw-kr', 2026, '가솔린', 'km/L', '스포츠', 'gasoline', 10),
    ('model-mini-jcw-kr', 2026, '전기차', 'km/kWh', '스포츠', 'electric', 20)
)
insert into public.vehicle_variants (
  id,
  model_year_id,
  generation_id,
  trim_name,
  engine_name,
  fuel_type,
  displacement_cc,
  battery_kwh,
  drivetrain,
  transmission,
  official_efficiency,
  efficiency_unit,
  vehicle_class,
  fuel_league,
  is_verified,
  source_status,
  confidence_score,
  is_selectable,
  is_deprecated,
  sort_order
)
select
  'variant-' || replace(vmy.id, 'year-', '') || '-' || p.fuel_league,
  vmy.id,
  vmy.generation_id,
  '공식 제원 검수 대기',
  'Pending official specification review',
  p.fuel_type,
  null::integer,
  null::numeric,
  '검수 대기',
  '검수 대기',
  null,
  p.efficiency_unit,
  p.vehicle_class,
  p.fuel_league,
  false,
  'pending_review',
  0.1,
  false,
  false,
  p.sort_order
from official_lineup_powertrains p
join public.vehicle_model_years vmy
  on vmy.model_id = p.model_id
  and vmy.year = p.year
on conflict (id) do update set
  model_year_id = excluded.model_year_id,
  generation_id = excluded.generation_id,
  trim_name = excluded.trim_name,
  engine_name = excluded.engine_name,
  fuel_type = excluded.fuel_type,
  displacement_cc = excluded.displacement_cc,
  battery_kwh = excluded.battery_kwh,
  drivetrain = excluded.drivetrain,
  transmission = excluded.transmission,
  official_efficiency = excluded.official_efficiency,
  efficiency_unit = excluded.efficiency_unit,
  vehicle_class = excluded.vehicle_class,
  fuel_league = excluded.fuel_league,
  is_verified = excluded.is_verified,
  source_status = excluded.source_status,
  confidence_score = excluded.confidence_score,
  is_selectable = excluded.is_selectable,
  is_deprecated = excluded.is_deprecated,
  sort_order = excluded.sort_order;

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and (
    (vmy.model_id = 'model-volvo-ex30-cross-country-kr' and vmy.year < 2025)
    or (vmy.model_id = 'model-volvo-es90-kr' and vmy.year < 2026)
    or (vmy.model_id in (
      'model-mini-cooper-5-door-kr',
      'model-mini-electric-cooper-kr',
      'model-mini-electric-countryman-kr',
      'model-mini-jcw-kr'
    ) and vmy.year < 2026)
  );

update public.vehicle_variants vv
set
  generation_id = null,
  source_status = 'deprecated',
  is_verified = false,
  is_selectable = false,
  is_deprecated = true
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and (
    (vmy.model_id = 'model-volvo-ex30-cross-country-kr' and vmy.year < 2025)
    or (vmy.model_id = 'model-volvo-es90-kr' and vmy.year < 2026)
    or (vmy.model_id in (
      'model-mini-cooper-5-door-kr',
      'model-mini-electric-cooper-kr',
      'model-mini-electric-countryman-kr',
      'model-mini-jcw-kr'
    ) and vmy.year < 2026)
  );

update public.vehicle_model_years
set
  generation_id = null,
  production_year_label = null
where (
    model_id = 'model-volvo-ex30-cross-country-kr'
    and year < 2025
  )
  or (
    model_id = 'model-volvo-es90-kr'
    and year < 2026
  )
  or (
    model_id in (
      'model-mini-cooper-5-door-kr',
      'model-mini-electric-cooper-kr',
      'model-mini-electric-countryman-kr',
      'model-mini-jcw-kr'
    )
    and year < 2026
  );
