import '../../../shared/models/fuel_arena_models.dart';

class IntegrityFailure {
  const IntegrityFailure(this.entityId, this.entityType, this.message);
  final String entityId;
  final String entityType; // 'manufacturer', 'model', 'year', 'variant'
  final String message;

  @override
  String toString() => '[$entityType:$entityId] $message';
}

class VehicleCatalogIntegrityValidator {
  /// 카탈로그 엔티티 리스트를 다 받아서 전체 계층의 참조 결손(integrity)을 진단
  static List<IntegrityFailure> validateCatalog({
    required List<VehicleManufacturer> manufacturers,
    required List<VehicleModel> models,
    required List<VehicleModelYear> years,
    required List<VehicleVariant> variants,
  }) {
    final failures = <IntegrityFailure>[];

    final manufacturerIds = manufacturers.map((m) => m.id).toSet();
    final modelIds = models.map((m) => m.id).toSet();
    final yearIds = years.map((y) => y.id).toSet();

    // 1. 모델 -> 제조사 참조 및 하위 연식 유무 검사
    final modelsWithYears = <String>{};
    for (final model in models) {
      if (!manufacturerIds.contains(model.manufacturerId)) {
        failures.add(IntegrityFailure(
          model.id,
          'model',
          '제조사 ID(${model.manufacturerId}) 참조가 존재하지 않습니다.',
        ));
      }
      
      // 연식 존재 여부 카운트용 임시 확인
      final hasYear = years.any((y) => y.modelId == model.id);
      if (hasYear) {
        modelsWithYears.add(model.id);
      } else {
        failures.add(IntegrityFailure(
          model.id,
          'model',
          '모델에 연결된 연식(VehicleModelYear)이 존재하지 않습니다.',
        ));
      }
    }

    // 2. 연식 -> 모델 참조 및 하위 변종(variants) 유무 검사
    final yearsWithVariants = <String>{};
    for (final year in years) {
      if (!modelIds.contains(year.modelId)) {
        failures.add(IntegrityFailure(
          year.id,
          'year',
          '모델 ID(${year.modelId}) 참조가 존재하지 않습니다.',
        ));
      }

      final hasVariant = variants.any((v) => v.modelYearId == year.id);
      if (hasVariant) {
        yearsWithVariants.add(year.id);
      } else {
        failures.add(IntegrityFailure(
          year.id,
          'year',
          '연식에 연결된 파워트레인 변종(VehicleVariant)이 존재하지 않습니다.',
        ));
      }
    }

    // 3. 변종 -> 연식 참조 검사
    for (final variant in variants) {
      if (!yearIds.contains(variant.modelYearId)) {
        failures.add(IntegrityFailure(
          variant.id,
          'variant',
          '연식 ID(${variant.modelYearId}) 참조가 존재하지 않습니다.',
        ));
      }
    }

    return failures;
  }
}
