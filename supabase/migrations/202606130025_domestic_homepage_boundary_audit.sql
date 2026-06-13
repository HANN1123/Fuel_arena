-- Domestic manufacturer official-homepage boundary audit.
-- Genesis, Chevrolet, Renault Korea, and KGM pages confirm model-lineup
-- boundaries. Their generated powertrain placeholders remain pending until
-- model-year specific official economy/spec sheets are audited row by row.

with audited_model_ids(id, source_name, source_url) as (
  values
    ('model-genesis-028-g70', 'Genesis Korea official download center boundary audit', 'https://www.genesis.com/kr/ko/support/download-center/genesis-models.html'),
    ('model-genesis-g70-shooting-brake-kr', 'Genesis Korea official download center boundary audit', 'https://www.genesis.com/kr/ko/support/download-center/genesis-models.html'),
    ('model-genesis-029-g80', 'Genesis Korea official download center boundary audit', 'https://www.genesis.com/kr/ko/support/download-center/genesis-models.html'),
    ('model-genesis-electrified-g80-kr', 'Genesis Korea official download center boundary audit', 'https://www.genesis.com/kr/ko/support/download-center/genesis-models.html'),
    ('model-genesis-030-g90', 'Genesis Korea official download center boundary audit', 'https://www.genesis.com/kr/ko/support/download-center/genesis-models.html'),
    ('model-genesis-031-gv60', 'Genesis Korea official download center boundary audit', 'https://www.genesis.com/kr/ko/support/download-center/genesis-models.html'),
    ('model-genesis-032-gv70', 'Genesis Korea official download center boundary audit', 'https://www.genesis.com/kr/ko/support/download-center/genesis-models.html'),
    ('model-genesis-electrified-gv70-kr', 'Genesis Korea official download center boundary audit', 'https://www.genesis.com/kr/ko/support/download-center/genesis-models.html'),
    ('model-genesis-033-gv80', 'Genesis Korea official download center boundary audit', 'https://www.genesis.com/kr/ko/support/download-center/genesis-models.html'),
    ('model-genesis-gv80-coupe-kr', 'Genesis Korea official download center boundary audit', 'https://www.genesis.com/kr/ko/support/download-center/genesis-models.html'),
    ('model-chevrolet-034-kr', 'Chevrolet Korea official type-price boundary audit', 'https://www.chevrolet.co.kr/finance/type-price'),
    ('model-chevrolet-035-kr', 'Chevrolet Korea official type-price boundary audit', 'https://www.chevrolet.co.kr/finance/type-price'),
    ('model-chevrolet-036-kr', 'Chevrolet Korea official type-price boundary audit', 'https://www.chevrolet.co.kr/finance/type-price'),
    ('model-chevrolet-037-kr', 'Chevrolet Korea official type-price boundary audit', 'https://www.chevrolet.co.kr/finance/type-price'),
    ('model-chevrolet-038-kr', 'Chevrolet Korea official type-price boundary audit', 'https://www.chevrolet.co.kr/finance/type-price'),
    ('model-chevrolet-039-kr', 'Chevrolet Korea official type-price boundary audit', 'https://www.chevrolet.co.kr/finance/type-price'),
    ('model-chevrolet-040-kr', 'Chevrolet Korea official type-price boundary audit', 'https://www.chevrolet.co.kr/finance/type-price'),
    ('model-chevrolet-041-ev', 'Chevrolet Korea official type-price boundary audit', 'https://www.chevrolet.co.kr/finance/type-price'),
    ('model-renault-042-sm6', 'Renault Korea official model list boundary audit', 'https://www.renault.co.kr/ko/model/model_list.jsp'),
    ('model-renault-043-qm6', 'Renault Korea official model list boundary audit', 'https://www.renault.co.kr/ko/model/model_list.jsp'),
    ('model-renault-044-xm3', 'Renault Korea official model list boundary audit', 'https://www.renault.co.kr/ko/model/model_list.jsp'),
    ('model-renault-arkana-kr', 'Renault Korea official model list boundary audit', 'https://www.renault.co.kr/ko/model/model_list.jsp'),
    ('model-renault-045-kr', 'Renault Korea official model list boundary audit', 'https://www.renault.co.kr/ko/model/model_list.jsp'),
    ('model-renault-filante-kr', 'Renault Korea official model list boundary audit', 'https://www.renault.co.kr/ko/model/model_list.jsp'),
    ('model-kgm-046-kr', 'KGM official model page boundary audit', 'https://www.kg-mobility.com/pr/model'),
    ('model-kgm-047-kr', 'KGM official model page boundary audit', 'https://www.kg-mobility.com/pr/model'),
    ('model-kgm-actyon-kr', 'KGM official model page boundary audit', 'https://www.kg-mobility.com/pr/model'),
    ('model-kgm-actyon-hybrid-kr', 'KGM official model page boundary audit', 'https://www.kg-mobility.com/pr/model'),
    ('model-kgm-048-kr', 'KGM official model page boundary audit', 'https://www.kg-mobility.com/pr/model'),
    ('model-kgm-torres-hybrid-kr', 'KGM official model page boundary audit', 'https://www.kg-mobility.com/pr/model'),
    ('model-kgm-torres-evx-kr', 'KGM official model page boundary audit', 'https://www.kg-mobility.com/pr/model'),
    ('model-kgm-049-kr', 'KGM official model page boundary audit', 'https://www.kg-mobility.com/pr/model'),
    ('model-kgm-050-kr', 'KGM official model page boundary audit', 'https://www.kg-mobility.com/pr/model'),
    ('model-kgm-musso-kr', 'KGM official model page boundary audit', 'https://www.kg-mobility.com/pr/model'),
    ('model-kgm-musso-ev-kr', 'KGM official model page boundary audit', 'https://www.kg-mobility.com/pr/model')
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
where vv.model_year_id = vmy.id;

with audited_model_ids(id) as (
  values
    ('model-genesis-028-g70'),
    ('model-genesis-g70-shooting-brake-kr'),
    ('model-genesis-029-g80'),
    ('model-genesis-electrified-g80-kr'),
    ('model-genesis-030-g90'),
    ('model-genesis-031-gv60'),
    ('model-genesis-032-gv70'),
    ('model-genesis-electrified-gv70-kr'),
    ('model-genesis-033-gv80'),
    ('model-genesis-gv80-coupe-kr'),
    ('model-chevrolet-034-kr'),
    ('model-chevrolet-035-kr'),
    ('model-chevrolet-036-kr'),
    ('model-chevrolet-037-kr'),
    ('model-chevrolet-038-kr'),
    ('model-chevrolet-039-kr'),
    ('model-chevrolet-040-kr'),
    ('model-chevrolet-041-ev'),
    ('model-renault-042-sm6'),
    ('model-renault-043-qm6'),
    ('model-renault-044-xm3'),
    ('model-renault-arkana-kr'),
    ('model-renault-045-kr'),
    ('model-renault-filante-kr'),
    ('model-kgm-046-kr'),
    ('model-kgm-047-kr'),
    ('model-kgm-actyon-kr'),
    ('model-kgm-actyon-hybrid-kr'),
    ('model-kgm-048-kr'),
    ('model-kgm-torres-hybrid-kr'),
    ('model-kgm-torres-evx-kr'),
    ('model-kgm-049-kr'),
    ('model-kgm-050-kr'),
    ('model-kgm-musso-kr'),
    ('model-kgm-musso-ev-kr')
)
delete from public.vehicle_powertrain_sources vps
using public.vehicle_variants vv,
  public.vehicle_model_years vmy,
  audited_model_ids ami
where vps.powertrain_id = vv.id
  and vv.model_year_id = vmy.id
  and vmy.model_id = ami.id
  and vv.source_status not in ('verified_official', 'verified_admin');
