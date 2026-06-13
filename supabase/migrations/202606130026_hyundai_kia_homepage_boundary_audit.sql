-- Hyundai/Kia official-homepage boundary audit.
-- Official Korea pages confirm model/category boundaries, but generated
-- unverified powertrain rows must not expose invented engine/efficiency specs.
-- Preserve rows that already have verified official/admin sources.

with audited_model_ids(id, source_name, source_url) as (
  values
    ('model-hyundai-001-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-002-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-003-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-004-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-005-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-006-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-007-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-008-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-009-5', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-010-6', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-011-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-012-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-avante-n-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-avante-sport-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-venue-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-casper-electric-kr', 'Hyundai Casper official electric model boundary audit', 'https://casper.hyundai.com/vehicles/electric/highlight'),
    ('model-hyundai-ioniq5-n-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-ioniq6-n-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-ioniq9-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-nexo-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-staria-electric-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-hyundai-st1-kr', 'Hyundai Motor Korea official vehicle lineup boundary audit', 'https://www.hyundai.com/kr/ko/e/all-vehicles'),
    ('model-kia-013-k3', 'Kia Korea official vehicle/category boundary audit', 'https://www.kia.com/kr/vehicles/catalog-price'),
    ('model-kia-014-k5', 'Kia Korea official sedan category boundary audit', 'https://www.kia.com/kr/vehicles/sedan'),
    ('model-kia-015-k8', 'Kia Korea official sedan/category boundary audit', 'https://www.kia.com/kr/vehicles/sedan'),
    ('model-kia-016-k9', 'Kia Korea official sedan/category boundary audit', 'https://www.kia.com/kr/vehicles/sedan'),
    ('model-kia-017-kr', 'Kia Korea official sedan/category boundary audit', 'https://www.kia.com/kr/vehicles/sedan'),
    ('model-kia-018-kr', 'Kia Korea official sedan/category boundary audit', 'https://www.kia.com/kr/vehicles/sedan'),
    ('model-kia-019-kr', 'Kia Korea official RV category boundary audit', 'https://www.kia.com/kr/vehicles/rv'),
    ('model-kia-020-kr', 'Kia Korea official RV category boundary audit', 'https://www.kia.com/kr/vehicles/rv'),
    ('model-kia-021-kr', 'Kia Korea official RV category boundary audit', 'https://www.kia.com/kr/vehicles/rv'),
    ('model-kia-022-kr', 'Kia Korea official RV category boundary audit', 'https://www.kia.com/kr/vehicles/rv'),
    ('model-kia-023-kr', 'Kia Korea official RV category boundary audit', 'https://www.kia.com/kr/vehicles/rv'),
    ('model-kia-024-ev3', 'Kia Korea official EV category boundary audit', 'https://www.kia.com/kr/vehicles/ev'),
    ('model-kia-025-ev6', 'Kia Korea official EV category boundary audit', 'https://www.kia.com/kr/vehicles/ev'),
    ('model-kia-026-ev9', 'Kia Korea official EV category boundary audit', 'https://www.kia.com/kr/vehicles/ev'),
    ('model-kia-027-kr', 'Kia Korea official commercial category boundary audit', 'https://www.kia.com/kr/vehicles/commercial'),
    ('model-kia-ev4-kr', 'Kia Korea official EV category boundary audit', 'https://www.kia.com/kr/vehicles/ev'),
    ('model-kia-ev5-kr', 'Kia Korea official EV category boundary audit', 'https://www.kia.com/kr/vehicles/ev'),
    ('model-kia-pv5-kr', 'Kia Korea official PBV/EV lineup boundary audit', 'https://www.kia.com/kr/vehicles/kia-ev/vehicles/ev-line-up'),
    ('model-kia-tasman-kr', 'Kia Korea official RV category boundary audit', 'https://www.kia.com/kr/vehicles/rv')
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
  source_name = ami.source_name,
  source_url = ami.source_url,
  source_file_name = null,
  last_verified_at = '2026-06-13',
  confidence_score = 0.10,
  is_selectable = false,
  is_deprecated = false
from public.vehicle_model_years vmy
join audited_model_ids ami on ami.id = vmy.model_id
where vv.model_year_id = vmy.id
  and coalesce(vv.source_status, 'unverified') not in (
    'verified_official',
    'verified_admin'
  );

update public.vehicle_variants
set
  trim_name = '1.6 가솔린',
  engine_name = 'Smartstream G1.6',
  displacement_cc = 1598,
  battery_kwh = null,
  drivetrain = 'FWD',
  transmission = 'IVT',
  official_efficiency = 15.0,
  efficiency_unit = 'km/L',
  vehicle_class = '준중형',
  fuel_league = 'gasoline',
  is_verified = true,
  source_status = 'verified_official',
  source_name = 'Hyundai Motor Korea official Avante price PDF',
  source_url = 'https://www.hyundai.com/contents/repn-car/catalog/the-new-avante-price.pdf',
  source_file_name = 'the-new-avante-price.pdf',
  last_verified_at = '2026-06-13',
  confidence_score = 0.90,
  is_selectable = true,
  is_deprecated = false
where id = 'variant-hyundai-avante-2024-gasoline';

update public.vehicle_variants
set
  trim_name = '1.6 가솔린',
  engine_name = 'Gamma 1.6 GDI',
  displacement_cc = 1591,
  battery_kwh = null,
  drivetrain = 'FWD',
  transmission = '자동 6단',
  official_efficiency = 14.3,
  efficiency_unit = 'km/L',
  vehicle_class = '준중형',
  fuel_league = 'gasoline',
  is_verified = false,
  source_status = 'pending_review',
  source_name = 'Kia K3 split powertrain pending source audit',
  source_url = null,
  source_file_name = null,
  last_verified_at = '2026-06-13',
  confidence_score = 0.10,
  is_selectable = false,
  is_deprecated = false
where id in (
  'variant-kia-k3-2015-16-gdi-6at',
  'variant-kia-k3-2016-16-gdi-6at',
  'variant-kia-k3-2017-16-gdi-6at'
);

update public.vehicle_variants
set
  trim_name = '1.6 디젤',
  engine_name = 'U2 1.6 VGT 디젤',
  displacement_cc = 1582,
  battery_kwh = null,
  drivetrain = 'FWD',
  transmission = '7단 DCT ISG',
  official_efficiency = 19.1,
  efficiency_unit = 'km/L',
  vehicle_class = '준중형',
  fuel_league = 'diesel',
  is_verified = false,
  source_status = 'pending_review',
  source_name = 'Kia K3 split powertrain pending source audit',
  source_url = null,
  source_file_name = null,
  last_verified_at = '2026-06-13',
  confidence_score = 0.10,
  is_selectable = false,
  is_deprecated = false
where id in (
  'variant-kia-k3-2016-16-diesel-7dct',
  'variant-kia-k3-2017-16-diesel-7dct'
);

update public.vehicle_variants
set
  trim_name = '1.6 가솔린',
  engine_name = 'Smartstream G1.6',
  displacement_cc = 1598,
  battery_kwh = null,
  drivetrain = 'FWD',
  transmission = 'IVT',
  official_efficiency = 15.2,
  efficiency_unit = 'km/L',
  vehicle_class = '준중형',
  fuel_league = 'gasoline',
  is_verified = false,
  source_status = 'pending_review',
  source_name = 'Kia K3 split powertrain pending source audit',
  source_url = null,
  source_file_name = null,
  last_verified_at = '2026-06-13',
  confidence_score = 0.10,
  is_selectable = false,
  is_deprecated = false
where id in (
  'variant-kia-k3-2018-16-ivt',
  'variant-kia-k3-2019-16-ivt',
  'variant-kia-k3-2020-16-ivt',
  'variant-kia-k3-2021-16-ivt',
  'variant-kia-k3-2022-16-ivt',
  'variant-kia-k3-2023-16-ivt'
);

update public.vehicle_variants
set
  trim_name = 'K3 GT 1.6T 가솔린 수동',
  engine_name = 'Gamma 1.6 T-GDi',
  displacement_cc = 1591,
  battery_kwh = null,
  drivetrain = 'FWD',
  transmission = '수동 6단',
  official_efficiency = 12.2,
  efficiency_unit = 'km/L',
  vehicle_class = '스포츠',
  fuel_league = 'gasoline',
  is_verified = false,
  source_status = 'pending_review',
  source_name = 'Kia K3 GT split powertrain pending source audit',
  source_url = null,
  source_file_name = null,
  last_verified_at = '2026-06-13',
  confidence_score = 0.10,
  is_selectable = false,
  is_deprecated = false
where id in (
  'variant-kia-k3-gt-2018-16t-6mt',
  'variant-kia-k3-gt-2019-16t-6mt',
  'variant-kia-k3-gt-2020-16t-6mt'
);

update public.vehicle_variants
set
  trim_name = 'K3 GT 1.6T 가솔린 DCT',
  engine_name = 'Gamma 1.6 T-GDi',
  displacement_cc = 1591,
  battery_kwh = null,
  drivetrain = 'FWD',
  transmission = '7단 DCT',
  official_efficiency = case
    when id in (
      'variant-kia-k3-gt-2018-16t-7dct',
      'variant-kia-k3-gt-2019-16t-7dct',
      'variant-kia-k3-gt-2020-16t-7dct'
    ) then 12.2
    else 12.1
  end,
  efficiency_unit = 'km/L',
  vehicle_class = '스포츠',
  fuel_league = 'gasoline',
  is_verified = false,
  source_status = 'pending_review',
  source_name = 'Kia K3 GT split powertrain pending source audit',
  source_url = null,
  source_file_name = null,
  last_verified_at = '2026-06-13',
  confidence_score = 0.10,
  is_selectable = false,
  is_deprecated = false
where id in (
  'variant-kia-k3-gt-2018-16t-7dct',
  'variant-kia-k3-gt-2019-16t-7dct',
  'variant-kia-k3-gt-2020-16t-7dct',
  'variant-kia-k3-gt-2021-16t-7dct',
  'variant-kia-k3-gt-2022-16t-7dct',
  'variant-kia-k3-gt-2023-16t-7dct'
);

with audited_model_ids(id) as (
  values
    ('model-hyundai-001-kr'), ('model-hyundai-002-kr'),
    ('model-hyundai-003-kr'), ('model-hyundai-004-kr'),
    ('model-hyundai-005-kr'), ('model-hyundai-006-kr'),
    ('model-hyundai-007-kr'), ('model-hyundai-008-kr'),
    ('model-hyundai-009-5'), ('model-hyundai-010-6'),
    ('model-hyundai-011-kr'), ('model-hyundai-012-kr'),
    ('model-hyundai-avante-n-kr'), ('model-hyundai-avante-sport-kr'),
    ('model-hyundai-venue-kr'), ('model-hyundai-casper-electric-kr'),
    ('model-hyundai-ioniq5-n-kr'), ('model-hyundai-ioniq6-n-kr'),
    ('model-hyundai-ioniq9-kr'), ('model-hyundai-nexo-kr'),
    ('model-hyundai-staria-electric-kr'), ('model-hyundai-st1-kr'),
    ('model-kia-013-k3'), ('model-kia-014-k5'),
    ('model-kia-015-k8'), ('model-kia-016-k9'),
    ('model-kia-017-kr'), ('model-kia-018-kr'),
    ('model-kia-019-kr'), ('model-kia-020-kr'),
    ('model-kia-021-kr'), ('model-kia-022-kr'),
    ('model-kia-023-kr'), ('model-kia-024-ev3'),
    ('model-kia-025-ev6'), ('model-kia-026-ev9'),
    ('model-kia-027-kr'), ('model-kia-ev4-kr'),
    ('model-kia-ev5-kr'), ('model-kia-pv5-kr'),
    ('model-kia-tasman-kr')
)
delete from public.vehicle_powertrain_sources vps
using public.vehicle_variants vv,
  public.vehicle_model_years vmy,
  audited_model_ids ami
where vps.powertrain_id = vv.id
  and vv.model_year_id = vmy.id
  and vmy.model_id = ami.id
  and coalesce(vv.source_status, 'unverified') not in (
    'verified_official',
    'verified_admin'
  );
