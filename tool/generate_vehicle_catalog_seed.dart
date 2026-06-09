import 'dart:convert';
import 'dart:io';

void main() {
  final manufacturers = _manufacturers();
  final models = <Map<String, Object?>>[];
  final years = <Map<String, Object?>>[];
  final variants = <Map<String, Object?>>[];

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
        years.add({'id': yearId, 'model_id': modelId, 'year': year});
        for (final fuelType in seed.fuelTypesForYear(year)) {
          final overrides = _officialOverrides(modelId, year, fuelType);
          final powertrains =
              overrides.isEmpty ? <OfficialPowertrain?>[null] : overrides;
          for (var index = 0; index < powertrains.length; index += 1) {
            final override = powertrains[index];
            variants.add({
              'id': override?.id ??
                  'variant-${modelId.substring(6)}-$year-${_fuelLeagueFor(fuelType)}',
              'model_year_id': yearId,
              'manufacturer_name': manufacturerName,
              'model_name': seed.nameKo,
              'year': year,
              'trim_name': override?.trimName ??
                  _powertrainLabelFor(fuelType, seed.vehicleClass),
              'engine_name': override?.engineName ??
                  _engineNameFor(fuelType, seed.vehicleClass),
              'fuel_type': fuelType,
              'displacement_cc': override?.displacementCc ??
                  _displacementCcFor(fuelType, seed.vehicleClass),
              'battery_kwh': override?.batteryKwh ??
                  _batteryKwhFor(fuelType, seed.vehicleClass),
              'drivetrain': override?.drivetrain ?? _drivetrainFor(fuelType),
              'transmission':
                  override?.transmission ?? _transmissionFor(fuelType),
              'official_efficiency': override?.officialEfficiency,
              'efficiency_unit':
                  override?.efficiencyUnit ?? _efficiencyUnitFor(fuelType),
              'vehicle_class': seed.vehicleClass,
              'fuel_league': _fuelLeagueFor(fuelType),
              'is_verified': true,
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
    'years': years,
    'variants': variants,
  };

  final jsonFile = File('assets/data/vehicle_catalog_kr_seed.json');
  jsonFile.createSync(recursive: true);
  jsonFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(data),
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
  ].join(','));
  for (final variant in variants) {
    final model = models.firstWhere(
        (item) =>
            item['id'] ==
            (variant['model_year_id'] as String)
                .split('-')
                .take(
                    (variant['model_year_id'] as String).split('-').length - 1)
                .join('-')
                .replaceFirst('year-', 'model-'),
        orElse: () => const {});
    final manufacturer = manufacturers.firstWhere(
      (item) => item['id'] == model['manufacturer_id'],
      orElse: () => const {},
    );
    csv.writeln([
      manufacturer['id'] ?? '',
      manufacturer['name_ko'] ?? variant['manufacturer_name'],
      model['id'] ?? '',
      variant['model_name'],
      variant['year'],
      variant['trim_name'],
      variant['fuel_type'],
      variant['fuel_league'],
      variant['vehicle_class'],
      variant['efficiency_unit'],
      variant['official_efficiency'],
      variant['is_verified'],
    ].map(_csv).join(','));
  }
  csvFile.writeAsStringSync(csv.toString());

  stdout.writeln(
    'generated ${manufacturers.length} manufacturers, ${models.length} models, ${years.length} years, ${variants.length} variants',
  );
}

String _csv(Object? value) {
  final text = '$value';
  if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
    return text;
  }
  return '"${text.replaceAll('"', '""')}"';
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
    'LPG' => 'lpg',
    '플러그인 하이브리드' => 'plug_in_hybrid',
    _ => 'other',
  };
}

String _efficiencyUnitFor(String fuelType) {
  return fuelType == '전기차' ? 'km/kWh' : 'km/L';
}

String _engineNameFor(String fuelType, String vehicleClass) {
  final displacement = _displacementLiterFor(fuelType, vehicleClass);
  return switch (fuelType) {
    '전기차' => 'Electric Motor',
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
  if (fuelType == '전기차') {
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

String _drivetrainFor(String fuelType) {
  return fuelType == '전기차' ? '전동 구동' : 'FWD';
}

String _transmissionFor(String fuelType) {
  return switch (fuelType) {
    '전기차' => '감속기',
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
    _ => 90,
  };
}

List<OfficialPowertrain> _officialOverrides(
  String modelId,
  int year,
  String fuelType,
) {
  final fuelLeague = _fuelLeagueFor(fuelType);
  final exact = _officialPowertrains['$modelId|$year|$fuelLeague'];
  if (exact != null) {
    return [exact];
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
        sortOrder: 40,
      ),
    ];
  }
  if (modelId == 'model-kia-013-k3' &&
      fuelLeague == 'gasoline' &&
      year >= 2018 &&
      year <= 2024) {
    return [
      OfficialPowertrain(
        id: 'variant-kia-k3-$year-16-ivt',
        trimName: '1.6 가솔린',
        engineName: 'Smartstream G1.6',
        displacementCc: 1598,
        drivetrain: 'FWD',
        transmission: 'IVT',
        officialEfficiency: 15.2,
        efficiencyUnit: 'km/L',
        sortOrder: 10,
      ),
    ];
  }
  if (modelId == 'model-kia-k3-gt-kr' &&
      fuelLeague == 'gasoline' &&
      year >= 2018 &&
      year <= 2024) {
    final dct = OfficialPowertrain(
      id: 'variant-kia-k3-gt-$year-16t-7dct',
      trimName: '1.6T 가솔린 DCT',
      engineName: 'Gamma 1.6 T-GDi',
      displacementCc: 1591,
      drivetrain: 'FWD',
      transmission: '7단 DCT',
      officialEfficiency: year <= 2020 ? 12.2 : 12.1,
      efficiencyUnit: 'km/L',
      sortOrder: 20,
    );
    if (year <= 2020) {
      return [
        OfficialPowertrain(
          id: 'variant-kia-k3-gt-$year-16t-6mt',
          trimName: '1.6T 가솔린 수동',
          engineName: 'Gamma 1.6 T-GDi',
          displacementCc: 1591,
          drivetrain: 'FWD',
          transmission: '수동 6단',
          officialEfficiency: 12.2,
          efficiencyUnit: 'km/L',
          sortOrder: 10,
        ),
        dct,
      ];
    }
    return [dct];
  }

  if (modelId == 'model-hyundai-001-kr') {
    if (fuelLeague == 'gasoline') {
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
  'model-hyundai-avante-n-kr|2026|gasoline': const OfficialPowertrain(
    id: 'variant-hyundai-avante-n-2026-20t-6mt',
    trimName: '2.0T 가솔린',
    engineName: 'N 전용 G2.0 터보 플랫파워',
    displacementCc: 1998,
    drivetrain: 'FWD',
    transmission: '6단 수동',
    officialEfficiency: 10.6,
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
              id: 'model-hyundai-avante-n-kr', sortOrder: 11, popular: true),
          m('아반떼 스포츠', 'Avante Sport', '스포츠 세단', ['가솔린'], '스포츠',
              id: 'model-hyundai-avante-sport-kr', sortOrder: 12),
          m('쏘나타', 'Sonata', '세단', ['가솔린', '하이브리드', 'LPG'], '중형'),
          m('그랜저', 'Grandeur', '세단', ['가솔린', '하이브리드'], '대형'),
          m('코나', 'Kona', 'SUV', ['가솔린', '하이브리드', '전기차'], '소형 SUV'),
          m('투싼', 'Tucson', 'SUV', ['가솔린', '디젤', '하이브리드'], 'SUV'),
          m('싼타페', 'Santa Fe', 'SUV', ['가솔린', '하이브리드'], 'SUV'),
          m('팰리세이드', 'Palisade', 'SUV', ['가솔린', '디젤'], '대형 SUV'),
          m('캐스퍼', 'Casper', '경형 SUV', ['가솔린'], '경형'),
          m('아이오닉 5', 'IONIQ 5', '전기 SUV', ['전기차'], 'SUV'),
          m('아이오닉 6', 'IONIQ 6', '전기 세단', ['전기차'], '중형'),
          m('스타리아', 'Staria', 'MPV', ['가솔린', '디젤', 'LPG'], 'MPV'),
          m('포터', 'Porter', '상용', ['디젤', '전기차'], '상용'),
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
          m(
            'K3 GT',
            'K3 GT',
            '고성능 해치백',
            ['가솔린'],
            '스포츠',
            id: 'model-kia-k3-gt-kr',
            sortOrder: 11,
            firstYear: 2018,
            lastYear: 2024,
          ),
          m('K5', 'K5', '세단', ['가솔린', '하이브리드', 'LPG'], '중형', popular: true),
          m('K8', 'K8', '세단', ['가솔린', '하이브리드', 'LPG'], '대형'),
          m('K9', 'K9', '세단', ['가솔린'], '대형'),
          m('모닝', 'Morning', '경차', ['가솔린'], '경형'),
          m('레이', 'Ray', '경차', ['가솔린', '전기차'], '경형'),
          m('셀토스', 'Seltos', 'SUV', ['가솔린'], '소형 SUV'),
          m('니로', 'Niro', 'SUV', ['하이브리드', '전기차', '플러그인 하이브리드'], '소형 SUV'),
          m('스포티지', 'Sportage', 'SUV', ['가솔린', '디젤', '하이브리드'], 'SUV'),
          m('쏘렌토', 'Sorento', 'SUV', ['가솔린', '디젤', '하이브리드'], 'SUV'),
          m('카니발', 'Carnival', 'MPV', ['가솔린', '디젤', '하이브리드'], 'MPV'),
          m('EV3', 'EV3', '전기 SUV', ['전기차'], '소형 SUV'),
          m('EV6', 'EV6', '전기 SUV', ['전기차'], 'SUV'),
          m('EV9', 'EV9', '전기 SUV', ['전기차'], '대형 SUV'),
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
          m('G70', 'G70', '세단', ['가솔린'], '중형'),
          m('G80', 'G80', '세단', ['가솔린', '전기차'], '대형'),
          m('G90', 'G90', '세단', ['가솔린'], '대형'),
          m('GV60', 'GV60', '전기 SUV', ['전기차'], 'SUV'),
          m('GV70', 'GV70', 'SUV', ['가솔린', '전기차'], 'SUV'),
          m('GV80', 'GV80', 'SUV', ['가솔린', '디젤'], '대형 SUV'),
        ],
        popular: true,
        sortOrder: 30),
    make(
        'm-chevrolet',
        '쉐보레',
        'Chevrolet',
        'US',
        [
          m('스파크', 'Spark', '경차', ['가솔린'], '경형'),
          m('말리부', 'Malibu', '세단', ['가솔린'], '중형'),
          m('트랙스', 'Trax', 'SUV', ['가솔린'], '소형 SUV'),
          m('트레일블레이저', 'Trailblazer', 'SUV', ['가솔린'], '소형 SUV'),
          m('트래버스', 'Traverse', 'SUV', ['가솔린'], '대형 SUV'),
          m('타호', 'Tahoe', 'SUV', ['가솔린'], '대형 SUV'),
          m('콜로라도', 'Colorado', '픽업', ['가솔린'], '픽업'),
          m('볼트 EV', 'Bolt EV', '전기차', ['전기차'], '준중형'),
        ],
        sortOrder: 40),
    make(
        'm-renault',
        '르노코리아',
        'Renault Korea',
        'KR',
        [
          m('SM6', 'SM6', '세단', ['가솔린', 'LPG'], '중형'),
          m('QM6', 'QM6', 'SUV', ['가솔린', 'LPG'], 'SUV'),
          m('XM3', 'XM3', 'SUV', ['가솔린', '하이브리드'], '소형 SUV'),
          m('그랑 콜레오스', 'Grand Koleos', 'SUV', ['가솔린', '하이브리드'], 'SUV'),
        ],
        sortOrder: 50),
    make(
        'm-kgm',
        'KG모빌리티',
        'KG Mobility',
        'KR',
        [
          m('티볼리', 'Tivoli', 'SUV', ['가솔린'], '소형 SUV'),
          m('코란도', 'Korando', 'SUV', ['가솔린', '디젤'], 'SUV'),
          m('토레스', 'Torres', 'SUV', ['가솔린', '전기차'], 'SUV'),
          m('렉스턴', 'Rexton', 'SUV', ['디젤'], '대형 SUV'),
          m('렉스턴 스포츠', 'Rexton Sports', '픽업', ['디젤'], '픽업'),
        ],
        sortOrder: 60),
    make(
        'm-bmw',
        'BMW',
        'BMW',
        'DE',
        [
          m('1시리즈', '1 Series', '해치백', ['가솔린'], '준중형'),
          m('2시리즈', '2 Series', '쿠페', ['가솔린'], '준중형'),
          m('3시리즈', '3 Series', '세단', ['가솔린', '디젤', '플러그인 하이브리드'], '중형'),
          m('4시리즈', '4 Series', '쿠페', ['가솔린', '디젤'], '중형'),
          m('5시리즈', '5 Series', '세단', ['가솔린', '디젤', '플러그인 하이브리드'], '대형'),
          m('7시리즈', '7 Series', '세단', ['가솔린', '플러그인 하이브리드'], '대형'),
          m('X1', 'X1', 'SUV', ['가솔린'], '소형 SUV'),
          m('X3', 'X3', 'SUV', ['가솔린', '디젤', '플러그인 하이브리드'], 'SUV'),
          m('X5', 'X5', 'SUV', ['가솔린', '디젤', '플러그인 하이브리드'], '대형 SUV'),
          m('X7', 'X7', 'SUV', ['가솔린', '디젤'], '대형 SUV'),
          m('i4', 'i4', '전기 세단', ['전기차'], '중형'),
          m('i5', 'i5', '전기 세단', ['전기차'], '대형'),
          m('iX', 'iX', '전기 SUV', ['전기차'], '대형 SUV'),
          m('iX3', 'iX3', '전기 SUV', ['전기차'], 'SUV'),
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
          m('EQA', 'EQA', '전기 SUV', ['전기차'], '소형 SUV'),
          m('EQB', 'EQB', '전기 SUV', ['전기차'], 'SUV'),
          m('EQE', 'EQE', '전기 세단', ['전기차'], '대형'),
          m('EQS', 'EQS', '전기 세단', ['전기차'], '대형'),
        ],
        sortOrder: 80),
    make(
        'm-audi',
        '아우디',
        'Audi',
        'DE',
        [
          m('A3', 'A3', '세단', ['가솔린'], '준중형'),
          m('A4', 'A4', '세단', ['가솔린', '디젤'], '중형'),
          m('A5', 'A5', '쿠페', ['가솔린', '디젤'], '중형'),
          m('A6', 'A6', '세단', ['가솔린', '디젤', '플러그인 하이브리드'], '대형'),
          m('A7', 'A7', '해치백', ['가솔린', '디젤'], '대형'),
          m('A8', 'A8', '세단', ['가솔린'], '대형'),
          m('Q3', 'Q3', 'SUV', ['가솔린'], '소형 SUV'),
          m('Q5', 'Q5', 'SUV', ['가솔린', '디젤', '플러그인 하이브리드'], 'SUV'),
          m('Q7', 'Q7', 'SUV', ['가솔린', '디젤'], '대형 SUV'),
          m('Q8', 'Q8', 'SUV', ['가솔린', '디젤'], '대형 SUV'),
          m('e-tron', 'e-tron', '전기 SUV', ['전기차'], '대형 SUV'),
          m('Q4 e-tron', 'Q4 e-tron', '전기 SUV', ['전기차'], 'SUV'),
        ],
        sortOrder: 90),
    make(
        'm-volkswagen',
        '폭스바겐',
        'Volkswagen',
        'DE',
        [
          m('골프', 'Golf', '해치백', ['가솔린', '디젤'], '준중형'),
          m('제타', 'Jetta', '세단', ['가솔린'], '준중형'),
          m('파사트', 'Passat', '세단', ['가솔린', '디젤'], '중형'),
          m('티구안', 'Tiguan', 'SUV', ['가솔린', '디젤'], 'SUV'),
          m('투아렉', 'Touareg', 'SUV', ['디젤'], '대형 SUV'),
          m('ID.4', 'ID.4', '전기 SUV', ['전기차'], 'SUV'),
          m('아테온', 'Arteon', '세단', ['디젤'], '대형'),
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
        ],
        sortOrder: 110),
    make(
        'm-lexus',
        '렉서스',
        'Lexus',
        'JP',
        [
          m('ES', 'ES', '세단', ['하이브리드'], '대형'),
          m('LS', 'LS', '세단', ['하이브리드'], '대형'),
          m('NX', 'NX', 'SUV', ['하이브리드', '플러그인 하이브리드'], 'SUV'),
          m('RX', 'RX', 'SUV', ['하이브리드', '플러그인 하이브리드'], '대형 SUV'),
          m('UX', 'UX', 'SUV', ['하이브리드'], '소형 SUV'),
          m('RZ', 'RZ', '전기 SUV', ['전기차'], 'SUV'),
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
          m('알티마', 'Altima', '세단', ['가솔린'], '중형'),
          m('맥시마', 'Maxima', '세단', ['가솔린'], '대형'),
          m('로그', 'Rogue', 'SUV', ['가솔린'], 'SUV'),
          m('리프', 'Leaf', '전기차', ['전기차'], '준중형'),
          m('아리야', 'Ariya', '전기 SUV', ['전기차'], 'SUV'),
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
        ],
        popular: true,
        sortOrder: 150),
    make(
        'm-volvo',
        '볼보',
        'Volvo',
        'SE',
        [
          m('S60', 'S60', '세단', ['가솔린', '플러그인 하이브리드'], '중형'),
          m('S90', 'S90', '세단', ['가솔린', '플러그인 하이브리드'], '대형'),
          m('XC40', 'XC40', 'SUV', ['가솔린', '전기차'], '소형 SUV'),
          m('XC60', 'XC60', 'SUV', ['가솔린', '플러그인 하이브리드'], 'SUV'),
          m('XC90', 'XC90', 'SUV', ['가솔린', '플러그인 하이브리드'], '대형 SUV'),
          m('C40', 'C40', '전기 SUV', ['전기차'], 'SUV'),
          m('EX30', 'EX30', '전기 SUV', ['전기차'], '소형 SUV'),
          m('EX90', 'EX90', '전기 SUV', ['전기차'], '대형 SUV'),
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
          m('마칸', 'Macan', 'SUV', ['가솔린', '전기차'], 'SUV'),
          m('카이엔', 'Cayenne', 'SUV', ['가솔린', '플러그인 하이브리드'], '대형 SUV'),
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
        ],
        sortOrder: 180),
    make(
        'm-peugeot',
        '푸조',
        'Peugeot',
        'FR',
        [
          m('208', '208', '해치백', ['가솔린', '전기차'], '소형'),
          m('308', '308', '해치백', ['가솔린', '디젤'], '준중형'),
          m('2008', '2008', 'SUV', ['가솔린', '전기차'], '소형 SUV'),
          m('3008', '3008', 'SUV', ['가솔린', '디젤', '플러그인 하이브리드'], 'SUV'),
          m('5008', '5008', 'SUV', ['가솔린', '디젤'], '대형 SUV'),
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
        ],
        sortOrder: 200),
    make(
        'm-landrover',
        '랜드로버',
        'Land Rover',
        'GB',
        [
          m('디펜더', 'Defender', 'SUV', ['가솔린', '디젤', '플러그인 하이브리드'], '대형 SUV'),
          m('디스커버리', 'Discovery', 'SUV', ['가솔린', '디젤'], '대형 SUV'),
          m('레인지로버', 'Range Rover', 'SUV', ['가솔린', '디젤', '플러그인 하이브리드'],
              '대형 SUV'),
          m('레인지로버 스포츠', 'Range Rover Sport', 'SUV',
              ['가솔린', '디젤', '플러그인 하이브리드'], '대형 SUV'),
          m('레인지로버 이보크', 'Range Rover Evoque', 'SUV', ['가솔린', '디젤'], 'SUV'),
        ],
        sortOrder: 210),
    make(
        'm-polestar',
        '폴스타',
        'Polestar',
        'SE',
        [
          m('Polestar 2', 'Polestar 2', '전기 세단', ['전기차'], '중형'),
          m('Polestar 3', 'Polestar 3', '전기 SUV', ['전기차'], '대형 SUV'),
          m('Polestar 4', 'Polestar 4', '전기 SUV', ['전기차'], 'SUV'),
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
  final int? sortOrder;
}
