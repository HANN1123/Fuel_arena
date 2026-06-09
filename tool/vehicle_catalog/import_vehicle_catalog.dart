import 'dart:convert';
import 'dart:io';

/// 차량 카탈로그 에셋 데이터를 제어하고 병합(Merge)하는 공통 헬퍼 클래스
class VehicleCatalogManager {
  static const jsonPath = 'assets/data/vehicle_catalog_kr_seed.json';

  /// 기존 JSON seed 데이터를 로드
  static Map<String, dynamic> loadCatalog() {
    final file = File(jsonPath);
    if (!file.existsSync()) {
      return {
        'schema_version': 1,
        'generated_at': DateTime.now().toIso8601String(),
        'notes': '차량 카탈로그 데이터베이스',
        'manufacturers': [],
        'models': [],
        'years': [],
        'variants': [],
      };
    }
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  /// 수정된 카탈로그를 JSON seed 파일에 저장
  static void saveCatalog(Map<String, dynamic> data) {
    data['generated_at'] = DateTime.now().toIso8601String();
    final file = File(jsonPath);
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  /// 새 variant를 병합(Conflict 해결 로직 탑재)
  static Map<String, dynamic> mergeVariant(
    Map<String, dynamic> catalog,
    Map<String, dynamic> newVariant, {
    required String sourceName,
    String? sourceUrl,
    required double confidence,
    bool overwrite = false,
  }) {
    final List<dynamic> variants = catalog['variants'] as List<dynamic>;
    final variantId = newVariant['id'] as String;

    final existingIndex = variants.indexWhere((v) => v['id'] == variantId);

    if (existingIndex >= 0) {
      final existing = variants[existingIndex] as Map<String, dynamic>;

      // 제원 비교를 통한 Conflict 체크
      final bool hasDiff = 
          existing['displacement_cc'] != newVariant['displacement_cc'] ||
          existing['battery_kwh'] != newVariant['battery_kwh'] ||
          existing['drivetrain'] != newVariant['drivetrain'] ||
          existing['transmission'] != newVariant['transmission'] ||
          existing['official_efficiency'] != newVariant['official_efficiency'];

      if (hasDiff) {
        if (overwrite) {
          // 덮어쓰기 허용 (Conflict 해결)
          newVariant['source_status'] = 'verified_official';
          newVariant['confidence_score'] = confidence;
          newVariant['source_name'] = sourceName;
          newVariant['source_url'] = sourceUrl;
          variants[existingIndex] = newVariant;
          stdout.writeln('[OVERWRITE] Variant $variantId updated.');
        } else {
          // 충돌 경고 및 unverified/conflict 상태 지정
          existing['source_status'] = 'conflict';
          stdout.writeln('[CONFLICT] Variant $variantId 제원 불일치 감지. 관리자 해결이 필요합니다.');
        }
      } else {
        // 제원 일치 시 출처 업데이트 및 등급 상향
        existing['source_status'] = 'verified_official';
        existing['confidence_score'] = confidence;
        existing['source_name'] = sourceName;
        existing['source_url'] = sourceUrl;
        stdout.writeln('[MATCH] Variant $variantId verified with $sourceName.');
      }
    } else {
      // 신규 등록
      newVariant['source_status'] = confidence >= 0.8 ? 'verified_official' : 'pending_review';
      newVariant['confidence_score'] = confidence;
      newVariant['source_name'] = sourceName;
      newVariant['source_url'] = sourceUrl;
      variants.add(newVariant);
      stdout.writeln('[INSERT] New Variant $variantId added.');
    }

    return catalog;
  }
}
