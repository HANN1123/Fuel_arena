import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final path =
      args.isEmpty ? 'assets/data/vehicle_catalog_kr_seed.json' : args.first;
  final file = File(path);
  if (!file.existsSync()) {
    _fail('차량 카탈로그 파일을 찾을 수 없습니다: $path');
  }

  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final manufacturers = _list(data, 'manufacturers');
  final models = _list(data, 'models');
  final years = _list(data, 'years');
  final variants = _list(data, 'variants');

  _min('manufacturers', manufacturers.length, 20);
  _min('models', models.length, 120);
  _min('years', years.length, 3000);
  _min('variants', variants.length, 5000);
  _min(
    'verified variants',
    variants.where((item) => item['is_verified'] == true).length,
    3000,
  );

  const requiredManufacturers = [
    '현대',
    '기아',
    '제네시스',
    '쉐보레',
    '르노코리아',
    'KG모빌리티',
    'BMW',
    '메르세데스-벤츠',
    '아우디',
    '폭스바겐',
    '토요타',
    '렉서스',
    '혼다',
    '닛산',
    '테슬라',
    '볼보',
    '포르쉐',
    'MINI',
    '푸조',
    '지프',
    '랜드로버',
    '폴스타',
  ];
  final manufacturerNames =
      manufacturers.map((item) => '${item['name_ko']}').toSet();
  for (final name in requiredManufacturers) {
    if (!manufacturerNames.contains(name)) {
      _fail('필수 제조사가 누락되었습니다: $name');
    }
  }

  final manufacturerIds = <String>{};
  for (final manufacturer in manufacturers) {
    final id = _required(manufacturer, 'id');
    manufacturerIds.add(id);
    _required(manufacturer, 'name_ko');
    _required(manufacturer, 'country');
  }

  final modelIds = <String>{};
  final modelCountByManufacturer = <String, int>{};
  for (final model in models) {
    final id = _required(model, 'id');
    final manufacturerId = _required(model, 'manufacturer_id');
    if (!manufacturerIds.contains(manufacturerId)) {
      _fail('모델의 manufacturer_id가 존재하지 않습니다: $id -> $manufacturerId');
    }
    modelIds.add(id);
    modelCountByManufacturer.update(manufacturerId, (value) => value + 1,
        ifAbsent: () => 1);
    _required(model, 'name_ko');
    _required(model, 'body_type');
    final fuels = model['available_fuel_types'];
    if (fuels is! List || fuels.isEmpty) {
      _fail('모델 fuel type 목록이 비어 있습니다: $id');
    }
  }
  for (final manufacturerId in manufacturerIds) {
    if ((modelCountByManufacturer[manufacturerId] ?? 0) == 0) {
      _fail('제조사에 연결된 모델이 없습니다: $manufacturerId');
    }
  }

  final yearIds = <String>{};
  final yearCountByModel = <String, int>{};
  var minYear = 9999;
  var maxYear = 0;
  for (final year in years) {
    final id = _required(year, 'id');
    final modelId = _required(year, 'model_id');
    if (!modelIds.contains(modelId)) {
      _fail('연식의 model_id가 존재하지 않습니다: $id -> $modelId');
    }
    if (year['year'] is! num) {
      _fail('연식 값이 숫자가 아닙니다: $id');
    }
    final yearValue = (year['year'] as num).toInt();
    minYear = yearValue < minYear ? yearValue : minYear;
    maxYear = yearValue > maxYear ? yearValue : maxYear;
    yearIds.add(id);
    yearCountByModel.update(modelId, (value) => value + 1, ifAbsent: () => 1);
  }
  if (minYear > 2008 || maxYear < 2026) {
    _fail('차량 카탈로그 연식 범위가 2008-2026을 포함하지 않습니다: $minYear-$maxYear');
  }
  for (final modelId in modelIds) {
    if ((yearCountByModel[modelId] ?? 0) == 0) {
      _fail('모델에 연결된 연식이 없습니다: $modelId');
    }
  }

  final variantCountByYear = <String, int>{};
  for (final variant in variants) {
    final id = _required(variant, 'id');
    final modelYearId = _required(variant, 'model_year_id');
    if (!yearIds.contains(modelYearId)) {
      _fail('variant의 model_year_id가 존재하지 않습니다: $id -> $modelYearId');
    }
    _required(variant, 'trim_name');
    _required(variant, 'fuel_type');
    _required(variant, 'fuel_league');
    _required(variant, 'vehicle_class');
    _required(variant, 'efficiency_unit');
    final fuelLeague = '${variant['fuel_league']}';
    final unit = '${variant['efficiency_unit']}';
    if (fuelLeague == 'electric' && unit != 'km/kWh') {
      _fail('전기차 효율 단위가 km/kWh가 아닙니다: $id');
    }
    if (fuelLeague != 'electric' && unit != 'km/L') {
      _fail('내연기관/하이브리드 효율 단위가 km/L가 아닙니다: $id');
    }
    _validatePowertrainVariant(id, variant);
    if (variant['is_verified'] == true) {
      _validateVerifiedVariant(id, variant);
    }
    variantCountByYear.update(modelYearId, (value) => value + 1,
        ifAbsent: () => 1);
  }
  for (final yearId in yearIds) {
    if ((variantCountByYear[yearId] ?? 0) == 0) {
      _fail('연식에 연결된 variant가 없습니다: $yearId');
    }
  }
  _validateK3PowertrainSplit(models, years, variants);

  stdout.writeln(
    'vehicle catalog valid: ${manufacturers.length} manufacturers, ${models.length} models, ${years.length} years, ${variants.length} variants',
  );
}

void _validateK3PowertrainSplit(
  List<Map<String, dynamic>> models,
  List<Map<String, dynamic>> years,
  List<Map<String, dynamic>> variants,
) {
  final modelIdsByName = {
    for (final model in models) '${model['name_ko']}': '${model['id']}',
  };
  if (modelIdsByName['K3'] != 'model-kia-013-k3') {
    _fail('K3 기본 모델 ID가 누락되었습니다.');
  }
  if (modelIdsByName['K3 GT'] != 'model-kia-k3-gt-kr') {
    _fail('K3 GT는 K3와 별도 모델로 분리되어야 합니다.');
  }

  final yearsByModel = <String, List<int>>{};
  for (final year in years) {
    yearsByModel
        .putIfAbsent('${year['model_id']}', () => [])
        .add((year['year'] as num).toInt());
  }
  final k3GtYears = yearsByModel['model-kia-k3-gt-kr'] ?? const <int>[];
  final k3Years = yearsByModel['model-kia-013-k3'] ?? const <int>[];
  if (k3Years.isEmpty ||
      k3Years.reduce((a, b) => a < b ? a : b) != 2012 ||
      k3Years.reduce((a, b) => a > b ? a : b) != 2024) {
    _fail('K3 기본 모델 연식 범위는 공식 판매/제원 확인 구간인 2012-2024여야 합니다.');
  }
  if (k3GtYears.isEmpty ||
      k3GtYears.reduce((a, b) => a < b ? a : b) != 2018 ||
      k3GtYears.reduce((a, b) => a > b ? a : b) != 2024) {
    _fail('K3 GT 연식 범위는 공식 판매/제원 확인 구간인 2018-2024여야 합니다.');
  }

  Map<String, dynamic> requiredVariant(String id) {
    return variants.firstWhere(
      (variant) => variant['id'] == id,
      orElse: () => _fail('필수 K3 파워트레인 variant가 없습니다: $id'),
    );
  }

  final k3Early = requiredVariant('variant-kia-k3-2017-16-gdi-6at');
  if (k3Early['trim_name'] != '1.6 가솔린' ||
      k3Early['engine_name'] != 'Gamma 1.6 GDI' ||
      k3Early['displacement_cc'] != 1591 ||
      k3Early['transmission'] != '자동 6단') {
    _fail('초기 K3 1.6 가솔린은 Gamma 1.6 GDI 자동 6단 파워트레인으로 등록되어야 합니다.');
  }

  final k3 = requiredVariant('variant-kia-k3-2024-16-ivt');
  if (k3['trim_name'] != '1.6 가솔린' ||
      k3['displacement_cc'] != 1598 ||
      k3['transmission'] != 'IVT') {
    _fail('K3 1.6 가솔린은 1598cc IVT 파워트레인으로 등록되어야 합니다.');
  }

  final k3Diesel = requiredVariant('variant-kia-k3-2017-16-diesel-7dct');
  if (k3Diesel['trim_name'] != '1.6 디젤' ||
      k3Diesel['engine_name'] != 'U2 1.6 VGT 디젤' ||
      k3Diesel['displacement_cc'] != 1582 ||
      k3Diesel['transmission'] != '7단 DCT ISG' ||
      k3Diesel['official_efficiency'] != 19.1) {
    _fail('K3 1.6 디젤은 U2 1.6 VGT 디젤 7단 DCT ISG 파워트레인으로 등록되어야 합니다.');
  }

  if (variants.any((variant) =>
      variant['id'] == 'variant-kia-k3-2024-diesel' ||
      (variant['model_year_id'] == 'year-kia-013-k3-2024' &&
          variant['fuel_type'] == '디젤'))) {
    _fail('K3 디젤은 공식 확인 구간 밖의 최신 K3 연식에 생성되면 안 됩니다.');
  }

  final k3GtManual = requiredVariant('variant-kia-k3-gt-2020-16t-6mt');
  if (k3GtManual['trim_name'] != '1.6T 가솔린 수동' ||
      k3GtManual['displacement_cc'] != 1591 ||
      k3GtManual['transmission'] != '수동 6단') {
    _fail('K3 GT 수동 모델은 1.6T 1591cc 수동 6단 파워트레인으로 등록되어야 합니다.');
  }

  final k3Gt = requiredVariant('variant-kia-k3-gt-2024-16t-7dct');
  if (k3Gt['trim_name'] != '1.6T 가솔린 DCT' ||
      k3Gt['displacement_cc'] != 1591 ||
      k3Gt['transmission'] != '7단 DCT') {
    _fail('K3 GT는 1.6T 1591cc 7단 DCT 파워트레인으로 등록되어야 합니다.');
  }
}

void _validatePowertrainVariant(String id, Map<String, dynamic> variant) {
  final trimName = '${variant['trim_name']}';
  for (final word in _salesTrimWords) {
    if (trimName.contains(word)) {
      _fail('variant에 판매 트림명이 남아 있습니다: $id -> $trimName');
    }
  }
}

void _validateVerifiedVariant(String id, Map<String, dynamic> variant) {
  final hasCombustionSpec = variant['displacement_cc'] is num;
  final hasElectricSpec = variant['battery_kwh'] is num;
  if (!hasCombustionSpec && !hasElectricSpec) {
    _fail('검증 완료 variant의 배기량/배터리 제원이 비어 있습니다: $id');
  }
  if ('${variant['transmission'] ?? ''}'.trim().isEmpty) {
    _fail('검증 완료 variant의 변속기/감속기 정보가 비어 있습니다: $id');
  }
  if ('${variant['drivetrain'] ?? ''}'.trim().isEmpty) {
    _fail('검증 완료 variant의 구동방식 정보가 비어 있습니다: $id');
  }
}

const _salesTrimWords = [
  '스탠다드',
  '프리미엄',
  '스마트',
  '모던',
  '인스퍼레이션',
  '프레스티지',
  '노블레스',
  '시그니처',
  '캘리그래피',
  '익스클루시브',
  '트렌디',
  'N Line',
  'N라인',
];

List<Map<String, dynamic>> _list(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! List) {
    _fail('$key 목록이 없습니다.');
  }
  return value.cast<Map<String, dynamic>>();
}

String _required(Map<String, dynamic> item, String key) {
  final value = item[key];
  if (value == null || '$value'.trim().isEmpty) {
    _fail('$key 값이 비어 있습니다: $item');
  }
  return '$value';
}

void _min(String label, int actual, int minimum) {
  if (actual < minimum) {
    _fail('$label 최소 기준 미달: $actual < $minimum');
  }
}

Never _fail(String message) {
  stderr.writeln('vehicle catalog validation failed: $message');
  exitCode = 1;
  throw StateError(message);
}
