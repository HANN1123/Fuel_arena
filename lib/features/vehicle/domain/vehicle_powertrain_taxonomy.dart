import 'package:flutter/material.dart';

/// 표준 연료 타입 분류
enum FuelType {
  gasoline('gasoline', '가솔린'),
  diesel('diesel', '디젤'),
  hybrid('hybrid', '하이브리드'),
  plugInHybrid('plug_in_hybrid', '플러그인 하이브리드'),
  electric('electric', '전기차'),
  lpg('lpg', 'LPG'),
  hydrogen('hydrogen', '수소차'),
  other('other', '기타'),
  unknown('unknown', '정보 없음');

  const FuelType(this.key, this.displayName);
  final String key;
  final String displayName;

  static FuelType fromKey(String? key) {
    if (key == null) return FuelType.unknown;
    final normalized = key.trim().toLowerCase().replaceAll('-', '_');
    return FuelType.values.firstWhere(
      (e) => e.key == normalized,
      orElse: () => FuelType.unknown,
    );
  }
}

/// 표준 파워트레인 타입 분류
enum PowertrainType {
  ice('ice', '내연기관'),
  hybrid('hybrid', '하이브리드'),
  plugInHybrid('plug_in_hybrid', '플러그인 하이브리드'),
  batteryElectric('battery_electric', '배터리 전기차'),
  fuelCell('fuel_cell', '수소 연료전지차'),
  lpg('lpg', 'LPG'),
  other('other', '기타'),
  unknown('unknown', '정보 없음');

  const PowertrainType(this.key, this.displayName);
  final String key;
  final String displayName;

  static PowertrainType fromKey(String? key) {
    if (key == null) return PowertrainType.unknown;
    final normalized = key.trim().toLowerCase().replaceAll('-', '_');
    return PowertrainType.values.firstWhere(
      (e) => e.key == normalized,
      orElse: () => PowertrainType.unknown,
    );
  }
}

/// 표준 리그 분류
enum FuelLeague {
  gasoline('gasoline', '가솔린 리그'),
  diesel('diesel', '디젤 리그'),
  hybrid('hybrid', '하이브리드 리그'),
  plugInHybrid('plug_in_hybrid', 'PHEV 리그'),
  electric('electric', '전기차 리그'),
  lpg('lpg', 'LPG 리그'),
  hydrogen('hydrogen', '수소차 리그'),
  other('other', '챌린지 리그');

  const FuelLeague(this.key, this.displayName);
  final String key;
  final String displayName;

  static FuelLeague fromKey(String? key) {
    if (key == null) return FuelLeague.other;
    final normalized = key.trim().toLowerCase().replaceAll('-', '_');
    return FuelLeague.values.firstWhere(
      (e) => e.key == normalized,
      orElse: () => FuelLeague.other,
    );
  }
}

/// 표준 효율 단위 분류
enum EfficiencyUnit {
  kmPerLiter('km_per_liter', 'km/L'),
  kmPerKwh('km_per_kwh', 'km/kWh'),
  kmPerKg('km_per_kg', 'km/kg'),
  lPer100km('l_per_100km', 'L/100km'),
  kwhPer100km('kwh_per_100km', 'kWh/100km'),
  unknown('unknown', '정보 없음');

  const EfficiencyUnit(this.key, this.symbol);
  final String key;
  final String symbol;

  static EfficiencyUnit fromKey(String? key) {
    if (key == null) return EfficiencyUnit.unknown;
    final normalized = key.trim().toLowerCase().replaceAll('-', '_');
    if (normalized == 'km/l') return EfficiencyUnit.kmPerLiter;
    if (normalized == 'km/kwh') return EfficiencyUnit.kmPerKwh;
    if (normalized == 'km/kg') return EfficiencyUnit.kmPerKg;
    return EfficiencyUnit.values.firstWhere(
      (e) => e.key == normalized,
      orElse: () => EfficiencyUnit.unknown,
    );
  }
}

/// 데이터 출처 및 검증 등급 (source_status)
enum SourceStatus {
  verifiedOfficial('verified_official', '공식 검증', Colors.green),
  verifiedAdmin('verified_admin', '관리자 검증', Colors.blue),
  importedPublic('imported_public', '공공 데이터', Colors.teal),
  userSubmitted('user_submitted', '사용자 직접 입력', Colors.orange),
  pendingReview('pending_review', '검토 대기', Colors.amber),
  conflict('conflict', '출처 충돌', Colors.red),
  deprecated('deprecated', '사용 중단', Colors.grey),
  unknown('unknown', '정보 없음', Colors.grey);

  const SourceStatus(this.key, this.displayName, this.color);
  final String key;
  final String displayName;
  final Color color;

  static SourceStatus fromKey(String? key) {
    if (key == null) return SourceStatus.unknown;
    final normalized = key.trim().toLowerCase().replaceAll('-', '_');
    return SourceStatus.values.firstWhere(
      (e) => e.key == normalized,
      orElse: () => SourceStatus.unknown,
    );
  }
}
