// ignore_for_file: avoid_print, avoid_relative_lib_imports, unused_local_variable, unused_import
import 'dart:convert';
import 'dart:io';
import 'import_vehicle_catalog.dart';

void main(List<String> args) {
  final csvPath = args.isEmpty
      ? 'assets/data/vehicle_catalog_sources/manufacturer_spec_template.csv'
      : args.first;
  final file = File(csvPath);
  if (!file.existsSync()) {
    stderr.writeln('CSV 파일을 찾을 수 없습니다: $csvPath');
    exitCode = 1;
    return;
  }

  stdout.writeln('Importing Manufacturer Specs from $csvPath...');
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
    final ptype = row[5];
    final dispCc = row[6].isNotEmpty ? int.parse(row[6]) : null;
    final batKwh = row[7].isNotEmpty ? double.parse(row[7]) : null;
    final drivetrain = row[8];
    final transmission = row[9];
    final motorPower = row[10].isNotEmpty ? double.parse(row[10]) : null;
    final rangeKm = row[11].isNotEmpty ? double.parse(row[11]) : null;
    final efficiency = row[12].isNotEmpty ? double.parse(row[12]) : null;
    final unit = row[13];
    final vehicleClass = row[14];
    final sourceUrl = row[15];

    final modelSlug =
        model.toLowerCase().replaceAll(' ', '-').replaceAll('.', '-');
    final league = fuelType == '전기차' ? 'electric' : 'gasoline';
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
      sourceName: '$manufacturer 공식 제원표',
      sourceUrl: sourceUrl,
      confidence: 0.9, // 제조사 공식 제원
      overwrite: false, // 충돌 시 덮어쓰지 않고 conflict 처리
    );
    importedCount++;
  }

  VehicleCatalogManager.saveCatalog(catalog);
  stdout.writeln(
      'Successfully imported $importedCount variants from Manufacturer Specs.');
}
