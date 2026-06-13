-- Genesis, Renault Korea, and KG Mobility official-lineup audit.
-- Adds official-homepage-backed current model rows, connects generations to
-- model years/variants, and deprecates legacy placeholder years or split-out
-- EV/hybrid placeholders.

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
  ('model-genesis-g70-shooting-brake-kr', 'm-genesis', 'G70 슈팅 브레이크', 'G70 Shooting Brake', '왜건', '{"가솔린"}', false, 20),
  ('model-genesis-electrified-g80-kr', 'm-genesis', 'Electrified G80', 'Electrified G80', '전기 세단', '{"전기차"}', false, 40),
  ('model-genesis-electrified-gv70-kr', 'm-genesis', 'Electrified GV70', 'Electrified GV70', '전기 SUV', '{"전기차"}', false, 80),
  ('model-genesis-gv80-coupe-kr', 'm-genesis', 'GV80 Coupe', 'GV80 Coupe', 'SUV 쿠페', '{"가솔린"}', false, 100),
  ('model-renault-arkana-kr', 'm-renault', 'Arkana', 'Arkana', 'SUV 쿠페', '{"가솔린","하이브리드"}', false, 40),
  ('model-renault-filante-kr', 'm-renault', 'Filante', 'Filante', 'SUV 쿠페', '{"하이브리드"}', false, 60),
  ('model-kgm-actyon-kr', 'm-kgm', '액티언', 'Actyon', 'SUV 쿠페', '{"가솔린"}', false, 30),
  ('model-kgm-actyon-hybrid-kr', 'm-kgm', '액티언 하이브리드', 'Actyon Hybrid', 'SUV 쿠페', '{"하이브리드"}', false, 40),
  ('model-kgm-torres-hybrid-kr', 'm-kgm', '토레스 하이브리드', 'Torres Hybrid', 'SUV', '{"하이브리드"}', false, 60),
  ('model-kgm-torres-evx-kr', 'm-kgm', '토레스 EVX', 'Torres EVX', '전기 SUV', '{"전기차"}', false, 70),
  ('model-kgm-musso-kr', 'm-kgm', '무쏘', 'Musso', '픽업', '{"디젤"}', false, 100),
  ('model-kgm-musso-ev-kr', 'm-kgm', '무쏘 EV', 'Musso EV', '전기 픽업', '{"전기차"}', false, 110)
on conflict (id) do update set
  manufacturer_id = excluded.manufacturer_id,
  name_ko = excluded.name_ko,
  name_en = excluded.name_en,
  body_type = excluded.body_type,
  available_fuel_types = excluded.available_fuel_types,
  is_popular = excluded.is_popular,
  sort_order = excluded.sort_order;

update public.vehicle_models
set available_fuel_types = '{"가솔린"}'
where id in ('model-genesis-029-g80', 'model-genesis-032-gv70', 'model-kgm-048-kr');

update public.vehicle_models
set available_fuel_types = '{"가솔린","디젤"}'
where id = 'model-kgm-047-kr';

update public.vehicle_models
set available_fuel_types = '{"디젤"}'
where id in ('model-kgm-049-kr', 'model-kgm-050-kr');

with official_generations (
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
  source_status,
  confidence_score,
  source_name,
  source_url
) as (
  values
    ('generation-genesis-g70-1', 'model-genesis-028-g70', 1, '1세대', 'First generation', '', '', 2017, null, null, null, '2017~현재', true, 'verified_admin', 0.76, 'Genesis G70 launch and official model page', 'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000180'),
    ('generation-genesis-g70-shooting-brake-1', 'model-genesis-g70-shooting-brake-kr', 1, '1세대', 'First generation', '', '', 2022, null, null, null, '2022~현재', true, 'verified_admin', 0.72, 'Genesis G70 Shooting Brake PR and download center', 'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000311'),
    ('generation-genesis-g80-2', 'model-genesis-029-g80', 2, '2세대', 'Second generation', '', '', 2016, null, 2019, null, '2016~2019', false, 'verified_admin', 0.76, 'Genesis G80 generation official PR', 'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000226'),
    ('generation-genesis-g80-3', 'model-genesis-029-g80', 3, '3세대', 'Third generation', '', '', 2020, null, null, null, '2020~현재', true, 'verified_admin', 0.78, 'Genesis The All-new G80 launch and official specs', 'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000221'),
    ('generation-genesis-electrified-g80-1', 'model-genesis-electrified-g80-kr', 1, '1세대', 'First generation', '', '', 2021, null, null, null, '2021~현재', true, 'verified_admin', 0.78, 'Genesis Electrified G80 launch and official specs', 'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000310'),
    ('generation-genesis-g90-1', 'model-genesis-030-g90', 1, '1세대', 'First generation', '', '', 2019, null, 2021, null, '2019~2021', false, 'verified_admin', 0.70, 'Genesis G90 official PR archive', 'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000232'),
    ('generation-genesis-g90-2', 'model-genesis-030-g90', 2, '2세대', 'Second generation', '', '', 2021, null, null, null, '2021~현재', true, 'verified_admin', 0.76, 'Genesis G90 full-change official PR', 'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000330'),
    ('generation-genesis-gv60-1', 'model-genesis-031-gv60', 1, '1세대', 'First generation', '', 'E-GMP', 2021, null, null, null, '2021~현재', true, 'verified_admin', 0.78, 'Genesis GV60 launch and official model page', 'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000319'),
    ('generation-genesis-gv70-1', 'model-genesis-032-gv70', 1, '1세대', 'First generation', '', '', 2020, null, null, null, '2020~현재', true, 'verified_admin', 0.76, 'Genesis GV70 official global reveal', 'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000290'),
    ('generation-genesis-electrified-gv70-1', 'model-genesis-electrified-gv70-kr', 1, '1세대', 'First generation', '', '', 2022, null, null, null, '2022~현재', true, 'verified_admin', 0.76, 'Genesis Electrified GV70 official model page and PR', 'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000339'),
    ('generation-genesis-gv80-1', 'model-genesis-033-gv80', 1, '1세대', 'First generation', '', '', 2020, null, null, null, '2020~현재', true, 'verified_admin', 0.76, 'Genesis GV80 official launch and specs', 'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000224'),
    ('generation-genesis-gv80-coupe-1', 'model-genesis-gv80-coupe-kr', 1, '1세대', 'First generation', '', '', 2023, null, null, null, '2023~현재', true, 'verified_admin', 0.74, 'Genesis GV80 Coupe official model page and PR', 'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000445'),
    ('generation-renault-sm6-1', 'model-renault-042-sm6', 1, '1세대', 'First generation', '', '', 2016, null, 2024, null, '2016~2024', false, 'pending_review', 0.58, null, null),
    ('generation-renault-qm6-1', 'model-renault-043-qm6', 1, '1세대', 'First generation', '', '', 2016, null, 2024, null, '2016~2024', false, 'pending_review', 0.58, null, null),
    ('generation-renault-xm3-1', 'model-renault-044-xm3', 1, '1세대', 'First generation', '', '', 2020, null, 2023, null, '2020~2023', false, 'pending_review', 0.58, null, null),
    ('generation-renault-arkana-1', 'model-renault-arkana-kr', 1, '1세대', 'First generation', '', '', 2024, null, null, null, '2024~현재', true, 'verified_admin', 0.74, 'Renault Korea official Arkana model page', 'https://www.renault.co.kr/ko/model/arkana_overview.jsp'),
    ('generation-renault-grand-koleos-1', 'model-renault-045-kr', 1, '1세대', 'First generation', '', '', 2024, null, null, null, '2024~현재', true, 'verified_admin', 0.76, 'Renault Korea official Grand Koleos model page', 'https://www.renault.co.kr/ko/model/koleos_overview.jsp'),
    ('generation-renault-filante-1', 'model-renault-filante-kr', 1, '1세대', 'First generation', '', '', 2026, null, null, null, '2026~현재', true, 'verified_admin', 0.76, 'Renault Korea official Filante model page', 'https://www.renault.co.kr/ko/model/filante_overview.jsp'),
    ('generation-kgm-tivoli-1', 'model-kgm-046-kr', 1, '1세대', 'First generation', '', '', 2015, null, null, null, '2015~현재', true, 'verified_admin', 0.72, 'KGM official Tivoli model page', 'https://www.kg-mobility.com/pr/model/show-room/200000100010007'),
    ('generation-kgm-korando-c300', 'model-kgm-047-kr', 4, '4세대', 'Fourth generation', '', '', 2019, null, 2024, null, '2019~2024', false, 'pending_review', 0.58, null, null),
    ('generation-kgm-actyon-j120', 'model-kgm-actyon-kr', 2, '2세대', 'Second generation', '', '', 2024, null, null, null, '2024~현재', true, 'verified_admin', 0.72, 'KGM official Actyon model page', 'https://www.kg-mobility.com/pr/model/show-room/200000100010016'),
    ('generation-kgm-actyon-hybrid-j120', 'model-kgm-actyon-hybrid-kr', 2, '2세대', 'Second generation', '', '', 2025, null, null, null, '2025~현재', true, 'verified_admin', 0.72, 'KGM official Actyon Hybrid model page and launch PR', 'https://www.kg-mobility.com/pr/model/show-room/200000100010018'),
    ('generation-kgm-torres-j100', 'model-kgm-048-kr', 1, '1세대', 'First generation', '', '', 2022, null, null, null, '2022~현재', true, 'verified_admin', 0.72, 'KGM official Torres model page and refresh PR', 'https://www.kg-mobility.com/pr/model/show-room/200000100010001'),
    ('generation-kgm-torres-hybrid-j100', 'model-kgm-torres-hybrid-kr', 1, '1세대', 'First generation', '', '', 2025, null, null, null, '2025~현재', true, 'verified_admin', 0.72, 'KGM official Torres Hybrid model page and launch PR', 'https://www.kg-mobility.com/pr/model/show-room/200000100010017'),
    ('generation-kgm-torres-evx-j100', 'model-kgm-torres-evx-kr', 1, '1세대', 'First generation', '', '', 2023, null, null, null, '2023~현재', true, 'verified_admin', 0.72, 'KGM official Torres EVX model page', 'https://www.kg-mobility.com/pr/model/show-room/200000100010009'),
    ('generation-kgm-rexton-y400', 'model-kgm-049-kr', 2, '2세대', 'Second generation', '', '', 2017, null, null, null, '2017~현재', true, 'verified_admin', 0.70, 'KGM official Rexton New Arena model page', 'https://www.kg-mobility.com/pr/model/show-room/200000100010012'),
    ('generation-kgm-rexton-sports-q200', 'model-kgm-050-kr', 1, '렉스턴 스포츠', 'Rexton Sports', '', '', 2018, null, 2025, null, '2018~2025', false, 'verified_admin', 0.72, 'KGM Musso pickup brand official PR', 'https://www.kg-mobility.com/br/news/press-release/0000000996'),
    ('generation-kgm-musso-q300', 'model-kgm-musso-kr', 1, '무쏘', 'Musso pickup brand', '', '', 2025, null, null, null, '2025~현재', true, 'verified_admin', 0.72, 'KGM official Musso model page', 'https://www.kg-mobility.com/pr/model/show-room/200000100030004'),
    ('generation-kgm-musso-ev-q300', 'model-kgm-musso-ev-kr', 1, '무쏘 EV', 'Musso EV', '', '', 2025, null, null, null, '2025~현재', true, 'verified_admin', 0.74, 'KGM official Musso EV model page and launch PR', 'https://www.kg-mobility.com/pr/model/show-room/200000100030003')
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
  false,
  'KR',
  source_status,
  confidence_score,
  source_name,
  source_url,
  null,
  '2026-06-13',
  true,
  false,
  now()
from official_generations
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

with generation_year_mapping (
  model_id,
  year_start,
  year_end,
  generation_id,
  production_year_label
) as (
  values
    ('model-genesis-028-g70', 2017, 2026, 'generation-genesis-g70-1', '2017~현재'),
    ('model-genesis-g70-shooting-brake-kr', 2022, 2026, 'generation-genesis-g70-shooting-brake-1', '2022~현재'),
    ('model-genesis-029-g80', 2016, 2019, 'generation-genesis-g80-2', '2016~2019'),
    ('model-genesis-029-g80', 2020, 2026, 'generation-genesis-g80-3', '2020~현재'),
    ('model-genesis-electrified-g80-kr', 2021, 2026, 'generation-genesis-electrified-g80-1', '2021~현재'),
    ('model-genesis-030-g90', 2019, 2021, 'generation-genesis-g90-1', '2019~2021'),
    ('model-genesis-030-g90', 2022, 2026, 'generation-genesis-g90-2', '2021~현재'),
    ('model-genesis-031-gv60', 2021, 2026, 'generation-genesis-gv60-1', '2021~현재'),
    ('model-genesis-032-gv70', 2021, 2026, 'generation-genesis-gv70-1', '2020~현재'),
    ('model-genesis-electrified-gv70-kr', 2022, 2026, 'generation-genesis-electrified-gv70-1', '2022~현재'),
    ('model-genesis-033-gv80', 2020, 2026, 'generation-genesis-gv80-1', '2020~현재'),
    ('model-genesis-gv80-coupe-kr', 2024, 2026, 'generation-genesis-gv80-coupe-1', '2023~현재'),
    ('model-renault-042-sm6', 2016, 2024, 'generation-renault-sm6-1', '2016~2024'),
    ('model-renault-043-qm6', 2016, 2024, 'generation-renault-qm6-1', '2016~2024'),
    ('model-renault-044-xm3', 2020, 2023, 'generation-renault-xm3-1', '2020~2023'),
    ('model-renault-arkana-kr', 2024, 2026, 'generation-renault-arkana-1', '2024~현재'),
    ('model-renault-045-kr', 2025, 2026, 'generation-renault-grand-koleos-1', '2024~현재'),
    ('model-renault-filante-kr', 2026, 2026, 'generation-renault-filante-1', '2026~현재'),
    ('model-kgm-046-kr', 2015, 2026, 'generation-kgm-tivoli-1', '2015~현재'),
    ('model-kgm-047-kr', 2019, 2024, 'generation-kgm-korando-c300', '2019~2024'),
    ('model-kgm-actyon-kr', 2024, 2026, 'generation-kgm-actyon-j120', '2024~현재'),
    ('model-kgm-actyon-hybrid-kr', 2025, 2026, 'generation-kgm-actyon-hybrid-j120', '2025~현재'),
    ('model-kgm-048-kr', 2022, 2026, 'generation-kgm-torres-j100', '2022~현재'),
    ('model-kgm-torres-hybrid-kr', 2025, 2026, 'generation-kgm-torres-hybrid-j100', '2025~현재'),
    ('model-kgm-torres-evx-kr', 2023, 2026, 'generation-kgm-torres-evx-j100', '2023~현재'),
    ('model-kgm-049-kr', 2017, 2026, 'generation-kgm-rexton-y400', '2017~현재'),
    ('model-kgm-050-kr', 2018, 2025, 'generation-kgm-rexton-sports-q200', '2018~2025'),
    ('model-kgm-musso-kr', 2025, 2026, 'generation-kgm-musso-q300', '2025~현재'),
    ('model-kgm-musso-ev-kr', 2025, 2026, 'generation-kgm-musso-ev-q300', '2025~현재')
),
missing_years as (
  select
    gym.model_id,
    year,
    gym.generation_id,
    gym.production_year_label
  from generation_year_mapping gym
  cross join lateral generate_series(gym.year_start, gym.year_end) as gs(year)
  where gym.model_id in (
    'model-genesis-g70-shooting-brake-kr',
    'model-genesis-electrified-g80-kr',
    'model-genesis-electrified-gv70-kr',
    'model-genesis-gv80-coupe-kr',
    'model-renault-arkana-kr',
    'model-renault-filante-kr',
    'model-kgm-actyon-kr',
    'model-kgm-actyon-hybrid-kr',
    'model-kgm-torres-hybrid-kr',
    'model-kgm-torres-evx-kr',
    'model-kgm-musso-kr',
    'model-kgm-musso-ev-kr'
  )
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
from missing_years
on conflict (id) do update set
  model_id = excluded.model_id,
  year = excluded.year,
  generation_id = excluded.generation_id,
  production_year_label = excluded.production_year_label;

with generation_year_mapping (
  model_id,
  year_start,
  year_end,
  generation_id,
  production_year_label
) as (
  values
    ('model-genesis-028-g70', 2017, 2026, 'generation-genesis-g70-1', '2017~현재'),
    ('model-genesis-g70-shooting-brake-kr', 2022, 2026, 'generation-genesis-g70-shooting-brake-1', '2022~현재'),
    ('model-genesis-029-g80', 2016, 2019, 'generation-genesis-g80-2', '2016~2019'),
    ('model-genesis-029-g80', 2020, 2026, 'generation-genesis-g80-3', '2020~현재'),
    ('model-genesis-electrified-g80-kr', 2021, 2026, 'generation-genesis-electrified-g80-1', '2021~현재'),
    ('model-genesis-030-g90', 2019, 2021, 'generation-genesis-g90-1', '2019~2021'),
    ('model-genesis-030-g90', 2022, 2026, 'generation-genesis-g90-2', '2021~현재'),
    ('model-genesis-031-gv60', 2021, 2026, 'generation-genesis-gv60-1', '2021~현재'),
    ('model-genesis-032-gv70', 2021, 2026, 'generation-genesis-gv70-1', '2020~현재'),
    ('model-genesis-electrified-gv70-kr', 2022, 2026, 'generation-genesis-electrified-gv70-1', '2022~현재'),
    ('model-genesis-033-gv80', 2020, 2026, 'generation-genesis-gv80-1', '2020~현재'),
    ('model-genesis-gv80-coupe-kr', 2024, 2026, 'generation-genesis-gv80-coupe-1', '2023~현재'),
    ('model-renault-042-sm6', 2016, 2024, 'generation-renault-sm6-1', '2016~2024'),
    ('model-renault-043-qm6', 2016, 2024, 'generation-renault-qm6-1', '2016~2024'),
    ('model-renault-044-xm3', 2020, 2023, 'generation-renault-xm3-1', '2020~2023'),
    ('model-renault-arkana-kr', 2024, 2026, 'generation-renault-arkana-1', '2024~현재'),
    ('model-renault-045-kr', 2025, 2026, 'generation-renault-grand-koleos-1', '2024~현재'),
    ('model-renault-filante-kr', 2026, 2026, 'generation-renault-filante-1', '2026~현재'),
    ('model-kgm-046-kr', 2015, 2026, 'generation-kgm-tivoli-1', '2015~현재'),
    ('model-kgm-047-kr', 2019, 2024, 'generation-kgm-korando-c300', '2019~2024'),
    ('model-kgm-actyon-kr', 2024, 2026, 'generation-kgm-actyon-j120', '2024~현재'),
    ('model-kgm-actyon-hybrid-kr', 2025, 2026, 'generation-kgm-actyon-hybrid-j120', '2025~현재'),
    ('model-kgm-048-kr', 2022, 2026, 'generation-kgm-torres-j100', '2022~현재'),
    ('model-kgm-torres-hybrid-kr', 2025, 2026, 'generation-kgm-torres-hybrid-j100', '2025~현재'),
    ('model-kgm-torres-evx-kr', 2023, 2026, 'generation-kgm-torres-evx-j100', '2023~현재'),
    ('model-kgm-049-kr', 2017, 2026, 'generation-kgm-rexton-y400', '2017~현재'),
    ('model-kgm-050-kr', 2018, 2025, 'generation-kgm-rexton-sports-q200', '2018~2025'),
    ('model-kgm-musso-kr', 2025, 2026, 'generation-kgm-musso-q300', '2025~현재'),
    ('model-kgm-musso-ev-kr', 2025, 2026, 'generation-kgm-musso-ev-q300', '2025~현재')
)
update public.vehicle_model_years vmy
set
  generation_id = gym.generation_id,
  production_year_label = gym.production_year_label
from generation_year_mapping gym
where vmy.model_id = gym.model_id
  and vmy.year between gym.year_start and gym.year_end;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select generation_id, id, year
from public.vehicle_model_years
where generation_id in (
  'generation-genesis-g70-1',
  'generation-genesis-g70-shooting-brake-1',
  'generation-genesis-g80-2',
  'generation-genesis-g80-3',
  'generation-genesis-electrified-g80-1',
  'generation-genesis-g90-1',
  'generation-genesis-g90-2',
  'generation-genesis-gv60-1',
  'generation-genesis-gv70-1',
  'generation-genesis-electrified-gv70-1',
  'generation-genesis-gv80-1',
  'generation-genesis-gv80-coupe-1',
  'generation-renault-sm6-1',
  'generation-renault-qm6-1',
  'generation-renault-xm3-1',
  'generation-renault-arkana-1',
  'generation-renault-grand-koleos-1',
  'generation-renault-filante-1',
  'generation-kgm-tivoli-1',
  'generation-kgm-korando-c300',
  'generation-kgm-actyon-j120',
  'generation-kgm-actyon-hybrid-j120',
  'generation-kgm-torres-j100',
  'generation-kgm-torres-hybrid-j100',
  'generation-kgm-torres-evx-j100',
  'generation-kgm-rexton-y400',
  'generation-kgm-rexton-sports-q200',
  'generation-kgm-musso-q300',
  'generation-kgm-musso-ev-q300'
)
on conflict (generation_id, model_year_id) do nothing;

with new_powertrains (
  model_id,
  fuel_type,
  trim_name,
  engine_name,
  displacement_cc,
  battery_kwh,
  drivetrain,
  transmission,
  efficiency_unit,
  vehicle_class,
  fuel_league,
  sort_order
) as (
  values
    ('model-genesis-g70-shooting-brake-kr', '가솔린', '2.0 가솔린', '2.0 Gasoline', 1999, null::numeric, 'FWD', '자동', 'km/L', '중형', 'gasoline', 10),
    ('model-genesis-electrified-g80-kr', '전기차', '전기차', 'Electric Motor', null::integer, null::numeric, '전동 구동', '감속기', 'km/kWh', '대형', 'electric', 10),
    ('model-genesis-electrified-gv70-kr', '전기차', '전기차', 'Electric Motor', null::integer, null::numeric, '전동 구동', '감속기', 'km/kWh', 'SUV', 'electric', 10),
    ('model-genesis-gv80-coupe-kr', '가솔린', '2.5 가솔린', '2.5 Gasoline', 2497, null::numeric, 'FWD', '자동', 'km/L', '대형 SUV', 'gasoline', 10),
    ('model-renault-arkana-kr', '가솔린', '1.6 가솔린', '1.6 Gasoline', 1598, null::numeric, 'FWD', '자동', 'km/L', '소형 SUV', 'gasoline', 10),
    ('model-renault-arkana-kr', '하이브리드', '1.6 하이브리드', '1.6 Hybrid', 1598, null::numeric, 'FWD', '하이브리드 전용 변속기', 'km/L', '소형 SUV', 'hybrid', 20),
    ('model-renault-filante-kr', '하이브리드', '하이브리드', 'Hybrid', null::integer, null::numeric, 'FWD', '하이브리드 전용 변속기', 'km/L', '대형 SUV', 'hybrid', 10),
    ('model-kgm-actyon-kr', '가솔린', '1.5 가솔린', '1.5 Gasoline', 1497, null::numeric, 'FWD', '자동', 'km/L', 'SUV', 'gasoline', 10),
    ('model-kgm-actyon-hybrid-kr', '하이브리드', '1.5 하이브리드', '1.5 Hybrid', 1497, null::numeric, 'FWD', '하이브리드 전용 변속기', 'km/L', 'SUV', 'hybrid', 10),
    ('model-kgm-torres-hybrid-kr', '하이브리드', '1.5 하이브리드', '1.5 Hybrid', 1497, null::numeric, 'FWD', '하이브리드 전용 변속기', 'km/L', 'SUV', 'hybrid', 10),
    ('model-kgm-torres-evx-kr', '전기차', '전기차', 'Electric Motor', null::integer, null::numeric, '전동 구동', '감속기', 'km/kWh', 'SUV', 'electric', 10),
    ('model-kgm-musso-kr', '디젤', '2.2 디젤', '2.2 Diesel', 2157, null::numeric, 'RWD', '자동', 'km/L', '픽업', 'diesel', 10),
    ('model-kgm-musso-ev-kr', '전기차', '전기차', 'Electric Motor', null::integer, null::numeric, '전동 구동', '감속기', 'km/kWh', '픽업', 'electric', 10)
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
  'variant-' || replace(vmy.id, 'year-', '') || '-' || np.fuel_league,
  vmy.id,
  vmy.generation_id,
  np.trim_name,
  np.engine_name,
  np.fuel_type,
  np.displacement_cc,
  np.battery_kwh,
  np.drivetrain,
  np.transmission,
  null,
  np.efficiency_unit,
  np.vehicle_class,
  np.fuel_league,
  false,
  'unverified',
  0,
  true,
  false,
  np.sort_order
from public.vehicle_model_years vmy
join new_powertrains np on np.model_id = vmy.model_id
where vmy.generation_id is not null
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

update public.vehicle_variants vv
set generation_id = vmy.generation_id
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.generation_id in (
    'generation-genesis-g70-1',
    'generation-genesis-g70-shooting-brake-1',
    'generation-genesis-g80-2',
    'generation-genesis-g80-3',
    'generation-genesis-electrified-g80-1',
    'generation-genesis-g90-1',
    'generation-genesis-g90-2',
    'generation-genesis-gv60-1',
    'generation-genesis-gv70-1',
    'generation-genesis-electrified-gv70-1',
    'generation-genesis-gv80-1',
    'generation-genesis-gv80-coupe-1',
    'generation-renault-sm6-1',
    'generation-renault-qm6-1',
    'generation-renault-xm3-1',
    'generation-renault-arkana-1',
    'generation-renault-grand-koleos-1',
    'generation-renault-filante-1',
    'generation-kgm-tivoli-1',
    'generation-kgm-korando-c300',
    'generation-kgm-actyon-j120',
    'generation-kgm-actyon-hybrid-j120',
    'generation-kgm-torres-j100',
    'generation-kgm-torres-hybrid-j100',
    'generation-kgm-torres-evx-j100',
    'generation-kgm-rexton-y400',
    'generation-kgm-rexton-sports-q200',
    'generation-kgm-musso-q300',
    'generation-kgm-musso-ev-q300'
  );

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and (
    (vmy.model_id = 'model-genesis-028-g70' and vmy.year < 2017)
    or (vmy.model_id = 'model-genesis-029-g80' and vmy.year < 2016)
    or (vmy.model_id = 'model-genesis-030-g90' and vmy.year < 2019)
    or (vmy.model_id = 'model-genesis-031-gv60' and vmy.year < 2021)
    or (vmy.model_id = 'model-genesis-032-gv70' and vmy.year < 2021)
    or (vmy.model_id = 'model-genesis-033-gv80' and vmy.year < 2020)
    or (vmy.model_id = 'model-renault-042-sm6' and vmy.year > 2024)
    or (vmy.model_id = 'model-renault-043-qm6' and vmy.year > 2024)
    or (vmy.model_id = 'model-renault-044-xm3' and vmy.year > 2023)
    or (vmy.model_id = 'model-renault-045-kr' and vmy.year < 2025)
    or (vmy.model_id = 'model-kgm-047-kr' and (vmy.year < 2019 or vmy.year > 2024))
    or (vmy.model_id = 'model-kgm-048-kr' and vmy.year < 2022)
    or (vmy.model_id = 'model-kgm-049-kr' and vmy.year < 2017)
    or (vmy.model_id = 'model-kgm-050-kr' and (vmy.year < 2018 or vmy.year > 2025))
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
    (vmy.model_id = 'model-genesis-028-g70' and vmy.year < 2017)
    or (vmy.model_id = 'model-genesis-029-g80' and (vmy.year < 2016 or vv.fuel_type = '전기차'))
    or (vmy.model_id = 'model-genesis-030-g90' and vmy.year < 2019)
    or (vmy.model_id = 'model-genesis-031-gv60' and vmy.year < 2021)
    or (vmy.model_id = 'model-genesis-032-gv70' and (vmy.year < 2021 or vv.fuel_type = '전기차'))
    or (vmy.model_id = 'model-genesis-033-gv80' and vmy.year < 2020)
    or (vmy.model_id = 'model-renault-042-sm6' and vmy.year > 2024)
    or (vmy.model_id = 'model-renault-043-qm6' and vmy.year > 2024)
    or (vmy.model_id = 'model-renault-044-xm3' and vmy.year > 2023)
    or (vmy.model_id = 'model-renault-045-kr' and vmy.year < 2025)
    or (vmy.model_id = 'model-kgm-047-kr' and (vmy.year < 2019 or vmy.year > 2024))
    or (vmy.model_id = 'model-kgm-048-kr' and (vmy.year < 2022 or vv.fuel_type <> '가솔린'))
    or (vmy.model_id = 'model-kgm-049-kr' and vmy.year < 2017)
    or (vmy.model_id = 'model-kgm-050-kr' and (vmy.year < 2018 or vmy.year > 2025))
  );

update public.vehicle_model_years
set
  generation_id = null,
  production_year_label = null
where (
    model_id = 'model-genesis-028-g70'
    and year < 2017
  )
  or (
    model_id = 'model-genesis-029-g80'
    and year < 2016
  )
  or (
    model_id = 'model-genesis-030-g90'
    and year < 2019
  )
  or (
    model_id = 'model-genesis-031-gv60'
    and year < 2021
  )
  or (
    model_id = 'model-genesis-032-gv70'
    and year < 2021
  )
  or (
    model_id = 'model-genesis-033-gv80'
    and year < 2020
  )
  or (
    model_id = 'model-renault-042-sm6'
    and year > 2024
  )
  or (
    model_id = 'model-renault-043-qm6'
    and year > 2024
  )
  or (
    model_id = 'model-renault-044-xm3'
    and year > 2023
  )
  or (
    model_id = 'model-renault-045-kr'
    and year < 2025
  )
  or (
    model_id = 'model-kgm-047-kr'
    and (year < 2019 or year > 2024)
  )
  or (
    model_id = 'model-kgm-048-kr'
    and year < 2022
  )
  or (
    model_id = 'model-kgm-049-kr'
    and year < 2017
  )
  or (
    model_id = 'model-kgm-050-kr'
    and (year < 2018 or year > 2025)
  );
