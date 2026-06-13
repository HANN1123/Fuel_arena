import 'package:intl/intl.dart';

String formatNumber(num value) => NumberFormat.decimalPattern().format(value);

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = duration.inHours;
  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

class FuelEfficiencyFormatter {
  const FuelEfficiencyFormatter();

  static const electricLeague = 'electric';
  static const hydrogenLeague = 'hydrogen';
  static const plugInHybridLeague = 'plug_in_hybrid';

  String unitForFuelLeague(String fuelLeague) {
    return switch (fuelLeague) {
      electricLeague => 'km/kWh',
      hydrogenLeague => 'km/kg',
      _ => 'km/L',
    };
  }

  String metricLabelForFuelLeague(String fuelLeague) {
    return fuelLeague == electricLeague || fuelLeague == hydrogenLeague
        ? '평균 효율'
        : '평균 연비';
  }

  String helperCopyForFuelLeague(String fuelLeague) {
    return switch (fuelLeague) {
      electricLeague => '전기차는 km/kWh 기준으로 효율을 계산해요.',
      hydrogenLeague => '수소전기차는 km/kg 기준으로 효율을 계산해요.',
      plugInHybridLeague => '플러그인 하이브리드는 연료와 전기 사용량을 분리해 확인해요.',
      _ => '공식 랭킹은 같은 연료 타입 안에서 비교됩니다.',
    };
  }

  String format(num value, String fuelLeague, {int decimals = 1}) {
    final unit = unitForFuelLeague(fuelLeague);
    return '${value.toStringAsFixed(decimals)}$unit';
  }

  String formatResultLine(num value, String fuelLeague) {
    return '${metricLabelForFuelLeague(fuelLeague)} ${format(value, fuelLeague)}';
  }
}
