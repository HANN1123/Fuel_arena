import '../models/fuel_arena_models.dart';

const _fuelTypeOrder = [
  'gasoline',
  'hybrid',
  'electric',
  'diesel',
  'lpg',
  'plug_in_hybrid',
  'other',
];

const _usageCategoryOrder = [
  'EV',
  'PBV',
  '승용',
  'SUV',
  'RV',
  '택시 & 버스 & 상용',
  '기타',
];

const _vehicleClassOrder = [
  '경형',
  '소형',
  '준중형',
  '중형',
  '준대형',
  '대형',
  '스포츠',
  '소형 SUV',
  '준중형 SUV',
  '중형 SUV',
  '대형 SUV',
  'SUV',
  'MPV',
  '픽업',
  '상용',
];

const _bodyTypeOrder = [
  '세단',
  'SUV',
  '해치백',
  '왜건',
  '쿠페',
  '스포츠',
  '픽업',
  '밴',
  '상용',
];

String normalizedVehicleFuelType(VehicleVariant variant) {
  final fuelLeague = variant.fuelLeague.trim();
  if (fuelLeague.isNotEmpty) {
    return fuelLeague;
  }
  return FuelLeague.keyForFuelType(variant.fuelType);
}

String normalizeVehicleBodyType(String bodyType) {
  var value = bodyType.trim();
  if (value.isEmpty) {
    return '';
  }
  for (final prefix in const ['전기 ', 'EV ', '일렉트릭 ']) {
    if (value.startsWith(prefix)) {
      value = value.substring(prefix.length).trim();
    }
  }
  if (value.contains('SUV')) {
    return 'SUV';
  }
  if (value.contains('세단')) {
    return '세단';
  }
  if (value.contains('해치백')) {
    return '해치백';
  }
  if (value.contains('왜건')) {
    return '왜건';
  }
  if (value.contains('쿠페')) {
    return '쿠페';
  }
  if (value.contains('픽업')) {
    return '픽업';
  }
  if (value.contains('밴') || value.contains('버스')) {
    return '밴';
  }
  if (value.contains('상용')) {
    return '상용';
  }
  return value;
}

String deriveVehicleMarketSegment(String bodyType) {
  final normalized = normalizeVehicleBodyType(bodyType);
  final raw = bodyType.trim();
  if (raw.contains('고성능') || raw.contains('스포츠') || raw.contains('GT')) {
    return 'performance';
  }
  if (normalized == 'SUV') {
    return 'suv';
  }
  if (normalized == '세단') {
    return 'sedan';
  }
  if (normalized == '상용' || normalized == '밴' || normalized == '픽업') {
    return 'commercial';
  }
  return normalized.isEmpty ? '' : normalized;
}

String vehicleUsageCategoryForVariant(VehicleVariant variant) {
  final fuelType = normalizedVehicleFuelType(variant);
  final text = _variantSearchText(variant);
  final bodyType = normalizeVehicleBodyType(variant.bodyType);
  final vehicleClass = variant.vehicleClass.trim();
  if (fuelType == 'electric') {
    return 'EV';
  }
  if (_containsAny(text, const ['pbv', 'pv5', '목적 기반', 'purpose built'])) {
    return 'PBV';
  }
  if (_containsAny(text, const [
    '택시',
    '버스',
    '상용',
    '트럭',
    '픽업',
    '포터',
    '봉고',
    '스타리아',
    '카고',
  ])) {
    return '택시 & 버스 & 상용';
  }
  if (bodyType == 'SUV' || vehicleClass.contains('SUV')) {
    return 'SUV';
  }
  if (_containsAny(text, const ['rv', 'mpv', '밴', '카니발', '승합'])) {
    return 'RV';
  }
  if (_containsAny(text, const ['세단', '해치백', '왜건', '쿠페', '스포츠'])) {
    return '승용';
  }
  return '기타';
}

bool isVehicleVariantSelectable(VehicleVariant variant) {
  return variant.isSelectable && !variant.isDeprecated;
}

List<String> supportedFuelTypesFromVariants(List<VehicleVariant> variants) {
  final values = variants
      .where(isVehicleVariantSelectable)
      .map(normalizedVehicleFuelType)
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();
  values.sort(_compareFuelTypes);
  return values;
}

List<VehicleCategoryFilter> buildVehicleCategoryFilters(
  List<VehicleVariant> variants, {
  required String fuelType,
}) {
  final scoped = variants.where((variant) {
    return isVehicleVariantSelectable(variant) &&
        _matchesFuelType(variant, fuelType);
  }).toList();
  final categories = scoped
      .map(vehicleUsageCategoryForVariant)
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList()
    ..sort(_compareUsageCategories);
  return [
    VehicleCategoryFilter.all,
    ...categories.map(
      (item) => VehicleCategoryFilter(
        key: 'usage:$item',
        label: item,
        kind: VehicleCategoryFilterKind.usageCategory,
        value: item,
      ),
    ),
  ];
}

List<VehicleModelFilterSummary> buildVehicleModelFilterSummaries({
  required List<VehicleModel> models,
  required List<VehicleModelYear> years,
  required List<VehicleVariant> variants,
  required String fuelType,
  required VehicleCategoryFilter category,
  String keyword = '',
}) {
  final normalizedKeyword = keyword.trim().toLowerCase();
  final yearsByModel = <String, List<VehicleModelYear>>{};
  for (final year in years) {
    yearsByModel
        .putIfAbsent(year.modelId, () => <VehicleModelYear>[])
        .add(year);
  }

  final summaries = <VehicleModelFilterSummary>[];
  for (final model in models) {
    final modelYears = yearsByModel[model.id] ?? const <VehicleModelYear>[];
    final yearIds = modelYears.map((item) => item.id).toSet();
    final modelKeywordMatches = normalizedKeyword.isEmpty ||
        model.nameKo.toLowerCase().contains(normalizedKeyword) ||
        model.nameEn.toLowerCase().contains(normalizedKeyword);
    final matchingVariants = variants.where((variant) {
      if (!yearIds.contains(variant.modelYearId)) {
        return false;
      }
      if (!isVehicleVariantSelectable(variant) ||
          !_matchesFuelType(variant, fuelType) ||
          !_matchesCategory(variant, category)) {
        return false;
      }
      return modelKeywordMatches ||
          _variantMatchesKeyword(variant, normalizedKeyword);
    }).toList()
      ..sort(compareVehicleVariants);
    if (matchingVariants.isEmpty) {
      continue;
    }
    final matchingYears = matchingVariants.map((item) => item.year).toList();
    summaries.add(
      VehicleModelFilterSummary(
        model: model,
        matchingVariants: matchingVariants,
        supportedFuelTypes: supportedFuelTypesFromVariants(matchingVariants),
        supportedVehicleClasses: _orderedUnique(
          matchingVariants.map((item) => item.vehicleClass),
          _compareVehicleClasses,
        ),
        supportedBodyTypes: _orderedUnique(
          matchingVariants
              .map((item) => normalizeVehicleBodyType(item.bodyType)),
          _compareBodyTypes,
        ),
        minYear: matchingYears.reduce((a, b) => a < b ? a : b),
        maxYear: matchingYears.reduce((a, b) => a > b ? a : b),
        samplePowertrainLabels: _orderedUnique(
          matchingVariants.map((item) => item.trimName),
          (a, b) => a.compareTo(b),
        ).take(3).toList(),
      ),
    );
  }
  summaries.sort((a, b) {
    final bySort = a.model.sortOrder.compareTo(b.model.sortOrder);
    if (bySort != 0) {
      return bySort;
    }
    return a.model.nameKo.compareTo(b.model.nameKo);
  });
  return summaries;
}

List<VehicleGenerationSummary> buildVehicleGenerationSummaries({
  required VehicleModel model,
  required List<VehicleGeneration> generations,
  required List<VehicleModelYear> years,
  required List<VehicleVariant> variants,
  required String fuelType,
  required VehicleCategoryFilter category,
  String keyword = '',
}) {
  final normalizedKeyword = keyword.trim().toLowerCase();
  final modelYears = years.where((item) => item.modelId == model.id).toList();
  final summaries = <VehicleGenerationSummary>[];
  for (final generation in generations.where((item) {
    return item.modelId == model.id && item.isSelectable && !item.isDeprecated;
  })) {
    final explicitYearIds = generation.modelYearIds.toSet();
    final generationYears = modelYears.where((year) {
      return year.generationId == generation.id ||
          explicitYearIds.contains(year.id);
    }).toList();
    if (generationYears.isEmpty) {
      continue;
    }
    final yearIds = generationYears.map((item) => item.id).toSet();
    final generationKeywordMatches = normalizedKeyword.isEmpty ||
        generation.displayName.toLowerCase().contains(normalizedKeyword) ||
        generation.periodLabel.toLowerCase().contains(normalizedKeyword) ||
        generation.generationCode.toLowerCase().contains(normalizedKeyword);
    final matchingVariants = variants.where((variant) {
      if (!yearIds.contains(variant.modelYearId)) {
        return false;
      }
      if (!isVehicleVariantSelectable(variant) ||
          !_matchesFuelType(variant, fuelType) ||
          !_matchesCategory(variant, category)) {
        return false;
      }
      return generationKeywordMatches ||
          _variantMatchesKeyword(variant, normalizedKeyword);
    }).toList()
      ..sort(compareVehicleVariants);
    if (matchingVariants.isEmpty) {
      continue;
    }
    final choices = buildVehiclePowertrainChoices(matchingVariants);
    summaries.add(
      VehicleGenerationSummary(
        generation: generation,
        modelYears: generationYears,
        matchingVariants: matchingVariants,
        supportedFuelTypes: supportedFuelTypesFromVariants(matchingVariants),
        supportedVehicleClasses: _orderedUnique(
          matchingVariants.map((item) => item.vehicleClass),
          _compareVehicleClasses,
        ),
        supportedBodyTypes: _orderedUnique(
          matchingVariants
              .map((item) => normalizeVehicleBodyType(item.bodyType)),
          _compareBodyTypes,
        ),
        matchingPowertrainCount: choices.length,
        verifiedPowertrainCount: choices
            .where(
                (item) => item.variants.every((variant) => variant.isVerified))
            .length,
        sourceStatusSummary:
            _summarizeSourceStatus(generation, matchingVariants),
      ),
    );
  }
  summaries.sort(_compareGenerationSummaries);
  return summaries;
}

List<VehicleModelYear> filterVehicleYearsByPowertrain({
  required List<VehicleModelYear> years,
  required List<VehicleVariant> variants,
  required String fuelType,
  required VehicleCategoryFilter category,
}) {
  final matchingYearIds = variants
      .where((variant) {
        return isVehicleVariantSelectable(variant) &&
            _matchesFuelType(variant, fuelType) &&
            _matchesCategory(variant, category);
      })
      .map((item) => item.modelYearId)
      .toSet();
  return years.where((item) => matchingYearIds.contains(item.id)).toList()
    ..sort((a, b) => b.year.compareTo(a.year));
}

List<VehicleVariant> filterVehiclePowertrains({
  required List<VehicleVariant> variants,
  required String fuelType,
  required VehicleCategoryFilter category,
  String keyword = '',
}) {
  final normalizedKeyword = keyword.trim().toLowerCase();
  return variants.where((variant) {
    return isVehicleVariantSelectable(variant) &&
        _matchesFuelType(variant, fuelType) &&
        _matchesCategory(variant, category) &&
        _variantMatchesKeyword(variant, normalizedKeyword);
  }).toList()
    ..sort(compareVehicleVariants);
}

List<VehicleVariant> filterVehiclePowertrainsByGeneration({
  required VehicleGeneration generation,
  required List<VehicleModelYear> years,
  required List<VehicleVariant> variants,
  required String fuelType,
  required VehicleCategoryFilter category,
  String keyword = '',
}) {
  final explicitYearIds = generation.modelYearIds.toSet();
  final generationYearIds = years
      .where((year) =>
          year.generationId == generation.id ||
          explicitYearIds.contains(year.id))
      .map((item) => item.id)
      .toSet();
  return filterVehiclePowertrains(
    variants: variants
        .where((item) => generationYearIds.contains(item.modelYearId))
        .toList(),
    fuelType: fuelType,
    category: category,
    keyword: keyword,
  );
}

List<VehiclePowertrainChoice> buildVehiclePowertrainChoices(
  List<VehicleVariant> variants,
) {
  final groups = <String, List<VehicleVariant>>{};
  for (final variant in variants) {
    groups.putIfAbsent(_powertrainSignature(variant), () => []).add(variant);
  }
  final choices = groups.values.map((items) {
    final sorted = [...items]..sort(compareVehicleVariants);
    final representative = sorted.first;
    return VehiclePowertrainChoice(
      representative: representative.copyWith(
        sourceStatus: _summarizeVariantSourceStatus(sorted),
      ),
      variants: sorted,
      validFromYear: sorted
          .map((item) => item.validFromYear ?? item.year)
          .reduce((a, b) => a < b ? a : b),
      validToYear: sorted
          .map((item) => item.validToYear ?? item.year)
          .reduce((a, b) => a > b ? a : b),
      validFromMonth: representative.validFromMonth,
      validToMonth: representative.validToMonth,
    );
  }).toList()
    ..sort((a, b) {
      final byVariant =
          compareVehicleVariants(a.representative, b.representative);
      if (byVariant != 0) {
        return byVariant;
      }
      return b.validToYear.compareTo(a.validToYear);
    });
  return choices;
}

int compareVehicleVariants(VehicleVariant a, VehicleVariant b) {
  final bySortOrder = a.sortOrder.compareTo(b.sortOrder);
  if (bySortOrder != 0) {
    return bySortOrder;
  }
  final byYear = b.year.compareTo(a.year);
  if (byYear != 0) {
    return byYear;
  }
  return a.trimName.compareTo(b.trimName);
}

bool _matchesFuelType(VehicleVariant variant, String fuelType) {
  return fuelType.isEmpty || normalizedVehicleFuelType(variant) == fuelType;
}

bool _matchesCategory(VehicleVariant variant, VehicleCategoryFilter category) {
  return switch (category.kind) {
    VehicleCategoryFilterKind.all => true,
    VehicleCategoryFilterKind.vehicleClass =>
      variant.vehicleClass.trim() == category.value,
    VehicleCategoryFilterKind.bodyType =>
      normalizeVehicleBodyType(variant.bodyType) == category.value,
    VehicleCategoryFilterKind.usageCategory =>
      vehicleUsageCategoryForVariant(variant) == category.value,
  };
}

bool _variantMatchesKeyword(VehicleVariant variant, String normalizedKeyword) {
  if (normalizedKeyword.isEmpty) {
    return true;
  }
  return _variantSearchText(variant).contains(normalizedKeyword);
}

String _variantSearchText(VehicleVariant variant) {
  return [
    variant.manufacturerName,
    variant.modelName,
    variant.trimName,
    variant.engineName,
    variant.fuelType,
    variant.vehicleClass,
    variant.bodyType,
    variant.transmission,
    FuelLeague.nameForKey(normalizedVehicleFuelType(variant)),
    if (variant.displacementCc != null) '${variant.displacementCc}cc',
    if (variant.batteryKwh != null) '${variant.batteryKwh}kWh',
    if (variant.officialEfficiency != null)
      variant.officialEfficiency!.toStringAsFixed(1),
  ].join(' ').toLowerCase();
}

String _powertrainSignature(VehicleVariant variant) {
  return [
    variant.trimName.trim().toLowerCase(),
    variant.engineName.trim().toLowerCase(),
    normalizedVehicleFuelType(variant),
    variant.drivetrain.trim().toLowerCase(),
    variant.transmission.trim().toLowerCase(),
    '${variant.displacementCc ?? ''}',
    '${variant.batteryKwh ?? ''}',
    variant.vehicleClass.trim().toLowerCase(),
  ].join('|');
}

String _summarizeSourceStatus(
  VehicleGeneration generation,
  List<VehicleVariant> variants,
) {
  if (generation.sourceStatus == 'conflict' ||
      variants.any((item) => item.sourceStatus == 'conflict')) {
    return 'conflict';
  }
  if (generation.sourceStatus.startsWith('verified') && generation.hasSource) {
    return generation.sourceStatus;
  }
  if (variants.any((item) => !item.isVerified)) {
    return 'pending_review';
  }
  if (generation.sourceStatus.isEmpty) {
    return 'unverified';
  }
  return generation.sourceStatus;
}

String _summarizeVariantSourceStatus(List<VehicleVariant> variants) {
  if (variants.any((item) => item.sourceStatus == 'conflict')) {
    return 'conflict';
  }
  if (variants.every((item) => item.sourceStatus == 'verified_official')) {
    return 'verified_official';
  }
  if (variants.every((item) => item.sourceStatus == 'verified_admin')) {
    return 'verified_admin';
  }
  if (variants.any((item) => !item.isVerified)) {
    return 'pending_review';
  }
  return variants.first.sourceStatus;
}

int _compareGenerationSummaries(
  VehicleGenerationSummary a,
  VehicleGenerationSummary b,
) {
  if (a.generation.isUpcoming != b.generation.isUpcoming) {
    return a.generation.isUpcoming ? 1 : -1;
  }
  if (a.generation.isCurrent != b.generation.isCurrent) {
    return a.generation.isCurrent ? -1 : 1;
  }
  final aYear = a.generation.startYear ?? 0;
  final bYear = b.generation.startYear ?? 0;
  if (aYear != bYear) {
    return bYear.compareTo(aYear);
  }
  final aOrder = a.generation.generationOrder ?? 0;
  final bOrder = b.generation.generationOrder ?? 0;
  if (aOrder != bOrder) {
    return bOrder.compareTo(aOrder);
  }
  return a.generation.displayName.compareTo(b.generation.displayName);
}

List<String> _orderedUnique(
  Iterable<String> values,
  int Function(String a, String b) compare,
) {
  final unique = values
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();
  unique.sort(compare);
  return unique;
}

bool _containsAny(String source, List<String> needles) {
  return needles.any((item) => source.contains(item.toLowerCase()));
}

int _compareFuelTypes(String a, String b) {
  final aIndex = _fuelTypeOrder.indexOf(a);
  final bIndex = _fuelTypeOrder.indexOf(b);
  if (aIndex >= 0 && bIndex >= 0) {
    return aIndex.compareTo(bIndex);
  }
  if (aIndex >= 0) {
    return -1;
  }
  if (bIndex >= 0) {
    return 1;
  }
  return a.compareTo(b);
}

int _compareUsageCategories(String a, String b) {
  final aIndex = _usageCategoryOrder.indexOf(a);
  final bIndex = _usageCategoryOrder.indexOf(b);
  if (aIndex >= 0 && bIndex >= 0) {
    return aIndex.compareTo(bIndex);
  }
  if (aIndex >= 0) {
    return -1;
  }
  if (bIndex >= 0) {
    return 1;
  }
  return a.compareTo(b);
}

int _compareVehicleClasses(String a, String b) {
  final aIndex = _vehicleClassOrder.indexOf(a);
  final bIndex = _vehicleClassOrder.indexOf(b);
  if (aIndex >= 0 && bIndex >= 0) {
    return aIndex.compareTo(bIndex);
  }
  if (aIndex >= 0) {
    return -1;
  }
  if (bIndex >= 0) {
    return 1;
  }
  return a.compareTo(b);
}

int _compareBodyTypes(String a, String b) {
  final aIndex = _bodyTypeOrder.indexOf(a);
  final bIndex = _bodyTypeOrder.indexOf(b);
  if (aIndex >= 0 && bIndex >= 0) {
    return aIndex.compareTo(bIndex);
  }
  if (aIndex >= 0) {
    return -1;
  }
  if (bIndex >= 0) {
    return 1;
  }
  return a.compareTo(b);
}
