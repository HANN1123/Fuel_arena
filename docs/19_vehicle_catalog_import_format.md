# Vehicle Catalog Import Format

CSV 샘플: `assets/data/vehicle_catalog_kr_sample.csv`

## 컬럼
- `manufacturer_id`
- `manufacturer_name_ko`
- `model_id`
- `model_name_ko`
- `year`
- `trim_name`
- `fuel_type`
- `fuel_league`
- `vehicle_class`
- `efficiency_unit`
- `official_efficiency`
- `is_verified`

## 필수 규칙
- `manufacturer_id`, `model_id`, `year`, `trim_name`은 비워둘 수 없다.
- schema 호환을 위해 컬럼명은 `trim_name`을 유지하지만, 값은 판매 트림명이 아니라 `1.6 가솔린`, `1.6T 가솔린 DCT`, `2.0 디젤`, `전기차` 같은 파워트레인명을 넣는다.
- `fuel_league`는 `gasoline`, `diesel`, `hybrid`, `electric`, `lpg`, `plug_in_hybrid`, `other` 중 하나다.
- `electric`은 `efficiency_unit = km/kWh`.
- 나머지 리그는 `efficiency_unit = km/L`.
- 공식 효율을 검증하지 못했으면 `official_efficiency`를 비운다.
- `is_verified`는 사용자 선택에 노출할 수 있는 카탈로그 항목만 `true`로 둔다. 공식 효율 미확인 여부는 `official_efficiency = null`로 구분한다.

## JSON 변환
현재 앱 mock fallback은 JSON asset을 사용한다.

```bash
dart run tool/generate_vehicle_catalog_seed.dart
dart run tool/validate_vehicle_catalog.dart
```

## SQL 변환
```bash
dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql
```

생성 SQL은 `vehicle_manufacturers`, `vehicle_models`, `vehicle_model_years`, `vehicle_variants`에 upsert한다.
