# Fuel Arena 차량 카탈로그 소스 데이터 디렉터리

본 디렉터리는 외부 공공 데이터 포털, 제조사 배포 제원 등 차량 카탈로그 데이터베이스를 갱신하기 위해 수집한 로우(raw) CSV 파일들을 관리합니다.

## 소스 템플릿 목록

1. **`kea_fuel_efficiency_sample.csv`**:
   - 한국에너지공단 수송에너지 관리 연비 데이터 서식 파일.
   - 정부 공인 연비 및 효율(도심, 고속도로, 복합 등) 정보를 포함합니다.
2. **`manufacturer_spec_template.csv`**:
   - 완성차 제조사에서 발표한 제품 가격표 및 브로셔 제원표 전용 템플릿.
   - 모터 출력, 배터리 용량, 구동계, 전비 등을 수집합니다.
3. **`manual_admin_template.csv`**:
   - 운영진이 잘못된 제원을 직접 교정하여 배포하기 위한 수동 관리자 보정 템플릿.
   - 충돌이 발생한 사양을 Overwrite하기 위해 사용합니다.

## 임포트 파이프라인 구동

- **KEA 연비 데이터 반영**:
  ```bash
  dart run tool/vehicle_catalog/import_kea_fuel_efficiency.dart assets/data/vehicle_catalog_sources/kea_fuel_efficiency_sample.csv
  ```
- **제조사 제원 데이터 반영**:
  ```bash
  dart run tool/vehicle_catalog/import_manufacturer_specs.dart assets/data/vehicle_catalog_sources/manufacturer_spec_template.csv
  ```
- **카탈로그 통합 검증 및 품질 보고서**:
  ```bash
  dart run tool/vehicle_catalog/validate_vehicle_catalog.dart
  dart run tool/vehicle_catalog/generate_catalog_quality_report.dart
  ```
