import 'dart:io';

class CheckFailure {
  const CheckFailure(this.scope, this.message);

  final String scope;
  final String message;

  @override
  String toString() => '$scope: $message';
}

void main() {
  final failures = <CheckFailure>[];
  var checkCount = 0;

  void check(String scope, bool condition, String message) {
    checkCount += 1;
    if (!condition) failures.add(CheckFailure(scope, message));
  }

  final migrationFiles = _migrationFiles();
  check(
    'supabase/migrations',
    migrationFiles.isNotEmpty,
    'Supabase migration files are missing',
  );
  final sql = migrationFiles.map((file) => file.readAsStringSync()).join('\n');

  _validateRequiredTables(sql, check);
  _validateRls(sql, check);
  _validatePolicies(sql, check);
  _validateProfileSelfWriteHardening(check);
  _validateViews(sql, check);
  _validateRpcFunctions(sql, check);
  _validateRpcGrants(sql, check);
  _validateAppSettingsSeeds(sql, check);
  _validateSubscriptionProductSeeds(sql, check);
  _validateIntegrityGuards(sql, check);
  _validateVehicleCatalogSeed(check);
  _validateVehicleGenerationSchema(sql, check);

  if (failures.isEmpty) {
    stdout.writeln('supabase schema valid: $checkCount checks');
    return;
  }

  stderr.writeln('supabase schema validation failed:');
  for (final failure in failures) {
    stderr.writeln('- $failure');
  }
  exitCode = 1;
}

void _validateRequiredTables(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final table in _requiredTables) {
    check(
      'supabase/migrations/$table',
      _hasCreateTable(sql, table),
      'required table public.$table is missing',
    );
  }
}

void _validateRls(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  final tables = {..._requiredTables, ..._createdPublicTables(sql)}..removeAll({
      'spatial_ref_sys',
    });
  for (final table in tables) {
    check(
      'supabase/migrations/$table',
      _hasRls(sql, table),
      'public.$table must enable row level security',
    );
  }
}

void _validatePolicies(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final entry in _requiredPolicies.entries) {
    final table = entry.key;
    for (final policy in entry.value) {
      check(
        'supabase/migrations/$table',
        _hasPolicy(sql, table, policy),
        'public.$table must define policy "$policy"',
      );
    }
  }
}

void _validateViews(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final view in [
    'public_rankings',
    'public_profiles_view',
    'public_rankings_view',
    'public_user_primary_vehicle_view',
    'vehicle_catalog_view',
    'vehicle_manufacturer_catalog_view',
    'vehicle_generation_filter_view',
  ]) {
    check(
      'supabase/migrations/$view',
      _hasView(sql, view),
      'public.$view view is missing',
    );
  }

  final publicRankings = _viewSql(sql, 'public_rankings').toLowerCase();
  check(
    'supabase/migrations/public_rankings',
    sql.contains('drop view if exists public.public_rankings'),
    'public_rankings must be dropped before repeated view definitions',
  );
  for (final forbidden in [
    'drive_points',
    'latitude',
    'longitude',
    ' email',
    '.email',
  ]) {
    check(
      'supabase/migrations/public_rankings',
      !publicRankings.contains(forbidden),
      'public_rankings must not expose $forbidden',
    );
  }

  final publicProfilesView =
      _viewSql(sql, 'public_profiles_view').toLowerCase();
  final publicRankingsView =
      _viewSql(sql, 'public_rankings_view').toLowerCase();
  for (final forbidden in [
    ' email',
    '.email',
    'google_subject',
    'last_login_at',
    'deleted_at',
    'drive_points',
    'latitude',
    'longitude',
  ]) {
    check(
      'supabase/migrations/public_profiles_view',
      !publicProfilesView.contains(forbidden),
      'public_profiles_view must not expose $forbidden',
    );
    check(
      'supabase/migrations/public_rankings_view',
      !publicRankingsView.contains(forbidden),
      'public_rankings_view must not expose $forbidden',
    );
  }

  final manufacturerCatalog =
      _viewSql(sql, 'vehicle_manufacturer_catalog_view').toLowerCase();
  for (final token in [
    'with (security_invoker = true)',
    'count(distinct vm.id)::integer as model_count',
    'coalesce(min(vmy.year), 0)::integer as min_year',
    'coalesce(max(vmy.year), 0)::integer as max_year',
    'left join public.vehicle_models vm',
    'left join public.vehicle_model_years vmy',
  ]) {
    check(
      'supabase/migrations/vehicle_manufacturer_catalog_view',
      manufacturerCatalog.contains(token),
      'vehicle_manufacturer_catalog_view must expose catalog stat "$token"',
    );
  }
}

void _validateVehicleGenerationSchema(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  final normalized = sql.toLowerCase();
  for (final token in [
    'create table if not exists public.vehicle_generations',
    'create table if not exists public.vehicle_generation_years',
    'add column if not exists generation_id text references public.vehicle_generations',
    'add column if not exists production_year_label text',
    'add column if not exists valid_from_year integer',
    'add column if not exists valid_to_year integer',
    'add column if not exists applies_to_years integer[]',
    'constraint vehicle_generations_verified_source check',
    "source_status not in ('verified_official', 'verified_admin')",
    'idx_vehicle_generations_model_id',
    'idx_vehicle_model_years_generation_id',
    'idx_vehicle_variants_generation_id',
    'idx_vehicle_generation_years_generation_id',
    'generation-hyundai-avante-cn7',
    'generation-hyundai-ioniq5-ne',
    'generation-hyundai-ioniq6-ce',
    'generation-hyundai-sonata-lf',
    'generation-hyundai-sonata-dn8',
    'generation-hyundai-grandeur-hg',
    'generation-hyundai-grandeur-ig',
    'generation-hyundai-grandeur-gn7',
    'generation-hyundai-tucson-tl',
    'generation-hyundai-tucson-nx4',
    'generation-hyundai-santafe-dm',
    'generation-hyundai-santafe-tm',
    'generation-hyundai-santafe-mx5',
    'generation-hyundai-avante-n-cn7',
    'generation-hyundai-avante-sport-ad',
    'generation-hyundai-kona-os',
    'generation-hyundai-kona-sx2',
    'generation-hyundai-palisade-lx2',
    'generation-hyundai-palisade-lx3',
    'generation-hyundai-casper-ax1',
    'generation-hyundai-staria-us4',
    'generation-hyundai-porter2-hr',
    'generation-hyundai-venue-official-lineup',
    'generation-hyundai-casper-electric-official-lineup',
    'generation-hyundai-ioniq5-n-official-lineup',
    'generation-hyundai-ioniq6-n-official-lineup',
    'generation-hyundai-ioniq9-official-lineup',
    'generation-hyundai-nexo-official-lineup',
    'generation-hyundai-staria-electric-official-lineup',
    'generation-hyundai-st1-official-lineup',
    'model-hyundai-venue-kr',
    'model-hyundai-casper-electric-kr',
    'model-hyundai-ioniq5-n-kr',
    'model-hyundai-ioniq6-n-kr',
    'model-hyundai-ioniq9-kr',
    'model-hyundai-nexo-kr',
    'model-hyundai-staria-electric-kr',
    'model-hyundai-st1-kr',
    "'https://www.hyundai.com/kr/ko/e/vehicles/venue/intro'",
    "'https://casper.hyundai.com/vehicles/electric/highlight'",
    "'https://www.hyundai.com/kr/ko/e/vehicles/ioniq5-n/intro'",
    "'https://www.hyundai.com/kr/ko/e/vehicles/ioniq6-n/intro'",
    "'https://www.hyundai.com/kr/ko/e/vehicles/ioniq9/intro'",
    "'https://www.hyundai.com/kr/ko/e/vehicles/the-all-new-nexo/intro'",
    "'https://www.hyundai.com/kr/ko/e/vehicles/the-new-staria-electric/intro'",
    "'https://www.hyundai.com/kr/ko/e/vehicles/st1/intro'",
    "'hydrogen', 'fuel_cell', '수소', '수소차', '수소전기', '수소전기차'",
    "'km/kg'",
    "model_id = 'model-hyundai-avante-n-kr'",
    "model_id = 'model-hyundai-004-kr'",
    "model_id = 'model-hyundai-007-kr'",
    "model_id = 'model-hyundai-011-kr'",
    "model_id = 'model-hyundai-012-kr'",
    "vv.fuel_type = '하이브리드'",
    "vv.fuel_type = 'lpg'",
    'generation-kia-k3-bd',
    'generation-kia-k5-jf',
    'generation-kia-k5-dl3',
    'generation-kia-k8-gl3',
    'generation-kia-k9-kh',
    'generation-kia-k9-rj',
    'generation-kia-morning-ta',
    'generation-kia-morning-ja',
    'generation-kia-ray-tam',
    'generation-kia-seltos-sp2',
    'generation-kia-niro-de',
    'generation-kia-niro-sg2',
    'generation-kia-sportage-ql',
    'generation-kia-sportage-nq5',
    'generation-kia-sorento-um',
    'generation-kia-sorento-mq4',
    'generation-kia-carnival-yp',
    'generation-kia-carnival-ka4',
    'generation-kia-ev3-sv1',
    'generation-kia-ev6-cv',
    'generation-kia-ev9-mv1',
    'generation-kia-bongo-pu',
    'generation-kia-ev4-official-lineup',
    'generation-kia-ev5-official-lineup',
    'generation-kia-pv5-official-lineup',
    'generation-kia-tasman-official-lineup',
    'model-kia-ev4-kr',
    'model-kia-ev5-kr',
    'model-kia-pv5-kr',
    'model-kia-tasman-kr',
    "'https://www.kia.com/kr/vehicles/ev4/features'",
    "'https://www.kia.com/kr/vehicles/ev5/features'",
    "'https://www.kia.com/kr/vehicles/kia-ev/vehicles/ev-line-up'",
    "'https://www.kia.com/kr/vehicles/tasman/features'",
    'generation-benz-a-class-w176',
    'generation-benz-a-class-w177',
    'generation-benz-c-class-w205',
    'generation-benz-c-class-w206',
    'generation-benz-e-class-w212',
    'generation-benz-e-class-w213',
    'generation-benz-e-class-w214',
    'generation-benz-s-class-w222',
    'generation-benz-s-class-w223',
    'generation-benz-gla-x156',
    'generation-benz-gla-h247',
    'generation-benz-glc-x253',
    'generation-benz-glc-x254',
    'generation-benz-gle-w166',
    'generation-benz-gle-v167',
    'generation-benz-gls-x166',
    'generation-benz-gls-x167',
    'generation-benz-eqa-h243',
    'generation-benz-eqb-x243',
    'generation-benz-eqe-v295',
    'generation-benz-eqs-v297',
    'generation-benz-s-class-long-official-lineup',
    'generation-benz-maybach-s-class-official-lineup',
    'generation-benz-eqe-suv-official-lineup',
    'generation-benz-maybach-eqs-suv-official-lineup',
    'generation-benz-glb-official-lineup',
    'generation-benz-glc-coupe-official-lineup',
    'generation-benz-gle-coupe-official-lineup',
    'generation-benz-maybach-gls-official-lineup',
    'generation-benz-g-class-official-lineup',
    'generation-benz-cla-coupe-official-lineup',
    'generation-benz-cle-coupe-official-lineup',
    'generation-benz-amg-gt-coupe-official-lineup',
    'generation-benz-amg-gt-4door-coupe-official-lineup',
    'generation-benz-cle-cabriolet-official-lineup',
    'generation-benz-sl-roadster-official-lineup',
    'generation-benz-maybach-sl-monogram-official-lineup',
    "'https://rk.mb-qr.com/en/'",
    "'https://www.mercedes-benz.co.kr/passengercars/models.html'",
    "model_id = 'model-benz-073-eqa'",
    "model_id = 'model-benz-074-eqb'",
    "model_id = 'model-benz-075-eqe'",
    "model_id = 'model-benz-076-eqs'",
    "vmy.model_id = 'model-benz-073-eqa' and vmy.year < 2021",
    "vmy.model_id = 'model-benz-074-eqb' and vmy.year < 2022",
    "vmy.model_id = 'model-benz-075-eqe' and vmy.year < 2022",
    "vmy.model_id = 'model-benz-076-eqs' and vmy.year < 2021",
    'generation-audi-a3-8v',
    'generation-audi-a3-8y',
    'generation-audi-a4-b9-8w',
    'generation-audi-a5-8t',
    'generation-audi-a5-f5',
    'generation-audi-a5-b10',
    'generation-audi-a6-c7-4g',
    'generation-audi-a6-c8-4a',
    'generation-audi-a6-c9',
    'generation-audi-a7-4g8',
    'generation-audi-a7-4k8',
    'generation-audi-a8-d4-4h',
    'generation-audi-a8-d5-4n',
    'generation-audi-q3-8u',
    'generation-audi-q3-f3',
    'generation-audi-q3-2025',
    'generation-audi-q5-8r',
    'generation-audi-q5-fy',
    'generation-audi-q5-2025',
    'generation-audi-q7-4m',
    'generation-audi-q8-4m',
    'generation-audi-e-tron-ge',
    'generation-audi-q8-e-tron-ge',
    'generation-audi-q4-e-tron-f4',
    'generation-audi-e-tron-gt-official-lineup',
    'generation-audi-a6-e-tron-official-lineup',
    'generation-audi-q6-e-tron-official-lineup',
    "'https://www.audi.com/en/rescue/'",
    "'https://www.audi.co.kr/ko/models/'",
    "model_id = 'model-audi-078-a4'",
    "model_id = 'model-audi-081-a7'",
    "model_id = 'model-audi-086-q8'",
    "model_id = 'model-audi-087-e-tron'",
    "model_id = 'model-audi-088-q4-e-tron'",
    "vmy.model_id = 'model-audi-078-a4' and vmy.year > 2024",
    "vmy.model_id = 'model-audi-081-a7' and vmy.year > 2025",
    "vmy.model_id = 'model-audi-086-q8' and vmy.year < 2018",
    "vmy.model_id = 'model-audi-087-e-tron' and (vmy.year < 2018 or vmy.year > 2025)",
    "vmy.model_id = 'model-audi-088-q4-e-tron' and vmy.year < 2021",
    'generation-chevrolet-spark-m400',
    'generation-chevrolet-malibu-v300',
    'generation-chevrolet-malibu-v400',
    'generation-chevrolet-trax-u200',
    'generation-chevrolet-trax-crossover-9bqc',
    'generation-chevrolet-trailblazer-vss-f',
    'generation-chevrolet-traverse-c1xx',
    'generation-chevrolet-tahoe-t1xx',
    'generation-chevrolet-equinox-official-lineup',
    'generation-chevrolet-colorado-rg',
    'generation-chevrolet-colorado-31xx-2',
    'generation-chevrolet-bolt-ev-g2cx',
    "'https://www.chevrolet.co.kr/finance/type-price'",
    "'https://www.chevrolet.co.kr/suvs'",
    "model_id = 'model-chevrolet-034-kr'",
    "model_id = 'model-chevrolet-035-kr'",
    "model_id = 'model-chevrolet-037-kr'",
    "model_id = 'model-chevrolet-038-kr'",
    "model_id = 'model-chevrolet-039-kr'",
    "model_id = 'model-chevrolet-equinox-kr'",
    "model_id = 'model-chevrolet-040-kr'",
    "model_id = 'model-chevrolet-041-ev'",
    "vmy.model_id = 'model-chevrolet-034-kr' and vmy.year > 2022",
    "vmy.model_id = 'model-chevrolet-035-kr' and vmy.year > 2022",
    "vmy.model_id = 'model-chevrolet-037-kr' and vmy.year < 2020",
    "vmy.model_id = 'model-chevrolet-038-kr' and (vmy.year < 2019 or vmy.year > 2026)",
    "vmy.model_id = 'model-chevrolet-039-kr' and (vmy.year < 2022 or vmy.year > 2026)",
    "vmy.model_id = 'model-chevrolet-equinox-kr' and vmy.year <> 2026",
    "vmy.model_id = 'model-chevrolet-040-kr' and vmy.year < 2019",
    "vmy.model_id = 'model-chevrolet-041-ev' and (vmy.year < 2017 or vmy.year > 2023)",
    'generation-volvo-s60-p3',
    'generation-volvo-s60-spa',
    'generation-volvo-s90-spa',
    'generation-volvo-xc40-cma',
    'generation-volvo-xc60-p3',
    'generation-volvo-xc60-spa',
    'generation-volvo-xc90-spa',
    'generation-volvo-c40-cma',
    'generation-volvo-ex40-official-lineup',
    'generation-volvo-ec40-official-lineup',
    'generation-volvo-ex30',
    'generation-volvo-ex90',
    'generation-volvo-v60-cross-country-spa',
    'generation-volvo-ex30-cross-country-official-lineup',
    'generation-volvo-es90-official-lineup',
    'model-volvo-v60-cross-country-kr',
    'model-volvo-ex30-cross-country-kr',
    'model-volvo-es90-kr',
    'model-volvo-ex40-kr',
    'model-volvo-ec40-kr',
    "'https://www.volvocars.com/kr/'",
    "'https://www.volvocars.com/us/media/press-releases/217972/'",
    "'https://www.volvocars.com/kr/news/corporate/new-name-new-me-say-hello-to-the-ex40-and-ec40/'",
    "'https://www.volvocars.com/kr/news/culture/20250904-launch-of-the-ex30-cross-country/'",
    "'https://www.volvocars.com/kr/news/culture/20260611-volvo-car-opens-es90-pre-orders/'",
    'volvo cars korea official ex40/ec40 rename news and support',
    "model_id = 'model-volvo-124-s60'",
    "model_id = 'model-volvo-125-s90'",
    "model_id = 'model-volvo-126-xc40'",
    "model_id = 'model-volvo-129-c40'",
    "vmy.model_id = 'model-volvo-129-c40' and vmy.year > 2024",
    "vmy.model_id = 'model-volvo-126-xc40'",
    "vv.fuel_league = 'electric'",
    "model_id = 'model-volvo-130-ex30'",
    "model_id = 'model-volvo-131-ex90'",
    "vmy.model_id = 'model-volvo-124-s60' and vmy.year > 2025",
    "vmy.model_id = 'model-volvo-125-s90' and vmy.year < 2016",
    "vmy.model_id = 'model-volvo-126-xc40' and vmy.year < 2018",
    "vmy.model_id = 'model-volvo-126-xc40' and vv.fuel_type = '전기차' and (vmy.year < 2021 or vmy.year > 2024)",
    "vmy.model_id = 'model-volvo-129-c40' and (vmy.year < 2022 or vmy.year > 2024)",
    "vmy.model_id = 'model-volvo-130-ex30' and vmy.year < 2025",
    "vmy.model_id = 'model-volvo-131-ex90' and vmy.year < 2026",
    "vmy.model_id = 'model-volvo-ex30-cross-country-kr' and vmy.year < 2025",
    "vmy.model_id = 'model-volvo-es90-kr' and vmy.year < 2026",
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
    'generation-kgm-torres-van-official-lineup',
    'generation-kgm-torres-evx-van-official-lineup',
    'generation-kgm-rexton-y400',
    'generation-kgm-rexton-summit-official-lineup',
    'generation-kgm-rexton-sports-q200',
    'generation-kgm-musso-q300',
    'generation-kgm-musso-ev-q300',
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
    'model-kgm-torres-van-kr',
    'model-kgm-torres-evx-van-kr',
    'model-kgm-rexton-summit-kr',
    'model-kgm-musso-kr',
    'model-kgm-musso-ev-kr',
    "vmy.model_id = 'model-genesis-029-g80' and (vmy.year < 2016 or vv.fuel_type = '전기차')",
    "vmy.model_id = 'model-genesis-032-gv70' and (vmy.year < 2021 or vv.fuel_type = '전기차')",
    "vmy.model_id = 'model-renault-045-kr' and vmy.year < 2025",
    "vmy.model_id = 'model-kgm-048-kr' and (vmy.year < 2022 or vv.fuel_type <> '가솔린')",
    'generation-volkswagen-golf-official-lineup',
    'generation-volkswagen-golf-gti-official-lineup',
    'generation-volkswagen-jetta-official-lineup',
    'generation-volkswagen-passat-official-lineup',
    'generation-volkswagen-tiguan-official-lineup',
    'generation-volkswagen-touareg-official-lineup',
    'generation-volkswagen-atlas-official-lineup',
    'generation-volkswagen-id4-official-lineup',
    'generation-volkswagen-id5-official-lineup',
    'generation-volkswagen-arteon-official-lineup',
    'generation-toyota-prius-official-lineup',
    'generation-toyota-camry-official-lineup',
    'generation-toyota-rav4-official-lineup',
    'generation-toyota-highlander-official-lineup',
    'generation-toyota-sienna-official-lineup',
    'generation-toyota-crown-official-lineup',
    'generation-toyota-gr86-official-lineup',
    'generation-toyota-alphard-official-lineup',
    'generation-lexus-es-official-lineup',
    'generation-lexus-ls-official-lineup',
    'generation-lexus-nx-official-lineup',
    'generation-lexus-rx-official-lineup',
    'generation-lexus-ux-official-lineup',
    'generation-lexus-rz-official-lineup',
    'generation-lexus-lm-official-lineup',
    'generation-lexus-lx-official-lineup',
    'generation-lexus-lc-official-model-page',
    'generation-lexus-rc-official-model-page',
    'variant-toyota-prius-2026-hev-2wd',
    'variant-toyota-rav4-2026-phev-xse',
    'variant-toyota-crown-2026-dual-boost-hev',
    'variant-toyota-gr86-2026-24-gasoline',
    "'https://www.toyota.co.kr/models/priushev/'",
    "'https://toyota.co.kr/models/rav4phev/'",
    "'https://toyota.co.kr/models/crown/'",
    'variant-lexus-nx-2026-450h-plus-pending',
    'variant-lexus-rx-2026-500h-pending',
    'variant-lexus-rz-2026-450e-pending',
    'variant-lexus-ls-2026-500-pending',
    'variant-lexus-lx-2026-700h-pending',
    'lexus korea official electrified/model page',
    'lexus korea official lx model page and model json',
    "'https://www.lexus.co.kr/models/nx-450h-plus/'",
    "'https://www.lexus.co.kr/models/rx-500h/'",
    "'https://www.lexus.co.kr/models/ls-500/'",
    "'https://www.lexus.co.kr/models/lx/'",
    'vmy.year <> 2026',
    'model-lexus-lc-kr',
    'model-lexus-lx-kr',
    'model-lexus-rc-kr',
    "'https://www.lexus.co.kr/models/lc-500/'",
    "'https://www.lexus.co.kr/models/rc-300-f-sport/'",
    'generation-honda-civic-official-lineup',
    'generation-honda-accord-official-lineup',
    'generation-honda-cr-v-official-lineup',
    'generation-honda-hr-v-official-lineup',
    'generation-honda-pilot-official-lineup',
    'generation-honda-odyssey-official-lineup',
    'generation-nissan-altima-official-lineup',
    'generation-nissan-maxima-official-lineup',
    'generation-nissan-rogue-official-lineup',
    'generation-nissan-leaf-official-lineup',
    'generation-nissan-ariya-official-lineup',
    'mercedes-benz korea official model overview boundary audit',
    'audi korea official model overview boundary audit',
    'volvo cars korea official model lineup boundary audit',
    'honda korea official showroom boundary audit',
    'nissan korea official withdrawal/archive boundary audit',
    'genesis korea official download center boundary audit',
    'chevrolet korea official type-price boundary audit',
    'chevrolet korea official suv lineup boundary audit',
    'renault korea official model list boundary audit',
    'kgm official model page boundary audit',
    'kgm official korean model list gap audit',
    "'https://www.genesis.com/kr/ko/support/download-center/genesis-models.html'",
    "'https://www.chevrolet.co.kr/finance/type-price'",
    "'https://www.chevrolet.co.kr/suvs'",
    "'https://www.renault.co.kr/ko/model/model_list.jsp'",
    "'https://www.kg-mobility.com/pr/model'",
    'hyundai motor korea official vehicle lineup boundary audit',
    'kia korea official vehicle/category boundary audit',
    'kia korea official ev category boundary audit',
    'hyundai motor korea official avante price pdf',
    "'https://www.hyundai.com/kr/ko/e/all-vehicles'",
    "'https://www.hyundai.com/contents/repn-car/catalog/the-new-avante-price.pdf'",
    "'https://www.kia.com/kr/vehicles/sedan'",
    "'https://www.kia.com/kr/vehicles/rv'",
    "'https://www.kia.com/kr/vehicles/ev'",
    "'https://www.kia.com/kr/vehicles/commercial'",
    'honda korea official online showroom current model list',
    "'https://www.nissan.co.kr/news_and_events/2002_news_b1.html'",
    "'https://www.nissan.co.kr/experience-nissan-im/news_and_events/190318.html'",
    "vmy.model_id in ('model-nissan-115-kr', 'model-nissan-116-kr', 'model-nissan-117-kr') and vmy.year > 2020",
    "vmy.model_id = 'model-nissan-118-kr' and (vmy.year < 2019 or vmy.year > 2020)",
    "vmy.model_id = 'model-nissan-119-kr' and vmy.year <> 2026",
    'generation-tesla-model3-official-lineup',
    'generation-tesla-modely-official-lineup',
    'generation-tesla-models-official-lineup',
    'generation-tesla-modelx-official-lineup',
    'generation-tesla-cybertruck-official-lineup',
    'model-tesla-cybertruck-kr',
    "'https://www.tesla.com/ko_kr/cybertruck'",
    'variant-tesla-model-3-2026-standard-rwd',
    'variant-tesla-model-3-2026-premium-long-range-rwd',
    'variant-tesla-model-3-2026-performance',
    'variant-tesla-model-y-2026-premium-rwd',
    'variant-tesla-model-y-2026-premium-long-range-awd',
    'variant-tesla-model-y-2026-l-pending',
    'variant-tesla-model-s-2026-awd',
    'variant-tesla-model-s-2026-plaid',
    'variant-tesla-model-x-2026-awd',
    'variant-tesla-model-x-2026-plaid',
    "'https://www.tesla.com/ko_kr/support/range-calculator-ref'",
    'generation-porsche-911-official-lineup',
    'generation-porsche-boxster-official-lineup',
    'generation-porsche-cayman-official-lineup',
    'generation-porsche-panamera-official-lineup',
    'generation-porsche-macan-official-lineup',
    'generation-porsche-cayenne-official-lineup',
    'generation-porsche-taycan-official-lineup',
    'porsche korea official model-page boundary audit',
    "'https://www.porsche.com/korea/ko/models/911/'",
    "'https://www.porsche.com/korea/ko/models/taycan/'",
    "'https://www.porsche.com/korea/ko/models/macan/'",
    "'https://www.porsche.com/korea/ko/models/cayenne/'",
    'variant-porsche-macan-2026-electric-pending',
    'variant-porsche-cayenne-2026-electric-pending',
    "vmy.model_id = 'model-porsche-136-kr'",
    "vmy.model_id = 'model-porsche-137-kr'",
    "and vv.fuel_type = '전기차'",
    'and vmy.year < 2026',
    'generation-mini-hatch-official-lineup',
    'generation-mini-countryman-official-lineup',
    'generation-mini-clubman-official-lineup',
    'generation-mini-cooper-se-official-lineup',
    'generation-mini-convertible-official-lineup',
    'generation-mini-aceman-official-lineup',
    'generation-mini-cooper-5-door-official-lineup',
    'generation-mini-electric-cooper-official-lineup',
    'generation-mini-electric-countryman-official-lineup',
    'generation-mini-jcw-official-lineup',
    'generation-peugeot-208-official-lineup',
    'generation-peugeot-308-official-lineup',
    'generation-peugeot-2008-official-lineup',
    'generation-peugeot-3008-official-lineup',
    'generation-peugeot-5008-official-lineup',
    'generation-peugeot-408-official-lineup',
    'variant-peugeot-308-2026-smart-hybrid-allure',
    'variant-peugeot-308-2026-smart-hybrid-gt',
    'variant-peugeot-3008-2026-smart-hybrid-allure',
    'variant-peugeot-3008-2026-smart-hybrid-gt',
    'variant-peugeot-5008-2026-smart-hybrid-allure',
    'variant-peugeot-5008-2026-smart-hybrid-gt',
    'variant-peugeot-408-2026-smart-hybrid-allure',
    'variant-peugeot-408-2026-smart-hybrid-gt',
    "'https://www.epeugeot.co.kr/car-selector/peugeot-range.html'",
    "'https://www.epeugeot.co.kr/new-cars/308hybrid.html'",
    "'https://www.epeugeot.co.kr/new-cars/3008hybrid.html'",
    "'https://www.epeugeot.co.kr/new-cars/5008hybrid.html'",
    "'https://www.epeugeot.co.kr/new-cars/408hybrid.html'",
    'generation-jeep-renegade-official-lineup',
    'generation-jeep-compass-official-lineup',
    'generation-jeep-cherokee-official-lineup',
    'generation-jeep-wrangler-official-lineup',
    'generation-jeep-grand-cherokee-official-lineup',
    'generation-jeep-gladiator-official-lineup',
    'generation-jeep-grand-cherokee-l-official-lineup',
    'generation-jeep-avenger-official-lineup',
    'model-jeep-avenger-kr',
    'jeep korea official homepage boundary audit',
    "'https://www.jeep.co.kr/wrangler.html'",
    "'https://www.jeep.co.kr/gladiator.html'",
    "'https://www.jeep.co.kr/grand-cherokee-l.html'",
    "'https://www.jeep.co.kr/jl/avenger.html'",
    'generation-landrover-defender-official-lineup',
    'generation-landrover-discovery-official-lineup',
    'generation-landrover-range-rover-official-lineup',
    'generation-landrover-range-rover-sport-official-lineup',
    'generation-landrover-range-rover-evoque-official-lineup',
    'generation-landrover-discovery-sport-official-lineup',
    'generation-landrover-range-rover-velar-official-lineup',
    'variant-landrover-defender-2026-d250-pending',
    'variant-landrover-range-rover-2026-p550e-pending',
    'variant-landrover-range-rover-sport-2026-p635-pending',
    'variant-landrover-velar-2026-p400e-pending',
    "'https://www.landroverkorea.co.kr/defender/defender-110/price-and-spec.html'",
    "'https://www.landroverkorea.co.kr/discovery/discovery/price-and-spec.html'",
    "'https://www.landroverkorea.co.kr/range-rover/range-rover-velar/price-and-spec.html'",
    'land rover korea official 2026 price page',
    'model-landrover-range-rover-velar-kr',
    '\'{"가솔린","플러그인 하이브리드"}\'',
    'generation-polestar-2-official-lineup',
    'generation-polestar-3-official-lineup',
    'generation-polestar-4-official-lineup',
    'generation-polestar-5-official-lineup',
    'model-polestar-5-kr',
    "'https://www.polestar.com/kr/polestar-5/'",
    'variant-polestar-2-2026-standard-range-single-motor',
    'variant-polestar-2-2026-long-range-single-motor',
    'variant-polestar-2-2026-long-range-dual-motor',
    'variant-polestar-4-2026-coupe-rear-motor',
    'variant-polestar-4-2026-coupe-dual-motor',
    'variant-polestar-4-2026-coupe-dual-motor-performance',
    "'https://www.polestar.com/kr/polestar-2/specifications/'",
    "'https://www.polestar.com/kr/polestar-4-models/polestar-4-coupe/specifications/'",
    '2026년 2분기 출시 예정',
    'is_upcoming',
    '2026년 국내 출시 예정',
    'model-volkswagen-golf-gti-kr',
    'model-volkswagen-atlas-kr',
    'model-volkswagen-id5-kr',
    "'https://www.volkswagen.co.kr/ko.html'",
    "'https://www.volkswagen.co.kr/ko/electriccar/models.html'",
    'variant-volkswagen-golf-2026-20-tdi-premium',
    'variant-volkswagen-golf-gti-2026-20-tsi',
    'variant-volkswagen-touareg-2026-30-tdi-final-prestige',
    'variant-volkswagen-atlas-2026-20-tsi-7-seat',
    'variant-volkswagen-id4-2026-pro-lite-my25',
    'variant-volkswagen-id5-2026-pro-lite',
    "'https://www.volkswagen.co.kr/ko/models/golf.html'",
    "'https://www.volkswagen.co.kr/ko/models/golf_gti.html'",
    "'https://www.volkswagen.co.kr/ko/models/atlas.html'",
    "'https://www.volkswagen.co.kr/ko/models/touareg.html'",
    "'https://www.volkswagen.co.kr/ko/models/id4.html'",
    "'https://www.volkswagen.co.kr/ko/models/id5.html'",
    "'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/id5/leaflet/id5_price%20list_260519_web.pdf'",
    "'https://www.toyota.co.kr/test-drive/'",
    "'https://www.toyota.co.kr/models/alphard/'",
    "'https://www.lexus.co.kr/contents/2022-lexus-electrified/electrified'",
    "'https://www.lexus.co.kr/models/lm-500h/'",
    "'https://auto.hondakorea.co.kr/main/'",
    "'https://www.audi.co.kr/ko/models/'",
    "'https://www.volvocars.com/kr/'",
    "'https://www.nissan.co.kr/experience-nissan-im/news_and_events.html'",
    "'https://www.tesla.com/ko_kr/model3'",
    "'https://www.porsche.com/korea/ko/models/'",
    "'https://www.mini.co.kr/ko_kr/home.html'",
    "'https://www.mini.co.kr/ko_kr/home/range/all-electric-mini-aceman.html'",
    "'https://www.mini.co.kr/ko_kr/home/range/john-cooper-works.html'",
    'model-mini-139-kr',
    'model-mini-140-kr',
    'model-mini-141-kr',
    'model-mini-142-se',
    'model-mini-143-kr',
    'model-mini-aceman-kr',
    'generation-mini-aceman-official-lineup',
    'mini korea official model range boundary audit',
    'delete from public.vehicle_powertrain_sources',
    "'https://www.epeugeot.co.kr/'",
    "'https://base.epeugeot.co.kr/board/details/145?srhpg=6&lcdv16=1pr8a5pma1m0a0b0'",
    "'https://www.jeep.co.kr/'",
    "'https://www.jeep.co.kr/gladiator.html'",
    "'https://www.jeep.co.kr/grand-cherokee-l.html'",
    "'https://www.rangerover.com/ko-kr/index.html'",
    "'https://www.landroverkorea.co.kr/content/dam/lrdx/pdfs/kr/241118%20rr%20velar%20price%20chart.pdf'",
    "'https://www.polestar.com/kr/polestar-4-models/polestar-4-coupe/'",
    'generation-bmw-x2-official-lineup',
    'generation-bmw-x4-official-lineup',
    'generation-bmw-x6-official-lineup',
    'generation-bmw-xm-official-lineup',
    'generation-bmw-z4-official-lineup',
    'generation-bmw-i7-official-lineup',
    'generation-bmw-ix1-official-lineup',
    'generation-bmw-ix2-official-lineup',
    'generation-bmw-i3-official-lineup',
    "'https://www.bmw.co.kr/ko/all-models.html'",
    'generation-bmw-1series-f20',
    'generation-bmw-1series-f40',
    'generation-bmw-1series-f70',
    'generation-bmw-2series-coupe-f22',
    'generation-bmw-2series-coupe-g42',
    'generation-bmw-i4-g26',
    'generation-bmw-3series-f30',
    'generation-bmw-3series-g20',
    'generation-bmw-4series-f32-f33-f36',
    'generation-bmw-4series-g22-g23-g26',
    'generation-bmw-5series-g30',
    'generation-bmw-5series-g60',
    'generation-bmw-7series-g11-g12',
    'generation-bmw-7series-g70',
    'generation-bmw-x1-e84',
    'generation-bmw-x1-f48',
    'generation-bmw-x1-u11',
    'generation-bmw-x3-f25',
    'generation-bmw-x3-g01',
    'generation-bmw-x3-g45',
    'generation-bmw-x5-f15',
    'generation-bmw-x5-g05',
    'generation-bmw-x7-g07',
    'generation-bmw-i5-g60',
    'generation-bmw-ix-i20',
    'generation-bmw-ix3-g08',
    "id = 'model-bmw-052-2'",
    "name_ko = '2시리즈 쿠페'",
    "vmy.model_id = 'model-bmw-062-i5' and vmy.year < 2024",
    "model_id = 'model-bmw-051-1'",
    "model_id = 'model-bmw-052-2'",
    "model_id = 'model-bmw-053-3'",
    "model_id = 'model-bmw-054-4'",
    "model_id = 'model-bmw-055-5'",
    "model_id = 'model-bmw-056-7'",
    "model_id = 'model-bmw-057-x1'",
    "model_id = 'model-bmw-058-x3'",
    "model_id = 'model-bmw-059-x5'",
    "model_id = 'model-bmw-060-x7'",
    "vmy.model_id = 'model-bmw-060-x7'",
    'and vmy.year < 2019',
    "vmy.model_id = 'model-bmw-051-1' and vmy.year <= 2019 then 'rwd'",
    "vmy.model_id = 'model-bmw-052-2' then 'rwd'",
    "drivetrain = 'rwd'",
    "then 'awd'",
    "source_status = 'deprecated'",
    "model_id = 'model-hyundai-009-5'",
    "model_id = 'model-hyundai-010-6'",
    "vmy.model_id = 'model-hyundai-009-5'",
    "vmy.model_id = 'model-hyundai-010-6'",
    "'model-hyundai-002-kr'",
    "'model-hyundai-003-kr'",
    "'model-hyundai-005-kr'",
    "'model-hyundai-006-kr'",
    'delete from public.vehicle_models',
    "id = 'model-kia-k3-gt-kr'",
    "model_id = 'model-kia-015-k8'",
    "model_id = 'model-kia-024-ev3'",
    "model_id = 'model-kia-025-ev6'",
    "model_id = 'model-kia-026-ev9'",
    'variant-kia-k3-gt-2024-16t-7dct',
    'valid_from_year = 2018',
    'valid_to_year = 2024',
    "'20260612-0002-4000-8000-000000000001'",
    'insert into public.vehicle_powertrain_sources',
    '기아 공식 k3/k3 gt 가격표',
    "source_status = 'pending_review'",
    'is_verified = false',
    'is_selectable = false',
    "source_status not in ('verified_official', 'verified_admin')",
  ]) {
    check(
      'supabase/migrations/vehicle_generations',
      normalized.contains(token),
      'vehicle generation schema must contain "$token"',
    );
  }

  final viewSql = _viewSql(sql, 'vehicle_generation_filter_view').toLowerCase();
  for (final token in [
    'from public.vehicle_generations vg',
    'join public.vehicle_models vm on vm.id = vg.model_id',
    'left join public.vehicle_model_years vmy on vmy.generation_id = vg.id',
    'left join public.vehicle_generation_years vgy on vgy.generation_id = vg.id',
    'left join public.vehicle_variants vv',
    'matching_powertrain_count',
    'verified_powertrain_count',
    'source_status_summary',
  ]) {
    check(
      'supabase/migrations/vehicle_generation_filter_view',
      viewSql.contains(token),
      'vehicle_generation_filter_view must expose "$token"',
    );
  }
}

void _validateRpcFunctions(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final functionName in [
    'fuel_league_for_type',
    'is_admin_user',
    'recompute_rankings',
    'claim_mission_reward',
    'is_crew_member',
    'get_my_crew_summary',
    'get_my_crew_members',
    'get_admin_dashboard_metrics',
    'handle_new_auth_user',
    'handle_auth_user_login_update',
    'ensure_my_profile',
    'update_my_profile',
    'record_my_consent',
    'revoke_my_consent',
    'request_account_deletion',
    'request_data_export',
    'record_auth_event',
    'get_my_auth_state',
    'is_admin',
  ]) {
    check(
      'supabase/migrations/$functionName',
      _hasFunction(sql, functionName),
      'required RPC function public.$functionName is missing',
    );
  }

  for (final functionName in [
    'is_admin_user',
    'recompute_rankings',
    'claim_mission_reward',
    'is_crew_member',
    'get_my_crew_summary',
    'get_my_crew_members',
    'get_admin_dashboard_metrics',
    'handle_new_auth_user',
    'handle_auth_user_login_update',
    'ensure_my_profile',
    'update_my_profile',
    'record_my_consent',
    'revoke_my_consent',
    'request_account_deletion',
    'request_data_export',
    'record_auth_event',
    'get_my_auth_state',
    'is_admin',
  ]) {
    final functionSql = _functionSql(sql, functionName).toLowerCase();
    check(
      'supabase/migrations/$functionName',
      functionSql.contains('security definer'),
      'public.$functionName must be security definer',
    );
    check(
      'supabase/migrations/$functionName',
      functionSql.contains('set search_path = public'),
      'public.$functionName must pin search_path to public',
    );
  }
}

void _validateRpcGrants(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  final normalized = sql.toLowerCase();
  for (final entry in {
    'recompute_rankings': 'public.recompute_rankings(text)',
    'claim_mission_reward': 'public.claim_mission_reward(uuid, uuid)',
  }.entries) {
    final functionName = entry.key;
    final signature = entry.value;
    for (final role in ['public', 'anon', 'authenticated']) {
      check(
        'supabase/migrations/$functionName',
        normalized.contains('revoke all on function $signature from $role'),
        'edge-only RPC $signature must revoke execute from $role',
      );
    }
    check(
      'supabase/migrations/$functionName',
      normalized.contains(
        'grant execute on function $signature to service_role',
      ),
      'edge-only RPC $signature must grant execute to service_role only',
    );
  }
}

void _validateAppSettingsSeeds(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final key in _requiredPublicAppSettings) {
    check(
      'supabase/migrations/app_settings/$key',
      RegExp(
        "\\(\\s*'$key'\\s*,\\s*'\\{[^']+\\}'\\s*,\\s*'[^']*'\\s*,\\s*true\\s*\\)",
        caseSensitive: false,
      ).hasMatch(sql),
      'public app_settings seed "$key" is missing or not public',
    );
  }
}

void _validateSubscriptionProductSeeds(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final productId in _requiredIapProductIds) {
    check(
      'supabase/migrations/subscription_plans/$productId',
      sql.contains("'$productId'"),
      'subscription_plans seed must include product_id $productId',
    );
  }
}

void _validateIntegrityGuards(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final index in [
    'drive_scores_drive_session_id_uidx',
    'purchase_verifications_provider_tx_uidx',
    'user_subscriptions_user_plan_uidx',
    'ranking_update_jobs_active_period_uidx',
    'user_coupons_user_coupon_uidx',
    'edge_function_idempotency_user_function_idx',
    'privacy_requests_active_type_uidx',
  ]) {
    check(
      'supabase/migrations/$index',
      sql.contains(index),
      'integrity guard $index is missing',
    );
  }

  check(
    'supabase/migrations/edge_function_idempotency_keys',
    RegExp(
      r'unique\s*\(\s*user_id\s*,\s*function_name\s*,\s*idempotency_key\s*\)',
      caseSensitive: false,
    ).hasMatch(sql),
    'edge_function_idempotency_keys must be unique by user/function/key',
  );
  check(
    'supabase/migrations/ranking_update_jobs',
    sql.toLowerCase().contains("where status in ('pending', 'running')"),
    'ranking_update_jobs must dedupe active jobs by period',
  );
  check(
    'supabase/migrations/custom_vehicle_requests',
    sql
            .toLowerCase()
            .contains('user_vehicle_id uuid references public.user_vehicles') &&
        sql
            .toLowerCase()
            .contains('custom_vehicle_requests_user_vehicle_idx') &&
        sql.toLowerCase().contains('generation_name text not null default') &&
        sql.toLowerCase().contains('generation_code text not null default') &&
        sql
            .toLowerCase()
            .contains('custom_vehicle_requests_generation_code_idx'),
    'custom_vehicle_requests must link review rows to user_vehicles and store generation fields',
  );
  check(
    'supabase/migrations/custom_vehicle_requests_self_insert',
    sql.toLowerCase().contains('custom_vehicle_requests_self_insert') &&
        sql.toLowerCase().contains('user_vehicle_id is not null') &&
        sql.toLowerCase().contains('from public.user_vehicles uv') &&
        sql.toLowerCase().contains('uv.user_id = auth.uid()'),
    'custom_vehicle_requests insert policy must require owned user_vehicles',
  );
  check(
    'supabase/migrations/privacy_requests',
    sql.toLowerCase().contains('privacy_requests_active_type_uidx') &&
        sql.toLowerCase().contains("where status in ('open', 'review')"),
    'privacy_requests must dedupe active requests by user and request type',
  );
}

void _validateProfileSelfWriteHardening(
  void Function(String scope, bool condition, String message) check,
) {
  final migration =
      File('supabase/migrations/202606060023_profile_self_write_hardening.sql');
  check(
    migration.path,
    migration.existsSync(),
    'profile self-write hardening migration is missing',
  );
  if (!migration.existsSync()) {
    return;
  }

  final source = migration.readAsStringSync().toLowerCase();
  for (final token in [
    'drop policy if exists "profiles_insert_self"',
    'create policy "profiles_insert_self" on public.profiles',
    'coalesce(is_admin, false) = false',
    'coalesce(is_premium, false) = false',
    'coalesce(total_score, 0) = 0',
    'coalesce(season_score, 0) = 0',
    'coalesce(current_streak, 0) = 0',
    'coalesce(best_streak, 0) = 0',
    "coalesce(nullif(tier, ''), 'bronze i') = 'bronze i'",
    'revoke insert on public.profiles from anon, authenticated',
    'revoke update on public.profiles from anon, authenticated',
    'grant insert (',
    'grant update (',
    'on public.profiles to authenticated',
  ]) {
    check(
      migration.path,
      source.contains(token),
      'profile self-write hardening must keep "$token"',
    );
  }

  final insertColumns = _profileGrantColumns(source, 'insert');
  final updateColumns = _profileGrantColumns(source, 'update');
  check(
    migration.path,
    insertColumns.isNotEmpty && updateColumns.isNotEmpty,
    'profile self-write hardening must grant explicit profile column lists',
  );

  for (final sensitiveColumn in [
    'tier',
    'total_score',
    'season_score',
    'current_streak',
    'best_streak',
    'is_premium',
    'is_admin',
    'created_at',
  ]) {
    check(
      migration.path,
      !insertColumns.contains(sensitiveColumn),
      'profile insert grant must not allow client-set $sensitiveColumn',
    );
    check(
      migration.path,
      !updateColumns.contains(sensitiveColumn),
      'profile update grant must not allow client-set $sensitiveColumn',
    );
  }
}

void _validateVehicleCatalogSeed(
  void Function(String scope, bool condition, String message) check,
) {
  final schemaSql = File(
    'supabase/migrations/202606060001_google_vehicle_leagues.sql',
  ).readAsStringSync();
  final completionSql = File(
    'supabase/migrations/202606060004_vehicle_catalog_completion.sql',
  ).readAsStringSync();
  final qualitySql = File(
    'supabase/migrations/202606090001_powertrain_quality_schema.sql',
  ).readAsStringSync();
  final seedFile = File(
    'supabase/migrations/202606060002_vehicle_catalog_seed.sql',
  );
  final seedSql = seedFile.existsSync() ? seedFile.readAsStringSync() : '';

  check(
    'supabase/migrations/vehicle_variants',
    schemaSql.contains('efficiency_unit text not null default'),
    'vehicle_variants must define efficiency_unit before catalog seed runs',
  );
  check(
    'supabase/migrations/fuel_leagues',
    schemaSql.contains('insert into public.fuel_leagues') &&
        schemaSql.contains("'gasoline'") &&
        schemaSql.contains("'electric'") &&
        schemaSql.contains("'other'"),
    'fuel_leagues defaults must be seeded before vehicle_variants catalog seed runs',
  );
  check(
    'supabase/migrations/vehicle_catalog_view',
    completionSql.contains('drop view if exists public.vehicle_catalog_view') &&
        completionSql.indexOf(
              'drop view if exists public.vehicle_catalog_view',
            ) <
            completionSql.indexOf(
              'create or replace view public.vehicle_catalog_view',
            ),
    'vehicle_catalog_view must be dropped before replacing with changed columns',
  );
  check(
    'supabase/migrations/vehicle_catalog_view',
    qualitySql.contains('drop view if exists public.vehicle_catalog_view') &&
        qualitySql
            .contains('create or replace view public.vehicle_catalog_view') &&
        qualitySql.contains('vv.source_status') &&
        qualitySql.contains('vv.confidence_score') &&
        qualitySql.contains('vv.is_selectable') &&
        qualitySql.contains('vv.is_deprecated'),
    'vehicle_catalog_view must expose vehicle quality columns after powertrain quality migration',
  );
  check(
    'supabase/migrations/vehicle_catalog_seed',
    seedSql.contains('year-hyundai-001-kr-2015') &&
        seedSql.contains('variant-hyundai-avante-2015-gasoline'),
    'vehicle catalog migration seed must include 2015 powertrain rows',
  );
  check(
    'supabase/migrations/vehicle_catalog_seed',
    seedSql.contains('model-hyundai-001-kr') &&
        seedSql.contains('model-hyundai-avante-n-kr') &&
        seedSql.contains('model-hyundai-avante-sport-kr'),
    'vehicle catalog migration seed must include current Hyundai model ids',
  );
  check(
    'supabase/migrations/vehicle_catalog_seed',
    !seedSql.contains("'model-avante'") &&
        !seedSql.contains("'variant-avante-2024-gasoline'"),
    'vehicle catalog migration seed must not contain stale compact Avante rows',
  );
  check(
    'supabase/migrations/vehicle_catalog_seed',
    !seedSql.contains('variant-hyundai-avante-2026-g16-smart') &&
        !seedSql.contains('variant-hyundai-avante-2026-g16-modern') &&
        !seedSql.contains('variant-hyundai-avante-2026-g16-inspiration') &&
        !seedSql.contains('variant-hyundai-avante-2026-g16-nline') &&
        !seedSql.contains('variant-hyundai-avante-2026-hybrid-modern') &&
        !seedSql.contains('variant-hyundai-avante-2026-lpi-modern'),
    'vehicle catalog migration seed must not contain sales-trim Avante rows',
  );
  check(
    'supabase/migrations/vehicle_catalog_seed',
    RegExp(r"^  \('variant-", multiLine: true).allMatches(seedSql).length >=
        2800,
    'vehicle catalog migration seed must include the full generated variant set',
  );
}

bool _hasCreateTable(String sql, String table) {
  return RegExp(
    'create\\s+table\\s+(if\\s+not\\s+exists\\s+)?public\\.$table\\b',
    caseSensitive: false,
  ).hasMatch(sql);
}

Set<String> _createdPublicTables(String sql) {
  final tables = <String>{};
  final regex = RegExp(
    r'create\s+table\s+(if\s+not\s+exists\s+)?public\.([a-zA-Z0-9_]+)\b',
    caseSensitive: false,
  );
  for (final match in regex.allMatches(sql)) {
    tables.add(match.group(2)!.toLowerCase());
  }
  return tables;
}

bool _hasRls(String sql, String table) {
  return RegExp(
    'alter\\s+table\\s+public\\.$table\\s+enable\\s+row\\s+level\\s+security',
    caseSensitive: false,
  ).hasMatch(sql);
}

bool _hasPolicy(String sql, String table, String policy) {
  return RegExp(
    'create\\s+policy\\s+"$policy"\\s+on\\s+public\\.$table\\b',
    caseSensitive: false,
  ).hasMatch(sql);
}

bool _hasView(String sql, String view) {
  return RegExp(
    'create\\s+or\\s+replace\\s+view\\s+public\\.$view\\b',
    caseSensitive: false,
  ).hasMatch(sql);
}

bool _hasFunction(String sql, String functionName) {
  return RegExp(
    'create\\s+or\\s+replace\\s+function\\s+public\\.$functionName\\b',
    caseSensitive: false,
  ).hasMatch(sql);
}

String _viewSql(String sql, String view) {
  final lower = sql.toLowerCase();
  final start = lower.indexOf('create or replace view public.$view');
  if (start < 0) return '';
  final end = sql.indexOf(';', start);
  return end < 0 ? sql.substring(start) : sql.substring(start, end + 1);
}

String _functionSql(String sql, String functionName) {
  final lower = sql.toLowerCase();
  final start =
      lower.indexOf('create or replace function public.$functionName');
  if (start < 0) return '';
  final next = lower.indexOf('\ncreate or replace function public.', start + 1);
  final end = next < 0 ? sql.length : next;
  return sql.substring(start, end);
}

Set<String> _profileGrantColumns(String sql, String verb) {
  final match = RegExp(
    'grant\\s+$verb\\s*\\(([\\s\\S]*?)\\)\\s+on\\s+public\\.profiles\\s+to\\s+authenticated',
    caseSensitive: false,
  ).firstMatch(sql);
  final body = match?.group(1);
  if (body == null) {
    return const {};
  }
  return body
      .split(',')
      .map((column) => column.trim().replaceAll(RegExp(r'\s+'), ' '))
      .where((column) => column.isNotEmpty)
      .toSet();
}

List<File> _migrationFiles() {
  final directory = Directory('supabase/migrations');
  if (!directory.existsSync()) return const [];
  return directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

const _requiredTables = [
  'profiles',
  'app_consents',
  'consent_logs',
  'vehicles',
  'fuel_leagues',
  'vehicle_manufacturers',
  'vehicle_models',
  'vehicle_generations',
  'vehicle_model_years',
  'vehicle_generation_years',
  'vehicle_variants',
  'user_vehicles',
  'league_memberships',
  'custom_vehicle_requests',
  'drive_sessions',
  'drive_points',
  'drive_scores',
  'rankings',
  'ranking_update_jobs',
  'battles',
  'battle_participants',
  'seasons',
  'season_missions',
  'mission_progress',
  'badges',
  'user_badges',
  'achievements',
  'user_achievements',
  'crews',
  'crew_members',
  'notifications',
  'sponsors',
  'sponsor_challenges',
  'advertisements',
  'ad_rewards',
  'coupons',
  'user_coupons',
  'subscription_plans',
  'user_subscriptions',
  'purchase_verifications',
  'fraud_reviews',
  'report_items',
  'support_tickets',
  'support_ticket_messages',
  'app_settings',
  'app_release_notes',
  'analytics_events',
  'user_local_sync_logs',
  'vehicle_catalog_change_logs',
  'admin_action_logs',
  'admin_audit_logs',
  'privacy_requests',
  'account_deletion_requests',
  'data_export_requests',
  'auth_audit_logs',
  'edge_function_idempotency_keys',
];

const _requiredPolicies = {
  'profiles': [
    'profiles_select_self',
    'profiles_update_self',
    'profiles_insert_self',
  ],
  'app_consents': ['consents_self'],
  'consent_logs': [
    'consent_logs_self_insert',
    'consent_logs_self_select_or_admin',
  ],
  'vehicles': ['vehicles_self'],
  'fuel_leagues': ['fuel_leagues_read_all'],
  'vehicle_manufacturers': [
    'vehicle_manufacturers_read_all',
    'vehicle_manufacturers_admin_write',
  ],
  'vehicle_models': [
    'vehicle_models_read_all',
    'vehicle_models_admin_write',
  ],
  'vehicle_generations': [
    'vehicle_generations_read_all',
    'vehicle_generations_admin_write',
  ],
  'vehicle_model_years': [
    'vehicle_model_years_read_all',
    'vehicle_model_years_admin_write',
  ],
  'vehicle_generation_years': [
    'vehicle_generation_years_read_all',
    'vehicle_generation_years_admin_write',
  ],
  'vehicle_variants': [
    'vehicle_variants_read_all',
    'vehicle_variants_admin_write',
  ],
  'user_vehicles': ['user_vehicles_self'],
  'league_memberships': ['league_memberships_self'],
  'custom_vehicle_requests': [
    'custom_vehicle_requests_self_select_or_admin',
    'custom_vehicle_requests_self_insert',
    'custom_vehicle_requests_admin_update',
    'custom_vehicle_requests_admin_delete',
  ],
  'drive_sessions': ['drive_sessions_self'],
  'drive_points': ['drive_points_private_self'],
  'drive_scores': ['drive_scores_self'],
  'rankings': ['rankings_read_all'],
  'ranking_update_jobs': [
    'ranking_update_jobs_admin_select',
    'ranking_update_jobs_admin_write',
  ],
  'battles': ['battles_read_all', 'battles_create_auth'],
  'battle_participants': ['battle_participants_member'],
  'seasons': ['seasons_read_all'],
  'season_missions': ['season_missions_read_all'],
  'mission_progress': ['mission_progress_self'],
  'badges': ['badges_read_all', 'badges_admin_write'],
  'user_badges': ['user_badges_self'],
  'achievements': ['achievements_read_all', 'achievements_admin_write'],
  'user_achievements': ['user_achievements_self'],
  'crews': ['crews_member_select', 'crews_admin_write'],
  'crew_members': ['crew_members_member_select', 'crew_members_admin_write'],
  'notifications': ['notifications_self'],
  'sponsors': ['sponsors_active_read', 'sponsors_admin_write'],
  'sponsor_challenges': [
    'sponsor_challenges_active_read',
    'sponsor_challenges_admin_write',
  ],
  'advertisements': [
    'advertisements_active_read',
    'advertisements_admin_write',
  ],
  'ad_rewards': ['ad_rewards_self_select', 'ad_rewards_admin_select'],
  'coupons': ['coupons_active_read', 'coupons_admin_write'],
  'user_coupons': ['user_coupons_self'],
  'subscription_plans': [
    'subscription_plans_public_read',
    'subscription_plans_admin_write',
  ],
  'user_subscriptions': ['subscriptions_self'],
  'purchase_verifications': ['purchase_verifications_self_select'],
  'fraud_reviews': ['fraud_reviews_self'],
  'report_items': [
    'reports_create_self',
    'reports_read_self',
    'reports_admin_select',
    'reports_admin_update',
  ],
  'support_tickets': [
    'support_tickets_self_select_or_admin',
    'support_tickets_self_insert',
    'support_tickets_self_update_or_admin',
  ],
  'support_ticket_messages': [
    'support_messages_ticket_participant_select',
    'support_messages_ticket_participant_insert',
  ],
  'app_settings': ['app_settings_public_read', 'app_settings_admin_write'],
  'app_release_notes': [
    'app_release_notes_public_read',
    'app_release_notes_admin_write',
  ],
  'analytics_events': [
    'analytics_events_self_insert',
    'analytics_events_admin_select',
  ],
  'user_local_sync_logs': ['user_local_sync_logs_self'],
  'vehicle_catalog_change_logs': ['vehicle_catalog_change_logs_admin'],
  'admin_action_logs': [
    'admin_action_logs_admin_select',
    'admin_action_logs_admin_insert',
  ],
  'admin_audit_logs': [
    'admin_audit_logs_admin_select',
    'admin_audit_logs_admin_insert',
  ],
  'privacy_requests': [
    'privacy_requests_self_select_or_admin',
    'privacy_requests_self_insert',
    'privacy_requests_admin_update',
  ],
  'account_deletion_requests': [
    'account_deletion_requests_self_select',
    'account_deletion_requests_self_insert',
    'account_deletion_requests_admin_select',
    'account_deletion_requests_admin_update',
  ],
  'data_export_requests': [
    'data_export_requests_self_select',
    'data_export_requests_self_insert',
    'data_export_requests_admin_select',
    'data_export_requests_admin_update',
  ],
  'auth_audit_logs': [
    'auth_audit_logs_self_select',
    'auth_audit_logs_admin_select',
  ],
  'edge_function_idempotency_keys': [
    'edge_function_idempotency_self_select',
    'edge_function_idempotency_admin_select',
  ],
};

const _requiredPublicAppSettings = [
  'reward_ad_daily_limit',
  'reward_ads_enabled',
  'new_user_ad_protection_days',
  'season_ending_soon_days',
  'official_drive_min_distance_km',
  'official_drive_min_duration_seconds',
  'abnormal_speed_kmh',
  'allow_custom_vehicle_official_ranking',
  'split_plug_in_hybrid_league',
  'friendly_battle_enabled',
  'premium_price_label',
  'coupons_enabled',
  'fairness_guidelines',
];

const _requiredIapProductIds = [
  'fuel_arena_premium_monthly',
  'fuel_arena_premium_yearly',
  'fuel_arena_season_pass',
  'fuel_arena_premium_bundle',
];
