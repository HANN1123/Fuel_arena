import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_arena/features/vehicle/domain/vehicle_powertrain_taxonomy.dart';
import 'package:fuel_arena/features/vehicle/domain/fuel_type_normalizer.dart';
import 'package:fuel_arena/features/vehicle/domain/powertrain_validator.dart';
import 'package:fuel_arena/features/vehicle/domain/fuel_efficiency_formatter.dart';

void main() {
  group('FuelTypeNormalizer Tests', () {
    test('Should normalize fuel type keys correctly', () {
      expect(FuelTypeNormalizer.normalizeFuelType('가솔린'), FuelType.gasoline);
      expect(FuelTypeNormalizer.normalizeFuelType('디젤'), FuelType.diesel);
      expect(FuelTypeNormalizer.normalizeFuelType('하이브리드'), FuelType.hybrid);
      expect(FuelTypeNormalizer.normalizeFuelType('전기'), FuelType.electric);
      expect(
          FuelTypeNormalizer.normalizeFuelType('electric'), FuelType.electric);
      expect(FuelTypeNormalizer.normalizeFuelType('LPG'), FuelType.lpg);
      expect(FuelTypeNormalizer.normalizeFuelType('수소차'), FuelType.hydrogen);
      expect(FuelTypeNormalizer.normalizeFuelType('invalid'), FuelType.unknown);
    });

    test('Should determine fuel leagues properly', () {
      expect(FuelTypeNormalizer.determineFuelLeague(FuelType.gasoline),
          FuelLeague.gasoline);
      expect(FuelTypeNormalizer.determineFuelLeague(FuelType.electric),
          FuelLeague.electric);
      expect(FuelTypeNormalizer.determineFuelLeague(FuelType.hybrid),
          FuelLeague.hybrid);
      expect(FuelTypeNormalizer.determineFuelLeague(FuelType.unknown),
          FuelLeague.other);
    });
  });

  group('PowertrainValidator Tests', () {
    test('Should pass for valid gasoline configuration', () {
      final errors = PowertrainValidator.validate(
        fuelTypeRaw: 'gasoline',
        displacementCc: 1598,
        efficiencyUnitRaw: 'km_per_liter',
        fuelLeagueRaw: 'gasoline',
        vehicleClass: '준중형',
        sourceStatusRaw: 'verified_official',
        sourceName: 'KEA 연비',
        confidenceScore: 0.95,
      );
      expect(errors.isEmpty, true);
    });

    test('Should flag EV with engine displacement as P0 violation', () {
      final errors = PowertrainValidator.validate(
        fuelTypeRaw: 'electric',
        displacementCc: 1598, // Violation: EV cannot have engine CC
        efficiencyUnitRaw: 'km_per_kwh',
        fuelLeagueRaw: 'electric',
        vehicleClass: '준중형',
        sourceStatusRaw: 'verified_official',
        sourceName: 'KEA 연비',
        confidenceScore: 0.95,
      );
      expect(errors.any((e) => e.field == 'displacement_cc'), true);
    });

    test('Should flag ICE vehicle with incorrect fuel efficiency unit', () {
      final errors = PowertrainValidator.validate(
        fuelTypeRaw: 'gasoline',
        displacementCc: 1998,
        efficiencyUnitRaw: 'km_per_kwh', // Violation: should be km/L
        fuelLeagueRaw: 'gasoline',
        vehicleClass: '중형',
        sourceStatusRaw: 'imported_public',
      );
      expect(errors.any((e) => e.field == 'efficiency_unit'), true);
    });

    test('Should require source name for official/admin verified data', () {
      final errors = PowertrainValidator.validate(
        fuelTypeRaw: 'gasoline',
        displacementCc: 1998,
        efficiencyUnitRaw: 'km_per_liter',
        fuelLeagueRaw: 'gasoline',
        vehicleClass: '중형',
        sourceStatusRaw: 'verified_official',
        sourceName: '', // Violation: source name required for verified
        confidenceScore: 0.85,
      );
      expect(errors.any((e) => e.field == 'source_name'), true);
    });

    test('Should flag low confidence score on verified official data', () {
      final errors = PowertrainValidator.validate(
        fuelTypeRaw: 'gasoline',
        displacementCc: 1998,
        efficiencyUnitRaw: 'km_per_liter',
        fuelLeagueRaw: 'gasoline',
        vehicleClass: '중형',
        sourceStatusRaw: 'verified_official',
        sourceName: '공식 제원',
        confidenceScore: 0.6, // Violation: confidence score must be >= 0.8
      );
      expect(errors.any((e) => e.field == 'confidence_score'), true);
    });
  });

  group('FuelEfficiencyFormatter Tests', () {
    test('Should format correct efficiency values with units', () {
      expect(
        FuelEfficiencyFormatter.format(
            efficiency: 15.6, unitRaw: 'km_per_liter'),
        '15.6 km/L',
      );
      expect(
        FuelEfficiencyFormatter.format(efficiency: 4.2, unitRaw: 'km_per_kwh'),
        '4.2 km/kWh',
      );
    });

    test('Should render fallback text for missing/null efficiency', () {
      expect(
        FuelEfficiencyFormatter.format(
            efficiency: null, unitRaw: 'km_per_liter'),
        '공식 효율 정보 준비 중',
      );
      expect(
        FuelEfficiencyFormatter.format(
            efficiency: 0.0, unitRaw: 'km_per_liter'),
        '공식 효율 정보 준비 중',
      );
    });
  });
}
