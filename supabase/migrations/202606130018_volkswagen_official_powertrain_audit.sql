-- Volkswagen Korea official 2026 powertrain audit.
-- Current official model list: Golf, Golf GTI, Touareg, Atlas, ID.4, ID.5.
-- Only price-list rows with domestic efficiency/spec data are selectable.

update public.vehicle_models
set available_fuel_types = '{"디젤"}'
where id = 'model-volkswagen-089-kr';

with retired_generation_updates (
  id,
  display_period
) as (
  values
    ('generation-volkswagen-jetta-official-lineup', '2015~2025'),
    ('generation-volkswagen-passat-official-lineup', '2015~2025'),
    ('generation-volkswagen-tiguan-official-lineup', '2015~2025'),
    ('generation-volkswagen-arteon-official-lineup', '2015~2025')
)
update public.vehicle_generations vg
set
  display_period = rgu.display_period,
  is_current = false,
  is_selectable = false,
  confidence_score = least(coalesce(vg.confidence_score, 0.52), 0.52),
  updated_at = now()
from retired_generation_updates rgu
where vg.id = rgu.id;

with current_generation_sources (
  id,
  source_name,
  source_url,
  confidence_score
) as (
  values
    ('generation-volkswagen-golf-official-lineup', 'Volkswagen Korea official Golf model page', 'https://www.volkswagen.co.kr/ko/models/golf.html', 0.62),
    ('generation-volkswagen-golf-gti-official-lineup', 'Volkswagen Korea official Golf GTI model page', 'https://www.volkswagen.co.kr/ko/models/golf_gti.html', 0.62),
    ('generation-volkswagen-touareg-official-lineup', 'Volkswagen Korea official Touareg model page', 'https://www.volkswagen.co.kr/ko/models/touareg.html', 0.62),
    ('generation-volkswagen-atlas-official-lineup', 'Volkswagen Korea official Atlas model page', 'https://www.volkswagen.co.kr/ko/models/atlas.html', 0.62),
    ('generation-volkswagen-id4-official-lineup', 'Volkswagen Korea official ID.4 model page', 'https://www.volkswagen.co.kr/ko/models/id4.html', 0.64),
    ('generation-volkswagen-id5-official-lineup', 'Volkswagen Korea official ID.5 model page', 'https://www.volkswagen.co.kr/ko/models/id5.html', 0.64)
)
update public.vehicle_generations vg
set
  source_name = cgs.source_name,
  source_url = cgs.source_url,
  confidence_score = cgs.confidence_score,
  is_current = true,
  is_selectable = true,
  last_verified_at = '2026-06-13',
  updated_at = now()
from current_generation_sources cgs
where vg.id = cgs.id;

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and vmy.model_id in (
    'model-volkswagen-090-kr',
    'model-volkswagen-091-kr',
    'model-volkswagen-092-kr',
    'model-volkswagen-095-kr'
  )
  and vmy.year = 2026;

delete from public.vehicle_variants vv
using public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in (
    'model-volkswagen-090-kr',
    'model-volkswagen-091-kr',
    'model-volkswagen-092-kr',
    'model-volkswagen-095-kr'
  )
  and vmy.year = 2026;

delete from public.vehicle_model_years vmy
where vmy.model_id in (
    'model-volkswagen-090-kr',
    'model-volkswagen-091-kr',
    'model-volkswagen-092-kr',
    'model-volkswagen-095-kr'
  )
  and vmy.year = 2026;

with audited_model_ids(id) as (
  values
    ('model-volkswagen-089-kr'),
    ('model-volkswagen-golf-gti-kr'),
    ('model-volkswagen-090-kr'),
    ('model-volkswagen-091-kr'),
    ('model-volkswagen-092-kr'),
    ('model-volkswagen-093-kr'),
    ('model-volkswagen-atlas-kr'),
    ('model-volkswagen-094-id-4'),
    ('model-volkswagen-id5-kr'),
    ('model-volkswagen-095-kr')
)
update public.vehicle_variants vv
set
  trim_name = '공식 제원 검수 대기',
  engine_name = 'Pending official specification review',
  displacement_cc = null,
  battery_kwh = null,
  drivetrain = '검수 대기',
  transmission = '검수 대기',
  official_efficiency = null,
  is_verified = false,
  source_status = 'pending_review',
  source_name = null,
  source_url = null,
  source_file_name = null,
  last_verified_at = null,
  confidence_score = 0.10,
  is_selectable = false,
  is_deprecated = false
from public.vehicle_model_years vmy
join audited_model_ids ami on ami.id = vmy.model_id
where vv.model_year_id = vmy.id
  and (
    vmy.year <> 2026
    or vv.id not in (
      'variant-volkswagen-golf-2026-20-tdi-premium',
      'variant-volkswagen-golf-2026-20-tdi-prestige',
      'variant-volkswagen-golf-gti-2026-20-tsi',
      'variant-volkswagen-touareg-2026-30-tdi-final-prestige',
      'variant-volkswagen-touareg-2026-30-tdi-final-r-line',
      'variant-volkswagen-atlas-2026-20-tsi-7-seat',
      'variant-volkswagen-atlas-2026-20-tsi-6-seat',
      'variant-volkswagen-id4-2026-pro-lite-my25',
      'variant-volkswagen-id4-2026-pro-my25',
      'variant-volkswagen-id5-2026-pro-lite',
      'variant-volkswagen-id5-2026-pro'
    )
  );

delete from public.vehicle_variants vv
using public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in (
    'model-volkswagen-089-kr',
    'model-volkswagen-golf-gti-kr',
    'model-volkswagen-093-kr',
    'model-volkswagen-atlas-kr',
    'model-volkswagen-094-id-4',
    'model-volkswagen-id5-kr'
  )
  and vmy.year = 2026
  and vv.id not in (
    'variant-volkswagen-golf-2026-20-tdi-premium',
    'variant-volkswagen-golf-2026-20-tdi-prestige',
    'variant-volkswagen-golf-gti-2026-20-tsi',
    'variant-volkswagen-touareg-2026-30-tdi-final-prestige',
    'variant-volkswagen-touareg-2026-30-tdi-final-r-line',
    'variant-volkswagen-atlas-2026-20-tsi-7-seat',
    'variant-volkswagen-atlas-2026-20-tsi-6-seat',
    'variant-volkswagen-id4-2026-pro-lite-my25',
    'variant-volkswagen-id4-2026-pro-my25',
    'variant-volkswagen-id5-2026-pro-lite',
    'variant-volkswagen-id5-2026-pro'
  );

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
  source_name,
  source_url,
  last_verified_at,
  confidence_score,
  is_selectable,
  is_deprecated,
  sort_order
)
values
  ('variant-volkswagen-golf-2026-20-tdi-premium', 'year-volkswagen-089-kr-2026', 'generation-volkswagen-golf-official-lineup', 'The Golf 2.0 TDI Premium', '2.0 TDI', '디젤', 1968, null, 'FWD', '7단 DSG', 17.3, 'km/L', '준중형', 'diesel', true, 'verified_official', 'Volkswagen Korea official Golf price list', 'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/2025-golf/leaflet/The%20Golf_Price%20List_251230_web.pdf', '2026-06-13', 0.90, true, false, 10),
  ('variant-volkswagen-golf-2026-20-tdi-prestige', 'year-volkswagen-089-kr-2026', 'generation-volkswagen-golf-official-lineup', 'The Golf 2.0 TDI Prestige', '2.0 TDI', '디젤', 1968, null, 'FWD', '7단 DSG', 17.3, 'km/L', '준중형', 'diesel', true, 'verified_official', 'Volkswagen Korea official Golf price list', 'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/2025-golf/leaflet/The%20Golf_Price%20List_251230_web.pdf', '2026-06-13', 0.90, true, false, 20),
  ('variant-volkswagen-golf-gti-2026-20-tsi', 'year-volkswagen-golf-gti-kr-2026', 'generation-volkswagen-golf-gti-official-lineup', 'Golf GTI', '2.0 TSI', '가솔린', 1984, null, 'FWD', '7단 DSG', 10.8, 'km/L', '스포츠', 'gasoline', true, 'verified_official', 'Volkswagen Korea official Golf GTI price list', 'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/2025-gti/leaflet/Golf%20GTI_Price%20List_260121_web.pdf', '2026-06-13', 0.90, true, false, 10),
  ('variant-volkswagen-touareg-2026-30-tdi-final-prestige', 'year-volkswagen-093-kr-2026', 'generation-volkswagen-touareg-official-lineup', 'Touareg 3.0 TDI FINAL EDITION Prestige', '3.0 TDI V6', '디젤', 2967, null, '4WD', '8단 자동', 10.8, 'km/L', '대형 SUV', 'diesel', true, 'verified_official', 'Volkswagen Korea official Touareg FINAL EDITION price list', 'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/touareg_final-edition/The%20new%20Touareg_Price%20List_260414_web.pdf', '2026-06-13', 0.90, true, false, 10),
  ('variant-volkswagen-touareg-2026-30-tdi-final-r-line', 'year-volkswagen-093-kr-2026', 'generation-volkswagen-touareg-official-lineup', 'Touareg 3.0 TDI FINAL EDITION R-Line', '3.0 TDI V6', '디젤', 2967, null, '4WD', '8단 자동', 10.8, 'km/L', '대형 SUV', 'diesel', true, 'verified_official', 'Volkswagen Korea official Touareg FINAL EDITION price list', 'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/touareg_final-edition/The%20new%20Touareg_Price%20List_260414_web.pdf', '2026-06-13', 0.90, true, false, 20),
  ('variant-volkswagen-atlas-2026-20-tsi-7-seat', 'year-volkswagen-atlas-kr-2026', 'generation-volkswagen-atlas-official-lineup', 'Atlas 2.0 TSI 7인승', '2.0 TSI', '가솔린', 1984, null, 'AWD', '8단 자동', 8.5, 'km/L', '대형 SUV', 'gasoline', true, 'verified_official', 'Volkswagen Korea official Atlas price list', 'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/atlas/leaflet/Atlas_Price%20List_260209.pdf', '2026-06-13', 0.90, true, false, 10),
  ('variant-volkswagen-atlas-2026-20-tsi-6-seat', 'year-volkswagen-atlas-kr-2026', 'generation-volkswagen-atlas-official-lineup', 'Atlas 2.0 TSI 6인승', '2.0 TSI', '가솔린', 1984, null, 'AWD', '8단 자동', 8.5, 'km/L', '대형 SUV', 'gasoline', true, 'verified_official', 'Volkswagen Korea official Atlas price list', 'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/atlas/leaflet/Atlas_Price%20List_260209.pdf', '2026-06-13', 0.90, true, false, 20),
  ('variant-volkswagen-id4-2026-pro-lite-my25', 'year-volkswagen-094-id-4-2026', 'generation-volkswagen-id4-official-lineup', 'ID.4 Pro Lite (MY25)', '영구 자석 동기모터', '전기차', null, 82.836, 'RWD', '감속기', 4.9, 'km/kWh', 'SUV', 'electric', true, 'verified_official', 'Volkswagen Korea official ID.4 price list', 'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/id4/leaflet/ID4_Price%20List_260105_web.pdf', '2026-06-13', 0.90, true, false, 10),
  ('variant-volkswagen-id4-2026-pro-my25', 'year-volkswagen-094-id-4-2026', 'generation-volkswagen-id4-official-lineup', 'ID.4 Pro (MY25)', '영구 자석 동기모터', '전기차', null, 82.836, 'RWD', '감속기', 4.9, 'km/kWh', 'SUV', 'electric', true, 'verified_official', 'Volkswagen Korea official ID.4 price list', 'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/id4/leaflet/ID4_Price%20List_260105_web.pdf', '2026-06-13', 0.90, true, false, 20),
  ('variant-volkswagen-id5-2026-pro-lite', 'year-volkswagen-id5-kr-2026', 'generation-volkswagen-id5-official-lineup', 'ID.5 Pro Lite (MY26)', '영구 자석 동기모터', '전기차', null, 82.836, 'RWD', '감속기', 5.2, 'km/kWh', 'SUV', 'electric', true, 'verified_official', 'Volkswagen Korea official ID.5 price list', 'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/id5/leaflet/ID5_Price%20List_260519_web.pdf', '2026-06-13', 0.90, true, false, 10),
  ('variant-volkswagen-id5-2026-pro', 'year-volkswagen-id5-kr-2026', 'generation-volkswagen-id5-official-lineup', 'ID.5 Pro (MY26)', '영구 자석 동기모터', '전기차', null, 82.836, 'RWD', '감속기', 5.2, 'km/kWh', 'SUV', 'electric', true, 'verified_official', 'Volkswagen Korea official ID.5 price list', 'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/id5/leaflet/ID5_Price%20List_260519_web.pdf', '2026-06-13', 0.90, true, false, 20)
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
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  last_verified_at = excluded.last_verified_at,
  confidence_score = excluded.confidence_score,
  is_selectable = excluded.is_selectable,
  is_deprecated = excluded.is_deprecated,
  sort_order = excluded.sort_order;
