import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final options = _ReportOptions.parse(args);
  final report = CatalogQualityReport.load(options.catalogPath);

  stdout.write(report.toConsoleText());

  if (options.writeDocs) {
    File(options.coverageDocPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(report.toCoverageMarkdown(), encoding: utf8);
    File(options.bmwDocPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(report.toBmwAuditMarkdown(), encoding: utf8);
    stdout.writeln('Wrote ${options.coverageDocPath}');
    stdout.writeln('Wrote ${options.bmwDocPath}');
  }

  if (options.failOnP0 && report.p0Count > 0) {
    stderr.writeln('P0 catalog quality failures detected: ${report.p0Count}');
    exit(1);
  }
}

class _ReportOptions {
  const _ReportOptions({
    required this.catalogPath,
    required this.failOnP0,
    required this.writeDocs,
    required this.coverageDocPath,
    required this.bmwDocPath,
  });

  factory _ReportOptions.parse(List<String> args) {
    var catalogPath = 'assets/data/vehicle_catalog_kr_seed.json';
    var failOnP0 = false;
    var writeDocs = false;
    var coverageDocPath = 'docs/61_vehicle_catalog_coverage_report.md';
    var bmwDocPath = 'docs/62_bmw_catalog_audit_matrix.md';

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '--fail-on-p0':
          failOnP0 = true;
        case '--write-docs':
          writeDocs = true;
        case '--coverage-doc':
          i++;
          if (i >= args.length) {
            throw ArgumentError('--coverage-doc requires a path');
          }
          coverageDocPath = args[i];
          writeDocs = true;
        case '--bmw-doc':
          i++;
          if (i >= args.length) {
            throw ArgumentError('--bmw-doc requires a path');
          }
          bmwDocPath = args[i];
          writeDocs = true;
        default:
          if (arg.startsWith('--')) {
            throw ArgumentError('Unknown option: $arg');
          }
          catalogPath = arg;
      }
    }

    return _ReportOptions(
      catalogPath: catalogPath,
      failOnP0: failOnP0,
      writeDocs: writeDocs,
      coverageDocPath: coverageDocPath,
      bmwDocPath: bmwDocPath,
    );
  }

  final String catalogPath;
  final bool failOnP0;
  final bool writeDocs;
  final String coverageDocPath;
  final String bmwDocPath;
}

class CatalogQualityReport {
  CatalogQualityReport._({
    required this.catalogPath,
    required this.generatedAt,
    required this.manufacturers,
    required this.models,
    required this.generations,
    required this.years,
    required this.variants,
    required this.coverage,
    required this.bmwAudit,
    required this.p0Items,
  });

  factory CatalogQualityReport.load(String catalogPath) {
    final file = File(catalogPath);
    if (!file.existsSync()) {
      throw StateError('Catalog file not found: $catalogPath');
    }
    final data = jsonDecode(file.readAsStringSync(encoding: utf8))
        as Map<String, dynamic>;
    final manufacturers = _list(data, 'manufacturers');
    final models = _list(data, 'models');
    final generations = (data['generations'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final years = _list(data, 'years');
    final variants = _list(data, 'variants');

    final modelsByManufacturer = <String, List<Map<String, dynamic>>>{};
    final yearsByModel = <String, List<Map<String, dynamic>>>{};
    final variantsByYear = <String, List<Map<String, dynamic>>>{};
    final generationsByModel = <String, List<Map<String, dynamic>>>{};
    final generationIdsByYear = <String, Set<String>>{};
    final generationIdsByModel = <String, Set<String>>{};

    for (final model in models) {
      modelsByManufacturer
          .putIfAbsent(_text(model, 'manufacturer_id'), () => [])
          .add(model);
    }
    for (final year in years) {
      yearsByModel.putIfAbsent(_text(year, 'model_id'), () => []).add(year);
      final generationId = _text(year, 'generation_id');
      if (generationId.isNotEmpty) {
        generationIdsByYear.putIfAbsent(_id(year), () => {}).add(generationId);
        generationIdsByModel
            .putIfAbsent(_text(year, 'model_id'), () => {})
            .add(generationId);
      }
    }
    for (final variant in variants) {
      variantsByYear
          .putIfAbsent(_text(variant, 'model_year_id'), () => [])
          .add(variant);
    }
    for (final generation in generations) {
      final generationId = _id(generation);
      final modelId = _text(generation, 'model_id');
      generationsByModel.putIfAbsent(modelId, () => []).add(generation);
      generationIdsByModel.putIfAbsent(modelId, () => {}).add(generationId);
      for (final yearId
          in generation['model_year_ids'] as List<dynamic>? ?? const []) {
        generationIdsByYear.putIfAbsent('$yearId', () => {}).add(generationId);
      }
    }

    final p0Items = <String>[];
    void addP0(String message) => p0Items.add(message);

    for (final model in models) {
      if (_isVerifiedStatus(_text(model, 'source_status')) &&
          !_hasSource(model)) {
        addP0('Verified model has no source: ${_id(model)}');
      }
    }
    for (final generation in generations) {
      if (_isVerifiedStatus(_text(generation, 'source_status')) &&
          !_hasSource(generation)) {
        addP0('Verified generation has no source: ${_id(generation)}');
      }
    }
    for (final variant in variants) {
      final status = _text(variant, 'source_status');
      if (_isVerifiedStatus(status) && !_hasSource(variant)) {
        addP0('Verified variant has no source: ${_id(variant)}');
      }
      if (variant['is_verified'] == true &&
          (!_isVerifiedStatus(status) || !_hasSource(variant))) {
        addP0(
          'is_verified variant lacks verified source evidence: ${_id(variant)}',
        );
      }
      if (_text(variant, 'manufacturer_name') == 'BMW' &&
          !_hasSource(variant) &&
          variant['is_selectable'] == true) {
        addP0('Source-less BMW variant is selectable: ${_id(variant)}');
      }
    }

    final coverage = manufacturers.map((manufacturer) {
      final manufacturerId = _id(manufacturer);
      final manufacturerModels =
          modelsByManufacturer[manufacturerId] ?? const [];
      final modelIds = manufacturerModels.map(_id).toSet();
      final manufacturerYears = [
        for (final modelId in modelIds)
          ...(yearsByModel[modelId] ?? const <Map<String, dynamic>>[]),
      ];
      final yearIds = manufacturerYears.map(_id).toSet();
      final manufacturerVariants = [
        for (final yearId in yearIds)
          ...(variantsByYear[yearId] ?? const <Map<String, dynamic>>[]),
      ];
      final manufacturerGenerations = [
        for (final modelId in modelIds)
          ...(generationsByModel[modelId] ?? const <Map<String, dynamic>>[]),
      ];
      final modelsWithGeneration = manufacturerModels.where((model) {
        return (generationIdsByModel[_id(model)] ?? const <String>{})
            .isNotEmpty;
      }).length;
      final variantsWithGeneration = manufacturerVariants.where((variant) {
        return _variantGenerationIds(variant, generationIdsByYear).isNotEmpty;
      }).length;
      final statusCounts = _statusCounts(manufacturerVariants);
      final legacyVerifiedWithoutSource = manufacturerVariants.where((variant) {
        return variant['is_verified'] == true &&
            !_hasSource(variant) &&
            !_isVerifiedStatus(_text(variant, 'source_status'));
      }).length;

      return ManufacturerCoverage(
        manufacturerId: manufacturerId,
        nameKo: _text(manufacturer, 'name_ko'),
        sortOrder: (manufacturer['sort_order'] as num?)?.toInt() ?? 9999,
        modelCount: manufacturerModels.length,
        generationCount: manufacturerGenerations.length,
        modelYearCount: manufacturerYears.length,
        variantCount: manufacturerVariants.length,
        modelsWithGeneration: modelsWithGeneration,
        variantsWithGeneration: variantsWithGeneration,
        verifiedStatusCount: statusCounts.verified,
        pendingReviewCount: statusCounts.pendingReview,
        conflictCount: statusCounts.conflict,
        unverifiedCount: statusCounts.unverified,
        legacyVerifiedWithoutSource: legacyVerifiedWithoutSource,
      );
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final bmwManufacturer = manufacturers.firstWhere(
      (item) => _text(item, 'name_ko') == 'BMW',
      orElse: () => const <String, dynamic>{},
    );
    final bmwManufacturerId =
        bmwManufacturer.isEmpty ? 'm-bmw' : _id(bmwManufacturer);
    final bmwModels = modelsByManufacturer[bmwManufacturerId] ?? const [];
    final bmwAudit = bmwModels.map((model) {
      final modelId = _id(model);
      final modelYears = yearsByModel[modelId] ?? const [];
      final modelYearIds = modelYears.map(_id).toSet();
      final modelVariants = [
        for (final yearId in modelYearIds)
          ...(variantsByYear[yearId] ?? const <Map<String, dynamic>>[]),
      ];
      final statusCounts = _statusCounts(modelVariants);
      final yearsSorted = modelYears
          .map((item) => (item['year'] as num?)?.toInt())
          .whereType<int>()
          .toList()
        ..sort();
      final generationCount = generationsByModel[modelId]?.length ?? 0;
      final selectableWithoutSource = modelVariants.where((variant) {
        return variant['is_selectable'] == true && !_hasSource(variant);
      }).length;
      final legacyVerifiedWithoutSource = modelVariants.where((variant) {
        return variant['is_verified'] == true &&
            !_hasSource(variant) &&
            !_isVerifiedStatus(_text(variant, 'source_status'));
      }).length;

      return BmwModelAudit(
        modelId: modelId,
        modelName: _text(model, 'name_ko'),
        yearRange: yearsSorted.isEmpty
            ? '-'
            : '${yearsSorted.first}-${yearsSorted.last}',
        generationCount: generationCount,
        variantCount: modelVariants.length,
        verifiedStatusCount: statusCounts.verified,
        pendingReviewCount: statusCounts.pendingReview,
        conflictCount: statusCounts.conflict,
        unverifiedCount: statusCounts.unverified,
        selectableCount:
            modelVariants.where((item) => item['is_selectable'] == true).length,
        selectableWithoutSource: selectableWithoutSource,
        legacyVerifiedWithoutSource: legacyVerifiedWithoutSource,
      );
    }).toList()
      ..sort((a, b) => a.modelName.compareTo(b.modelName));

    return CatalogQualityReport._(
      catalogPath: catalogPath,
      generatedAt: DateTime.now().toUtc(),
      manufacturers: manufacturers,
      models: models,
      generations: generations,
      years: years,
      variants: variants,
      coverage: coverage,
      bmwAudit: bmwAudit,
      p0Items: p0Items,
    );
  }

  final String catalogPath;
  final DateTime generatedAt;
  final List<Map<String, dynamic>> manufacturers;
  final List<Map<String, dynamic>> models;
  final List<Map<String, dynamic>> generations;
  final List<Map<String, dynamic>> years;
  final List<Map<String, dynamic>> variants;
  final List<ManufacturerCoverage> coverage;
  final List<BmwModelAudit> bmwAudit;
  final List<String> p0Items;

  int get p0Count => p0Items.length;

  int get modelsWithoutGeneration =>
      coverage.fold(0, (sum, item) => sum + item.modelsWithoutGeneration);

  int get variantsWithoutGeneration =>
      coverage.fold(0, (sum, item) => sum + item.variantsWithoutGeneration);

  int get verifiedStatusCount =>
      coverage.fold(0, (sum, item) => sum + item.verifiedStatusCount);

  int get pendingReviewCount =>
      coverage.fold(0, (sum, item) => sum + item.pendingReviewCount);

  int get conflictCount =>
      coverage.fold(0, (sum, item) => sum + item.conflictCount);

  int get unverifiedCount =>
      coverage.fold(0, (sum, item) => sum + item.unverifiedCount);

  int get legacyVerifiedWithoutSource => coverage.fold(
        0,
        (sum, item) => sum + item.legacyVerifiedWithoutSource,
      );

  String toConsoleText() {
    final buffer = StringBuffer()
      ..writeln('==================================================')
      ..writeln('Vehicle Catalog Quality Report')
      ..writeln('==================================================')
      ..writeln('catalog: $catalogPath')
      ..writeln('manufacturers: ${manufacturers.length}')
      ..writeln('models: ${models.length}')
      ..writeln('generations: ${generations.length}')
      ..writeln('model years: ${years.length}')
      ..writeln('powertrains: ${variants.length}')
      ..writeln('--------------------------------------------------')
      ..writeln('source_status verified: $verifiedStatusCount')
      ..writeln('pending_review: $pendingReviewCount')
      ..writeln('conflict: $conflictCount')
      ..writeln('unverified/unknown: $unverifiedCount')
      ..writeln(
          'is_verified source policy violations: $legacyVerifiedWithoutSource')
      ..writeln('models without generation: $modelsWithoutGeneration')
      ..writeln('powertrains without generation: $variantsWithoutGeneration')
      ..writeln('P0 failures: $p0Count');
    if (p0Items.isNotEmpty) {
      buffer.writeln('--------------------------------------------------');
      for (final item in p0Items.take(20)) {
        buffer.writeln('- $item');
      }
      if (p0Items.length > 20) {
        buffer.writeln('- ... ${p0Items.length - 20} more');
      }
    }
    buffer.writeln('==================================================');
    return buffer.toString();
  }

  String toCoverageMarkdown() {
    final topMissing = coverage
        .where((item) => item.modelsWithoutGeneration > 0)
        .toList()
      ..sort((a, b) =>
          b.modelsWithoutGeneration.compareTo(a.modelsWithoutGeneration));

    final buffer = StringBuffer()
      ..writeln('# 차량 카탈로그 제조사별 Coverage 리포트')
      ..writeln()
      ..writeln('- 생성 시각(UTC): `${generatedAt.toIso8601String()}`')
      ..writeln('- 입력 파일: `$catalogPath`')
      ..writeln('- 제조사: ${manufacturers.length}개')
      ..writeln('- 모델: ${models.length}개')
      ..writeln('- 세대: ${generations.length}개')
      ..writeln('- 연식: ${years.length}개')
      ..writeln('- 파워트레인: ${variants.length}개')
      ..writeln('- P0 결함: $p0Count개')
      ..writeln()
      ..writeln('## 핵심 지표')
      ..writeln()
      ..writeln('| 항목 | 수량 |')
      ..writeln('|---|---:|')
      ..writeln('| 세대 없는 모델 | $modelsWithoutGeneration |')
      ..writeln('| generation 연결 없는 파워트레인 | $variantsWithoutGeneration |')
      ..writeln('| source_status verified | $verifiedStatusCount |')
      ..writeln('| pending_review | $pendingReviewCount |')
      ..writeln('| conflict | $conflictCount |')
      ..writeln('| unverified/unknown | $unverifiedCount |')
      ..writeln('| is_verified 출처 정책 위반 row | $legacyVerifiedWithoutSource |')
      ..writeln()
      ..writeln('## 제조사별 Coverage')
      ..writeln()
      ..writeln(
        '| 제조사 | 모델 | 세대 | 세대 연결 모델 | 세대 누락 모델 | 파워트레인 | generation 연결 누락 | verified_status | pending | conflict | unverified | verified 정책 위반 |',
      )
      ..writeln('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
    for (final item in coverage) {
      buffer.writeln(
        '| ${item.nameKo} | ${item.modelCount} | ${item.generationCount} | ${item.modelsWithGeneration} | ${item.modelsWithoutGeneration} | ${item.variantCount} | ${item.variantsWithoutGeneration} | ${item.verifiedStatusCount} | ${item.pendingReviewCount} | ${item.conflictCount} | ${item.unverifiedCount} | ${item.legacyVerifiedWithoutSource} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('## 우선 보강 대상')
      ..writeln()
      ..writeln(
        '세대 없는 모델 수 기준 상위 제조사다. 이 표는 공식 출처를 대신하지 않으며, import 대상 우선순위를 정하기 위한 현재 카탈로그 상태다.',
      )
      ..writeln()
      ..writeln('| 우선순위 | 제조사 | 세대 누락 모델 | generation 연결 없는 파워트레인 |')
      ..writeln('|---:|---|---:|---:|');
    for (var i = 0; i < topMissing.take(10).length; i++) {
      final item = topMissing[i];
      buffer.writeln(
        '| ${i + 1} | ${item.nameKo} | ${item.modelsWithoutGeneration} | ${item.variantsWithoutGeneration} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('## 판정 규칙')
      ..writeln()
      ..writeln('- 모델/세대/파워트레인은 공식 출처 없이 임의 생성하지 않는다.')
      ..writeln(
          '- `source_status=verified_official` 또는 `verified_admin`은 `source_name`, `source_url`, `source_file_name` 중 하나가 있어야 한다.')
      ..writeln(
          '- `is_verified=true`는 verified source_status와 출처가 함께 있을 때만 허용한다.')
      ..writeln('- `is_selectable=true`는 사용자 선택 가능 여부이며, 검증 완료 여부와 분리한다.')
      ..writeln(
          '- generation 연결이 없는 파워트레인은 UI 세대 선택 정확도를 보장하지 못하므로 제조사별 import backlog로 본다.');

    return buffer.toString();
  }

  String toBmwAuditMarkdown() {
    final totals = bmwAudit.fold<BmwModelAuditTotals>(
      const BmwModelAuditTotals(),
      (sum, item) => sum.add(item),
    );
    final buffer = StringBuffer()
      ..writeln('# BMW 카탈로그 감사 매트릭스')
      ..writeln()
      ..writeln('- 생성 시각(UTC): `${generatedAt.toIso8601String()}`')
      ..writeln('- 입력 파일: `$catalogPath`')
      ..writeln('- BMW 모델 row: ${bmwAudit.length}개')
      ..writeln('- BMW generation row: ${totals.generationCount}개')
      ..writeln('- BMW 파워트레인 row: ${totals.variantCount}개')
      ..writeln('- BMW selectable row: ${totals.selectableCount}개')
      ..writeln(
          '- 출처 없는 selectable BMW row: ${totals.selectableWithoutSource}개')
      ..writeln()
      ..writeln('## 모델별 상태')
      ..writeln()
      ..writeln(
        '| 모델 | 연식 범위 | 세대 | 파워트레인 | verified_status | pending | conflict | unverified | selectable | 출처 없는 selectable | verified 정책 위반 | 조치 |',
      )
      ..writeln('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|');
    for (final item in bmwAudit) {
      buffer.writeln(
        '| ${item.modelName} | ${item.yearRange} | ${item.generationCount} | ${item.variantCount} | ${item.verifiedStatusCount} | ${item.pendingReviewCount} | ${item.conflictCount} | ${item.unverifiedCount} | ${item.selectableCount} | ${item.selectableWithoutSource} | ${item.legacyVerifiedWithoutSource} | ${item.actionLabel} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('## 현재 판정')
      ..writeln()
      ..writeln(
          '- 현재 BMW 파워트레인은 공식 출처가 붙기 전까지 `pending_review`와 `is_selectable=false` 상태로 유지한다.')
      ..writeln('- source 없는 BMW row가 선택 가능해지면 P0 결함으로 본다.')
      ..writeln(
          '- BMW Korea 가격표/제원표, 한국에너지공단/환경부 공개 데이터, 또는 운영자 검수 파일이 붙은 row만 verified로 승격한다.')
      ..writeln(
          '- 1시리즈 F20/F40/F70, 2시리즈 쿠페 F22/G42, 3시리즈 F30/G20, 4시리즈 F32/G22 계열, 5시리즈 F10/G30/G60, 7시리즈 G11/G70, X1/X3/X5/X7, i4/i5/iX/iX3 세대는 연결되어 있으며, 세부 파워트레인은 공식 출처별로 재수집한 뒤 verified로 승격한다.');

    return buffer.toString();
  }
}

class ManufacturerCoverage {
  const ManufacturerCoverage({
    required this.manufacturerId,
    required this.nameKo,
    required this.sortOrder,
    required this.modelCount,
    required this.generationCount,
    required this.modelYearCount,
    required this.variantCount,
    required this.modelsWithGeneration,
    required this.variantsWithGeneration,
    required this.verifiedStatusCount,
    required this.pendingReviewCount,
    required this.conflictCount,
    required this.unverifiedCount,
    required this.legacyVerifiedWithoutSource,
  });

  final String manufacturerId;
  final String nameKo;
  final int sortOrder;
  final int modelCount;
  final int generationCount;
  final int modelYearCount;
  final int variantCount;
  final int modelsWithGeneration;
  final int variantsWithGeneration;
  final int verifiedStatusCount;
  final int pendingReviewCount;
  final int conflictCount;
  final int unverifiedCount;
  final int legacyVerifiedWithoutSource;

  int get modelsWithoutGeneration => modelCount - modelsWithGeneration;

  int get variantsWithoutGeneration => variantCount - variantsWithGeneration;
}

class BmwModelAudit {
  const BmwModelAudit({
    required this.modelId,
    required this.modelName,
    required this.yearRange,
    required this.generationCount,
    required this.variantCount,
    required this.verifiedStatusCount,
    required this.pendingReviewCount,
    required this.conflictCount,
    required this.unverifiedCount,
    required this.selectableCount,
    required this.selectableWithoutSource,
    required this.legacyVerifiedWithoutSource,
  });

  final String modelId;
  final String modelName;
  final String yearRange;
  final int generationCount;
  final int variantCount;
  final int verifiedStatusCount;
  final int pendingReviewCount;
  final int conflictCount;
  final int unverifiedCount;
  final int selectableCount;
  final int selectableWithoutSource;
  final int legacyVerifiedWithoutSource;

  String get actionLabel {
    if (selectableWithoutSource > 0) {
      return '선택 차단 필요';
    }
    if (generationCount == 0) {
      return '공식 세대 출처 수집 필요';
    }
    if (pendingReviewCount > 0 || unverifiedCount > 0) {
      return '공식 파워트레인 출처 수집 필요';
    }
    return '검수 유지';
  }
}

class BmwModelAuditTotals {
  const BmwModelAuditTotals({
    this.generationCount = 0,
    this.variantCount = 0,
    this.selectableCount = 0,
    this.selectableWithoutSource = 0,
  });

  final int generationCount;
  final int variantCount;
  final int selectableCount;
  final int selectableWithoutSource;

  BmwModelAuditTotals add(BmwModelAudit item) {
    return BmwModelAuditTotals(
      generationCount: generationCount + item.generationCount,
      variantCount: variantCount + item.variantCount,
      selectableCount: selectableCount + item.selectableCount,
      selectableWithoutSource:
          selectableWithoutSource + item.selectableWithoutSource,
    );
  }
}

class _StatusCounts {
  const _StatusCounts({
    required this.verified,
    required this.pendingReview,
    required this.conflict,
    required this.unverified,
  });

  final int verified;
  final int pendingReview;
  final int conflict;
  final int unverified;
}

_StatusCounts _statusCounts(List<Map<String, dynamic>> variants) {
  var verified = 0;
  var pendingReview = 0;
  var conflict = 0;
  var unverified = 0;
  for (final variant in variants) {
    final status = _text(variant, 'source_status');
    if (_isVerifiedStatus(status)) {
      verified++;
    } else if (status == 'pending_review') {
      pendingReview++;
    } else if (status == 'conflict') {
      conflict++;
    } else {
      unverified++;
    }
  }
  return _StatusCounts(
    verified: verified,
    pendingReview: pendingReview,
    conflict: conflict,
    unverified: unverified,
  );
}

Set<String> _variantGenerationIds(
  Map<String, dynamic> variant,
  Map<String, Set<String>> generationIdsByYear,
) {
  final direct = _text(variant, 'generation_id');
  if (direct.isNotEmpty) {
    return {direct};
  }
  return generationIdsByYear[_text(variant, 'model_year_id')] ?? const {};
}

bool _isVerifiedStatus(String status) {
  return status == 'verified_official' || status == 'verified_admin';
}

bool _hasSource(Map<String, dynamic> item) {
  return _text(item, 'source_name').isNotEmpty ||
      _text(item, 'source_url').isNotEmpty ||
      _text(item, 'source_file_name').isNotEmpty;
}

List<Map<String, dynamic>> _list(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! List) {
    throw StateError('$key is missing or not a list');
  }
  return value.cast<Map<String, dynamic>>();
}

String _id(Map<String, dynamic> item) => _text(item, 'id');

String _text(Map<String, dynamic> item, String key) {
  final value = item[key];
  if (value == null) {
    return '';
  }
  return '$value'.trim();
}
