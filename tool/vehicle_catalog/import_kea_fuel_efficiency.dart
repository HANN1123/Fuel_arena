// ignore_for_file: avoid_print, avoid_relative_lib_imports, unused_local_variable, unused_import
import 'dart:convert';
import 'dart:io';
import 'import_vehicle_catalog.dart';

void main(List<String> args) {
  final csvPath = args.isEmpty
      ? 'assets/data/vehicle_catalog_sources/kea_fuel_efficiency_sample.csv'
      : args.first;
  final file = File(csvPath);
  if (!file.existsSync()) {
    stderr.writeln('CSV 파일을 찾을 수 없습니다: $csvPath');
    exitCode = 1;
    return;
  }

  stdout.writeln('Importing KEA Fuel Efficiency from $csvPath...');
  final lines = file.readAsLinesSync(encoding: utf8);
  if (lines.isEmpty) return;

  final headers = lines.first.split(',');
  final catalog = VehicleCatalogManager.loadCatalog();

  var importedCount = 0;

  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final row = line.split(',');

    final manufacturer = row[0];
    final model = row[1];
    final year = int.parse(row[2]);
    final trimName = row[3];
    final fuelType = row[4];
    final dispCc = row[5].isNotEmpty ? int.parse(row[5]) : null;
    final batKwh = row[6].isNotEmpty ? double.parse(row[6]) : null;
    final drivetrain = row[7];
    final transmission = row[8];
    final efficiency = row[9].isNotEmpty ? double.parse(row[9]) : null;
    final unit = row[12];
    final vehicleClass = row[13];
    final sourceUrl = row[14];

    // ID 규칙 생성 (slug 체계 반영)
    final modelSlug = model.toLowerCase().replaceAll(' ', '-').replaceAll('.', '-');
    final league = fuelType == '전기차' ? 'electric' : (fuelType == '하이브리드' ? 'hybrid' : 'gasoline');
    final variantId = 'variant-$manufacturer-$modelSlug-$year-$league';

    final newVariant = {
      'id': variantId,
      'model_year_id': 'year-$manufacturer-$modelSlug-$year',
      'manufacturer_name': manufacturer,
      'model_name': model,
      'year': year,
      'trim_name': trimName,
      'engine_name': '',
      'fuel_type': fuelType,
      'displacement_cc': dispCc,
      'battery_kwh': batKwh,
      'drivetrain': drivetrain,
      'transmission': transmission,
      'official_efficiency': efficiency,
      'efficiency_unit': unit,
      'vehicle_class': vehicleClass,
      'fuel_league': league,
      'is_verified': true,
      'sort_order': 10,
    };

    VehicleCatalogManager.mergeVariant(
      catalog,
      newVariant,
      sourceName: '한국에너지공단 연비 공공 데이터',
      sourceUrl: sourceUrl,
      confidence: 1.0,
      overwrite: true,
    );
    importedCount++;
  }

  VehicleCatalogManager.saveCatalog(catalog);
  stdout.writeln('Successfully imported $importedCount variants from KEA Fuel Efficiency.');
}
