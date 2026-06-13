# 차량 선택 필터 재설계

## 배경

기존 차량 설정 화면은 `제조사 -> 모델 -> 연식 -> 파워트레인 -> 확인` 순서였고, 모델 단계의 필터가 `VehicleModel.bodyType`에 의존했다. 이 구조에서는 코나처럼 같은 모델에 가솔린, 하이브리드, 전기 파워트레인이 함께 있는 경우 선택한 연료와 맞지 않는 모델/파워트레인이 섞일 수 있었다. 또한 `전기 SUV`, `전기 세단`처럼 연료와 차형이 섞인 카테고리 칩이 노출됐다.

## 새 사용자 흐름

차량 설정은 다음 7단계로 진행한다.

1. 제조사 선택
2. 연료 타입 선택
3. 차급/차형 카테고리 선택
4. 모델 선택
5. 기준 연식 선택
6. 파워트레인 선택
7. 확인 및 대표 차량 저장

모든 단계는 선택한 제조사, 연료 타입, 카테고리를 유지하며, 상위 선택이 바뀌면 하위 선택만 초기화한다. 카탈로그에 매칭 결과가 없으면 직접 입력 CTA를 보여준다.

## 필터 기준

모델 노출 여부는 모델 row의 `bodyType`만으로 판단하지 않는다. 선택 가능한 `VehicleVariant`의 다음 값을 기준으로 계산한다.

- `fuelType` / `fuelLeague`
- `vehicleClass`
- `bodyType`
- `marketSegment`
- `isVerified`, `isSelectable`, `isDeprecated`

예시는 다음과 같다.

- `현대 -> 가솔린 -> 준중형 -> 아반떼 -> 2024 -> 1.6 가솔린`
- 코나는 가솔린, 하이브리드, 전기차 연료 단계에 모두 나타날 수 있지만, 마지막 파워트레인 목록은 선택한 연료만 보여준다.
- 전기차 카테고리에서는 `전기 SUV` 같은 혼합 칩을 만들지 않고 `소형 SUV`, `중형 SUV`, `SUV`처럼 차급/차형 의미만 남긴다.

## 구현 파일

- `lib/shared/models/fuel_arena_models.dart`
  - `VehicleSelectionStep`은 현재 `manufacturer`, `fuelType`, `category`, `model`, `generation`, `powertrain`, `confirm` 흐름을 사용한다.
  - `VehicleSelectionState`에 `selectedFuelType`, `selectedCategory`를 추가했다.
  - `VehicleVariant`에 `manufacturerId`, `modelId`, `bodyType`, `marketSegment`, `isSelectable`, `isDeprecated`를 추가했다.
  - `VehicleCategoryFilter`, `VehicleModelFilterQuery`, `VehicleGenerationFilterQuery`, `VehiclePowertrainFilterQuery`, `VehicleModelFilterSummary`, `VehicleGenerationSummary`를 추가했다.
- `lib/shared/domain/vehicle_selection_filters.dart`
  - variant 기반 연료/카테고리/모델/연식/파워트레인 필터를 순수 함수로 분리했다.
  - `전기 SUV`, `전기 세단` 같은 body label은 `SUV`, `세단`으로 정규화한다.
- `lib/shared/repositories/fuel_arena_repositories.dart`
  - Mock/Supabase repository에 새 필터 API를 추가했다.
  - Supabase는 기존 `vehicle_models`, `vehicle_model_years`, `vehicle_catalog_view`를 조합해 variant에 model/body 정보를 보강한다.
- `lib/shared/providers/repository_providers.dart`
  - 연료, 카테고리, 필터 모델, 필터 연식, 필터 파워트레인 provider를 추가했다.
- `lib/features/vehicle/presentation/vehicle_setup_screen.dart`
  - 화면 스텝을 새 7단계 흐름으로 개편했다.
  - 모델 카드는 선택 조건에 맞는 파워트레인 수, 연식 범위, 대표 파워트레인을 보여준다.
  - 파워트레인 단계는 이미 선택 연료로 좁혀진 목록만 보여준다.

## Repository API

`VehicleCatalogRepository`는 기존 API와 함께 다음 API를 제공한다.

```dart
Future<List<String>> listFuelTypesByManufacturer(String manufacturerId);
Future<List<VehicleCategoryFilter>>
    listVehicleClassesByManufacturerAndFuelType(
  String manufacturerId,
  String fuelType,
);
Future<List<VehicleModelFilterSummary>> listModelsByFilter(
  VehicleModelFilterQuery query,
);
Future<List<VehicleGenerationSummary>> listGenerationsByFilter(
  VehicleGenerationFilterQuery query,
);
Future<List<VehiclePowertrainChoice>> listPowertrainsByGeneration(
  VehiclePowertrainFilterQuery query,
);
```

`fuelType` 값은 앱 내부 필터 안정성을 위해 `gasoline`, `diesel`, `hybrid`, `electric`, `lpg`, `plug_in_hybrid` 같은 fuel league key를 사용한다. 화면 표시명은 `FuelLeague.nameForKey`로 한국어 라벨을 만든다.

## 검증

- `flutter analyze`
- `flutter test test/unit/vehicle_selection_filters_test.dart test/widget/flow_screens_test.dart`

추가된 단위 테스트는 전기차 카테고리가 `EV`로 묶이는지, 가솔린/승용에서 아반떼만 남는지, 세대 summary와 파워트레인 적용 기간 grouping이 동작하는지 검증한다.
