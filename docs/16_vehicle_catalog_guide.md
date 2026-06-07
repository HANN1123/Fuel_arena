# Vehicle Catalog Guide

Fuel Arena의 차량 카탈로그는 앱 코드 상수보다 `assets/data/vehicle_catalog_kr_seed.json`을 우선 사용한다.

## 포함 범위
- 제조사 22개.
- 모델 164개.
- 2008-2026 범위의 실제 판매 연식 조합 3098개.
- 파워트레인 variant 5079개.

## 데이터 원칙
- 공식 효율을 확인하지 못한 항목은 `official_efficiency`를 `null`로 둔다.
- 사용자 선택 단위는 판매 트림이 아니라 차종과 파생모델, 기준 연식, 엔진·미션 파워트레인이다.
- 제조사 선택 단계는 전체/국산/수입 필터를 제공하고, 수입 필터는 `country != KR` 제조사를 묶어 보여준다.
- 앱의 기준 연식 단계는 피커/스크롤 리스트로 노출하며, 선택한 연식의 파워트레인 목록만 세분화한다.
- 모델 단계에서는 `K3`, `K3 GT`, `아반떼`, `아반떼 N`처럼 고객이 구분하는 차종/파생모델명만 보여주고 `세대`라는 표현은 사용하지 않는다.
- 카탈로그 보강은 각 제조사 공식 가격표/제원표를 우선 출처로 삼고, 스마트/모던/프레스티지/시그니처 같은 판매 등급과 휠 인치수는 제외한다. K3는 K3와 K3 GT를 별도 모델로 두고, 1.6 GDI 자동 6단, Smartstream G1.6 IVT, 1.6T 수동 6단, 1.6T 7단 DCT처럼 엔진·미션 차이가 있는 항목만 variant로 나눈다.
- runtime fallback catalog와 mock 가입 흐름도 seed의 최신 model/year/variant ID와 동기화해야 한다.
- 스마트, 모던, 프레스티지, 시그니처 같은 판매 등급과 휠 인치수는 공식 리그 분류 축으로 쓰지 않는다.
- 전기차는 `efficiency_unit = km/kWh`.
- 가솔린, 디젤, 하이브리드, LPG, 플러그인 하이브리드는 `efficiency_unit = km/L`.
- `fuel_type`, `fuel_league`, `vehicle_class`, `efficiency_unit`은 비워 두지 않는다.
- 카탈로그에 없는 차량은 직접 입력으로 `pending_review` 요청을 만든다.

## 생성과 검증
```bash
dart run tool/generate_vehicle_catalog_seed.dart
dart run tool/validate_vehicle_catalog.dart
```

## 공식 출처 메모
- K3 2024: 기아 공식 `price_k3.pdf`의 파워트레인 표를 기준으로 K3 `1.6 가솔린 · Smartstream G1.6 · IVT`를 반영한다. 출처: `https://www.kia.com/content/dam/kwp/kr/ko/vehicles/pdf/price/price_k3.pdf`
- K3 GT 2024: 기아 공식 `price_k3gt.pdf`의 파워트레인 표를 기준으로 K3 GT `1.6T 가솔린 DCT · Gamma 1.6 T-GDi · 7단 DCT`를 반영한다. 출처: `https://www.kia.com/content/dam/kwp/kr/ko/vehicles/pdf/price/price_k3gt.pdf`
- K3 2016-2017: 기아 공식 K3 카탈로그의 정부공인 표준연비/등급 표를 기준으로 K3 `1.6 디젤 · U2 1.6 VGT 디젤 · 7단 DCT ISG`를 가솔린과 별도 파워트레인으로 반영한다.
- K3/K3 GT 2020: 기아 공식 `price_k3.pdf`의 파워트레인/정부 신고 연비 표를 기준으로 K3 GT `1.6T 가솔린 수동 · 수동 6단`과 `1.6T 가솔린 DCT · 7단 DCT`를 분리한다.
- 아반떼 2026: 현대 공식 가격/제원 페이지의 엔진 선택 축을 기준으로 `Smartstream G1.6`, `LPi 1.6`, 하이브리드처럼 엔진/미션이 다른 항목만 파워트레인으로 분리한다. 판매 등급과 휠 인치수는 제외한다.

## Supabase import
```bash
dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql
```

생성된 SQL은 production migration 적용 후 Supabase SQL editor 또는 CLI seed 단계에서 실행한다.
앱의 production 차량 선택은 제조사 카드 통계용 `vehicle_manufacturer_catalog_view`와 variant 조회용 `vehicle_catalog_view`를 사용한다. migration 적용 후 `model_count`, `min_year`, `max_year`가 제조사별로 채워지는지 확인한다.

## 운영 검수
- 직접 입력 차량은 `custom_vehicle_requests`에 저장되고, 동시에 생성된 `user_vehicles.id`가 `user_vehicle_id`로 연결된다.
- 운영자는 관리자 차량 카탈로그 화면의 검수 큐에서 요청을 확인하고 승인/반려한다.
- 승인/반려 처리는 `review_custom_vehicle` Edge Function으로 처리한다. 이 함수는 `custom_vehicle_requests.user_vehicle_id`와 요청 사용자, 검수 대상 `user_vehicles` 소유자가 일치할 때만 `user_vehicles.verification_status`와 `custom_vehicle_requests.status`를 함께 갱신하고, 사용자 알림함에 `vehicle_review` 알림을 남긴다.
- 승인된 차량만 공식 랭킹과 공식 배틀에 반영한다.
