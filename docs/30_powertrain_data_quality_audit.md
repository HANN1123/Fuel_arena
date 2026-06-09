# 차량 및 파워트레인 데이터 품질 감사 보고서 (docs/30)

본 보고서는 Fuel Arena의 실제 출시 가능한 수준(Production Ready) 도달을 위해 현재 차량 카탈로그 데이터의 무결성, 스키마 구조, 누락 상태 및 UI/UX의 미흡점을 정밀 감사한 결과입니다.

---

## 1. 현재 차량 카탈로그 기본 메트릭 및 구조

* **카탈로그 구조**: 
  - `VehicleManufacturer` (제조사) -> `VehicleModel` (모델) -> `VehicleModelYear` (모델 연식) -> `VehicleVariant` (변종 / 파워트레인)
* **저장 위치**:
  - **Supabase migrations**: `supabase/migrations/` 하위 SQL 스크립트
  - **seed SQL**: `supabase/seed_vehicle_catalog.sql` (마이그레이션용 정적 데이터)
  - **assets JSON**: `assets/data/vehicle_catalog_kr_seed.json` (약 3.6MB, 모바일 및 폴백용)
  - **Dart mock data**: `lib/shared/repositories/fuel_arena_repositories.dart` 내 하드코딩된 fallback 상수 (`_catalogManufacturers` 등)
  - **관리자 화면**: `AdminVehicleCatalogScreen` (단순 리스트만 노출하는 형태)
* **수량 요약 (assets JSON 기준)**:
  - **제조사 수**: 22개
  - **모델 수**: 164개
  - **연식 조합 수**: 3,098개
  - **트림/엔진 variant 수**: 5,155개

---

## 2. 데이터 품질 분석 및 누락/오류 통계

1. **fuelType 누락 데이터 수**: 0 (가솔린, 전기차, 디젤, PHEV, 하이브리드, LPG 등 전체 분류 매핑 완료)
2. **fuelLeague 누락 데이터 수**: 0 (gasoline, electric, diesel, plug_in_hybrid, hybrid, lpg 매핑 완료)
3. **vehicleClass 누락 데이터 수**: 0 (차급 매핑 완료)
4. **efficiencyUnit 누락 데이터 수**: **914개** (전체 5,155개 중 공인연비가 누락되어 효율 단위가 명시되지 않은 데이터 수)
5. **officialEfficiency가 임의값처럼 보이는 데이터 수**: 
   - 현재 894개는 연비가 누락(null)되어 있으며, 일부 수입차 및 구형 모델은 seed 제네레이터의 폴백 추정 규칙에 의해 대치되어 검증 출처가 불분명함.
6. **source(출처 기록)가 없는 데이터 수**: **5,155개 전체** (JSON seed에 출처 명시 필드가 부재함)
7. **verified_status(검증 상태)가 없는 데이터 수**: **5,155개 전체** (스키마 상에 단순 `is_verified` 불리언만 존재하고 구체적인 `source_status` 문자열 등급 분류가 없음)
8. **전기차인데 km/L로 표시되는 데이터**: 0개 (모두 km/kWh로 정규화됨)
9. **내연기관인데 km/kWh로 표시되는 데이터**: 0개 (모두 km/L로 정규화됨)
10. **하이브리드/PHEV 분류가 모호한 데이터**: 
    - `plug_in_hybrid` (570)와 `hybrid` (532)가 숫자로 분리되어 있으나, 일부 수입 PHEV 모델이 `hybrid` 리그로 잘못 매핑되었거나 제원(배터리 용량 등) 누락으로 모호하게 분류되어 있음.
11. **실제 존재 여부를 확인할 수 없는 트림/엔진 조합**:
    - **포르쉐 박스터 (2022~2026)**: drivetrain이 **FWD**로 저장됨 (실제 포르쉐 박스터는 전 차량 **RWD**인 미드엔진 스포츠카임) - *심각한 데이터 오류*
    - **BMW 1시리즈 (2024~2026)**: FWD 118i 사양이 기재되어 있으나, 국내 및 해외 사양 변경에 따른 실존 여부 및 제원 매칭 검증 필요.
12. **연식 및 트림 단계에서 빈 화면이 발생할 수 있는 잠재 영역**:
    - `vehicle_catalog_kr_seed.json` 상으로는 다트 밸리데이터가 "연식에 연결된 variant가 없으면 에러"를 내도록 강제하고 있어 정상이나, Supabase DB 상에 custom_vehicle_requests 등을 통해 불완전하게 추가되는 사용자 입력 데이터의 경우 연식 및 트림 매핑 누락으로 UI 빈 화면을 유발할 수 있음.

---

## 3. 앱 UI/UX 및 Route 감사

1. **전체 앱에서 placeholder 또는 빈 화면이 남아 있는 route**:
   - `/legal/:document` (약관 상세 - 템플릿만 존재)
   - `/premium` (프리미엄 구독 페이지 - 모의 결제 연동 누락)
   - `/crew` (크루 화면 - UI 완성도 부족 및 placeholder 리스트 존재)
   - `/support/faq` 및 `/support/contact` (고객센터 FAQ 및 문의하기 - 실제 UI 레이아웃 미연결)
   - `/profile/badges` (배지 상세 - placeholder 텍스트 노출)
2. **사용자 버튼 중 동작하지 않는 CTA**:
   - 설정 메뉴 내 일부 스위치 및 개인정보 삭제 요청 버튼
   - 라이벌 분석 카드 내 "분석하기" 및 일부 미션의 "도전하기" 미작동 버튼

---

## 4. 품질 개선 중요도 정의 (우선순위)

### 🔴 P0: 출시 차단 문제
* 포르쉐 구동계 FWD 지정 오류 즉시 교정.
* 차량 카탈로그 테이블 스키마에 `source_status` 및 `confidence_score` 적용 및 verified 상태 중 출처가 없는 데이터 unverified로 일괄 강등.
* 사용자 직접 입력 차량(`custom_vehicle_requests`)을 공식 리그 집계에서 격리하고 pending_review 상태로 지정.

### 🟡 P1: 베타 전 반드시 수정
* 공공 데이터 포털(KEA) 및 제조사 공식 제원 CSV import 파이프라인 스크립트 구현.
* UI 차량 선택 단계(`VehicleSetupScreen`)에 데이터 검증 배지 및 출처(source_url) 확인 BottomSheet 구현.
* 플러그인 하이브리드(PHEV)와 하이브리드(HEV)의 리그 및 제원 검증 실패 규칙 보강.

### 🟢 P2: 운영 중 개선 가능
* 관리자 전용 차량 데이터 검수 화면(AdminVehicleCatalogScreen, AdminPowertrainConflictScreen 등) 강화.
* 앱 내 placeholder 화면(FAQ, Badges 등)에 mock 데이터 또는 완전한 뷰 연결.
* RLS 정책 강화 및 change_log 기록 기능 Supabase 트리거/RPC 구현.

### 🔵 P3: 장기 개선
* GitHub Actions에 P0 품질 이슈 발생 시 빌드 실패(fail-on-p0) 조건 추가.
* Open API를 활용한 공공 연비 데이터 실시간 동기화 파이프라인.
