import 'vehicle_powertrain_taxonomy.dart';
import 'fuel_type_normalizer.dart';

class PowertrainValidationError {
  const PowertrainValidationError(this.field, this.message);
  final String field;
  final String message;

  @override
  String toString() => '$field: $message';
}

class PowertrainValidator {
  /// 파워트레인 데이터의 제원 무결성을 실시간 검증
  static List<PowertrainValidationError> validate({
    required String fuelTypeRaw,
    String? powertrainTypeRaw,
    int? displacementCc,
    double? batteryKwh,
    double? officialEfficiency,
    required String efficiencyUnitRaw,
    required String fuelLeagueRaw,
    String? vehicleClass,
    String? sourceStatusRaw,
    String? sourceName,
    double? confidenceScore,
  }) {
    final errors = <PowertrainValidationError>[];

    final fuelType = FuelTypeNormalizer.normalizeFuelType(fuelTypeRaw);
    final powertrainType =
        FuelTypeNormalizer.normalizePowertrainType(powertrainTypeRaw, fuelType);
    final unit = EfficiencyUnit.fromKey(efficiencyUnitRaw);
    final league = FuelLeague.fromKey(fuelLeagueRaw);
    final status = SourceStatus.fromKey(sourceStatusRaw);

    // 1. 차급(vehicleClass) 검증
    if (vehicleClass == null || vehicleClass.trim().isEmpty) {
      errors.add(const PowertrainValidationError(
          'vehicle_class', '차급(vehicleClass) 정보는 필수입니다.'));
    }

    // 2. 전기차(electric) 검증 규칙
    if (fuelType == FuelType.electric) {
      if (unit != EfficiencyUnit.kmPerKwh) {
        errors.add(const PowertrainValidationError(
            'efficiency_unit', '전기차의 효율 단위는 km/kWh 여야 합니다.'));
      }
      if (displacementCc != null && displacementCc > 0) {
        errors.add(const PowertrainValidationError(
            'displacement_cc', '전기차는 배기량(displacement_cc)을 가질 수 없습니다.'));
      }
      if (league != FuelLeague.electric) {
        errors.add(const PowertrainValidationError(
            'fuel_league', '전기차는 electric 리그에 배정되어야 합니다.'));
      }
    }

    // 3. 수소차(hydrogen) 검증 규칙
    if (fuelType == FuelType.hydrogen) {
      if (unit != EfficiencyUnit.kmPerKg) {
        errors.add(const PowertrainValidationError(
            'efficiency_unit', '수소차의 효율 단위는 km/kg 이여야 합니다.'));
      }
      if (displacementCc != null && displacementCc > 0) {
        errors.add(const PowertrainValidationError(
            'displacement_cc', '수소차는 배기량을 가질 수 없습니다.'));
      }
      if (league != FuelLeague.hydrogen) {
        errors.add(const PowertrainValidationError(
            'fuel_league', '수소차는 hydrogen 리그에 배정되어야 합니다.'));
      }
    }

    // 4. 일반 내연기관/하이브리드/LPG 검증 규칙
    if (fuelType == FuelType.gasoline ||
        fuelType == FuelType.diesel ||
        fuelType == FuelType.hybrid ||
        fuelType == FuelType.lpg) {
      if (unit != EfficiencyUnit.kmPerLiter) {
        errors.add(const PowertrainValidationError(
            'efficiency_unit', '내연기관, 하이브리드, LPG의 효율 단위는 km/L 여야 합니다.'));
      }
      if (displacementCc == null || displacementCc <= 0) {
        errors.add(const PowertrainValidationError(
            'displacement_cc', '내연기관/하이브리드 차량은 배기량 정보가 필요합니다.'));
      }

      // 배터리가 있는 순수 가솔린차 충돌 검증
      if (fuelType == FuelType.gasoline &&
          batteryKwh != null &&
          batteryKwh > 0) {
        errors.add(const PowertrainValidationError('battery_kwh',
            '하이브리드가 아닌 순수 가솔린 차량은 배터리 용량(battery_kwh)을 가질 수 없습니다.'));
      }
    }

    // 5. 플러그인 하이브리드(PHEV) 특화 규칙
    if (fuelType == FuelType.plugInHybrid) {
      if (powertrainType != PowertrainType.plugInHybrid) {
        errors.add(const PowertrainValidationError('powertrain_type',
            '플러그인 하이브리드는 powertrain_type도 plug_in_hybrid 여야 합니다.'));
      }
      // PHEV는 연비(km/L)와 전비(km/kWh)가 복합 구성되나, 플랫폼 기본 리그 연비 단위 규격을 통제
    }

    // 6. 리그 배정과 연료 타입 매칭성 검증
    final expectedLeague = FuelTypeNormalizer.determineFuelLeague(fuelType);
    if (expectedLeague != league && fuelType != FuelType.unknown) {
      errors.add(PowertrainValidationError('fuel_league',
          '연료 타입(${fuelType.displayName})에 맞지 않는 리그(${league.displayName})에 배정되었습니다.'));
    }

    // 7. 공식 효율 수치(officialEfficiency) 0 정규화 알림
    if (officialEfficiency != null && officialEfficiency <= 0) {
      errors.add(const PowertrainValidationError(
          'official_efficiency', '공식 효율 수치는 0보다 커야 합니다. 없을 시 null이어야 합니다.'));
    }

    // 8. 신뢰 및 출처 검증 규칙
    if (status == SourceStatus.verifiedOfficial ||
        status == SourceStatus.verifiedAdmin) {
      if (sourceName == null || sourceName.trim().isEmpty) {
        errors.add(const PowertrainValidationError(
            'source_name', '검증된 공식 데이터(verified)는 반드시 출처 명칭이 있어야 합니다.'));
      }
      final score = confidenceScore ?? 0.0;
      if (score < 0.8 && status == SourceStatus.verifiedOfficial) {
        errors.add(const PowertrainValidationError('confidence_score',
            '매칭 신뢰도(confidence_score)가 0.8 미만인 데이터는 verified_official로 지정할 수 없습니다.'));
      }
    }

    return errors;
  }
}
