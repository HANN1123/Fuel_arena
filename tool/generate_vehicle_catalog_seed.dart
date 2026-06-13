import 'dart:convert';
import 'dart:io';

void main() {
  final manufacturers = _manufacturers();
  final models = <Map<String, Object?>>[];
  final years = <Map<String, Object?>>[];
  final variants = <Map<String, Object?>>[];
  final generations = _generationSeeds();

  var modelSort = 0;
  for (final manufacturer in manufacturers) {
    final manufacturerId = manufacturer['id']! as String;
    final manufacturerName = manufacturer['name_ko']! as String;
    final modelSeeds = manufacturer['models']! as List<ModelSeed>;
    var sortOrder = 10;
    for (final seed in modelSeeds) {
      final modelId = seed.id ??
          'model-${manufacturerId.substring(2)}-${_slug(++modelSort, seed.nameKo)}';
      models.add({
        'id': modelId,
        'manufacturer_id': manufacturerId,
        'name_ko': seed.nameKo,
        'name_en': seed.nameEn,
        'body_type': seed.bodyType,
        'available_fuel_types': seed.fuelTypes,
        'is_popular': seed.isPopular,
        'sort_order': seed.sortOrder ?? sortOrder,
      });
      if (seed.sortOrder == null) {
        sortOrder += 10;
      }

      final startYear = seed.firstYear < 2015 ? 2015 : seed.firstYear;
      for (var year = seed.lastYear; year >= startYear; year -= 1) {
        final yearId = 'year-${modelId.substring(6)}-$year';
        final generationId = _generationIdFor(modelId, year);
        years.add({
          'id': yearId,
          'model_id': modelId,
          'year': year,
          if (generationId != null) 'generation_id': generationId,
          if (generationId != null)
            'production_year_label': _generationPeriodLabel(generationId),
        });
        for (final fuelType in seed.fuelTypesForYear(year)) {
          final overrides = _officialOverrides(modelId, year, fuelType);
          final powertrains =
              overrides.isEmpty ? <OfficialPowertrain?>[null] : overrides;
          for (var index = 0; index < powertrains.length; index += 1) {
            final override = powertrains[index];
            final variantId = override?.id ??
                'variant-${modelId.substring(6)}-$year-${_fuelLeagueFor(fuelType)}';
            final isLockedOfficialLineup = manufacturerName == 'BMW' ||
                _lockedOfficialLineupModelIds.contains(modelId);
            final overrideHasVerifiedSource =
                override?.sourceStatus == 'verified_official' ||
                    override?.sourceStatus == 'verified_admin' ||
                    override?.isVerified == true;
            final locksUnverifiedOverride = isLockedOfficialLineup &&
                override != null &&
                !overrideHasVerifiedSource &&
                (override.sourceStatus == null ||
                    override.sourceStatus == 'unverified');
            final locksVariantSpec = override != null &&
                (locksUnverifiedOverride ||
                    (override.sourceStatus == 'pending_review' &&
                        override.officialEfficiency == null &&
                        override.displacementCc == null &&
                        override.batteryKwh == null));
            final sourceStatus = locksUnverifiedOverride
                ? 'pending_review'
                : override?.sourceStatus ??
                    (isLockedOfficialLineup ? 'pending_review' : 'unverified');
            variants.add({
              'id': variantId,
              'model_year_id': yearId,
              if (generationId != null) 'generation_id': generationId,
              'manufacturer_name': manufacturerName,
              'model_name': seed.nameKo,
              'year': year,
              'trim_name': locksUnverifiedOverride
                  ? '공식 제원 검수 대기'
                  : override?.trimName ??
                      (isLockedOfficialLineup
                          ? '공식 제원 검수 대기'
                          : _powertrainLabelFor(fuelType, seed.vehicleClass)),
              'engine_name': locksUnverifiedOverride
                  ? 'Pending official specification review'
                  : override?.engineName ??
                      (isLockedOfficialLineup
                          ? 'Pending official specification review'
                          : _engineNameFor(fuelType, seed.vehicleClass)),
              'fuel_type': fuelType,
              'displacement_cc': locksUnverifiedOverride
                  ? null
                  : override?.displacementCc ??
                      (isLockedOfficialLineup || locksVariantSpec
                          ? null
                          : _displacementCcFor(fuelType, seed.vehicleClass)),
              'battery_kwh': locksUnverifiedOverride
                  ? null
                  : override?.batteryKwh ??
                      (isLockedOfficialLineup || locksVariantSpec
                          ? null
                          : _batteryKwhFor(fuelType, seed.vehicleClass)),
              'drivetrain': locksUnverifiedOverride
                  ? '검수 대기'
                  : override?.drivetrain ??
                      (isLockedOfficialLineup
                          ? '검수 대기'
                          : _drivetrainFor(modelId, fuelType, year)),
              'transmission': locksUnverifiedOverride
                  ? '검수 대기'
                  : override?.transmission ??
                      (isLockedOfficialLineup
                          ? '검수 대기'
                          : _transmissionFor(fuelType)),
              'official_efficiency':
                  locksUnverifiedOverride ? null : override?.officialEfficiency,
              'efficiency_unit':
                  override?.efficiencyUnit ?? _efficiencyUnitFor(fuelType),
              'vehicle_class': override?.vehicleClass ?? seed.vehicleClass,
              'fuel_league': _fuelLeagueFor(fuelType),
              'is_verified': locksUnverifiedOverride
                  ? false
                  : override?.isVerified ?? false,
              'source_status': sourceStatus,
              if (!locksUnverifiedOverride && override?.sourceName != null)
                'source_name': override!.sourceName,
              if (!locksUnverifiedOverride && override?.sourceUrl != null)
                'source_url': override!.sourceUrl,
              if (!locksUnverifiedOverride && override?.sourceFileName != null)
                'source_file_name': override!.sourceFileName,
              if (!locksUnverifiedOverride && override?.lastVerifiedAt != null)
                'last_verified_at': override!.lastVerifiedAt,
              'confidence_score': locksUnverifiedOverride
                  ? 0.1
                  : override?.confidenceScore ??
                      (isLockedOfficialLineup ? 0.1 : 0.0),
              'is_selectable': locksUnverifiedOverride
                  ? false
                  : override?.isSelectable ??
                      (overrideHasVerifiedSource
                          ? true
                          : !isLockedOfficialLineup),
              'is_deprecated': false,
              if (variantId == 'variant-hyundai-avante-2024-gasoline')
                'valid_from_year': 2020,
              if (variantId == 'variant-kia-k3-gt-2024-16t-7dct')
                'valid_from_year': 2018,
              if (variantId == 'variant-kia-k3-gt-2024-16t-7dct')
                'valid_to_year': 2024,
              'sort_order':
                  override?.sortOrder ?? _fuelSortOrderFor(fuelType) + index,
            });
          }
        }
      }
    }
  }

  final data = {
    'schema_version': 1,
    'generated_at': DateTime.utc(2026, 6, 6).toIso8601String(),
    'notes':
        '2008-2026 연식을 제조사 > 모델 > 연식 > 파워트레인 단위로 구조화한다. 공식 효율을 확인하지 못한 항목은 official_efficiency를 null로 둔다.',
    'manufacturers': manufacturers.map((item) {
      final copy = Map<String, Object?>.from(item)..remove('models');
      return copy;
    }).toList(),
    'models': models,
    'generations': generations,
    'years': years,
    'variants': variants,
  };

  const encoder = JsonEncoder.withIndent('  ');
  File('assets/data/vehicle_catalog_kr_seed.json').writeAsStringSync(
    encoder.convert(data),
  );

  final csvFile = File('assets/data/vehicle_catalog_kr_sample.csv');
  csvFile.createSync(recursive: true);
  final csv = StringBuffer();
  csv.writeln([
    'manufacturer_id',
    'manufacturer_name_ko',
    'model_id',
    'model_name_ko',
    'year',
    'trim_name',
    'fuel_type',
    'fuel_league',
    'vehicle_class',
    'efficiency_unit',
    'official_efficiency',
    'is_verified',
    'source_status',
    'is_selectable',
  ].join(','));
  final modelByYearId = {
    for (final year in years) year['id'] as String: year['model_id'] as String,
  };
  final modelById = {
    for (final model in models) model['id'] as String: model,
  };
  final manufacturerById = {
    for (final manufacturer in manufacturers)
      manufacturer['id'] as String: manufacturer,
  };
  for (final variant in variants.take(200)) {
    final model = modelById[modelByYearId[variant['model_year_id']]];
    final manufacturer = manufacturerById[model?['manufacturer_id']];
    csv.writeln([
      manufacturer?['id'] ?? '',
      manufacturer?['name_ko'] ?? variant['manufacturer_name'],
      model?['id'] ?? '',
      variant['model_name'],
      variant['year'],
      variant['trim_name'],
      variant['fuel_type'],
      variant['fuel_league'],
      variant['vehicle_class'],
      variant['efficiency_unit'],
      variant['official_efficiency'],
      variant['is_verified'],
      variant['source_status'],
      variant['is_selectable'],
    ].map(_csvEscape).join(','));
  }
  csvFile.writeAsStringSync(csv.toString());

  stdout.writeln(
    'generated ${manufacturers.length} manufacturers, '
    '${models.length} models, ${years.length} years, ${variants.length} variants',
  );
}

String _csvEscape(Object? value) {
  final text = value?.toString() ?? '';
  if (text.contains(',') || text.contains('"') || text.contains('\n')) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

List<Map<String, Object?>> _generationSeeds() {
  return [
    {
      'id': 'generation-hyundai-avante-ad',
      'model_id': 'model-hyundai-001-kr',
      'generation_order': 6,
      'generation_name_ko': '6세대',
      'generation_name_en': 'Sixth generation',
      'generation_code': 'AD',
      'platform_code': 'AD',
      'start_year': 2015,
      'start_month': null,
      'end_year': 2020,
      'end_month': 4,
      'display_period': '2015~2020.4',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.68,
      'source_name':
          'Hyundai Motor official Avante history and software version list',
      'source_url':
          'https://update.hyundai.com/KR/KO/updateNoticeView/software-version',
      'source_file_name': null,
      'last_verified_at': '2026-06-13',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2019; year += 1)
          'year-hyundai-001-kr-$year',
      ],
    },
    {
      'id': 'generation-hyundai-avante-cn7',
      'model_id': 'model-hyundai-001-kr',
      'generation_order': 7,
      'generation_name_ko': '7세대',
      'generation_name_en': 'Seventh generation',
      'generation_code': 'CN7',
      'platform_code': '',
      'start_year': 2020,
      'start_month': 4,
      'end_year': null,
      'end_month': null,
      'display_period': '2020.4~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'unverified',
      'confidence_score': 0.35,
      'source_name': null,
      'source_url': null,
      'source_file_name': null,
      'last_verified_at': null,
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2020; year <= 2026; year += 1)
          'year-hyundai-001-kr-$year',
      ],
    },
    {
      'id': 'generation-hyundai-ioniq5-ne',
      'model_id': 'model-hyundai-009-5',
      'generation_order': 1,
      'generation_name_ko': '1세대',
      'generation_name_en': 'First generation',
      'generation_code': 'NE/NE PE',
      'platform_code': 'E-GMP',
      'start_year': 2021,
      'start_month': 2,
      'end_year': null,
      'end_month': null,
      'display_period': '2021.2~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'Hyundai Motor IONIQ 5 world premiere',
      'source_url':
          'https://www.hyundai.com/worldwide/en/newsroom/detail/hyundai-ioniq-5-redefines-electric-mobility-lifestyle-0000000551',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2021; year <= 2026; year += 1)
          'year-hyundai-009-5-$year',
      ],
    },
    {
      'id': 'generation-hyundai-ioniq6-ce',
      'model_id': 'model-hyundai-010-6',
      'generation_order': 1,
      'generation_name_ko': '1세대',
      'generation_name_en': 'First generation',
      'generation_code': 'CE/CE PE',
      'platform_code': 'E-GMP',
      'start_year': 2022,
      'start_month': 7,
      'end_year': null,
      'end_month': null,
      'display_period': '2022.7~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'Hyundai Motor IONIQ 6 world premiere',
      'source_url':
          'https://www.hyundai.com/worldwide/en/newsroom/detail/hyundai-motor-debuts-ioniq-6-electrified-streamliner-with-610km-range-and-innovative-personal-space--0000016850',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2022; year <= 2026; year += 1)
          'year-hyundai-010-6-$year',
      ],
    },
    {
      'id': 'generation-hyundai-sonata-lf',
      'model_id': 'model-hyundai-002-kr',
      'generation_order': 7,
      'generation_name_ko': '7세대',
      'generation_name_en': 'Seventh generation',
      'generation_code': 'LF/LF PE',
      'platform_code': 'LF',
      'start_year': 2014,
      'start_month': null,
      'end_year': 2019,
      'end_month': null,
      'display_period': '2014~2019',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'Hyundai Motor model history and software version list',
      'source_url':
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/sonata-history',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2018; year += 1)
          'year-hyundai-002-kr-$year',
      ],
    },
    {
      'id': 'generation-hyundai-sonata-dn8',
      'model_id': 'model-hyundai-002-kr',
      'generation_order': 8,
      'generation_name_ko': '8세대',
      'generation_name_en': 'Eighth generation',
      'generation_code': 'DN8/DN8 PE',
      'platform_code': 'DN8',
      'start_year': 2019,
      'start_month': null,
      'end_year': null,
      'end_month': null,
      'display_period': '2019~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'Hyundai Motor model history and software version list',
      'source_url':
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/sonata-history',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2019; year <= 2026; year += 1)
          'year-hyundai-002-kr-$year',
      ],
    },
    {
      'id': 'generation-hyundai-grandeur-hg',
      'model_id': 'model-hyundai-003-kr',
      'generation_order': 5,
      'generation_name_ko': '5세대',
      'generation_name_en': 'Fifth generation',
      'generation_code': 'HG',
      'platform_code': 'HG',
      'start_year': 2011,
      'start_month': null,
      'end_year': 2016,
      'end_month': null,
      'display_period': '2011~2016',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'Hyundai Motor model history and software version list',
      'source_url':
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/grandeur-history',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2016; year += 1)
          'year-hyundai-003-kr-$year',
      ],
    },
    {
      'id': 'generation-hyundai-grandeur-ig',
      'model_id': 'model-hyundai-003-kr',
      'generation_order': 6,
      'generation_name_ko': '6세대',
      'generation_name_en': 'Sixth generation',
      'generation_code': 'IG/IG PE',
      'platform_code': 'IG',
      'start_year': 2016,
      'start_month': null,
      'end_year': 2022,
      'end_month': null,
      'display_period': '2016~2022',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'Hyundai Motor model history and software version list',
      'source_url':
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/grandeur-history',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2017; year <= 2022; year += 1)
          'year-hyundai-003-kr-$year',
      ],
    },
    {
      'id': 'generation-hyundai-grandeur-gn7',
      'model_id': 'model-hyundai-003-kr',
      'generation_order': 7,
      'generation_name_ko': '7세대',
      'generation_name_en': 'Seventh generation',
      'generation_code': 'GN7',
      'platform_code': 'GN7',
      'start_year': 2022,
      'start_month': null,
      'end_year': null,
      'end_month': null,
      'display_period': '2022~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'Hyundai Motor model history and software version list',
      'source_url':
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/grandeur-history',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2023; year <= 2026; year += 1)
          'year-hyundai-003-kr-$year',
      ],
    },
    {
      'id': 'generation-hyundai-tucson-tl',
      'model_id': 'model-hyundai-005-kr',
      'generation_order': 3,
      'generation_name_ko': '3세대',
      'generation_name_en': 'Third generation',
      'generation_code': 'TL/TL PE',
      'platform_code': 'TL',
      'start_year': 2015,
      'start_month': null,
      'end_year': 2020,
      'end_month': null,
      'display_period': '2015~2020',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'Hyundai Motor model history and software version list',
      'source_url':
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/tucson-history',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2019; year += 1)
          'year-hyundai-005-kr-$year',
      ],
    },
    {
      'id': 'generation-hyundai-tucson-nx4',
      'model_id': 'model-hyundai-005-kr',
      'generation_order': 4,
      'generation_name_ko': '4세대',
      'generation_name_en': 'Fourth generation',
      'generation_code': 'NX4/NX4 PE',
      'platform_code': 'NX4',
      'start_year': 2020,
      'start_month': null,
      'end_year': null,
      'end_month': null,
      'display_period': '2020~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'Hyundai Motor model history and software version list',
      'source_url':
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/tucson-history',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2020; year <= 2026; year += 1)
          'year-hyundai-005-kr-$year',
      ],
    },
    {
      'id': 'generation-hyundai-santafe-dm',
      'model_id': 'model-hyundai-006-kr',
      'generation_order': 3,
      'generation_name_ko': '3세대',
      'generation_name_en': 'Third generation',
      'generation_code': 'DM/DM PE',
      'platform_code': 'DM',
      'start_year': 2012,
      'start_month': null,
      'end_year': 2018,
      'end_month': null,
      'display_period': '2012~2018',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'Hyundai Motor model history and software version list',
      'source_url':
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/santafe-history',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2017; year += 1)
          'year-hyundai-006-kr-$year',
      ],
    },
    {
      'id': 'generation-hyundai-santafe-tm',
      'model_id': 'model-hyundai-006-kr',
      'generation_order': 4,
      'generation_name_ko': '4세대',
      'generation_name_en': 'Fourth generation',
      'generation_code': 'TM/TM PE',
      'platform_code': 'TM',
      'start_year': 2018,
      'start_month': null,
      'end_year': 2023,
      'end_month': null,
      'display_period': '2018~2023',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'Hyundai Motor model history and software version list',
      'source_url':
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/santafe-history',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2018; year <= 2022; year += 1)
          'year-hyundai-006-kr-$year',
      ],
    },
    {
      'id': 'generation-hyundai-santafe-mx5',
      'model_id': 'model-hyundai-006-kr',
      'generation_order': 5,
      'generation_name_ko': '5세대',
      'generation_name_en': 'Fifth generation',
      'generation_code': 'MX5',
      'platform_code': 'MX5',
      'start_year': 2023,
      'start_month': null,
      'end_year': null,
      'end_month': null,
      'display_period': '2023~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'Hyundai Motor model history and software version list',
      'source_url':
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/santafe-history',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2023; year <= 2026; year += 1)
          'year-hyundai-006-kr-$year',
      ],
    },
    ..._hyundaiRemainingGenerationSeeds(),
    ..._genesisGenerationSeeds(),
    ..._chevroletGenerationSeeds(),
    ..._renaultGenerationSeeds(),
    ..._kgmGenerationSeeds(),
    ..._volvoGenerationSeeds(),
    ..._kiaGenerationSeeds(),
    ..._mercedesGenerationSeeds(),
    ..._audiGenerationSeeds(),
    ..._remainingManufacturerGenerationSeeds(),
    {
      'id': 'generation-bmw-1series-f20',
      'model_id': 'model-bmw-051-1',
      'generation_order': 2,
      'generation_name_ko': '2세대',
      'generation_name_en': 'Second generation',
      'generation_code': 'F20',
      'platform_code': 'F20',
      'start_year': 2012,
      'start_month': 10,
      'end_year': 2019,
      'end_month': null,
      'display_period': '2012.10~2019',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Korea PressClub 2nd generation 1 Series launch',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0133869KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EB%89%B4-1%EC%8B%9C%EB%A6%AC%EC%A6%88-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2019; year += 1) 'year-bmw-051-1-$year',
      ],
    },
    {
      'id': 'generation-bmw-1series-f40',
      'model_id': 'model-bmw-051-1',
      'generation_order': 3,
      'generation_name_ko': '3세대',
      'generation_name_en': 'Third generation',
      'generation_code': 'F40',
      'platform_code': 'F40',
      'start_year': 2020,
      'start_month': 1,
      'end_year': 2024,
      'end_month': null,
      'display_period': '2020.1~2024',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Korea PressClub 3rd generation 1 Series launch',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0304413KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-3%EC%84%B8%EB%8C%80-%EB%89%B4-1%EC%8B%9C%EB%A6%AC%EC%A6%88-%EA%B5%AD%EB%82%B4-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2020; year <= 2024; year += 1) 'year-bmw-051-1-$year',
      ],
    },
    {
      'id': 'generation-bmw-1series-f70',
      'model_id': 'model-bmw-051-1',
      'generation_order': 4,
      'generation_name_ko': '4세대',
      'generation_name_en': 'Fourth generation',
      'generation_code': 'F70',
      'platform_code': 'F70',
      'start_year': 2024,
      'start_month': 10,
      'end_year': null,
      'end_month': null,
      'display_period': '2024.10~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'BMW Group/Korea PressClub 4th generation 1 Series launch',
      'source_url':
          'https://www.press.bmwgroup.com/global/article/detail/T0443483EN/bmw-1-series-production-launch-at-bmw-group-plant-leipzig?language=en',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2025; year <= 2026; year += 1) 'year-bmw-051-1-$year',
      ],
    },
    {
      'id': 'generation-bmw-2series-coupe-f22',
      'model_id': 'model-bmw-052-2',
      'generation_order': 1,
      'generation_name_ko': '1세대',
      'generation_name_en': 'First generation',
      'generation_code': 'F22',
      'platform_code': 'F22',
      'start_year': 2013,
      'start_month': null,
      'end_year': 2021,
      'end_month': null,
      'display_period': '2013~2021',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.74,
      'source_name': 'BMW Group PressClub Leipzig production list',
      'source_url':
          'https://www.press.bmwgroup.com/global/article/detail/T0448360EN/anniversary%3A-20-years-of-series-production-at-bmw-group-plant-leipzig?language=en',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2021; year += 1) 'year-bmw-052-2-$year',
      ],
    },
    {
      'id': 'generation-bmw-2series-coupe-g42',
      'model_id': 'model-bmw-052-2',
      'generation_order': 2,
      'generation_name_ko': '2세대',
      'generation_name_en': 'Second generation',
      'generation_code': 'G42',
      'platform_code': 'G42',
      'start_year': 2021,
      'start_month': 7,
      'end_year': null,
      'end_month': null,
      'display_period': '2021.7~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Group PressClub all-new 2 Series Coupe',
      'source_url':
          'https://www.press.bmwgroup.com/global/article/detail/T0336854EN/the-all-new-bmw-2-series-coup%C3%A9?language=en',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2022; year <= 2026; year += 1) 'year-bmw-052-2-$year',
      ],
    },
    {
      'id': 'generation-bmw-i4-g26',
      'model_id': 'model-bmw-061-i4',
      'generation_order': 1,
      'generation_name_ko': '1세대',
      'generation_name_en': 'First generation',
      'generation_code': 'G26',
      'platform_code': 'G26',
      'start_year': 2022,
      'start_month': 4,
      'end_year': null,
      'end_month': null,
      'display_period': '2022.4~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.72,
      'source_name': 'BMW Group PressClub Korea i4 release',
      'source_url':
          'https://www.press.bmwgroup.com/korea/photo/detail/P90456990/BMW-Korea-to-officially-release-the-BMW-i4-the-brand%E2%80%99s-first-all-electric-gran-coupe-04-2022?forceSitePreference=DESKTOP',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2022; year <= 2026; year += 1) 'year-bmw-061-i4-$year',
      ],
    },
    {
      'id': 'generation-bmw-3series-f30',
      'model_id': 'model-bmw-053-3',
      'generation_order': 6,
      'generation_name_ko': '6세대',
      'generation_name_en': 'Sixth generation',
      'generation_code': 'F30',
      'platform_code': 'F30',
      'start_year': 2012,
      'start_month': null,
      'end_year': 2018,
      'end_month': null,
      'display_period': '2012~2018',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Korea PressClub 3 Series history',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0264213KO/%EC%95%9E%EC%84%A0-%EA%B8%B0%EC%88%A0%EA%B3%BC-%ED%98%81%EC%8B%A0%EC%9D%84-%EC%9D%B4%EC%96%B4%EC%98%A8-bmw-3%EC%8B%9C%EB%A6%AC%EC%A6%88%EC%9D%98-%EC%97%AD%EC%82%AC?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2018; year += 1) 'year-bmw-053-3-$year',
      ],
    },
    {
      'id': 'generation-bmw-3series-g20',
      'model_id': 'model-bmw-053-3',
      'generation_order': 7,
      'generation_name_ko': '7세대',
      'generation_name_en': 'Seventh generation',
      'generation_code': 'G20',
      'platform_code': 'G20',
      'start_year': 2019,
      'start_month': 3,
      'end_year': null,
      'end_month': null,
      'display_period': '2019.3~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Group PressClub 3 Series G20 launch',
      'source_url':
          'https://www.press.bmwgroup.com/global/article/detail/T0285128EN/the-all-new-bmw-3-series-sedan?language=en',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2019; year <= 2026; year += 1) 'year-bmw-053-3-$year',
      ],
    },
    {
      'id': 'generation-bmw-4series-f32-f33-f36',
      'model_id': 'model-bmw-054-4',
      'generation_order': 1,
      'generation_name_ko': '1세대',
      'generation_name_en': 'First generation',
      'generation_code': 'F32/F33/F36',
      'platform_code': 'F32/F33/F36',
      'start_year': 2013,
      'start_month': 10,
      'end_year': 2020,
      'end_month': null,
      'display_period': '2013.10~2020',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'BMW Korea PressClub 4 Series Coupe launch',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0152484KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EB%89%B4-4%EC%8B%9C%EB%A6%AC%EC%A6%88-%EC%BF%A0%ED%8E%98-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2020; year += 1) 'year-bmw-054-4-$year',
      ],
    },
    {
      'id': 'generation-bmw-4series-g22-g23-g26',
      'model_id': 'model-bmw-054-4',
      'generation_order': 2,
      'generation_name_ko': '2세대',
      'generation_name_en': 'Second generation',
      'generation_code': 'G22/G23/G26',
      'platform_code': 'G22/G23/G26',
      'start_year': 2021,
      'start_month': 2,
      'end_year': null,
      'end_month': null,
      'display_period': '2021.2~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Korea PressClub 4 Series G22/G23 launch',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0325769KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EB%89%B4-4%EC%8B%9C%EB%A6%AC%EC%A6%88-%EA%B5%AD%EB%82%B4-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2021; year <= 2026; year += 1) 'year-bmw-054-4-$year',
      ],
    },
    {
      'id': 'generation-bmw-5series-f10',
      'model_id': 'model-bmw-055-5',
      'generation_order': 6,
      'generation_name_ko': '6세대',
      'generation_name_en': 'Sixth generation',
      'generation_code': 'F10 LCI',
      'platform_code': 'F10',
      'start_year': 2015,
      'start_month': null,
      'end_year': 2016,
      'end_month': null,
      'display_period': '2015~2016',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.66,
      'source_name': 'BMW Korea PressClub F10 LCI 5 Series release',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0233602KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-520d-m-%EC%97%90%EC%96%B4%EB%A1%9C%EB%8B%A4%EC%9D%B4%EB%82%B4%EB%AF%B9-%EC%8A%A4%ED%8E%98%EC%85%9C-%EC%97%90%EB%94%94%EC%85%98-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-13',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2016; year += 1) 'year-bmw-055-5-$year',
      ],
    },
    {
      'id': 'generation-bmw-5series-g30',
      'model_id': 'model-bmw-055-5',
      'generation_order': 7,
      'generation_name_ko': '7세대',
      'generation_name_en': 'Seventh generation',
      'generation_code': 'G30',
      'platform_code': 'G30',
      'start_year': 2017,
      'start_month': null,
      'end_year': 2023,
      'end_month': null,
      'display_period': '2017~2023',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.72,
      'source_name': 'BMW Group PressClub 2017 5 Series release',
      'source_url':
          'https://www.press.bmwgroup.com/usa/article/detail/T0264802EN_US/the-all-new-2017-bmw-5-series%3A-performance-redefined?language=en_US',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2017; year <= 2023; year += 1) 'year-bmw-055-5-$year',
      ],
    },
    {
      'id': 'generation-bmw-5series-g60',
      'model_id': 'model-bmw-055-5',
      'generation_order': 8,
      'generation_name_ko': '8세대',
      'generation_name_en': 'Eighth generation',
      'generation_code': 'G60',
      'platform_code': 'G60',
      'start_year': 2023,
      'start_month': 10,
      'end_year': null,
      'end_month': null,
      'display_period': '2023.10~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Korea PressClub 5 Series G60 release',
      'source_url':
          'https://www.press.bmwgroup.com/korea/photo/detail/P90526770/BMW-Korea-to-release-the-next-generation-premium-sedan-the-new-BMW-5-Series-for-the-first-time-in-the?forceSitePreference=DESKTOP',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2024; year <= 2026; year += 1) 'year-bmw-055-5-$year',
      ],
    },
    {
      'id': 'generation-bmw-7series-g11-g12',
      'model_id': 'model-bmw-056-7',
      'generation_order': 6,
      'generation_name_ko': '6세대',
      'generation_name_en': 'Sixth generation',
      'generation_code': 'G11/G12',
      'platform_code': 'G11/G12',
      'start_year': 2015,
      'start_month': 10,
      'end_year': 2022,
      'end_month': null,
      'display_period': '2015.10~2022',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Korea PressClub 6th generation 7 Series launch',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0239522KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-6%EC%84%B8%EB%8C%80-%EB%89%B4-7%EC%8B%9C%EB%A6%AC%EC%A6%88-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2022; year += 1) 'year-bmw-056-7-$year',
      ],
    },
    {
      'id': 'generation-bmw-7series-g70',
      'model_id': 'model-bmw-056-7',
      'generation_order': 7,
      'generation_name_ko': '7세대',
      'generation_name_en': 'Seventh generation',
      'generation_code': 'G70',
      'platform_code': 'G70',
      'start_year': 2022,
      'start_month': 12,
      'end_year': null,
      'end_month': null,
      'display_period': '2022.12~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Korea PressClub 7 Series G70 launch',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0407078KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EC%83%88%EB%A1%9C%EC%9A%B4-%EC%B0%A8%EC%9B%90%EC%9D%98-%EB%9F%AD%EC%85%94%EB%A6%AC-%ED%94%8C%EB%9E%98%EA%B7%B8%EC%8B%AD-%EC%84%B8%EB%8B%A8-%EB%89%B4-7%EC%8B%9C%EB%A6%AC%EC%A6%88%E2%80%99-%EA%B5%AD%EB%82%B4-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2023; year <= 2026; year += 1) 'year-bmw-056-7-$year',
      ],
    },
    {
      'id': 'generation-bmw-x1-e84',
      'model_id': 'model-bmw-057-x1',
      'generation_order': 1,
      'generation_name_ko': '1세대',
      'generation_name_en': 'First generation',
      'generation_code': 'E84',
      'platform_code': 'E84',
      'start_year': 2010,
      'start_month': 2,
      'end_year': 2015,
      'end_month': null,
      'display_period': '2010.2~2015',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'BMW Korea PressClub X1 launch',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0077953KO/%EC%84%B8%EA%B3%84-%EC%B5%9C%EC%B4%88-%ED%94%84%EB%A6%AC%EB%AF%B8%EC%97%84-%EC%BB%B4%ED%8C%A9%ED%8A%B8-sav-bmw-%EC%BD%94%EB%A6%AC%EC%95%84-bmw-x1-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': ['year-bmw-057-x1-2015'],
    },
    {
      'id': 'generation-bmw-x1-f48',
      'model_id': 'model-bmw-057-x1',
      'generation_order': 2,
      'generation_name_ko': '2세대',
      'generation_name_en': 'Second generation',
      'generation_code': 'F48',
      'platform_code': 'F48',
      'start_year': 2016,
      'start_month': 2,
      'end_year': 2022,
      'end_month': null,
      'display_period': '2016.2~2022',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Korea PressClub 2nd generation X1 launch',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0258265KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-2%EC%84%B8%EB%8C%80-%EB%89%B4-x1-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2016; year <= 2022; year += 1) 'year-bmw-057-x1-$year',
      ],
    },
    {
      'id': 'generation-bmw-x1-u11',
      'model_id': 'model-bmw-057-x1',
      'generation_order': 3,
      'generation_name_ko': '3세대',
      'generation_name_en': 'Third generation',
      'generation_code': 'U11',
      'platform_code': 'U11',
      'start_year': 2023,
      'start_month': 3,
      'end_year': null,
      'end_month': null,
      'display_period': '2023.3~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Korea PressClub New X1 and iX1 launch',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0412647KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%ED%94%84%EB%A6%AC%EB%AF%B8%EC%97%84-%EC%86%8C%ED%98%95-sav-%EB%89%B4-x1-%EB%B0%8F-%EB%89%B4-ix1-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2023; year <= 2026; year += 1) 'year-bmw-057-x1-$year',
      ],
    },
    {
      'id': 'generation-bmw-x3-f25',
      'model_id': 'model-bmw-058-x3',
      'generation_order': 2,
      'generation_name_ko': '2세대',
      'generation_name_en': 'Second generation',
      'generation_code': 'F25',
      'platform_code': 'F25',
      'start_year': 2011,
      'start_month': null,
      'end_year': 2017,
      'end_month': null,
      'display_period': '2011~2017',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'BMW Korea PressClub New X3 launch note',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0192351KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EB%89%B4-x3-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2017; year += 1) 'year-bmw-058-x3-$year',
      ],
    },
    {
      'id': 'generation-bmw-x3-g01',
      'model_id': 'model-bmw-058-x3',
      'generation_order': 3,
      'generation_name_ko': '3세대',
      'generation_name_en': 'Third generation',
      'generation_code': 'G01',
      'platform_code': 'G01',
      'start_year': 2017,
      'start_month': 11,
      'end_year': 2024,
      'end_month': null,
      'display_period': '2017.11~2024',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Korea PressClub 3rd generation X3 launch',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0276123KO/bmw-%EA%B7%B8%EB%A3%B9-%EC%BD%94%EB%A6%AC%EC%95%84-3%EC%84%B8%EB%8C%80-%EB%89%B4-x3-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2018; year <= 2024; year += 1) 'year-bmw-058-x3-$year',
      ],
    },
    {
      'id': 'generation-bmw-x3-g45',
      'model_id': 'model-bmw-058-x3',
      'generation_order': 4,
      'generation_name_ko': '4세대',
      'generation_name_en': 'Fourth generation',
      'generation_code': 'G45',
      'platform_code': 'G45',
      'start_year': 2024,
      'start_month': 11,
      'end_year': null,
      'end_month': null,
      'display_period': '2024.11~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Korea PressClub 4th generation X3 launch',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0446603KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-4%EC%84%B8%EB%8C%80-%EC%99%84%EC%A0%84%EB%B3%80%EA%B2%BD-bmw-%EB%89%B4-x3%E2%80%99-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2025; year <= 2026; year += 1) 'year-bmw-058-x3-$year',
      ],
    },
    {
      'id': 'generation-bmw-x5-f15',
      'model_id': 'model-bmw-059-x5',
      'generation_order': 3,
      'generation_name_ko': '3세대',
      'generation_name_en': 'Third generation',
      'generation_code': 'F15',
      'platform_code': 'F15',
      'start_year': 2013,
      'start_month': 11,
      'end_year': 2018,
      'end_month': null,
      'display_period': '2013.11~2018',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Korea PressClub 3rd generation X5 launch',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0156364KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EB%89%B4-x5-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2018; year += 1) 'year-bmw-059-x5-$year',
      ],
    },
    {
      'id': 'generation-bmw-x5-g05',
      'model_id': 'model-bmw-059-x5',
      'generation_order': 4,
      'generation_name_ko': '4세대',
      'generation_name_en': 'Fourth generation',
      'generation_code': 'G05',
      'platform_code': 'G05',
      'start_year': 2018,
      'start_month': 11,
      'end_year': null,
      'end_month': null,
      'display_period': '2018.11~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': 'BMW Korea PressClub 4th generation X5 pre-order',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0287123KO/bmw-%EA%B7%B8%EB%A3%B9-%EC%BD%94%EB%A6%AC%EC%95%84-4%EC%84%B8%EB%8C%80-%EB%89%B4-x5-%EC%82%AC%EC%A0%84-%EC%98%88%EC%95%BD-%EC%8B%A4%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2019; year <= 2026; year += 1) 'year-bmw-059-x5-$year',
      ],
    },
    {
      'id': 'generation-bmw-x7-g07',
      'model_id': 'model-bmw-060-x7',
      'generation_order': 1,
      'generation_name_ko': '1세대',
      'generation_name_en': 'First generation',
      'generation_code': 'G07',
      'platform_code': 'G07',
      'start_year': 2019,
      'start_month': null,
      'end_year': null,
      'end_month': null,
      'display_period': '2019~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.76,
      'source_name': 'BMW Korea PressClub X7 LCI launch note',
      'source_url':
          'https://www.press.bmwgroup.com/korea/article/detail/T0407081KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%ED%95%9C%EC%B8%B5-%EC%A7%84%EB%B3%B4%ED%95%9C-%ED%94%8C%EB%9E%98%EA%B7%B8%EC%8B%AD-sav-%EB%89%B4-x7%E2%80%99-%EA%B5%AD%EB%82%B4-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2019; year <= 2026; year += 1) 'year-bmw-060-x7-$year',
      ],
    },
    {
      'id': 'generation-bmw-i5-g60',
      'model_id': 'model-bmw-062-i5',
      'generation_order': 1,
      'generation_name_ko': '1세대',
      'generation_name_en': 'First generation',
      'generation_code': 'G60',
      'platform_code': 'G60',
      'start_year': 2024,
      'start_month': 3,
      'end_year': null,
      'end_month': null,
      'display_period': '2024.3~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.72,
      'source_name': 'BMW Group PressClub i5 xDrive40 production note',
      'source_url':
          'https://www.press.bmwgroup.com/canada/article/detail/T0437821EN/market-launch-of-the-new-bmw-5-series-sedan-and-the-first-bmw-i5?language=en',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2024; year <= 2026; year += 1) 'year-bmw-062-i5-$year',
      ],
    },
    {
      'id': 'generation-bmw-ix-i20',
      'model_id': 'model-bmw-063-ix',
      'generation_order': 1,
      'generation_name_ko': '1세대',
      'generation_name_en': 'First generation',
      'generation_code': 'i20',
      'platform_code': 'i20',
      'start_year': 2022,
      'start_month': null,
      'end_year': null,
      'end_month': null,
      'display_period': '2022~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.72,
      'source_name': 'BMW Group PressClub Korea iX/iX3 release',
      'source_url':
          'https://www.press.bmwgroup.com/korea/photo/detail/P90445396/BMW-Korea-to-officially-release-new-pure-electric-models-the-BMW-iX-and-iX3-in-Korea-11-2021?forceSitePreference=DESKTOP',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2022; year <= 2026; year += 1) 'year-bmw-063-ix-$year',
      ],
    },
    {
      'id': 'generation-bmw-ix3-g08',
      'model_id': 'model-bmw-064-ix3',
      'generation_order': 1,
      'generation_name_ko': '1세대',
      'generation_name_en': 'First generation',
      'generation_code': 'G08',
      'platform_code': 'G08',
      'start_year': 2022,
      'start_month': null,
      'end_year': null,
      'end_month': null,
      'display_period': '2022~현재',
      'is_current': true,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.72,
      'source_name': 'BMW Group PressClub Korea iX/iX3 release',
      'source_url':
          'https://www.press.bmwgroup.com/korea/photo/detail/P90445396/BMW-Korea-to-officially-release-new-pure-electric-models-the-BMW-iX-and-iX3-in-Korea-11-2021?forceSitePreference=DESKTOP',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2022; year <= 2026; year += 1) 'year-bmw-064-ix3-$year',
      ],
    },
    {
      'id': 'generation-kia-k3-yd',
      'model_id': 'model-kia-013-k3',
      'generation_order': 1,
      'generation_name_ko': '1세대',
      'generation_name_en': 'First generation',
      'generation_code': 'YD',
      'platform_code': 'YD',
      'start_year': 2015,
      'start_month': null,
      'end_year': 2018,
      'end_month': 2,
      'display_period': '2015~2018.2',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.66,
      'source_name': 'Kia official software version list',
      'source_url':
          'https://update.kia.com/KR/KO/updateNoticeView/software-version',
      'source_file_name': null,
      'last_verified_at': '2026-06-13',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2015; year <= 2017; year += 1) 'year-kia-013-k3-$year',
      ],
    },
    {
      'id': 'generation-kia-k3-bd',
      'model_id': 'model-kia-013-k3',
      'generation_order': 2,
      'generation_name_ko': '2세대',
      'generation_name_en': 'Second generation',
      'generation_code': 'BD',
      'platform_code': 'BD',
      'start_year': 2018,
      'start_month': 2,
      'end_year': 2024,
      'end_month': null,
      'display_period': '2018.2~2024',
      'is_current': false,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': 0.78,
      'source_name': '기아 보도자료/기아 커넥트/기아 공식 가격표',
      'source_url': 'https://www.newswire.co.kr/newsRead.php?no=865190',
      'source_file_name': 'price_k3gt.pdf',
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = 2018; year <= 2024; year += 1) 'year-kia-013-k3-$year',
      ],
    },
  ];
}

List<Map<String, Object?>> _mercedesGenerationSeeds() {
  Map<String, Object?> generation({
    required String id,
    required String modelId,
    required int generationOrder,
    required String generationNameKo,
    required String generationNameEn,
    required String generationCode,
    required String platformCode,
    required int startYear,
    int? endYear,
    required String displayPeriod,
    required bool isCurrent,
    required int modelYearStart,
    required int modelYearEnd,
    double confidenceScore = 0.72,
  }) {
    return {
      'id': id,
      'model_id': modelId,
      'generation_order': generationOrder,
      'generation_name_ko': generationNameKo,
      'generation_name_en': generationNameEn,
      'generation_code': generationCode,
      'platform_code': platformCode,
      'start_year': startYear,
      'start_month': null,
      'end_year': endYear,
      'end_month': null,
      'display_period': displayPeriod,
      'is_current': isCurrent,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': confidenceScore,
      'source_name': 'Mercedes-Benz official rescue sheets and media pages',
      'source_url': 'https://rk.mb-qr.com/en/',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = modelYearStart; year <= modelYearEnd; year += 1)
          'year-${modelId.substring(6)}-$year',
      ],
    };
  }

  return [
    generation(
      id: 'generation-benz-a-class-w176',
      modelId: 'model-benz-065-a-class',
      generationOrder: 3,
      generationNameKo: '3세대',
      generationNameEn: 'Third generation',
      generationCode: 'W176',
      platformCode: 'W176',
      startYear: 2012,
      endYear: 2018,
      displayPeriod: '2012~2018',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2017,
    ),
    generation(
      id: 'generation-benz-a-class-w177',
      modelId: 'model-benz-065-a-class',
      generationOrder: 4,
      generationNameKo: '4세대',
      generationNameEn: 'Fourth generation',
      generationCode: 'W177/V177',
      platformCode: 'W177',
      startYear: 2018,
      displayPeriod: '2018~현재',
      isCurrent: true,
      modelYearStart: 2018,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-benz-c-class-w205',
      modelId: 'model-benz-066-c-class',
      generationOrder: 4,
      generationNameKo: '4세대',
      generationNameEn: 'Fourth generation',
      generationCode: 'W205/S205/C205/A205',
      platformCode: 'W205',
      startYear: 2014,
      endYear: 2021,
      displayPeriod: '2014~2021',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2020,
    ),
    generation(
      id: 'generation-benz-c-class-w206',
      modelId: 'model-benz-066-c-class',
      generationOrder: 5,
      generationNameKo: '5세대',
      generationNameEn: 'Fifth generation',
      generationCode: 'W206/S206',
      platformCode: 'W206',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-benz-e-class-w212',
      modelId: 'model-benz-067-e-class',
      generationOrder: 4,
      generationNameKo: '4세대',
      generationNameEn: 'Fourth generation',
      generationCode: 'W212/S212/C207/A207',
      platformCode: 'W212',
      startYear: 2009,
      endYear: 2016,
      displayPeriod: '2009~2016',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2015,
    ),
    generation(
      id: 'generation-benz-e-class-w213',
      modelId: 'model-benz-067-e-class',
      generationOrder: 5,
      generationNameKo: '5세대',
      generationNameEn: 'Fifth generation',
      generationCode: 'W213/S213/C238/A238',
      platformCode: 'W213',
      startYear: 2016,
      endYear: 2023,
      displayPeriod: '2016~2023',
      isCurrent: false,
      modelYearStart: 2016,
      modelYearEnd: 2023,
    ),
    generation(
      id: 'generation-benz-e-class-w214',
      modelId: 'model-benz-067-e-class',
      generationOrder: 6,
      generationNameKo: '6세대',
      generationNameEn: 'Sixth generation',
      generationCode: 'W214/S214',
      platformCode: 'W214',
      startYear: 2023,
      displayPeriod: '2023~현재',
      isCurrent: true,
      modelYearStart: 2024,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-benz-s-class-w222',
      modelId: 'model-benz-068-s-class',
      generationOrder: 6,
      generationNameKo: '6세대',
      generationNameEn: 'Sixth generation',
      generationCode: 'W222/V222/X222',
      platformCode: 'W222',
      startYear: 2013,
      endYear: 2020,
      displayPeriod: '2013~2020',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2020,
    ),
    generation(
      id: 'generation-benz-s-class-w223',
      modelId: 'model-benz-068-s-class',
      generationOrder: 7,
      generationNameKo: '7세대',
      generationNameEn: 'Seventh generation',
      generationCode: 'W223/V223/Z223',
      platformCode: 'W223',
      startYear: 2020,
      displayPeriod: '2020~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-benz-gla-x156',
      modelId: 'model-benz-069-gla',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'X156',
      platformCode: 'X156',
      startYear: 2014,
      endYear: 2020,
      displayPeriod: '2014~2020',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2019,
    ),
    generation(
      id: 'generation-benz-gla-h247',
      modelId: 'model-benz-069-gla',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'H247',
      platformCode: 'H247',
      startYear: 2020,
      displayPeriod: '2020~현재',
      isCurrent: true,
      modelYearStart: 2020,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-benz-glc-x253',
      modelId: 'model-benz-070-glc',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'X253/C253',
      platformCode: 'X253',
      startYear: 2015,
      endYear: 2022,
      displayPeriod: '2015~2022',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2022,
    ),
    generation(
      id: 'generation-benz-glc-x254',
      modelId: 'model-benz-070-glc',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'X254/C254',
      platformCode: 'X254',
      startYear: 2022,
      displayPeriod: '2022~현재',
      isCurrent: true,
      modelYearStart: 2023,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-benz-gle-w166',
      modelId: 'model-benz-071-gle',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'W166/C292',
      platformCode: 'W166',
      startYear: 2015,
      endYear: 2019,
      displayPeriod: '2015~2019',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2018,
    ),
    generation(
      id: 'generation-benz-gle-v167',
      modelId: 'model-benz-071-gle',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'V167/C167',
      platformCode: 'V167',
      startYear: 2019,
      displayPeriod: '2019~현재',
      isCurrent: true,
      modelYearStart: 2019,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-benz-gls-x166',
      modelId: 'model-benz-072-gls',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'X166',
      platformCode: 'X166',
      startYear: 2015,
      endYear: 2019,
      displayPeriod: '2015~2019',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2019,
    ),
    generation(
      id: 'generation-benz-gls-x167',
      modelId: 'model-benz-072-gls',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'X167',
      platformCode: 'X167',
      startYear: 2019,
      displayPeriod: '2019~현재',
      isCurrent: true,
      modelYearStart: 2020,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-benz-eqa-h243',
      modelId: 'model-benz-073-eqa',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'H243',
      platformCode: 'H243',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-benz-eqb-x243',
      modelId: 'model-benz-074-eqb',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'X243',
      platformCode: 'X243',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2022,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-benz-eqe-v295',
      modelId: 'model-benz-075-eqe',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'V295/X294',
      platformCode: 'EVA2',
      startYear: 2022,
      displayPeriod: '2022~현재',
      isCurrent: true,
      modelYearStart: 2022,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-benz-eqs-v297',
      modelId: 'model-benz-076-eqs',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'V297/X296',
      platformCode: 'EVA2',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
    ),
  ];
}

List<Map<String, Object?>> _audiGenerationSeeds() {
  Map<String, Object?> generation({
    required String id,
    required String modelId,
    required int generationOrder,
    required String generationNameKo,
    required String generationNameEn,
    required String generationCode,
    required String platformCode,
    required int startYear,
    int? endYear,
    required String displayPeriod,
    required bool isCurrent,
    required int modelYearStart,
    required int modelYearEnd,
    double confidenceScore = 0.7,
  }) {
    return {
      'id': id,
      'model_id': modelId,
      'generation_order': generationOrder,
      'generation_name_ko': generationNameKo,
      'generation_name_en': generationNameEn,
      'generation_code': generationCode,
      'platform_code': platformCode,
      'start_year': startYear,
      'start_month': null,
      'end_year': endYear,
      'end_month': null,
      'display_period': displayPeriod,
      'is_current': isCurrent,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': confidenceScore,
      'source_name': 'Audi official rescue sheets and MediaCenter pages',
      'source_url': 'https://www.audi.com/en/rescue/',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = modelYearStart; year <= modelYearEnd; year += 1)
          'year-${modelId.substring(6)}-$year',
      ],
    };
  }

  return [
    generation(
      id: 'generation-audi-a3-8v',
      modelId: 'model-audi-077-a3',
      generationOrder: 3,
      generationNameKo: '3세대',
      generationNameEn: 'Third generation',
      generationCode: '8V',
      platformCode: 'MQB',
      startYear: 2012,
      endYear: 2020,
      displayPeriod: '2012~2020',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2019,
    ),
    generation(
      id: 'generation-audi-a3-8y',
      modelId: 'model-audi-077-a3',
      generationOrder: 4,
      generationNameKo: '4세대',
      generationNameEn: 'Fourth generation',
      generationCode: '8Y/8Y PA',
      platformCode: 'MQB Evo',
      startYear: 2020,
      displayPeriod: '2020~현재',
      isCurrent: true,
      modelYearStart: 2020,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-audi-a4-b9-8w',
      modelId: 'model-audi-078-a4',
      generationOrder: 5,
      generationNameKo: '5세대',
      generationNameEn: 'Fifth generation',
      generationCode: 'B9/8W',
      platformCode: 'MLB Evo',
      startYear: 2015,
      endYear: 2024,
      displayPeriod: '2015~2024',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2024,
    ),
    generation(
      id: 'generation-audi-a5-8t',
      modelId: 'model-audi-079-a5',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: '8T/8F',
      platformCode: 'MLB',
      startYear: 2007,
      endYear: 2016,
      displayPeriod: '2007~2016',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2015,
    ),
    generation(
      id: 'generation-audi-a5-f5',
      modelId: 'model-audi-079-a5',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'F5',
      platformCode: 'MLB Evo',
      startYear: 2016,
      endYear: 2024,
      displayPeriod: '2016~2024',
      isCurrent: false,
      modelYearStart: 2016,
      modelYearEnd: 2023,
    ),
    generation(
      id: 'generation-audi-a5-b10',
      modelId: 'model-audi-079-a5',
      generationOrder: 3,
      generationNameKo: '3세대',
      generationNameEn: 'Third generation',
      generationCode: 'B10',
      platformCode: 'PPC',
      startYear: 2024,
      displayPeriod: '2024~현재',
      isCurrent: true,
      modelYearStart: 2024,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-audi-a6-c7-4g',
      modelId: 'model-audi-080-a6',
      generationOrder: 7,
      generationNameKo: '7세대',
      generationNameEn: 'Seventh generation',
      generationCode: 'C7/4G',
      platformCode: 'MLB',
      startYear: 2011,
      endYear: 2018,
      displayPeriod: '2011~2018',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2018,
    ),
    generation(
      id: 'generation-audi-a6-c8-4a',
      modelId: 'model-audi-080-a6',
      generationOrder: 8,
      generationNameKo: '8세대',
      generationNameEn: 'Eighth generation',
      generationCode: 'C8/4A',
      platformCode: 'MLB Evo',
      startYear: 2018,
      endYear: 2025,
      displayPeriod: '2018~2025',
      isCurrent: false,
      modelYearStart: 2019,
      modelYearEnd: 2024,
    ),
    generation(
      id: 'generation-audi-a6-c9',
      modelId: 'model-audi-080-a6',
      generationOrder: 9,
      generationNameKo: '9세대',
      generationNameEn: 'Ninth generation',
      generationCode: 'C9',
      platformCode: 'PPC',
      startYear: 2025,
      displayPeriod: '2025~현재',
      isCurrent: true,
      modelYearStart: 2025,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-audi-a7-4g8',
      modelId: 'model-audi-081-a7',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: '4G8',
      platformCode: 'MLB',
      startYear: 2010,
      endYear: 2017,
      displayPeriod: '2010~2017',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2017,
    ),
    generation(
      id: 'generation-audi-a7-4k8',
      modelId: 'model-audi-081-a7',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: '4K8',
      platformCode: 'MLB Evo',
      startYear: 2017,
      endYear: 2025,
      displayPeriod: '2017~2025',
      isCurrent: false,
      modelYearStart: 2018,
      modelYearEnd: 2025,
    ),
    generation(
      id: 'generation-audi-a8-d4-4h',
      modelId: 'model-audi-082-a8',
      generationOrder: 3,
      generationNameKo: '3세대',
      generationNameEn: 'Third generation',
      generationCode: 'D4/4H',
      platformCode: 'MLB',
      startYear: 2010,
      endYear: 2017,
      displayPeriod: '2010~2017',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2017,
    ),
    generation(
      id: 'generation-audi-a8-d5-4n',
      modelId: 'model-audi-082-a8',
      generationOrder: 4,
      generationNameKo: '4세대',
      generationNameEn: 'Fourth generation',
      generationCode: 'D5/4N',
      platformCode: 'MLB Evo',
      startYear: 2017,
      displayPeriod: '2017~현재',
      isCurrent: true,
      modelYearStart: 2018,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-audi-q3-8u',
      modelId: 'model-audi-083-q3',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: '8U',
      platformCode: 'PQ35',
      startYear: 2011,
      endYear: 2018,
      displayPeriod: '2011~2018',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2018,
    ),
    generation(
      id: 'generation-audi-q3-f3',
      modelId: 'model-audi-083-q3',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'F3',
      platformCode: 'MQB',
      startYear: 2018,
      endYear: 2025,
      displayPeriod: '2018~2025',
      isCurrent: false,
      modelYearStart: 2019,
      modelYearEnd: 2024,
    ),
    generation(
      id: 'generation-audi-q3-2025',
      modelId: 'model-audi-083-q3',
      generationOrder: 3,
      generationNameKo: '3세대',
      generationNameEn: 'Third generation',
      generationCode: '2025 generation',
      platformCode: 'MQB Evo',
      startYear: 2025,
      displayPeriod: '2025~현재',
      isCurrent: true,
      modelYearStart: 2025,
      modelYearEnd: 2026,
      confidenceScore: 0.66,
    ),
    generation(
      id: 'generation-audi-q5-8r',
      modelId: 'model-audi-084-q5',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: '8R',
      platformCode: 'MLB',
      startYear: 2008,
      endYear: 2017,
      displayPeriod: '2008~2017',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2016,
    ),
    generation(
      id: 'generation-audi-q5-fy',
      modelId: 'model-audi-084-q5',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'FY',
      platformCode: 'MLB Evo',
      startYear: 2017,
      endYear: 2024,
      displayPeriod: '2017~2024',
      isCurrent: false,
      modelYearStart: 2017,
      modelYearEnd: 2024,
    ),
    generation(
      id: 'generation-audi-q5-2025',
      modelId: 'model-audi-084-q5',
      generationOrder: 3,
      generationNameKo: '3세대',
      generationNameEn: 'Third generation',
      generationCode: '2025 generation',
      platformCode: 'PPC',
      startYear: 2024,
      displayPeriod: '2024~현재',
      isCurrent: true,
      modelYearStart: 2025,
      modelYearEnd: 2026,
      confidenceScore: 0.66,
    ),
    generation(
      id: 'generation-audi-q7-4m',
      modelId: 'model-audi-085-q7',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: '4M/4M PA',
      platformCode: 'MLB Evo',
      startYear: 2015,
      displayPeriod: '2015~현재',
      isCurrent: true,
      modelYearStart: 2015,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-audi-q8-4m',
      modelId: 'model-audi-086-q8',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: '4M',
      platformCode: 'MLB Evo',
      startYear: 2018,
      displayPeriod: '2018~현재',
      isCurrent: true,
      modelYearStart: 2018,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-audi-e-tron-ge',
      modelId: 'model-audi-087-e-tron',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'GE',
      platformCode: 'MLB Evo',
      startYear: 2018,
      endYear: 2022,
      displayPeriod: '2018~2022',
      isCurrent: false,
      modelYearStart: 2018,
      modelYearEnd: 2022,
    ),
    generation(
      id: 'generation-audi-q8-e-tron-ge',
      modelId: 'model-audi-087-e-tron',
      generationOrder: 2,
      generationNameKo: 'Q8 e-tron',
      generationNameEn: 'Q8 e-tron facelift',
      generationCode: 'GE PE',
      platformCode: 'MLB Evo',
      startYear: 2023,
      endYear: 2025,
      displayPeriod: '2023~2025',
      isCurrent: false,
      modelYearStart: 2023,
      modelYearEnd: 2025,
    ),
    generation(
      id: 'generation-audi-q4-e-tron-f4',
      modelId: 'model-audi-088-q4-e-tron',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'F4',
      platformCode: 'MEB',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
    ),
  ];
}

Map<String, Object?> _catalogGeneration({
  required String id,
  required String modelId,
  required int generationOrder,
  required String generationNameKo,
  required String generationNameEn,
  String generationCode = '',
  String platformCode = '',
  required int startYear,
  int? startMonth,
  int? endYear,
  int? endMonth,
  required String displayPeriod,
  required bool isCurrent,
  required int modelYearStart,
  required int modelYearEnd,
  String sourceStatus = 'pending_review',
  double confidenceScore = 0.58,
  String? sourceName,
  String? sourceUrl,
  String? sourceFileName,
  String lastVerifiedAt = '2026-06-13',
  bool isUpcoming = false,
  bool isSelectable = true,
}) {
  return {
    'id': id,
    'model_id': modelId,
    'generation_order': generationOrder,
    'generation_name_ko': generationNameKo,
    'generation_name_en': generationNameEn,
    'generation_code': generationCode,
    'platform_code': platformCode,
    'start_year': startYear,
    'start_month': startMonth,
    'end_year': endYear,
    'end_month': endMonth,
    'display_period': displayPeriod,
    'is_current': isCurrent,
    'is_upcoming': isUpcoming,
    'market_region': 'KR',
    'source_status': sourceStatus,
    'confidence_score': confidenceScore,
    'source_name': sourceName,
    'source_url': sourceUrl,
    'source_file_name': sourceFileName,
    'last_verified_at':
        sourceName == null && sourceUrl == null ? null : lastVerifiedAt,
    'is_selectable': isSelectable,
    'is_deprecated': false,
    'model_year_ids': [
      for (var year = modelYearStart; year <= modelYearEnd; year += 1)
        'year-${modelId.substring(6)}-$year',
    ],
  };
}

List<Map<String, Object?>> _genesisGenerationSeeds() {
  return [
    _catalogGeneration(
      id: 'generation-genesis-g70-1',
      modelId: 'model-genesis-028-g70',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2017,
      displayPeriod: '2017~현재',
      isCurrent: true,
      modelYearStart: 2017,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.76,
      sourceName: 'Genesis G70 launch and official model page',
      sourceUrl:
          'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000180',
    ),
    _catalogGeneration(
      id: 'generation-genesis-g70-shooting-brake-1',
      modelId: 'model-genesis-g70-shooting-brake-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2022,
      displayPeriod: '2022~현재',
      isCurrent: true,
      modelYearStart: 2022,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.72,
      sourceName: 'Genesis G70 Shooting Brake PR and download center',
      sourceUrl:
          'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000311',
    ),
    _catalogGeneration(
      id: 'generation-genesis-g80-2',
      modelId: 'model-genesis-029-g80',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      startYear: 2016,
      endYear: 2019,
      displayPeriod: '2016~2019',
      isCurrent: false,
      modelYearStart: 2016,
      modelYearEnd: 2019,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.76,
      sourceName: 'Genesis G80 generation official PR',
      sourceUrl:
          'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000226',
    ),
    _catalogGeneration(
      id: 'generation-genesis-g80-3',
      modelId: 'model-genesis-029-g80',
      generationOrder: 3,
      generationNameKo: '3세대',
      generationNameEn: 'Third generation',
      startYear: 2020,
      displayPeriod: '2020~현재',
      isCurrent: true,
      modelYearStart: 2020,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.78,
      sourceName: 'Genesis The All-new G80 launch and official specs',
      sourceUrl:
          'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000221',
    ),
    _catalogGeneration(
      id: 'generation-genesis-electrified-g80-1',
      modelId: 'model-genesis-electrified-g80-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.78,
      sourceName: 'Genesis Electrified G80 launch and official specs',
      sourceUrl:
          'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000310',
    ),
    _catalogGeneration(
      id: 'generation-genesis-g90-1',
      modelId: 'model-genesis-030-g90',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2019,
      endYear: 2021,
      displayPeriod: '2019~2021',
      isCurrent: false,
      modelYearStart: 2019,
      modelYearEnd: 2021,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.7,
      sourceName: 'Genesis G90 official PR archive',
      sourceUrl:
          'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000232',
    ),
    _catalogGeneration(
      id: 'generation-genesis-g90-2',
      modelId: 'model-genesis-030-g90',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2022,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.76,
      sourceName: 'Genesis G90 full-change official PR',
      sourceUrl:
          'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000330',
    ),
    _catalogGeneration(
      id: 'generation-genesis-gv60-1',
      modelId: 'model-genesis-031-gv60',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      platformCode: 'E-GMP',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.78,
      sourceName: 'Genesis GV60 launch and official model page',
      sourceUrl:
          'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000319',
    ),
    _catalogGeneration(
      id: 'generation-genesis-gv70-1',
      modelId: 'model-genesis-032-gv70',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2020,
      displayPeriod: '2020~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.76,
      sourceName: 'Genesis GV70 official global reveal',
      sourceUrl:
          'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000290',
    ),
    _catalogGeneration(
      id: 'generation-genesis-electrified-gv70-1',
      modelId: 'model-genesis-electrified-gv70-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2022,
      displayPeriod: '2022~현재',
      isCurrent: true,
      modelYearStart: 2022,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.76,
      sourceName: 'Genesis Electrified GV70 official model page and PR',
      sourceUrl:
          'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000339',
    ),
    _catalogGeneration(
      id: 'generation-genesis-gv80-1',
      modelId: 'model-genesis-033-gv80',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2020,
      displayPeriod: '2020~현재',
      isCurrent: true,
      modelYearStart: 2020,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.76,
      sourceName: 'Genesis GV80 official launch and specs',
      sourceUrl:
          'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000224',
    ),
    _catalogGeneration(
      id: 'generation-genesis-gv80-coupe-1',
      modelId: 'model-genesis-gv80-coupe-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2023,
      displayPeriod: '2023~현재',
      isCurrent: true,
      modelYearStart: 2024,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.74,
      sourceName: 'Genesis GV80 Coupe official model page and PR',
      sourceUrl:
          'https://www.genesis.com/kr/ko/support/pr-center/detail.html?seq=0000000445',
    ),
  ];
}

List<Map<String, Object?>> _renaultGenerationSeeds() {
  return [
    _catalogGeneration(
      id: 'generation-renault-sm6-1',
      modelId: 'model-renault-042-sm6',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2016,
      endYear: 2024,
      displayPeriod: '2016~2024',
      isCurrent: false,
      modelYearStart: 2016,
      modelYearEnd: 2024,
    ),
    _catalogGeneration(
      id: 'generation-renault-qm6-1',
      modelId: 'model-renault-043-qm6',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2016,
      endYear: 2024,
      displayPeriod: '2016~2024',
      isCurrent: false,
      modelYearStart: 2016,
      modelYearEnd: 2024,
    ),
    _catalogGeneration(
      id: 'generation-renault-xm3-1',
      modelId: 'model-renault-044-xm3',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2020,
      endYear: 2023,
      displayPeriod: '2020~2023',
      isCurrent: false,
      modelYearStart: 2020,
      modelYearEnd: 2023,
    ),
    _catalogGeneration(
      id: 'generation-renault-arkana-1',
      modelId: 'model-renault-arkana-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2024,
      displayPeriod: '2024~현재',
      isCurrent: true,
      modelYearStart: 2024,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.74,
      sourceName: 'Renault Korea official Arkana model page',
      sourceUrl: 'https://www.renault.co.kr/ko/model/arkana_overview.jsp',
    ),
    _catalogGeneration(
      id: 'generation-renault-grand-koleos-1',
      modelId: 'model-renault-045-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2024,
      displayPeriod: '2024~현재',
      isCurrent: true,
      modelYearStart: 2025,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.76,
      sourceName: 'Renault Korea official Grand Koleos model page',
      sourceUrl: 'https://www.renault.co.kr/ko/model/koleos_overview.jsp',
    ),
    _catalogGeneration(
      id: 'generation-renault-filante-1',
      modelId: 'model-renault-filante-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2026,
      displayPeriod: '2026~현재',
      isCurrent: true,
      modelYearStart: 2026,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.76,
      sourceName: 'Renault Korea official Filante model page',
      sourceUrl: 'https://www.renault.co.kr/ko/model/filante_overview.jsp',
    ),
  ];
}

List<Map<String, Object?>> _kgmGenerationSeeds() {
  return [
    _catalogGeneration(
      id: 'generation-kgm-tivoli-1',
      modelId: 'model-kgm-046-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2015,
      displayPeriod: '2015~현재',
      isCurrent: true,
      modelYearStart: 2015,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.72,
      sourceName: 'KGM official Tivoli model page',
      sourceUrl:
          'https://www.kg-mobility.com/pr/model/show-room/200000100010007',
    ),
    _catalogGeneration(
      id: 'generation-kgm-korando-c300',
      modelId: 'model-kgm-047-kr',
      generationOrder: 4,
      generationNameKo: '4세대',
      generationNameEn: 'Fourth generation',
      startYear: 2019,
      endYear: 2024,
      displayPeriod: '2019~2024',
      isCurrent: false,
      modelYearStart: 2019,
      modelYearEnd: 2024,
    ),
    _catalogGeneration(
      id: 'generation-kgm-actyon-j120',
      modelId: 'model-kgm-actyon-kr',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      startYear: 2024,
      displayPeriod: '2024~현재',
      isCurrent: true,
      modelYearStart: 2024,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.72,
      sourceName: 'KGM official Actyon model page',
      sourceUrl:
          'https://www.kg-mobility.com/pr/model/show-room/200000100010016',
    ),
    _catalogGeneration(
      id: 'generation-kgm-actyon-hybrid-j120',
      modelId: 'model-kgm-actyon-hybrid-kr',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      startYear: 2025,
      displayPeriod: '2025~현재',
      isCurrent: true,
      modelYearStart: 2025,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.72,
      sourceName: 'KGM official Actyon Hybrid model page and launch PR',
      sourceUrl:
          'https://www.kg-mobility.com/pr/model/show-room/200000100010018',
    ),
    _catalogGeneration(
      id: 'generation-kgm-torres-j100',
      modelId: 'model-kgm-048-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2022,
      displayPeriod: '2022~현재',
      isCurrent: true,
      modelYearStart: 2022,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.72,
      sourceName: 'KGM official Torres model page and refresh PR',
      sourceUrl:
          'https://www.kg-mobility.com/pr/model/show-room/200000100010001',
    ),
    _catalogGeneration(
      id: 'generation-kgm-torres-hybrid-j100',
      modelId: 'model-kgm-torres-hybrid-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2025,
      displayPeriod: '2025~현재',
      isCurrent: true,
      modelYearStart: 2025,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.72,
      sourceName: 'KGM official Torres Hybrid model page and launch PR',
      sourceUrl:
          'https://www.kg-mobility.com/pr/model/show-room/200000100010017',
    ),
    _catalogGeneration(
      id: 'generation-kgm-torres-evx-j100',
      modelId: 'model-kgm-torres-evx-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      startYear: 2023,
      displayPeriod: '2023~현재',
      isCurrent: true,
      modelYearStart: 2023,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.72,
      sourceName: 'KGM official Torres EVX model page',
      sourceUrl:
          'https://www.kg-mobility.com/pr/model/show-room/200000100010009',
    ),
    _catalogGeneration(
      id: 'generation-kgm-torres-van-official-lineup',
      modelId: 'model-kgm-torres-van-kr',
      generationOrder: 1,
      generationNameKo: '공식 라인업',
      generationNameEn: 'Official lineup',
      startYear: 2026,
      displayPeriod: '2026~현재',
      isCurrent: true,
      modelYearStart: 2026,
      modelYearEnd: 2026,
      sourceStatus: 'pending_review',
      confidenceScore: 0.64,
      sourceName: 'KGM official Korean model list',
      sourceUrl: 'https://www.kg-mobility.com/pr/model',
    ),
    _catalogGeneration(
      id: 'generation-kgm-torres-evx-van-official-lineup',
      modelId: 'model-kgm-torres-evx-van-kr',
      generationOrder: 1,
      generationNameKo: '공식 라인업',
      generationNameEn: 'Official lineup',
      startYear: 2026,
      displayPeriod: '2026~현재',
      isCurrent: true,
      modelYearStart: 2026,
      modelYearEnd: 2026,
      sourceStatus: 'pending_review',
      confidenceScore: 0.64,
      sourceName: 'KGM official Korean model list',
      sourceUrl: 'https://www.kg-mobility.com/pr/model',
    ),
    _catalogGeneration(
      id: 'generation-kgm-rexton-y400',
      modelId: 'model-kgm-049-kr',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      startYear: 2017,
      displayPeriod: '2017~현재',
      isCurrent: true,
      modelYearStart: 2017,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.7,
      sourceName: 'KGM official Rexton New Arena model page',
      sourceUrl:
          'https://www.kg-mobility.com/pr/model/show-room/200000100010012',
    ),
    _catalogGeneration(
      id: 'generation-kgm-rexton-summit-official-lineup',
      modelId: 'model-kgm-rexton-summit-kr',
      generationOrder: 1,
      generationNameKo: '공식 라인업',
      generationNameEn: 'Official lineup',
      startYear: 2026,
      displayPeriod: '2026~현재',
      isCurrent: true,
      modelYearStart: 2026,
      modelYearEnd: 2026,
      sourceStatus: 'pending_review',
      confidenceScore: 0.64,
      sourceName: 'KGM official Korean model list',
      sourceUrl: 'https://www.kg-mobility.com/pr/model',
    ),
    _catalogGeneration(
      id: 'generation-kgm-rexton-sports-q200',
      modelId: 'model-kgm-050-kr',
      generationOrder: 1,
      generationNameKo: '렉스턴 스포츠',
      generationNameEn: 'Rexton Sports',
      startYear: 2018,
      endYear: 2025,
      displayPeriod: '2018~2025',
      isCurrent: false,
      modelYearStart: 2018,
      modelYearEnd: 2025,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.72,
      sourceName: 'KGM Musso pickup brand official PR',
      sourceUrl: 'https://www.kg-mobility.com/br/news/press-release/0000000996',
    ),
    _catalogGeneration(
      id: 'generation-kgm-musso-q300',
      modelId: 'model-kgm-musso-kr',
      generationOrder: 1,
      generationNameKo: '무쏘',
      generationNameEn: 'Musso pickup brand',
      startYear: 2025,
      displayPeriod: '2025~현재',
      isCurrent: true,
      modelYearStart: 2025,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.72,
      sourceName: 'KGM official Musso model page',
      sourceUrl:
          'https://www.kg-mobility.com/pr/model/show-room/200000100030004',
    ),
    _catalogGeneration(
      id: 'generation-kgm-musso-ev-q300',
      modelId: 'model-kgm-musso-ev-kr',
      generationOrder: 1,
      generationNameKo: '무쏘 EV',
      generationNameEn: 'Musso EV',
      startYear: 2025,
      displayPeriod: '2025~현재',
      isCurrent: true,
      modelYearStart: 2025,
      modelYearEnd: 2026,
      sourceStatus: 'verified_admin',
      confidenceScore: 0.74,
      sourceName: 'KGM official Musso EV model page and launch PR',
      sourceUrl:
          'https://www.kg-mobility.com/pr/model/show-room/200000100030003',
    ),
  ];
}

List<Map<String, Object?>> _remainingManufacturerGenerationSeeds() {
  Map<String, Object?> lineup({
    required String id,
    required String modelId,
    required String sourceName,
    required String sourceUrl,
    required int startYear,
    required int modelYearStart,
    required int modelYearEnd,
    required String displayPeriod,
    double confidenceScore = 0.56,
    bool isCurrent = true,
    bool isUpcoming = false,
    bool isSelectable = true,
  }) {
    return _catalogGeneration(
      id: id,
      modelId: modelId,
      generationOrder: 1,
      generationNameKo: '공식 라인업',
      generationNameEn: 'Official lineup',
      startYear: startYear,
      displayPeriod: displayPeriod,
      isCurrent: isCurrent,
      modelYearStart: modelYearStart,
      modelYearEnd: modelYearEnd,
      sourceStatus: 'pending_review',
      confidenceScore: confidenceScore,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      isUpcoming: isUpcoming,
      isSelectable: isSelectable,
    );
  }

  return [
    for (final entry in _remainingLineupGenerationData)
      lineup(
        id: entry.generationId,
        modelId: entry.modelId,
        sourceName: entry.sourceName,
        sourceUrl: entry.sourceUrl,
        startYear: entry.startYear,
        modelYearStart: entry.modelYearStart,
        modelYearEnd: entry.modelYearEnd,
        displayPeriod: entry.displayPeriod,
        confidenceScore: entry.confidenceScore,
        isCurrent: entry.isCurrent,
        isUpcoming: entry.isUpcoming,
        isSelectable: entry.isSelectable,
      ),
  ];
}

const _remainingLineupGenerationData = [
  _LineupGenerationSeed(
    generationId: 'generation-hyundai-venue-official-lineup',
    modelId: 'model-hyundai-venue-kr',
    sourceName: 'Hyundai Motor Korea official Venue model page',
    sourceUrl: 'https://www.hyundai.com/kr/ko/e/vehicles/venue/intro',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-hyundai-casper-electric-official-lineup',
    modelId: 'model-hyundai-casper-electric-kr',
    sourceName: 'Hyundai Casper official CASPER Electric page',
    sourceUrl: 'https://casper.hyundai.com/vehicles/electric/highlight',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.64,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-hyundai-ioniq5-n-official-lineup',
    modelId: 'model-hyundai-ioniq5-n-kr',
    sourceName: 'Hyundai Motor Korea official IONIQ 5 N model page',
    sourceUrl: 'https://www.hyundai.com/kr/ko/e/vehicles/ioniq5-n/intro',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-hyundai-ioniq6-n-official-lineup',
    modelId: 'model-hyundai-ioniq6-n-kr',
    sourceName: 'Hyundai Motor Korea official IONIQ 6 N model page',
    sourceUrl: 'https://www.hyundai.com/kr/ko/e/vehicles/ioniq6-n/intro',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-hyundai-ioniq9-official-lineup',
    modelId: 'model-hyundai-ioniq9-kr',
    sourceName: 'Hyundai Motor Korea official IONIQ 9 model page',
    sourceUrl: 'https://www.hyundai.com/kr/ko/e/vehicles/ioniq9/intro',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-hyundai-nexo-official-lineup',
    modelId: 'model-hyundai-nexo-kr',
    sourceName: 'Hyundai Motor Korea official all-new NEXO model page',
    sourceUrl:
        'https://www.hyundai.com/kr/ko/e/vehicles/the-all-new-nexo/intro',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-hyundai-staria-electric-official-lineup',
    modelId: 'model-hyundai-staria-electric-kr',
    sourceName: 'Hyundai Motor Korea official STARIA Electric model page',
    sourceUrl:
        'https://www.hyundai.com/kr/ko/e/vehicles/the-new-staria-electric/intro',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-hyundai-st1-official-lineup',
    modelId: 'model-hyundai-st1-kr',
    sourceName: 'Hyundai Motor Korea official ST1 model page',
    sourceUrl: 'https://www.hyundai.com/kr/ko/e/vehicles/st1/intro',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-kia-ev4-official-lineup',
    modelId: 'model-kia-ev4-kr',
    sourceName: 'Kia Korea official EV4 model page',
    sourceUrl: 'https://www.kia.com/kr/vehicles/ev4/features',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.64,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-kia-ev5-official-lineup',
    modelId: 'model-kia-ev5-kr',
    sourceName: 'Kia Korea official EV5 model page',
    sourceUrl: 'https://www.kia.com/kr/vehicles/ev5/features',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.64,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-kia-pv5-official-lineup',
    modelId: 'model-kia-pv5-kr',
    sourceName: 'Kia Korea official EV/PBV lineup page',
    sourceUrl: 'https://www.kia.com/kr/vehicles/kia-ev/vehicles/ev-line-up',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-kia-tasman-official-lineup',
    modelId: 'model-kia-tasman-kr',
    sourceName: 'Kia Korea official Tasman model page',
    sourceUrl: 'https://www.kia.com/kr/vehicles/tasman/features',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.64,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-x2-official-lineup',
    modelId: 'model-bmw-x2-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-x4-official-lineup',
    modelId: 'model-bmw-x4-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-x6-official-lineup',
    modelId: 'model-bmw-x6-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-xm-official-lineup',
    modelId: 'model-bmw-xm-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-z4-official-lineup',
    modelId: 'model-bmw-z4-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-i7-official-lineup',
    modelId: 'model-bmw-i7-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-ix1-official-lineup',
    modelId: 'model-bmw-ix1-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-ix2-official-lineup',
    modelId: 'model-bmw-ix2-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-i3-official-lineup',
    modelId: 'model-bmw-i3-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-2series-gran-coupe-official-lineup',
    modelId: 'model-bmw-2-series-gran-coupe-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-8series-official-lineup',
    modelId: 'model-bmw-8-series-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-m2-official-lineup',
    modelId: 'model-bmw-m2-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-m3-official-lineup',
    modelId: 'model-bmw-m3-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-m4-official-lineup',
    modelId: 'model-bmw-m4-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-m5-official-lineup',
    modelId: 'model-bmw-m5-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-m8-official-lineup',
    modelId: 'model-bmw-m8-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-x5-m-official-lineup',
    modelId: 'model-bmw-x5-m-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-bmw-x6-m-official-lineup',
    modelId: 'model-bmw-x6-m-kr',
    sourceName: 'BMW Korea official model lineup',
    sourceUrl: 'https://www.bmw.co.kr/ko/all-models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-renault-scenic-e-tech-official-lineup',
    modelId: 'model-renault-scenic-e-tech-kr',
    sourceName: 'Renault Korea official Scenic E-Tech price list',
    sourceUrl:
        'https://www.renault.co.kr/upload/asset/price/price_scenic_202508.pdf',
    startYear: 2025,
    modelYearStart: 2025,
    modelYearEnd: 2026,
    displayPeriod: '2025~현재',
    confidenceScore: 0.68,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-s-class-long-official-lineup',
    modelId: 'model-benz-s-class-long-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-maybach-s-class-official-lineup',
    modelId: 'model-benz-maybach-s-class-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-eqe-suv-official-lineup',
    modelId: 'model-benz-eqe-suv-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-maybach-eqs-suv-official-lineup',
    modelId: 'model-benz-maybach-eqs-suv-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-glb-official-lineup',
    modelId: 'model-benz-glb-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-glc-coupe-official-lineup',
    modelId: 'model-benz-glc-coupe-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-gle-coupe-official-lineup',
    modelId: 'model-benz-gle-coupe-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-maybach-gls-official-lineup',
    modelId: 'model-benz-maybach-gls-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-g-class-official-lineup',
    modelId: 'model-benz-g-class-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-cla-coupe-official-lineup',
    modelId: 'model-benz-cla-coupe-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-cle-coupe-official-lineup',
    modelId: 'model-benz-cle-coupe-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-amg-gt-coupe-official-lineup',
    modelId: 'model-benz-amg-gt-coupe-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-amg-gt-4door-coupe-official-lineup',
    modelId: 'model-benz-amg-gt-4door-coupe-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-cle-cabriolet-official-lineup',
    modelId: 'model-benz-cle-cabriolet-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-sl-roadster-official-lineup',
    modelId: 'model-benz-sl-roadster-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-benz-maybach-sl-monogram-official-lineup',
    modelId: 'model-benz-maybach-sl-monogram-kr',
    sourceName: 'Mercedes-Benz Korea official model overview',
    sourceUrl: 'https://www.mercedes-benz.co.kr/passengercars/models.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-audi-e-tron-gt-official-lineup',
    modelId: 'model-audi-e-tron-gt-kr',
    sourceName: 'Audi Korea official model overview',
    sourceUrl: 'https://www.audi.co.kr/ko/models/',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-audi-a6-e-tron-official-lineup',
    modelId: 'model-audi-a6-e-tron-kr',
    sourceName: 'Audi Korea official model overview',
    sourceUrl: 'https://www.audi.co.kr/ko/models/',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-audi-q6-e-tron-official-lineup',
    modelId: 'model-audi-q6-e-tron-kr',
    sourceName: 'Audi Korea official model overview',
    sourceUrl: 'https://www.audi.co.kr/ko/models/',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volvo-ex30-cross-country-official-lineup',
    modelId: 'model-volvo-ex30-cross-country-kr',
    sourceName: 'Volvo Cars Korea official EX30 Cross Country launch',
    sourceUrl:
        'https://www.volvocars.com/kr/news/culture/20250904-Launch-of-the-EX30-Cross-Country/',
    startYear: 2025,
    modelYearStart: 2025,
    displayPeriod: '2025~현재',
    confidenceScore: 0.66,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volvo-es90-official-lineup',
    modelId: 'model-volvo-es90-kr',
    sourceName: 'Volvo Cars Korea official ES90 preorder notice',
    sourceUrl:
        'https://www.volvocars.com/kr/news/culture/20260611-Volvo-Car-Opens-ES90-Pre-Orders/',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.64,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volvo-ex40-official-lineup',
    modelId: 'model-volvo-ex40-kr',
    sourceName: 'Volvo Cars Korea official EX40/EC40 rename news and support',
    sourceUrl:
        'https://www.volvocars.com/kr/news/corporate/new-name-new-me-say-hello-to-the-ex40-and-ec40/',
    startYear: 2025,
    modelYearStart: 2025,
    displayPeriod: '2025~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volvo-ec40-official-lineup',
    modelId: 'model-volvo-ec40-kr',
    sourceName: 'Volvo Cars Korea official EX40/EC40 rename news and support',
    sourceUrl:
        'https://www.volvocars.com/kr/news/corporate/new-name-new-me-say-hello-to-the-ex40-and-ec40/',
    startYear: 2025,
    modelYearStart: 2025,
    displayPeriod: '2025~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volkswagen-golf-gti-official-lineup',
    modelId: 'model-volkswagen-golf-gti-kr',
    sourceName: 'Volkswagen Korea official Golf GTI model page',
    sourceUrl: 'https://www.volkswagen.co.kr/ko/models/golf_gti.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volkswagen-atlas-official-lineup',
    modelId: 'model-volkswagen-atlas-kr',
    sourceName: 'Volkswagen Korea official Atlas model page',
    sourceUrl: 'https://www.volkswagen.co.kr/ko/models/atlas.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volkswagen-id5-official-lineup',
    modelId: 'model-volkswagen-id5-kr',
    sourceName: 'Volkswagen Korea official ID.5 model page',
    sourceUrl: 'https://www.volkswagen.co.kr/ko/models/id5.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.64,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-lexus-lc-official-model-page',
    modelId: 'model-lexus-lc-kr',
    sourceName: 'Lexus Korea official LC 500 model page',
    sourceUrl: 'https://www.lexus.co.kr/models/LC-500/',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.58,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-lexus-rc-official-model-page',
    modelId: 'model-lexus-rc-kr',
    sourceName: 'Lexus Korea official RC 300 F SPORT model page',
    sourceUrl: 'https://www.lexus.co.kr/models/RC-300-F-SPORT/',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.56,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-mini-cooper-5-door-official-lineup',
    modelId: 'model-mini-cooper-5-door-kr',
    sourceName: 'MINI Korea official model range',
    sourceUrl: 'https://www.mini.co.kr/ko_KR/home.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-mini-electric-cooper-official-lineup',
    modelId: 'model-mini-electric-cooper-kr',
    sourceName: 'MINI Korea official model range',
    sourceUrl: 'https://www.mini.co.kr/ko_KR/home.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-mini-electric-countryman-official-lineup',
    modelId: 'model-mini-electric-countryman-kr',
    sourceName: 'MINI Korea official model range',
    sourceUrl: 'https://www.mini.co.kr/ko_KR/home.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-mini-jcw-official-lineup',
    modelId: 'model-mini-jcw-kr',
    sourceName: 'MINI Korea official John Cooper Works page',
    sourceUrl: 'https://www.mini.co.kr/ko_KR/home/range/john-cooper-works.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volkswagen-golf-official-lineup',
    modelId: 'model-volkswagen-089-kr',
    sourceName: 'Volkswagen Korea official Golf model page',
    sourceUrl: 'https://www.volkswagen.co.kr/ko/models/golf.html',
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volkswagen-jetta-official-lineup',
    modelId: 'model-volkswagen-090-kr',
    sourceName: 'Volkswagen Korea official model/news pages',
    sourceUrl:
        'https://www.volkswagen.co.kr/ko/promotion_news/news/2021/2021-03-05.html',
    confidenceScore: 0.52,
    modelYearEnd: 2025,
    displayPeriod: '2015~2025',
    isCurrent: false,
    isSelectable: false,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volkswagen-passat-official-lineup',
    modelId: 'model-volkswagen-091-kr',
    sourceName: 'Volkswagen Korea official model/news pages',
    sourceUrl:
        'https://www.volkswagen.co.kr/ko/promotion_news/news/2021/2021-03-05.html',
    confidenceScore: 0.52,
    modelYearEnd: 2025,
    displayPeriod: '2015~2025',
    isCurrent: false,
    isSelectable: false,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volkswagen-tiguan-official-lineup',
    modelId: 'model-volkswagen-092-kr',
    sourceName: 'Volkswagen Korea official model/news pages',
    sourceUrl:
        'https://www.volkswagen.co.kr/ko/promotion_news/news/news-2022.html',
    confidenceScore: 0.54,
    modelYearEnd: 2025,
    displayPeriod: '2015~2025',
    isCurrent: false,
    isSelectable: false,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volkswagen-touareg-official-lineup',
    modelId: 'model-volkswagen-093-kr',
    sourceName: 'Volkswagen Korea official Touareg model page',
    sourceUrl: 'https://www.volkswagen.co.kr/ko/models/touareg.html',
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volkswagen-id4-official-lineup',
    modelId: 'model-volkswagen-094-id-4',
    sourceName: 'Volkswagen Korea official ID.4 model page',
    sourceUrl: 'https://www.volkswagen.co.kr/ko/models/id4.html',
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-volkswagen-arteon-official-lineup',
    modelId: 'model-volkswagen-095-kr',
    sourceName: 'Volkswagen Korea official model/news pages',
    sourceUrl:
        'https://www.volkswagen.co.kr/ko/promotion_news/news/2021/2021-03-05.html',
    confidenceScore: 0.52,
    modelYearEnd: 2025,
    displayPeriod: '2015~2025',
    isCurrent: false,
    isSelectable: false,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-toyota-prius-official-lineup',
    modelId: 'model-toyota-096-kr',
    sourceName: 'Toyota Korea official model lineup',
    sourceUrl: 'https://www.toyota.co.kr/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-toyota-camry-official-lineup',
    modelId: 'model-toyota-097-kr',
    sourceName: 'Toyota Korea official model lineup',
    sourceUrl: 'https://www.toyota.co.kr/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-toyota-rav4-official-lineup',
    modelId: 'model-toyota-098-4',
    sourceName: 'Toyota Korea official model lineup',
    sourceUrl: 'https://www.toyota.co.kr/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-toyota-highlander-official-lineup',
    modelId: 'model-toyota-099-kr',
    sourceName: 'Toyota Korea official model lineup',
    sourceUrl: 'https://www.toyota.co.kr/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-toyota-sienna-official-lineup',
    modelId: 'model-toyota-100-kr',
    sourceName: 'Toyota Korea official owner/test-drive pages',
    sourceUrl: 'https://www.toyota.co.kr/test-drive/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-toyota-crown-official-lineup',
    modelId: 'model-toyota-101-kr',
    sourceName: 'Toyota Korea official model lineup',
    sourceUrl: 'https://www.toyota.co.kr/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-toyota-gr86-official-lineup',
    modelId: 'model-toyota-102-gr86',
    sourceName: 'Toyota Korea official owner/test-drive pages',
    sourceUrl: 'https://www.toyota.co.kr/test-drive/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-toyota-alphard-official-lineup',
    modelId: 'model-toyota-alphard-kr',
    sourceName: 'Toyota Korea official Alphard page',
    sourceUrl: 'https://www.toyota.co.kr/models/alphard/',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.68,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-lexus-es-official-lineup',
    modelId: 'model-lexus-103-es',
    sourceName: 'Lexus Korea official electrified lineup',
    sourceUrl:
        'https://www.lexus.co.kr/contents/2022-lexus-electrified/electrified',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-lexus-ls-official-lineup',
    modelId: 'model-lexus-104-ls',
    sourceName: 'Lexus Korea official electrified lineup',
    sourceUrl:
        'https://www.lexus.co.kr/contents/2022-lexus-electrified/electrified',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-lexus-nx-official-lineup',
    modelId: 'model-lexus-105-nx',
    sourceName: 'Lexus Korea official electrified lineup',
    sourceUrl:
        'https://www.lexus.co.kr/contents/2022-lexus-electrified/electrified',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-lexus-rx-official-lineup',
    modelId: 'model-lexus-106-rx',
    sourceName: 'Lexus Korea official electrified lineup',
    sourceUrl:
        'https://www.lexus.co.kr/contents/2022-lexus-electrified/electrified',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-lexus-ux-official-lineup',
    modelId: 'model-lexus-107-ux',
    sourceName: 'Lexus Korea official electrified lineup',
    sourceUrl:
        'https://www.lexus.co.kr/contents/2022-lexus-electrified/electrified',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-lexus-rz-official-lineup',
    modelId: 'model-lexus-108-rz',
    sourceName: 'Lexus Korea official electrified lineup',
    sourceUrl:
        'https://www.lexus.co.kr/contents/2022-lexus-electrified/electrified',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-lexus-lm-official-lineup',
    modelId: 'model-lexus-lm-kr',
    sourceName: 'Lexus Korea official LM 500h page',
    sourceUrl: 'https://www.lexus.co.kr/models/LM-500h/',
    startYear: 2025,
    modelYearStart: 2025,
    displayPeriod: '2025~현재',
    confidenceScore: 0.60,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-lexus-lx-official-lineup',
    modelId: 'model-lexus-lx-kr',
    sourceName: 'Lexus Korea official LX model page and model JSON',
    sourceUrl: 'https://www.lexus.co.kr/models/LX/',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.68,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-honda-civic-official-lineup',
    modelId: 'model-honda-109-kr',
    sourceName: 'Honda Korea official online showroom current model list',
    sourceUrl: 'https://auto.hondakorea.co.kr/main/',
    displayPeriod: '국내 공식 현재 라인업 미확인',
    confidenceScore: 0.44,
    isCurrent: false,
    isSelectable: false,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-honda-accord-official-lineup',
    modelId: 'model-honda-110-kr',
    sourceName: 'Honda Korea official online showroom',
    sourceUrl: 'https://auto.hondakorea.co.kr/main/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-honda-cr-v-official-lineup',
    modelId: 'model-honda-111-cr-v',
    sourceName: 'Honda Korea official online showroom',
    sourceUrl: 'https://auto.hondakorea.co.kr/main/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-honda-hr-v-official-lineup',
    modelId: 'model-honda-112-hr-v',
    sourceName: 'Honda Korea official online showroom current model list',
    sourceUrl: 'https://auto.hondakorea.co.kr/main/',
    displayPeriod: '국내 공식 현재 라인업 미확인',
    confidenceScore: 0.44,
    isCurrent: false,
    isSelectable: false,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-honda-pilot-official-lineup',
    modelId: 'model-honda-113-kr',
    sourceName: 'Honda Korea official online showroom',
    sourceUrl: 'https://auto.hondakorea.co.kr/main/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-honda-odyssey-official-lineup',
    modelId: 'model-honda-114-kr',
    sourceName: 'Honda Korea official online showroom',
    sourceUrl: 'https://auto.hondakorea.co.kr/main/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-nissan-altima-official-lineup',
    modelId: 'model-nissan-115-kr',
    sourceName: 'Nissan Korea official withdrawal notice',
    sourceUrl: 'https://www.nissan.co.kr/news_and_events/2002_news_b1.html',
    modelYearEnd: 2020,
    displayPeriod: '2015~2020',
    confidenceScore: 0.52,
    isCurrent: false,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-nissan-maxima-official-lineup',
    modelId: 'model-nissan-116-kr',
    sourceName: 'Nissan Korea official withdrawal notice',
    sourceUrl: 'https://www.nissan.co.kr/news_and_events/2002_news_b1.html',
    modelYearEnd: 2020,
    displayPeriod: '2015~2020',
    confidenceScore: 0.52,
    isCurrent: false,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-nissan-rogue-official-lineup',
    modelId: 'model-nissan-117-kr',
    sourceName: 'Nissan Korea official withdrawal notice',
    sourceUrl: 'https://www.nissan.co.kr/news_and_events/2002_news_b1.html',
    modelYearEnd: 2020,
    displayPeriod: '2015~2020',
    confidenceScore: 0.52,
    isCurrent: false,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-nissan-leaf-official-lineup',
    modelId: 'model-nissan-118-kr',
    sourceName: 'Nissan Korea official Leaf launch and withdrawal notices',
    sourceUrl:
        'https://www.nissan.co.kr/experience-nissan-im/news_and_events/190318.html',
    startYear: 2019,
    modelYearStart: 2019,
    modelYearEnd: 2020,
    displayPeriod: '2019~2020',
    confidenceScore: 0.60,
    isCurrent: false,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-nissan-ariya-official-lineup',
    modelId: 'model-nissan-119-kr',
    sourceName:
        'Nissan Korea official withdrawal notice; Ariya Korea sales unconfirmed',
    sourceUrl: 'https://www.nissan.co.kr/news_and_events/2002_news_b1.html',
    startYear: 2026,
    modelYearStart: 2026,
    modelYearEnd: 2026,
    displayPeriod: '국내 공식 판매 미확인',
    confidenceScore: 0.34,
    isCurrent: false,
    isSelectable: false,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-tesla-model3-official-lineup',
    modelId: 'model-tesla-120-model-3',
    sourceName: 'Tesla Korea official Model 3 page',
    sourceUrl: 'https://www.tesla.com/ko_kr/model3',
    confidenceScore: 0.64,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-tesla-modely-official-lineup',
    modelId: 'model-tesla-121-model-y',
    sourceName: 'Tesla Korea official Model Y page',
    sourceUrl: 'https://www.tesla.com/ko_kr/modely',
    confidenceScore: 0.64,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-tesla-models-official-lineup',
    modelId: 'model-tesla-122-model-s',
    sourceName: 'Tesla Korea official Model S page',
    sourceUrl: 'https://www.tesla.com/ko_kr/models',
    confidenceScore: 0.60,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-tesla-modelx-official-lineup',
    modelId: 'model-tesla-123-model-x',
    sourceName: 'Tesla Korea official Model X page',
    sourceUrl: 'https://www.tesla.com/ko_kr/modelx',
    confidenceScore: 0.60,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-tesla-cybertruck-official-lineup',
    modelId: 'model-tesla-cybertruck-kr',
    sourceName: 'Tesla Korea official Cybertruck page',
    sourceUrl: 'https://www.tesla.com/ko_kr/cybertruck',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.62,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-porsche-911-official-lineup',
    modelId: 'model-porsche-132-911',
    sourceName: 'Porsche Korea official model overview',
    sourceUrl: 'https://www.porsche.com/korea/ko/models/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-porsche-boxster-official-lineup',
    modelId: 'model-porsche-133-kr',
    sourceName: 'Porsche Korea official model overview',
    sourceUrl: 'https://www.porsche.com/korea/ko/models/',
    confidenceScore: 0.54,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-porsche-cayman-official-lineup',
    modelId: 'model-porsche-134-kr',
    sourceName: 'Porsche Korea official model overview',
    sourceUrl: 'https://www.porsche.com/korea/ko/models/',
    confidenceScore: 0.54,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-porsche-panamera-official-lineup',
    modelId: 'model-porsche-135-kr',
    sourceName: 'Porsche Korea official Panamera page',
    sourceUrl: 'https://www.porsche.com/korea/ko/models/panamera/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-porsche-macan-official-lineup',
    modelId: 'model-porsche-136-kr',
    sourceName: 'Porsche Korea official model overview',
    sourceUrl: 'https://www.porsche.com/korea/ko/models/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-porsche-cayenne-official-lineup',
    modelId: 'model-porsche-137-kr',
    sourceName: 'Porsche Korea official Cayenne page',
    sourceUrl: 'https://www.porsche.com/korea/ko/models/Cayenne/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-porsche-taycan-official-lineup',
    modelId: 'model-porsche-138-kr',
    sourceName: 'Porsche Korea official Taycan page',
    sourceUrl: 'https://www.porsche.com/korea/ko/models/taycan/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-mini-hatch-official-lineup',
    modelId: 'model-mini-139-kr',
    sourceName: 'MINI Korea official model range',
    sourceUrl: 'https://www.mini.co.kr/ko_KR/home.html',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-mini-countryman-official-lineup',
    modelId: 'model-mini-140-kr',
    sourceName: 'MINI Korea official model range',
    sourceUrl: 'https://www.mini.co.kr/ko_KR/home.html',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-mini-clubman-official-lineup',
    modelId: 'model-mini-141-kr',
    sourceName: 'MINI Korea official model range/archive',
    sourceUrl: 'https://www.mini.co.kr/ko_KR/home/faqs.html',
    confidenceScore: 0.52,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-mini-cooper-se-official-lineup',
    modelId: 'model-mini-142-se',
    sourceName: 'MINI Korea official model range',
    sourceUrl: 'https://www.mini.co.kr/ko_KR/home.html',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-mini-convertible-official-lineup',
    modelId: 'model-mini-143-kr',
    sourceName: 'MINI Korea official model range',
    sourceUrl: 'https://www.mini.co.kr/ko_KR/home.html',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-mini-aceman-official-lineup',
    modelId: 'model-mini-aceman-kr',
    sourceName: 'MINI Korea official Aceman page',
    sourceUrl:
        'https://www.mini.co.kr/ko_KR/home/range/all-electric-mini-aceman.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.66,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-peugeot-208-official-lineup',
    modelId: 'model-peugeot-144-208',
    sourceName: 'Peugeot Korea official model lineup/archive',
    sourceUrl: 'https://www.epeugeot.co.kr/',
    modelYearEnd: 2025,
    displayPeriod: '2015~2025',
    confidenceScore: 0.50,
    isCurrent: false,
    isSelectable: false,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-peugeot-308-official-lineup',
    modelId: 'model-peugeot-145-308',
    sourceName: 'Peugeot Korea official 308 SMART HYBRID model page',
    sourceUrl: 'https://www.epeugeot.co.kr/new-cars/308hybrid.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.72,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-peugeot-2008-official-lineup',
    modelId: 'model-peugeot-146-2008',
    sourceName: 'Peugeot Korea official model lineup/archive',
    sourceUrl: 'https://www.epeugeot.co.kr/',
    modelYearEnd: 2025,
    displayPeriod: '2015~2025',
    confidenceScore: 0.50,
    isCurrent: false,
    isSelectable: false,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-peugeot-3008-official-lineup',
    modelId: 'model-peugeot-147-3008',
    sourceName: 'Peugeot Korea official 3008 SMART HYBRID model page',
    sourceUrl: 'https://www.epeugeot.co.kr/new-cars/3008hybrid.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.72,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-peugeot-5008-official-lineup',
    modelId: 'model-peugeot-148-5008',
    sourceName: 'Peugeot Korea official 5008 SMART HYBRID model page',
    sourceUrl: 'https://www.epeugeot.co.kr/new-cars/5008hybrid.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.72,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-peugeot-408-official-lineup',
    modelId: 'model-peugeot-408-kr',
    sourceName: 'Peugeot Korea official 408 SMART HYBRID model page',
    sourceUrl: 'https://www.epeugeot.co.kr/new-cars/408hybrid.html',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.72,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-jeep-renegade-official-lineup',
    modelId: 'model-jeep-149-kr',
    sourceName: 'Jeep Korea official promotion/archive pages',
    sourceUrl: 'https://www.jeep.co.kr/promotion.html',
    confidenceScore: 0.50,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-jeep-compass-official-lineup',
    modelId: 'model-jeep-150-kr',
    sourceName: 'Jeep Korea official Compass page',
    sourceUrl: 'https://www.jeep.co.kr/compass.html',
    confidenceScore: 0.54,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-jeep-cherokee-official-lineup',
    modelId: 'model-jeep-151-kr',
    sourceName: 'Jeep Korea official promotion/archive pages',
    sourceUrl: 'https://www.jeep.co.kr/promotion.html',
    confidenceScore: 0.50,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-jeep-wrangler-official-lineup',
    modelId: 'model-jeep-152-kr',
    sourceName: 'Jeep Korea official model lineup',
    sourceUrl: 'https://www.jeep.co.kr/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-jeep-grand-cherokee-official-lineup',
    modelId: 'model-jeep-153-kr',
    sourceName: 'Jeep Korea official model lineup',
    sourceUrl: 'https://www.jeep.co.kr/',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-jeep-gladiator-official-lineup',
    modelId: 'model-jeep-gladiator-kr',
    sourceName: 'Jeep Korea official Gladiator page',
    sourceUrl: 'https://www.jeep.co.kr/gladiator.html',
    startYear: 2025,
    modelYearStart: 2025,
    displayPeriod: '2025~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-jeep-grand-cherokee-l-official-lineup',
    modelId: 'model-jeep-grand-cherokee-l-kr',
    sourceName: 'Jeep Korea official Grand Cherokee L page',
    sourceUrl: 'https://www.jeep.co.kr/grand-cherokee-l.html',
    startYear: 2024,
    modelYearStart: 2024,
    displayPeriod: '2024~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-jeep-avenger-official-lineup',
    modelId: 'model-jeep-avenger-kr',
    sourceName: 'Jeep Korea official Avenger model and battery pages',
    sourceUrl: 'https://www.jeep.co.kr/JL/Avenger.html',
    startYear: 2024,
    modelYearStart: 2024,
    displayPeriod: '2024~현재',
    confidenceScore: 0.64,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-landrover-defender-official-lineup',
    modelId: 'model-landrover-154-kr',
    sourceName: 'Land Rover Korea official model pages',
    sourceUrl: 'https://www.landroverkorea.co.kr/defender/index.html',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-landrover-discovery-official-lineup',
    modelId: 'model-landrover-155-kr',
    sourceName: 'Land Rover Korea official model pages',
    sourceUrl:
        'https://www.landroverkorea.co.kr/discovery/discovery/index.html',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-landrover-range-rover-official-lineup',
    modelId: 'model-landrover-156-kr',
    sourceName: 'Range Rover Korea official model page',
    sourceUrl: 'https://www.rangerover.com/ko-kr/index.html',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-landrover-range-rover-sport-official-lineup',
    modelId: 'model-landrover-157-kr',
    sourceName: 'Range Rover Korea official model page',
    sourceUrl: 'https://www.rangerover.com/ko-kr/range-rover-sport/index.html',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-landrover-range-rover-evoque-official-lineup',
    modelId: 'model-landrover-158-kr',
    sourceName: 'Range Rover Korea official Evoque page',
    sourceUrl:
        'https://www.landroverkorea.co.kr/range-rover/range-rover-evoque/index.html',
  ),
  _LineupGenerationSeed(
    generationId: 'generation-landrover-discovery-sport-official-lineup',
    modelId: 'model-landrover-discovery-sport-kr',
    sourceName: 'Land Rover Korea official price chart',
    sourceUrl:
        'https://www.landroverkorea.co.kr/content/dam/lrdx/pdfs/kr/241118%20RR%20Velar%20Price%20Chart.pdf',
    startYear: 2025,
    modelYearStart: 2025,
    displayPeriod: '2025~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-landrover-range-rover-velar-official-lineup',
    modelId: 'model-landrover-range-rover-velar-kr',
    sourceName: 'Land Rover Korea official price chart',
    sourceUrl:
        'https://www.landroverkorea.co.kr/content/dam/lrdx/pdfs/kr/241118%20RR%20Velar%20Price%20Chart.pdf',
    startYear: 2025,
    modelYearStart: 2025,
    displayPeriod: '2025~현재',
    confidenceScore: 0.62,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-polestar-2-official-lineup',
    modelId: 'model-polestar-159-polestar-2',
    sourceName: 'Polestar Korea official Polestar 2 specifications page',
    sourceUrl: 'https://www.polestar.com/kr/polestar-2/specifications/',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.82,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-polestar-3-official-lineup',
    modelId: 'model-polestar-160-polestar-3',
    sourceName: 'Polestar Korea official Polestar 3 page',
    sourceUrl: 'https://www.polestar.com/kr/polestar-3/',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026년 2분기 출시 예정',
    confidenceScore: 0.62,
    isUpcoming: true,
    isSelectable: false,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-polestar-4-official-lineup',
    modelId: 'model-polestar-161-polestar-4',
    sourceName: 'Polestar Korea official Polestar 4 specifications page',
    sourceUrl:
        'https://www.polestar.com/kr/polestar-4-models/polestar-4-coupe/specifications/',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026~현재',
    confidenceScore: 0.82,
    lockPlaceholderVariants: true,
  ),
  _LineupGenerationSeed(
    generationId: 'generation-polestar-5-official-lineup',
    modelId: 'model-polestar-5-kr',
    sourceName: 'Polestar Korea official Polestar 5 page',
    sourceUrl: 'https://www.polestar.com/kr/polestar-5/',
    startYear: 2026,
    modelYearStart: 2026,
    displayPeriod: '2026년 국내 출시 예정',
    confidenceScore: 0.60,
    isCurrent: false,
    isUpcoming: true,
    isSelectable: false,
    lockPlaceholderVariants: true,
  ),
];

class _LineupGenerationSeed {
  const _LineupGenerationSeed({
    required this.generationId,
    required this.modelId,
    required this.sourceName,
    required this.sourceUrl,
    this.startYear = 2015,
    this.modelYearStart = 2015,
    this.modelYearEnd = 2026,
    this.displayPeriod = '2015~현재',
    this.confidenceScore = 0.56,
    this.isCurrent = true,
    this.isUpcoming = false,
    this.isSelectable = true,
    this.lockPlaceholderVariants = false,
  });

  final String generationId;
  final String modelId;
  final String sourceName;
  final String sourceUrl;
  final int startYear;
  final int modelYearStart;
  final int modelYearEnd;
  final String displayPeriod;
  final double confidenceScore;
  final bool isCurrent;
  final bool isUpcoming;
  final bool isSelectable;
  final bool lockPlaceholderVariants;
}

final _remainingGenerationByModelId = {
  for (final entry in _remainingLineupGenerationData) entry.modelId: entry,
};

final _lockedOfficialLineupModelIds = {
  for (final entry in _remainingLineupGenerationData)
    if (entry.lockPlaceholderVariants) entry.modelId,
  ..._extraLockedOfficialLineupModelIds,
};

const _extraLockedOfficialLineupModelIds = {
  'model-hyundai-001-kr',
  'model-hyundai-002-kr',
  'model-hyundai-003-kr',
  'model-hyundai-004-kr',
  'model-hyundai-005-kr',
  'model-hyundai-006-kr',
  'model-hyundai-007-kr',
  'model-hyundai-008-kr',
  'model-hyundai-009-5',
  'model-hyundai-010-6',
  'model-hyundai-011-kr',
  'model-hyundai-012-kr',
  'model-hyundai-avante-n-kr',
  'model-hyundai-avante-sport-kr',
  'model-kia-013-k3',
  'model-kia-014-k5',
  'model-kia-015-k8',
  'model-kia-016-k9',
  'model-kia-017-kr',
  'model-kia-018-kr',
  'model-kia-019-kr',
  'model-kia-020-kr',
  'model-kia-021-kr',
  'model-kia-022-kr',
  'model-kia-023-kr',
  'model-kia-024-ev3',
  'model-kia-025-ev6',
  'model-kia-026-ev9',
  'model-kia-027-kr',
  'model-volkswagen-089-kr',
  'model-volkswagen-090-kr',
  'model-volkswagen-091-kr',
  'model-volkswagen-092-kr',
  'model-volkswagen-093-kr',
  'model-volkswagen-atlas-kr',
  'model-volkswagen-094-id-4',
  'model-volkswagen-id5-kr',
  'model-volkswagen-095-kr',
  'model-volkswagen-golf-gti-kr',
  'model-peugeot-144-208',
  'model-peugeot-145-308',
  'model-peugeot-146-2008',
  'model-peugeot-147-3008',
  'model-peugeot-148-5008',
  'model-peugeot-408-kr',
  'model-tesla-120-model-3',
  'model-tesla-121-model-y',
  'model-tesla-122-model-s',
  'model-tesla-123-model-x',
  'model-tesla-cybertruck-kr',
  'model-benz-065-a-class',
  'model-benz-066-c-class',
  'model-benz-067-e-class',
  'model-benz-068-s-class',
  'model-benz-069-gla',
  'model-benz-070-glc',
  'model-benz-071-gle',
  'model-benz-072-gls',
  'model-benz-073-eqa',
  'model-benz-074-eqb',
  'model-benz-075-eqe',
  'model-benz-076-eqs',
  'model-benz-s-class-long-kr',
  'model-benz-maybach-s-class-kr',
  'model-benz-eqe-suv-kr',
  'model-benz-maybach-eqs-suv-kr',
  'model-benz-glb-kr',
  'model-benz-glc-coupe-kr',
  'model-benz-gle-coupe-kr',
  'model-benz-maybach-gls-kr',
  'model-benz-g-class-kr',
  'model-benz-cla-coupe-kr',
  'model-benz-cle-coupe-kr',
  'model-benz-amg-gt-coupe-kr',
  'model-benz-amg-gt-4door-coupe-kr',
  'model-benz-cle-cabriolet-kr',
  'model-benz-sl-roadster-kr',
  'model-benz-maybach-sl-monogram-kr',
  'model-audi-077-a3',
  'model-audi-078-a4',
  'model-audi-079-a5',
  'model-audi-080-a6',
  'model-audi-081-a7',
  'model-audi-082-a8',
  'model-audi-083-q3',
  'model-audi-084-q5',
  'model-audi-085-q7',
  'model-audi-086-q8',
  'model-audi-087-e-tron',
  'model-audi-088-q4-e-tron',
  'model-audi-e-tron-gt-kr',
  'model-audi-a6-e-tron-kr',
  'model-audi-q6-e-tron-kr',
  'model-porsche-132-911',
  'model-porsche-133-kr',
  'model-porsche-134-kr',
  'model-porsche-135-kr',
  'model-porsche-136-kr',
  'model-porsche-137-kr',
  'model-porsche-138-kr',
  'model-mini-139-kr',
  'model-mini-140-kr',
  'model-mini-141-kr',
  'model-mini-142-se',
  'model-mini-143-kr',
  'model-mini-aceman-kr',
  'model-mini-cooper-5-door-kr',
  'model-mini-electric-cooper-kr',
  'model-mini-electric-countryman-kr',
  'model-mini-jcw-kr',
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
  'model-lexus-lm-kr',
  'model-honda-109-kr',
  'model-honda-110-kr',
  'model-honda-111-cr-v',
  'model-honda-112-hr-v',
  'model-honda-113-kr',
  'model-honda-114-kr',
  'model-nissan-115-kr',
  'model-nissan-116-kr',
  'model-nissan-117-kr',
  'model-nissan-118-kr',
  'model-nissan-119-kr',
  'model-jeep-149-kr',
  'model-jeep-150-kr',
  'model-jeep-151-kr',
  'model-jeep-152-kr',
  'model-jeep-153-kr',
  'model-jeep-gladiator-kr',
  'model-jeep-grand-cherokee-l-kr',
  'model-jeep-avenger-kr',
  'model-landrover-154-kr',
  'model-landrover-155-kr',
  'model-landrover-156-kr',
  'model-landrover-157-kr',
  'model-landrover-158-kr',
  'model-landrover-discovery-sport-kr',
  'model-landrover-range-rover-velar-kr',
  'model-volvo-124-s60',
  'model-volvo-125-s90',
  'model-volvo-126-xc40',
  'model-volvo-127-xc60',
  'model-volvo-128-xc90',
  'model-volvo-129-c40',
  'model-volvo-130-ex30',
  'model-volvo-131-ex90',
  'model-volvo-v60-cross-country-kr',
  'model-volvo-es90-kr',
  'model-volvo-ex30-cross-country-kr',
  'model-genesis-028-g70',
  'model-genesis-g70-shooting-brake-kr',
  'model-genesis-029-g80',
  'model-genesis-electrified-g80-kr',
  'model-genesis-030-g90',
  'model-genesis-031-gv60',
  'model-genesis-032-gv70',
  'model-genesis-electrified-gv70-kr',
  'model-genesis-033-gv80',
  'model-genesis-gv80-coupe-kr',
  'model-chevrolet-034-kr',
  'model-chevrolet-035-kr',
  'model-chevrolet-036-kr',
  'model-chevrolet-037-kr',
  'model-chevrolet-038-kr',
  'model-chevrolet-039-kr',
  'model-chevrolet-equinox-kr',
  'model-chevrolet-040-kr',
  'model-chevrolet-041-ev',
  'model-renault-042-sm6',
  'model-renault-043-qm6',
  'model-renault-044-xm3',
  'model-renault-arkana-kr',
  'model-renault-045-kr',
  'model-renault-filante-kr',
  'model-kgm-046-kr',
  'model-kgm-047-kr',
  'model-kgm-actyon-kr',
  'model-kgm-actyon-hybrid-kr',
  'model-kgm-048-kr',
  'model-kgm-torres-hybrid-kr',
  'model-kgm-torres-evx-kr',
  'model-kgm-torres-van-kr',
  'model-kgm-torres-evx-van-kr',
  'model-kgm-049-kr',
  'model-kgm-rexton-summit-kr',
  'model-kgm-050-kr',
  'model-kgm-musso-kr',
  'model-kgm-musso-ev-kr',
};

final _remainingGenerationPeriodLabelById = {
  for (final entry in _remainingLineupGenerationData)
    entry.generationId: entry.displayPeriod,
};

List<Map<String, Object?>> _hyundaiRemainingGenerationSeeds() {
  Map<String, Object?> generation({
    required String id,
    required String modelId,
    required int generationOrder,
    required String generationNameKo,
    required String generationNameEn,
    required String generationCode,
    required String platformCode,
    required int startYear,
    int? startMonth,
    int? endYear,
    int? endMonth,
    required String displayPeriod,
    required bool isCurrent,
    required int modelYearStart,
    required int modelYearEnd,
    required String sourceUrl,
    String sourceStatus = 'verified_admin',
    double confidenceScore = 0.72,
  }) {
    return {
      'id': id,
      'model_id': modelId,
      'generation_order': generationOrder,
      'generation_name_ko': generationNameKo,
      'generation_name_en': generationNameEn,
      'generation_code': generationCode,
      'platform_code': platformCode,
      'start_year': startYear,
      'start_month': startMonth,
      'end_year': endYear,
      'end_month': endMonth,
      'display_period': displayPeriod,
      'is_current': isCurrent,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': sourceStatus,
      'confidence_score': confidenceScore,
      'source_name': 'Hyundai Motor model history and software version list',
      'source_url': sourceUrl,
      'source_file_name': null,
      'last_verified_at': '2026-06-13',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = modelYearStart; year <= modelYearEnd; year += 1)
          'year-${modelId.substring(6)}-$year',
      ],
    };
  }

  return [
    generation(
      id: 'generation-hyundai-avante-n-cn7',
      modelId: 'model-hyundai-avante-n-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'CN7 N/CN7 N PE',
      platformCode: 'CN7',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
      sourceUrl:
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/avante-history',
    ),
    generation(
      id: 'generation-hyundai-avante-sport-ad',
      modelId: 'model-hyundai-avante-sport-kr',
      generationOrder: 1,
      generationNameKo: 'AD 스포츠',
      generationNameEn: 'Avante Sport',
      generationCode: 'AD Sport',
      platformCode: 'AD',
      startYear: 2016,
      endYear: 2018,
      displayPeriod: '2016~2018',
      isCurrent: false,
      modelYearStart: 2016,
      modelYearEnd: 2018,
      sourceUrl:
          'https://update.hyundai.com/KR/KO/updateNoticeView/software-version',
      sourceStatus: 'pending_review',
      confidenceScore: 0.58,
    ),
    generation(
      id: 'generation-hyundai-kona-os',
      modelId: 'model-hyundai-004-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'OS/OS PE',
      platformCode: 'OS',
      startYear: 2017,
      endYear: 2023,
      displayPeriod: '2017~2023',
      isCurrent: false,
      modelYearStart: 2017,
      modelYearEnd: 2022,
      sourceUrl:
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/kona-history',
    ),
    generation(
      id: 'generation-hyundai-kona-sx2',
      modelId: 'model-hyundai-004-kr',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'SX2/SX2 PE',
      platformCode: 'SX2',
      startYear: 2023,
      displayPeriod: '2023~현재',
      isCurrent: true,
      modelYearStart: 2023,
      modelYearEnd: 2026,
      sourceUrl:
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/kona-history',
    ),
    generation(
      id: 'generation-hyundai-palisade-lx2',
      modelId: 'model-hyundai-007-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'LX2/LX2 PE',
      platformCode: 'LX2',
      startYear: 2018,
      endYear: 2024,
      displayPeriod: '2018~2024',
      isCurrent: false,
      modelYearStart: 2019,
      modelYearEnd: 2024,
      sourceUrl:
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/palisade-history',
    ),
    generation(
      id: 'generation-hyundai-palisade-lx3',
      modelId: 'model-hyundai-007-kr',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'LX3',
      platformCode: 'LX3',
      startYear: 2025,
      startMonth: 1,
      displayPeriod: '2025.1~현재',
      isCurrent: true,
      modelYearStart: 2025,
      modelYearEnd: 2026,
      sourceUrl:
          'https://www.hyundai.com/kr/ko/e/vehicles/the-all-new-palisade/intro',
    ),
    generation(
      id: 'generation-hyundai-casper-ax1',
      modelId: 'model-hyundai-008-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'AX1/AX1 PE',
      platformCode: 'AX1',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
      sourceUrl:
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/casper-history',
    ),
    generation(
      id: 'generation-hyundai-staria-us4',
      modelId: 'model-hyundai-011-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'US4/US4 PE',
      platformCode: 'US4',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
      sourceUrl:
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/staria-history',
    ),
    generation(
      id: 'generation-hyundai-porter2-hr',
      modelId: 'model-hyundai-012-kr',
      generationOrder: 4,
      generationNameKo: '포터 II',
      generationNameEn: 'Porter II',
      generationCode: 'HR/HR PE',
      platformCode: 'HR',
      startYear: 2004,
      displayPeriod: '2004~현재',
      isCurrent: true,
      modelYearStart: 2015,
      modelYearEnd: 2026,
      sourceUrl:
          'https://www.hyundai.com/kr/ko/brand/brandstory/model/porter-history',
    ),
  ];
}

List<Map<String, Object?>> _chevroletGenerationSeeds() {
  Map<String, Object?> generation({
    required String id,
    required String modelId,
    required int generationOrder,
    required String generationNameKo,
    required String generationNameEn,
    required String generationCode,
    required String platformCode,
    required int startYear,
    int? endYear,
    required String displayPeriod,
    required bool isCurrent,
    required int modelYearStart,
    required int modelYearEnd,
    double confidenceScore = 0.58,
    String sourceName = 'Chevrolet Korea newsroom and type-price pages',
    String sourceUrl = 'https://www.chevrolet.co.kr/finance/type-price',
  }) {
    return {
      'id': id,
      'model_id': modelId,
      'generation_order': generationOrder,
      'generation_name_ko': generationNameKo,
      'generation_name_en': generationNameEn,
      'generation_code': generationCode,
      'platform_code': platformCode,
      'start_year': startYear,
      'start_month': null,
      'end_year': endYear,
      'end_month': null,
      'display_period': displayPeriod,
      'is_current': isCurrent,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'pending_review',
      'confidence_score': confidenceScore,
      'source_name': sourceName,
      'source_url': sourceUrl,
      'source_file_name': null,
      'last_verified_at': null,
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = modelYearStart; year <= modelYearEnd; year += 1)
          'year-${modelId.substring(6)}-$year',
      ],
    };
  }

  return [
    generation(
      id: 'generation-chevrolet-spark-m400',
      modelId: 'model-chevrolet-034-kr',
      generationOrder: 2,
      generationNameKo: 'M400',
      generationNameEn: 'M400 generation',
      generationCode: 'M400',
      platformCode: 'Gamma II',
      startYear: 2015,
      endYear: 2022,
      displayPeriod: '2015~2022',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2022,
    ),
    generation(
      id: 'generation-chevrolet-malibu-v300',
      modelId: 'model-chevrolet-035-kr',
      generationOrder: 8,
      generationNameKo: '8세대',
      generationNameEn: 'Eighth generation',
      generationCode: 'V300',
      platformCode: 'Epsilon II',
      startYear: 2011,
      endYear: 2016,
      displayPeriod: '2011~2016',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2015,
      confidenceScore: 0.55,
    ),
    generation(
      id: 'generation-chevrolet-malibu-v400',
      modelId: 'model-chevrolet-035-kr',
      generationOrder: 9,
      generationNameKo: '9세대',
      generationNameEn: 'Ninth generation',
      generationCode: 'V400',
      platformCode: 'E2XX',
      startYear: 2016,
      endYear: 2022,
      displayPeriod: '2016~2022',
      isCurrent: false,
      modelYearStart: 2016,
      modelYearEnd: 2022,
    ),
    generation(
      id: 'generation-chevrolet-trax-u200',
      modelId: 'model-chevrolet-036-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'U200',
      platformCode: 'Gamma II',
      startYear: 2013,
      endYear: 2022,
      displayPeriod: '2013~2022',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2022,
    ),
    generation(
      id: 'generation-chevrolet-trax-crossover-9bqc',
      modelId: 'model-chevrolet-036-kr',
      generationOrder: 2,
      generationNameKo: '트랙스 크로스오버',
      generationNameEn: 'Trax Crossover',
      generationCode: '9BQC',
      platformCode: 'VSS-F',
      startYear: 2023,
      displayPeriod: '2023~현재',
      isCurrent: true,
      modelYearStart: 2023,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-chevrolet-trailblazer-vss-f',
      modelId: 'model-chevrolet-037-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'VSS-F',
      platformCode: 'VSS-F',
      startYear: 2020,
      displayPeriod: '2020~현재',
      isCurrent: true,
      modelYearStart: 2020,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-chevrolet-traverse-c1xx',
      modelId: 'model-chevrolet-038-kr',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'C1XX',
      platformCode: 'C1XX',
      startYear: 2019,
      displayPeriod: '2019~현재',
      isCurrent: true,
      modelYearStart: 2019,
      modelYearEnd: 2026,
      confidenceScore: 0.6,
      sourceName: 'Chevrolet Korea official SUV lineup page',
      sourceUrl: 'https://www.chevrolet.co.kr/suvs',
    ),
    generation(
      id: 'generation-chevrolet-tahoe-t1xx',
      modelId: 'model-chevrolet-039-kr',
      generationOrder: 5,
      generationNameKo: '5세대',
      generationNameEn: 'Fifth generation',
      generationCode: 'T1XX',
      platformCode: 'GMT1YC',
      startYear: 2022,
      displayPeriod: '2022~현재',
      isCurrent: true,
      modelYearStart: 2022,
      modelYearEnd: 2026,
      confidenceScore: 0.6,
      sourceName: 'Chevrolet Korea official SUV lineup page',
      sourceUrl: 'https://www.chevrolet.co.kr/suvs',
    ),
    generation(
      id: 'generation-chevrolet-equinox-official-lineup',
      modelId: 'model-chevrolet-equinox-kr',
      generationOrder: 1,
      generationNameKo: '공식 라인업',
      generationNameEn: 'Official lineup',
      generationCode: '',
      platformCode: '',
      startYear: 2026,
      displayPeriod: '2026~현재',
      isCurrent: true,
      modelYearStart: 2026,
      modelYearEnd: 2026,
      confidenceScore: 0.62,
      sourceName: 'Chevrolet Korea official SUV lineup page',
      sourceUrl: 'https://www.chevrolet.co.kr/suvs',
    ),
    generation(
      id: 'generation-chevrolet-colorado-rg',
      modelId: 'model-chevrolet-040-kr',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'RG',
      platformCode: '31XX',
      startYear: 2019,
      endYear: 2023,
      displayPeriod: '2019~2023',
      isCurrent: false,
      modelYearStart: 2019,
      modelYearEnd: 2023,
    ),
    generation(
      id: 'generation-chevrolet-colorado-31xx-2',
      modelId: 'model-chevrolet-040-kr',
      generationOrder: 3,
      generationNameKo: '3세대',
      generationNameEn: 'Third generation',
      generationCode: '31XX-2',
      platformCode: '31XX-2',
      startYear: 2024,
      displayPeriod: '2024~현재',
      isCurrent: true,
      modelYearStart: 2024,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-chevrolet-bolt-ev-g2cx',
      modelId: 'model-chevrolet-041-ev',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'G2CX',
      platformCode: 'BEV2',
      startYear: 2017,
      endYear: 2023,
      displayPeriod: '2017~2023',
      isCurrent: false,
      modelYearStart: 2017,
      modelYearEnd: 2023,
      confidenceScore: 0.56,
    ),
  ];
}

List<Map<String, Object?>> _volvoGenerationSeeds() {
  Map<String, Object?> generation({
    required String id,
    required String modelId,
    required int generationOrder,
    required String generationNameKo,
    required String generationNameEn,
    required String generationCode,
    required String platformCode,
    required int startYear,
    int? endYear,
    required String displayPeriod,
    required bool isCurrent,
    required int modelYearStart,
    required int modelYearEnd,
    required String sourceUrl,
    String sourceName = 'Volvo Cars media and Volvo Korea current lineup',
    double confidenceScore = 0.62,
  }) {
    return {
      'id': id,
      'model_id': modelId,
      'generation_order': generationOrder,
      'generation_name_ko': generationNameKo,
      'generation_name_en': generationNameEn,
      'generation_code': generationCode,
      'platform_code': platformCode,
      'start_year': startYear,
      'start_month': null,
      'end_year': endYear,
      'end_month': null,
      'display_period': displayPeriod,
      'is_current': isCurrent,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'pending_review',
      'confidence_score': confidenceScore,
      'source_name': sourceName,
      'source_url': sourceUrl,
      'source_file_name': null,
      'last_verified_at': '2026-06-13',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = modelYearStart; year <= modelYearEnd; year += 1)
          'year-${modelId.substring(6)}-$year',
      ],
    };
  }

  return [
    generation(
      id: 'generation-volvo-s60-p3',
      modelId: 'model-volvo-124-s60',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'P3',
      platformCode: 'P3',
      startYear: 2010,
      endYear: 2018,
      displayPeriod: '2010~2018',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2018,
      sourceUrl:
          'https://www.volvocars.com/us/media/press-releases/4DA080AF252FD9FF/',
      confidenceScore: 0.56,
    ),
    generation(
      id: 'generation-volvo-s60-spa',
      modelId: 'model-volvo-124-s60',
      generationOrder: 3,
      generationNameKo: '3세대',
      generationNameEn: 'Third generation',
      generationCode: 'SPA',
      platformCode: 'SPA',
      startYear: 2018,
      endYear: 2025,
      displayPeriod: '2018~2025',
      isCurrent: false,
      modelYearStart: 2019,
      modelYearEnd: 2025,
      sourceUrl:
          'https://www.volvocars.com/us/media/press-releases/221545E8824EBEFC/',
      confidenceScore: 0.64,
    ),
    generation(
      id: 'generation-volvo-s90-spa',
      modelId: 'model-volvo-125-s90',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'SPA',
      platformCode: 'SPA',
      startYear: 2016,
      displayPeriod: '2016~현재',
      isCurrent: true,
      modelYearStart: 2016,
      modelYearEnd: 2026,
      sourceUrl:
          'https://www.volvocars.com/us/media/press-releases/42E0670260E4D00D/',
      confidenceScore: 0.64,
    ),
    generation(
      id: 'generation-volvo-xc40-cma',
      modelId: 'model-volvo-126-xc40',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'CMA',
      platformCode: 'CMA',
      startYear: 2017,
      displayPeriod: '2017~현재',
      isCurrent: true,
      modelYearStart: 2018,
      modelYearEnd: 2026,
      sourceUrl: 'https://www.volvocars.com/us/media/press-releases/217972/',
      confidenceScore: 0.64,
    ),
    generation(
      id: 'generation-volvo-xc60-p3',
      modelId: 'model-volvo-127-xc60',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'P3',
      platformCode: 'P3',
      startYear: 2008,
      endYear: 2017,
      displayPeriod: '2008~2017',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2017,
      sourceUrl: 'https://www.volvocars.com/us/media/press-releases/184814/',
      confidenceScore: 0.56,
    ),
    generation(
      id: 'generation-volvo-xc60-spa',
      modelId: 'model-volvo-127-xc60',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'SPA',
      platformCode: 'SPA',
      startYear: 2017,
      displayPeriod: '2017~현재',
      isCurrent: true,
      modelYearStart: 2018,
      modelYearEnd: 2026,
      sourceUrl: 'https://www.volvocars.com/us/media/press-releases/184814/',
      confidenceScore: 0.64,
    ),
    generation(
      id: 'generation-volvo-xc90-spa',
      modelId: 'model-volvo-128-xc90',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'SPA',
      platformCode: 'SPA',
      startYear: 2014,
      displayPeriod: '2014~현재',
      isCurrent: true,
      modelYearStart: 2015,
      modelYearEnd: 2026,
      sourceUrl: 'https://www.volvocars.com/kr/',
      confidenceScore: 0.6,
    ),
    generation(
      id: 'generation-volvo-c40-cma',
      modelId: 'model-volvo-129-c40',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'C40',
      platformCode: 'CMA',
      startYear: 2021,
      endYear: 2024,
      displayPeriod: '2021~2024',
      isCurrent: false,
      modelYearStart: 2022,
      modelYearEnd: 2024,
      sourceUrl: 'https://www.volvocars.com/us/media/press-releases/277409/',
      confidenceScore: 0.58,
    ),
    generation(
      id: 'generation-volvo-ex30',
      modelId: 'model-volvo-130-ex30',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'EX30',
      platformCode: '',
      startYear: 2025,
      displayPeriod: '2025~현재',
      isCurrent: true,
      modelYearStart: 2025,
      modelYearEnd: 2026,
      sourceUrl:
          'https://www.volvocars.com/us/media/models/ex30/2025/press-releases/',
      confidenceScore: 0.58,
    ),
    generation(
      id: 'generation-volvo-ex90',
      modelId: 'model-volvo-131-ex90',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'EX90',
      platformCode: '',
      startYear: 2026,
      displayPeriod: '2026~현재',
      isCurrent: true,
      modelYearStart: 2026,
      modelYearEnd: 2026,
      sourceUrl: 'https://www.volvocars.com/kr/',
      confidenceScore: 0.54,
    ),
    generation(
      id: 'generation-volvo-v60-cross-country-spa',
      modelId: 'model-volvo-v60-cross-country-kr',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'SPA',
      platformCode: 'SPA',
      startYear: 2018,
      displayPeriod: '2018~현재',
      isCurrent: true,
      modelYearStart: 2019,
      modelYearEnd: 2026,
      sourceUrl: 'https://www.volvocars.com/us/media/press-releases/240100/',
      confidenceScore: 0.62,
    ),
  ];
}

List<Map<String, Object?>> _kiaGenerationSeeds() {
  Map<String, Object?> generation({
    required String id,
    required String modelId,
    required int generationOrder,
    required String generationNameKo,
    required String generationNameEn,
    required String generationCode,
    required String platformCode,
    required int startYear,
    int? endYear,
    required String displayPeriod,
    required bool isCurrent,
    required int modelYearStart,
    required int modelYearEnd,
    double confidenceScore = 0.74,
  }) {
    return {
      'id': id,
      'model_id': modelId,
      'generation_order': generationOrder,
      'generation_name_ko': generationNameKo,
      'generation_name_en': generationNameEn,
      'generation_code': generationCode,
      'platform_code': platformCode,
      'start_year': startYear,
      'start_month': null,
      'end_year': endYear,
      'end_month': null,
      'display_period': displayPeriod,
      'is_current': isCurrent,
      'is_upcoming': false,
      'market_region': 'KR',
      'source_status': 'verified_admin',
      'confidence_score': confidenceScore,
      'source_name': 'Kia software version list',
      'source_url':
          'https://update.kia.com/KR/KO/updateNoticeView/software-version',
      'source_file_name': null,
      'last_verified_at': '2026-06-12',
      'is_selectable': true,
      'is_deprecated': false,
      'model_year_ids': [
        for (var year = modelYearStart; year <= modelYearEnd; year += 1)
          'year-${modelId.substring(6)}-$year',
      ],
    };
  }

  return [
    generation(
      id: 'generation-kia-k5-jf',
      modelId: 'model-kia-014-k5',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'JF/JF PE',
      platformCode: 'JF',
      startYear: 2015,
      endYear: 2019,
      displayPeriod: '2015~2019',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2018,
    ),
    generation(
      id: 'generation-kia-k5-dl3',
      modelId: 'model-kia-014-k5',
      generationOrder: 3,
      generationNameKo: '3세대',
      generationNameEn: 'Third generation',
      generationCode: 'DL3/DL3 PE',
      platformCode: 'DL3',
      startYear: 2019,
      displayPeriod: '2019~현재',
      isCurrent: true,
      modelYearStart: 2019,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-kia-k8-gl3',
      modelId: 'model-kia-015-k8',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'GL3/GL3 PE',
      platformCode: 'GL3',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-kia-k9-kh',
      modelId: 'model-kia-016-k9',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'KH/KH PE',
      platformCode: 'KH',
      startYear: 2012,
      endYear: 2018,
      displayPeriod: '2012~2018',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2017,
    ),
    generation(
      id: 'generation-kia-k9-rj',
      modelId: 'model-kia-016-k9',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'RJ/RJ PE',
      platformCode: 'RJ',
      startYear: 2018,
      displayPeriod: '2018~현재',
      isCurrent: true,
      modelYearStart: 2018,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-kia-morning-ta',
      modelId: 'model-kia-017-kr',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'TA/TA PE',
      platformCode: 'TA',
      startYear: 2011,
      endYear: 2017,
      displayPeriod: '2011~2017',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2016,
    ),
    generation(
      id: 'generation-kia-morning-ja',
      modelId: 'model-kia-017-kr',
      generationOrder: 3,
      generationNameKo: '3세대',
      generationNameEn: 'Third generation',
      generationCode: 'JA/JA PE',
      platformCode: 'JA',
      startYear: 2017,
      displayPeriod: '2017~현재',
      isCurrent: true,
      modelYearStart: 2017,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-kia-ray-tam',
      modelId: 'model-kia-018-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'TAM/TAM PE',
      platformCode: 'TAM',
      startYear: 2011,
      displayPeriod: '2011~현재',
      isCurrent: true,
      modelYearStart: 2015,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-kia-seltos-sp2',
      modelId: 'model-kia-019-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'SP2/SP2 PE',
      platformCode: 'SP2',
      startYear: 2019,
      displayPeriod: '2019~현재',
      isCurrent: true,
      modelYearStart: 2019,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-kia-niro-de',
      modelId: 'model-kia-020-kr',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'DE/DE PE',
      platformCode: 'DE',
      startYear: 2016,
      endYear: 2021,
      displayPeriod: '2016~2021',
      isCurrent: false,
      modelYearStart: 2016,
      modelYearEnd: 2021,
    ),
    generation(
      id: 'generation-kia-niro-sg2',
      modelId: 'model-kia-020-kr',
      generationOrder: 2,
      generationNameKo: '2세대',
      generationNameEn: 'Second generation',
      generationCode: 'SG2/SG2 PE',
      platformCode: 'SG2',
      startYear: 2022,
      displayPeriod: '2022~현재',
      isCurrent: true,
      modelYearStart: 2022,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-kia-sportage-ql',
      modelId: 'model-kia-021-kr',
      generationOrder: 4,
      generationNameKo: '4세대',
      generationNameEn: 'Fourth generation',
      generationCode: 'QL/QL PE',
      platformCode: 'QL',
      startYear: 2015,
      endYear: 2021,
      displayPeriod: '2015~2021',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2021,
    ),
    generation(
      id: 'generation-kia-sportage-nq5',
      modelId: 'model-kia-021-kr',
      generationOrder: 5,
      generationNameKo: '5세대',
      generationNameEn: 'Fifth generation',
      generationCode: 'NQ5/NQ5 PE',
      platformCode: 'NQ5',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2022,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-kia-sorento-um',
      modelId: 'model-kia-022-kr',
      generationOrder: 3,
      generationNameKo: '3세대',
      generationNameEn: 'Third generation',
      generationCode: 'UM/UM PE',
      platformCode: 'UM',
      startYear: 2014,
      endYear: 2020,
      displayPeriod: '2014~2020',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2019,
    ),
    generation(
      id: 'generation-kia-sorento-mq4',
      modelId: 'model-kia-022-kr',
      generationOrder: 4,
      generationNameKo: '4세대',
      generationNameEn: 'Fourth generation',
      generationCode: 'MQ4/MQ4 PE',
      platformCode: 'MQ4',
      startYear: 2020,
      displayPeriod: '2020~현재',
      isCurrent: true,
      modelYearStart: 2020,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-kia-carnival-yp',
      modelId: 'model-kia-023-kr',
      generationOrder: 3,
      generationNameKo: '3세대',
      generationNameEn: 'Third generation',
      generationCode: 'YP/YP PE',
      platformCode: 'YP',
      startYear: 2014,
      endYear: 2020,
      displayPeriod: '2014~2020',
      isCurrent: false,
      modelYearStart: 2015,
      modelYearEnd: 2020,
    ),
    generation(
      id: 'generation-kia-carnival-ka4',
      modelId: 'model-kia-023-kr',
      generationOrder: 4,
      generationNameKo: '4세대',
      generationNameEn: 'Fourth generation',
      generationCode: 'KA4/KA4 PE',
      platformCode: 'KA4',
      startYear: 2020,
      displayPeriod: '2020~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-kia-ev3-sv1',
      modelId: 'model-kia-024-ev3',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'SV1',
      platformCode: 'E-GMP',
      startYear: 2024,
      displayPeriod: '2024~현재',
      isCurrent: true,
      modelYearStart: 2024,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-kia-ev6-cv',
      modelId: 'model-kia-025-ev6',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'CV/CV PE',
      platformCode: 'E-GMP',
      startYear: 2021,
      displayPeriod: '2021~현재',
      isCurrent: true,
      modelYearStart: 2021,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-kia-ev9-mv1',
      modelId: 'model-kia-026-ev9',
      generationOrder: 1,
      generationNameKo: '1세대',
      generationNameEn: 'First generation',
      generationCode: 'MV1',
      platformCode: 'E-GMP',
      startYear: 2023,
      displayPeriod: '2023~현재',
      isCurrent: true,
      modelYearStart: 2023,
      modelYearEnd: 2026,
    ),
    generation(
      id: 'generation-kia-bongo-pu',
      modelId: 'model-kia-027-kr',
      generationOrder: 4,
      generationNameKo: '4세대',
      generationNameEn: 'Fourth generation',
      generationCode: 'PU/PU PE',
      platformCode: 'PU',
      startYear: 2004,
      displayPeriod: '2004~현재',
      isCurrent: true,
      modelYearStart: 2015,
      modelYearEnd: 2026,
    ),
  ];
}

String? _generationIdFor(String modelId, int year) {
  final remainingGeneration = _remainingGenerationByModelId[modelId];
  if (remainingGeneration != null &&
      year >= remainingGeneration.modelYearStart &&
      year <= remainingGeneration.modelYearEnd) {
    return remainingGeneration.generationId;
  }
  if (modelId == 'model-hyundai-001-kr' && year >= 2020 && year <= 2026) {
    return 'generation-hyundai-avante-cn7';
  }
  if (modelId == 'model-hyundai-001-kr' && year >= 2015 && year <= 2019) {
    return 'generation-hyundai-avante-ad';
  }
  if (modelId == 'model-hyundai-009-5' && year >= 2021 && year <= 2026) {
    return 'generation-hyundai-ioniq5-ne';
  }
  if (modelId == 'model-hyundai-010-6' && year >= 2022 && year <= 2026) {
    return 'generation-hyundai-ioniq6-ce';
  }
  if (modelId == 'model-hyundai-002-kr' && year >= 2015 && year <= 2018) {
    return 'generation-hyundai-sonata-lf';
  }
  if (modelId == 'model-hyundai-002-kr' && year >= 2019 && year <= 2026) {
    return 'generation-hyundai-sonata-dn8';
  }
  if (modelId == 'model-hyundai-003-kr' && year >= 2015 && year <= 2016) {
    return 'generation-hyundai-grandeur-hg';
  }
  if (modelId == 'model-hyundai-003-kr' && year >= 2017 && year <= 2022) {
    return 'generation-hyundai-grandeur-ig';
  }
  if (modelId == 'model-hyundai-003-kr' && year >= 2023 && year <= 2026) {
    return 'generation-hyundai-grandeur-gn7';
  }
  if (modelId == 'model-hyundai-005-kr' && year >= 2015 && year <= 2019) {
    return 'generation-hyundai-tucson-tl';
  }
  if (modelId == 'model-hyundai-005-kr' && year >= 2020 && year <= 2026) {
    return 'generation-hyundai-tucson-nx4';
  }
  if (modelId == 'model-hyundai-006-kr' && year >= 2015 && year <= 2017) {
    return 'generation-hyundai-santafe-dm';
  }
  if (modelId == 'model-hyundai-006-kr' && year >= 2018 && year <= 2022) {
    return 'generation-hyundai-santafe-tm';
  }
  if (modelId == 'model-hyundai-006-kr' && year >= 2023 && year <= 2026) {
    return 'generation-hyundai-santafe-mx5';
  }
  if (modelId == 'model-hyundai-avante-n-kr' && year >= 2021 && year <= 2026) {
    return 'generation-hyundai-avante-n-cn7';
  }
  if (modelId == 'model-hyundai-avante-sport-kr' &&
      year >= 2016 &&
      year <= 2018) {
    return 'generation-hyundai-avante-sport-ad';
  }
  if (modelId == 'model-hyundai-004-kr' && year >= 2017 && year <= 2022) {
    return 'generation-hyundai-kona-os';
  }
  if (modelId == 'model-hyundai-004-kr' && year >= 2023 && year <= 2026) {
    return 'generation-hyundai-kona-sx2';
  }
  if (modelId == 'model-hyundai-007-kr' && year >= 2019 && year <= 2024) {
    return 'generation-hyundai-palisade-lx2';
  }
  if (modelId == 'model-hyundai-007-kr' && year >= 2025 && year <= 2026) {
    return 'generation-hyundai-palisade-lx3';
  }
  if (modelId == 'model-hyundai-008-kr' && year >= 2021 && year <= 2026) {
    return 'generation-hyundai-casper-ax1';
  }
  if (modelId == 'model-hyundai-011-kr' && year >= 2021 && year <= 2026) {
    return 'generation-hyundai-staria-us4';
  }
  if (modelId == 'model-hyundai-012-kr' && year >= 2015 && year <= 2026) {
    return 'generation-hyundai-porter2-hr';
  }
  if (modelId == 'model-genesis-028-g70' && year >= 2017 && year <= 2026) {
    return 'generation-genesis-g70-1';
  }
  if (modelId == 'model-genesis-g70-shooting-brake-kr' &&
      year >= 2022 &&
      year <= 2026) {
    return 'generation-genesis-g70-shooting-brake-1';
  }
  if (modelId == 'model-genesis-029-g80' && year >= 2016 && year <= 2019) {
    return 'generation-genesis-g80-2';
  }
  if (modelId == 'model-genesis-029-g80' && year >= 2020 && year <= 2026) {
    return 'generation-genesis-g80-3';
  }
  if (modelId == 'model-genesis-electrified-g80-kr' &&
      year >= 2021 &&
      year <= 2026) {
    return 'generation-genesis-electrified-g80-1';
  }
  if (modelId == 'model-genesis-030-g90' && year >= 2019 && year <= 2021) {
    return 'generation-genesis-g90-1';
  }
  if (modelId == 'model-genesis-030-g90' && year >= 2022 && year <= 2026) {
    return 'generation-genesis-g90-2';
  }
  if (modelId == 'model-genesis-031-gv60' && year >= 2021 && year <= 2026) {
    return 'generation-genesis-gv60-1';
  }
  if (modelId == 'model-genesis-032-gv70' && year >= 2021 && year <= 2026) {
    return 'generation-genesis-gv70-1';
  }
  if (modelId == 'model-genesis-electrified-gv70-kr' &&
      year >= 2022 &&
      year <= 2026) {
    return 'generation-genesis-electrified-gv70-1';
  }
  if (modelId == 'model-genesis-033-gv80' && year >= 2020 && year <= 2026) {
    return 'generation-genesis-gv80-1';
  }
  if (modelId == 'model-genesis-gv80-coupe-kr' &&
      year >= 2024 &&
      year <= 2026) {
    return 'generation-genesis-gv80-coupe-1';
  }
  if (modelId == 'model-chevrolet-034-kr' && year >= 2015 && year <= 2022) {
    return 'generation-chevrolet-spark-m400';
  }
  if (modelId == 'model-chevrolet-035-kr' && year == 2015) {
    return 'generation-chevrolet-malibu-v300';
  }
  if (modelId == 'model-chevrolet-035-kr' && year >= 2016 && year <= 2022) {
    return 'generation-chevrolet-malibu-v400';
  }
  if (modelId == 'model-chevrolet-036-kr' && year >= 2015 && year <= 2022) {
    return 'generation-chevrolet-trax-u200';
  }
  if (modelId == 'model-chevrolet-036-kr' && year >= 2023 && year <= 2026) {
    return 'generation-chevrolet-trax-crossover-9bqc';
  }
  if (modelId == 'model-chevrolet-037-kr' && year >= 2020 && year <= 2026) {
    return 'generation-chevrolet-trailblazer-vss-f';
  }
  if (modelId == 'model-chevrolet-038-kr' && year >= 2019 && year <= 2026) {
    return 'generation-chevrolet-traverse-c1xx';
  }
  if (modelId == 'model-chevrolet-039-kr' && year >= 2022 && year <= 2026) {
    return 'generation-chevrolet-tahoe-t1xx';
  }
  if (modelId == 'model-chevrolet-equinox-kr' && year == 2026) {
    return 'generation-chevrolet-equinox-official-lineup';
  }
  if (modelId == 'model-chevrolet-040-kr' && year >= 2019 && year <= 2023) {
    return 'generation-chevrolet-colorado-rg';
  }
  if (modelId == 'model-chevrolet-040-kr' && year >= 2024 && year <= 2026) {
    return 'generation-chevrolet-colorado-31xx-2';
  }
  if (modelId == 'model-chevrolet-041-ev' && year >= 2017 && year <= 2023) {
    return 'generation-chevrolet-bolt-ev-g2cx';
  }
  if (modelId == 'model-renault-042-sm6' && year >= 2016 && year <= 2024) {
    return 'generation-renault-sm6-1';
  }
  if (modelId == 'model-renault-043-qm6' && year >= 2016 && year <= 2024) {
    return 'generation-renault-qm6-1';
  }
  if (modelId == 'model-renault-044-xm3' && year >= 2020 && year <= 2023) {
    return 'generation-renault-xm3-1';
  }
  if (modelId == 'model-renault-arkana-kr' && year >= 2024 && year <= 2026) {
    return 'generation-renault-arkana-1';
  }
  if (modelId == 'model-renault-045-kr' && year >= 2025 && year <= 2026) {
    return 'generation-renault-grand-koleos-1';
  }
  if (modelId == 'model-renault-filante-kr' && year == 2026) {
    return 'generation-renault-filante-1';
  }
  if (modelId == 'model-kgm-046-kr' && year >= 2015 && year <= 2026) {
    return 'generation-kgm-tivoli-1';
  }
  if (modelId == 'model-kgm-047-kr' && year >= 2019 && year <= 2024) {
    return 'generation-kgm-korando-c300';
  }
  if (modelId == 'model-kgm-actyon-kr' && year >= 2024 && year <= 2026) {
    return 'generation-kgm-actyon-j120';
  }
  if (modelId == 'model-kgm-actyon-hybrid-kr' && year >= 2025 && year <= 2026) {
    return 'generation-kgm-actyon-hybrid-j120';
  }
  if (modelId == 'model-kgm-048-kr' && year >= 2022 && year <= 2026) {
    return 'generation-kgm-torres-j100';
  }
  if (modelId == 'model-kgm-torres-hybrid-kr' && year >= 2025 && year <= 2026) {
    return 'generation-kgm-torres-hybrid-j100';
  }
  if (modelId == 'model-kgm-torres-evx-kr' && year >= 2023 && year <= 2026) {
    return 'generation-kgm-torres-evx-j100';
  }
  if (modelId == 'model-kgm-torres-van-kr' && year == 2026) {
    return 'generation-kgm-torres-van-official-lineup';
  }
  if (modelId == 'model-kgm-torres-evx-van-kr' && year == 2026) {
    return 'generation-kgm-torres-evx-van-official-lineup';
  }
  if (modelId == 'model-kgm-049-kr' && year >= 2017 && year <= 2026) {
    return 'generation-kgm-rexton-y400';
  }
  if (modelId == 'model-kgm-rexton-summit-kr' && year == 2026) {
    return 'generation-kgm-rexton-summit-official-lineup';
  }
  if (modelId == 'model-kgm-050-kr' && year >= 2018 && year <= 2025) {
    return 'generation-kgm-rexton-sports-q200';
  }
  if (modelId == 'model-kgm-musso-kr' && year >= 2025 && year <= 2026) {
    return 'generation-kgm-musso-q300';
  }
  if (modelId == 'model-kgm-musso-ev-kr' && year >= 2025 && year <= 2026) {
    return 'generation-kgm-musso-ev-q300';
  }
  if (modelId == 'model-volvo-124-s60' && year >= 2015 && year <= 2018) {
    return 'generation-volvo-s60-p3';
  }
  if (modelId == 'model-volvo-124-s60' && year >= 2019 && year <= 2025) {
    return 'generation-volvo-s60-spa';
  }
  if (modelId == 'model-volvo-125-s90' && year >= 2016 && year <= 2026) {
    return 'generation-volvo-s90-spa';
  }
  if (modelId == 'model-volvo-126-xc40' && year >= 2018 && year <= 2026) {
    return 'generation-volvo-xc40-cma';
  }
  if (modelId == 'model-volvo-127-xc60' && year >= 2015 && year <= 2017) {
    return 'generation-volvo-xc60-p3';
  }
  if (modelId == 'model-volvo-127-xc60' && year >= 2018 && year <= 2026) {
    return 'generation-volvo-xc60-spa';
  }
  if (modelId == 'model-volvo-128-xc90' && year >= 2015 && year <= 2026) {
    return 'generation-volvo-xc90-spa';
  }
  if (modelId == 'model-volvo-129-c40' && year >= 2022 && year <= 2024) {
    return 'generation-volvo-c40-cma';
  }
  if (modelId == 'model-volvo-130-ex30' && year >= 2025 && year <= 2026) {
    return 'generation-volvo-ex30';
  }
  if (modelId == 'model-volvo-131-ex90' && year == 2026) {
    return 'generation-volvo-ex90';
  }
  if (modelId == 'model-volvo-v60-cross-country-kr' &&
      year >= 2019 &&
      year <= 2026) {
    return 'generation-volvo-v60-cross-country-spa';
  }
  if (modelId == 'model-kia-013-k3' && year >= 2018 && year <= 2024) {
    return 'generation-kia-k3-bd';
  }
  if (modelId == 'model-kia-013-k3' && year >= 2015 && year <= 2017) {
    return 'generation-kia-k3-yd';
  }
  if (modelId == 'model-kia-014-k5' && year >= 2015 && year <= 2018) {
    return 'generation-kia-k5-jf';
  }
  if (modelId == 'model-kia-014-k5' && year >= 2019 && year <= 2026) {
    return 'generation-kia-k5-dl3';
  }
  if (modelId == 'model-kia-015-k8' && year >= 2021 && year <= 2026) {
    return 'generation-kia-k8-gl3';
  }
  if (modelId == 'model-kia-016-k9' && year >= 2015 && year <= 2017) {
    return 'generation-kia-k9-kh';
  }
  if (modelId == 'model-kia-016-k9' && year >= 2018 && year <= 2026) {
    return 'generation-kia-k9-rj';
  }
  if (modelId == 'model-kia-017-kr' && year >= 2015 && year <= 2016) {
    return 'generation-kia-morning-ta';
  }
  if (modelId == 'model-kia-017-kr' && year >= 2017 && year <= 2026) {
    return 'generation-kia-morning-ja';
  }
  if (modelId == 'model-kia-018-kr' && year >= 2015 && year <= 2026) {
    return 'generation-kia-ray-tam';
  }
  if (modelId == 'model-kia-019-kr' && year >= 2019 && year <= 2026) {
    return 'generation-kia-seltos-sp2';
  }
  if (modelId == 'model-kia-020-kr' && year >= 2016 && year <= 2021) {
    return 'generation-kia-niro-de';
  }
  if (modelId == 'model-kia-020-kr' && year >= 2022 && year <= 2026) {
    return 'generation-kia-niro-sg2';
  }
  if (modelId == 'model-kia-021-kr' && year >= 2015 && year <= 2021) {
    return 'generation-kia-sportage-ql';
  }
  if (modelId == 'model-kia-021-kr' && year >= 2022 && year <= 2026) {
    return 'generation-kia-sportage-nq5';
  }
  if (modelId == 'model-kia-022-kr' && year >= 2015 && year <= 2019) {
    return 'generation-kia-sorento-um';
  }
  if (modelId == 'model-kia-022-kr' && year >= 2020 && year <= 2026) {
    return 'generation-kia-sorento-mq4';
  }
  if (modelId == 'model-kia-023-kr' && year >= 2015 && year <= 2020) {
    return 'generation-kia-carnival-yp';
  }
  if (modelId == 'model-kia-023-kr' && year >= 2021 && year <= 2026) {
    return 'generation-kia-carnival-ka4';
  }
  if (modelId == 'model-kia-024-ev3' && year >= 2024 && year <= 2026) {
    return 'generation-kia-ev3-sv1';
  }
  if (modelId == 'model-kia-025-ev6' && year >= 2021 && year <= 2026) {
    return 'generation-kia-ev6-cv';
  }
  if (modelId == 'model-kia-026-ev9' && year >= 2023 && year <= 2026) {
    return 'generation-kia-ev9-mv1';
  }
  if (modelId == 'model-kia-027-kr' && year >= 2015 && year <= 2026) {
    return 'generation-kia-bongo-pu';
  }
  if (modelId == 'model-benz-065-a-class' && year >= 2015 && year <= 2017) {
    return 'generation-benz-a-class-w176';
  }
  if (modelId == 'model-benz-065-a-class' && year >= 2018 && year <= 2026) {
    return 'generation-benz-a-class-w177';
  }
  if (modelId == 'model-benz-066-c-class' && year >= 2015 && year <= 2020) {
    return 'generation-benz-c-class-w205';
  }
  if (modelId == 'model-benz-066-c-class' && year >= 2021 && year <= 2026) {
    return 'generation-benz-c-class-w206';
  }
  if (modelId == 'model-benz-067-e-class' && year == 2015) {
    return 'generation-benz-e-class-w212';
  }
  if (modelId == 'model-benz-067-e-class' && year >= 2016 && year <= 2023) {
    return 'generation-benz-e-class-w213';
  }
  if (modelId == 'model-benz-067-e-class' && year >= 2024 && year <= 2026) {
    return 'generation-benz-e-class-w214';
  }
  if (modelId == 'model-benz-068-s-class' && year >= 2015 && year <= 2020) {
    return 'generation-benz-s-class-w222';
  }
  if (modelId == 'model-benz-068-s-class' && year >= 2021 && year <= 2026) {
    return 'generation-benz-s-class-w223';
  }
  if (modelId == 'model-benz-069-gla' && year >= 2015 && year <= 2019) {
    return 'generation-benz-gla-x156';
  }
  if (modelId == 'model-benz-069-gla' && year >= 2020 && year <= 2026) {
    return 'generation-benz-gla-h247';
  }
  if (modelId == 'model-benz-070-glc' && year >= 2015 && year <= 2022) {
    return 'generation-benz-glc-x253';
  }
  if (modelId == 'model-benz-070-glc' && year >= 2023 && year <= 2026) {
    return 'generation-benz-glc-x254';
  }
  if (modelId == 'model-benz-071-gle' && year >= 2015 && year <= 2018) {
    return 'generation-benz-gle-w166';
  }
  if (modelId == 'model-benz-071-gle' && year >= 2019 && year <= 2026) {
    return 'generation-benz-gle-v167';
  }
  if (modelId == 'model-benz-072-gls' && year >= 2015 && year <= 2019) {
    return 'generation-benz-gls-x166';
  }
  if (modelId == 'model-benz-072-gls' && year >= 2020 && year <= 2026) {
    return 'generation-benz-gls-x167';
  }
  if (modelId == 'model-benz-073-eqa' && year >= 2021 && year <= 2026) {
    return 'generation-benz-eqa-h243';
  }
  if (modelId == 'model-benz-074-eqb' && year >= 2022 && year <= 2026) {
    return 'generation-benz-eqb-x243';
  }
  if (modelId == 'model-benz-075-eqe' && year >= 2022 && year <= 2026) {
    return 'generation-benz-eqe-v295';
  }
  if (modelId == 'model-benz-076-eqs' && year >= 2021 && year <= 2026) {
    return 'generation-benz-eqs-v297';
  }
  if (modelId == 'model-audi-077-a3' && year >= 2015 && year <= 2019) {
    return 'generation-audi-a3-8v';
  }
  if (modelId == 'model-audi-077-a3' && year >= 2020 && year <= 2026) {
    return 'generation-audi-a3-8y';
  }
  if (modelId == 'model-audi-078-a4' && year >= 2015 && year <= 2024) {
    return 'generation-audi-a4-b9-8w';
  }
  if (modelId == 'model-audi-079-a5' && year == 2015) {
    return 'generation-audi-a5-8t';
  }
  if (modelId == 'model-audi-079-a5' && year >= 2016 && year <= 2023) {
    return 'generation-audi-a5-f5';
  }
  if (modelId == 'model-audi-079-a5' && year >= 2024 && year <= 2026) {
    return 'generation-audi-a5-b10';
  }
  if (modelId == 'model-audi-080-a6' && year >= 2015 && year <= 2018) {
    return 'generation-audi-a6-c7-4g';
  }
  if (modelId == 'model-audi-080-a6' && year >= 2019 && year <= 2024) {
    return 'generation-audi-a6-c8-4a';
  }
  if (modelId == 'model-audi-080-a6' && year >= 2025 && year <= 2026) {
    return 'generation-audi-a6-c9';
  }
  if (modelId == 'model-audi-081-a7' && year >= 2015 && year <= 2017) {
    return 'generation-audi-a7-4g8';
  }
  if (modelId == 'model-audi-081-a7' && year >= 2018 && year <= 2025) {
    return 'generation-audi-a7-4k8';
  }
  if (modelId == 'model-audi-082-a8' && year >= 2015 && year <= 2017) {
    return 'generation-audi-a8-d4-4h';
  }
  if (modelId == 'model-audi-082-a8' && year >= 2018 && year <= 2026) {
    return 'generation-audi-a8-d5-4n';
  }
  if (modelId == 'model-audi-083-q3' && year >= 2015 && year <= 2018) {
    return 'generation-audi-q3-8u';
  }
  if (modelId == 'model-audi-083-q3' && year >= 2019 && year <= 2024) {
    return 'generation-audi-q3-f3';
  }
  if (modelId == 'model-audi-083-q3' && year >= 2025 && year <= 2026) {
    return 'generation-audi-q3-2025';
  }
  if (modelId == 'model-audi-084-q5' && year >= 2015 && year <= 2016) {
    return 'generation-audi-q5-8r';
  }
  if (modelId == 'model-audi-084-q5' && year >= 2017 && year <= 2024) {
    return 'generation-audi-q5-fy';
  }
  if (modelId == 'model-audi-084-q5' && year >= 2025 && year <= 2026) {
    return 'generation-audi-q5-2025';
  }
  if (modelId == 'model-audi-085-q7' && year >= 2015 && year <= 2026) {
    return 'generation-audi-q7-4m';
  }
  if (modelId == 'model-audi-086-q8' && year >= 2018 && year <= 2026) {
    return 'generation-audi-q8-4m';
  }
  if (modelId == 'model-audi-087-e-tron' && year >= 2018 && year <= 2022) {
    return 'generation-audi-e-tron-ge';
  }
  if (modelId == 'model-audi-087-e-tron' && year >= 2023 && year <= 2025) {
    return 'generation-audi-q8-e-tron-ge';
  }
  if (modelId == 'model-audi-088-q4-e-tron' && year >= 2021 && year <= 2026) {
    return 'generation-audi-q4-e-tron-f4';
  }
  if (modelId == 'model-bmw-051-1' && year >= 2015 && year <= 2019) {
    return 'generation-bmw-1series-f20';
  }
  if (modelId == 'model-bmw-051-1' && year >= 2020 && year <= 2024) {
    return 'generation-bmw-1series-f40';
  }
  if (modelId == 'model-bmw-051-1' && year >= 2025 && year <= 2026) {
    return 'generation-bmw-1series-f70';
  }
  if (modelId == 'model-bmw-052-2' && year >= 2015 && year <= 2021) {
    return 'generation-bmw-2series-coupe-f22';
  }
  if (modelId == 'model-bmw-052-2' && year >= 2022 && year <= 2026) {
    return 'generation-bmw-2series-coupe-g42';
  }
  if (modelId == 'model-bmw-061-i4' && year >= 2022 && year <= 2026) {
    return 'generation-bmw-i4-g26';
  }
  if (modelId == 'model-bmw-053-3' && year >= 2015 && year <= 2018) {
    return 'generation-bmw-3series-f30';
  }
  if (modelId == 'model-bmw-053-3' && year >= 2019 && year <= 2026) {
    return 'generation-bmw-3series-g20';
  }
  if (modelId == 'model-bmw-054-4' && year >= 2015 && year <= 2020) {
    return 'generation-bmw-4series-f32-f33-f36';
  }
  if (modelId == 'model-bmw-054-4' && year >= 2021 && year <= 2026) {
    return 'generation-bmw-4series-g22-g23-g26';
  }
  if (modelId == 'model-bmw-055-5' && year >= 2017 && year <= 2023) {
    return 'generation-bmw-5series-g30';
  }
  if (modelId == 'model-bmw-055-5' && year >= 2015 && year <= 2016) {
    return 'generation-bmw-5series-f10';
  }
  if (modelId == 'model-bmw-055-5' && year >= 2024 && year <= 2026) {
    return 'generation-bmw-5series-g60';
  }
  if (modelId == 'model-bmw-056-7' && year >= 2015 && year <= 2022) {
    return 'generation-bmw-7series-g11-g12';
  }
  if (modelId == 'model-bmw-056-7' && year >= 2023 && year <= 2026) {
    return 'generation-bmw-7series-g70';
  }
  if (modelId == 'model-bmw-057-x1' && year == 2015) {
    return 'generation-bmw-x1-e84';
  }
  if (modelId == 'model-bmw-057-x1' && year >= 2016 && year <= 2022) {
    return 'generation-bmw-x1-f48';
  }
  if (modelId == 'model-bmw-057-x1' && year >= 2023 && year <= 2026) {
    return 'generation-bmw-x1-u11';
  }
  if (modelId == 'model-bmw-058-x3' && year >= 2015 && year <= 2017) {
    return 'generation-bmw-x3-f25';
  }
  if (modelId == 'model-bmw-058-x3' && year >= 2018 && year <= 2024) {
    return 'generation-bmw-x3-g01';
  }
  if (modelId == 'model-bmw-058-x3' && year >= 2025 && year <= 2026) {
    return 'generation-bmw-x3-g45';
  }
  if (modelId == 'model-bmw-059-x5' && year >= 2015 && year <= 2018) {
    return 'generation-bmw-x5-f15';
  }
  if (modelId == 'model-bmw-059-x5' && year >= 2019 && year <= 2026) {
    return 'generation-bmw-x5-g05';
  }
  if (modelId == 'model-bmw-060-x7' && year >= 2019 && year <= 2026) {
    return 'generation-bmw-x7-g07';
  }
  if (modelId == 'model-bmw-062-i5' && year >= 2024 && year <= 2026) {
    return 'generation-bmw-i5-g60';
  }
  if (modelId == 'model-bmw-063-ix' && year >= 2022 && year <= 2026) {
    return 'generation-bmw-ix-i20';
  }
  if (modelId == 'model-bmw-064-ix3' && year >= 2022 && year <= 2026) {
    return 'generation-bmw-ix3-g08';
  }
  return null;
}

String _generationPeriodLabel(String generationId) {
  final remainingLabel = _remainingGenerationPeriodLabelById[generationId];
  if (remainingLabel != null) {
    return remainingLabel;
  }
  return switch (generationId) {
    'generation-hyundai-avante-ad' => '2015~2020.4',
    'generation-hyundai-avante-cn7' => '2020.4~현재',
    'generation-hyundai-ioniq5-ne' => '2021.2~현재',
    'generation-hyundai-ioniq6-ce' => '2022.7~현재',
    'generation-hyundai-sonata-lf' => '2014~2019',
    'generation-hyundai-sonata-dn8' => '2019~현재',
    'generation-hyundai-grandeur-hg' => '2011~2016',
    'generation-hyundai-grandeur-ig' => '2016~2022',
    'generation-hyundai-grandeur-gn7' => '2022~현재',
    'generation-hyundai-tucson-tl' => '2015~2020',
    'generation-hyundai-tucson-nx4' => '2020~현재',
    'generation-hyundai-santafe-dm' => '2012~2018',
    'generation-hyundai-santafe-tm' => '2018~2023',
    'generation-hyundai-santafe-mx5' => '2023~현재',
    'generation-hyundai-avante-n-cn7' => '2021~현재',
    'generation-hyundai-avante-sport-ad' => '2016~2018',
    'generation-hyundai-kona-os' => '2017~2023',
    'generation-hyundai-kona-sx2' => '2023~현재',
    'generation-hyundai-palisade-lx2' => '2018~2024',
    'generation-hyundai-palisade-lx3' => '2025.1~현재',
    'generation-hyundai-casper-ax1' => '2021~현재',
    'generation-hyundai-staria-us4' => '2021~현재',
    'generation-hyundai-porter2-hr' => '2004~현재',
    'generation-genesis-g70-1' => '2017~현재',
    'generation-genesis-g70-shooting-brake-1' => '2022~현재',
    'generation-genesis-g80-2' => '2016~2019',
    'generation-genesis-g80-3' => '2020~현재',
    'generation-genesis-electrified-g80-1' => '2021~현재',
    'generation-genesis-g90-1' => '2019~2021',
    'generation-genesis-g90-2' => '2021~현재',
    'generation-genesis-gv60-1' => '2021~현재',
    'generation-genesis-gv70-1' => '2020~현재',
    'generation-genesis-electrified-gv70-1' => '2022~현재',
    'generation-genesis-gv80-1' => '2020~현재',
    'generation-genesis-gv80-coupe-1' => '2023~현재',
    'generation-chevrolet-spark-m400' => '2015~2022',
    'generation-chevrolet-malibu-v300' => '2011~2016',
    'generation-chevrolet-malibu-v400' => '2016~2022',
    'generation-chevrolet-trax-u200' => '2013~2022',
    'generation-chevrolet-trax-crossover-9bqc' => '2023~현재',
    'generation-chevrolet-trailblazer-vss-f' => '2020~현재',
    'generation-chevrolet-traverse-c1xx' => '2019~현재',
    'generation-chevrolet-tahoe-t1xx' => '2022~현재',
    'generation-chevrolet-equinox-official-lineup' => '2026~현재',
    'generation-chevrolet-colorado-rg' => '2019~2023',
    'generation-chevrolet-colorado-31xx-2' => '2024~현재',
    'generation-chevrolet-bolt-ev-g2cx' => '2017~2023',
    'generation-renault-sm6-1' => '2016~2024',
    'generation-renault-qm6-1' => '2016~2024',
    'generation-renault-xm3-1' => '2020~2023',
    'generation-renault-arkana-1' => '2024~현재',
    'generation-renault-grand-koleos-1' => '2024~현재',
    'generation-renault-filante-1' => '2026~현재',
    'generation-kgm-tivoli-1' => '2015~현재',
    'generation-kgm-korando-c300' => '2019~2024',
    'generation-kgm-actyon-j120' => '2024~현재',
    'generation-kgm-actyon-hybrid-j120' => '2025~현재',
    'generation-kgm-torres-j100' => '2022~현재',
    'generation-kgm-torres-hybrid-j100' => '2025~현재',
    'generation-kgm-torres-evx-j100' => '2023~현재',
    'generation-kgm-torres-van-official-lineup' => '2026~현재',
    'generation-kgm-torres-evx-van-official-lineup' => '2026~현재',
    'generation-kgm-rexton-y400' => '2017~현재',
    'generation-kgm-rexton-summit-official-lineup' => '2026~현재',
    'generation-kgm-rexton-sports-q200' => '2018~2025',
    'generation-kgm-musso-q300' => '2025~현재',
    'generation-kgm-musso-ev-q300' => '2025~현재',
    'generation-volvo-s60-p3' => '2010~2018',
    'generation-volvo-s60-spa' => '2018~2025',
    'generation-volvo-s90-spa' => '2016~현재',
    'generation-volvo-xc40-cma' => '2017~현재',
    'generation-volvo-xc60-p3' => '2008~2017',
    'generation-volvo-xc60-spa' => '2017~현재',
    'generation-volvo-xc90-spa' => '2014~현재',
    'generation-volvo-c40-cma' => '2021~2024',
    'generation-volvo-ex30' => '2025~현재',
    'generation-volvo-ex90' => '2026~현재',
    'generation-volvo-v60-cross-country-spa' => '2018~현재',
    'generation-kia-k3-yd' => '2015~2018.2',
    'generation-kia-k3-bd' => '2018.2~2024',
    'generation-kia-k5-jf' => '2015~2019',
    'generation-kia-k5-dl3' => '2019~현재',
    'generation-kia-k8-gl3' => '2021~현재',
    'generation-kia-k9-kh' => '2012~2018',
    'generation-kia-k9-rj' => '2018~현재',
    'generation-kia-morning-ta' => '2011~2017',
    'generation-kia-morning-ja' => '2017~현재',
    'generation-kia-ray-tam' => '2011~현재',
    'generation-kia-seltos-sp2' => '2019~현재',
    'generation-kia-niro-de' => '2016~2021',
    'generation-kia-niro-sg2' => '2022~현재',
    'generation-kia-sportage-ql' => '2015~2021',
    'generation-kia-sportage-nq5' => '2021~현재',
    'generation-kia-sorento-um' => '2014~2020',
    'generation-kia-sorento-mq4' => '2020~현재',
    'generation-kia-carnival-yp' => '2014~2020',
    'generation-kia-carnival-ka4' => '2020~현재',
    'generation-kia-ev3-sv1' => '2024~현재',
    'generation-kia-ev6-cv' => '2021~현재',
    'generation-kia-ev9-mv1' => '2023~현재',
    'generation-kia-bongo-pu' => '2004~현재',
    'generation-benz-a-class-w176' => '2012~2018',
    'generation-benz-a-class-w177' => '2018~현재',
    'generation-benz-c-class-w205' => '2014~2021',
    'generation-benz-c-class-w206' => '2021~현재',
    'generation-benz-e-class-w212' => '2009~2016',
    'generation-benz-e-class-w213' => '2016~2023',
    'generation-benz-e-class-w214' => '2023~현재',
    'generation-benz-s-class-w222' => '2013~2020',
    'generation-benz-s-class-w223' => '2020~현재',
    'generation-benz-gla-x156' => '2014~2020',
    'generation-benz-gla-h247' => '2020~현재',
    'generation-benz-glc-x253' => '2015~2022',
    'generation-benz-glc-x254' => '2022~현재',
    'generation-benz-gle-w166' => '2015~2019',
    'generation-benz-gle-v167' => '2019~현재',
    'generation-benz-gls-x166' => '2015~2019',
    'generation-benz-gls-x167' => '2019~현재',
    'generation-benz-eqa-h243' => '2021~현재',
    'generation-benz-eqb-x243' => '2021~현재',
    'generation-benz-eqe-v295' => '2022~현재',
    'generation-benz-eqs-v297' => '2021~현재',
    'generation-audi-a3-8v' => '2012~2020',
    'generation-audi-a3-8y' => '2020~현재',
    'generation-audi-a4-b9-8w' => '2015~2024',
    'generation-audi-a5-8t' => '2007~2016',
    'generation-audi-a5-f5' => '2016~2024',
    'generation-audi-a5-b10' => '2024~현재',
    'generation-audi-a6-c7-4g' => '2011~2018',
    'generation-audi-a6-c8-4a' => '2018~2025',
    'generation-audi-a6-c9' => '2025~현재',
    'generation-audi-a7-4g8' => '2010~2017',
    'generation-audi-a7-4k8' => '2017~2025',
    'generation-audi-a8-d4-4h' => '2010~2017',
    'generation-audi-a8-d5-4n' => '2017~현재',
    'generation-audi-q3-8u' => '2011~2018',
    'generation-audi-q3-f3' => '2018~2025',
    'generation-audi-q3-2025' => '2025~현재',
    'generation-audi-q5-8r' => '2008~2017',
    'generation-audi-q5-fy' => '2017~2024',
    'generation-audi-q5-2025' => '2024~현재',
    'generation-audi-q7-4m' => '2015~현재',
    'generation-audi-q8-4m' => '2018~현재',
    'generation-audi-e-tron-ge' => '2018~2022',
    'generation-audi-q8-e-tron-ge' => '2023~2025',
    'generation-audi-q4-e-tron-f4' => '2021~현재',
    'generation-bmw-1series-f20' => '2012.10~2019',
    'generation-bmw-1series-f40' => '2020.1~2024',
    'generation-bmw-1series-f70' => '2024.10~현재',
    'generation-bmw-2series-coupe-f22' => '2013~2021',
    'generation-bmw-2series-coupe-g42' => '2021.7~현재',
    'generation-bmw-i4-g26' => '2022.4~현재',
    'generation-bmw-3series-f30' => '2012~2018',
    'generation-bmw-3series-g20' => '2019.3~현재',
    'generation-bmw-4series-f32-f33-f36' => '2013.10~2020',
    'generation-bmw-4series-g22-g23-g26' => '2021.2~현재',
    'generation-bmw-5series-f10' => '2015~2016',
    'generation-bmw-5series-g30' => '2017~2023',
    'generation-bmw-5series-g60' => '2023.10~현재',
    'generation-bmw-7series-g11-g12' => '2015.10~2022',
    'generation-bmw-7series-g70' => '2022.12~현재',
    'generation-bmw-x1-e84' => '2010.2~2015',
    'generation-bmw-x1-f48' => '2016.2~2022',
    'generation-bmw-x1-u11' => '2023.3~현재',
    'generation-bmw-x3-f25' => '2011~2017',
    'generation-bmw-x3-g01' => '2017.11~2024',
    'generation-bmw-x3-g45' => '2024.11~현재',
    'generation-bmw-x5-f15' => '2013.11~2018',
    'generation-bmw-x5-g05' => '2018.11~현재',
    'generation-bmw-x7-g07' => '2019~현재',
    'generation-bmw-i5-g60' => '2024.3~현재',
    'generation-bmw-ix-i20' => '2022~현재',
    'generation-bmw-ix3-g08' => '2022~현재',
    _ => '',
  };
}

String _slug(int index, String text) {
  final ascii = text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return '${index.toString().padLeft(3, '0')}-${ascii.isEmpty ? 'kr' : ascii}';
}

String _fuelLeagueFor(String fuelType) {
  return switch (fuelType) {
    '가솔린' => 'gasoline',
    '디젤' => 'diesel',
    '하이브리드' => 'hybrid',
    '전기차' => 'electric',
    '수소전기차' || '수소차' => 'hydrogen',
    'LPG' => 'lpg',
    '플러그인 하이브리드' => 'plug_in_hybrid',
    _ => 'other',
  };
}

String _efficiencyUnitFor(String fuelType) {
  if (fuelType == '수소전기차' || fuelType == '수소차') {
    return 'km/kg';
  }
  return fuelType == '전기차' ? 'km/kWh' : 'km/L';
}

String _engineNameFor(String fuelType, String vehicleClass) {
  final displacement = _displacementLiterFor(fuelType, vehicleClass);
  return switch (fuelType) {
    '전기차' => 'Electric Motor',
    '수소전기차' || '수소차' => 'Fuel Cell Electric Motor',
    '하이브리드' => '$displacement Hybrid',
    '플러그인 하이브리드' => '$displacement PHEV',
    '디젤' => '$displacement Diesel',
    'LPG' => '$displacement LPi',
    _ => '$displacement Gasoline',
  };
}

String _powertrainLabelFor(String fuelType, String vehicleClass) {
  if (fuelType == '전기차') {
    return '전기차';
  }
  if (fuelType == '수소전기차' || fuelType == '수소차') {
    return '수소전기차';
  }
  final displacement = _displacementLiterFor(fuelType, vehicleClass);
  final label = fuelType == 'LPG' ? 'LPi' : fuelType;
  return '$displacement $label';
}

String _displacementLiterFor(String fuelType, String vehicleClass) {
  final cc = _displacementCcFor(fuelType, vehicleClass);
  if (cc == null) {
    return '';
  }
  return (cc / 1000).toStringAsFixed(1);
}

int? _displacementCcFor(String fuelType, String vehicleClass) {
  if (fuelType == '전기차' || fuelType == '수소전기차' || fuelType == '수소차') {
    return null;
  }
  if (vehicleClass == '경형') {
    return 998;
  }
  if (vehicleClass == '소형' ||
      vehicleClass == '준중형' ||
      vehicleClass == '소형 SUV') {
    return 1598;
  }
  if (vehicleClass == '중형' || vehicleClass == 'SUV') {
    return fuelType == '하이브리드' || fuelType == '플러그인 하이브리드' ? 1598 : 1999;
  }
  if (vehicleClass == '대형' ||
      vehicleClass == '대형 SUV' ||
      vehicleClass == 'MPV') {
    return fuelType == '하이브리드' || fuelType == '플러그인 하이브리드' ? 1598 : 2497;
  }
  if (vehicleClass == '픽업' || vehicleClass == '상용') {
    return 2497;
  }
  if (vehicleClass == '스포츠') {
    return 1998;
  }
  return 1999;
}

double? _batteryKwhFor(String fuelType, String vehicleClass) {
  if (fuelType != '전기차') {
    return null;
  }
  if (vehicleClass == '경형' ||
      vehicleClass == '소형' ||
      vehicleClass == '소형 SUV') {
    return 45.0;
  }
  if (vehicleClass == '대형' ||
      vehicleClass == '대형 SUV' ||
      vehicleClass == 'MPV') {
    return 90.0;
  }
  if (vehicleClass == '픽업' || vehicleClass == '상용') {
    return 68.0;
  }
  return 64.0;
}

String _drivetrainFor(String modelId, String fuelType, int year) {
  if (fuelType == '전기차') {
    return '전동 구동';
  }
  if (modelId == 'model-bmw-051-1') {
    return year <= 2019 ? 'RWD' : 'FWD';
  }
  if (modelId == 'model-bmw-052-2') {
    return 'RWD';
  }
  if (modelId == 'model-volvo-v60-cross-country-kr') {
    return 'AWD';
  }
  return switch (modelId) {
    'model-bmw-053-3' ||
    'model-bmw-054-4' ||
    'model-bmw-055-5' ||
    'model-bmw-056-7' =>
      'RWD',
    'model-bmw-057-x1' ||
    'model-bmw-058-x3' ||
    'model-bmw-059-x5' ||
    'model-bmw-060-x7' =>
      'AWD',
    'model-porsche-132-911' ||
    'model-porsche-133-kr' ||
    'model-porsche-134-kr' ||
    'model-porsche-135-kr' =>
      'RWD',
    'model-porsche-136-kr' || 'model-porsche-137-kr' => 'AWD',
    _ => 'FWD',
  };
}

String _transmissionFor(String fuelType) {
  return switch (fuelType) {
    '전기차' => '감속기',
    '수소전기차' || '수소차' => '감속기',
    '하이브리드' || '플러그인 하이브리드' => '하이브리드 전용 변속기',
    _ => '자동',
  };
}

int _fuelSortOrderFor(String fuelType) {
  return switch (_fuelLeagueFor(fuelType)) {
    'gasoline' => 10,
    'hybrid' => 20,
    'lpg' => 30,
    'diesel' => 40,
    'electric' => 50,
    'plug_in_hybrid' => 60,
    'hydrogen' => 70,
    _ => 90,
  };
}

List<OfficialPowertrain> _officialOverrides(
  String modelId,
  int year,
  String fuelType,
) {
  final fuelLeague = _fuelLeagueFor(fuelType);
  if (year == 2026) {
    final kiaLineupOverrides = _kia2026OfficialLineupPowertrains(
      modelId,
      fuelLeague,
    );
    if (kiaLineupOverrides.isNotEmpty) {
      return kiaLineupOverrides;
    }
    final peugeotOverrides = _peugeot2026OfficialPowertrains(
      modelId,
      fuelLeague,
    );
    if (peugeotOverrides.isNotEmpty) {
      return peugeotOverrides;
    }
    final teslaOverrides = _tesla2026OfficialPowertrains(
      modelId,
      fuelLeague,
    );
    if (teslaOverrides.isNotEmpty) {
      return teslaOverrides;
    }
    final polestarOverrides = _polestar2026OfficialPowertrains(
      modelId,
      fuelLeague,
    );
    if (polestarOverrides.isNotEmpty) {
      return polestarOverrides;
    }
  }
  final exact = _officialPowertrains['$modelId|$year|$fuelLeague'];
  if (exact != null) {
    return [exact];
  }
  if (year == 2026) {
    final volkswagenOverrides = _volkswagen2026OfficialPowertrains(
      modelId,
      fuelLeague,
    );
    if (volkswagenOverrides.isNotEmpty) {
      return volkswagenOverrides;
    }
    final toyotaOverrides = _toyota2026OfficialPowertrains(
      modelId,
      fuelLeague,
    );
    if (toyotaOverrides.isNotEmpty) {
      return toyotaOverrides;
    }
    final lexusOverrides = _lexus2026OfficialPowertrains(
      modelId,
      fuelLeague,
    );
    if (lexusOverrides.isNotEmpty) {
      return lexusOverrides;
    }
    final landRoverOverrides = _landRover2026OfficialPowertrains(
      modelId,
      fuelLeague,
    );
    if (landRoverOverrides.isNotEmpty) {
      return landRoverOverrides;
    }
    final jeepOverrides = _jeep2026OfficialPowertrains(
      modelId,
      fuelLeague,
    );
    if (jeepOverrides.isNotEmpty) {
      return jeepOverrides;
    }
  }
  if (modelId == 'model-kia-013-k3' &&
      fuelLeague == 'gasoline' &&
      year >= 2012 &&
      year <= 2017) {
    return [
      OfficialPowertrain(
        id: 'variant-kia-k3-$year-16-gdi-6at',
        trimName: '1.6 가솔린',
        engineName: 'Gamma 1.6 GDI',
        displacementCc: 1591,
        drivetrain: 'FWD',
        transmission: '자동 6단',
        officialEfficiency: year >= 2015 ? 14.3 : null,
        efficiencyUnit: 'km/L',
        sourceStatus: year >= 2015 ? 'pending_review' : null,
        isSelectable: false,
        sortOrder: 10,
      ),
    ];
  }
  if (modelId == 'model-kia-013-k3' &&
      fuelLeague == 'diesel' &&
      year >= 2016 &&
      year <= 2017) {
    return [
      OfficialPowertrain(
        id: 'variant-kia-k3-$year-16-diesel-7dct',
        trimName: '1.6 디젤',
        engineName: 'U2 1.6 VGT 디젤',
        displacementCc: 1582,
        drivetrain: 'FWD',
        transmission: '7단 DCT ISG',
        officialEfficiency: 19.1,
        efficiencyUnit: 'km/L',
        sourceStatus: 'pending_review',
        isSelectable: false,
        sortOrder: 40,
      ),
    ];
  }
  if (modelId == 'model-kia-013-k3' &&
      fuelLeague == 'gasoline' &&
      year >= 2018 &&
      year <= 2024) {
    final isOfficial2024 = year == 2024;
    final powertrains = [
      OfficialPowertrain(
        id: 'variant-kia-k3-$year-16-ivt',
        trimName: '1.6 가솔린',
        engineName: 'Smartstream G1.6',
        displacementCc: 1598,
        drivetrain: 'FWD',
        transmission: 'IVT',
        officialEfficiency: 15.2,
        efficiencyUnit: 'km/L',
        isVerified: isOfficial2024,
        sourceStatus: isOfficial2024 ? 'verified_official' : 'pending_review',
        sourceName: isOfficial2024 ? _kiaK3OfficialPriceSourceName : null,
        sourceUrl: isOfficial2024 ? _kiaK3OfficialPriceSourceUrl : null,
        sourceFileName: isOfficial2024 ? 'price_k3gt.pdf' : null,
        lastVerifiedAt: isOfficial2024 ? '2026-06-12' : null,
        confidenceScore: isOfficial2024 ? 0.92 : null,
        isSelectable: isOfficial2024,
        sortOrder: 10,
      ),
    ];
    final dct = OfficialPowertrain(
      id: 'variant-kia-k3-gt-$year-16t-7dct',
      trimName: 'K3 GT 1.6T 가솔린 DCT',
      engineName: 'Gamma 1.6 T-GDi',
      displacementCc: 1591,
      drivetrain: 'FWD',
      transmission: '7단 DCT',
      officialEfficiency: year <= 2020 ? 12.2 : 12.1,
      efficiencyUnit: 'km/L',
      vehicleClass: '스포츠',
      isVerified: isOfficial2024,
      sourceStatus: isOfficial2024 ? 'verified_official' : 'pending_review',
      sourceName: isOfficial2024 ? _kiaK3OfficialPriceSourceName : null,
      sourceUrl: isOfficial2024 ? _kiaK3OfficialPriceSourceUrl : null,
      sourceFileName: isOfficial2024 ? 'price_k3gt.pdf' : null,
      lastVerifiedAt: isOfficial2024 ? '2026-06-12' : null,
      confidenceScore: isOfficial2024 ? 0.92 : null,
      isSelectable: isOfficial2024,
      sortOrder: 30,
    );
    if (year <= 2020) {
      powertrains.addAll([
        OfficialPowertrain(
          id: 'variant-kia-k3-gt-$year-16t-6mt',
          trimName: 'K3 GT 1.6T 가솔린 수동',
          engineName: 'Gamma 1.6 T-GDi',
          displacementCc: 1591,
          drivetrain: 'FWD',
          transmission: '수동 6단',
          officialEfficiency: 12.2,
          efficiencyUnit: 'km/L',
          vehicleClass: '스포츠',
          sourceStatus: 'pending_review',
          isSelectable: false,
          sortOrder: 20,
        ),
        dct,
      ]);
    } else {
      powertrains.add(dct);
    }
    return powertrains;
  }

  if (modelId == 'model-hyundai-avante-n-kr' &&
      fuelLeague == 'gasoline' &&
      year >= 2021 &&
      year <= 2026) {
    return [
      OfficialPowertrain(
        id: 'variant-hyundai-avante-n-$year-20t-6mt',
        trimName: '2.0T 가솔린 수동',
        engineName: 'N 전용 G2.0 터보 플랫파워',
        displacementCc: 1998,
        drivetrain: 'FWD',
        transmission: '6단 수동',
        officialEfficiency: 10.6,
        efficiencyUnit: 'km/L',
        vehicleClass: '스포츠',
        sortOrder: 10,
      ),
      OfficialPowertrain(
        id: 'variant-hyundai-avante-n-$year-20t-8dct',
        trimName: '2.0T 가솔린 DCT',
        engineName: 'N 전용 G2.0 터보 플랫파워',
        displacementCc: 1998,
        drivetrain: 'FWD',
        transmission: '8단 DCT',
        officialEfficiency: 10.4,
        efficiencyUnit: 'km/L',
        vehicleClass: '스포츠',
        sortOrder: 11,
      ),
    ];
  }

  if (modelId == 'model-hyundai-avante-sport-kr' &&
      fuelLeague == 'gasoline' &&
      year >= 2016 &&
      year <= 2018) {
    return [
      OfficialPowertrain(
        id: 'variant-hyundai-avante-sport-$year-16t-7dct',
        trimName: '1.6T 가솔린',
        engineName: 'Gamma 1.6 T-GDi',
        displacementCc: 1591,
        drivetrain: 'FWD',
        transmission: '7단 DCT',
        officialEfficiency: year == 2018 ? 12.0 : null,
        efficiencyUnit: 'km/L',
        vehicleClass: '스포츠',
        sortOrder: 10,
      ),
    ];
  }

  if (modelId == 'model-hyundai-001-kr') {
    if (fuelLeague == 'gasoline') {
      final isOfficialAvanteExample = year == 2024;
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-avante-$year-gasoline',
          trimName: '1.6 가솔린',
          engineName: 'Smartstream G1.6',
          displacementCc: 1598,
          drivetrain: 'FWD',
          transmission: 'IVT',
          officialEfficiency: 15.0,
          efficiencyUnit: 'km/L',
          isVerified: isOfficialAvanteExample,
          sourceStatus: isOfficialAvanteExample ? 'verified_official' : null,
          sourceName: isOfficialAvanteExample
              ? 'Hyundai Motor Korea official Avante price PDF'
              : null,
          sourceUrl: isOfficialAvanteExample
              ? 'https://www.hyundai.com/contents/repn-car/catalog/the-new-avante-price.pdf'
              : null,
          sourceFileName:
              isOfficialAvanteExample ? 'the-new-avante-price.pdf' : null,
          lastVerifiedAt: isOfficialAvanteExample ? '2026-06-13' : null,
          confidenceScore: isOfficialAvanteExample ? 0.90 : null,
          sortOrder: 10,
        ),
      ];
    }
    if (fuelLeague == 'hybrid') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-avante-$year-hybrid',
          trimName: '1.6 하이브리드',
          engineName: 'Smartstream G1.6 Hybrid',
          displacementCc: 1580,
          drivetrain: 'FWD',
          transmission: '6단 DCT',
          officialEfficiency: 21.1,
          efficiencyUnit: 'km/L',
          sortOrder: 20,
        ),
      ];
    }
    if (fuelLeague == 'lpg') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-avante-$year-lpi',
          trimName: '1.6 LPi',
          engineName: 'LPi 1.6',
          displacementCc: 1591,
          drivetrain: 'FWD',
          transmission: '자동 6단',
          officialEfficiency: 10.5,
          efficiencyUnit: 'km/L',
          sortOrder: 30,
        ),
      ];
    }
  }

  if (modelId == 'model-hyundai-002-kr') {
    if (fuelLeague == 'gasoline') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-sonata-$year-20-gasoline',
          trimName: '2.0 가솔린',
          engineName: 'Smartstream G2.0',
          displacementCc: 1999,
          drivetrain: 'FWD',
          transmission: '자동 6단',
          officialEfficiency: year >= 2019 ? 12.6 : 11.6,
          efficiencyUnit: 'km/L',
          sortOrder: 10,
        ),
        OfficialPowertrain(
          id: 'variant-hyundai-sonata-$year-16t-gasoline',
          trimName: '1.6T 가솔린',
          engineName: 'Smartstream G1.6T',
          displacementCc: 1598,
          drivetrain: 'FWD',
          transmission: '자동 8단',
          officialEfficiency: year >= 2019 ? 13.5 : 13.0,
          efficiencyUnit: 'km/L',
          sortOrder: 11,
        ),
      ];
    }
    if (fuelLeague == 'hybrid') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-sonata-$year-20-hybrid',
          trimName: '2.0 하이브리드',
          engineName: 'Smartstream G2.0 Hybrid',
          displacementCc: 1999,
          drivetrain: 'FWD',
          transmission: '자동 6단',
          officialEfficiency: year >= 2019 ? 19.4 : 18.0,
          efficiencyUnit: 'km/L',
          sortOrder: 20,
        ),
      ];
    }
  }

  if (modelId == 'model-hyundai-003-kr') {
    if (fuelLeague == 'gasoline') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-grandeur-$year-25-gasoline',
          trimName: '2.5 가솔린',
          engineName: 'Smartstream G2.5',
          displacementCc: 2497,
          drivetrain: 'FWD',
          transmission: '자동 8단',
          officialEfficiency: year >= 2020 ? 11.7 : 11.2,
          efficiencyUnit: 'km/L',
          sortOrder: 10,
        ),
        OfficialPowertrain(
          id: 'variant-hyundai-grandeur-$year-35-gasoline',
          trimName: '3.5 가솔린',
          engineName: 'Smartstream G3.5',
          displacementCc: 3470,
          drivetrain: 'FWD',
          transmission: '자동 8단',
          officialEfficiency: year >= 2020 ? 10.4 : 9.7,
          efficiencyUnit: 'km/L',
          sortOrder: 11,
        ),
      ];
    }
    if (fuelLeague == 'hybrid') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-grandeur-$year-16t-hybrid',
          trimName: '1.6T 하이브리드',
          engineName: 'Smartstream G1.6T Hybrid',
          displacementCc: 1598,
          drivetrain: 'FWD',
          transmission: '자동 6단',
          officialEfficiency: year >= 2023 ? 18.0 : 16.2,
          efficiencyUnit: 'km/L',
          sortOrder: 20,
        ),
      ];
    }
  }

  if (modelId == 'model-hyundai-004-kr') {
    if (fuelLeague == 'gasoline') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-kona-$year-16-gasoline',
          trimName: '1.6 가솔린',
          engineName: 'Smartstream G1.6',
          displacementCc: 1598,
          drivetrain: 'FWD',
          transmission: '자동',
          officialEfficiency: 14.3,
          efficiencyUnit: 'km/L',
          vehicleClass: '소형 SUV',
          sortOrder: 10,
        ),
      ];
    }
    if (fuelLeague == 'hybrid') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-kona-$year-16-hybrid',
          trimName: '1.6 하이브리드',
          engineName: 'Smartstream G1.6 Hybrid',
          displacementCc: 1580,
          drivetrain: 'FWD',
          transmission: '하이브리드 전용 변속기',
          officialEfficiency: 20.2,
          efficiencyUnit: 'km/L',
          vehicleClass: '소형 SUV',
          sortOrder: 20,
        ),
      ];
    }
    if (fuelLeague == 'electric') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-kona-$year-electric',
          trimName: '코나 일렉트릭',
          engineName: 'Electric Motor',
          batteryKwh: 64.8,
          drivetrain: '전동 구동',
          transmission: '감속기',
          officialEfficiency: 5.6,
          efficiencyUnit: 'km/kWh',
          vehicleClass: '소형 SUV',
          sortOrder: 50,
        ),
      ];
    }
  }

  if (modelId == 'model-hyundai-006-kr') {
    if (fuelLeague == 'gasoline') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-santafe-$year-25t-gasoline',
          trimName: '2.5T 가솔린',
          engineName: 'Smartstream G2.5T',
          displacementCc: 2497,
          drivetrain: 'FWD',
          transmission: '8단 DCT',
          officialEfficiency: 11.0,
          efficiencyUnit: 'km/L',
          sortOrder: 10,
        ),
      ];
    }
    if (fuelLeague == 'hybrid') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-santafe-$year-16t-hybrid',
          trimName: '1.6T 하이브리드',
          engineName: 'Smartstream G1.6T Hybrid',
          displacementCc: 1598,
          drivetrain: 'FWD',
          transmission: '자동 6단',
          officialEfficiency: 15.5,
          efficiencyUnit: 'km/L',
          sortOrder: 20,
        ),
      ];
    }
  }

  if (modelId == 'model-hyundai-007-kr') {
    if (fuelLeague == 'gasoline') {
      return [
        OfficialPowertrain(
          id: year >= 2025
              ? 'variant-hyundai-palisade-$year-25t-gasoline'
              : 'variant-hyundai-palisade-$year-38-gasoline',
          trimName: year >= 2025 ? '2.5T 가솔린' : '3.8 가솔린',
          engineName: year >= 2025 ? 'Smartstream G2.5T' : 'Lambda II 3.8 GDi',
          displacementCc: year >= 2025 ? 2497 : 3778,
          drivetrain: 'FWD',
          transmission: '자동 8단',
          officialEfficiency: year >= 2025 ? 9.7 : 9.6,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형 SUV',
          sortOrder: 10,
        ),
      ];
    }
    if (fuelLeague == 'hybrid') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-palisade-$year-25t-hybrid',
          trimName: '2.5T 하이브리드',
          engineName: 'Smartstream G2.5T Hybrid',
          displacementCc: 2497,
          drivetrain: 'FWD',
          transmission: '자동 6단',
          officialEfficiency: 14.1,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형 SUV',
          sortOrder: 20,
        ),
      ];
    }
    if (fuelLeague == 'diesel') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-palisade-$year-22-diesel',
          trimName: '2.2 디젤',
          engineName: 'R 2.2 e-VGT',
          displacementCc: 2199,
          drivetrain: 'FWD',
          transmission: '자동 8단',
          officialEfficiency: 12.1,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형 SUV',
          sortOrder: 40,
        ),
      ];
    }
  }

  if (modelId == 'model-hyundai-008-kr') {
    if (fuelLeague == 'gasoline') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-casper-$year-10-gasoline',
          trimName: '1.0 가솔린',
          engineName: 'Smartstream G1.0',
          displacementCc: 998,
          drivetrain: 'FWD',
          transmission: '자동 4단',
          officialEfficiency: 14.3,
          efficiencyUnit: 'km/L',
          sortOrder: 10,
        ),
        OfficialPowertrain(
          id: 'variant-hyundai-casper-$year-10t-gasoline',
          trimName: '1.0T 가솔린',
          engineName: 'Kappa 1.0 T-GDI',
          displacementCc: 998,
          drivetrain: 'FWD',
          transmission: '자동 4단',
          officialEfficiency: 12.8,
          efficiencyUnit: 'km/L',
          sortOrder: 11,
        ),
      ];
    }
  }

  if (modelId == 'model-hyundai-011-kr') {
    if (fuelLeague == 'diesel') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-staria-$year-22-diesel',
          trimName: '2.2 디젤',
          engineName: 'Smartstream D2.2',
          displacementCc: 2199,
          drivetrain: 'FWD',
          transmission: '자동 8단',
          officialEfficiency: 11.8,
          efficiencyUnit: 'km/L',
          vehicleClass: 'MPV',
          sortOrder: 40,
        ),
      ];
    }
    if (fuelLeague == 'lpg') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-staria-$year-35-lpi',
          trimName: '3.5 LPi',
          engineName: 'Smartstream LPG 3.5',
          displacementCc: 3470,
          drivetrain: 'FWD',
          transmission: '자동 8단',
          officialEfficiency: 6.7,
          efficiencyUnit: 'km/L',
          vehicleClass: 'MPV',
          sortOrder: 30,
        ),
      ];
    }
    if (fuelLeague == 'hybrid') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-staria-$year-16t-hybrid',
          trimName: '1.6T 하이브리드',
          engineName: 'Smartstream G1.6T Hybrid',
          displacementCc: 1598,
          drivetrain: 'FWD',
          transmission: '자동 6단',
          officialEfficiency: 13.0,
          efficiencyUnit: 'km/L',
          vehicleClass: 'MPV',
          sortOrder: 20,
        ),
      ];
    }
  }

  if (modelId == 'model-hyundai-012-kr') {
    if (fuelLeague == 'diesel') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-porter2-$year-25-diesel',
          trimName: '2.5 디젤',
          engineName: 'A2 2.5 CRDi',
          displacementCc: 2497,
          drivetrain: 'RWD',
          transmission: '자동',
          officialEfficiency: 10.5,
          efficiencyUnit: 'km/L',
          vehicleClass: '상용',
          sortOrder: 40,
        ),
      ];
    }
    if (fuelLeague == 'lpg') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-porter2-$year-25-lpg-6mt',
          trimName: '2.5 LPG 터보 수동',
          engineName: 'Smartstream LPG 2.5T',
          displacementCc: 2497,
          drivetrain: 'RWD',
          transmission: '6단 수동',
          officialEfficiency: null,
          efficiencyUnit: 'km/L',
          vehicleClass: '상용',
          sortOrder: 10,
        ),
        OfficialPowertrain(
          id: 'variant-hyundai-porter2-$year-25-lpg-5at',
          trimName: '2.5 LPG 터보 자동',
          engineName: 'Smartstream LPG 2.5T',
          displacementCc: 2497,
          drivetrain: 'RWD',
          transmission: '자동 5단',
          officialEfficiency: null,
          efficiencyUnit: 'km/L',
          vehicleClass: '상용',
          sortOrder: 11,
        ),
      ];
    }
    if (fuelLeague == 'electric') {
      return [
        OfficialPowertrain(
          id: 'variant-hyundai-porter2-$year-electric',
          trimName: '포터 II Electric',
          engineName: 'Electric Motor',
          batteryKwh: 58.8,
          drivetrain: '전동 구동',
          transmission: '감속기',
          officialEfficiency: 3.1,
          efficiencyUnit: 'km/kWh',
          vehicleClass: '상용',
          sortOrder: 50,
        ),
      ];
    }
  }

  if (modelId == 'model-kia-017-kr') {
    if (fuelLeague == 'gasoline') {
      return [
        OfficialPowertrain(
          id: 'variant-kia-morning-$year-10-gasoline',
          trimName: '1.0 가솔린',
          engineName: 'Smartstream G1.0',
          displacementCc: 998,
          drivetrain: 'FWD',
          transmission: '자동 4단',
          officialEfficiency: 15.1,
          efficiencyUnit: 'km/L',
          sortOrder: 10,
        ),
      ];
    }
  }

  if (modelId == 'model-kia-018-kr') {
    if (fuelLeague == 'gasoline') {
      return [
        OfficialPowertrain(
          id: 'variant-kia-ray-$year-10-gasoline',
          trimName: '1.0 가솔린',
          engineName: 'Smartstream G1.0',
          displacementCc: 998,
          drivetrain: 'FWD',
          transmission: '자동 4단',
          officialEfficiency: 13.0,
          efficiencyUnit: 'km/L',
          sortOrder: 10,
        ),
      ];
    }
    if (fuelLeague == 'electric') {
      return [
        OfficialPowertrain(
          id: 'variant-kia-ray-$year-electric',
          trimName: '전기차',
          engineName: 'Ray EV Motor',
          batteryKwh: 35.2,
          drivetrain: '전동 구동',
          transmission: '감속기',
          officialEfficiency: 5.1,
          efficiencyUnit: 'km/kWh',
          sortOrder: 50,
        ),
      ];
    }
  }

  if (modelId == 'model-kia-019-kr') {
    if (fuelLeague == 'gasoline') {
      return [
        OfficialPowertrain(
          id: 'variant-kia-seltos-$year-16t-gasoline',
          trimName: '1.6T 가솔린',
          engineName: 'Smartstream G1.6T',
          displacementCc: 1598,
          drivetrain: 'FWD',
          transmission: '자동 8단',
          officialEfficiency: 12.8,
          efficiencyUnit: 'km/L',
          sortOrder: 10,
        ),
        OfficialPowertrain(
          id: 'variant-kia-seltos-$year-20-gasoline',
          trimName: '2.0 가솔린',
          engineName: 'Smartstream G2.0',
          displacementCc: 1999,
          drivetrain: 'FWD',
          transmission: 'IVT',
          officialEfficiency: 12.9,
          efficiencyUnit: 'km/L',
          sortOrder: 11,
        ),
      ];
    }
  }

  if (modelId == 'model-kia-021-kr') {
    if (fuelLeague == 'gasoline') {
      return [
        OfficialPowertrain(
          id: 'variant-kia-sportage-$year-16t-gasoline',
          trimName: '1.6T 가솔린',
          engineName: 'Smartstream G1.6T',
          displacementCc: 1598,
          drivetrain: 'FWD',
          transmission: '자동 8단',
          officialEfficiency: 12.5,
          efficiencyUnit: 'km/L',
          sortOrder: 10,
        ),
      ];
    }
    if (fuelLeague == 'diesel') {
      return [
        OfficialPowertrain(
          id: 'variant-kia-sportage-$year-20-diesel',
          trimName: '2.0 디젤',
          engineName: 'Smartstream D2.0',
          displacementCc: 1998,
          drivetrain: 'FWD',
          transmission: '자동 8단',
          officialEfficiency: 14.6,
          efficiencyUnit: 'km/L',
          sortOrder: 40,
        ),
      ];
    }
    if (fuelLeague == 'hybrid') {
      return [
        OfficialPowertrain(
          id: 'variant-kia-sportage-$year-16t-hybrid',
          trimName: '1.6T 하이브리드',
          engineName: 'Smartstream G1.6T Hybrid',
          displacementCc: 1598,
          drivetrain: 'FWD',
          transmission: '자동 6단',
          officialEfficiency: 16.7,
          efficiencyUnit: 'km/L',
          sortOrder: 20,
        ),
      ];
    }
  }

  if (modelId == 'model-kia-022-kr') {
    if (fuelLeague == 'gasoline') {
      return [
        OfficialPowertrain(
          id: 'variant-kia-sorento-$year-25t-gasoline',
          trimName: '2.5T 가솔린',
          engineName: 'Smartstream G2.5T',
          displacementCc: 2497,
          drivetrain: 'FWD',
          transmission: '8단 DCT',
          officialEfficiency: 11.0,
          efficiencyUnit: 'km/L',
          sortOrder: 10,
        ),
      ];
    }
    if (fuelLeague == 'diesel') {
      return [
        OfficialPowertrain(
          id: 'variant-kia-sorento-$year-22-diesel',
          trimName: '2.2 디젤',
          engineName: 'Smartstream D2.2',
          displacementCc: 2151,
          drivetrain: 'FWD',
          transmission: '8단 DCT',
          officialEfficiency: 14.3,
          efficiencyUnit: 'km/L',
          sortOrder: 40,
        ),
      ];
    }
    if (fuelLeague == 'hybrid') {
      return [
        OfficialPowertrain(
          id: 'variant-kia-sorento-$year-16t-hybrid',
          trimName: '1.6T 하이브리드',
          engineName: 'Smartstream G1.6T Hybrid',
          displacementCc: 1598,
          drivetrain: 'FWD',
          transmission: '자동 6단',
          officialEfficiency: 15.7,
          efficiencyUnit: 'km/L',
          sortOrder: 20,
        ),
      ];
    }
  }

  return const [];
}

const _kiaK3OfficialPriceSourceName = '기아 공식 K3/K3 GT 가격표';
const _kiaK3OfficialPriceSourceUrl =
    'https://www.kia.com/content/dam/kwp/kr/ko/vehicles/pdf/price/price_k3gt.pdf';

const _kiaOfficialEvLineupSourceName = 'Kia Korea official EV lineup page';
const _kiaOfficialEvLineupSourceUrl = 'https://www.kia.com/kr/vehicles/ev';
const _kiaOfficialPbvLineupSourceName = 'Kia Korea official PBV lineup page';
const _kiaOfficialPbvLineupSourceUrl = 'https://www.kia.com/kr/vehicles/pbv';
const _kiaOfficialCommercialLineupSourceName =
    'Kia Korea official taxi, bus and commercial lineup page';
const _kiaOfficialCommercialLineupSourceUrl =
    'https://www.kia.com/kr/vehicles/commercial';

List<OfficialPowertrain> _kia2026OfficialLineupPowertrains(
  String modelId,
  String fuelLeague,
) {
  OfficialPowertrain pending({
    required String id,
    required String trimName,
    required String sourceName,
    required String sourceUrl,
    required int sortOrder,
    String? vehicleClass,
  }) {
    return OfficialPowertrain(
      id: id,
      trimName: trimName,
      engineName: 'Pending official $trimName specification review',
      drivetrain: '검수 대기',
      transmission: '검수 대기',
      officialEfficiency: null,
      efficiencyUnit: fuelLeague == 'electric' ? 'km/kWh' : 'km/L',
      vehicleClass: vehicleClass,
      sourceStatus: 'pending_review',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      lastVerifiedAt: '2026-06-13',
      confidenceScore: 0.66,
      isSelectable: false,
      sortOrder: sortOrder,
    );
  }

  if (fuelLeague == 'electric') {
    switch (modelId) {
      case 'model-kia-018-kr':
        return [
          pending(
            id: 'variant-kia-ray-2026-ray-ev-pending',
            trimName: '레이 EV',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            sortOrder: 50,
          ),
        ];
      case 'model-kia-024-ev3':
        return [
          pending(
            id: 'variant-kia-ev3-2026-ev3-pending',
            trimName: 'EV3',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            sortOrder: 50,
          ),
          pending(
            id: 'variant-kia-ev3-2026-ev3-gt-pending',
            trimName: 'EV3 GT',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            sortOrder: 51,
          ),
        ];
      case 'model-kia-ev4-kr':
        return [
          pending(
            id: 'variant-kia-ev4-2026-ev4-pending',
            trimName: 'EV4',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            sortOrder: 50,
          ),
          pending(
            id: 'variant-kia-ev4-2026-ev4-gt-pending',
            trimName: 'EV4 GT',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            sortOrder: 51,
          ),
        ];
      case 'model-kia-ev5-kr':
        return [
          pending(
            id: 'variant-kia-ev5-2026-ev5-pending',
            trimName: 'EV5',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            sortOrder: 50,
          ),
          pending(
            id: 'variant-kia-ev5-2026-ev5-gt-pending',
            trimName: 'EV5 GT',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            sortOrder: 51,
          ),
        ];
      case 'model-kia-025-ev6':
        return [
          pending(
            id: 'variant-kia-ev6-2026-ev6-pending',
            trimName: 'EV6',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            sortOrder: 50,
          ),
          pending(
            id: 'variant-kia-ev6-2026-ev6-gt-pending',
            trimName: 'EV6 GT',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            sortOrder: 51,
          ),
        ];
      case 'model-kia-026-ev9':
        return [
          pending(
            id: 'variant-kia-ev9-2026-ev9-pending',
            trimName: 'EV9',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            sortOrder: 50,
          ),
          pending(
            id: 'variant-kia-ev9-2026-ev9-gt-pending',
            trimName: 'EV9 GT',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            sortOrder: 51,
          ),
        ];
      case 'model-kia-pv5-kr':
        return [
          pending(
            id: 'variant-kia-pv5-2026-passenger-pending',
            trimName: 'PV5 패신저',
            sourceName: _kiaOfficialPbvLineupSourceName,
            sourceUrl: _kiaOfficialPbvLineupSourceUrl,
            vehicleClass: '상용',
            sortOrder: 50,
          ),
          pending(
            id: 'variant-kia-pv5-2026-cargo-pending',
            trimName: 'PV5 카고',
            sourceName: _kiaOfficialPbvLineupSourceName,
            sourceUrl: _kiaOfficialPbvLineupSourceUrl,
            vehicleClass: '상용',
            sortOrder: 51,
          ),
          pending(
            id: 'variant-kia-pv5-2026-wav-pending',
            trimName: 'PV5 WAV',
            sourceName: _kiaOfficialPbvLineupSourceName,
            sourceUrl: _kiaOfficialPbvLineupSourceUrl,
            vehicleClass: '상용',
            sortOrder: 52,
          ),
          pending(
            id: 'variant-kia-pv5-2026-openbed-pending',
            trimName: 'PV5 오픈베드',
            sourceName: _kiaOfficialPbvLineupSourceName,
            sourceUrl: _kiaOfficialPbvLineupSourceUrl,
            vehicleClass: '상용',
            sortOrder: 53,
          ),
          pending(
            id: 'variant-kia-pv5-2026-passenger-taxi-pending',
            trimName: 'PV5 패신저 택시',
            sourceName: _kiaOfficialCommercialLineupSourceName,
            sourceUrl: _kiaOfficialCommercialLineupSourceUrl,
            vehicleClass: '택시',
            sortOrder: 54,
          ),
          pending(
            id: 'variant-kia-pv5-2026-wav-taxi-pending',
            trimName: 'PV5 WAV 택시',
            sourceName: _kiaOfficialCommercialLineupSourceName,
            sourceUrl: _kiaOfficialCommercialLineupSourceUrl,
            vehicleClass: '택시',
            sortOrder: 55,
          ),
        ];
      case 'model-kia-027-kr':
        return [
          pending(
            id: 'variant-kia-bongo-2026-ev-truck-pending',
            trimName: '봉고Ⅲ EV',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            vehicleClass: '상용',
            sortOrder: 50,
          ),
          pending(
            id: 'variant-kia-bongo-2026-ev-box-wing-pending',
            trimName: '봉고III EV 탑차/윙바디',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            vehicleClass: '상용',
            sortOrder: 51,
          ),
          pending(
            id: 'variant-kia-bongo-2026-ev-powergate-pending',
            trimName: '봉고III EV 파워게이트',
            sourceName: _kiaOfficialEvLineupSourceName,
            sourceUrl: _kiaOfficialEvLineupSourceUrl,
            vehicleClass: '상용',
            sortOrder: 52,
          ),
        ];
    }
  }

  if (modelId == 'model-kia-015-k8' && fuelLeague == 'lpg') {
    return [
      pending(
        id: 'variant-kia-k8-2026-taxi-lpg-pending',
        trimName: 'K8 택시',
        sourceName: _kiaOfficialCommercialLineupSourceName,
        sourceUrl: _kiaOfficialCommercialLineupSourceUrl,
        vehicleClass: '택시',
        sortOrder: 30,
      ),
    ];
  }

  if (modelId == 'model-kia-027-kr' && fuelLeague == 'diesel') {
    return [
      pending(
        id: 'variant-kia-bongo-2026-truck-diesel-pending',
        trimName: '봉고Ⅲ 트럭',
        sourceName: _kiaOfficialCommercialLineupSourceName,
        sourceUrl: _kiaOfficialCommercialLineupSourceUrl,
        vehicleClass: '상용',
        sortOrder: 40,
      ),
      pending(
        id: 'variant-kia-bongo-2026-box-wing-walkthrough-diesel-pending',
        trimName: '봉고III 탑차/윙바디/워크스루밴',
        sourceName: _kiaOfficialCommercialLineupSourceName,
        sourceUrl: _kiaOfficialCommercialLineupSourceUrl,
        vehicleClass: '상용',
        sortOrder: 41,
      ),
      pending(
        id: 'variant-kia-bongo-2026-dump-diesel-pending',
        trimName: '봉고III 덤프',
        sourceName: _kiaOfficialCommercialLineupSourceName,
        sourceUrl: _kiaOfficialCommercialLineupSourceUrl,
        vehicleClass: '상용',
        sortOrder: 42,
      ),
    ];
  }

  return const [];
}

const _teslaCertifiedEfficiencySourceName =
    'Tesla Korea official certified range and efficiency';
const _teslaCertifiedEfficiencySourceUrl =
    'https://www.tesla.com/ko_kr/support/range-calculator-ref';
const _teslaModelYSourceName = 'Tesla Korea official Model Y page';
const _teslaModelYSourceUrl = 'https://www.tesla.com/ko_kr/modely';

List<OfficialPowertrain> _tesla2026OfficialPowertrains(
  String modelId,
  String fuelLeague,
) {
  if (fuelLeague != 'electric') {
    return const [];
  }

  OfficialPowertrain verifiedRow({
    required String id,
    required String trimName,
    required String engineName,
    required double batteryKwh,
    required String drivetrain,
    required double officialEfficiency,
    required String vehicleClass,
    required int sortOrder,
  }) {
    return OfficialPowertrain(
      id: id,
      trimName: trimName,
      engineName: engineName,
      batteryKwh: batteryKwh,
      drivetrain: drivetrain,
      transmission: '감속기',
      officialEfficiency: officialEfficiency,
      efficiencyUnit: 'km/kWh',
      vehicleClass: vehicleClass,
      isVerified: true,
      sourceStatus: 'verified_official',
      sourceName: _teslaCertifiedEfficiencySourceName,
      sourceUrl: _teslaCertifiedEfficiencySourceUrl,
      lastVerifiedAt: '2026-06-13',
      confidenceScore: 0.90,
      isSelectable: true,
      sortOrder: sortOrder,
    );
  }

  OfficialPowertrain pendingRow({
    required String id,
    required String trimName,
    required String engineName,
    required String drivetrain,
    required String sourceName,
    required String sourceUrl,
    required String vehicleClass,
    required int sortOrder,
  }) {
    return OfficialPowertrain(
      id: id,
      trimName: trimName,
      engineName: engineName,
      drivetrain: drivetrain,
      transmission: '검수 대기',
      officialEfficiency: null,
      efficiencyUnit: 'km/kWh',
      vehicleClass: vehicleClass,
      sourceStatus: 'pending_review',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      lastVerifiedAt: '2026-06-13',
      confidenceScore: 0.62,
      isSelectable: false,
      sortOrder: sortOrder,
    );
  }

  switch (modelId) {
    case 'model-tesla-120-model-3':
      return [
        verifiedRow(
          id: 'variant-tesla-model-3-2026-standard-rwd',
          trimName: 'Model 3 Standard RWD',
          engineName: 'Single Motor RWD',
          batteryKwh: 62.10,
          drivetrain: 'RWD',
          officialEfficiency: 5.4,
          vehicleClass: '중형',
          sortOrder: 10,
        ),
        verifiedRow(
          id: 'variant-tesla-model-3-2026-premium-long-range-rwd',
          trimName: 'Model 3 Premium Long Range RWD',
          engineName: 'Single Motor RWD',
          batteryKwh: 84.85,
          drivetrain: 'RWD',
          officialEfficiency: 5.8,
          vehicleClass: '중형',
          sortOrder: 20,
        ),
        verifiedRow(
          id: 'variant-tesla-model-3-2026-performance',
          trimName: 'Model 3 Performance',
          engineName: 'Dual Motor AWD',
          batteryKwh: 84.85,
          drivetrain: 'AWD',
          officialEfficiency: 4.8,
          vehicleClass: '중형',
          sortOrder: 30,
        ),
      ];
    case 'model-tesla-121-model-y':
      return [
        verifiedRow(
          id: 'variant-tesla-model-y-2026-premium-rwd',
          trimName: 'Model Y Premium RWD',
          engineName: 'Single Motor RWD',
          batteryKwh: 62.10,
          drivetrain: 'RWD',
          officialEfficiency: 5.6,
          vehicleClass: 'SUV',
          sortOrder: 10,
        ),
        verifiedRow(
          id: 'variant-tesla-model-y-2026-premium-long-range-awd',
          trimName: 'Model Y Premium Long Range AWD',
          engineName: 'Dual Motor AWD',
          batteryKwh: 84.85,
          drivetrain: 'AWD',
          officialEfficiency: 5.4,
          vehicleClass: 'SUV',
          sortOrder: 20,
        ),
        pendingRow(
          id: 'variant-tesla-model-y-2026-l-pending',
          trimName: 'Model Y L 공식 공인연비 검수 대기',
          engineName: 'Dual Motor AWD',
          drivetrain: 'AWD',
          sourceName: _teslaModelYSourceName,
          sourceUrl: _teslaModelYSourceUrl,
          vehicleClass: 'SUV',
          sortOrder: 30,
        ),
      ];
    case 'model-tesla-122-model-s':
      return [
        verifiedRow(
          id: 'variant-tesla-model-s-2026-awd',
          trimName: 'Model S AWD',
          engineName: 'Dual Motor AWD',
          batteryKwh: 104.96,
          drivetrain: 'AWD',
          officialEfficiency: 4.8,
          vehicleClass: '대형',
          sortOrder: 10,
        ),
        verifiedRow(
          id: 'variant-tesla-model-s-2026-plaid',
          trimName: 'Model S Plaid',
          engineName: 'Tri Motor AWD',
          batteryKwh: 104.96,
          drivetrain: 'AWD',
          officialEfficiency: 4.2,
          vehicleClass: '대형',
          sortOrder: 20,
        ),
      ];
    case 'model-tesla-123-model-x':
      return [
        verifiedRow(
          id: 'variant-tesla-model-x-2026-awd',
          trimName: 'Model X AWD',
          engineName: 'Dual Motor AWD',
          batteryKwh: 104.96,
          drivetrain: 'AWD',
          officialEfficiency: 4.2,
          vehicleClass: '대형 SUV',
          sortOrder: 10,
        ),
        verifiedRow(
          id: 'variant-tesla-model-x-2026-plaid',
          trimName: 'Model X Plaid',
          engineName: 'Tri Motor AWD',
          batteryKwh: 104.96,
          drivetrain: 'AWD',
          officialEfficiency: 3.8,
          vehicleClass: '대형 SUV',
          sortOrder: 20,
        ),
      ];
  }

  return const [];
}

const _polestar2SpecificationsSourceName =
    'Polestar Korea official Polestar 2 specifications page';
const _polestar2SpecificationsSourceUrl =
    'https://www.polestar.com/kr/polestar-2/specifications/';
const _polestar4SpecificationsSourceName =
    'Polestar Korea official Polestar 4 specifications page';
const _polestar4SpecificationsSourceUrl =
    'https://www.polestar.com/kr/polestar-4-models/polestar-4-coupe/specifications/';

List<OfficialPowertrain> _polestar2026OfficialPowertrains(
  String modelId,
  String fuelLeague,
) {
  if (fuelLeague != 'electric') {
    return const [];
  }

  OfficialPowertrain row({
    required String id,
    required String trimName,
    required String engineName,
    required double batteryKwh,
    required String drivetrain,
    required double officialEfficiency,
    required String vehicleClass,
    required String sourceName,
    required String sourceUrl,
    required int sortOrder,
  }) {
    return OfficialPowertrain(
      id: id,
      trimName: trimName,
      engineName: engineName,
      batteryKwh: batteryKwh,
      drivetrain: drivetrain,
      transmission: '감속기',
      officialEfficiency: officialEfficiency,
      efficiencyUnit: 'km/kWh',
      vehicleClass: vehicleClass,
      isVerified: true,
      sourceStatus: 'verified_official',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      lastVerifiedAt: '2026-06-13',
      confidenceScore: 0.90,
      isSelectable: true,
      sortOrder: sortOrder,
    );
  }

  switch (modelId) {
    case 'model-polestar-159-polestar-2':
      return [
        row(
          id: 'variant-polestar-2-2026-standard-range-single-motor',
          trimName: 'Polestar 2 Standard range Single motor',
          engineName: 'Single motor 200 kW',
          batteryKwh: 69.0,
          drivetrain: 'RWD',
          officialEfficiency: 5.2,
          vehicleClass: '중형',
          sourceName: _polestar2SpecificationsSourceName,
          sourceUrl: _polestar2SpecificationsSourceUrl,
          sortOrder: 10,
        ),
        row(
          id: 'variant-polestar-2-2026-long-range-single-motor',
          trimName: 'Polestar 2 Long range Single motor',
          engineName: 'Single motor 220 kW',
          batteryKwh: 78.0,
          drivetrain: 'RWD',
          officialEfficiency: 5.1,
          vehicleClass: '중형',
          sourceName: _polestar2SpecificationsSourceName,
          sourceUrl: _polestar2SpecificationsSourceUrl,
          sortOrder: 20,
        ),
        row(
          id: 'variant-polestar-2-2026-long-range-dual-motor',
          trimName: 'Polestar 2 Long range Dual motor',
          engineName: 'Dual motor 310 kW',
          batteryKwh: 78.0,
          drivetrain: 'AWD',
          officialEfficiency: 4.3,
          vehicleClass: '중형',
          sourceName: _polestar2SpecificationsSourceName,
          sourceUrl: _polestar2SpecificationsSourceUrl,
          sortOrder: 30,
        ),
      ];
    case 'model-polestar-161-polestar-4':
      return [
        row(
          id: 'variant-polestar-4-2026-coupe-rear-motor',
          trimName: 'Polestar 4 coupé Rear motor',
          engineName: 'Rear motor',
          batteryKwh: 100.0,
          drivetrain: 'RWD',
          officialEfficiency: 4.6,
          vehicleClass: 'SUV',
          sourceName: _polestar4SpecificationsSourceName,
          sourceUrl: _polestar4SpecificationsSourceUrl,
          sortOrder: 10,
        ),
        row(
          id: 'variant-polestar-4-2026-coupe-dual-motor',
          trimName: 'Polestar 4 coupé Dual motor (20/21인치 휠)',
          engineName: 'Dual motor',
          batteryKwh: 100.0,
          drivetrain: 'AWD',
          officialEfficiency: 4.2,
          vehicleClass: 'SUV',
          sourceName: _polestar4SpecificationsSourceName,
          sourceUrl: _polestar4SpecificationsSourceUrl,
          sortOrder: 20,
        ),
        row(
          id: 'variant-polestar-4-2026-coupe-dual-motor-performance',
          trimName: 'Polestar 4 coupé Dual motor Performance package (22인치 휠)',
          engineName: 'Dual motor',
          batteryKwh: 100.0,
          drivetrain: 'AWD',
          officialEfficiency: 3.7,
          vehicleClass: 'SUV',
          sourceName: _polestar4SpecificationsSourceName,
          sourceUrl: _polestar4SpecificationsSourceUrl,
          sortOrder: 30,
        ),
      ];
  }

  return const [];
}

const _peugeot308SmartHybridSourceName =
    'Peugeot Korea official 308 SMART HYBRID model page';
const _peugeot308SmartHybridSourceUrl =
    'https://www.epeugeot.co.kr/new-cars/308hybrid.html';
const _peugeot3008SmartHybridSourceName =
    'Peugeot Korea official 3008 SMART HYBRID model page';
const _peugeot3008SmartHybridSourceUrl =
    'https://www.epeugeot.co.kr/new-cars/3008hybrid.html';
const _peugeot5008SmartHybridSourceName =
    'Peugeot Korea official 5008 SMART HYBRID model page';
const _peugeot5008SmartHybridSourceUrl =
    'https://www.epeugeot.co.kr/new-cars/5008hybrid.html';
const _peugeot408SmartHybridSourceName =
    'Peugeot Korea official 408 SMART HYBRID model page';
const _peugeot408SmartHybridSourceUrl =
    'https://www.epeugeot.co.kr/new-cars/408hybrid.html';

List<OfficialPowertrain> _peugeot2026OfficialPowertrains(
  String modelId,
  String fuelLeague,
) {
  if (fuelLeague != 'hybrid') {
    return const [];
  }

  OfficialPowertrain row({
    required String id,
    required String trimName,
    required String sourceName,
    required String sourceUrl,
    required double officialEfficiency,
    required String vehicleClass,
    required int sortOrder,
  }) {
    return OfficialPowertrain(
      id: id,
      trimName: trimName,
      engineName: '1.2L PureTech Smart Hybrid',
      displacementCc: 1199,
      drivetrain: 'FWD',
      transmission: '6단 듀얼 클러치 자동변속기(e-DCS6)',
      officialEfficiency: officialEfficiency,
      efficiencyUnit: 'km/L',
      vehicleClass: vehicleClass,
      isVerified: true,
      sourceStatus: 'verified_official',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      lastVerifiedAt: '2026-06-13',
      confidenceScore: 0.90,
      isSelectable: true,
      sortOrder: sortOrder,
    );
  }

  List<OfficialPowertrain> trims({
    required String slug,
    required String modelName,
    required String sourceName,
    required String sourceUrl,
    required double officialEfficiency,
    required String vehicleClass,
  }) {
    return [
      row(
        id: 'variant-peugeot-$slug-2026-smart-hybrid-allure',
        trimName: '$modelName SMART HYBRID Allure',
        sourceName: sourceName,
        sourceUrl: sourceUrl,
        officialEfficiency: officialEfficiency,
        vehicleClass: vehicleClass,
        sortOrder: 10,
      ),
      row(
        id: 'variant-peugeot-$slug-2026-smart-hybrid-gt',
        trimName: '$modelName SMART HYBRID GT',
        sourceName: sourceName,
        sourceUrl: sourceUrl,
        officialEfficiency: officialEfficiency,
        vehicleClass: vehicleClass,
        sortOrder: 20,
      ),
    ];
  }

  switch (modelId) {
    case 'model-peugeot-145-308':
      return trims(
        slug: '308',
        modelName: '308',
        sourceName: _peugeot308SmartHybridSourceName,
        sourceUrl: _peugeot308SmartHybridSourceUrl,
        officialEfficiency: 15.2,
        vehicleClass: '준중형',
      );
    case 'model-peugeot-147-3008':
      return trims(
        slug: '3008',
        modelName: '3008',
        sourceName: _peugeot3008SmartHybridSourceName,
        sourceUrl: _peugeot3008SmartHybridSourceUrl,
        officialEfficiency: 14.6,
        vehicleClass: 'SUV',
      );
    case 'model-peugeot-148-5008':
      return trims(
        slug: '5008',
        modelName: '5008',
        sourceName: _peugeot5008SmartHybridSourceName,
        sourceUrl: _peugeot5008SmartHybridSourceUrl,
        officialEfficiency: 13.3,
        vehicleClass: '대형 SUV',
      );
    case 'model-peugeot-408-kr':
      return trims(
        slug: '408',
        modelName: '408',
        sourceName: _peugeot408SmartHybridSourceName,
        sourceUrl: _peugeot408SmartHybridSourceUrl,
        officialEfficiency: 14.1,
        vehicleClass: '중형',
      );
  }

  return const [];
}

const _volkswagenGolfPriceSourceName =
    'Volkswagen Korea official Golf price list';
const _volkswagenGolfPriceSourceUrl =
    'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/2025-golf/leaflet/The%20Golf_Price%20List_251230_web.pdf';
const _volkswagenGolfGtiPriceSourceName =
    'Volkswagen Korea official Golf GTI price list';
const _volkswagenGolfGtiPriceSourceUrl =
    'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/2025-gti/leaflet/Golf%20GTI_Price%20List_260121_web.pdf';
const _volkswagenAtlasPriceSourceName =
    'Volkswagen Korea official Atlas price list';
const _volkswagenAtlasPriceSourceUrl =
    'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/atlas/leaflet/Atlas_Price%20List_260209.pdf';
const _volkswagenTouaregPriceSourceName =
    'Volkswagen Korea official Touareg FINAL EDITION price list';
const _volkswagenTouaregPriceSourceUrl =
    'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/touareg_final-edition/The%20new%20Touareg_Price%20List_260414_web.pdf';
const _volkswagenId4PriceSourceName =
    'Volkswagen Korea official ID.4 price list';
const _volkswagenId4PriceSourceUrl =
    'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/id4/leaflet/ID4_Price%20List_260105_web.pdf';
const _volkswagenId5PriceSourceName =
    'Volkswagen Korea official ID.5 price list';
const _volkswagenId5PriceSourceUrl =
    'https://www.volkswagen.co.kr/idhub/content/dam/onehub_pkw/importers/kr/models/id5/leaflet/ID5_Price%20List_260519_web.pdf';

List<OfficialPowertrain> _volkswagen2026OfficialPowertrains(
  String modelId,
  String fuelLeague,
) {
  OfficialPowertrain row({
    required String id,
    required String trimName,
    required String engineName,
    int? displacementCc,
    double? batteryKwh,
    required String drivetrain,
    required String transmission,
    required double officialEfficiency,
    required String efficiencyUnit,
    required String vehicleClass,
    required String sourceName,
    required String sourceUrl,
    required int sortOrder,
  }) {
    return OfficialPowertrain(
      id: id,
      trimName: trimName,
      engineName: engineName,
      displacementCc: displacementCc,
      batteryKwh: batteryKwh,
      drivetrain: drivetrain,
      transmission: transmission,
      officialEfficiency: officialEfficiency,
      efficiencyUnit: efficiencyUnit,
      vehicleClass: vehicleClass,
      isVerified: true,
      sourceStatus: 'verified_official',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      lastVerifiedAt: '2026-06-13',
      confidenceScore: 0.90,
      isSelectable: true,
      sortOrder: sortOrder,
    );
  }

  switch ('$modelId|$fuelLeague') {
    case 'model-volkswagen-089-kr|diesel':
      return [
        row(
          id: 'variant-volkswagen-golf-2026-20-tdi-premium',
          trimName: 'The Golf 2.0 TDI Premium',
          engineName: '2.0 TDI',
          displacementCc: 1968,
          drivetrain: 'FWD',
          transmission: '7단 DSG',
          officialEfficiency: 17.3,
          efficiencyUnit: 'km/L',
          vehicleClass: '준중형',
          sourceName: _volkswagenGolfPriceSourceName,
          sourceUrl: _volkswagenGolfPriceSourceUrl,
          sortOrder: 10,
        ),
        row(
          id: 'variant-volkswagen-golf-2026-20-tdi-prestige',
          trimName: 'The Golf 2.0 TDI Prestige',
          engineName: '2.0 TDI',
          displacementCc: 1968,
          drivetrain: 'FWD',
          transmission: '7단 DSG',
          officialEfficiency: 17.3,
          efficiencyUnit: 'km/L',
          vehicleClass: '준중형',
          sourceName: _volkswagenGolfPriceSourceName,
          sourceUrl: _volkswagenGolfPriceSourceUrl,
          sortOrder: 20,
        ),
      ];
    case 'model-volkswagen-golf-gti-kr|gasoline':
      return [
        row(
          id: 'variant-volkswagen-golf-gti-2026-20-tsi',
          trimName: 'Golf GTI',
          engineName: '2.0 TSI',
          displacementCc: 1984,
          drivetrain: 'FWD',
          transmission: '7단 DSG',
          officialEfficiency: 10.8,
          efficiencyUnit: 'km/L',
          vehicleClass: '스포츠',
          sourceName: _volkswagenGolfGtiPriceSourceName,
          sourceUrl: _volkswagenGolfGtiPriceSourceUrl,
          sortOrder: 10,
        ),
      ];
    case 'model-volkswagen-093-kr|diesel':
      return [
        row(
          id: 'variant-volkswagen-touareg-2026-30-tdi-final-prestige',
          trimName: 'Touareg 3.0 TDI FINAL EDITION Prestige',
          engineName: '3.0 TDI V6',
          displacementCc: 2967,
          drivetrain: '4WD',
          transmission: '8단 자동',
          officialEfficiency: 10.8,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형 SUV',
          sourceName: _volkswagenTouaregPriceSourceName,
          sourceUrl: _volkswagenTouaregPriceSourceUrl,
          sortOrder: 10,
        ),
        row(
          id: 'variant-volkswagen-touareg-2026-30-tdi-final-r-line',
          trimName: 'Touareg 3.0 TDI FINAL EDITION R-Line',
          engineName: '3.0 TDI V6',
          displacementCc: 2967,
          drivetrain: '4WD',
          transmission: '8단 자동',
          officialEfficiency: 10.8,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형 SUV',
          sourceName: _volkswagenTouaregPriceSourceName,
          sourceUrl: _volkswagenTouaregPriceSourceUrl,
          sortOrder: 20,
        ),
      ];
    case 'model-volkswagen-atlas-kr|gasoline':
      return [
        row(
          id: 'variant-volkswagen-atlas-2026-20-tsi-7-seat',
          trimName: 'Atlas 2.0 TSI 7인승',
          engineName: '2.0 TSI',
          displacementCc: 1984,
          drivetrain: 'AWD',
          transmission: '8단 자동',
          officialEfficiency: 8.5,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형 SUV',
          sourceName: _volkswagenAtlasPriceSourceName,
          sourceUrl: _volkswagenAtlasPriceSourceUrl,
          sortOrder: 10,
        ),
        row(
          id: 'variant-volkswagen-atlas-2026-20-tsi-6-seat',
          trimName: 'Atlas 2.0 TSI 6인승',
          engineName: '2.0 TSI',
          displacementCc: 1984,
          drivetrain: 'AWD',
          transmission: '8단 자동',
          officialEfficiency: 8.5,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형 SUV',
          sourceName: _volkswagenAtlasPriceSourceName,
          sourceUrl: _volkswagenAtlasPriceSourceUrl,
          sortOrder: 20,
        ),
      ];
    case 'model-volkswagen-094-id-4|electric':
      return [
        row(
          id: 'variant-volkswagen-id4-2026-pro-lite-my25',
          trimName: 'ID.4 Pro Lite (MY25)',
          engineName: '영구 자석 동기모터',
          batteryKwh: 82.836,
          drivetrain: 'RWD',
          transmission: '감속기',
          officialEfficiency: 4.9,
          efficiencyUnit: 'km/kWh',
          vehicleClass: 'SUV',
          sourceName: _volkswagenId4PriceSourceName,
          sourceUrl: _volkswagenId4PriceSourceUrl,
          sortOrder: 10,
        ),
        row(
          id: 'variant-volkswagen-id4-2026-pro-my25',
          trimName: 'ID.4 Pro (MY25)',
          engineName: '영구 자석 동기모터',
          batteryKwh: 82.836,
          drivetrain: 'RWD',
          transmission: '감속기',
          officialEfficiency: 4.9,
          efficiencyUnit: 'km/kWh',
          vehicleClass: 'SUV',
          sourceName: _volkswagenId4PriceSourceName,
          sourceUrl: _volkswagenId4PriceSourceUrl,
          sortOrder: 20,
        ),
      ];
    case 'model-volkswagen-id5-kr|electric':
      return [
        row(
          id: 'variant-volkswagen-id5-2026-pro-lite',
          trimName: 'ID.5 Pro Lite (MY26)',
          engineName: '영구 자석 동기모터',
          batteryKwh: 82.836,
          drivetrain: 'RWD',
          transmission: '감속기',
          officialEfficiency: 5.2,
          efficiencyUnit: 'km/kWh',
          vehicleClass: 'SUV',
          sourceName: _volkswagenId5PriceSourceName,
          sourceUrl: _volkswagenId5PriceSourceUrl,
          sortOrder: 10,
        ),
        row(
          id: 'variant-volkswagen-id5-2026-pro',
          trimName: 'ID.5 Pro (MY26)',
          engineName: '영구 자석 동기모터',
          batteryKwh: 82.836,
          drivetrain: 'RWD',
          transmission: '감속기',
          officialEfficiency: 5.2,
          efficiencyUnit: 'km/kWh',
          vehicleClass: 'SUV',
          sourceName: _volkswagenId5PriceSourceName,
          sourceUrl: _volkswagenId5PriceSourceUrl,
          sortOrder: 20,
        ),
      ];
  }

  return const [];
}

List<OfficialPowertrain> _toyota2026OfficialPowertrains(
  String modelId,
  String fuelLeague,
) {
  OfficialPowertrain row({
    required String id,
    required String trimName,
    required String engineName,
    int? displacementCc,
    double? batteryKwh,
    required String drivetrain,
    required String transmission,
    required double officialEfficiency,
    required String vehicleClass,
    required String sourceName,
    required String sourceUrl,
    required int sortOrder,
  }) {
    return OfficialPowertrain(
      id: id,
      trimName: trimName,
      engineName: engineName,
      displacementCc: displacementCc,
      batteryKwh: batteryKwh,
      drivetrain: drivetrain,
      transmission: transmission,
      officialEfficiency: officialEfficiency,
      efficiencyUnit: 'km/L',
      vehicleClass: vehicleClass,
      isVerified: true,
      sourceStatus: 'verified_official',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      lastVerifiedAt: '2026-06-13',
      confidenceScore: 0.90,
      isSelectable: true,
      sortOrder: sortOrder,
    );
  }

  switch ('$modelId|$fuelLeague') {
    case 'model-toyota-096-kr|hybrid':
      return [
        row(
          id: 'variant-toyota-prius-2026-hev-2wd',
          trimName: 'PRIUS HEV 2WD XLE/LE',
          engineName: '2.0L 하이브리드 시스템',
          displacementCc: 1987,
          drivetrain: '2WD',
          transmission: '무단 자동 변속기 (e-CVT)',
          officialEfficiency: 20.9,
          vehicleClass: '준중형',
          sourceName: 'Toyota Korea official Prius HEV model page',
          sourceUrl: 'https://www.toyota.co.kr/models/priushev/',
          sortOrder: 10,
        ),
        row(
          id: 'variant-toyota-prius-2026-hev-awd',
          trimName: 'PRIUS HEV AWD XLE',
          engineName: '2.0L 하이브리드 시스템',
          displacementCc: 1987,
          drivetrain: 'E-Four AWD',
          transmission: '무단 자동 변속기 (e-CVT)',
          officialEfficiency: 20.0,
          vehicleClass: '준중형',
          sourceName: 'Toyota Korea official Prius HEV model page',
          sourceUrl: 'https://www.toyota.co.kr/models/priushev/',
          sortOrder: 20,
        ),
      ];
    case 'model-toyota-096-kr|plug_in_hybrid':
      return [
        row(
          id: 'variant-toyota-prius-2026-phev',
          trimName: 'PRIUS PHEV',
          engineName: '2.0L 플러그인 하이브리드 시스템',
          displacementCc: 1987,
          batteryKwh: 13.6,
          drivetrain: '공식 제원 확인',
          transmission: '무단 자동 변속기 (e-CVT)',
          officialEfficiency: 19.4,
          vehicleClass: '준중형',
          sourceName: 'Toyota Korea official Prius PHEV model page',
          sourceUrl: 'https://www.toyota.co.kr/models/priusphev/',
          sortOrder: 30,
        ),
      ];
    case 'model-toyota-097-kr|hybrid':
      return [
        row(
          id: 'variant-toyota-camry-2026-hev',
          trimName: 'CAMRY HEV',
          engineName: '2.5L 하이브리드 시스템',
          displacementCc: 2487,
          drivetrain: '공식 제원 확인',
          transmission: '무단 자동 변속기 (e-CVT)',
          officialEfficiency: 17.1,
          vehicleClass: '중형',
          sourceName: 'Toyota Korea official Camry model page',
          sourceUrl: 'https://toyota.co.kr/models/camry/',
          sortOrder: 10,
        ),
      ];
    case 'model-toyota-098-4|hybrid':
      return [
        row(
          id: 'variant-toyota-rav4-2026-hev-2wd-xle',
          trimName: 'RAV4 HEV 2WD XLE',
          engineName: '2.5L 다이내믹 포스 하이브리드',
          displacementCc: 2487,
          drivetrain: '2WD',
          transmission: '무단 자동 변속기 (e-CVT)',
          officialEfficiency: 14.5,
          vehicleClass: 'SUV',
          sourceName: 'Toyota Korea official RAV4 HEV model page',
          sourceUrl: 'https://toyota.co.kr/models/rav4hev/',
          sortOrder: 10,
        ),
        row(
          id: 'variant-toyota-rav4-2026-hev-awd-ltd',
          trimName: 'RAV4 HEV AWD LTD',
          engineName: '2.5L 다이내믹 포스 하이브리드',
          displacementCc: 2487,
          drivetrain: 'E-Four AWD',
          transmission: '무단 자동 변속기 (e-CVT)',
          officialEfficiency: 14.1,
          vehicleClass: 'SUV',
          sourceName: 'Toyota Korea official RAV4 HEV model page',
          sourceUrl: 'https://toyota.co.kr/models/rav4hev/',
          sortOrder: 20,
        ),
      ];
    case 'model-toyota-098-4|plug_in_hybrid':
      return [
        row(
          id: 'variant-toyota-rav4-2026-phev-xse',
          trimName: 'RAV4 PHEV XSE',
          engineName: '2.5L 플러그인 하이브리드 시스템',
          displacementCc: 2487,
          batteryKwh: 18.1,
          drivetrain: '사륜구동',
          transmission: '무단 자동 변속기 (e-CVT)',
          officialEfficiency: 15.6,
          vehicleClass: 'SUV',
          sourceName: 'Toyota Korea official RAV4 PHEV model page',
          sourceUrl: 'https://toyota.co.kr/models/rav4phev/',
          sortOrder: 30,
        ),
      ];
    case 'model-toyota-099-kr|hybrid':
      return [
        row(
          id: 'variant-toyota-highlander-2026-hev-platinum',
          trimName: 'HIGHLANDER 2.5 HEV PLATINUM',
          engineName: '2.5L 하이브리드 파워트레인',
          displacementCc: 2487,
          drivetrain: 'E-Four AWD',
          transmission: '무단 자동 변속기 (e-CVT)',
          officialEfficiency: 13.8,
          vehicleClass: '대형 SUV',
          sourceName: 'Toyota Korea official Highlander model page',
          sourceUrl: 'https://toyota.co.kr/models/highlander/',
          sortOrder: 10,
        ),
      ];
    case 'model-toyota-100-kr|hybrid':
      return [
        row(
          id: 'variant-toyota-sienna-2026-hev-2wd',
          trimName: 'SIENNA HEV 2WD',
          engineName: '2.5L 다이내믹 포스 하이브리드',
          displacementCc: 2487,
          drivetrain: '2WD',
          transmission: '무단 자동 변속기 (e-CVT)',
          officialEfficiency: 14.5,
          vehicleClass: 'MPV',
          sourceName: 'Toyota Korea official Sienna model page',
          sourceUrl: 'https://toyota.co.kr/models/sienna/',
          sortOrder: 10,
        ),
        row(
          id: 'variant-toyota-sienna-2026-hev-awd',
          trimName: 'SIENNA HEV AWD',
          engineName: '2.5L 다이내믹 포스 하이브리드',
          displacementCc: 2487,
          drivetrain: 'E-Four AWD',
          transmission: '무단 자동 변속기 (e-CVT)',
          officialEfficiency: 13.7,
          vehicleClass: 'MPV',
          sourceName: 'Toyota Korea official Sienna model page',
          sourceUrl: 'https://toyota.co.kr/models/sienna/',
          sortOrder: 20,
        ),
      ];
    case 'model-toyota-101-kr|hybrid':
      return [
        row(
          id: 'variant-toyota-crown-2026-hev',
          trimName: 'CROWN HEV',
          engineName: '2.5L 자연흡기 가솔린 하이브리드',
          displacementCc: 2487,
          drivetrain: '공식 제원 확인',
          transmission: '무단 자동 변속기 (e-CVT)',
          officialEfficiency: 17.2,
          vehicleClass: '대형',
          sourceName: 'Toyota Korea official Crown model page',
          sourceUrl: 'https://toyota.co.kr/models/crown/',
          sortOrder: 10,
        ),
        row(
          id: 'variant-toyota-crown-2026-dual-boost-hev',
          trimName: 'CROWN Dual Boost HEV',
          engineName: '2.4L 가솔린 터보 하이브리드',
          displacementCc: 2393,
          drivetrain: 'E-Four Advanced AWD',
          transmission: '무단 자동 변속기 (e-CVT)',
          officialEfficiency: 11.0,
          vehicleClass: '대형',
          sourceName: 'Toyota Korea official Crown model page',
          sourceUrl: 'https://toyota.co.kr/models/crown/',
          sortOrder: 20,
        ),
      ];
    case 'model-toyota-102-gr86|gasoline':
      return [
        row(
          id: 'variant-toyota-gr86-2026-24-gasoline',
          trimName: 'GR86 2.4 가솔린',
          engineName: '2.4L 수평대향 가솔린 엔진',
          displacementCc: 2387,
          drivetrain: '공식 제원 확인',
          transmission: '공식 제원 확인',
          officialEfficiency: 9.5,
          vehicleClass: '준중형',
          sourceName: 'Toyota Korea official GR86 model page',
          sourceUrl: 'https://toyota.co.kr/models/gr86/',
          sortOrder: 10,
        ),
      ];
    case 'model-toyota-alphard-kr|hybrid':
      return [
        row(
          id: 'variant-toyota-alphard-2026-hev',
          trimName: 'ALPHARD HEV',
          engineName: '2.5L 하이브리드 시스템',
          displacementCc: 2487,
          drivetrain: 'E-Four AWD',
          transmission: '무단 자동 변속기 (e-CVT)',
          officialEfficiency: 13.5,
          vehicleClass: 'MPV',
          sourceName: 'Toyota Korea official Alphard model page',
          sourceUrl: 'https://toyota.co.kr/models/alphard/',
          sortOrder: 10,
        ),
      ];
  }

  return const [];
}

List<OfficialPowertrain> _lexus2026OfficialPowertrains(
  String modelId,
  String fuelLeague,
) {
  OfficialPowertrain row({
    required String id,
    required String trimName,
    required String engineName,
    int? displacementCc,
    double? batteryKwh,
    required String efficiencyUnit,
    required String vehicleClass,
    required String sourceUrl,
    String sourceName = 'Lexus Korea official electrified/model page',
    double confidenceScore = 0.62,
    required int sortOrder,
  }) {
    return OfficialPowertrain(
      id: id,
      trimName: trimName,
      engineName: engineName,
      displacementCc: displacementCc,
      batteryKwh: batteryKwh,
      drivetrain: '검수 대기',
      transmission: '검수 대기',
      officialEfficiency: null,
      efficiencyUnit: efficiencyUnit,
      vehicleClass: vehicleClass,
      sourceStatus: 'pending_review',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      lastVerifiedAt: '2026-06-13',
      confidenceScore: confidenceScore,
      isSelectable: false,
      sortOrder: sortOrder,
    );
  }

  switch ('$modelId|$fuelLeague') {
    case 'model-lexus-103-es|hybrid':
      return [
        row(
          id: 'variant-lexus-es-2026-300h-pending',
          trimName: 'ES 300h 공식 제원 검수 대기',
          engineName: 'ES 300h hybrid official specification review pending',
          displacementCc: 2487,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형',
          sourceUrl: 'https://www.lexus.co.kr/models/ES-300h/',
          sortOrder: 10,
        ),
      ];
    case 'model-lexus-104-ls|hybrid':
      return [
        row(
          id: 'variant-lexus-ls-2026-500h-pending',
          trimName: 'LS 500h 공식 제원 검수 대기',
          engineName: 'LS 500h hybrid official specification review pending',
          displacementCc: 3456,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형',
          sourceUrl: 'https://www.lexus.co.kr/models/LS-500h/',
          sortOrder: 10,
        ),
      ];
    case 'model-lexus-104-ls|gasoline':
      return [
        row(
          id: 'variant-lexus-ls-2026-500-pending',
          trimName: 'LS 500 공식 제원 검수 대기',
          engineName: 'LS 500 gasoline official specification review pending',
          displacementCc: 3445,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형',
          sourceName: 'Lexus Korea official model JSON/model page',
          sourceUrl: 'https://www.lexus.co.kr/models/LS-500/',
          sortOrder: 20,
        ),
      ];
    case 'model-lexus-105-nx|hybrid':
      return [
        row(
          id: 'variant-lexus-nx-2026-350h-pending',
          trimName: 'NX 350h 공식 제원 검수 대기',
          engineName: 'NX 350h hybrid official specification review pending',
          displacementCc: 2487,
          efficiencyUnit: 'km/L',
          vehicleClass: 'SUV',
          sourceUrl: 'https://www.lexus.co.kr/models/NX-350h/',
          sortOrder: 10,
        ),
      ];
    case 'model-lexus-105-nx|plug_in_hybrid':
      return [
        row(
          id: 'variant-lexus-nx-2026-450h-plus-pending',
          trimName: 'NX 450h+ 공식 제원 검수 대기',
          engineName:
              'NX 450h+ plug-in hybrid official specification review pending',
          displacementCc: 2487,
          efficiencyUnit: 'km/L',
          vehicleClass: 'SUV',
          sourceUrl: 'https://www.lexus.co.kr/models/NX-450h-plus/',
          sortOrder: 20,
        ),
      ];
    case 'model-lexus-106-rx|hybrid':
      return [
        row(
          id: 'variant-lexus-rx-2026-350h-pending',
          trimName: 'RX 350h 공식 제원 검수 대기',
          engineName: 'RX 350h hybrid official specification review pending',
          displacementCc: 2487,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형 SUV',
          sourceUrl: 'https://www.lexus.co.kr/models/RX-350h/',
          sortOrder: 10,
        ),
        row(
          id: 'variant-lexus-rx-2026-500h-pending',
          trimName: 'RX 500h 공식 제원 검수 대기',
          engineName: 'RX 500h hybrid official specification review pending',
          displacementCc: 2393,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형 SUV',
          sourceUrl: 'https://www.lexus.co.kr/models/RX-500h/',
          sortOrder: 20,
        ),
      ];
    case 'model-lexus-106-rx|plug_in_hybrid':
      return [
        row(
          id: 'variant-lexus-rx-2026-450h-plus-pending',
          trimName: 'RX 450h+ 공식 제원 검수 대기',
          engineName:
              'RX 450h+ plug-in hybrid official specification review pending',
          displacementCc: 2487,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형 SUV',
          sourceUrl: 'https://www.lexus.co.kr/models/RX-450h-plus/',
          sortOrder: 30,
        ),
      ];
    case 'model-lexus-107-ux|hybrid':
      return [
        row(
          id: 'variant-lexus-ux-2026-300h-2wd-pending',
          trimName: 'UX 300h 2WD 공식 제원 검수 대기',
          engineName: 'UX 300h hybrid official specification review pending',
          displacementCc: 1987,
          efficiencyUnit: 'km/L',
          vehicleClass: '소형 SUV',
          sourceUrl: 'https://www.lexus.co.kr/models/UX-300h/',
          sortOrder: 10,
        ),
        row(
          id: 'variant-lexus-ux-2026-300h-f-sport-pending',
          trimName: 'UX 300h F SPORT 공식 제원 검수 대기',
          engineName: 'UX 300h hybrid official specification review pending',
          displacementCc: 1987,
          efficiencyUnit: 'km/L',
          vehicleClass: '소형 SUV',
          sourceUrl: 'https://www.lexus.co.kr/models/UX-300h/',
          sortOrder: 20,
        ),
      ];
    case 'model-lexus-108-rz|electric':
      return [
        row(
          id: 'variant-lexus-rz-2026-450e-pending',
          trimName: 'RZ 450e 공식 제원 검수 대기',
          engineName: 'RZ 450e electric official specification review pending',
          efficiencyUnit: 'km/kWh',
          vehicleClass: 'SUV',
          sourceUrl: 'https://www.lexus.co.kr/models/RZ-450e/',
          sortOrder: 10,
        ),
      ];
    case 'model-lexus-lm-kr|hybrid':
      return [
        row(
          id: 'variant-lexus-lm-2026-500h-pending',
          trimName: 'LM 500h 공식 제원 검수 대기',
          engineName: 'LM 500h hybrid official specification review pending',
          displacementCc: 2393,
          efficiencyUnit: 'km/L',
          vehicleClass: 'MPV',
          sourceUrl: 'https://www.lexus.co.kr/models/LM-500h/',
          sortOrder: 10,
        ),
      ];
    case 'model-lexus-lx-kr|hybrid':
      return [
        row(
          id: 'variant-lexus-lx-2026-700h-pending',
          trimName: 'LX 700h 공식 제원 검수 대기',
          engineName: 'LX 700h hybrid official specification review pending',
          displacementCc: 3445,
          efficiencyUnit: 'km/L',
          vehicleClass: '대형 SUV',
          sourceName: 'Lexus Korea official LX model page and model JSON',
          sourceUrl: 'https://www.lexus.co.kr/models/LX/',
          confidenceScore: 0.68,
          sortOrder: 10,
        ),
      ];
  }

  return const [];
}

List<OfficialPowertrain> _landRover2026OfficialPowertrains(
  String modelId,
  String fuelLeague,
) {
  OfficialPowertrain row({
    required String id,
    required String trimName,
    required String vehicleClass,
    required String sourceUrl,
    required int sortOrder,
  }) {
    return OfficialPowertrain(
      id: id,
      trimName: '$trimName 공식 제원 검수 대기',
      engineName: '$trimName official specification review pending',
      drivetrain: '검수 대기',
      transmission: '검수 대기',
      officialEfficiency: null,
      efficiencyUnit: 'km/L',
      vehicleClass: vehicleClass,
      sourceStatus: 'pending_review',
      sourceName: 'Land Rover Korea official 2026 price page',
      sourceUrl: sourceUrl,
      lastVerifiedAt: '2026-06-13',
      confidenceScore: 0.60,
      isSelectable: false,
      sortOrder: sortOrder,
    );
  }

  switch ('$modelId|$fuelLeague') {
    case 'model-landrover-154-kr|diesel':
      return [
        row(
          id: 'variant-landrover-defender-2026-d250-pending',
          trimName: 'Defender D250',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/defender/defender-110/price-and-spec.html',
          sortOrder: 10,
        ),
        row(
          id: 'variant-landrover-defender-2026-d300-pending',
          trimName: 'Defender D300',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/defender/defender-110/price-and-spec.html',
          sortOrder: 20,
        ),
      ];
    case 'model-landrover-154-kr|gasoline':
      return [
        row(
          id: 'variant-landrover-defender-2026-p300-pending',
          trimName: 'Defender P300',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/defender/defender-110/price-and-spec.html',
          sortOrder: 30,
        ),
        row(
          id: 'variant-landrover-defender-2026-p400-pending',
          trimName: 'Defender P400',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/defender/defender-110/price-and-spec.html',
          sortOrder: 40,
        ),
        row(
          id: 'variant-landrover-defender-2026-p635-pending',
          trimName: 'Defender P635 OCTA',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/defender/defender-110/price-and-spec.html',
          sortOrder: 50,
        ),
      ];
    case 'model-landrover-155-kr|diesel':
      return [
        row(
          id: 'variant-landrover-discovery-2026-d350-pending',
          trimName: 'Discovery D350',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/discovery/discovery/price-and-spec.html',
          sortOrder: 10,
        ),
      ];
    case 'model-landrover-155-kr|gasoline':
      return [
        row(
          id: 'variant-landrover-discovery-2026-p300-pending',
          trimName: 'Discovery P300',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/discovery/discovery/price-and-spec.html',
          sortOrder: 20,
        ),
        row(
          id: 'variant-landrover-discovery-2026-p360-pending',
          trimName: 'Discovery P360',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/discovery/discovery/price-and-spec.html',
          sortOrder: 30,
        ),
      ];
    case 'model-landrover-156-kr|gasoline':
      return [
        row(
          id: 'variant-landrover-range-rover-2026-p530-pending',
          trimName: 'Range Rover P530',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/range-rover/range-rover/price-and-spec.html',
          sortOrder: 10,
        ),
        row(
          id: 'variant-landrover-range-rover-2026-p615-pending',
          trimName: 'Range Rover P615 SV',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/range-rover/range-rover/price-and-spec.html',
          sortOrder: 20,
        ),
      ];
    case 'model-landrover-156-kr|plug_in_hybrid':
      return [
        row(
          id: 'variant-landrover-range-rover-2026-p550e-pending',
          trimName: 'Range Rover P550e',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/range-rover/range-rover/price-and-spec.html',
          sortOrder: 30,
        ),
      ];
    case 'model-landrover-157-kr|gasoline':
      return [
        row(
          id: 'variant-landrover-range-rover-sport-2026-p360-pending',
          trimName: 'Range Rover Sport P360',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/range-rover/range-rover-sport/price-and-spec.html',
          sortOrder: 10,
        ),
        row(
          id: 'variant-landrover-range-rover-sport-2026-p400-pending',
          trimName: 'Range Rover Sport P400',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/range-rover/range-rover-sport/price-and-spec.html',
          sortOrder: 20,
        ),
        row(
          id: 'variant-landrover-range-rover-sport-2026-p635-pending',
          trimName: 'Range Rover Sport P635 SV',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/range-rover/range-rover-sport/price-and-spec.html',
          sortOrder: 30,
        ),
      ];
    case 'model-landrover-157-kr|plug_in_hybrid':
      return [
        row(
          id: 'variant-landrover-range-rover-sport-2026-p550e-pending',
          trimName: 'Range Rover Sport P550e',
          vehicleClass: '대형 SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/range-rover/range-rover-sport/price-and-spec.html',
          sortOrder: 40,
        ),
      ];
    case 'model-landrover-158-kr|gasoline':
      return [
        row(
          id: 'variant-landrover-evoque-2026-p250-pending',
          trimName: 'Range Rover Evoque P250',
          vehicleClass: 'SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/range-rover/range-rover-evoque/price-and-spec.html',
          sortOrder: 10,
        ),
      ];
    case 'model-landrover-discovery-sport-kr|gasoline':
      return [
        row(
          id: 'variant-landrover-discovery-sport-2026-p250-pending',
          trimName: 'Discovery Sport P250',
          vehicleClass: 'SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/discovery/discovery-sport/price-and-spec.html',
          sortOrder: 10,
        ),
      ];
    case 'model-landrover-range-rover-velar-kr|gasoline':
      return [
        row(
          id: 'variant-landrover-velar-2026-p250-pending',
          trimName: 'Range Rover Velar P250',
          vehicleClass: 'SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/range-rover/range-rover-velar/price-and-spec.html',
          sortOrder: 10,
        ),
        row(
          id: 'variant-landrover-velar-2026-p400-pending',
          trimName: 'Range Rover Velar P400',
          vehicleClass: 'SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/range-rover/range-rover-velar/price-and-spec.html',
          sortOrder: 20,
        ),
      ];
    case 'model-landrover-range-rover-velar-kr|plug_in_hybrid':
      return [
        row(
          id: 'variant-landrover-velar-2026-p400e-pending',
          trimName: 'Range Rover Velar P400e',
          vehicleClass: 'SUV',
          sourceUrl:
              'https://www.landroverkorea.co.kr/range-rover/range-rover-velar/price-and-spec.html',
          sortOrder: 30,
        ),
      ];
  }

  return const [];
}

List<OfficialPowertrain> _jeep2026OfficialPowertrains(
  String modelId,
  String fuelLeague,
) {
  if (modelId != 'model-jeep-152-kr' || fuelLeague != 'gasoline') {
    return const [];
  }

  return const [
    OfficialPowertrain(
      id: 'variant-jeep-152-kr-2026-gasoline',
      trimName: 'Wrangler',
      engineName: 'Pending official Wrangler specification review',
      drivetrain: 'review pending',
      transmission: 'review pending',
      officialEfficiency: null,
      efficiencyUnit: 'km/L',
      vehicleClass: 'SUV',
      sourceStatus: 'pending_review',
      sourceName: 'Jeep Korea official Wrangler page',
      sourceUrl: 'https://www.jeep.co.kr/wrangler.html',
      lastVerifiedAt: '2026-06-13',
      confidenceScore: 0.58,
      isSelectable: false,
      sortOrder: 10,
    ),
    OfficialPowertrain(
      id: 'variant-jeep-wrangler-2026-trail-hunt-pending',
      trimName: 'Wrangler Trail Hunt Edition',
      engineName:
          'Pending official Wrangler Trail Hunt Edition specification review',
      drivetrain: 'review pending',
      transmission: 'review pending',
      officialEfficiency: null,
      efficiencyUnit: 'km/L',
      vehicleClass: 'SUV',
      sourceStatus: 'pending_review',
      sourceName: 'Jeep Korea official Wrangler Trail Hunt Edition page',
      sourceUrl: 'https://www.jeep.co.kr/JL/wrangler/edition.html',
      lastVerifiedAt: '2026-06-13',
      confidenceScore: 0.62,
      isSelectable: false,
      sortOrder: 11,
    ),
  ];
}

final _officialPowertrains = {
  'model-hyundai-001-kr|2026|gasoline': const OfficialPowertrain(
    id: 'variant-hyundai-avante-2026-gasoline',
    trimName: '1.6 가솔린',
    engineName: 'Smartstream G1.6',
    displacementCc: 1598,
    drivetrain: 'FWD',
    transmission: 'IVT',
    officialEfficiency: 15.0,
    efficiencyUnit: 'km/L',
  ),
  'model-hyundai-001-kr|2026|hybrid': const OfficialPowertrain(
    id: 'variant-hyundai-avante-2026-hybrid',
    trimName: '1.6 하이브리드',
    engineName: 'Smartstream G1.6 Hybrid',
    displacementCc: 1580,
    drivetrain: 'FWD',
    transmission: '6단 DCT',
    officialEfficiency: 21.1,
    efficiencyUnit: 'km/L',
  ),
  'model-hyundai-001-kr|2026|lpg': const OfficialPowertrain(
    id: 'variant-hyundai-avante-2026-lpi',
    trimName: '1.6 LPi',
    engineName: 'LPi 1.6',
    displacementCc: 1591,
    drivetrain: 'FWD',
    transmission: '자동 6단',
    officialEfficiency: 10.5,
    efficiencyUnit: 'km/L',
  ),
  'model-hyundai-avante-sport-kr|2018|gasoline': const OfficialPowertrain(
    id: 'variant-hyundai-avante-sport-2018-16t-7dct',
    trimName: '1.6T 가솔린',
    engineName: 'Gamma 1.6 T-GDi',
    displacementCc: 1591,
    drivetrain: 'FWD',
    transmission: '7단 DCT',
    officialEfficiency: 12.0,
    efficiencyUnit: 'km/L',
  ),
  'model-chevrolet-038-kr|2025|gasoline': const OfficialPowertrain(
    id: 'variant-chevrolet-traverse-2025-official-lineup-pending',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official Traverse 3.6L V6 specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/L',
    vehicleClass: '대형 SUV',
    sourceStatus: 'pending_review',
    sourceName: 'Chevrolet Korea official SUV lineup page',
    sourceUrl: 'https://www.chevrolet.co.kr/suvs',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.6,
    isSelectable: false,
  ),
  'model-chevrolet-038-kr|2026|gasoline': const OfficialPowertrain(
    id: 'variant-chevrolet-traverse-2026-official-lineup-pending',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official Traverse 3.6L V6 specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/L',
    vehicleClass: '대형 SUV',
    sourceStatus: 'pending_review',
    sourceName: 'Chevrolet Korea official SUV lineup page',
    sourceUrl: 'https://www.chevrolet.co.kr/suvs',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.6,
    isSelectable: false,
  ),
  'model-chevrolet-039-kr|2025|gasoline': const OfficialPowertrain(
    id: 'variant-chevrolet-tahoe-2025-official-lineup-pending',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official Tahoe 6.2L V8 specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/L',
    vehicleClass: '대형 SUV',
    sourceStatus: 'pending_review',
    sourceName: 'Chevrolet Korea official SUV lineup page',
    sourceUrl: 'https://www.chevrolet.co.kr/suvs',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.6,
    isSelectable: false,
  ),
  'model-chevrolet-039-kr|2026|gasoline': const OfficialPowertrain(
    id: 'variant-chevrolet-tahoe-2026-official-lineup-pending',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official Tahoe 6.2L V8 specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/L',
    vehicleClass: '대형 SUV',
    sourceStatus: 'pending_review',
    sourceName: 'Chevrolet Korea official SUV lineup page',
    sourceUrl: 'https://www.chevrolet.co.kr/suvs',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.6,
    isSelectable: false,
  ),
  'model-chevrolet-equinox-kr|2026|gasoline': const OfficialPowertrain(
    id: 'variant-chevrolet-equinox-2026-official-lineup-pending',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official Equinox 1.5L turbo specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/L',
    vehicleClass: 'SUV',
    sourceStatus: 'pending_review',
    sourceName: 'Chevrolet Korea official SUV lineup page',
    sourceUrl: 'https://www.chevrolet.co.kr/suvs',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.62,
    isSelectable: false,
  ),
  'model-kgm-torres-van-kr|2026|gasoline': const OfficialPowertrain(
    id: 'variant-kgm-torres-van-2026-gasoline-pending',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official Torres Van specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/L',
    vehicleClass: '상용',
    sourceStatus: 'pending_review',
    sourceName: 'KGM official Korean model list',
    sourceUrl: 'https://www.kg-mobility.com/pr/model',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.64,
    isSelectable: false,
  ),
  'model-kgm-torres-evx-van-kr|2026|electric': const OfficialPowertrain(
    id: 'variant-kgm-torres-evx-van-2026-electric-pending',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official Torres EVX Van specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/kWh',
    vehicleClass: '상용',
    sourceStatus: 'pending_review',
    sourceName: 'KGM official Korean model list',
    sourceUrl: 'https://www.kg-mobility.com/pr/model',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.64,
    isSelectable: false,
  ),
  'model-kgm-rexton-summit-kr|2026|diesel': const OfficialPowertrain(
    id: 'variant-kgm-rexton-summit-2026-diesel-pending',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official Rexton Summit specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/L',
    vehicleClass: '대형 SUV',
    sourceStatus: 'pending_review',
    sourceName: 'KGM official Korean model list',
    sourceUrl: 'https://www.kg-mobility.com/pr/model',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.64,
    isSelectable: false,
  ),
  'model-volvo-ex40-kr|2025|electric': const OfficialPowertrain(
    id: 'variant-volvo-ex40-kr-2025-electric',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official EX40 electric specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/kWh',
    sourceStatus: 'pending_review',
    sourceName: 'Volvo Cars Korea official EX40/EC40 rename news and support',
    sourceUrl:
        'https://www.volvocars.com/kr/news/corporate/new-name-new-me-say-hello-to-the-ex40-and-ec40/',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.62,
    isSelectable: false,
  ),
  'model-volvo-ex40-kr|2026|electric': const OfficialPowertrain(
    id: 'variant-volvo-ex40-kr-2026-electric',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official EX40 electric specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/kWh',
    sourceStatus: 'pending_review',
    sourceName: 'Volvo Cars Korea official EX40/EC40 rename news and support',
    sourceUrl:
        'https://www.volvocars.com/kr/news/corporate/new-name-new-me-say-hello-to-the-ex40-and-ec40/',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.62,
    isSelectable: false,
  ),
  'model-volvo-ec40-kr|2025|electric': const OfficialPowertrain(
    id: 'variant-volvo-ec40-kr-2025-electric',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official EC40 electric specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/kWh',
    sourceStatus: 'pending_review',
    sourceName: 'Volvo Cars Korea official EX40/EC40 rename news and support',
    sourceUrl:
        'https://www.volvocars.com/kr/news/corporate/new-name-new-me-say-hello-to-the-ex40-and-ec40/',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.62,
    isSelectable: false,
  ),
  'model-volvo-ec40-kr|2026|electric': const OfficialPowertrain(
    id: 'variant-volvo-ec40-kr-2026-electric',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official EC40 electric specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/kWh',
    sourceStatus: 'pending_review',
    sourceName: 'Volvo Cars Korea official EX40/EC40 rename news and support',
    sourceUrl:
        'https://www.volvocars.com/kr/news/corporate/new-name-new-me-say-hello-to-the-ex40-and-ec40/',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.62,
    isSelectable: false,
  ),
  'model-porsche-136-kr|2026|electric': const OfficialPowertrain(
    id: 'variant-porsche-macan-2026-electric-pending',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official Macan Electric specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/kWh',
    sourceStatus: 'pending_review',
    sourceName: 'Porsche Korea official Macan Electric model page',
    sourceUrl: 'https://www.porsche.com/korea/ko/models/macan/',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.58,
    isSelectable: false,
  ),
  'model-porsche-137-kr|2026|electric': const OfficialPowertrain(
    id: 'variant-porsche-cayenne-2026-electric-pending',
    trimName: '공식 제원 검수 대기',
    engineName: 'Pending official Cayenne Electric specification review',
    drivetrain: '검수 대기',
    transmission: '검수 대기',
    officialEfficiency: null,
    efficiencyUnit: 'km/kWh',
    sourceStatus: 'pending_review',
    sourceName: 'Porsche Korea official Cayenne Electric model page',
    sourceUrl:
        'https://www.porsche.com/korea/ko/models/cayenne/cayenne-electric-models/cayenne-electric/',
    lastVerifiedAt: '2026-06-13',
    confidenceScore: 0.58,
    isSelectable: false,
  ),
};

List<Map<String, Object?>> _manufacturers() {
  Map<String, Object?> make(
    String id,
    String nameKo,
    String nameEn,
    String country,
    List<ModelSeed> models, {
    bool popular = false,
    int sortOrder = 0,
  }) {
    return {
      'id': id,
      'name_ko': nameKo,
      'name_en': nameEn,
      'country': country,
      'logo_url': '',
      'is_popular': popular,
      'sort_order': sortOrder,
      'models': models,
    };
  }

  return [
    make(
        'm-hyundai',
        '현대',
        'Hyundai',
        'KR',
        [
          m('아반떼', 'Avante', '세단', ['가솔린', '하이브리드', 'LPG'], '준중형',
              popular: true),
          m('아반떼 N', 'Avante N', '고성능 세단', ['가솔린'], '스포츠',
              id: 'model-hyundai-avante-n-kr',
              sortOrder: 11,
              popular: true,
              firstYear: 2021),
          m('아반떼 스포츠', 'Avante Sport', '스포츠 세단', ['가솔린'], '스포츠',
              id: 'model-hyundai-avante-sport-kr',
              sortOrder: 12,
              firstYear: 2016,
              lastYear: 2018),
          m('쏘나타', 'Sonata', '세단', ['가솔린', '하이브리드', 'LPG'], '중형'),
          m('그랜저', 'Grandeur', '세단', ['가솔린', '하이브리드'], '대형'),
          m(
            '코나',
            'Kona',
            'SUV',
            ['가솔린', '하이브리드', '전기차'],
            '소형 SUV',
            firstYear: 2017,
            fuelTypeYearRanges: {
              '하이브리드': FuelTypeYearRange(firstYear: 2020, lastYear: 2026),
              '전기차': FuelTypeYearRange(firstYear: 2018, lastYear: 2026),
            },
          ),
          m('베뉴', 'Venue', 'SUV', ['가솔린'], '소형 SUV',
              id: 'model-hyundai-venue-kr', firstYear: 2026, sortOrder: 41),
          m('투싼', 'Tucson', 'SUV', ['가솔린', '디젤', '하이브리드'], 'SUV'),
          m('싼타페', 'Santa Fe', 'SUV', ['가솔린', '하이브리드'], 'SUV'),
          m(
            '팰리세이드',
            'Palisade',
            'SUV',
            ['가솔린', '하이브리드', '디젤'],
            '대형 SUV',
            firstYear: 2019,
            fuelTypeYearRanges: {
              '하이브리드': FuelTypeYearRange(firstYear: 2025, lastYear: 2026),
              '디젤': FuelTypeYearRange(firstYear: 2019, lastYear: 2024),
            },
          ),
          m('캐스퍼', 'Casper', '경형 SUV', ['가솔린'], '경형', firstYear: 2021),
          m('캐스퍼 Electric', 'CASPER Electric', '전기 SUV', ['전기차'], '경형',
              id: 'model-hyundai-casper-electric-kr',
              firstYear: 2026,
              sortOrder: 81),
          m('아이오닉 5', 'IONIQ 5', '전기 SUV', ['전기차'], 'SUV', firstYear: 2021),
          m('아이오닉 5 N', 'IONIQ 5 N', '고성능 전기 SUV', ['전기차'], '스포츠',
              id: 'model-hyundai-ioniq5-n-kr', firstYear: 2026, sortOrder: 91),
          m('아이오닉 6', 'IONIQ 6', '전기 세단', ['전기차'], '중형', firstYear: 2022),
          m('아이오닉 6 N', 'IONIQ 6 N', '고성능 전기 세단', ['전기차'], '스포츠',
              id: 'model-hyundai-ioniq6-n-kr', firstYear: 2026, sortOrder: 101),
          m('아이오닉 9', 'IONIQ 9', '전기 SUV', ['전기차'], '대형 SUV',
              id: 'model-hyundai-ioniq9-kr', firstYear: 2026, sortOrder: 102),
          m('넥쏘', 'NEXO', '수소 SUV', ['수소전기차'], 'SUV',
              id: 'model-hyundai-nexo-kr', firstYear: 2026, sortOrder: 103),
          m(
            '스타리아',
            'Staria',
            'MPV',
            ['디젤', 'LPG', '하이브리드'],
            'MPV',
            firstYear: 2021,
            fuelTypeYearRanges: {
              '하이브리드': FuelTypeYearRange(firstYear: 2024, lastYear: 2026),
            },
          ),
          m('스타리아 Electric', 'STARIA Electric', '전기 MPV', ['전기차'], 'MPV',
              id: 'model-hyundai-staria-electric-kr',
              firstYear: 2026,
              sortOrder: 111),
          m(
            '포터',
            'Porter',
            '상용',
            ['디젤', 'LPG', '전기차'],
            '상용',
            fuelTypeYearRanges: {
              '디젤': FuelTypeYearRange(firstYear: 2015, lastYear: 2023),
              'LPG': FuelTypeYearRange(firstYear: 2024, lastYear: 2026),
              '전기차': FuelTypeYearRange(firstYear: 2019, lastYear: 2026),
            },
          ),
          m('ST1', 'ST1', '상용 전기차', ['전기차'], '상용',
              id: 'model-hyundai-st1-kr', firstYear: 2026, sortOrder: 121),
        ],
        popular: true,
        sortOrder: 10),
    make(
        'm-kia',
        '기아',
        'Kia',
        'KR',
        [
          m(
            'K3',
            'K3',
            '세단',
            ['가솔린', '디젤'],
            '준중형',
            firstYear: 2012,
            lastYear: 2024,
            fuelTypeYearRanges: {
              '디젤': FuelTypeYearRange(firstYear: 2016, lastYear: 2017),
            },
          ),
          m('K5', 'K5', '세단', ['가솔린', '하이브리드', 'LPG'], '중형', popular: true),
          m('K8', 'K8', '세단', ['가솔린', '하이브리드', 'LPG'], '대형', firstYear: 2021),
          m('K9', 'K9', '세단', ['가솔린'], '대형'),
          m('모닝', 'Morning', '경차', ['가솔린'], '경형'),
          m('레이', 'Ray', '경차', ['가솔린', '전기차'], '경형'),
          m('셀토스', 'Seltos', 'SUV', ['가솔린'], '소형 SUV', firstYear: 2019),
          m('니로', 'Niro', 'SUV', ['하이브리드', '전기차', '플러그인 하이브리드'], '소형 SUV',
              firstYear: 2016),
          m('스포티지', 'Sportage', 'SUV', ['가솔린', '디젤', '하이브리드'], 'SUV'),
          m('쏘렌토', 'Sorento', 'SUV', ['가솔린', '디젤', '하이브리드'], 'SUV'),
          m('카니발', 'Carnival', 'MPV', ['가솔린', '디젤', '하이브리드'], 'MPV'),
          m('EV3', 'EV3', '전기 SUV', ['전기차'], '소형 SUV', firstYear: 2024),
          m('EV4', 'EV4', '전기 세단', ['전기차'], '중형',
              id: 'model-kia-ev4-kr', firstYear: 2026, sortOrder: 121),
          m('EV5', 'EV5', '전기 SUV', ['전기차'], 'SUV',
              id: 'model-kia-ev5-kr', firstYear: 2026, sortOrder: 122),
          m('EV6', 'EV6', '전기 SUV', ['전기차'], 'SUV', firstYear: 2021),
          m('EV9', 'EV9', '전기 SUV', ['전기차'], '대형 SUV', firstYear: 2023),
          m('PV5', 'PV5', 'PBV', ['전기차'], '상용',
              id: 'model-kia-pv5-kr', firstYear: 2026, sortOrder: 141),
          m('타스만', 'Tasman', '픽업', ['가솔린'], '픽업',
              id: 'model-kia-tasman-kr', firstYear: 2026, sortOrder: 142),
          m('봉고', 'Bongo', '상용', ['디젤', '전기차', 'LPG'], '상용'),
        ],
        popular: true,
        sortOrder: 20),
    make(
        'm-genesis',
        '제네시스',
        'Genesis',
        'KR',
        [
          m('G70', 'G70', '세단', ['가솔린'], '중형', firstYear: 2017),
          m('G70 슈팅 브레이크', 'G70 Shooting Brake', '왜건', ['가솔린'], '중형',
              id: 'model-genesis-g70-shooting-brake-kr', firstYear: 2022),
          m('G80', 'G80', '세단', ['가솔린'], '대형', firstYear: 2016),
          m('Electrified G80', 'Electrified G80', '전기 세단', ['전기차'], '대형',
              id: 'model-genesis-electrified-g80-kr', firstYear: 2021),
          m('G90', 'G90', '세단', ['가솔린'], '대형', firstYear: 2019),
          m('GV60', 'GV60', '전기 SUV', ['전기차'], 'SUV', firstYear: 2021),
          m('GV70', 'GV70', 'SUV', ['가솔린'], 'SUV', firstYear: 2021),
          m('Electrified GV70', 'Electrified GV70', '전기 SUV', ['전기차'], 'SUV',
              id: 'model-genesis-electrified-gv70-kr', firstYear: 2022),
          m('GV80', 'GV80', 'SUV', ['가솔린', '디젤'], '대형 SUV', firstYear: 2020),
          m('GV80 Coupe', 'GV80 Coupe', 'SUV 쿠페', ['가솔린'], '대형 SUV',
              id: 'model-genesis-gv80-coupe-kr', firstYear: 2024),
        ],
        popular: true,
        sortOrder: 30),
    make(
        'm-chevrolet',
        '쉐보레',
        'Chevrolet',
        'US',
        [
          m('스파크', 'Spark', '경차', ['가솔린'], '경형', lastYear: 2022),
          m('말리부', 'Malibu', '세단', ['가솔린'], '중형', lastYear: 2022),
          m('트랙스', 'Trax', 'SUV', ['가솔린'], '소형 SUV'),
          m('트레일블레이저', 'Trailblazer', 'SUV', ['가솔린'], '소형 SUV',
              firstYear: 2020),
          m('트래버스', 'Traverse', 'SUV', ['가솔린'], '대형 SUV', firstYear: 2019),
          m('타호', 'Tahoe', 'SUV', ['가솔린'], '대형 SUV', firstYear: 2022),
          m('이쿼녹스', 'Equinox', 'SUV', ['가솔린'], 'SUV',
              id: 'model-chevrolet-equinox-kr', firstYear: 2026, sortOrder: 65),
          m('콜로라도', 'Colorado', '픽업', ['가솔린'], '픽업', firstYear: 2019),
          m('볼트 EV', 'Bolt EV', '전기차', ['전기차'], '준중형',
              firstYear: 2017, lastYear: 2023),
        ],
        sortOrder: 40),
    make(
        'm-renault',
        '르노코리아',
        'Renault Korea',
        'KR',
        [
          m('SM6', 'SM6', '세단', ['가솔린', 'LPG'], '중형',
              firstYear: 2016, lastYear: 2024),
          m('QM6', 'QM6', 'SUV', ['가솔린', 'LPG'], 'SUV',
              firstYear: 2016, lastYear: 2024),
          m('XM3', 'XM3', 'SUV', ['가솔린', '하이브리드'], '소형 SUV',
              firstYear: 2020, lastYear: 2023),
          m('Arkana', 'Arkana', 'SUV 쿠페', ['가솔린', '하이브리드'], '소형 SUV',
              id: 'model-renault-arkana-kr', firstYear: 2024),
          m('그랑 콜레오스', 'Grand Koleos', 'SUV', ['가솔린', '하이브리드'], 'SUV',
              firstYear: 2025),
          m('Filante', 'Filante', 'SUV 쿠페', ['하이브리드'], '대형 SUV',
              id: 'model-renault-filante-kr', firstYear: 2026),
          m('세닉 E-Tech', 'Scenic E-Tech', '전기 SUV', ['전기차'], 'SUV',
              id: 'model-renault-scenic-e-tech-kr',
              firstYear: 2025,
              sortOrder: 70),
        ],
        sortOrder: 50),
    make(
        'm-kgm',
        'KG모빌리티',
        'KG Mobility',
        'KR',
        [
          m('티볼리', 'Tivoli', 'SUV', ['가솔린'], '소형 SUV'),
          m('코란도', 'Korando', 'SUV', ['가솔린', '디젤'], 'SUV',
              firstYear: 2019, lastYear: 2024),
          m('액티언', 'Actyon', 'SUV 쿠페', ['가솔린'], 'SUV',
              id: 'model-kgm-actyon-kr', firstYear: 2024),
          m('액티언 하이브리드', 'Actyon Hybrid', 'SUV 쿠페', ['하이브리드'], 'SUV',
              id: 'model-kgm-actyon-hybrid-kr', firstYear: 2025),
          m('토레스', 'Torres', 'SUV', ['가솔린'], 'SUV', firstYear: 2022),
          m('토레스 하이브리드', 'Torres Hybrid', 'SUV', ['하이브리드'], 'SUV',
              id: 'model-kgm-torres-hybrid-kr', firstYear: 2025),
          m('토레스 EVX', 'Torres EVX', '전기 SUV', ['전기차'], 'SUV',
              id: 'model-kgm-torres-evx-kr', firstYear: 2023),
          m('토레스 밴', 'Torres Van', '밴', ['가솔린'], '상용',
              id: 'model-kgm-torres-van-kr', firstYear: 2026, sortOrder: 66),
          m('토레스 EVX 밴', 'Torres EVX Van', '전기 밴', ['전기차'], '상용',
              id: 'model-kgm-torres-evx-van-kr',
              firstYear: 2026,
              sortOrder: 67),
          m('렉스턴', 'Rexton', 'SUV', ['디젤'], '대형 SUV', firstYear: 2017),
          m('렉스턴 써밋', 'Rexton Summit', 'SUV', ['디젤'], '대형 SUV',
              id: 'model-kgm-rexton-summit-kr', firstYear: 2026, sortOrder: 75),
          m('렉스턴 스포츠', 'Rexton Sports', '픽업', ['디젤'], '픽업',
              firstYear: 2018, lastYear: 2025),
          m('무쏘', 'Musso', '픽업', ['디젤'], '픽업',
              id: 'model-kgm-musso-kr', firstYear: 2025),
          m('무쏘 EV', 'Musso EV', '전기 픽업', ['전기차'], '픽업',
              id: 'model-kgm-musso-ev-kr', firstYear: 2025),
        ],
        sortOrder: 60),
    make(
        'm-bmw',
        'BMW',
        'BMW',
        'DE',
        [
          m('1시리즈', '1 Series', '해치백', ['가솔린'], '준중형'),
          m('2시리즈 쿠페', '2 Series Coupe', '쿠페', ['가솔린'], '준중형'),
          m('2시리즈 그란 쿠페', '2 Series Gran Coupe', '그란 쿠페', ['가솔린'], '준중형',
              id: 'model-bmw-2-series-gran-coupe-kr',
              firstYear: 2026,
              sortOrder: 25),
          m('3시리즈', '3 Series', '세단', ['가솔린', '디젤', '플러그인 하이브리드'], '중형'),
          m('4시리즈', '4 Series', '쿠페', ['가솔린', '디젤'], '중형'),
          m('5시리즈', '5 Series', '세단', ['가솔린', '디젤', '플러그인 하이브리드'], '대형'),
          m('7시리즈', '7 Series', '세단', ['가솔린', '플러그인 하이브리드'], '대형'),
          m('8시리즈', '8 Series', '쿠페/그란 쿠페', ['가솔린'], '스포츠',
              id: 'model-bmw-8-series-kr', firstYear: 2026, sortOrder: 65),
          m('X1', 'X1', 'SUV', ['가솔린'], '소형 SUV'),
          m('X2', 'X2', 'SUV', ['가솔린'], '소형 SUV',
              id: 'model-bmw-x2-kr', firstYear: 2026),
          m('X3', 'X3', 'SUV', ['가솔린', '디젤', '플러그인 하이브리드'], 'SUV'),
          m('X4', 'X4', 'SUV', ['가솔린'], 'SUV',
              id: 'model-bmw-x4-kr', firstYear: 2026),
          m('X5', 'X5', 'SUV', ['가솔린', '디젤', '플러그인 하이브리드'], '대형 SUV'),
          m('X5 M', 'X5 M', '고성능 SUV', ['가솔린'], '스포츠',
              id: 'model-bmw-x5-m-kr', firstYear: 2026, sortOrder: 115),
          m('X6', 'X6', 'SUV', ['가솔린'], '대형 SUV',
              id: 'model-bmw-x6-kr', firstYear: 2026),
          m('X6 M', 'X6 M', '고성능 SUV', ['가솔린'], '스포츠',
              id: 'model-bmw-x6-m-kr', firstYear: 2026, sortOrder: 125),
          m('X7', 'X7', 'SUV', ['가솔린', '디젤'], '대형 SUV', firstYear: 2019),
          m('XM', 'XM', 'SUV', ['플러그인 하이브리드'], '대형 SUV',
              id: 'model-bmw-xm-kr', firstYear: 2026),
          m('Z4', 'Z4', '컨버터블', ['가솔린'], '스포츠',
              id: 'model-bmw-z4-kr', firstYear: 2026),
          m('M2', 'M2', '고성능 쿠페', ['가솔린'], '스포츠',
              id: 'model-bmw-m2-kr', firstYear: 2026, sortOrder: 151),
          m('M3', 'M3', '고성능 세단/투어링', ['가솔린'], '스포츠',
              id: 'model-bmw-m3-kr', firstYear: 2026, sortOrder: 152),
          m('M4', 'M4', '고성능 쿠페/컨버터블', ['가솔린'], '스포츠',
              id: 'model-bmw-m4-kr', firstYear: 2026, sortOrder: 153),
          m('M5', 'M5', '고성능 세단/투어링', ['플러그인 하이브리드'], '스포츠',
              id: 'model-bmw-m5-kr', firstYear: 2026, sortOrder: 154),
          m('M8', 'M8', '고성능 쿠페/그란 쿠페', ['가솔린'], '스포츠',
              id: 'model-bmw-m8-kr', firstYear: 2026, sortOrder: 155),
          m('i4', 'i4', '전기 세단', ['전기차'], '중형', firstYear: 2022),
          m('i5', 'i5', '전기 세단', ['전기차'], '대형', firstYear: 2024),
          m('i7', 'i7', '전기 세단', ['전기차'], '대형',
              id: 'model-bmw-i7-kr', firstYear: 2026),
          m('iX', 'iX', '전기 SUV', ['전기차'], '대형 SUV', firstYear: 2022),
          m('iX3', 'iX3', '전기 SUV', ['전기차'], 'SUV', firstYear: 2022),
          m('iX1', 'iX1', '전기 SUV', ['전기차'], '소형 SUV',
              id: 'model-bmw-ix1-kr', firstYear: 2026),
          m('iX2', 'iX2', '전기 SUV', ['전기차'], '소형 SUV',
              id: 'model-bmw-ix2-kr', firstYear: 2026),
          m('i3', 'i3', '전기 세단', ['전기차'], '중형',
              id: 'model-bmw-i3-kr', firstYear: 2026),
        ],
        popular: true,
        sortOrder: 70),
    make(
        'm-benz',
        '메르세데스-벤츠',
        'Mercedes-Benz',
        'DE',
        [
          m('A-Class', 'A-Class', '해치백', ['가솔린'], '준중형'),
          m('C-Class', 'C-Class', '세단', ['가솔린', '디젤', '플러그인 하이브리드'], '중형'),
          m('E-Class', 'E-Class', '세단', ['가솔린', '디젤', '플러그인 하이브리드'], '대형'),
          m('S-Class', 'S-Class', '세단', ['가솔린', '플러그인 하이브리드'], '대형'),
          m('GLA', 'GLA', 'SUV', ['가솔린'], '소형 SUV'),
          m('GLC', 'GLC', 'SUV', ['가솔린', '디젤', '플러그인 하이브리드'], 'SUV'),
          m('GLE', 'GLE', 'SUV', ['가솔린', '디젤', '플러그인 하이브리드'], '대형 SUV'),
          m('GLS', 'GLS', 'SUV', ['가솔린', '디젤'], '대형 SUV'),
          m('EQA', 'EQA', '전기 SUV', ['전기차'], '소형 SUV', firstYear: 2021),
          m('EQB', 'EQB', '전기 SUV', ['전기차'], 'SUV', firstYear: 2022),
          m('EQE', 'EQE', '전기 세단', ['전기차'], '대형', firstYear: 2022),
          m('EQS', 'EQS', '전기 세단', ['전기차'], '대형', firstYear: 2021),
          m('S-Class Long', 'S-Class Long', '세단', ['가솔린', '플러그인 하이브리드'], '대형',
              id: 'model-benz-s-class-long-kr', firstYear: 2026, sortOrder: 45),
          m('Mercedes-Maybach S-Class', 'Mercedes-Maybach S-Class', '세단',
              ['가솔린'], '대형',
              id: 'model-benz-maybach-s-class-kr',
              firstYear: 2026,
              sortOrder: 46),
          m('EQE SUV', 'EQE SUV', '전기 SUV', ['전기차'], '대형 SUV',
              id: 'model-benz-eqe-suv-kr', firstYear: 2026, sortOrder: 105),
          m('Mercedes-Maybach EQS SUV', 'Mercedes-Maybach EQS SUV', '전기 SUV',
              ['전기차'], '대형 SUV',
              id: 'model-benz-maybach-eqs-suv-kr',
              firstYear: 2026,
              sortOrder: 106),
          m('GLB', 'GLB', 'SUV', ['가솔린'], 'SUV',
              id: 'model-benz-glb-kr', firstYear: 2026, sortOrder: 115),
          m('GLC Coupé', 'GLC Coupé', 'SUV', ['가솔린'], 'SUV',
              id: 'model-benz-glc-coupe-kr', firstYear: 2026, sortOrder: 116),
          m('GLE Coupé', 'GLE Coupé', 'SUV', ['가솔린', '디젤'], '대형 SUV',
              id: 'model-benz-gle-coupe-kr', firstYear: 2026, sortOrder: 117),
          m('Mercedes-Maybach GLS', 'Mercedes-Maybach GLS', 'SUV', ['가솔린'],
              '대형 SUV',
              id: 'model-benz-maybach-gls-kr', firstYear: 2026, sortOrder: 118),
          m('G-Class', 'G-Class', 'SUV', ['가솔린', '디젤', '전기차'], '대형 SUV',
              id: 'model-benz-g-class-kr', firstYear: 2026, sortOrder: 119),
          m('CLA Coupé', 'CLA Coupé', '쿠페', ['가솔린'], '준중형',
              id: 'model-benz-cla-coupe-kr', firstYear: 2026, sortOrder: 130),
          m('CLE Coupé', 'CLE Coupé', '쿠페', ['가솔린'], '중형',
              id: 'model-benz-cle-coupe-kr', firstYear: 2026, sortOrder: 140),
          m('Mercedes-AMG GT Coupé', 'Mercedes-AMG GT Coupé', '스포츠카',
              ['가솔린', '플러그인 하이브리드'], '스포츠',
              id: 'model-benz-amg-gt-coupe-kr',
              firstYear: 2026,
              sortOrder: 150),
          m('Mercedes-AMG GT 4-Door Coupé', 'Mercedes-AMG GT 4-Door Coupé',
              '쿠페', ['가솔린'], '대형',
              id: 'model-benz-amg-gt-4door-coupe-kr',
              firstYear: 2026,
              sortOrder: 160),
          m('CLE Cabriolet', 'CLE Cabriolet', '컨버터블', ['가솔린'], '중형',
              id: 'model-benz-cle-cabriolet-kr',
              firstYear: 2026,
              sortOrder: 170),
          m('SL Roadster', 'SL Roadster', '컨버터블', ['가솔린'], '스포츠',
              id: 'model-benz-sl-roadster-kr', firstYear: 2026, sortOrder: 180),
          m('Mercedes-Maybach SL Monogram Series',
              'Mercedes-Maybach SL Monogram Series', '컨버터블', ['가솔린'], '스포츠',
              id: 'model-benz-maybach-sl-monogram-kr',
              firstYear: 2026,
              sortOrder: 190),
        ],
        sortOrder: 80),
    make(
        'm-audi',
        '아우디',
        'Audi',
        'DE',
        [
          m('A3', 'A3', '세단', ['가솔린'], '준중형'),
          m('A4', 'A4', '세단', ['가솔린', '디젤'], '중형', lastYear: 2024),
          m('A5', 'A5', '쿠페', ['가솔린', '디젤'], '중형'),
          m('A6', 'A6', '세단', ['가솔린', '디젤', '플러그인 하이브리드'], '대형'),
          m('A7', 'A7', '해치백', ['가솔린', '디젤'], '대형', lastYear: 2025),
          m('A8', 'A8', '세단', ['가솔린'], '대형'),
          m('Q3', 'Q3', 'SUV', ['가솔린'], '소형 SUV'),
          m('Q5', 'Q5', 'SUV', ['가솔린', '디젤', '플러그인 하이브리드'], 'SUV'),
          m('Q7', 'Q7', 'SUV', ['가솔린', '디젤'], '대형 SUV'),
          m('Q8', 'Q8', 'SUV', ['가솔린', '디젤'], '대형 SUV', firstYear: 2018),
          m('e-tron', 'e-tron', '전기 SUV', ['전기차'], '대형 SUV',
              firstYear: 2018, lastYear: 2025),
          m('Q4 e-tron', 'Q4 e-tron', '전기 SUV', ['전기차'], 'SUV',
              firstYear: 2021),
          m('e-tron GT', 'e-tron GT', '스포츠카', ['전기차'], '스포츠',
              id: 'model-audi-e-tron-gt-kr', firstYear: 2026, sortOrder: 115),
          m('A6 e-tron', 'A6 e-tron', '전기 세단', ['전기차'], '대형',
              id: 'model-audi-a6-e-tron-kr', firstYear: 2026, sortOrder: 116),
          m('Q6 e-tron', 'Q6 e-tron', '전기 SUV', ['전기차'], 'SUV',
              id: 'model-audi-q6-e-tron-kr', firstYear: 2026, sortOrder: 117),
        ],
        sortOrder: 90),
    make(
        'm-volkswagen',
        '폭스바겐',
        'Volkswagen',
        'DE',
        [
          m('골프', 'Golf', '해치백', ['디젤'], '준중형'),
          m('Golf GTI', 'Golf GTI', '고성능 해치백', ['가솔린'], '스포츠',
              id: 'model-volkswagen-golf-gti-kr',
              firstYear: 2026,
              sortOrder: 11),
          m('제타', 'Jetta', '세단', ['가솔린'], '준중형', lastYear: 2025),
          m('파사트', 'Passat', '세단', ['가솔린', '디젤'], '중형', lastYear: 2025),
          m('티구안', 'Tiguan', 'SUV', ['가솔린', '디젤'], 'SUV', lastYear: 2025),
          m('투아렉', 'Touareg', 'SUV', ['디젤'], '대형 SUV'),
          m('Atlas', 'Atlas', 'SUV', ['가솔린'], '대형 SUV',
              id: 'model-volkswagen-atlas-kr', firstYear: 2026, sortOrder: 55),
          m('ID.4', 'ID.4', '전기 SUV', ['전기차'], 'SUV'),
          m('ID.5', 'ID.5', '전기 SUV', ['전기차'], 'SUV',
              id: 'model-volkswagen-id5-kr', firstYear: 2026, sortOrder: 65),
          m('아테온', 'Arteon', '세단', ['디젤'], '대형', lastYear: 2025),
        ],
        sortOrder: 100),
    make(
        'm-toyota',
        '토요타',
        'Toyota',
        'JP',
        [
          m('프리우스', 'Prius', '해치백', ['하이브리드', '플러그인 하이브리드'], '준중형'),
          m('캠리', 'Camry', '세단', ['하이브리드'], '중형'),
          m('라브4', 'RAV4', 'SUV', ['하이브리드', '플러그인 하이브리드'], 'SUV'),
          m('하이랜더', 'Highlander', 'SUV', ['하이브리드'], '대형 SUV'),
          m('시에나', 'Sienna', 'MPV', ['하이브리드'], 'MPV'),
          m('크라운', 'Crown', '세단', ['하이브리드'], '대형'),
          m('GR86', 'GR86', '쿠페', ['가솔린'], '준중형'),
          m('알파드', 'Alphard', 'MPV', ['하이브리드'], 'MPV',
              id: 'model-toyota-alphard-kr', firstYear: 2026),
        ],
        sortOrder: 110),
    make(
        'm-lexus',
        '렉서스',
        'Lexus',
        'JP',
        [
          m('ES', 'ES', '세단', ['하이브리드'], '대형'),
          m('LS', 'LS', '세단', ['가솔린', '하이브리드'], '대형'),
          m('NX', 'NX', 'SUV', ['하이브리드', '플러그인 하이브리드'], 'SUV'),
          m('RX', 'RX', 'SUV', ['하이브리드', '플러그인 하이브리드'], '대형 SUV'),
          m('UX', 'UX', 'SUV', ['하이브리드'], '소형 SUV'),
          m('RZ', 'RZ', '전기 SUV', ['전기차'], 'SUV'),
          m('LM', 'LM', 'MPV', ['하이브리드'], 'MPV',
              id: 'model-lexus-lm-kr', firstYear: 2025),
          m('LX', 'LX 700h', 'SUV', ['하이브리드'], '대형 SUV',
              id: 'model-lexus-lx-kr', firstYear: 2026, sortOrder: 75),
          m('LC', 'LC 500', '스포츠 쿠페', ['가솔린'], '스포츠',
              id: 'model-lexus-lc-kr', firstYear: 2026, sortOrder: 80),
          m('RC', 'RC 300 F SPORT', '스포츠 쿠페', ['가솔린'], '스포츠',
              id: 'model-lexus-rc-kr', firstYear: 2026, sortOrder: 90),
        ],
        sortOrder: 120),
    make(
        'm-honda',
        '혼다',
        'Honda',
        'JP',
        [
          m('시빅', 'Civic', '세단', ['가솔린', '하이브리드'], '준중형'),
          m('어코드', 'Accord', '세단', ['하이브리드'], '중형'),
          m('CR-V', 'CR-V', 'SUV', ['가솔린', '하이브리드'], 'SUV'),
          m('HR-V', 'HR-V', 'SUV', ['가솔린'], '소형 SUV'),
          m('파일럿', 'Pilot', 'SUV', ['가솔린'], '대형 SUV'),
          m('오딧세이', 'Odyssey', 'MPV', ['가솔린'], 'MPV'),
        ],
        sortOrder: 130),
    make(
        'm-nissan',
        '닛산',
        'Nissan',
        'JP',
        [
          m('알티마', 'Altima', '세단', ['가솔린'], '중형', lastYear: 2020),
          m('맥시마', 'Maxima', '세단', ['가솔린'], '대형', lastYear: 2020),
          m('로그', 'Rogue', 'SUV', ['가솔린'], 'SUV', lastYear: 2020),
          m('리프', 'Leaf', '전기차', ['전기차'], '준중형',
              firstYear: 2019, lastYear: 2020),
          m('아리야', 'Ariya', '전기 SUV', ['전기차'], 'SUV', firstYear: 2026),
        ],
        sortOrder: 140),
    make(
        'm-tesla',
        '테슬라',
        'Tesla',
        'US',
        [
          m('Model 3', 'Model 3', '전기 세단', ['전기차'], '중형', popular: true),
          m('Model Y', 'Model Y', '전기 SUV', ['전기차'], 'SUV', popular: true),
          m('Model S', 'Model S', '전기 세단', ['전기차'], '대형'),
          m('Model X', 'Model X', '전기 SUV', ['전기차'], '대형 SUV'),
          m('Cybertruck', 'Cybertruck', '픽업', ['전기차'], '픽업',
              id: 'model-tesla-cybertruck-kr', firstYear: 2026, sortOrder: 50),
        ],
        popular: true,
        sortOrder: 150),
    make(
        'm-volvo',
        '볼보',
        'Volvo',
        'SE',
        [
          m('S60', 'S60', '세단', ['가솔린', '플러그인 하이브리드'], '중형', lastYear: 2025),
          m('S90', 'S90', '세단', ['가솔린', '플러그인 하이브리드'], '대형', firstYear: 2016),
          m('XC40', 'XC40', 'SUV', ['가솔린', '전기차'], '소형 SUV',
              firstYear: 2018,
              fuelTypeYearRanges: {
                '전기차': FuelTypeYearRange(firstYear: 2021, lastYear: 2024),
              }),
          m('XC60', 'XC60', 'SUV', ['가솔린', '플러그인 하이브리드'], 'SUV'),
          m('XC90', 'XC90', 'SUV', ['가솔린', '플러그인 하이브리드'], '대형 SUV'),
          m('C40', 'C40', '전기 SUV', ['전기차'], 'SUV',
              firstYear: 2022, lastYear: 2024),
          m('EX40', 'EX40', '전기 SUV', ['전기차'], 'SUV',
              id: 'model-volvo-ex40-kr', firstYear: 2025, sortOrder: 62),
          m('EC40', 'EC40', '전기 SUV', ['전기차'], 'SUV',
              id: 'model-volvo-ec40-kr', firstYear: 2025, sortOrder: 64),
          m('EX30', 'EX30', '전기 SUV', ['전기차'], '소형 SUV', firstYear: 2025),
          m('EX90', 'EX90', '전기 SUV', ['전기차'], '대형 SUV', firstYear: 2026),
          m('EX30 Cross Country', 'EX30 Cross Country', '전기 SUV', ['전기차'],
              '소형 SUV',
              id: 'model-volvo-ex30-cross-country-kr',
              firstYear: 2025,
              sortOrder: 85),
          m('ES90', 'ES90', '전기 세단', ['전기차'], '대형',
              id: 'model-volvo-es90-kr', firstYear: 2026, sortOrder: 86),
          m('V60 Cross Country', 'V60 Cross Country', '크로스컨트리', ['가솔린'], '중형',
              id: 'model-volvo-v60-cross-country-kr',
              firstYear: 2019,
              sortOrder: 90),
        ],
        sortOrder: 160),
    make(
        'm-porsche',
        '포르쉐',
        'Porsche',
        'DE',
        [
          m('911', '911', '스포츠카', ['가솔린'], '스포츠'),
          m('박스터', 'Boxster', '스포츠카', ['가솔린'], '스포츠'),
          m('카이맨', 'Cayman', '스포츠카', ['가솔린'], '스포츠'),
          m('파나메라', 'Panamera', '세단', ['가솔린', '플러그인 하이브리드'], '대형'),
          m(
            '마칸',
            'Macan',
            'SUV',
            ['가솔린', '전기차'],
            'SUV',
            fuelTypeYearRanges: {
              '가솔린': FuelTypeYearRange(firstYear: 2015, lastYear: 2025),
              '전기차': FuelTypeYearRange(firstYear: 2026, lastYear: 2026),
            },
          ),
          m(
            '카이엔',
            'Cayenne',
            'SUV',
            ['가솔린', '플러그인 하이브리드', '전기차'],
            '대형 SUV',
            fuelTypeYearRanges: {
              '전기차': FuelTypeYearRange(firstYear: 2026, lastYear: 2026),
            },
          ),
          m('타이칸', 'Taycan', '전기 세단', ['전기차'], '대형'),
        ],
        sortOrder: 170),
    make(
        'm-mini',
        'MINI',
        'MINI',
        'GB',
        [
          m('해치', 'Hatch', '해치백', ['가솔린', '전기차'], '소형'),
          m('컨트리맨', 'Countryman', 'SUV', ['가솔린', '플러그인 하이브리드', '전기차'],
              '소형 SUV'),
          m('클럽맨', 'Clubman', '왜건', ['가솔린'], '준중형'),
          m('쿠퍼 SE', 'Cooper SE', '전기차', ['전기차'], '소형'),
          m('컨버터블', 'Convertible', '컨버터블', ['가솔린'], '소형'),
          m('에이스맨', 'Aceman', '전기 SUV', ['전기차'], '소형 SUV',
              id: 'model-mini-aceman-kr', firstYear: 2026),
          m('MINI Cooper 5-Door', 'MINI Cooper 5-Door', '해치백', ['가솔린'], '소형',
              id: 'model-mini-cooper-5-door-kr',
              firstYear: 2026,
              sortOrder: 70),
          m('All-Electric MINI Cooper', 'All-Electric MINI Cooper', '전기차',
              ['전기차'], '소형',
              id: 'model-mini-electric-cooper-kr',
              firstYear: 2026,
              sortOrder: 80),
          m('All-Electric MINI Countryman', 'All-Electric MINI Countryman',
              '전기 SUV', ['전기차'], '소형 SUV',
              id: 'model-mini-electric-countryman-kr',
              firstYear: 2026,
              sortOrder: 90),
          m('John Cooper Works', 'John Cooper Works', '스포츠카', ['가솔린', '전기차'],
              '스포츠',
              id: 'model-mini-jcw-kr', firstYear: 2026, sortOrder: 100),
        ],
        sortOrder: 180),
    make(
        'm-peugeot',
        '푸조',
        'Peugeot',
        'FR',
        [
          m('208', '208', '해치백', ['가솔린', '전기차'], '소형', lastYear: 2025),
          m(
            '308',
            '308',
            '해치백',
            ['하이브리드'],
            '준중형',
            firstYear: 2026,
          ),
          m('2008', '2008', 'SUV', ['가솔린', '전기차'], '소형 SUV', lastYear: 2025),
          m(
            '3008',
            '3008',
            'SUV',
            ['하이브리드'],
            'SUV',
            firstYear: 2026,
          ),
          m(
            '5008',
            '5008',
            'SUV',
            ['하이브리드'],
            '대형 SUV',
            firstYear: 2026,
          ),
          m(
            '408',
            '408',
            '패스트백',
            ['하이브리드'],
            '중형',
            id: 'model-peugeot-408-kr',
            firstYear: 2026,
          ),
        ],
        sortOrder: 190),
    make(
        'm-jeep',
        '지프',
        'Jeep',
        'US',
        [
          m('레니게이드', 'Renegade', 'SUV', ['가솔린'], '소형 SUV'),
          m('컴패스', 'Compass', 'SUV', ['가솔린'], 'SUV'),
          m('체로키', 'Cherokee', 'SUV', ['가솔린'], 'SUV'),
          m('랭글러', 'Wrangler', 'SUV', ['가솔린', '플러그인 하이브리드'], 'SUV'),
          m('그랜드 체로키', 'Grand Cherokee', 'SUV', ['가솔린', '플러그인 하이브리드'],
              '대형 SUV'),
          m('글래디에이터', 'Gladiator', '픽업', ['가솔린'], '픽업',
              id: 'model-jeep-gladiator-kr', firstYear: 2025),
          m('그랜드 체로키 L', 'Grand Cherokee L', 'SUV', ['가솔린'], '대형 SUV',
              id: 'model-jeep-grand-cherokee-l-kr', firstYear: 2024),
          m('어벤저', 'Avenger', '전기 SUV', ['전기차'], '소형 SUV',
              id: 'model-jeep-avenger-kr', firstYear: 2024, sortOrder: 80),
        ],
        sortOrder: 200),
    make(
        'm-landrover',
        '랜드로버',
        'Land Rover',
        'GB',
        [
          m('디펜더', 'Defender', 'SUV', ['가솔린', '디젤', '플러그인 하이브리드'], '대형 SUV',
              fuelTypeYearRanges: {
                '플러그인 하이브리드':
                    FuelTypeYearRange(firstYear: 2015, lastYear: 2025),
              }),
          m('디스커버리', 'Discovery', 'SUV', ['가솔린', '디젤'], '대형 SUV'),
          m('레인지로버', 'Range Rover', 'SUV', ['가솔린', '디젤', '플러그인 하이브리드'],
              '대형 SUV',
              fuelTypeYearRanges: {
                '디젤': FuelTypeYearRange(firstYear: 2015, lastYear: 2025),
              }),
          m('레인지로버 스포츠', 'Range Rover Sport', 'SUV',
              ['가솔린', '디젤', '플러그인 하이브리드'], '대형 SUV',
              fuelTypeYearRanges: {
                '디젤': FuelTypeYearRange(firstYear: 2015, lastYear: 2025),
              }),
          m('레인지로버 이보크', 'Range Rover Evoque', 'SUV', ['가솔린', '디젤'], 'SUV',
              fuelTypeYearRanges: {
                '디젤': FuelTypeYearRange(firstYear: 2015, lastYear: 2025),
              }),
          m('디스커버리 스포츠', 'Discovery Sport', 'SUV', ['가솔린'], 'SUV',
              id: 'model-landrover-discovery-sport-kr', firstYear: 2025),
          m('레인지로버 벨라', 'Range Rover Velar', 'SUV', ['가솔린', '플러그인 하이브리드'],
              'SUV',
              id: 'model-landrover-range-rover-velar-kr',
              firstYear: 2025,
              fuelTypeYearRanges: {
                '플러그인 하이브리드':
                    FuelTypeYearRange(firstYear: 2026, lastYear: 2026),
              }),
        ],
        sortOrder: 210),
    make(
        'm-polestar',
        '폴스타',
        'Polestar',
        'SE',
        [
          m('Polestar 2', 'Polestar 2', '전기 세단', ['전기차'], '중형',
              firstYear: 2026),
          m('Polestar 3', 'Polestar 3', '전기 SUV', ['전기차'], '대형 SUV',
              firstYear: 2026),
          m('Polestar 4', 'Polestar 4', '전기 SUV', ['전기차'], 'SUV',
              firstYear: 2026),
          m('Polestar 5', 'Polestar 5', '전기 세단', ['전기차'], '대형',
              id: 'model-polestar-5-kr', firstYear: 2026, sortOrder: 40),
        ],
        sortOrder: 220),
  ];
}

ModelSeed m(
  String nameKo,
  String nameEn,
  String bodyType,
  List<String> fuelTypes,
  String vehicleClass, {
  String? id,
  int? sortOrder,
  bool popular = false,
  int firstYear = 2015,
  int lastYear = 2026,
  Map<String, FuelTypeYearRange> fuelTypeYearRanges = const {},
}) {
  return ModelSeed(
    id: id,
    nameKo: nameKo,
    nameEn: nameEn,
    bodyType: bodyType,
    fuelTypes: fuelTypes,
    vehicleClass: vehicleClass,
    sortOrder: sortOrder,
    isPopular: popular,
    firstYear: firstYear,
    lastYear: lastYear,
    fuelTypeYearRanges: fuelTypeYearRanges,
  );
}

class ModelSeed {
  const ModelSeed({
    this.id,
    required this.nameKo,
    required this.nameEn,
    required this.bodyType,
    required this.fuelTypes,
    required this.vehicleClass,
    this.sortOrder,
    this.isPopular = false,
    this.firstYear = 2015,
    this.lastYear = 2026,
    this.fuelTypeYearRanges = const {},
  });

  final String? id;
  final String nameKo;
  final String nameEn;
  final String bodyType;
  final List<String> fuelTypes;
  final String vehicleClass;
  final int? sortOrder;
  final bool isPopular;
  final int firstYear;
  final int lastYear;
  final Map<String, FuelTypeYearRange> fuelTypeYearRanges;

  List<String> fuelTypesForYear(int year) {
    return fuelTypes.where((fuelType) {
      final range = fuelTypeYearRanges[fuelType];
      return range == null || range.includes(year);
    }).toList(growable: false);
  }
}

class FuelTypeYearRange {
  const FuelTypeYearRange({
    required this.firstYear,
    required this.lastYear,
  });

  final int firstYear;
  final int lastYear;

  bool includes(int year) => year >= firstYear && year <= lastYear;
}

class OfficialPowertrain {
  const OfficialPowertrain({
    required this.id,
    required this.trimName,
    required this.engineName,
    this.displacementCc,
    this.batteryKwh,
    required this.drivetrain,
    required this.transmission,
    required this.officialEfficiency,
    required this.efficiencyUnit,
    this.vehicleClass,
    this.isVerified = false,
    this.sourceStatus,
    this.sourceName,
    this.sourceUrl,
    this.sourceFileName,
    this.lastVerifiedAt,
    this.confidenceScore,
    this.isSelectable,
    this.sortOrder,
  });

  final String id;
  final String trimName;
  final String engineName;
  final int? displacementCc;
  final double? batteryKwh;
  final String drivetrain;
  final String transmission;
  final double? officialEfficiency;
  final String efficiencyUnit;
  final String? vehicleClass;
  final bool isVerified;
  final String? sourceStatus;
  final String? sourceName;
  final String? sourceUrl;
  final String? sourceFileName;
  final String? lastVerifiedAt;
  final double? confidenceScore;
  final bool? isSelectable;
  final int? sortOrder;
}
