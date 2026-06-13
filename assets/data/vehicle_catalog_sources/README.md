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
4. **`generation_template.csv`**:
   - 모델별 세대명, 코드명, 판매 기간, 검증 상태, 출처를 수집합니다.
   - source 없는 generation은 verified로 import하지 않습니다.
   - `start_year/start_month/end_year/end_month`는 실제 판매/출시 기간입니다.
   - `model_year_start_year/model_year_end_year`는 `vehicle_model_years` 연결 범위입니다. BMW 5시리즈 G60처럼 2023년 말 출시지만 앱의 model_year row는 2024년부터 연결해야 하는 경우에 사용합니다.
   - `is_selectable`은 선택 UX 노출 여부입니다. Honda Civic/HR-V, Nissan Ariya처럼 국내 공식 판매/현재 라인업 근거가 부족한 placeholder는 `pending_review`여도 `false`로 둡니다.
5. **`powertrain_generation_template.csv`**:
   - 파워트레인 row를 generation_id 또는 generation_code와 연결합니다.
   - K3 GT처럼 모델이 아니라 트림인 항목은 model=K3, trim_name=K3 GT ... 형태로 관리합니다.

## 임포트 파이프라인 구동

- **KEA 연비 데이터 반영**:
  ```bash
  dart run tool/vehicle_catalog/import_kea_fuel_efficiency.dart assets/data/vehicle_catalog_sources/kea_fuel_efficiency_sample.csv
  ```
- **제조사 제원 데이터 반영**:
  ```bash
  dart run tool/vehicle_catalog/import_manufacturer_specs.dart assets/data/vehicle_catalog_sources/manufacturer_spec_template.csv
  ```
- **세대/파워트레인 세대 연결 반영**:
  ```bash
  dart run tool/vehicle_catalog/import_vehicle_generations.dart \
    --generations assets/data/vehicle_catalog_sources/generation_template.csv \
    --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv
  ```
- **카탈로그 통합 검증 및 품질 보고서**:
  ```bash
  dart run tool/vehicle_catalog/validate_vehicle_catalog.dart
  dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs
  ```
