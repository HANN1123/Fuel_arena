import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final path =
      args.isEmpty ? 'assets/data/vehicle_catalog_kr_seed.json' : args.first;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('파일을 찾을 수 없습니다: $path');
    exit(1);
  }

  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  final manufacturers = data['manufacturers'] as List<dynamic>;
  final models = data['models'] as List<dynamic>;
  final years = data['years'] as List<dynamic>;
  final variants = data['variants'] as List<dynamic>;

  var verifiedCount = 0;
  var conflictCount = 0;
  var pendingCount = 0;
  var unverifiedCount = 0;

  var efficiencyMissingCount = 0;
  var sourceMissingCount = 0;

  for (final v in variants) {
    final vMap = v as Map<String, dynamic>;
    final status = vMap['source_status'] as String? ?? 'unverified';
    final hasEfficiency = vMap['official_efficiency'] != null;
    final hasSource = vMap['source_name'] != null;

    if (status == 'verified_official' || status == 'verified_admin') {
      verifiedCount++;
    } else if (status == 'conflict') {
      conflictCount++;
    } else if (status == 'pending_review') {
      pendingCount++;
    } else {
      unverifiedCount++;
    }

    if (!hasEfficiency) efficiencyMissingCount++;
    if (status.startsWith('verified') && !hasSource) sourceMissingCount++;
  }

  stdout.writeln('==================================================');
  stdout.writeln('           VEHICLE CATALOG QUALITY REPORT         ');
  stdout.writeln('==================================================');
  stdout.writeln('1. 카탈로그 총량 요약:');
  stdout.writeln('   - 제조사 수: ${manufacturers.length}');
  stdout.writeln('   - 모델 수: ${models.length}');
  stdout.writeln('   - 연식 수: ${years.length}');
  stdout.writeln('   - 파워트레인 변체 수: ${variants.length}');
  stdout.writeln('--------------------------------------------------');
  stdout.writeln('2. 신뢰성 통계:');
  stdout.writeln(
      '   - 공식/관리자 검증(Verified): $verifiedCount (${(verifiedCount / variants.length * 100).toStringAsFixed(1)}%)');
  stdout.writeln('   - 출처 충돌(Conflict): $conflictCount');
  stdout.writeln('   - 검토 대기(Pending Review): $pendingCount');
  stdout.writeln('   - 미검증(Unverified): $unverifiedCount');
  stdout.writeln('--------------------------------------------------');
  stdout.writeln('3. 품질 결함 지표:');
  stdout.writeln('   - 공식 연비 누락: $efficiencyMissingCount');
  stdout.writeln('   - 검증 완료 중 출처 누락(P0): $sourceMissingCount');
  stdout.writeln('==================================================');

  // P0 결함이 있고 fail-on-p0 옵션이 들어온 경우 에러 종료
  final failOnP0 = args.contains('--fail-on-p0');
  if (failOnP0 && sourceMissingCount > 0) {
    stderr.writeln('[FATAL] verified 등급에 출처(source_name)가 없는 P0 결함이 감지되었습니다.');
    exit(1);
  }
}
