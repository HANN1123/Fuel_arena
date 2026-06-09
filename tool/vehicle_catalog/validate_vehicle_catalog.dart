// ignore_for_file: avoid_print, avoid_relative_lib_imports, unused_local_variable, unused_import
import 'dart:convert';
import 'dart:io';

// 도메인 유효성 및 정합성 검증 엔진 결합
import '../../lib/features/vehicle/domain/vehicle_powertrain_taxonomy.dart';
import '../../lib/features/vehicle/domain/powertrain_validator.dart';
import '../../lib/features/vehicle/domain/vehicle_catalog_integrity_validator.dart';
import '../../lib/shared/models/fuel_arena_models.dart';

void main(List<String> args) {
  final path = args.isEmpty ? 'assets/data/vehicle_catalog_kr_seed.json' : args.first;
  try {
    runValidation(path);
  } catch (e) {
    stderr.writeln(e);
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

  final manufacturersRaw = data['manufacturers'] as List<dynamic>;
  final modelsRaw = data['models'] as List<dynamic>;
  final yearsRaw = data['years'] as List<dynamic>;
  final variantsRaw = data['variants'] as List<dynamic>;

  final manufacturers = manufacturersRaw.map((m) => VehicleManufacturer.fromJson(m as Map<String, dynamic>)).toList();
  final models = modelsRaw.map((m) => VehicleModel.fromJson(m as Map<String, dynamic>)).toList();
  final years = yearsRaw.map((y) => VehicleModelYear.fromJson(y as Map<String, dynamic>)).toList();
  final variants = variantsRaw.map((v) => VehicleVariant.fromJson(v as Map<String, dynamic>)).toList();

  var p0Failures = 0;
  final List<String> errorMessages = [];

  // 1. 전체 계층 정합성(Integrity) 검증
  final integrityFailures = VehicleCatalogIntegrityValidator.validateCatalog(
    manufacturers: manufacturers,
    models: models,
    years: years,
    variants: variants,
  );

  if (integrityFailures.isNotEmpty) {
    errorMessages.add('[INTEGRITY ERROR] 계층 구조 오류가 발견되었습니다:');
    for (final f in integrityFailures) {
      errorMessages.add('  - $f');
      p0Failures++;
    }
  }

  // 2. 개별 파워트레인(Variant) 검증 규칙 진단
  for (final v in variantsRaw) {
    final vMap = v as Map<String, dynamic>;
    final id = vMap['id'] as String;

    final errors = PowertrainValidator.validate(
      fuelTypeRaw: vMap['fuel_type'] as String,
      powertrainTypeRaw: vMap['powertrain_type'] as String?,
      displacementCc: vMap['displacement_cc'] as int?,
      batteryKwh: vMap['battery_kwh'] != null ? (vMap['battery_kwh'] as num).toDouble() : null,
      officialEfficiency: vMap['official_efficiency'] != null ? (vMap['official_efficiency'] as num).toDouble() : null,
      efficiencyUnitRaw: vMap['efficiency_unit'] as String? ?? 'km/L',
      fuelLeagueRaw: vMap['fuel_league'] as String,
      vehicleClass: vMap['vehicle_class'] as String,
      sourceStatusRaw: vMap['source_status'] as String?,
      sourceName: vMap['source_name'] as String?,
      confidenceScore: vMap['confidence_score'] != null ? (vMap['confidence_score'] as num).toDouble() : null,
    );

    if (errors.isNotEmpty) {
      errorMessages.add('[VALIDATION ERROR] Variant ID: $id 가 도메인 규칙을 위반했습니다:');
      for (final err in errors) {
        errorMessages.add('  - $err');
        p0Failures++;
      }
    }

    // 포르쉐 FWD 오류 감지 (P0 품질 기준 통제)
    final manufacturerName = vMap['manufacturer_name'] as String? ?? '';
    final modelName = vMap['model_name'] as String? ?? '';
    final drivetrain = vMap['drivetrain'] as String? ?? '';
    if (manufacturerName == '포르쉐' && modelName == '박스터' && drivetrain == 'FWD') {
      errorMessages.add('[P0 DATA ERROR] 포르쉐 박스터는 FWD 일 수 없습니다: $id');
      p0Failures++;
    }
  }

  if (p0Failures > 0) {
    throw Exception('Validation FAILED: $p0Failures개의 P0 결함이 감지되었습니다.\n${errorMessages.join('\n')}');
  }

  stdout.writeln('Validation SUCCESS: ${manufacturers.length} manufacturers, ${models.length} models, ${years.length} years, ${variants.length} variants.');
}
