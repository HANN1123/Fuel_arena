import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final options = GenerationImportOptions.parse(args);
  final result = runGenerationImport(options);
  stdout
    ..writeln('Vehicle generation import completed.')
    ..writeln('catalog: ${options.catalogPath}')
    ..writeln('generation csv: ${options.generationCsvPath}')
    ..writeln('powertrain csv: ${options.powertrainCsvPath ?? '-'}')
    ..writeln('dry run: ${options.dryRun}')
    ..writeln('inserted generations: ${result.insertedGenerations}')
    ..writeln('updated generations: ${result.updatedGenerations}')
    ..writeln('linked model years: ${result.linkedModelYears}')
    ..writeln('linked variants: ${result.linkedVariants}')
    ..writeln('powertrain links: ${result.powertrainLinks}');
  if (result.warnings.isNotEmpty) {
    stdout.writeln('warnings:');
    for (final warning in result.warnings) {
      stdout.writeln('- $warning');
    }
  }
}

GenerationImportResult runGenerationImport(GenerationImportOptions options) {
  final catalogFile = File(options.catalogPath);
  if (!catalogFile.existsSync()) {
    throw StateError('Catalog file not found: ${options.catalogPath}');
  }
  final catalog = jsonDecode(catalogFile.readAsStringSync(encoding: utf8))
      as Map<String, dynamic>;

  final manufacturers = _list(catalog, 'manufacturers');
  final models = _list(catalog, 'models');
  final generations = (catalog['generations'] as List<dynamic>? ?? <dynamic>[]);
  catalog['generations'] = generations;
  final years = _list(catalog, 'years');
  final variants = _list(catalog, 'variants');

  final manufacturersByName = {
    for (final manufacturer in manufacturers)
      _text(manufacturer, 'name_ko'): manufacturer,
  };
  final modelsByManufacturerAndName = {
    for (final model in models)
      '${_text(model, 'manufacturer_id')}|${_text(model, 'name_ko')}': model,
  };
  final yearsByModel = <String, List<Map<String, dynamic>>>{};
  final variantsByYear = <String, List<Map<String, dynamic>>>{};
  for (final year in years) {
    yearsByModel.putIfAbsent(_text(year, 'model_id'), () => []).add(year);
  }
  for (final variant in variants) {
    variantsByYear
        .putIfAbsent(_text(variant, 'model_year_id'), () => [])
        .add(variant);
  }

  var insertedGenerations = 0;
  var updatedGenerations = 0;
  var linkedModelYears = 0;
  var linkedVariants = 0;
  final warnings = <String>[];

  final generationRows = _readCsv(options.generationCsvPath);
  for (final row in generationRows) {
    final manufacturerName = _required(row, 'manufacturer_name');
    final modelName = _required(row, 'model_name');
    final manufacturer = manufacturersByName[manufacturerName];
    if (manufacturer == null) {
      throw StateError('Unknown manufacturer: $manufacturerName');
    }
    final model =
        modelsByManufacturerAndName['${_text(manufacturer, 'id')}|$modelName'];
    if (model == null) {
      throw StateError('Unknown model: $manufacturerName $modelName');
    }

    final sourceStatus = row['source_status']?.trim().isEmpty ?? true
        ? 'unverified'
        : row['source_status']!.trim();
    if (_isVerifiedStatus(sourceStatus) && !_rowHasSource(row)) {
      throw StateError(
        'verified generation must include source_name/source_url/source_file_name: $manufacturerName $modelName',
      );
    }

    final modelId = _text(model, 'id');
    final generation = _findGeneration(
          generations,
          modelId: modelId,
          generationCode: row['generation_code'] ?? '',
          generationNameKo: row['generation_name_ko'] ?? '',
        ) ??
        <String, dynamic>{'id': _buildGenerationId(model, row)};
    final isInsert = !generations.contains(generation);
    if (isInsert) {
      generations.add(generation);
      insertedGenerations++;
    } else {
      updatedGenerations++;
    }

    final selectableCell = row['is_selectable']?.trim();
    final isSelectable = selectableCell == null || selectableCell.isEmpty
        ? sourceStatus != 'deprecated'
        : _bool(selectableCell);

    generation
      ..['model_id'] = modelId
      ..['generation_order'] = _intOrNull(row['generation_order'])
      ..['generation_name_ko'] = _required(row, 'generation_name_ko')
      ..['generation_name_en'] = row['generation_name_en']?.trim()
      ..['generation_code'] = row['generation_code']?.trim()
      ..['platform_code'] = row['platform_code']?.trim()
      ..['start_year'] = _intOrNull(row['start_year'])
      ..['start_month'] = _intOrNull(row['start_month'])
      ..['end_year'] = _intOrNull(row['end_year'])
      ..['end_month'] = _intOrNull(row['end_month'])
      ..['display_period'] = row['display_period']?.trim()
      ..['is_current'] = _bool(row['is_current'])
      ..['is_upcoming'] = _bool(row['is_upcoming'])
      ..['market_region'] = row['market_region']?.trim().isEmpty ?? true
          ? 'KR'
          : row['market_region']!.trim()
      ..['source_name'] = _emptyToNull(row['source_name'])
      ..['source_url'] = _emptyToNull(row['source_url'])
      ..['source_status'] = sourceStatus
      ..['confidence_score'] = _doubleOrNull(row['confidence_score']) ?? 0.0
      ..['is_selectable'] = isSelectable
      ..['is_deprecated'] = sourceStatus == 'deprecated';

    final modelYearStartYear = _intOrNull(row['model_year_start_year']) ??
        (generation['start_year'] as int?);
    final modelYearEndYear = _intOrNull(row['model_year_end_year']) ??
        (generation['end_year'] as int?);
    final selectedYears = _selectModelYears(
      yearsByModel[modelId] ?? const <Map<String, dynamic>>[],
      startYear: modelYearStartYear,
      endYear: modelYearEndYear,
    );
    final modelYearIds = selectedYears.map((item) => _text(item, 'id')).toSet();
    final existingModelYearIds =
        (generation['model_year_ids'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .toSet();
    generation['model_year_ids'] = {...existingModelYearIds, ...modelYearIds}
        .where((item) => item.isNotEmpty)
        .toList()
      ..sort();

    for (final year in selectedYears) {
      if (year['generation_id'] != generation['id']) {
        year['generation_id'] = generation['id'];
        year['production_year_label'] = generation['display_period'];
        linkedModelYears++;
      }
      for (final variant in variantsByYear[_text(year, 'id')] ??
          const <Map<String, dynamic>>[]) {
        if (variant['generation_id'] != generation['id']) {
          variant['generation_id'] = generation['id'];
          linkedVariants++;
        }
      }
    }
  }

  var powertrainLinks = 0;
  if (options.powertrainCsvPath != null) {
    for (final row in _readCsv(options.powertrainCsvPath!)) {
      final generationId = row['generation_id']?.trim();
      if (generationId == null || generationId.isEmpty) {
        warnings.add('powertrain row skipped because generation_id is empty');
        continue;
      }
      final generationExists = generations.any(
        (generation) =>
            _text(generation as Map<String, dynamic>, 'id') == generationId,
      );
      if (!generationExists) {
        throw StateError(
            'Unknown generation_id in powertrain CSV: $generationId');
      }
      final matches = _matchPowertrainRows(
        variants,
        years,
        manufacturer: _required(row, 'manufacturer'),
        model: _required(row, 'model'),
        year: _intOrNull(row['year']),
        trimName: _required(row, 'trim_name'),
        fuelType: _required(row, 'fuel_type'),
        displacementCc: _intOrNull(row['displacement_cc']),
        batteryKwh: _doubleOrNull(row['battery_kwh']),
        transmission: row['transmission']?.trim(),
      );
      if (matches.isEmpty) {
        throw StateError(
          'No variant matched powertrain generation row: ${row.values.join(' / ')}',
        );
      }
      for (final variant in matches) {
        variant
          ..['generation_id'] = generationId
          ..['valid_from_year'] = _intOrNull(row['valid_from_year'])
          ..['valid_to_year'] = _intOrNull(row['valid_to_year']);
        powertrainLinks++;
      }
    }
  }

  if (!options.dryRun) {
    catalog['generated_at'] = DateTime.now().toUtc().toIso8601String();
    catalogFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(catalog),
      encoding: utf8,
    );
  }

  return GenerationImportResult(
    insertedGenerations: insertedGenerations,
    updatedGenerations: updatedGenerations,
    linkedModelYears: linkedModelYears,
    linkedVariants: linkedVariants,
    powertrainLinks: powertrainLinks,
    warnings: warnings,
  );
}

class GenerationImportOptions {
  const GenerationImportOptions({
    required this.catalogPath,
    required this.generationCsvPath,
    this.powertrainCsvPath,
    this.dryRun = false,
  });

  factory GenerationImportOptions.parse(List<String> args) {
    var catalogPath = 'assets/data/vehicle_catalog_kr_seed.json';
    var generationCsvPath =
        'assets/data/vehicle_catalog_sources/generation_template.csv';
    String? powertrainCsvPath;
    var dryRun = false;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '--catalog':
          catalogPath = _nextArg(args, ++i, '--catalog');
        case '--generations':
          generationCsvPath = _nextArg(args, ++i, '--generations');
        case '--powertrains':
          powertrainCsvPath = _nextArg(args, ++i, '--powertrains');
        case '--dry-run':
          dryRun = true;
        default:
          throw ArgumentError('Unknown option: $arg');
      }
    }

    return GenerationImportOptions(
      catalogPath: catalogPath,
      generationCsvPath: generationCsvPath,
      powertrainCsvPath: powertrainCsvPath,
      dryRun: dryRun,
    );
  }

  final String catalogPath;
  final String generationCsvPath;
  final String? powertrainCsvPath;
  final bool dryRun;
}

class GenerationImportResult {
  const GenerationImportResult({
    required this.insertedGenerations,
    required this.updatedGenerations,
    required this.linkedModelYears,
    required this.linkedVariants,
    required this.powertrainLinks,
    required this.warnings,
  });

  final int insertedGenerations;
  final int updatedGenerations;
  final int linkedModelYears;
  final int linkedVariants;
  final int powertrainLinks;
  final List<String> warnings;
}

List<Map<String, dynamic>> _matchPowertrainRows(
  List<Map<String, dynamic>> variants,
  List<Map<String, dynamic>> years, {
  required String manufacturer,
  required String model,
  required int? year,
  required String trimName,
  required String fuelType,
  required int? displacementCc,
  required double? batteryKwh,
  required String? transmission,
}) {
  final yearById = {for (final item in years) _text(item, 'id'): item};
  return variants.where((variant) {
    final variantYear = yearById[_text(variant, 'model_year_id')];
    if (_text(variant, 'manufacturer_name') != manufacturer ||
        _text(variant, 'model_name') != model ||
        _text(variant, 'trim_name') != trimName ||
        _text(variant, 'fuel_type') != fuelType) {
      return false;
    }
    if (year != null && (variantYear?['year'] as num?)?.toInt() != year) {
      return false;
    }
    if (displacementCc != null &&
        variant['displacement_cc'] != displacementCc) {
      return false;
    }
    if (batteryKwh != null && variant['battery_kwh'] != batteryKwh) {
      return false;
    }
    if (transmission != null &&
        transmission.isNotEmpty &&
        _text(variant, 'transmission') != transmission) {
      return false;
    }
    return true;
  }).toList();
}

List<Map<String, dynamic>> _selectModelYears(
  List<Map<String, dynamic>> years, {
  required int? startYear,
  required int? endYear,
}) {
  return years.where((year) {
    final value = (year['year'] as num?)?.toInt();
    if (value == null) {
      return false;
    }
    if (startYear != null && value < startYear) {
      return false;
    }
    if (endYear != null && value > endYear) {
      return false;
    }
    return true;
  }).toList();
}

Map<String, dynamic>? _findGeneration(
  List<dynamic> generations, {
  required String modelId,
  required String generationCode,
  required String generationNameKo,
}) {
  final code = generationCode.trim();
  final name = generationNameKo.trim();
  for (final generation in generations.cast<Map<String, dynamic>>()) {
    if (_text(generation, 'model_id') != modelId) {
      continue;
    }
    if (code.isNotEmpty && _text(generation, 'generation_code') == code) {
      return generation;
    }
    if (name.isNotEmpty && _text(generation, 'generation_name_ko') == name) {
      return generation;
    }
  }
  return null;
}

String _buildGenerationId(Map<String, dynamic> model, Map<String, String> row) {
  final modelToken = _text(model, 'id').replaceFirst('model-', '');
  final sourceToken = _slug(row['generation_code']) ??
      _slug(row['generation_name_en']) ??
      (row['source_status'] == 'pending_review' ? 'review' : null) ??
      'generation';
  return 'generation-$modelToken-$sourceToken';
}

String? _slug(String? value) {
  final normalized = (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? null : normalized;
}

List<Map<String, String>> _readCsv(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('CSV file not found: $path');
  }
  final lines = file.readAsLinesSync(encoding: utf8);
  if (lines.isEmpty) {
    return const [];
  }
  final headers = _parseCsvLine(lines.first);
  return [
    for (final line in lines.skip(1))
      if (line.trim().isNotEmpty)
        {
          for (var i = 0; i < headers.length; i++)
            headers[i]:
                i < _parseCsvLine(line).length ? _parseCsvLine(line)[i] : '',
        },
  ];
}

List<String> _parseCsvLine(String line) {
  final cells = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        buffer.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      cells.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  cells.add(buffer.toString());
  return cells;
}

List<Map<String, dynamic>> _list(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! List) {
    throw StateError('$key is missing or not a list');
  }
  return value.cast<Map<String, dynamic>>();
}

String _required(Map<String, String> row, String key) {
  final value = row[key]?.trim() ?? '';
  if (value.isEmpty) {
    throw StateError('$key is required in CSV row: $row');
  }
  return value;
}

String _nextArg(List<String> args, int index, String option) {
  if (index >= args.length) {
    throw ArgumentError('$option requires a value');
  }
  return args[index];
}

bool _isVerifiedStatus(String status) {
  return status == 'verified_official' || status == 'verified_admin';
}

bool _rowHasSource(Map<String, String> row) {
  return (row['source_name']?.trim().isNotEmpty ?? false) ||
      (row['source_url']?.trim().isNotEmpty ?? false) ||
      (row['source_file_name']?.trim().isNotEmpty ?? false);
}

bool _bool(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

int? _intOrNull(String? value) {
  final normalized = (value ?? '').trim();
  return normalized.isEmpty ? null : int.parse(normalized);
}

double? _doubleOrNull(String? value) {
  final normalized = (value ?? '').trim();
  return normalized.isEmpty ? null : double.parse(normalized);
}

String? _emptyToNull(String? value) {
  final normalized = (value ?? '').trim();
  return normalized.isEmpty ? null : normalized;
}

String _text(Map<String, dynamic> item, String key) {
  final value = item[key];
  return value == null ? '' : '$value'.trim();
}
