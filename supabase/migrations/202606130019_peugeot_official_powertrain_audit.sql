-- Peugeot Korea official 2026 SMART HYBRID powertrain audit.
-- Current official model lineup: 5008, 3008, 408, 308 SMART HYBRID.
-- 208/2008 are not present in the current official model list, so 2026
-- placeholder rows stay out of the selectable catalog.

with current_model_fuels (id, fuels) as (
  values
    ('model-peugeot-145-308', '{"하이브리드"}'::text[]),
    ('model-peugeot-147-3008', '{"하이브리드"}'::text[]),
    ('model-peugeot-148-5008', '{"하이브리드"}'::text[]),
    ('model-peugeot-408-kr', '{"하이브리드"}'::text[])
)
update public.vehicle_models vm
set available_fuel_types = cmf.fuels
from current_model_fuels cmf
where vm.id = cmf.id;

with retired_generation_updates (
  id,
  display_period
) as (
  values
    ('generation-peugeot-208-official-lineup', '2015~2025'),
    ('generation-peugeot-2008-official-lineup', '2015~2025')
)
update public.vehicle_generations vg
set
  display_period = rgu.display_period,
  end_year = 2025,
  is_current = false,
  is_selectable = false,
  source_status = 'pending_review',
  confidence_score = least(coalesce(vg.confidence_score, 0.50), 0.50),
  updated_at = now()
from retired_generation_updates rgu
where vg.id = rgu.id;

with current_generation_sources (
  id,
  source_name,
  source_url
) as (
  values
    ('generation-peugeot-308-official-lineup', 'Peugeot Korea official 308 SMART HYBRID model page', 'https://www.epeugeot.co.kr/new-cars/308hybrid.html'),
    ('generation-peugeot-3008-official-lineup', 'Peugeot Korea official 3008 SMART HYBRID model page', 'https://www.epeugeot.co.kr/new-cars/3008hybrid.html'),
    ('generation-peugeot-5008-official-lineup', 'Peugeot Korea official 5008 SMART HYBRID model page', 'https://www.epeugeot.co.kr/new-cars/5008hybrid.html'),
    ('generation-peugeot-408-official-lineup', 'Peugeot Korea official 408 SMART HYBRID model page', 'https://www.epeugeot.co.kr/new-cars/408hybrid.html')
)
update public.vehicle_generations vg
set
  start_year = 2026,
  end_year = null,
  display_period = '2026~현재',
  is_current = true,
  is_selectable = true,
  source_status = 'pending_review',
  source_name = cgs.source_name,
  source_url = cgs.source_url,
  last_verified_at = '2026-06-13',
  confidence_score = 0.72,
  updated_at = now()
from current_generation_sources cgs
where vg.id = cgs.id;

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and (
    (
      vmy.model_id in ('model-peugeot-144-208', 'model-peugeot-146-2008')
      and vmy.year = 2026
    )
    or (
      vmy.model_id in (
        'model-peugeot-145-308',
        'model-peugeot-147-3008',
        'model-peugeot-148-5008',
        'model-peugeot-408-kr'
      )
      and vmy.year <> 2026
    )
  );

delete from public.vehicle_variants vv
using public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and (
    (
      vmy.model_id in ('model-peugeot-144-208', 'model-peugeot-146-2008')
      and vmy.year = 2026
    )
    or (
      vmy.model_id in (
        'model-peugeot-145-308',
        'model-peugeot-147-3008',
        'model-peugeot-148-5008',
        'model-peugeot-408-kr'
      )
      and (
        vmy.year <> 2026
        or vv.id not in (
          'variant-peugeot-308-2026-smart-hybrid-allure',
          'variant-peugeot-308-2026-smart-hybrid-gt',
          'variant-peugeot-3008-2026-smart-hybrid-allure',
          'variant-peugeot-3008-2026-smart-hybrid-gt',
          'variant-peugeot-5008-2026-smart-hybrid-allure',
          'variant-peugeot-5008-2026-smart-hybrid-gt',
          'variant-peugeot-408-2026-smart-hybrid-allure',
          'variant-peugeot-408-2026-smart-hybrid-gt'
        )
      )
    )
  );

delete from public.vehicle_model_years vmy
where (
    vmy.model_id in ('model-peugeot-144-208', 'model-peugeot-146-2008')
    and vmy.year = 2026
  )
  or (
    vmy.model_id in (
      'model-peugeot-145-308',
      'model-peugeot-147-3008',
      'model-peugeot-148-5008',
      'model-peugeot-408-kr'
    )
    and vmy.year <> 2026
  );

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
where vv.model_year_id = vmy.id
  and vmy.model_id in ('model-peugeot-144-208', 'model-peugeot-146-2008');

insert into public.vehicle_model_years (
  id,
  model_id,
  year,
  generation_id,
  production_year_label
)
values
  ('year-peugeot-145-308-2026', 'model-peugeot-145-308', 2026, 'generation-peugeot-308-official-lineup', '2026~현재'),
  ('year-peugeot-147-3008-2026', 'model-peugeot-147-3008', 2026, 'generation-peugeot-3008-official-lineup', '2026~현재'),
  ('year-peugeot-148-5008-2026', 'model-peugeot-148-5008', 2026, 'generation-peugeot-5008-official-lineup', '2026~현재'),
  ('year-peugeot-408-kr-2026', 'model-peugeot-408-kr', 2026, 'generation-peugeot-408-official-lineup', '2026~현재')
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
values
  ('generation-peugeot-308-official-lineup', 'year-peugeot-145-308-2026', 2026),
  ('generation-peugeot-3008-official-lineup', 'year-peugeot-147-3008-2026', 2026),
  ('generation-peugeot-5008-official-lineup', 'year-peugeot-148-5008-2026', 2026),
  ('generation-peugeot-408-official-lineup', 'year-peugeot-408-kr-2026', 2026)
on conflict (generation_id, model_year_id) do nothing;

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
  ('variant-peugeot-308-2026-smart-hybrid-allure', 'year-peugeot-145-308-2026', 'generation-peugeot-308-official-lineup', '308 SMART HYBRID Allure', '1.2L PureTech Smart Hybrid', '하이브리드', 1199, null, 'FWD', '6단 듀얼 클러치 자동변속기(e-DCS6)', 15.2, 'km/L', '준중형', 'hybrid', true, 'verified_official', 'Peugeot Korea official 308 SMART HYBRID model page', 'https://www.epeugeot.co.kr/new-cars/308hybrid.html', '2026-06-13', 0.90, true, false, 10),
  ('variant-peugeot-308-2026-smart-hybrid-gt', 'year-peugeot-145-308-2026', 'generation-peugeot-308-official-lineup', '308 SMART HYBRID GT', '1.2L PureTech Smart Hybrid', '하이브리드', 1199, null, 'FWD', '6단 듀얼 클러치 자동변속기(e-DCS6)', 15.2, 'km/L', '준중형', 'hybrid', true, 'verified_official', 'Peugeot Korea official 308 SMART HYBRID model page', 'https://www.epeugeot.co.kr/new-cars/308hybrid.html', '2026-06-13', 0.90, true, false, 20),
  ('variant-peugeot-3008-2026-smart-hybrid-allure', 'year-peugeot-147-3008-2026', 'generation-peugeot-3008-official-lineup', '3008 SMART HYBRID Allure', '1.2L PureTech Smart Hybrid', '하이브리드', 1199, null, 'FWD', '6단 듀얼 클러치 자동변속기(e-DCS6)', 14.6, 'km/L', 'SUV', 'hybrid', true, 'verified_official', 'Peugeot Korea official 3008 SMART HYBRID model page', 'https://www.epeugeot.co.kr/new-cars/3008hybrid.html', '2026-06-13', 0.90, true, false, 10),
  ('variant-peugeot-3008-2026-smart-hybrid-gt', 'year-peugeot-147-3008-2026', 'generation-peugeot-3008-official-lineup', '3008 SMART HYBRID GT', '1.2L PureTech Smart Hybrid', '하이브리드', 1199, null, 'FWD', '6단 듀얼 클러치 자동변속기(e-DCS6)', 14.6, 'km/L', 'SUV', 'hybrid', true, 'verified_official', 'Peugeot Korea official 3008 SMART HYBRID model page', 'https://www.epeugeot.co.kr/new-cars/3008hybrid.html', '2026-06-13', 0.90, true, false, 20),
  ('variant-peugeot-5008-2026-smart-hybrid-allure', 'year-peugeot-148-5008-2026', 'generation-peugeot-5008-official-lineup', '5008 SMART HYBRID Allure', '1.2L PureTech Smart Hybrid', '하이브리드', 1199, null, 'FWD', '6단 듀얼 클러치 자동변속기(e-DCS6)', 13.3, 'km/L', '대형 SUV', 'hybrid', true, 'verified_official', 'Peugeot Korea official 5008 SMART HYBRID model page', 'https://www.epeugeot.co.kr/new-cars/5008hybrid.html', '2026-06-13', 0.90, true, false, 10),
  ('variant-peugeot-5008-2026-smart-hybrid-gt', 'year-peugeot-148-5008-2026', 'generation-peugeot-5008-official-lineup', '5008 SMART HYBRID GT', '1.2L PureTech Smart Hybrid', '하이브리드', 1199, null, 'FWD', '6단 듀얼 클러치 자동변속기(e-DCS6)', 13.3, 'km/L', '대형 SUV', 'hybrid', true, 'verified_official', 'Peugeot Korea official 5008 SMART HYBRID model page', 'https://www.epeugeot.co.kr/new-cars/5008hybrid.html', '2026-06-13', 0.90, true, false, 20),
  ('variant-peugeot-408-2026-smart-hybrid-allure', 'year-peugeot-408-kr-2026', 'generation-peugeot-408-official-lineup', '408 SMART HYBRID Allure', '1.2L PureTech Smart Hybrid', '하이브리드', 1199, null, 'FWD', '6단 듀얼 클러치 자동변속기(e-DCS6)', 14.1, 'km/L', '중형', 'hybrid', true, 'verified_official', 'Peugeot Korea official 408 SMART HYBRID model page', 'https://www.epeugeot.co.kr/new-cars/408hybrid.html', '2026-06-13', 0.90, true, false, 10),
  ('variant-peugeot-408-2026-smart-hybrid-gt', 'year-peugeot-408-kr-2026', 'generation-peugeot-408-official-lineup', '408 SMART HYBRID GT', '1.2L PureTech Smart Hybrid', '하이브리드', 1199, null, 'FWD', '6단 듀얼 클러치 자동변속기(e-DCS6)', 14.1, 'km/L', '중형', 'hybrid', true, 'verified_official', 'Peugeot Korea official 408 SMART HYBRID model page', 'https://www.epeugeot.co.kr/new-cars/408hybrid.html', '2026-06-13', 0.90, true, false, 20)
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
