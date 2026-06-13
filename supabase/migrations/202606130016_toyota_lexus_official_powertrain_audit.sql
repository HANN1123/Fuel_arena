-- Toyota/Lexus official powertrain audit.
-- Toyota 2026 rows are promoted only where Toyota Korea model pages expose
-- official fuel economy/displacement. Lexus Korea rows are locked pending
-- because the official pages confirm model/displacement, but complete fuel
-- economy/spec audit remains open.

with audited_model_ids(id) as (
  values
    ('model-toyota-096-kr'),
    ('model-toyota-097-kr'),
    ('model-toyota-098-4'),
    ('model-toyota-099-kr'),
    ('model-toyota-100-kr'),
    ('model-toyota-101-kr'),
    ('model-toyota-102-gr86'),
    ('model-toyota-alphard-kr'),
    ('model-lexus-103-es'),
    ('model-lexus-104-ls'),
    ('model-lexus-105-nx'),
    ('model-lexus-106-rx'),
    ('model-lexus-107-ux'),
    ('model-lexus-108-rz'),
    ('model-lexus-lm-kr')
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
  and vmy.year <> 2026;

delete from public.vehicle_variants vv
using public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in (
    'model-toyota-096-kr',
    'model-toyota-097-kr',
    'model-toyota-098-4',
    'model-toyota-099-kr',
    'model-toyota-100-kr',
    'model-toyota-101-kr',
    'model-toyota-102-gr86',
    'model-toyota-alphard-kr',
    'model-lexus-103-es',
    'model-lexus-104-ls',
    'model-lexus-105-nx',
    'model-lexus-106-rx',
    'model-lexus-107-ux',
    'model-lexus-108-rz',
    'model-lexus-lm-kr'
  )
  and vmy.year = 2026
  and vv.id not in (
    'variant-toyota-prius-2026-hev-2wd',
    'variant-toyota-prius-2026-hev-awd',
    'variant-toyota-prius-2026-phev',
    'variant-toyota-camry-2026-hev',
    'variant-toyota-rav4-2026-hev-2wd-xle',
    'variant-toyota-rav4-2026-hev-awd-ltd',
    'variant-toyota-rav4-2026-phev-xse',
    'variant-toyota-highlander-2026-hev-platinum',
    'variant-toyota-sienna-2026-hev-2wd',
    'variant-toyota-sienna-2026-hev-awd',
    'variant-toyota-crown-2026-hev',
    'variant-toyota-crown-2026-dual-boost-hev',
    'variant-toyota-gr86-2026-24-gasoline',
    'variant-toyota-alphard-2026-hev',
    'variant-lexus-es-2026-300h-pending',
    'variant-lexus-ls-2026-500h-pending',
    'variant-lexus-nx-2026-350h-pending',
    'variant-lexus-nx-2026-450h-plus-pending',
    'variant-lexus-rx-2026-350h-pending',
    'variant-lexus-rx-2026-500h-pending',
    'variant-lexus-rx-2026-450h-plus-pending',
    'variant-lexus-ux-2026-300h-2wd-pending',
    'variant-lexus-ux-2026-300h-f-sport-pending',
    'variant-lexus-rz-2026-450e-pending',
    'variant-lexus-lm-2026-500h-pending'
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
  ('variant-toyota-prius-2026-hev-2wd', 'year-toyota-096-kr-2026', 'generation-toyota-prius-official-lineup', 'PRIUS HEV 2WD XLE/LE', '2.0L 하이브리드 시스템', '하이브리드', 1987, null, '2WD', '무단 자동 변속기 (e-CVT)', 20.9, 'km/L', '준중형', 'hybrid', true, 'verified_official', 'Toyota Korea official Prius HEV model page', 'https://www.toyota.co.kr/models/priushev/', '2026-06-13', 0.90, true, false, 10),
  ('variant-toyota-prius-2026-hev-awd', 'year-toyota-096-kr-2026', 'generation-toyota-prius-official-lineup', 'PRIUS HEV AWD XLE', '2.0L 하이브리드 시스템', '하이브리드', 1987, null, 'E-Four AWD', '무단 자동 변속기 (e-CVT)', 20.0, 'km/L', '준중형', 'hybrid', true, 'verified_official', 'Toyota Korea official Prius HEV model page', 'https://www.toyota.co.kr/models/priushev/', '2026-06-13', 0.90, true, false, 20),
  ('variant-toyota-prius-2026-phev', 'year-toyota-096-kr-2026', 'generation-toyota-prius-official-lineup', 'PRIUS PHEV', '2.0L 플러그인 하이브리드 시스템', '플러그인 하이브리드', 1987, 13.6, '공식 제원 확인', '무단 자동 변속기 (e-CVT)', 19.4, 'km/L', '준중형', 'plug_in_hybrid', true, 'verified_official', 'Toyota Korea official Prius PHEV model page', 'https://www.toyota.co.kr/models/priusphev/', '2026-06-13', 0.90, true, false, 30),
  ('variant-toyota-camry-2026-hev', 'year-toyota-097-kr-2026', 'generation-toyota-camry-official-lineup', 'CAMRY HEV', '2.5L 하이브리드 시스템', '하이브리드', 2487, null, '공식 제원 확인', '무단 자동 변속기 (e-CVT)', 17.1, 'km/L', '중형', 'hybrid', true, 'verified_official', 'Toyota Korea official Camry model page', 'https://toyota.co.kr/models/camry/', '2026-06-13', 0.90, true, false, 10),
  ('variant-toyota-rav4-2026-hev-2wd-xle', 'year-toyota-098-4-2026', 'generation-toyota-rav4-official-lineup', 'RAV4 HEV 2WD XLE', '2.5L 다이내믹 포스 하이브리드', '하이브리드', 2487, null, '2WD', '무단 자동 변속기 (e-CVT)', 14.5, 'km/L', 'SUV', 'hybrid', true, 'verified_official', 'Toyota Korea official RAV4 HEV model page', 'https://toyota.co.kr/models/rav4hev/', '2026-06-13', 0.90, true, false, 10),
  ('variant-toyota-rav4-2026-hev-awd-ltd', 'year-toyota-098-4-2026', 'generation-toyota-rav4-official-lineup', 'RAV4 HEV AWD LTD', '2.5L 다이내믹 포스 하이브리드', '하이브리드', 2487, null, 'E-Four AWD', '무단 자동 변속기 (e-CVT)', 14.1, 'km/L', 'SUV', 'hybrid', true, 'verified_official', 'Toyota Korea official RAV4 HEV model page', 'https://toyota.co.kr/models/rav4hev/', '2026-06-13', 0.90, true, false, 20),
  ('variant-toyota-rav4-2026-phev-xse', 'year-toyota-098-4-2026', 'generation-toyota-rav4-official-lineup', 'RAV4 PHEV XSE', '2.5L 플러그인 하이브리드 시스템', '플러그인 하이브리드', 2487, 18.1, '사륜구동', '무단 자동 변속기 (e-CVT)', 15.6, 'km/L', 'SUV', 'plug_in_hybrid', true, 'verified_official', 'Toyota Korea official RAV4 PHEV model page', 'https://toyota.co.kr/models/rav4phev/', '2026-06-13', 0.90, true, false, 30),
  ('variant-toyota-highlander-2026-hev-platinum', 'year-toyota-099-kr-2026', 'generation-toyota-highlander-official-lineup', 'HIGHLANDER 2.5 HEV PLATINUM', '2.5L 하이브리드 파워트레인', '하이브리드', 2487, null, 'E-Four AWD', '무단 자동 변속기 (e-CVT)', 13.8, 'km/L', '대형 SUV', 'hybrid', true, 'verified_official', 'Toyota Korea official Highlander model page', 'https://toyota.co.kr/models/highlander/', '2026-06-13', 0.90, true, false, 10),
  ('variant-toyota-sienna-2026-hev-2wd', 'year-toyota-100-kr-2026', 'generation-toyota-sienna-official-lineup', 'SIENNA HEV 2WD', '2.5L 다이내믹 포스 하이브리드', '하이브리드', 2487, null, '2WD', '무단 자동 변속기 (e-CVT)', 14.5, 'km/L', 'MPV', 'hybrid', true, 'verified_official', 'Toyota Korea official Sienna model page', 'https://toyota.co.kr/models/sienna/', '2026-06-13', 0.90, true, false, 10),
  ('variant-toyota-sienna-2026-hev-awd', 'year-toyota-100-kr-2026', 'generation-toyota-sienna-official-lineup', 'SIENNA HEV AWD', '2.5L 다이내믹 포스 하이브리드', '하이브리드', 2487, null, 'E-Four AWD', '무단 자동 변속기 (e-CVT)', 13.7, 'km/L', 'MPV', 'hybrid', true, 'verified_official', 'Toyota Korea official Sienna model page', 'https://toyota.co.kr/models/sienna/', '2026-06-13', 0.90, true, false, 20),
  ('variant-toyota-crown-2026-hev', 'year-toyota-101-kr-2026', 'generation-toyota-crown-official-lineup', 'CROWN HEV', '2.5L 자연흡기 가솔린 하이브리드', '하이브리드', 2487, null, '공식 제원 확인', '무단 자동 변속기 (e-CVT)', 17.2, 'km/L', '대형', 'hybrid', true, 'verified_official', 'Toyota Korea official Crown model page', 'https://toyota.co.kr/models/crown/', '2026-06-13', 0.90, true, false, 10),
  ('variant-toyota-crown-2026-dual-boost-hev', 'year-toyota-101-kr-2026', 'generation-toyota-crown-official-lineup', 'CROWN Dual Boost HEV', '2.4L 가솔린 터보 하이브리드', '하이브리드', 2393, null, 'E-Four Advanced AWD', '무단 자동 변속기 (e-CVT)', 11.0, 'km/L', '대형', 'hybrid', true, 'verified_official', 'Toyota Korea official Crown model page', 'https://toyota.co.kr/models/crown/', '2026-06-13', 0.90, true, false, 20),
  ('variant-toyota-gr86-2026-24-gasoline', 'year-toyota-102-gr86-2026', 'generation-toyota-gr86-official-lineup', 'GR86 2.4 가솔린', '2.4L 수평대향 가솔린 엔진', '가솔린', 2387, null, '공식 제원 확인', '공식 제원 확인', 9.5, 'km/L', '준중형', 'gasoline', true, 'verified_official', 'Toyota Korea official GR86 model page', 'https://toyota.co.kr/models/gr86/', '2026-06-13', 0.90, true, false, 10),
  ('variant-toyota-alphard-2026-hev', 'year-toyota-alphard-kr-2026', 'generation-toyota-alphard-official-lineup', 'ALPHARD HEV', '2.5L 하이브리드 시스템', '하이브리드', 2487, null, 'E-Four AWD', '무단 자동 변속기 (e-CVT)', 13.5, 'km/L', 'MPV', 'hybrid', true, 'verified_official', 'Toyota Korea official Alphard model page', 'https://toyota.co.kr/models/alphard/', '2026-06-13', 0.90, true, false, 10),
  ('variant-lexus-es-2026-300h-pending', 'year-lexus-103-es-2026', 'generation-lexus-es-official-lineup', 'ES 300h 공식 제원 검수 대기', 'ES 300h hybrid official specification review pending', '하이브리드', 2487, null, '검수 대기', '검수 대기', null, 'km/L', '대형', 'hybrid', false, 'pending_review', 'Lexus Korea official electrified/model page', 'https://www.lexus.co.kr/models/ES-300h/', '2026-06-13', 0.62, false, false, 10),
  ('variant-lexus-ls-2026-500h-pending', 'year-lexus-104-ls-2026', 'generation-lexus-ls-official-lineup', 'LS 500h 공식 제원 검수 대기', 'LS 500h hybrid official specification review pending', '하이브리드', 3456, null, '검수 대기', '검수 대기', null, 'km/L', '대형', 'hybrid', false, 'pending_review', 'Lexus Korea official electrified/model page', 'https://www.lexus.co.kr/models/LS-500h/', '2026-06-13', 0.62, false, false, 10),
  ('variant-lexus-nx-2026-350h-pending', 'year-lexus-105-nx-2026', 'generation-lexus-nx-official-lineup', 'NX 350h 공식 제원 검수 대기', 'NX 350h hybrid official specification review pending', '하이브리드', 2487, null, '검수 대기', '검수 대기', null, 'km/L', 'SUV', 'hybrid', false, 'pending_review', 'Lexus Korea official electrified/model page', 'https://www.lexus.co.kr/models/NX-350h/', '2026-06-13', 0.62, false, false, 10),
  ('variant-lexus-nx-2026-450h-plus-pending', 'year-lexus-105-nx-2026', 'generation-lexus-nx-official-lineup', 'NX 450h+ 공식 제원 검수 대기', 'NX 450h+ plug-in hybrid official specification review pending', '플러그인 하이브리드', 2487, null, '검수 대기', '검수 대기', null, 'km/L', 'SUV', 'plug_in_hybrid', false, 'pending_review', 'Lexus Korea official electrified/model page', 'https://www.lexus.co.kr/models/NX-450h-plus/', '2026-06-13', 0.62, false, false, 20),
  ('variant-lexus-rx-2026-350h-pending', 'year-lexus-106-rx-2026', 'generation-lexus-rx-official-lineup', 'RX 350h 공식 제원 검수 대기', 'RX 350h hybrid official specification review pending', '하이브리드', 2487, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'hybrid', false, 'pending_review', 'Lexus Korea official electrified/model page', 'https://www.lexus.co.kr/models/RX-350h/', '2026-06-13', 0.62, false, false, 10),
  ('variant-lexus-rx-2026-500h-pending', 'year-lexus-106-rx-2026', 'generation-lexus-rx-official-lineup', 'RX 500h 공식 제원 검수 대기', 'RX 500h hybrid official specification review pending', '하이브리드', 2393, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'hybrid', false, 'pending_review', 'Lexus Korea official electrified/model page', 'https://www.lexus.co.kr/models/RX-500h/', '2026-06-13', 0.62, false, false, 20),
  ('variant-lexus-rx-2026-450h-plus-pending', 'year-lexus-106-rx-2026', 'generation-lexus-rx-official-lineup', 'RX 450h+ 공식 제원 검수 대기', 'RX 450h+ plug-in hybrid official specification review pending', '플러그인 하이브리드', 2487, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'plug_in_hybrid', false, 'pending_review', 'Lexus Korea official electrified/model page', 'https://www.lexus.co.kr/models/RX-450h-plus/', '2026-06-13', 0.62, false, false, 30),
  ('variant-lexus-ux-2026-300h-2wd-pending', 'year-lexus-107-ux-2026', 'generation-lexus-ux-official-lineup', 'UX 300h 2WD 공식 제원 검수 대기', 'UX 300h hybrid official specification review pending', '하이브리드', 1987, null, '검수 대기', '검수 대기', null, 'km/L', '소형 SUV', 'hybrid', false, 'pending_review', 'Lexus Korea official electrified/model page', 'https://www.lexus.co.kr/models/UX-300h/', '2026-06-13', 0.62, false, false, 10),
  ('variant-lexus-ux-2026-300h-f-sport-pending', 'year-lexus-107-ux-2026', 'generation-lexus-ux-official-lineup', 'UX 300h F SPORT 공식 제원 검수 대기', 'UX 300h hybrid official specification review pending', '하이브리드', 1987, null, '검수 대기', '검수 대기', null, 'km/L', '소형 SUV', 'hybrid', false, 'pending_review', 'Lexus Korea official electrified/model page', 'https://www.lexus.co.kr/models/UX-300h/', '2026-06-13', 0.62, false, false, 20),
  ('variant-lexus-rz-2026-450e-pending', 'year-lexus-108-rz-2026', 'generation-lexus-rz-official-lineup', 'RZ 450e 공식 제원 검수 대기', 'RZ 450e electric official specification review pending', '전기차', null, null, '검수 대기', '검수 대기', null, 'km/kWh', 'SUV', 'electric', false, 'pending_review', 'Lexus Korea official electrified/model page', 'https://www.lexus.co.kr/models/RZ-450e/', '2026-06-13', 0.62, false, false, 10),
  ('variant-lexus-lm-2026-500h-pending', 'year-lexus-lm-kr-2026', 'generation-lexus-lm-official-lineup', 'LM 500h 공식 제원 검수 대기', 'LM 500h hybrid official specification review pending', '하이브리드', 2393, null, '검수 대기', '검수 대기', null, 'km/L', 'MPV', 'hybrid', false, 'pending_review', 'Lexus Korea official electrified/model page', 'https://www.lexus.co.kr/models/LM-500h/', '2026-06-13', 0.62, false, false, 10)
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
