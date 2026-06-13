import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_arena/shared/domain/vehicle_selection_filters.dart';
import 'package:fuel_arena/shared/models/fuel_arena_models.dart';

void main() {
  group('vehicle selection filters', () {
    const manufacturerId = 'm-hyundai';
    const avante = VehicleModel(
      id: 'model-avante',
      manufacturerId: manufacturerId,
      nameKo: '아반떼',
      bodyType: '세단',
      sortOrder: 10,
    );
    const kona = VehicleModel(
      id: 'model-kona',
      manufacturerId: manufacturerId,
      nameKo: '코나',
      bodyType: 'SUV',
      sortOrder: 20,
    );
    const ioniq5 = VehicleModel(
      id: 'model-ioniq5',
      manufacturerId: manufacturerId,
      nameKo: '아이오닉 5',
      bodyType: '전기 SUV',
      sortOrder: 30,
    );
    const years = [
      VehicleModelYear(
          id: 'year-avante-2024', modelId: 'model-avante', year: 2024),
      VehicleModelYear(id: 'year-kona-2024', modelId: 'model-kona', year: 2024),
      VehicleModelYear(
          id: 'year-ioniq5-2024', modelId: 'model-ioniq5', year: 2024),
    ];
    final variants = [
      _variant(
        id: 'avante-gas',
        modelYearId: 'year-avante-2024',
        modelId: 'model-avante',
        modelName: '아반떼',
        bodyType: '세단',
        fuelLeague: 'gasoline',
        fuelType: '가솔린',
        vehicleClass: '준중형',
        trimName: '1.6 가솔린',
      ),
      _variant(
        id: 'kona-gas',
        modelYearId: 'year-kona-2024',
        modelId: 'model-kona',
        modelName: '코나',
        bodyType: 'SUV',
        fuelLeague: 'gasoline',
        fuelType: '가솔린',
        vehicleClass: '소형 SUV',
        trimName: '2.0 가솔린',
      ),
      _variant(
        id: 'kona-electric',
        modelYearId: 'year-kona-2024',
        modelId: 'model-kona',
        modelName: '코나',
        bodyType: 'SUV',
        fuelLeague: 'electric',
        fuelType: '전기차',
        vehicleClass: '소형 SUV',
        trimName: '롱레인지 전기',
      ),
      _variant(
        id: 'ioniq5-electric',
        modelYearId: 'year-ioniq5-2024',
        modelId: 'model-ioniq5',
        modelName: '아이오닉 5',
        bodyType: '전기 SUV',
        fuelLeague: 'electric',
        fuelType: '전기차',
        vehicleClass: '중형 SUV',
        trimName: '롱레인지 AWD',
      ),
    ];

    test('builds broad usage categories for selected fuel only', () {
      final categories = buildVehicleCategoryFilters(
        variants,
        fuelType: 'electric',
      ).map((item) => item.label);

      expect(categories, ['전체', 'EV']);
      expect(categories, isNot(contains('전기 SUV')));
      expect(categories, isNot(contains('준중형')));
    });

    test('filters model summaries by broad usage category', () {
      final summaries = buildVehicleModelFilterSummaries(
        models: const [avante, kona, ioniq5],
        years: years,
        variants: variants,
        fuelType: 'gasoline',
        category: const VehicleCategoryFilter(
          key: 'usage:승용',
          label: '승용',
          kind: VehicleCategoryFilterKind.usageCategory,
          value: '승용',
        ),
      );

      expect(summaries.map((item) => item.model.nameKo), ['아반떼']);
      expect(summaries.single.samplePowertrainLabels, ['1.6 가솔린']);
    });

    test('keeps final powertrain list scoped to selected fuel', () {
      final powertrains = filterVehiclePowertrains(
        variants: variants
            .where((item) => item.modelYearId == 'year-kona-2024')
            .toList(),
        fuelType: 'gasoline',
        category: VehicleCategoryFilter.all,
      );

      expect(powertrains.map((item) => item.trimName), ['2.0 가솔린']);
    });

    test('builds generation summaries from model years and variants', () {
      const cn7 = VehicleGeneration(
        id: 'generation-avante-cn7',
        modelId: 'model-avante',
        generationOrder: 7,
        generationNameKo: '7세대',
        generationCode: 'CN7',
        startYear: 2020,
        startMonth: 4,
        displayPeriod: '2020.4~현재',
        isCurrent: true,
        sourceStatus: 'unverified',
        modelYearIds: ['year-avante-2024'],
      );

      final summaries = buildVehicleGenerationSummaries(
        model: avante,
        generations: const [cn7],
        years: years,
        variants: variants,
        fuelType: 'gasoline',
        category: VehicleCategoryFilter.all,
      );

      expect(summaries, hasLength(1));
      expect(summaries.single.displayName, '7세대 CN7');
      expect(summaries.single.displayPeriod, '2020.4~현재');
      expect(summaries.single.matchingPowertrainCount, 1);
    });

    test('groups repeated yearly powertrains into one choice', () {
      final repeated = [
        _variant(
          id: 'avante-gas-2023',
          modelYearId: 'year-avante-2023',
          modelId: 'model-avante',
          modelName: '아반떼',
          bodyType: '세단',
          fuelLeague: 'gasoline',
          fuelType: '가솔린',
          vehicleClass: '준중형',
          trimName: '1.6 가솔린',
          year: 2023,
        ),
        _variant(
          id: 'avante-gas-2024',
          modelYearId: 'year-avante-2024',
          modelId: 'model-avante',
          modelName: '아반떼',
          bodyType: '세단',
          fuelLeague: 'gasoline',
          fuelType: '가솔린',
          vehicleClass: '준중형',
          trimName: '1.6 가솔린',
          year: 2024,
        ),
      ];

      final choices = buildVehiclePowertrainChoices(repeated);

      expect(choices, hasLength(1));
      expect(choices.single.representative.trimName, '1.6 가솔린');
      expect(choices.single.periodLabel, '2023~2024 적용');
    });
  });
}

VehicleVariant _variant({
  required String id,
  required String modelYearId,
  required String modelId,
  required String modelName,
  required String bodyType,
  required String fuelLeague,
  required String fuelType,
  required String vehicleClass,
  required String trimName,
  int year = 2024,
}) {
  return VehicleVariant(
    id: id,
    modelYearId: modelYearId,
    manufacturerId: 'm-hyundai',
    modelId: modelId,
    manufacturerName: '현대',
    modelName: modelName,
    year: year,
    trimName: trimName,
    fuelType: fuelType,
    vehicleClass: vehicleClass,
    fuelLeague: fuelLeague,
    bodyType: bodyType,
  );
}
