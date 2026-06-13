import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final path = args.firstWhere(
    (arg) => !arg.startsWith('--'),
    orElse: () => 'assets/data/vehicle_catalog_kr_seed.json',
  );
  try {
    runValidation(path);
  } catch (error) {
    stderr.writeln(error);
    exit(1);
  }
}

void runValidation(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw Exception('차량 카탈로그 파일을 찾을 수 없습니다: $path');
  }

  stdout.writeln('Validating Vehicle Catalog with Domain Rules: $path...');
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  final manufacturers = _list(data, 'manufacturers');
  final models = _list(data, 'models');
  final generations = data['generations'] as List<dynamic>? ?? const [];
  final years = _list(data, 'years');
  final variants = _list(data, 'variants');

  var p0Failures = 0;
  final errors = <String>[];

  void addError(String message) {
    errors.add(message);
    p0Failures++;
  }

  final manufacturerIds = manufacturers.map((item) => _id(item)).toSet();
  final modelIds = <String>{};
  final yearsById = {for (final year in years) _id(year): year};
  for (final model in models) {
    final id = _id(model);
    final manufacturerId = '${model['manufacturer_id'] ?? ''}';
    if (!manufacturerIds.contains(manufacturerId)) {
      addError('[INTEGRITY] model manufacturer_id가 존재하지 않습니다: $id');
    }
    if ('${model['name_ko'] ?? ''}' == 'K3 GT') {
      addError('[K3] K3 GT는 별도 모델이 아니라 K3의 트림/파워트레인입니다.');
    }
    if (_isVerifiedStatus('${model['source_status'] ?? ''}') &&
        !_hasSource(model)) {
      addError('[SOURCE] verified 모델에 출처가 없습니다: $id');
    }
    modelIds.add(id);
  }

  final generationIds = <String>{};
  final generationModelIdsById = <String, String>{};
  final generationIdsByYear = <String, Set<String>>{};
  for (final generation in generations) {
    final generationMap = generation as Map<String, dynamic>;
    final id = _id(generationMap);
    final modelId = '${generationMap['model_id'] ?? ''}';
    final sourceStatus = '${generationMap['source_status'] ?? 'unverified'}';
    if (!modelIds.contains(modelId)) {
      addError('[GENERATION] 세대 model_id가 존재하지 않습니다: $id');
    }
    if (_isVerifiedStatus(sourceStatus) && !_hasSource(generationMap)) {
      addError('[GENERATION] verified 세대에 출처가 없습니다: $id');
    }
    final startYear = (generationMap['start_year'] as num?)?.toInt();
    final endYear = (generationMap['end_year'] as num?)?.toInt();
    if (startYear != null && endYear != null && startYear > endYear) {
      addError('[GENERATION] 세대 기간이 비정상입니다: $id');
    }
    if ({
          'generation-honda-civic-official-lineup',
          'generation-honda-hr-v-official-lineup',
        }.contains(id) &&
        (generationMap['is_current'] != false ||
            generationMap['is_selectable'] != false)) {
      addError(
        '[HONDA] Civic/HR-V must stay non-current and non-selectable without Korea official showroom evidence: $id',
      );
    }
    if (id.startsWith('generation-nissan-') &&
        generationMap['is_current'] != false) {
      addError(
        '[NISSAN] Korea rows must not be marked current after the official 2020 withdrawal notice: $id',
      );
    }
    for (final yearId
        in generationMap['model_year_ids'] as List<dynamic>? ?? const []) {
      final yearKey = '$yearId';
      final year = yearsById[yearKey];
      if (year == null) {
        addError('[GENERATION] 세대 model_year_ids가 존재하지 않습니다: $id -> $yearKey');
      } else if ('${year['model_id'] ?? ''}' != modelId) {
        addError(
            '[GENERATION] 세대와 model_year의 model_id가 다릅니다: $id -> $yearKey');
      }
      generationIdsByYear.putIfAbsent(yearKey, () => {}).add(id);
    }
    generationIds.add(id);
    generationModelIdsById[id] = modelId;
  }
  for (final requiredGenerationId in _requiredGenerationIds) {
    if (!generationIds.contains(requiredGenerationId)) {
      addError('[GENERATION] 필수 세대 row가 누락되었습니다: $requiredGenerationId');
    }
  }

  final yearIds = <String>{};
  final variantCountByYear = <String, int>{};
  for (final year in years) {
    final id = _id(year);
    final modelId = '${year['model_id'] ?? ''}';
    final generationId = '${year['generation_id'] ?? ''}';
    if (!modelIds.contains(modelId)) {
      addError('[INTEGRITY] year model_id가 존재하지 않습니다: $id');
    }
    if (generationId.isNotEmpty && !generationIds.contains(generationId)) {
      addError('[GENERATION] year generation_id가 존재하지 않습니다: $id');
    }
    if (generationId.isNotEmpty &&
        generationModelIdsById[generationId] != modelId) {
      addError('[GENERATION] year generation_id의 model_id가 다릅니다: $id');
    }
    if (generationId.isNotEmpty) {
      generationIdsByYear.putIfAbsent(id, () => {}).add(generationId);
    }
    final yearValue = year['year'] is int ? year['year'] as int : null;
    if (modelId == 'model-benz-073-eqa' &&
        yearValue != null &&
        yearValue < 2021) {
      addError('[MERCEDES] EQA must not have pre-2021 model years: $id');
    }
    if (modelId == 'model-hyundai-avante-n-kr' &&
        yearValue != null &&
        yearValue < 2021) {
      addError('[HYUNDAI] 아반떼 N은 2021년 이전 연식 row를 생성하면 안 됩니다: $id');
    }
    if (modelId == 'model-hyundai-avante-sport-kr' &&
        yearValue != null &&
        (yearValue < 2016 || yearValue > 2018)) {
      addError('[HYUNDAI] 아반떼 스포츠는 2016-2018 연식만 생성해야 합니다: $id');
    }
    if (modelId == 'model-hyundai-004-kr' &&
        yearValue != null &&
        yearValue < 2017) {
      addError('[HYUNDAI] 코나는 2017년 이전 연식 row를 생성하면 안 됩니다: $id');
    }
    if (modelId == 'model-hyundai-007-kr' &&
        yearValue != null &&
        yearValue < 2019) {
      addError('[HYUNDAI] 팰리세이드는 2019년 이전 연식 row를 생성하면 안 됩니다: $id');
    }
    if (modelId == 'model-hyundai-008-kr' &&
        yearValue != null &&
        yearValue < 2021) {
      addError('[HYUNDAI] 캐스퍼는 2021년 이전 연식 row를 생성하면 안 됩니다: $id');
    }
    if (modelId == 'model-hyundai-011-kr' &&
        yearValue != null &&
        yearValue < 2021) {
      addError('[HYUNDAI] 스타리아는 2021년 이전 연식 row를 생성하면 안 됩니다: $id');
    }
    if (modelId == 'model-benz-074-eqb' &&
        yearValue != null &&
        yearValue < 2022) {
      addError('[MERCEDES] EQB must not have pre-2022 model years: $id');
    }
    if (modelId == 'model-benz-075-eqe' &&
        yearValue != null &&
        yearValue < 2022) {
      addError('[MERCEDES] EQE must not have pre-2022 model years: $id');
    }
    if (modelId == 'model-benz-076-eqs' &&
        yearValue != null &&
        yearValue < 2021) {
      addError('[MERCEDES] EQS must not have pre-2021 model years: $id');
    }
    if (modelId == 'model-audi-078-a4' &&
        yearValue != null &&
        yearValue > 2024) {
      addError('[AUDI] A4 must not have post-2024 model years: $id');
    }
    if (modelId == 'model-audi-081-a7' &&
        yearValue != null &&
        yearValue > 2025) {
      addError('[AUDI] A7 must not have post-2025 model years: $id');
    }
    if (modelId == 'model-audi-086-q8' &&
        yearValue != null &&
        yearValue < 2018) {
      addError('[AUDI] Q8 must not have pre-2018 model years: $id');
    }
    if (modelId == 'model-audi-087-e-tron' &&
        yearValue != null &&
        (yearValue < 2018 || yearValue > 2025)) {
      addError('[AUDI] e-tron must only have 2018-2025 model years: $id');
    }
    if (modelId == 'model-audi-088-q4-e-tron' &&
        yearValue != null &&
        yearValue < 2021) {
      addError('[AUDI] Q4 e-tron must not have pre-2021 model years: $id');
    }
    if (modelId == 'model-chevrolet-034-kr' &&
        yearValue != null &&
        yearValue > 2022) {
      addError('[CHEVROLET] Spark must not have post-2022 model years: $id');
    }
    if (modelId == 'model-chevrolet-035-kr' &&
        yearValue != null &&
        yearValue > 2022) {
      addError('[CHEVROLET] Malibu must not have post-2022 model years: $id');
    }
    if (modelId == 'model-chevrolet-037-kr' &&
        yearValue != null &&
        yearValue < 2020) {
      addError(
          '[CHEVROLET] Trailblazer must not have pre-2020 model years: $id');
    }
    if (modelId == 'model-chevrolet-038-kr' &&
        yearValue != null &&
        (yearValue < 2019 || yearValue > 2026)) {
      addError(
          '[CHEVROLET] Traverse must only have 2019-2026 model years: $id');
    }
    if (modelId == 'model-chevrolet-039-kr' &&
        yearValue != null &&
        (yearValue < 2022 || yearValue > 2026)) {
      addError('[CHEVROLET] Tahoe must only have 2022-2026 model years: $id');
    }
    if (modelId == 'model-chevrolet-equinox-kr' &&
        yearValue != null &&
        yearValue != 2026) {
      addError('[CHEVROLET] Equinox official homepage row is 2026-only: $id');
    }
    if (modelId == 'model-chevrolet-040-kr' &&
        yearValue != null &&
        yearValue < 2019) {
      addError('[CHEVROLET] Colorado must not have pre-2019 model years: $id');
    }
    if (modelId == 'model-chevrolet-041-ev' &&
        yearValue != null &&
        (yearValue < 2017 || yearValue > 2023)) {
      addError('[CHEVROLET] Bolt EV must only have 2017-2023 model years: $id');
    }
    if (modelId == 'model-volvo-124-s60' &&
        yearValue != null &&
        yearValue > 2025) {
      addError('[VOLVO] S60 must not have post-2025 model years: $id');
    }
    if (modelId == 'model-volvo-125-s90' &&
        yearValue != null &&
        yearValue < 2016) {
      addError('[VOLVO] S90 must not have pre-2016 model years: $id');
    }
    if (modelId == 'model-volvo-126-xc40' &&
        yearValue != null &&
        yearValue < 2018) {
      addError('[VOLVO] XC40 must not have pre-2018 model years: $id');
    }
    if (modelId == 'model-volvo-129-c40' &&
        yearValue != null &&
        (yearValue < 2022 || yearValue > 2024)) {
      addError('[VOLVO] C40 must only have 2022-2024 model years: $id');
    }
    if ({
          'model-volvo-ex40-kr',
          'model-volvo-ec40-kr',
        }.contains(modelId) &&
        yearValue != null &&
        yearValue < 2025) {
      addError('[VOLVO] EX40/EC40 must not have pre-2025 model years: $id');
    }
    if (modelId == 'model-volvo-130-ex30' &&
        yearValue != null &&
        yearValue < 2025) {
      addError('[VOLVO] EX30 must not have pre-2025 model years: $id');
    }
    if (modelId == 'model-volvo-131-ex90' &&
        yearValue != null &&
        yearValue < 2026) {
      addError('[VOLVO] EX90 must not have pre-2026 model years: $id');
    }
    if (modelId == 'model-volvo-ex30-cross-country-kr' &&
        yearValue != null &&
        yearValue < 2025) {
      addError(
        '[VOLVO] EX30 Cross Country must not have pre-2025 model years: $id',
      );
    }
    if (modelId == 'model-volvo-es90-kr' &&
        yearValue != null &&
        yearValue < 2026) {
      addError('[VOLVO] ES90 must not have pre-2026 model years: $id');
    }
    if (modelId == 'model-volvo-v60-cross-country-kr' &&
        yearValue != null &&
        yearValue < 2019) {
      addError(
          '[VOLVO] V60 Cross Country must not have pre-2019 model years: $id');
    }
    if ({
          'model-mini-cooper-5-door-kr',
          'model-mini-electric-cooper-kr',
          'model-mini-electric-countryman-kr',
          'model-mini-jcw-kr',
        }.contains(modelId) &&
        yearValue != null &&
        yearValue < 2026) {
      addError('[MINI] New official-lineup model must not predate 2026: $id');
    }
    if ({
          'model-hyundai-venue-kr',
          'model-hyundai-casper-electric-kr',
          'model-hyundai-ioniq5-n-kr',
          'model-hyundai-ioniq6-n-kr',
          'model-hyundai-ioniq9-kr',
          'model-hyundai-nexo-kr',
          'model-hyundai-staria-electric-kr',
          'model-hyundai-st1-kr',
        }.contains(modelId) &&
        yearValue != null &&
        yearValue < 2026) {
      addError(
          '[HYUNDAI] New official-lineup model must not predate 2026: $id');
    }
    if ({
          'model-kia-ev4-kr',
          'model-kia-ev5-kr',
          'model-kia-pv5-kr',
          'model-kia-tasman-kr',
        }.contains(modelId) &&
        yearValue != null &&
        yearValue < 2026) {
      addError('[KIA] New official-lineup model must not predate 2026: $id');
    }
    if ({
          'model-volkswagen-golf-gti-kr',
          'model-volkswagen-atlas-kr',
          'model-volkswagen-id5-kr',
        }.contains(modelId) &&
        yearValue != null &&
        yearValue < 2026) {
      addError(
        '[VOLKSWAGEN] New official-lineup model must not predate 2026: $id',
      );
    }
    if ({
          'model-lexus-lc-kr',
          'model-lexus-lx-kr',
          'model-lexus-rc-kr',
        }.contains(modelId) &&
        yearValue != null &&
        yearValue < 2026) {
      addError(
        '[LEXUS] New official model page row must not predate 2026: $id',
      );
    }
    if ({
          'model-nissan-115-kr',
          'model-nissan-116-kr',
          'model-nissan-117-kr',
        }.contains(modelId) &&
        yearValue != null &&
        yearValue > 2020) {
      addError(
          '[NISSAN] Korea gasoline archive rows must not exceed 2020: $id');
    }
    if (modelId == 'model-nissan-118-kr' &&
        yearValue != null &&
        (yearValue < 2019 || yearValue > 2020)) {
      addError('[NISSAN] Leaf Korea row must only cover 2019-2020: $id');
    }
    if (modelId == 'model-nissan-119-kr' &&
        yearValue != null &&
        yearValue != 2026) {
      addError(
        '[NISSAN] Ariya Korea-unconfirmed placeholder must only keep the 2026 template row: $id',
      );
    }
    yearIds.add(id);
  }
  _validateHyundaiCoreGenerationMapping(years, addError);
  _validateKiaCoreGenerationMapping(years, addError);
  _validateMercedesGenerationMapping(years, addError);
  _validateAudiGenerationMapping(years, addError);
  _validateChevroletGenerationMapping(years, addError);
  _validateVolvoGenerationMapping(years, addError);

  final variantCountByGeneration = <String, int>{};
  for (final variant in variants) {
    final id = _id(variant);
    final modelYearId = '${variant['model_year_id'] ?? ''}';
    final generationId = '${variant['generation_id'] ?? ''}';
    final modelName = '${variant['model_name'] ?? ''}';
    final yearValue = variant['year'] is int ? variant['year'] as int : null;
    if (!yearIds.contains(modelYearId)) {
      addError('[INTEGRITY] variant model_year_id가 존재하지 않습니다: $id');
    }
    if (generationId.isNotEmpty && !generationIds.contains(generationId)) {
      addError('[GENERATION] variant generation_id가 존재하지 않습니다: $id');
    }
    final year = yearsById[modelYearId];
    if (generationId.isNotEmpty && year != null) {
      final yearGenerationId = '${year['generation_id'] ?? ''}';
      if (yearGenerationId.isNotEmpty && generationId != yearGenerationId) {
        addError('[GENERATION] variant와 year의 generation_id가 다릅니다: $id');
      }
      final yearModelId = '${year['model_id'] ?? ''}';
      if (generationModelIdsById[generationId] != yearModelId) {
        addError('[GENERATION] variant generation_id의 model_id가 다릅니다: $id');
      }
    }
    if (_isVerifiedStatus('${variant['source_status'] ?? ''}') &&
        !_hasSource(variant)) {
      addError('[SOURCE] verified 파워트레인에 출처가 없습니다: $id');
    }
    if ((modelYearId.startsWith('year-honda-109-kr-') ||
            modelYearId.startsWith('year-honda-112-hr-v-') ||
            modelYearId.startsWith('year-nissan-119-kr-')) &&
        variant['is_selectable'] == true) {
      addError(
        '[SOURCE] Korea-unconfirmed Honda/Nissan placeholder variants must not be selectable: $id',
      );
    }
    if (modelYearId.startsWith('year-nissan-115-kr-') ||
        modelYearId.startsWith('year-nissan-116-kr-') ||
        modelYearId.startsWith('year-nissan-117-kr-')) {
      final nissanYear = yearValue ?? int.tryParse(modelYearId.split('-').last);
      if (nissanYear != null && nissanYear > 2020) {
        addError('[NISSAN] Korea archive variants must not exceed 2020: $id');
      }
    }
    if (modelYearId.startsWith('year-nissan-118-kr-')) {
      final nissanYear = yearValue ?? int.tryParse(modelYearId.split('-').last);
      if (nissanYear != null && (nissanYear < 2019 || nissanYear > 2020)) {
        addError('[NISSAN] Leaf Korea variants must only cover 2019-2020: $id');
      }
    }
    _validateToyotaLexusOfficialAuditState(
      id,
      modelYearId,
      variant,
      addError,
    );
    _validateVolkswagenOfficialAuditState(
      id,
      modelYearId,
      variant,
      addError,
    );
    _validatePeugeotOfficialAuditState(
      id,
      modelYearId,
      variant,
      addError,
    );
    _validateTeslaOfficialAuditState(
      id,
      modelYearId,
      variant,
      addError,
    );
    _validatePolestarOfficialAuditState(
      id,
      modelYearId,
      variant,
      addError,
    );
    _validateMiniOfficialAuditState(
      id,
      modelYearId,
      variant,
      addError,
    );
    _validatePorscheOfficialBoundaryState(
      id,
      modelYearId,
      variant,
      addError,
    );
    _validateJeepOfficialBoundaryState(
      id,
      modelYearId,
      variant,
      addError,
    );
    _validateImportedHomepageBoundaryState(
      id,
      modelYearId,
      variant,
      addError,
    );
    _validateDomesticHomepageBoundaryState(
      id,
      modelYearId,
      variant,
      addError,
    );
    _validateHyundaiKiaHomepageBoundaryState(
      id,
      modelYearId,
      variant,
      addError,
    );
    _validateLandRoverOfficialAuditState(
      id,
      modelYearId,
      variant,
      addError,
    );
    if (modelName == '아이오닉 5' && yearValue != null && yearValue < 2021) {
      addError('[HYUNDAI] 아이오닉 5 출시 전 연식 row가 남아 있습니다: $id');
    }
    if (modelName == '아이오닉 6' && yearValue != null && yearValue < 2022) {
      addError('[HYUNDAI] 아이오닉 6 출시 전 연식 row가 남아 있습니다: $id');
    }
    if (modelName == 'K8' && yearValue != null && yearValue < 2021) {
      addError('[KIA] K8 출시 전 연식 row가 남아 있습니다: $id');
    }
    if (modelName == '셀토스' && yearValue != null && yearValue < 2019) {
      addError('[KIA] 셀토스 출시 전 연식 row가 남아 있습니다: $id');
    }
    if (modelName == '니로' && yearValue != null && yearValue < 2016) {
      addError('[KIA] 니로 출시 전 연식 row가 남아 있습니다: $id');
    }
    if (modelName == 'EV3' && yearValue != null && yearValue < 2024) {
      addError('[KIA] EV3 출시 전 연식 row가 남아 있습니다: $id');
    }
    if (modelName == 'EV6' && yearValue != null && yearValue < 2021) {
      addError('[KIA] EV6 출시 전 연식 row가 남아 있습니다: $id');
    }
    if (modelName == 'EV9' && yearValue != null && yearValue < 2023) {
      addError('[KIA] EV9 출시 전 연식 row가 남아 있습니다: $id');
    }
    if (variant['manufacturer_name'] == '볼보' &&
        modelName == 'XC40' &&
        variant['fuel_type'] == '전기차' &&
        yearValue != null &&
        (yearValue < 2021 || yearValue > 2024)) {
      addError('[VOLVO] XC40 electric variants must only cover 2021-2024: $id');
    }
    if (variant['manufacturer_name'] == '현대' && yearValue != null) {
      final fuelType = '${variant['fuel_type'] ?? ''}';
      if (modelName == '코나' && fuelType == '하이브리드' && yearValue < 2020) {
        addError('[HYUNDAI] 코나 하이브리드는 2020년 이전 variant를 생성하면 안 됩니다: $id');
      }
      if (modelName == '코나' && fuelType == '전기차' && yearValue < 2018) {
        addError('[HYUNDAI] 코나 일렉트릭은 2018년 이전 variant를 생성하면 안 됩니다: $id');
      }
      if (modelName == '팰리세이드' && fuelType == '디젤' && yearValue > 2024) {
        addError('[HYUNDAI] 팰리세이드 디젤은 2024년 이후 variant를 생성하면 안 됩니다: $id');
      }
      if (modelName == '팰리세이드' && fuelType == '하이브리드' && yearValue < 2025) {
        addError('[HYUNDAI] 팰리세이드 하이브리드는 2025년 이전 variant를 생성하면 안 됩니다: $id');
      }
      if (modelName == '스타리아' && fuelType == '가솔린') {
        addError('[HYUNDAI] 스타리아는 가솔린 variant를 생성하면 안 됩니다: $id');
      }
      if (modelName == '스타리아' && fuelType == '하이브리드' && yearValue < 2024) {
        addError('[HYUNDAI] 스타리아 하이브리드는 2024년 이전 variant를 생성하면 안 됩니다: $id');
      }
      if (modelName == '포터' && fuelType == '디젤' && yearValue > 2023) {
        addError('[HYUNDAI] 포터 디젤은 2024년 이후 variant를 생성하면 안 됩니다: $id');
      }
      if (modelName == '포터' && fuelType == 'LPG' && yearValue < 2024) {
        addError('[HYUNDAI] 포터 LPG는 2024년 이전 variant를 생성하면 안 됩니다: $id');
      }
      if (modelName == '포터' && fuelType == '전기차' && yearValue < 2019) {
        addError('[HYUNDAI] 포터 일렉트릭은 2019년 이전 variant를 생성하면 안 됩니다: $id');
      }
    }
    if (variant['manufacturer_name'] == '포르쉐' && yearValue != null) {
      final fuelType = '${variant['fuel_type'] ?? ''}';
      if ((modelName == '마칸' || modelName == '카이엔') &&
          fuelType == '전기차' &&
          yearValue < 2026) {
        addError(
          '[PORSCHE] $modelName electric variants must not predate 2026: $id',
        );
      }
    }
    if (variant['manufacturer_name'] == '테슬라' && yearValue != null) {
      if (modelName == 'Cybertruck' && yearValue < 2026) {
        addError('[TESLA] Cybertruck variants must not predate 2026: $id');
      }
    }
    if (variant['manufacturer_name'] == '지프' && yearValue != null) {
      if (modelName == '어벤저' && yearValue < 2024) {
        addError('[JEEP] Avenger variants must not predate 2024: $id');
      }
    }
    if (variant['manufacturer_name'] == '폴스타' && yearValue != null) {
      if (modelName == 'Polestar 5' && yearValue < 2026) {
        addError('[POLESTAR] Polestar 5 variants must not predate 2026: $id');
      }
    }
    if (variant['manufacturer_name'] == '푸조' && yearValue != null) {
      final fuelType = '${variant['fuel_type'] ?? ''}';
      if ({'308', '3008', '5008', '408'}.contains(modelName) &&
          fuelType == '하이브리드' &&
          yearValue < 2026) {
        addError(
          '[PEUGEOT] SMART HYBRID variants must not predate 2026: $id',
        );
      }
    }
    if (variant['is_verified'] == true &&
        (!_isVerifiedStatus('${variant['source_status'] ?? ''}') ||
            !_hasSource(variant))) {
      addError(
          '[SOURCE] is_verified=true 파워트레인은 verified source_status와 출처가 필요합니다: $id');
    }
    final resolvedGenerationIds = generationId.isNotEmpty
        ? {generationId}
        : generationIdsByYear[modelYearId] ?? const <String>{};
    for (final resolvedGenerationId in resolvedGenerationIds) {
      variantCountByGeneration.update(
        resolvedGenerationId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    _validateVariantShape(id, variant, addError);
    variantCountByYear.update(modelYearId, (value) => value + 1,
        ifAbsent: () => 1);
  }

  for (final yearId in yearIds) {
    if ((variantCountByYear[yearId] ?? 0) == 0) {
      addError('[INTEGRITY] 연식에 연결된 variant가 없습니다: $yearId');
    }
  }
  for (final generationId in generationIds) {
    if ((variantCountByGeneration[generationId] ?? 0) == 0) {
      addError('[GENERATION] 세대에 연결된 파워트레인이 없습니다: $generationId');
    }
  }

  _validateK3(models, variants, addError);
  _validateBmwAuditState(models, variants, addError);

  if (p0Failures > 0) {
    throw Exception(
      'Validation FAILED: $p0Failures개의 P0 결함이 감지되었습니다.\n${errors.join('\n')}',
    );
  }

  stdout.writeln(
    'Validation SUCCESS: ${manufacturers.length} manufacturers, ${models.length} models, ${generations.length} generations, ${years.length} years, ${variants.length} variants.',
  );
}

void _validateBmwAuditState(
  List<Map<String, dynamic>> models,
  List<Map<String, dynamic>> variants,
  void Function(String message) addError,
) {
  if (models.any((model) => model['manufacturer_id'] == 'm-bmw')) {
    for (final model
        in models.where((item) => item['manufacturer_id'] == 'm-bmw')) {
      if (model['id'] == 'model-bmw-052-2' && model['name_ko'] != '2시리즈 쿠페') {
        addError('[BMW] 2시리즈 쿠페 row는 그란쿠페/액티브 투어러와 섞이면 안 됩니다.');
      }
      final status = '${model['source_status'] ?? ''}';
      if (_isVerifiedStatus(status) && !_hasSource(model)) {
        addError('[BMW] verified BMW 모델에 출처가 없습니다: ${model['id']}');
      }
    }
  }
  for (final variant
      in variants.where((item) => item['manufacturer_name'] == 'BMW')) {
    final id = _id(variant);
    final status = '${variant['source_status'] ?? ''}';
    final modelName = '${variant['model_name'] ?? ''}';
    final year = variant['year'] is int ? variant['year'] as int : null;
    if (modelName == '1시리즈' &&
        year != null &&
        year <= 2019 &&
        variant['drivetrain'] == 'FWD') {
      addError('[BMW] F20 1시리즈 placeholder는 FWD로 생성되면 안 됩니다: $id');
    }
    if ((modelName == '3시리즈' ||
            modelName == '4시리즈' ||
            modelName == '5시리즈' ||
            modelName == '7시리즈' ||
            modelName == '2시리즈 쿠페' ||
            modelName == 'X3' ||
            modelName == 'X5' ||
            modelName == 'X7') &&
        variant['drivetrain'] == 'FWD') {
      addError('[BMW] $modelName placeholder는 FWD로 생성되면 안 됩니다: $id');
    }
    final earliestYearByElectricModel = {
      'i4': 2022,
      'i5': 2024,
      'iX': 2022,
      'iX3': 2022,
      'X7': 2019,
    };
    final earliestYear = earliestYearByElectricModel[modelName];
    if (year != null && earliestYear != null && year < earliestYear) {
      addError('[BMW] $modelName 출시 전 연식 row가 남아 있습니다: $id');
    }
    if (_isVerifiedStatus(status) && !_hasSource(variant)) {
      addError('[BMW] verified BMW 파워트레인에 출처가 없습니다: $id');
    }
    if (variant['is_verified'] == true &&
        (!_isVerifiedStatus(status) || !_hasSource(variant))) {
      addError(
          '[BMW] is_verified=true BMW 파워트레인은 verified source_status와 출처가 필요합니다: $id');
    }
    if (!_hasSource(variant) && variant['is_selectable'] == true) {
      addError('[BMW] 출처 없는 BMW 파워트레인은 선택 가능하면 안 됩니다: $id');
    }
    if (status == 'pending_review' && variant['is_verified'] == true) {
      addError('[BMW] pending_review BMW 파워트레인은 is_verified=false여야 합니다: $id');
    }
  }
}

void _validateHyundaiCoreGenerationMapping(
  List<Map<String, dynamic>> years,
  void Function(String message) addError,
) {
  final yearsByModelYear = {
    for (final year in years) '${year['model_id']}:${year['year']}': year,
  };

  void expectRange(
    String modelId,
    int startYear,
    int endYear,
    String generationId,
  ) {
    for (var year = startYear; year <= endYear; year += 1) {
      final row = yearsByModelYear['$modelId:$year'];
      if (row == null) {
        addError('[GENERATION] 필수 현대 세대 연식 row가 누락되었습니다: $modelId $year');
      } else if ('${row['generation_id'] ?? ''}' != generationId) {
        addError(
          '[GENERATION] 현대 주요 모델 세대 매핑이 다릅니다: $modelId $year -> ${row['generation_id']}',
        );
      }
    }
  }

  expectRange(
      'model-hyundai-002-kr', 2015, 2018, 'generation-hyundai-sonata-lf');
  expectRange(
      'model-hyundai-002-kr', 2019, 2026, 'generation-hyundai-sonata-dn8');
  expectRange(
      'model-hyundai-003-kr', 2015, 2016, 'generation-hyundai-grandeur-hg');
  expectRange(
      'model-hyundai-003-kr', 2017, 2022, 'generation-hyundai-grandeur-ig');
  expectRange(
      'model-hyundai-003-kr', 2023, 2026, 'generation-hyundai-grandeur-gn7');
  expectRange(
      'model-hyundai-005-kr', 2015, 2019, 'generation-hyundai-tucson-tl');
  expectRange(
      'model-hyundai-005-kr', 2020, 2026, 'generation-hyundai-tucson-nx4');
  expectRange(
      'model-hyundai-006-kr', 2015, 2017, 'generation-hyundai-santafe-dm');
  expectRange(
      'model-hyundai-006-kr', 2018, 2022, 'generation-hyundai-santafe-tm');
  expectRange(
      'model-hyundai-006-kr', 2023, 2026, 'generation-hyundai-santafe-mx5');
  expectRange('model-hyundai-avante-n-kr', 2021, 2026,
      'generation-hyundai-avante-n-cn7');
  expectRange('model-hyundai-avante-sport-kr', 2016, 2018,
      'generation-hyundai-avante-sport-ad');
  expectRange('model-hyundai-004-kr', 2017, 2022, 'generation-hyundai-kona-os');
  expectRange(
      'model-hyundai-004-kr', 2023, 2026, 'generation-hyundai-kona-sx2');
  expectRange(
      'model-hyundai-007-kr', 2019, 2024, 'generation-hyundai-palisade-lx2');
  expectRange(
      'model-hyundai-007-kr', 2025, 2026, 'generation-hyundai-palisade-lx3');
  expectRange(
      'model-hyundai-008-kr', 2021, 2026, 'generation-hyundai-casper-ax1');
  expectRange('model-hyundai-venue-kr', 2026, 2026,
      'generation-hyundai-venue-official-lineup');
  expectRange('model-hyundai-casper-electric-kr', 2026, 2026,
      'generation-hyundai-casper-electric-official-lineup');
  expectRange('model-hyundai-ioniq5-n-kr', 2026, 2026,
      'generation-hyundai-ioniq5-n-official-lineup');
  expectRange('model-hyundai-ioniq6-n-kr', 2026, 2026,
      'generation-hyundai-ioniq6-n-official-lineup');
  expectRange('model-hyundai-ioniq9-kr', 2026, 2026,
      'generation-hyundai-ioniq9-official-lineup');
  expectRange('model-hyundai-nexo-kr', 2026, 2026,
      'generation-hyundai-nexo-official-lineup');
  expectRange(
      'model-hyundai-011-kr', 2021, 2026, 'generation-hyundai-staria-us4');
  expectRange('model-hyundai-staria-electric-kr', 2026, 2026,
      'generation-hyundai-staria-electric-official-lineup');
  expectRange(
      'model-hyundai-012-kr', 2015, 2026, 'generation-hyundai-porter2-hr');
  expectRange('model-hyundai-st1-kr', 2026, 2026,
      'generation-hyundai-st1-official-lineup');
}

void _validateKiaCoreGenerationMapping(
  List<Map<String, dynamic>> years,
  void Function(String message) addError,
) {
  final yearsByModelYear = {
    for (final year in years) '${year['model_id']}:${year['year']}': year,
  };

  void expectRange(
    String modelId,
    int startYear,
    int endYear,
    String generationId,
  ) {
    for (var year = startYear; year <= endYear; year += 1) {
      final row = yearsByModelYear['$modelId:$year'];
      if (row == null) {
        addError('[GENERATION] 필수 기아 세대 연식 row가 누락되었습니다: $modelId $year');
      } else if ('${row['generation_id'] ?? ''}' != generationId) {
        addError(
          '[GENERATION] 기아 주요 모델 세대 매핑이 다릅니다: $modelId $year -> ${row['generation_id']}',
        );
      }
    }
  }

  expectRange('model-kia-014-k5', 2015, 2018, 'generation-kia-k5-jf');
  expectRange('model-kia-014-k5', 2019, 2026, 'generation-kia-k5-dl3');
  expectRange('model-kia-015-k8', 2021, 2026, 'generation-kia-k8-gl3');
  expectRange('model-kia-016-k9', 2015, 2017, 'generation-kia-k9-kh');
  expectRange('model-kia-016-k9', 2018, 2026, 'generation-kia-k9-rj');
  expectRange('model-kia-017-kr', 2015, 2016, 'generation-kia-morning-ta');
  expectRange('model-kia-017-kr', 2017, 2026, 'generation-kia-morning-ja');
  expectRange('model-kia-018-kr', 2015, 2026, 'generation-kia-ray-tam');
  expectRange('model-kia-019-kr', 2019, 2026, 'generation-kia-seltos-sp2');
  expectRange('model-kia-020-kr', 2016, 2021, 'generation-kia-niro-de');
  expectRange('model-kia-020-kr', 2022, 2026, 'generation-kia-niro-sg2');
  expectRange('model-kia-021-kr', 2015, 2021, 'generation-kia-sportage-ql');
  expectRange('model-kia-021-kr', 2022, 2026, 'generation-kia-sportage-nq5');
  expectRange('model-kia-022-kr', 2015, 2019, 'generation-kia-sorento-um');
  expectRange('model-kia-022-kr', 2020, 2026, 'generation-kia-sorento-mq4');
  expectRange('model-kia-023-kr', 2015, 2020, 'generation-kia-carnival-yp');
  expectRange('model-kia-023-kr', 2021, 2026, 'generation-kia-carnival-ka4');
  expectRange('model-kia-024-ev3', 2024, 2026, 'generation-kia-ev3-sv1');
  expectRange(
      'model-kia-ev4-kr', 2026, 2026, 'generation-kia-ev4-official-lineup');
  expectRange(
      'model-kia-ev5-kr', 2026, 2026, 'generation-kia-ev5-official-lineup');
  expectRange('model-kia-025-ev6', 2021, 2026, 'generation-kia-ev6-cv');
  expectRange('model-kia-026-ev9', 2023, 2026, 'generation-kia-ev9-mv1');
  expectRange(
      'model-kia-pv5-kr', 2026, 2026, 'generation-kia-pv5-official-lineup');
  expectRange('model-kia-tasman-kr', 2026, 2026,
      'generation-kia-tasman-official-lineup');
  expectRange('model-kia-027-kr', 2015, 2026, 'generation-kia-bongo-pu');
}

void _validateMercedesGenerationMapping(
  List<Map<String, dynamic>> years,
  void Function(String message) addError,
) {
  final yearsByModelYear = {
    for (final year in years) '${year['model_id']}:${year['year']}': year,
  };

  void expectRange(
    String modelId,
    int startYear,
    int endYear,
    String generationId,
  ) {
    for (var year = startYear; year <= endYear; year += 1) {
      final row = yearsByModelYear['$modelId:$year'];
      if (row == null) {
        addError(
          '[GENERATION] Required Mercedes-Benz generation model year is missing: $modelId $year',
        );
      } else if ('${row['generation_id'] ?? ''}' != generationId) {
        addError(
          '[GENERATION] Mercedes-Benz generation mapping mismatch: $modelId $year -> ${row['generation_id']}',
        );
      }
    }
  }

  expectRange(
      'model-benz-065-a-class', 2015, 2017, 'generation-benz-a-class-w176');
  expectRange(
      'model-benz-065-a-class', 2018, 2026, 'generation-benz-a-class-w177');
  expectRange(
      'model-benz-066-c-class', 2015, 2020, 'generation-benz-c-class-w205');
  expectRange(
      'model-benz-066-c-class', 2021, 2026, 'generation-benz-c-class-w206');
  expectRange(
      'model-benz-067-e-class', 2015, 2015, 'generation-benz-e-class-w212');
  expectRange(
      'model-benz-067-e-class', 2016, 2023, 'generation-benz-e-class-w213');
  expectRange(
      'model-benz-067-e-class', 2024, 2026, 'generation-benz-e-class-w214');
  expectRange(
      'model-benz-068-s-class', 2015, 2020, 'generation-benz-s-class-w222');
  expectRange(
      'model-benz-068-s-class', 2021, 2026, 'generation-benz-s-class-w223');
  expectRange('model-benz-069-gla', 2015, 2019, 'generation-benz-gla-x156');
  expectRange('model-benz-069-gla', 2020, 2026, 'generation-benz-gla-h247');
  expectRange('model-benz-070-glc', 2015, 2022, 'generation-benz-glc-x253');
  expectRange('model-benz-070-glc', 2023, 2026, 'generation-benz-glc-x254');
  expectRange('model-benz-071-gle', 2015, 2018, 'generation-benz-gle-w166');
  expectRange('model-benz-071-gle', 2019, 2026, 'generation-benz-gle-v167');
  expectRange('model-benz-072-gls', 2015, 2019, 'generation-benz-gls-x166');
  expectRange('model-benz-072-gls', 2020, 2026, 'generation-benz-gls-x167');
  expectRange('model-benz-073-eqa', 2021, 2026, 'generation-benz-eqa-h243');
  expectRange('model-benz-074-eqb', 2022, 2026, 'generation-benz-eqb-x243');
  expectRange('model-benz-075-eqe', 2022, 2026, 'generation-benz-eqe-v295');
  expectRange('model-benz-076-eqs', 2021, 2026, 'generation-benz-eqs-v297');
  expectRange('model-benz-s-class-long-kr', 2026, 2026,
      'generation-benz-s-class-long-official-lineup');
  expectRange('model-benz-maybach-s-class-kr', 2026, 2026,
      'generation-benz-maybach-s-class-official-lineup');
  expectRange('model-benz-eqe-suv-kr', 2026, 2026,
      'generation-benz-eqe-suv-official-lineup');
  expectRange('model-benz-maybach-eqs-suv-kr', 2026, 2026,
      'generation-benz-maybach-eqs-suv-official-lineup');
  expectRange(
      'model-benz-glb-kr', 2026, 2026, 'generation-benz-glb-official-lineup');
  expectRange('model-benz-glc-coupe-kr', 2026, 2026,
      'generation-benz-glc-coupe-official-lineup');
  expectRange('model-benz-gle-coupe-kr', 2026, 2026,
      'generation-benz-gle-coupe-official-lineup');
  expectRange('model-benz-maybach-gls-kr', 2026, 2026,
      'generation-benz-maybach-gls-official-lineup');
  expectRange('model-benz-g-class-kr', 2026, 2026,
      'generation-benz-g-class-official-lineup');
  expectRange('model-benz-cla-coupe-kr', 2026, 2026,
      'generation-benz-cla-coupe-official-lineup');
  expectRange('model-benz-cle-coupe-kr', 2026, 2026,
      'generation-benz-cle-coupe-official-lineup');
  expectRange('model-benz-amg-gt-coupe-kr', 2026, 2026,
      'generation-benz-amg-gt-coupe-official-lineup');
  expectRange('model-benz-amg-gt-4door-coupe-kr', 2026, 2026,
      'generation-benz-amg-gt-4door-coupe-official-lineup');
  expectRange('model-benz-cle-cabriolet-kr', 2026, 2026,
      'generation-benz-cle-cabriolet-official-lineup');
  expectRange('model-benz-sl-roadster-kr', 2026, 2026,
      'generation-benz-sl-roadster-official-lineup');
  expectRange('model-benz-maybach-sl-monogram-kr', 2026, 2026,
      'generation-benz-maybach-sl-monogram-official-lineup');
}

void _validateAudiGenerationMapping(
  List<Map<String, dynamic>> years,
  void Function(String message) addError,
) {
  final yearsByModelYear = {
    for (final year in years) '${year['model_id']}:${year['year']}': year,
  };

  void expectRange(
    String modelId,
    int startYear,
    int endYear,
    String generationId,
  ) {
    for (var year = startYear; year <= endYear; year += 1) {
      final row = yearsByModelYear['$modelId:$year'];
      if (row == null) {
        addError(
          '[GENERATION] Required Audi generation model year is missing: $modelId $year',
        );
      } else if ('${row['generation_id'] ?? ''}' != generationId) {
        addError(
          '[GENERATION] Audi generation mapping mismatch: $modelId $year -> ${row['generation_id']}',
        );
      }
    }
  }

  expectRange('model-audi-077-a3', 2015, 2019, 'generation-audi-a3-8v');
  expectRange('model-audi-077-a3', 2020, 2026, 'generation-audi-a3-8y');
  expectRange('model-audi-078-a4', 2015, 2024, 'generation-audi-a4-b9-8w');
  expectRange('model-audi-079-a5', 2015, 2015, 'generation-audi-a5-8t');
  expectRange('model-audi-079-a5', 2016, 2023, 'generation-audi-a5-f5');
  expectRange('model-audi-079-a5', 2024, 2026, 'generation-audi-a5-b10');
  expectRange('model-audi-080-a6', 2015, 2018, 'generation-audi-a6-c7-4g');
  expectRange('model-audi-080-a6', 2019, 2024, 'generation-audi-a6-c8-4a');
  expectRange('model-audi-080-a6', 2025, 2026, 'generation-audi-a6-c9');
  expectRange('model-audi-081-a7', 2015, 2017, 'generation-audi-a7-4g8');
  expectRange('model-audi-081-a7', 2018, 2025, 'generation-audi-a7-4k8');
  expectRange('model-audi-082-a8', 2015, 2017, 'generation-audi-a8-d4-4h');
  expectRange('model-audi-082-a8', 2018, 2026, 'generation-audi-a8-d5-4n');
  expectRange('model-audi-083-q3', 2015, 2018, 'generation-audi-q3-8u');
  expectRange('model-audi-083-q3', 2019, 2024, 'generation-audi-q3-f3');
  expectRange('model-audi-083-q3', 2025, 2026, 'generation-audi-q3-2025');
  expectRange('model-audi-084-q5', 2015, 2016, 'generation-audi-q5-8r');
  expectRange('model-audi-084-q5', 2017, 2024, 'generation-audi-q5-fy');
  expectRange('model-audi-084-q5', 2025, 2026, 'generation-audi-q5-2025');
  expectRange('model-audi-085-q7', 2015, 2026, 'generation-audi-q7-4m');
  expectRange('model-audi-086-q8', 2018, 2026, 'generation-audi-q8-4m');
  expectRange('model-audi-087-e-tron', 2018, 2022, 'generation-audi-e-tron-ge');
  expectRange(
      'model-audi-087-e-tron', 2023, 2025, 'generation-audi-q8-e-tron-ge');
  expectRange(
      'model-audi-088-q4-e-tron', 2021, 2026, 'generation-audi-q4-e-tron-f4');
  expectRange('model-audi-e-tron-gt-kr', 2026, 2026,
      'generation-audi-e-tron-gt-official-lineup');
  expectRange('model-audi-a6-e-tron-kr', 2026, 2026,
      'generation-audi-a6-e-tron-official-lineup');
  expectRange('model-audi-q6-e-tron-kr', 2026, 2026,
      'generation-audi-q6-e-tron-official-lineup');
}

void _validateChevroletGenerationMapping(
  List<Map<String, dynamic>> years,
  void Function(String message) addError,
) {
  final yearsByModelYear = {
    for (final year in years) '${year['model_id']}:${year['year']}': year,
  };

  void expectRange(
    String modelId,
    int startYear,
    int endYear,
    String generationId,
  ) {
    for (var year = startYear; year <= endYear; year += 1) {
      final row = yearsByModelYear['$modelId:$year'];
      if (row == null) {
        addError(
          '[GENERATION] Required Chevrolet generation model year is missing: $modelId $year',
        );
      } else if ('${row['generation_id'] ?? ''}' != generationId) {
        addError(
          '[GENERATION] Chevrolet generation mapping mismatch: $modelId $year -> ${row['generation_id']}',
        );
      }
    }
  }

  expectRange(
      'model-chevrolet-034-kr', 2015, 2022, 'generation-chevrolet-spark-m400');
  expectRange(
      'model-chevrolet-035-kr', 2015, 2015, 'generation-chevrolet-malibu-v300');
  expectRange(
      'model-chevrolet-035-kr', 2016, 2022, 'generation-chevrolet-malibu-v400');
  expectRange(
      'model-chevrolet-036-kr', 2015, 2022, 'generation-chevrolet-trax-u200');
  expectRange('model-chevrolet-036-kr', 2023, 2026,
      'generation-chevrolet-trax-crossover-9bqc');
  expectRange('model-chevrolet-037-kr', 2020, 2026,
      'generation-chevrolet-trailblazer-vss-f');
  expectRange('model-chevrolet-038-kr', 2019, 2026,
      'generation-chevrolet-traverse-c1xx');
  expectRange(
      'model-chevrolet-039-kr', 2022, 2026, 'generation-chevrolet-tahoe-t1xx');
  expectRange('model-chevrolet-equinox-kr', 2026, 2026,
      'generation-chevrolet-equinox-official-lineup');
  expectRange(
      'model-chevrolet-040-kr', 2019, 2023, 'generation-chevrolet-colorado-rg');
  expectRange('model-chevrolet-040-kr', 2024, 2026,
      'generation-chevrolet-colorado-31xx-2');
  expectRange('model-chevrolet-041-ev', 2017, 2023,
      'generation-chevrolet-bolt-ev-g2cx');
}

void _validateVolvoGenerationMapping(
  List<Map<String, dynamic>> years,
  void Function(String message) addError,
) {
  final yearsByModelYear = {
    for (final year in years) '${year['model_id']}:${year['year']}': year,
  };

  void expectRange(
    String modelId,
    int startYear,
    int endYear,
    String generationId,
  ) {
    for (var year = startYear; year <= endYear; year += 1) {
      final row = yearsByModelYear['$modelId:$year'];
      if (row == null) {
        addError(
          '[GENERATION] Required Volvo generation model year is missing: $modelId $year',
        );
      } else if ('${row['generation_id'] ?? ''}' != generationId) {
        addError(
          '[GENERATION] Volvo generation mapping mismatch: $modelId $year -> ${row['generation_id']}',
        );
      }
    }
  }

  expectRange('model-volvo-124-s60', 2015, 2018, 'generation-volvo-s60-p3');
  expectRange('model-volvo-124-s60', 2019, 2025, 'generation-volvo-s60-spa');
  expectRange('model-volvo-125-s90', 2016, 2026, 'generation-volvo-s90-spa');
  expectRange('model-volvo-126-xc40', 2018, 2026, 'generation-volvo-xc40-cma');
  expectRange('model-volvo-127-xc60', 2015, 2017, 'generation-volvo-xc60-p3');
  expectRange('model-volvo-127-xc60', 2018, 2026, 'generation-volvo-xc60-spa');
  expectRange('model-volvo-128-xc90', 2015, 2026, 'generation-volvo-xc90-spa');
  expectRange('model-volvo-129-c40', 2022, 2024, 'generation-volvo-c40-cma');
  expectRange('model-volvo-ex40-kr', 2025, 2026,
      'generation-volvo-ex40-official-lineup');
  expectRange('model-volvo-ec40-kr', 2025, 2026,
      'generation-volvo-ec40-official-lineup');
  expectRange('model-volvo-130-ex30', 2025, 2026, 'generation-volvo-ex30');
  expectRange('model-volvo-131-ex90', 2026, 2026, 'generation-volvo-ex90');
  expectRange('model-volvo-ex30-cross-country-kr', 2025, 2026,
      'generation-volvo-ex30-cross-country-official-lineup');
  expectRange('model-volvo-es90-kr', 2026, 2026,
      'generation-volvo-es90-official-lineup');
  expectRange('model-volvo-v60-cross-country-kr', 2019, 2026,
      'generation-volvo-v60-cross-country-spa');
}

void _validateVariantShape(
  String id,
  Map<String, dynamic> variant,
  void Function(String message) addError,
) {
  for (final key in [
    'trim_name',
    'fuel_type',
    'fuel_league',
    'vehicle_class',
    'efficiency_unit',
  ]) {
    if ('${variant[key] ?? ''}'.trim().isEmpty) {
      addError('[VARIANT] $key 값이 비어 있습니다: $id');
    }
  }
  final fuelLeague = '${variant['fuel_league'] ?? ''}';
  final unit = '${variant['efficiency_unit'] ?? ''}';
  if (fuelLeague == 'electric' && unit != 'km/kWh') {
    addError('[VARIANT] 전기차 효율 단위가 km/kWh가 아닙니다: $id');
  }
  if (fuelLeague == 'hydrogen' && unit != 'km/kg') {
    addError('[VARIANT] 수소전기차 효율 단위가 km/kg가 아닙니다: $id');
  }
  if (fuelLeague != 'electric' && fuelLeague != 'hydrogen' && unit != 'km/L') {
    addError('[VARIANT] 내연기관/하이브리드 효율 단위가 km/L가 아닙니다: $id');
  }
  if (variant['manufacturer_name'] == '포르쉐' &&
      variant['model_name'] == '박스터' &&
      variant['drivetrain'] == 'FWD') {
    addError('[P0 DATA] 포르쉐 박스터는 FWD일 수 없습니다: $id');
  }
}

void _validateVolkswagenOfficialAuditState(
  String id,
  String modelYearId,
  Map<String, dynamic> variant,
  void Function(String message) addError,
) {
  final isVolkswagen = _volkswagenOfficialAuditYearPrefixes
      .any((prefix) => modelYearId.startsWith(prefix));
  if (!isVolkswagen) {
    return;
  }

  final year = variant['year'] is num ? (variant['year'] as num).toInt() : null;
  if (year == 2026 &&
      _volkswagenRetiredModelYearPrefixes
          .any((prefix) => modelYearId.startsWith(prefix))) {
    addError(
      '[VOLKSWAGEN] Non-current Korea lineup models must not have 2026 rows: $id',
    );
  }

  if (year == 2026 && _volkswagen2026OfficialVariantIds.contains(id)) {
    final isElectric = _volkswagen2026ElectricVariantIds.contains(id);
    if (variant['source_status'] != 'verified_official' ||
        variant['is_verified'] != true ||
        variant['is_selectable'] != true ||
        variant['official_efficiency'] is! num ||
        !'${variant['source_url'] ?? ''}'.contains('volkswagen.co.kr')) {
      addError(
        '[VOLKSWAGEN] 2026 audited variants must be selectable verified official rows with Volkswagen Korea source and efficiency: $id',
      );
    }
    if (isElectric) {
      if (variant['battery_kwh'] is! num ||
          variant['displacement_cc'] != null ||
          variant['efficiency_unit'] != 'km/kWh') {
        addError(
          '[VOLKSWAGEN] 2026 EV official variants must include battery_kwh, no displacement, and km/kWh efficiency: $id',
        );
      }
    } else if (variant['displacement_cc'] is! num ||
        variant['battery_kwh'] != null ||
        variant['efficiency_unit'] != 'km/L') {
      addError(
        '[VOLKSWAGEN] 2026 combustion official variants must include displacement, no battery_kwh, and km/L efficiency: $id',
      );
    }
    return;
  }

  if (variant['source_status'] != 'pending_review' ||
      variant['is_verified'] == true ||
      variant['is_selectable'] == true ||
      variant['official_efficiency'] != null ||
      variant['displacement_cc'] != null ||
      variant['battery_kwh'] != null ||
      '${variant['trim_name'] ?? ''}'.contains('1.6') ||
      '${variant['trim_name'] ?? ''}'.contains('2.5')) {
    addError(
      '[VOLKSWAGEN] Unaudited/non-current placeholders must stay pending, non-selectable, and free of invented numeric specs: $id',
    );
  }
}

const _volkswagenOfficialAuditYearPrefixes = {
  'year-volkswagen-089-kr-',
  'year-volkswagen-golf-gti-kr-',
  'year-volkswagen-090-kr-',
  'year-volkswagen-091-kr-',
  'year-volkswagen-092-kr-',
  'year-volkswagen-093-kr-',
  'year-volkswagen-atlas-kr-',
  'year-volkswagen-094-id-4-',
  'year-volkswagen-id5-kr-',
  'year-volkswagen-095-kr-',
};

const _volkswagenRetiredModelYearPrefixes = {
  'year-volkswagen-090-kr-',
  'year-volkswagen-091-kr-',
  'year-volkswagen-092-kr-',
  'year-volkswagen-095-kr-',
};

const _volkswagen2026OfficialVariantIds = {
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
  'variant-volkswagen-id5-2026-pro',
};

const _volkswagen2026ElectricVariantIds = {
  'variant-volkswagen-id4-2026-pro-lite-my25',
  'variant-volkswagen-id4-2026-pro-my25',
  'variant-volkswagen-id5-2026-pro-lite',
  'variant-volkswagen-id5-2026-pro',
};

void _validatePeugeotOfficialAuditState(
  String id,
  String modelYearId,
  Map<String, dynamic> variant,
  void Function(String message) addError,
) {
  final isPeugeot = _peugeotOfficialAuditYearPrefixes
      .any((prefix) => modelYearId.startsWith(prefix));
  if (!isPeugeot) {
    return;
  }

  final year = variant['year'] is num ? (variant['year'] as num).toInt() : null;
  if (year == 2026 &&
      _peugeotRetiredModelYearPrefixes
          .any((prefix) => modelYearId.startsWith(prefix))) {
    addError(
      '[PEUGEOT] Non-current Korea lineup models must not have 2026 rows: $id',
    );
  }

  if (year == 2026 && _peugeot2026OfficialVariantIds.contains(id)) {
    if (variant['source_status'] != 'verified_official' ||
        variant['is_verified'] != true ||
        variant['is_selectable'] != true ||
        variant['official_efficiency'] is! num ||
        variant['displacement_cc'] != 1199 ||
        variant['battery_kwh'] != null ||
        variant['fuel_league'] != 'hybrid' ||
        variant['efficiency_unit'] != 'km/L' ||
        !'${variant['source_url'] ?? ''}'.contains('epeugeot.co.kr')) {
      addError(
        '[PEUGEOT] 2026 SMART HYBRID variants must be selectable verified official rows with Peugeot Korea source and 1,199cc hybrid specs: $id',
      );
    }
    return;
  }

  if (variant['source_status'] != 'pending_review' ||
      variant['is_verified'] == true ||
      variant['is_selectable'] == true ||
      variant['official_efficiency'] != null ||
      variant['displacement_cc'] != null ||
      variant['battery_kwh'] != null ||
      '${variant['trim_name'] ?? ''}'.contains('1.6')) {
    addError(
      '[PEUGEOT] Unaudited/non-current placeholders must stay pending, non-selectable, and free of invented numeric specs: $id',
    );
  }
}

const _peugeotOfficialAuditYearPrefixes = {
  'year-peugeot-144-208-',
  'year-peugeot-145-308-',
  'year-peugeot-146-2008-',
  'year-peugeot-147-3008-',
  'year-peugeot-148-5008-',
  'year-peugeot-408-kr-',
};

const _peugeotRetiredModelYearPrefixes = {
  'year-peugeot-144-208-',
  'year-peugeot-146-2008-',
};

const _peugeot2026OfficialVariantIds = {
  'variant-peugeot-308-2026-smart-hybrid-allure',
  'variant-peugeot-308-2026-smart-hybrid-gt',
  'variant-peugeot-3008-2026-smart-hybrid-allure',
  'variant-peugeot-3008-2026-smart-hybrid-gt',
  'variant-peugeot-5008-2026-smart-hybrid-allure',
  'variant-peugeot-5008-2026-smart-hybrid-gt',
  'variant-peugeot-408-2026-smart-hybrid-allure',
  'variant-peugeot-408-2026-smart-hybrid-gt',
};

void _validateTeslaOfficialAuditState(
  String id,
  String modelYearId,
  Map<String, dynamic> variant,
  void Function(String message) addError,
) {
  final isTesla = _teslaOfficialAuditYearPrefixes
      .any((prefix) => modelYearId.startsWith(prefix));
  if (!isTesla) {
    return;
  }

  final year = variant['year'] is num ? (variant['year'] as num).toInt() : null;
  if (year == 2026 && _tesla2026OfficialVariantIds.contains(id)) {
    if (variant['source_status'] != 'verified_official' ||
        variant['is_verified'] != true ||
        variant['is_selectable'] != true ||
        variant['fuel_league'] != 'electric' ||
        variant['official_efficiency'] is! num ||
        variant['battery_kwh'] is! num ||
        variant['displacement_cc'] != null ||
        variant['efficiency_unit'] != 'km/kWh' ||
        !'${variant['source_url'] ?? ''}'.contains('tesla.com')) {
      addError(
        '[TESLA] 2026 official variants must be selectable verified official EV rows with Tesla Korea certified efficiency and battery specs: $id',
      );
    }
    return;
  }

  if (variant['source_status'] != 'pending_review' ||
      variant['is_verified'] == true ||
      variant['is_selectable'] == true ||
      variant['official_efficiency'] != null ||
      variant['displacement_cc'] != null ||
      variant['battery_kwh'] != null) {
    addError(
      '[TESLA] Unaudited/non-current placeholders must stay pending, non-selectable, and free of invented numeric specs: $id',
    );
  }
}

const _teslaOfficialAuditYearPrefixes = {
  'year-tesla-120-model-3-',
  'year-tesla-121-model-y-',
  'year-tesla-122-model-s-',
  'year-tesla-123-model-x-',
  'year-tesla-cybertruck-kr-',
};

const _tesla2026OfficialVariantIds = {
  'variant-tesla-model-3-2026-standard-rwd',
  'variant-tesla-model-3-2026-premium-long-range-rwd',
  'variant-tesla-model-3-2026-performance',
  'variant-tesla-model-y-2026-premium-rwd',
  'variant-tesla-model-y-2026-premium-long-range-awd',
  'variant-tesla-model-s-2026-awd',
  'variant-tesla-model-s-2026-plaid',
  'variant-tesla-model-x-2026-awd',
  'variant-tesla-model-x-2026-plaid',
};

void _validatePolestarOfficialAuditState(
  String id,
  String modelYearId,
  Map<String, dynamic> variant,
  void Function(String message) addError,
) {
  final isPolestar = _polestarOfficialAuditYearPrefixes
      .any((prefix) => modelYearId.startsWith(prefix));
  if (!isPolestar) {
    return;
  }

  final year = variant['year'] is num ? (variant['year'] as num).toInt() : null;
  if (year != 2026) {
    addError(
        '[POLESTAR] Official audit variants must only cover 2026 rows: $id');
  }

  if (_polestar2026OfficialVariantIds.contains(id)) {
    if (variant['source_status'] != 'verified_official' ||
        variant['is_verified'] != true ||
        variant['is_selectable'] != true ||
        variant['fuel_league'] != 'electric' ||
        variant['official_efficiency'] is! num ||
        variant['battery_kwh'] is! num ||
        variant['displacement_cc'] != null ||
        variant['efficiency_unit'] != 'km/kWh' ||
        !'${variant['source_url'] ?? ''}'.contains('polestar.com')) {
      addError(
        '[POLESTAR] 2026 official variants must be selectable verified official EV rows with Polestar Korea efficiency and battery specs: $id',
      );
    }
    return;
  }

  if (variant['source_status'] != 'pending_review' ||
      variant['is_verified'] == true ||
      variant['is_selectable'] == true ||
      variant['official_efficiency'] != null ||
      variant['displacement_cc'] != null ||
      variant['battery_kwh'] != null) {
    addError(
      '[POLESTAR] Unaudited/upcoming placeholders must stay pending, non-selectable, and free of invented numeric specs: $id',
    );
  }
}

const _polestarOfficialAuditYearPrefixes = {
  'year-polestar-159-polestar-2-',
  'year-polestar-160-polestar-3-',
  'year-polestar-161-polestar-4-',
  'year-polestar-5-kr-',
};

const _polestar2026OfficialVariantIds = {
  'variant-polestar-2-2026-standard-range-single-motor',
  'variant-polestar-2-2026-long-range-single-motor',
  'variant-polestar-2-2026-long-range-dual-motor',
  'variant-polestar-4-2026-coupe-rear-motor',
  'variant-polestar-4-2026-coupe-dual-motor',
  'variant-polestar-4-2026-coupe-dual-motor-performance',
};

void _validateMiniOfficialAuditState(
  String id,
  String modelYearId,
  Map<String, dynamic> variant,
  void Function(String message) addError,
) {
  final isMini = _miniOfficialAuditYearPrefixes
      .any((prefix) => modelYearId.startsWith(prefix));
  if (!isMini) {
    return;
  }

  if (variant['source_status'] != 'pending_review' ||
      variant['is_verified'] == true ||
      variant['is_selectable'] == true ||
      variant['official_efficiency'] != null ||
      variant['displacement_cc'] != null ||
      variant['battery_kwh'] != null ||
      '${variant['trim_name'] ?? ''}'.contains('1.6')) {
    addError(
      '[MINI] official-lineup placeholders must stay pending, non-selectable, and free of invented numeric specs: $id',
    );
  }
}

const _miniOfficialAuditYearPrefixes = {
  'year-mini-139-kr-',
  'year-mini-140-kr-',
  'year-mini-141-kr-',
  'year-mini-142-se-',
  'year-mini-143-kr-',
  'year-mini-aceman-kr-',
  'year-mini-cooper-5-door-kr-',
  'year-mini-electric-cooper-kr-',
  'year-mini-electric-countryman-kr-',
  'year-mini-jcw-kr-',
};

void _validatePorscheOfficialBoundaryState(
  String id,
  String modelYearId,
  Map<String, dynamic> variant,
  void Function(String message) addError,
) {
  final isPorsche = _porscheOfficialBoundaryYearPrefixes
      .any((prefix) => modelYearId.startsWith(prefix));
  if (!isPorsche) {
    return;
  }

  if (variant['source_status'] != 'pending_review' ||
      variant['is_verified'] == true ||
      variant['is_selectable'] == true ||
      variant['official_efficiency'] != null ||
      variant['displacement_cc'] != null ||
      variant['battery_kwh'] != null ||
      '${variant['trim_name'] ?? ''}'.contains('2.0') ||
      '${variant['trim_name'] ?? ''}'.contains('1.6')) {
    addError(
      '[PORSCHE] official model-page placeholders must stay pending, non-selectable, and free of invented numeric specs: $id',
    );
  }
}

const _porscheOfficialBoundaryYearPrefixes = {
  'year-porsche-132-911-',
  'year-porsche-133-kr-',
  'year-porsche-134-kr-',
  'year-porsche-135-kr-',
  'year-porsche-136-kr-',
  'year-porsche-137-kr-',
  'year-porsche-138-kr-',
};

void _validateJeepOfficialBoundaryState(
  String id,
  String modelYearId,
  Map<String, dynamic> variant,
  void Function(String message) addError,
) {
  final isJeep = _jeepOfficialBoundaryYearPrefixes
      .any((prefix) => modelYearId.startsWith(prefix));
  if (!isJeep) {
    return;
  }

  if (variant['source_status'] != 'pending_review' ||
      variant['is_verified'] == true ||
      variant['is_selectable'] == true ||
      variant['official_efficiency'] != null ||
      variant['displacement_cc'] != null ||
      variant['battery_kwh'] != null ||
      '${variant['trim_name'] ?? ''}'.contains('1.6') ||
      '${variant['trim_name'] ?? ''}'.contains('2.0')) {
    addError(
      '[JEEP] official homepage placeholders must stay pending, non-selectable, and free of invented numeric specs: $id',
    );
  }
}

const _jeepOfficialBoundaryYearPrefixes = {
  'year-jeep-149-kr-',
  'year-jeep-150-kr-',
  'year-jeep-151-kr-',
  'year-jeep-152-kr-',
  'year-jeep-153-kr-',
  'year-jeep-gladiator-kr-',
  'year-jeep-grand-cherokee-l-kr-',
  'year-jeep-avenger-kr-',
};

void _validateImportedHomepageBoundaryState(
  String id,
  String modelYearId,
  Map<String, dynamic> variant,
  void Function(String message) addError,
) {
  final isBoundaryModel = _importedHomepageBoundaryYearPrefixes
      .any((prefix) => modelYearId.startsWith(prefix));
  if (!isBoundaryModel) {
    return;
  }

  if (variant['source_status'] != 'pending_review' ||
      variant['is_verified'] == true ||
      variant['is_selectable'] == true ||
      variant['official_efficiency'] != null ||
      variant['displacement_cc'] != null ||
      variant['battery_kwh'] != null ||
      '${variant['trim_name'] ?? ''}'.contains('1.6') ||
      '${variant['trim_name'] ?? ''}'.contains('2.0') ||
      '${variant['trim_name'] ?? ''}'.contains('2.5')) {
    addError(
      '[IMPORTED] official-homepage placeholders must stay pending, non-selectable, and free of invented numeric specs: $id',
    );
  }
}

const _importedHomepageBoundaryYearPrefixes = {
  'year-benz-065-a-class-',
  'year-benz-066-c-class-',
  'year-benz-067-e-class-',
  'year-benz-068-s-class-',
  'year-benz-069-gla-',
  'year-benz-070-glc-',
  'year-benz-071-gle-',
  'year-benz-072-gls-',
  'year-benz-073-eqa-',
  'year-benz-074-eqb-',
  'year-benz-075-eqe-',
  'year-benz-076-eqs-',
  'year-benz-s-class-long-kr-',
  'year-benz-maybach-s-class-kr-',
  'year-benz-eqe-suv-kr-',
  'year-benz-maybach-eqs-suv-kr-',
  'year-benz-glb-kr-',
  'year-benz-glc-coupe-kr-',
  'year-benz-gle-coupe-kr-',
  'year-benz-maybach-gls-kr-',
  'year-benz-g-class-kr-',
  'year-benz-cla-coupe-kr-',
  'year-benz-cle-coupe-kr-',
  'year-benz-amg-gt-coupe-kr-',
  'year-benz-amg-gt-4door-coupe-kr-',
  'year-benz-cle-cabriolet-kr-',
  'year-benz-sl-roadster-kr-',
  'year-benz-maybach-sl-monogram-kr-',
  'year-audi-077-a3-',
  'year-audi-078-a4-',
  'year-audi-079-a5-',
  'year-audi-080-a6-',
  'year-audi-081-a7-',
  'year-audi-082-a8-',
  'year-audi-083-q3-',
  'year-audi-084-q5-',
  'year-audi-085-q7-',
  'year-audi-086-q8-',
  'year-audi-087-e-tron-',
  'year-audi-088-q4-e-tron-',
  'year-audi-e-tron-gt-kr-',
  'year-audi-a6-e-tron-kr-',
  'year-audi-q6-e-tron-kr-',
  'year-volvo-124-s60-',
  'year-volvo-125-s90-',
  'year-volvo-126-xc40-',
  'year-volvo-127-xc60-',
  'year-volvo-128-xc90-',
  'year-volvo-129-c40-',
  'year-volvo-ex40-kr-',
  'year-volvo-ec40-kr-',
  'year-volvo-130-ex30-',
  'year-volvo-131-ex90-',
  'year-volvo-ex30-cross-country-kr-',
  'year-volvo-es90-kr-',
  'year-volvo-v60-cross-country-kr-',
  'year-honda-109-kr-',
  'year-honda-110-kr-',
  'year-honda-111-cr-v-',
  'year-honda-112-hr-v-',
  'year-honda-113-kr-',
  'year-honda-114-kr-',
  'year-nissan-115-kr-',
  'year-nissan-116-kr-',
  'year-nissan-117-kr-',
  'year-nissan-118-kr-',
  'year-nissan-119-kr-',
};

void _validateDomesticHomepageBoundaryState(
  String id,
  String modelYearId,
  Map<String, dynamic> variant,
  void Function(String message) addError,
) {
  final isBoundaryModel = _domesticHomepageBoundaryYearPrefixes
      .any((prefix) => modelYearId.startsWith(prefix));
  if (!isBoundaryModel) {
    return;
  }

  if (variant['source_status'] != 'pending_review' ||
      variant['is_verified'] == true ||
      variant['is_selectable'] == true ||
      variant['official_efficiency'] != null ||
      variant['displacement_cc'] != null ||
      variant['battery_kwh'] != null ||
      '${variant['trim_name'] ?? ''}'.contains('1.0') ||
      '${variant['trim_name'] ?? ''}'.contains('1.2') ||
      '${variant['trim_name'] ?? ''}'.contains('1.6') ||
      '${variant['trim_name'] ?? ''}'.contains('2.0') ||
      '${variant['trim_name'] ?? ''}'.contains('2.5') ||
      '${variant['trim_name'] ?? ''}'.contains('3.5')) {
    addError(
      '[DOMESTIC] official-homepage placeholders must stay pending, non-selectable, and free of invented numeric specs: $id',
    );
  }
}

const _domesticHomepageBoundaryYearPrefixes = {
  'year-genesis-028-g70-',
  'year-genesis-g70-shooting-brake-kr-',
  'year-genesis-029-g80-',
  'year-genesis-electrified-g80-kr-',
  'year-genesis-030-g90-',
  'year-genesis-031-gv60-',
  'year-genesis-032-gv70-',
  'year-genesis-electrified-gv70-kr-',
  'year-genesis-033-gv80-',
  'year-genesis-gv80-coupe-kr-',
  'year-chevrolet-034-kr-',
  'year-chevrolet-035-kr-',
  'year-chevrolet-036-kr-',
  'year-chevrolet-037-kr-',
  'year-chevrolet-038-kr-',
  'year-chevrolet-039-kr-',
  'year-chevrolet-equinox-kr-',
  'year-chevrolet-040-kr-',
  'year-chevrolet-041-ev-',
  'year-renault-042-sm6-',
  'year-renault-043-qm6-',
  'year-renault-044-xm3-',
  'year-renault-arkana-kr-',
  'year-renault-045-kr-',
  'year-renault-filante-kr-',
  'year-kgm-046-kr-',
  'year-kgm-047-kr-',
  'year-kgm-actyon-kr-',
  'year-kgm-actyon-hybrid-kr-',
  'year-kgm-048-kr-',
  'year-kgm-torres-hybrid-kr-',
  'year-kgm-torres-evx-kr-',
  'year-kgm-torres-van-kr-',
  'year-kgm-torres-evx-van-kr-',
  'year-kgm-049-kr-',
  'year-kgm-rexton-summit-kr-',
  'year-kgm-050-kr-',
  'year-kgm-musso-kr-',
  'year-kgm-musso-ev-kr-',
};

void _validateHyundaiKiaHomepageBoundaryState(
  String id,
  String modelYearId,
  Map<String, dynamic> variant,
  void Function(String message) addError,
) {
  final isBoundaryModel = _hyundaiKiaHomepageBoundaryYearPrefixes
      .any((prefix) => modelYearId.startsWith(prefix));
  if (!isBoundaryModel) {
    return;
  }

  final sourceStatus = '${variant['source_status'] ?? ''}';
  if (sourceStatus == 'verified_official' || sourceStatus == 'verified_admin') {
    return;
  }

  if (_isPendingK3SplitReferenceVariant(id)) {
    if (sourceStatus != 'pending_review' ||
        variant['is_verified'] == true ||
        variant['is_selectable'] == true) {
      addError(
        '[K3] split reference variants must keep their powertrain shape but remain pending and non-selectable: $id',
      );
    }
    return;
  }

  if (sourceStatus != 'pending_review' ||
      variant['is_verified'] == true ||
      variant['is_selectable'] == true ||
      variant['official_efficiency'] != null ||
      variant['displacement_cc'] != null ||
      variant['battery_kwh'] != null ||
      '${variant['trim_name'] ?? ''}'.contains('1.0') ||
      '${variant['trim_name'] ?? ''}'.contains('1.6') ||
      '${variant['trim_name'] ?? ''}'.contains('2.0') ||
      '${variant['trim_name'] ?? ''}'.contains('2.2') ||
      '${variant['trim_name'] ?? ''}'.contains('2.5') ||
      '${variant['trim_name'] ?? ''}'.contains('3.5') ||
      '${variant['trim_name'] ?? ''}'.contains('3.8')) {
    addError(
      '[HYUNDAI/KIA] official-homepage placeholders must stay pending, non-selectable, and free of invented numeric specs unless verified by official/admin source: $id',
    );
  }
}

bool _isPendingK3SplitReferenceVariant(String id) {
  return id.startsWith('variant-kia-k3-');
}

const _hyundaiKiaHomepageBoundaryYearPrefixes = {
  'year-hyundai-001-kr-',
  'year-hyundai-002-kr-',
  'year-hyundai-003-kr-',
  'year-hyundai-004-kr-',
  'year-hyundai-005-kr-',
  'year-hyundai-006-kr-',
  'year-hyundai-007-kr-',
  'year-hyundai-008-kr-',
  'year-hyundai-009-5-',
  'year-hyundai-010-6-',
  'year-hyundai-011-kr-',
  'year-hyundai-012-kr-',
  'year-hyundai-avante-n-kr-',
  'year-hyundai-avante-sport-kr-',
  'year-hyundai-venue-kr-',
  'year-hyundai-casper-electric-kr-',
  'year-hyundai-ioniq5-n-kr-',
  'year-hyundai-ioniq6-n-kr-',
  'year-hyundai-ioniq9-kr-',
  'year-hyundai-nexo-kr-',
  'year-hyundai-staria-electric-kr-',
  'year-hyundai-st1-kr-',
  'year-kia-013-k3-',
  'year-kia-014-k5-',
  'year-kia-015-k8-',
  'year-kia-016-k9-',
  'year-kia-017-kr-',
  'year-kia-018-kr-',
  'year-kia-019-kr-',
  'year-kia-020-kr-',
  'year-kia-021-kr-',
  'year-kia-022-kr-',
  'year-kia-023-kr-',
  'year-kia-024-ev3-',
  'year-kia-025-ev6-',
  'year-kia-026-ev9-',
  'year-kia-027-kr-',
  'year-kia-ev4-kr-',
  'year-kia-ev5-kr-',
  'year-kia-pv5-kr-',
  'year-kia-tasman-kr-',
};

void _validateToyotaLexusOfficialAuditState(
  String id,
  String modelYearId,
  Map<String, dynamic> variant,
  void Function(String message) addError,
) {
  final isToyota = _toyotaOfficialAuditYearPrefixes
      .any((prefix) => modelYearId.startsWith(prefix));
  final isLexus = _lexusOfficialAuditYearPrefixes
      .any((prefix) => modelYearId.startsWith(prefix));
  if (!isToyota && !isLexus) {
    return;
  }

  final year = variant['year'] is num ? (variant['year'] as num).toInt() : null;
  if (year != 2026) {
    if (variant['source_status'] != 'pending_review' ||
        variant['is_selectable'] == true ||
        variant['official_efficiency'] != null ||
        variant['displacement_cc'] != null ||
        variant['battery_kwh'] != null) {
      addError(
        '[TOYOTA/LEXUS] non-2026 official-lineup placeholders must stay locked pending without invented specs: $id',
      );
    }
    return;
  }

  if (isToyota) {
    if (!_toyota2026OfficialVariantIds.contains(id)) {
      addError('[TOYOTA] Unexpected 2026 official audit variant id: $id');
    }
    if (variant['source_status'] != 'verified_official' ||
        variant['is_verified'] != true ||
        variant['is_selectable'] != true ||
        variant['official_efficiency'] is! num ||
        variant['displacement_cc'] is! num ||
        !'${variant['source_url'] ?? ''}'.contains('toyota.co.kr')) {
      addError(
        '[TOYOTA] 2026 audited variants must be selectable verified official rows with Toyota source and specs: $id',
      );
    }
    if (_toyota2026PhevVariantIds.contains(id) &&
        variant['battery_kwh'] is! num) {
      addError(
          '[TOYOTA] 2026 PHEV official variants must include battery_kwh: $id');
    }
    return;
  }

  if (!_lexus2026PendingVariantIds.contains(id)) {
    addError('[LEXUS] Unexpected 2026 official audit variant id: $id');
  }
  if (variant['source_status'] != 'pending_review' ||
      variant['is_verified'] == true ||
      variant['is_selectable'] == true ||
      variant['official_efficiency'] != null ||
      !'${variant['source_url'] ?? ''}'.contains('lexus.co.kr') ||
      '${variant['trim_name'] ?? ''}'.contains('1.6')) {
    addError(
      '[LEXUS] 2026 official audit variants must stay pending, non-selectable, sourced, and free of fake 1.6 placeholders: $id',
    );
  }
  if (!_lexus2026ElectricVariantIds.contains(id) &&
      variant['displacement_cc'] is! num) {
    addError(
        '[LEXUS] 2026 HEV/PHEV pending rows must keep official displacement: $id');
  }
}

const _toyotaOfficialAuditYearPrefixes = {
  'year-toyota-096-kr-',
  'year-toyota-097-kr-',
  'year-toyota-098-4-',
  'year-toyota-099-kr-',
  'year-toyota-100-kr-',
  'year-toyota-101-kr-',
  'year-toyota-102-gr86-',
  'year-toyota-alphard-kr-',
};

const _lexusOfficialAuditYearPrefixes = {
  'year-lexus-103-es-',
  'year-lexus-104-ls-',
  'year-lexus-105-nx-',
  'year-lexus-106-rx-',
  'year-lexus-107-ux-',
  'year-lexus-108-rz-',
  'year-lexus-lm-kr-',
  'year-lexus-lx-kr-',
};

const _toyota2026OfficialVariantIds = {
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
};

const _toyota2026PhevVariantIds = {
  'variant-toyota-prius-2026-phev',
  'variant-toyota-rav4-2026-phev-xse',
};

const _lexus2026PendingVariantIds = {
  'variant-lexus-es-2026-300h-pending',
  'variant-lexus-ls-2026-500-pending',
  'variant-lexus-ls-2026-500h-pending',
  'variant-lexus-nx-2026-350h-pending',
  'variant-lexus-nx-2026-450h-plus-pending',
  'variant-lexus-rx-2026-350h-pending',
  'variant-lexus-rx-2026-500h-pending',
  'variant-lexus-rx-2026-450h-plus-pending',
  'variant-lexus-ux-2026-300h-2wd-pending',
  'variant-lexus-ux-2026-300h-f-sport-pending',
  'variant-lexus-rz-2026-450e-pending',
  'variant-lexus-lm-2026-500h-pending',
  'variant-lexus-lx-2026-700h-pending',
};

const _lexus2026ElectricVariantIds = {
  'variant-lexus-rz-2026-450e-pending',
};

void _validateLandRoverOfficialAuditState(
  String id,
  String modelYearId,
  Map<String, dynamic> variant,
  void Function(String message) addError,
) {
  final isLandRover = _landRoverOfficialAuditYearPrefixes
      .any((prefix) => modelYearId.startsWith(prefix));
  if (!isLandRover) {
    return;
  }

  final year = variant['year'] is num ? (variant['year'] as num).toInt() : null;
  if (variant['source_status'] != 'pending_review' ||
      variant['is_verified'] == true ||
      variant['is_selectable'] == true ||
      variant['official_efficiency'] != null ||
      variant['displacement_cc'] != null ||
      variant['battery_kwh'] != null ||
      '${variant['trim_name'] ?? ''}'.contains('1.6') ||
      '${variant['trim_name'] ?? ''}'.contains('2.5')) {
    addError(
      '[LAND ROVER] official-lineup variants must stay pending/non-selectable without invented numeric specs: $id',
    );
  }

  if (year == 2026) {
    if (!_landRover2026PendingVariantIds.contains(id)) {
      addError('[LAND ROVER] Unexpected 2026 official audit variant id: $id');
    }
    if (!'${variant['source_url'] ?? ''}'.contains('landroverkorea.co.kr')) {
      addError(
          '[LAND ROVER] 2026 pending rows must keep official Korea source: $id');
    }
  }

  if (modelYearId.startsWith('year-landrover-range-rover-velar-kr-') &&
      variant['fuel_league'] == 'plug_in_hybrid' &&
      year != 2026) {
    addError(
        '[LAND ROVER] Range Rover Velar PHEV must only be generated for 2026: $id');
  }
}

const _landRoverOfficialAuditYearPrefixes = {
  'year-landrover-154-kr-',
  'year-landrover-155-kr-',
  'year-landrover-156-kr-',
  'year-landrover-157-kr-',
  'year-landrover-158-kr-',
  'year-landrover-discovery-sport-kr-',
  'year-landrover-range-rover-velar-kr-',
};

const _landRover2026PendingVariantIds = {
  'variant-landrover-defender-2026-d250-pending',
  'variant-landrover-defender-2026-d300-pending',
  'variant-landrover-defender-2026-p300-pending',
  'variant-landrover-defender-2026-p400-pending',
  'variant-landrover-defender-2026-p635-pending',
  'variant-landrover-discovery-2026-d350-pending',
  'variant-landrover-discovery-2026-p300-pending',
  'variant-landrover-discovery-2026-p360-pending',
  'variant-landrover-range-rover-2026-p530-pending',
  'variant-landrover-range-rover-2026-p615-pending',
  'variant-landrover-range-rover-2026-p550e-pending',
  'variant-landrover-range-rover-sport-2026-p360-pending',
  'variant-landrover-range-rover-sport-2026-p400-pending',
  'variant-landrover-range-rover-sport-2026-p635-pending',
  'variant-landrover-range-rover-sport-2026-p550e-pending',
  'variant-landrover-evoque-2026-p250-pending',
  'variant-landrover-discovery-sport-2026-p250-pending',
  'variant-landrover-velar-2026-p250-pending',
  'variant-landrover-velar-2026-p400-pending',
  'variant-landrover-velar-2026-p400e-pending',
};

void _validateK3(
  List<Map<String, dynamic>> models,
  List<Map<String, dynamic>> variants,
  void Function(String message) addError,
) {
  final k3Models = models.where((model) => model['name_ko'] == 'K3').toList();
  if (k3Models.length != 1 || k3Models.single['id'] != 'model-kia-013-k3') {
    addError('[K3] K3 모델 ID가 올바르지 않습니다.');
  }
  final k3Gt = variants.firstWhere(
    (variant) => variant['id'] == 'variant-kia-k3-gt-2024-16t-7dct',
    orElse: () => <String, dynamic>{},
  );
  if (k3Gt.isEmpty ||
      k3Gt['model_name'] != 'K3' ||
      k3Gt['model_year_id'] != 'year-kia-013-k3-2024' ||
      k3Gt['trim_name'] != 'K3 GT 1.6T 가솔린 DCT') {
    addError('[K3] K3 GT는 K3 모델의 GT 트림/파워트레인으로 연결되어야 합니다.');
  }
}

List<Map<String, dynamic>> _list(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! List) {
    throw Exception('$key 목록이 없습니다.');
  }
  return value.cast<Map<String, dynamic>>();
}

String _id(Map<String, dynamic> item) {
  final id = '${item['id'] ?? ''}';
  if (id.isEmpty) {
    throw Exception('id 값이 비어 있습니다: $item');
  }
  return id;
}

bool _isVerifiedStatus(String status) {
  return status == 'verified_official' || status == 'verified_admin';
}

bool _hasSource(Map<String, dynamic> item) {
  return '${item['source_name'] ?? ''}'.trim().isNotEmpty ||
      '${item['source_url'] ?? ''}'.trim().isNotEmpty ||
      '${item['source_file_name'] ?? ''}'.trim().isNotEmpty;
}

const _requiredGenerationIds = [
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
  'generation-hyundai-venue-official-lineup',
  'generation-hyundai-casper-electric-official-lineup',
  'generation-hyundai-ioniq5-n-official-lineup',
  'generation-hyundai-ioniq6-n-official-lineup',
  'generation-hyundai-ioniq9-official-lineup',
  'generation-hyundai-nexo-official-lineup',
  'generation-hyundai-staria-us4',
  'generation-hyundai-staria-electric-official-lineup',
  'generation-hyundai-porter2-hr',
  'generation-hyundai-st1-official-lineup',
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
  'generation-kia-ev4-official-lineup',
  'generation-kia-ev5-official-lineup',
  'generation-kia-ev6-cv',
  'generation-kia-ev9-mv1',
  'generation-kia-pv5-official-lineup',
  'generation-kia-tasman-official-lineup',
  'generation-kia-bongo-pu',
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
  'generation-tesla-model3-official-lineup',
  'generation-tesla-modely-official-lineup',
  'generation-tesla-models-official-lineup',
  'generation-tesla-modelx-official-lineup',
  'generation-porsche-911-official-lineup',
  'generation-porsche-boxster-official-lineup',
  'generation-porsche-cayman-official-lineup',
  'generation-porsche-panamera-official-lineup',
  'generation-porsche-macan-official-lineup',
  'generation-porsche-cayenne-official-lineup',
  'generation-porsche-taycan-official-lineup',
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
  'generation-jeep-renegade-official-lineup',
  'generation-jeep-compass-official-lineup',
  'generation-jeep-cherokee-official-lineup',
  'generation-jeep-wrangler-official-lineup',
  'generation-jeep-grand-cherokee-official-lineup',
  'generation-jeep-gladiator-official-lineup',
  'generation-jeep-grand-cherokee-l-official-lineup',
  'generation-landrover-defender-official-lineup',
  'generation-landrover-discovery-official-lineup',
  'generation-landrover-range-rover-official-lineup',
  'generation-landrover-range-rover-sport-official-lineup',
  'generation-landrover-range-rover-evoque-official-lineup',
  'generation-landrover-discovery-sport-official-lineup',
  'generation-landrover-range-rover-velar-official-lineup',
  'generation-polestar-2-official-lineup',
  'generation-polestar-3-official-lineup',
  'generation-polestar-4-official-lineup',
  'generation-bmw-x2-official-lineup',
  'generation-bmw-x4-official-lineup',
  'generation-bmw-x6-official-lineup',
  'generation-bmw-xm-official-lineup',
  'generation-bmw-z4-official-lineup',
  'generation-bmw-i7-official-lineup',
  'generation-bmw-ix1-official-lineup',
  'generation-bmw-ix2-official-lineup',
  'generation-bmw-i3-official-lineup',
];
