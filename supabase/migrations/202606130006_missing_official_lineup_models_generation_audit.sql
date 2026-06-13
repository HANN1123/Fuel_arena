-- Official homepage missing model generation audit.
-- Adds conservative pending_review generation rows for models that are present
-- on official manufacturer pages but were missing from the seed catalog.

with missing_generations (
  id,
  model_id,
  start_year,
  model_year_start,
  model_year_end,
  display_period,
  source_name,
  source_url,
  confidence_score
) as (
  values
    ('generation-toyota-alphard-official-lineup', 'model-toyota-alphard-kr', 2026, 2026, 2026, '2026~현재', 'Toyota Korea official Alphard page', 'https://www.toyota.co.kr/models/alphard/', 0.68),
    ('generation-lexus-lm-official-lineup', 'model-lexus-lm-kr', 2025, 2025, 2026, '2025~현재', 'Lexus Korea official LM 500h page', 'https://www.lexus.co.kr/models/LM-500h/', 0.60),
    ('generation-mini-aceman-official-lineup', 'model-mini-aceman-kr', 2026, 2026, 2026, '2026~현재', 'MINI Korea official Aceman page', 'https://www.mini.co.kr/ko_KR/home/range/all-electric-mini-aceman.html', 0.66),
    ('generation-peugeot-408-official-lineup', 'model-peugeot-408-kr', 2023, 2023, 2026, '2023~현재', 'Peugeot Korea official 408 launch news', 'https://base.epeugeot.co.kr/Board/Details/145?SrhPg=6&lcdv16=1PR8A5PMA1M0A0B0', 0.62),
    ('generation-jeep-gladiator-official-lineup', 'model-jeep-gladiator-kr', 2025, 2025, 2026, '2025~현재', 'Jeep Korea official Gladiator page', 'https://www.jeep.co.kr/gladiator.html', 0.62),
    ('generation-jeep-grand-cherokee-l-official-lineup', 'model-jeep-grand-cherokee-l-kr', 2024, 2024, 2026, '2024~현재', 'Jeep Korea official Grand Cherokee L page', 'https://www.jeep.co.kr/grand-cherokee-l.html', 0.62),
    ('generation-landrover-discovery-sport-official-lineup', 'model-landrover-discovery-sport-kr', 2025, 2025, 2026, '2025~현재', 'Land Rover Korea official price chart', 'https://www.landroverkorea.co.kr/content/dam/lrdx/pdfs/kr/241118%20RR%20Velar%20Price%20Chart.pdf', 0.62),
    ('generation-landrover-range-rover-velar-official-lineup', 'model-landrover-range-rover-velar-kr', 2025, 2025, 2026, '2025~현재', 'Land Rover Korea official price chart', 'https://www.landroverkorea.co.kr/content/dam/lrdx/pdfs/kr/241118%20RR%20Velar%20Price%20Chart.pdf', 0.62)
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
  mg.id,
  mg.model_id,
  1,
  '공식 라인업',
  'Official lineup',
  '',
  '',
  mg.start_year,
  null,
  null,
  null,
  mg.display_period,
  true,
  false,
  'KR',
  'pending_review',
  mg.confidence_score,
  mg.source_name,
  mg.source_url,
  null,
  '2026-06-13',
  true,
  false,
  now()
from missing_generations mg
join public.vehicle_models vm on vm.id = mg.model_id
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

with missing_generations (
  generation_id,
  model_id,
  model_year_start,
  model_year_end,
  display_period
) as (
  values
    ('generation-toyota-alphard-official-lineup', 'model-toyota-alphard-kr', 2026, 2026, '2026~현재'),
    ('generation-lexus-lm-official-lineup', 'model-lexus-lm-kr', 2025, 2026, '2025~현재'),
    ('generation-mini-aceman-official-lineup', 'model-mini-aceman-kr', 2026, 2026, '2026~현재'),
    ('generation-peugeot-408-official-lineup', 'model-peugeot-408-kr', 2023, 2026, '2023~현재'),
    ('generation-jeep-gladiator-official-lineup', 'model-jeep-gladiator-kr', 2025, 2026, '2025~현재'),
    ('generation-jeep-grand-cherokee-l-official-lineup', 'model-jeep-grand-cherokee-l-kr', 2024, 2026, '2024~현재'),
    ('generation-landrover-discovery-sport-official-lineup', 'model-landrover-discovery-sport-kr', 2025, 2026, '2025~현재'),
    ('generation-landrover-range-rover-velar-official-lineup', 'model-landrover-range-rover-velar-kr', 2025, 2026, '2025~현재')
)
update public.vehicle_model_years vmy
set
  generation_id = mg.generation_id,
  production_year_label = mg.display_period
from missing_generations mg
where vmy.model_id = mg.model_id
  and vmy.year between mg.model_year_start and mg.model_year_end;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select vmy.generation_id, vmy.id, vmy.year
from public.vehicle_model_years vmy
where vmy.generation_id in (
  'generation-toyota-alphard-official-lineup',
  'generation-lexus-lm-official-lineup',
  'generation-mini-aceman-official-lineup',
  'generation-peugeot-408-official-lineup',
  'generation-jeep-gladiator-official-lineup',
  'generation-jeep-grand-cherokee-l-official-lineup',
  'generation-landrover-discovery-sport-official-lineup',
  'generation-landrover-range-rover-velar-official-lineup'
)
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set generation_id = vmy.generation_id
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.generation_id in (
    'generation-toyota-alphard-official-lineup',
    'generation-lexus-lm-official-lineup',
    'generation-mini-aceman-official-lineup',
    'generation-peugeot-408-official-lineup',
    'generation-jeep-gladiator-official-lineup',
    'generation-jeep-grand-cherokee-l-official-lineup',
    'generation-landrover-discovery-sport-official-lineup',
    'generation-landrover-range-rover-velar-official-lineup'
  );
