import 'vehicle_powertrain_taxonomy.dart';

class FuelTypeNormalizer {
  /// 문자열 입력으로부터 표준 [FuelType]를 정규화하여 반환
  static FuelType normalizeFuelType(String? raw) {
    if (raw == null || raw.trim().isEmpty) return FuelType.unknown;
    final value = raw.trim().toLowerCase();

    if (value.contains('가솔린') ||
        value.contains('휘발유') ||
        value == 'gasoline' ||
        value == 'gas') {
      return FuelType.gasoline;
    }
    if (value.contains('디젤') || value.contains('경유') || value == 'diesel') {
      return FuelType.diesel;
    }
    if (value.contains('플러그인') ||
        value == 'phev' ||
        value == 'plug_in_hybrid' ||
        value == 'plugin_hybrid') {
      return FuelType.plugInHybrid;
    }
    if (value.contains('하이브리드') || value == 'hybrid' || value == 'hev') {
      return FuelType.hybrid;
    }
    if (value.contains('전기차') ||
        value.contains('전기') ||
        value == 'electric' ||
        value == 'ev') {
      return FuelType.electric;
    }
    if (value.contains('lpg') ||
        value.contains('lpi') ||
        value == 'lpg' ||
        value == 'lpi') {
      return FuelType.lpg;
    }
    if (value.contains('수소차') ||
        value.contains('수소') ||
        value == 'hydrogen' ||
        value == 'fcev') {
      return FuelType.hydrogen;
    }
    return FuelType.unknown;
  }

  /// 문자열 입력으로부터 표준 [PowertrainType]를 정규화하여 반환
  static PowertrainType normalizePowertrainType(
      String? raw, FuelType fuelType) {
    if (raw == null || raw.trim().isEmpty) {
      // fuelType 기반 추론
      return switch (fuelType) {
        FuelType.gasoline || FuelType.diesel => PowertrainType.ice,
        FuelType.hybrid => PowertrainType.hybrid,
        FuelType.plugInHybrid => PowertrainType.plugInHybrid,
        FuelType.electric => PowertrainType.batteryElectric,
        FuelType.lpg => PowertrainType.lpg,
        FuelType.hydrogen => PowertrainType.fuelCell,
        FuelType.other => PowertrainType.other,
        _ => PowertrainType.unknown,
      };
    }

    final value = raw.trim().toLowerCase();
    if (value == 'ice' || value.contains('내연')) return PowertrainType.ice;
    if (value == 'hybrid' || value.contains('하이브리드')) {
      return PowertrainType.hybrid;
    }
    if (value == 'plug_in_hybrid' ||
        value == 'phev' ||
        value.contains('플러그인')) {
      return PowertrainType.plugInHybrid;
    }
    if (value == 'battery_electric' ||
        value == 'electric' ||
        value == 'ev' ||
        value.contains('배터리') ||
        value.contains('전기')) {
      return PowertrainType.batteryElectric;
    }
    if (value == 'fuel_cell' ||
        value == 'fcev' ||
        value.contains('연료전지') ||
        value.contains('수소')) {
      return PowertrainType.fuelCell;
    }
    if (value == 'lpg' || value == 'lpi') return PowertrainType.lpg;
    return PowertrainType.unknown;
  }

  /// 표준 리그 매핑 반환
  static FuelLeague determineFuelLeague(FuelType fuelType) {
    return switch (fuelType) {
      FuelType.gasoline => FuelLeague.gasoline,
      FuelType.diesel => FuelLeague.diesel,
      FuelType.hybrid => FuelLeague.hybrid,
      FuelType.plugInHybrid => FuelLeague.plugInHybrid,
      FuelType.electric => FuelLeague.electric,
      FuelType.lpg => FuelLeague.lpg,
      FuelType.hydrogen => FuelLeague.hydrogen,
      _ => FuelLeague.other,
    };
  }

  /// 표준 효율 단위 매핑 반환
  static EfficiencyUnit determineDefaultUnit(FuelType fuelType) {
    return switch (fuelType) {
      FuelType.electric => EfficiencyUnit.kmPerKwh,
      FuelType.hydrogen => EfficiencyUnit.kmPerKg,
      FuelType.unknown => EfficiencyUnit.unknown,
      _ => EfficiencyUnit.kmPerLiter,
    };
  }
}
