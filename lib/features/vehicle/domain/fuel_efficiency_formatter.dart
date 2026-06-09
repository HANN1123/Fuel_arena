import 'vehicle_powertrain_taxonomy.dart';

class FuelEfficiencyFormatter {
  /// 효율 수치와 단위를 결합하여 UI용 텍스트를 포맷팅하여 리턴
  static String format({
    required double? efficiency,
    required String unitRaw,
    String fallbackText = '공식 효율 정보 준비 중',
  }) {
    if (efficiency == null || efficiency <= 0) {
      return fallbackText;
    }

    final unit = EfficiencyUnit.fromKey(unitRaw);
    final symbol = unit == EfficiencyUnit.unknown ? 'km/L' : unit.symbol;

    // 소수점 첫째짜리까지 렌더링
    final valueStr = efficiency.toStringAsFixed(1);
    return '$valueStr $symbol';
  }

  /// 출처 등급 뱃지 표시명 및 테두리 색상 맵 반환 (UI 편의성 제공)
  static String formatSourceStatus(String? sourceStatusRaw) {
    final status = SourceStatus.fromKey(sourceStatusRaw);
    return status.displayName;
  }
}
