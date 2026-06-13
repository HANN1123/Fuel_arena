# 차량 세대 선택 리디자인

## 1. 현재 단계

기존 차량 설정은 `제조사 -> 연료 타입 -> 차급/범주 -> 모델 -> 연식 -> 파워트레인 -> 확인` 흐름이었다. 이번 변경 후 기본 UX는 `제조사 -> 연료 타입 -> 범주 -> 모델 -> 세대 -> 파워트레인 -> 확인`이다.

## 2. 연식 선택 위치

기존 연식 선택은 `VehicleSetupScreen`의 5단계 `_YearStep`과 `VehicleModelRangePickerField`에 있었다. 이 단계는 `_GenerationStep`과 `VehicleGenerationCard`로 대체했다.

## 3. model_year 구조

`vehicle_model_years`와 `VehicleModelYear`는 삭제하지 않는다. `generation_id`와 `production_year_label`을 추가해 세대가 포함하는 연식 범위를 유지한다.

## 4. generation 개념

`VehicleGeneration`, `VehicleGenerationSummary`, `VehicleGenerationFilterQuery`, `VehiclePowertrainChoice`를 추가했다. JSON seed에는 `generations` 배열을 추가했다.

## 5. powertrain 연결

UI는 generation을 선택하지만 repository는 `generation -> model_years -> variants`로 파워트레인을 찾는다. 같은 파워트레인이 여러 연식에 반복되면 `VehiclePowertrainChoice`로 묶고 적용 기간을 표시한다.

## 6. BMW 오류 현황

BMW variant는 출처 없는 verified 상태였으므로 `is_verified=false`, `source_status=pending_review`, `is_selectable=false`로 낮췄다. 이후 1시리즈 F20/F40/F70, 2시리즈 쿠페 F22/G42, 3시리즈 F30/G20, 4시리즈 F32/G22 계열, 5시리즈 G30/G60, 7시리즈 G11/G70, X1 E84/F48/U11, X3 F25/G01/G45, X5 F15/G05, X7 G07, i4/i5/iX/iX3는 공식 출처가 확인된 세대 row를 추가했고, 출시 전 placeholder 연식/variant는 JSON seed에서 제거하고 Supabase migration에서는 deprecated 처리한다. 공식 파워트레인 출처가 붙기 전까지 BMW variant는 선택 목록에 노출하지 않는다.

## 7. 주요 제조사 누락

현재 세대 seed는 현대 14개 seed 모델 전체를 포함한다. 아반떼 CN7, 아반떼 N CN7 N, 아반떼 스포츠 AD Sport, 쏘나타 LF/DN8, 그랜저 HG/IG/GN7, 코나 OS/SX2, 투싼 TL/NX4, 싼타페 DM/TM/MX5, 팰리세이드 LX2/LX3, 캐스퍼 AX1, 아이오닉 5 NE/NE PE, 아이오닉 6 CE/CE PE, 스타리아 US4, 포터 II HR을 연결했다. 기아는 K3 BD와 K5/K8/K9/모닝/레이/셀토스/니로/스포티지/쏘렌토/카니발/EV3/EV6/EV9/봉고 세대를 포함하고, BMW는 1시리즈 F20/F40/F70, 2시리즈 쿠페 F22/G42, 3시리즈 F30/G20, 4시리즈 F32/G22 계열, 5시리즈 G30/G60, 7시리즈 G11/G70, X1/X3/X5/X7, i4 G26, i5 G60, iX i20, iX3 G08을 포함한다. 제네시스는 G70, G70 슈팅 브레이크, G80, Electrified G80, G90, GV60, GV70, Electrified GV70, GV80, GV80 Coupe 전체를 공식 Genesis 모델/보도자료 기준으로 연결했다. 르노코리아는 SM6/QM6/XM3/Arkana/그랑 콜레오스/Filante 전체를 연결하되, 현행 공식 모델 페이지가 없는 SM6/QM6/XM3는 `pending_review`로 유지한다. KG모빌리티는 티볼리/코란도/액티언/액티언 하이브리드/토레스/토레스 하이브리드/토레스 EVX/렉스턴/렉스턴 스포츠/무쏘/무쏘 EV 전체를 공식 모델 페이지 기준으로 연결하고, 공식 페이지에서 코드명을 확인하지 못한 row는 코드명 필드를 비워 둔다. K3 2세대 BD는 2018년 2월 출시 보도자료, Kia Connect의 `K3 (BD)` 표기, 2024 K3/K3 GT 공식 가격표를 근거로 연결했고, 나머지 기아 세대는 Kia 소프트웨어 버전 목록의 모델 코드 표기를 근거로 연결했다. 현대 세대는 Hyundai Motor 모델 히스토리와 Hyundai AutoEver 소프트웨어 버전 목록을 함께 근거로 연결했다. BMW 1/2/3/4/5/7/X계열 및 전기 모델 세대는 BMW Group/BMW Korea 공식 자료를 근거로 연결했다. Volvo는 S60 P3/SPA, S90 SPA, XC40 CMA, XC60 P3/SPA, XC90 SPA, C40 CMA, EX30, EX90, V60 Cross Country SPA를 Volvo Cars media와 Volvo Korea 현재 라인업 근거로 `pending_review` 세대 row에 연결한다. 나머지 제조사는 `docs/60_manufacturer_model_coverage_plan.md`와 자동 산출물 `docs/61_vehicle_catalog_coverage_report.md`에서 coverage backlog로 관리한다.

Mercedes-Benz seed 모델은 A-Class W176/W177, C-Class W205/W206, E-Class W212/W213/W214, S-Class W222/W223, GLA X156/H247, GLC X253/X254, GLE W166/V167, GLS X166/X167, EQA H243, EQB X243, EQE V295, EQS V297 세대를 포함한다. EQA는 2021년, EQB/EQE는 2022년, EQS는 2021년부터 seed model_year를 생성하고, legacy placeholder는 Supabase migration에서 deprecated/non-selectable로 낮춘다. Mercedes-Benz Korea 공식 모델 overview에서 별도 모델 카드로 확인한 S-Class Long, Mercedes-Maybach S-Class, EQE SUV, Mercedes-Maybach EQS SUV, GLB, GLC Coupé, GLE Coupé, Mercedes-Maybach GLS, G-Class, CLA Coupé, CLE Coupé, Mercedes-AMG GT Coupé, Mercedes-AMG GT 4-Door Coupé, CLE Cabriolet, SL Roadster, Mercedes-Maybach SL Monogram Series는 2026 현재 `공식 라인업` generation으로 추가하되, 상세 제원 감사 전까지 powertrain placeholder는 `pending_review`, `is_selectable=false`로 둔다.

Audi seed 모델은 A3 8V/8Y, A4 B9/8W, A5 8T/F5/B10, A6 C7/C8/C9, A7 4G8/4K8, A8 D4/D5, Q3 8U/F3/2025 generation, Q5 8R/FY/2025 generation, Q7 4M, Q8 4M, e-tron GE/Q8 e-tron, Q4 e-tron F4 세대를 포함한다. A4는 2024년까지, A7/e-tron은 2025년까지 seed model_year를 생성하고, Q8은 2018년, Q4 e-tron은 2021년부터 생성한다. Audi Korea 공식 모델 overview에서 확인한 e-tron GT, A6 e-tron, Q6 e-tron은 2026 현재 `공식 라인업` generation으로 추가하되, 상세 제원 감사 전까지 powertrain placeholder는 `pending_review`, `is_selectable=false`로 둔다.

Chevrolet seed 모델은 스파크 M400, 말리부 V300/V400, 트랙스 U200/트랙스 크로스오버 9BQC, 트레일블레이저 VSS-F, 트래버스 C1XX, 타호 T1XX, 콜로라도 RG/31XX-2, 볼트 EV G2CX 세대를 포함한다. 공식 원문이 안정적으로 확인되지 않는 단종 모델이 섞여 있어 세대 row는 `pending_review`로 유지하고, 출시 전/단종 후 placeholder model_year와 variant는 seed에서 제거하고 migration에서 deprecated/non-selectable로 낮춘다.

Volvo seed 모델은 S60 P3/SPA, S90 SPA, XC40 CMA, XC60 P3/SPA, XC90 SPA, C40 CMA, EX30, EX90, V60 Cross Country SPA 세대를 포함한다. Volvo Korea 현재 라인업에 있는 V60 Cross Country는 명시 ID `model-volvo-v60-cross-country-kr`로 추가했고, S60/C40 단종 후 placeholder와 S90/XC40/EX30/EX90 출시 전 placeholder는 seed에서 제거하고 migration에서 deprecated/non-selectable로 낮춘다. XC40 전기차 variant는 2021-2024년으로 제한한다.

현대 잔여 seed 모델은 아반떼 N, 아반떼 스포츠, 코나, 팰리세이드, 캐스퍼, 스타리아, 포터까지 연결했다. seed는 출시 전 model_year를 생성하지 않고, 코나 전기/하이브리드, 팰리세이드 디젤/하이브리드, 스타리아 하이브리드, 포터 LPG/전기차 적용 기간을 연료별로 제한한다. Supabase legacy row는 `202606130002_hyundai_remaining_generation_audit.sql`에서 generation 연결, 신규 하이브리드/LPG variant 삽입, 잘못된 placeholder deprecated/non-selectable 처리를 함께 관리한다.

## 8. 누락 수

품질 리포트는 `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`에서 세대 수, 세대 없는 모델, BMW 감사 상태, generation 연결 없는 파워트레인을 출력하고 `docs/61_vehicle_catalog_coverage_report.md`, `docs/62_bmw_catalog_audit_matrix.md`를 갱신한다.

## 9. DB 변경

`supabase/migrations/202606120001_vehicle_generations.sql`을 추가했다. `vehicle_generations`, `vehicle_generation_years`, `vehicle_model_years.generation_id`, `vehicle_variants.generation_id`, 적용 기간 컬럼을 포함한다. 초기 seed 연결은 `supabase/migrations/202606120002_vehicle_generation_seed.sql`에서 아반떼 CN7과 K3 2세대 BD를 upsert하고 model_years/variants/junction row를 연결한다. BMW 전기 모델 세대 및 출시 전 placeholder deprecated 처리는 `supabase/migrations/202606120004_bmw_electric_generation_audit.sql`에서 관리하고, BMW 5시리즈/3시리즈/4·7시리즈/X계열/1·2시리즈 세대 연결은 각각 `202606120005_bmw_5series_generation_audit.sql`, `202606120006_bmw_3series_generation_audit.sql`, `202606120007_bmw_4_7series_generation_audit.sql`, `202606120008_bmw_xseries_generation_audit.sql`, `202606120009_bmw_1_2series_generation_audit.sql`에서 관리한다. 현대 아이오닉 5/6 세대와 출시 전 placeholder deprecated 처리는 `202606120010_hyundai_ioniq_generation_audit.sql`에서 관리하고, 현대 쏘나타/그랜저/투싼/싼타페 세대 연결은 `202606120011_hyundai_core_generation_audit.sql`에서 관리한다. 현대 잔여 seed 모델 세대 연결과 연료별 placeholder 정리는 `202606130002_hyundai_remaining_generation_audit.sql`에서 관리한다. 예전 seed의 K3 GT 독립 모델 row 제거는 `202606120012_kia_k3_gt_model_cleanup.sql`에서 관리하고, 기아 나머지 seed 모델 세대 연결과 출시 전 placeholder deprecated 처리는 `202606120013_kia_core_generation_audit.sql`에서 관리한다. Mercedes-Benz seed 모델 세대 연결과 EQA/EQB/EQE/EQS 출시 전 placeholder deprecated 처리는 `202606120014_mercedes_generation_audit.sql`에서 관리한다. Audi seed 모델 세대 연결과 A4/A7/Q8/e-tron/Q4 e-tron placeholder deprecated 처리는 `202606120015_audi_generation_audit.sql`에서 관리한다. Chevrolet seed 모델 세대 연결과 출시 전/단종 후 placeholder deprecated 처리는 `202606120016_chevrolet_generation_audit.sql`에서 관리한다. Volvo seed 모델 세대 연결, V60 Cross Country 모델/연식/placeholder variant 삽입, 출시 전/단종 후 placeholder deprecated 처리는 `202606130001_volvo_generation_audit.sql`에서 관리한다. 제네시스/르노코리아/KG모빌리티 공식 라인업 보강, 신규 명시 모델 row, 기존 placeholder deprecated 처리는 `202606130004_genesis_renault_kgm_official_lineup_audit.sql`에서 관리한다. 잔여 수입 제조사의 기존 seed 모델 공식 라인업 세대 연결은 `202606130005_remaining_imported_lineup_generation_audit.sql`에서 관리하고, 공식 홈페이지에서 확인한 누락 모델 8개(Alphard, LM, Aceman, 408, Gladiator, Grand Cherokee L, Discovery Sport, Range Rover Velar)의 보수적 세대 연결은 `202606130006_missing_official_lineup_models_generation_audit.sql`에서 관리한다. BMW 공식 라인업 누락 모델 X2/X4/X6/XM/Z4/i7/iX1/iX2/i3의 보수적 2026 현재 row는 `202606130007_bmw_missing_official_lineup_models.sql`에서 관리한다. Mercedes-Benz/Audi 공식 모델 overview에서 확인한 누락 모델 19개의 보수적 2026 현재 row와 공식 제원 미검수 placeholder 정리는 `202606130008_mercedes_audi_official_lineup_gap_models.sql`에서 관리한다.

후속 공식 라인업 gap 보강은 `202606130009_volvo_mini_official_lineup_gap_models.sql`, `202606130010_hyundai_kia_official_lineup_gap_models.sql`, `202606130011_volkswagen_official_lineup_gap_models.sql`, `202606130012_lexus_official_model_page_gap_models.sql`, `202606130013_porsche_electric_powertrain_boundaries.sql`, `202606130014_tesla_jeep_polestar_peugeot_official_gap_models.sql`에서 관리한다. Volvo EX30 Cross Country/ES90, MINI Cooper 5-Door/All-Electric MINI Cooper/All-Electric MINI Countryman/John Cooper Works, 현대 베뉴/캐스퍼 Electric/아이오닉 5 N/아이오닉 6 N/아이오닉 9/넥쏘/스타리아 Electric/ST1, 기아 EV4/EV5/PV5/타스만, 폭스바겐 Golf GTI/Atlas/ID.5, Lexus LC/RC, Tesla Cybertruck, Jeep Avenger, Polestar 5는 공식 홈페이지 또는 공식 보도자료에서 모델 존재만 확인한 row로 추가하고, 상세 세대 코드와 국내 제원 출처가 붙기 전까지 placeholder powertrain은 `pending_review`, `is_selectable=false`로 유지한다. Porsche Macan Electric/Cayenne Electric은 별도 모델 row가 아니라 마칸/카이엔의 2026 전기 파워트레인 후보로만 남기고, 이전 연식 전기 placeholder는 제거한다. Peugeot 308/3008/5008/408 SMART HYBRID는 2026년 powertrain 후보로만 반영한다.

## 10. Flutter 모델 변경

`VehicleGeneration`, `VehicleGenerationSummary`, `VehiclePowertrainChoice`를 추가하고 `VehicleSelectionStep.year`를 `VehicleSelectionStep.generation`으로 교체했다.

## 11. Repository 변경

`listGenerationsByFilter`, `listPowertrainsByGeneration`, `listModelYearsByGeneration`, `inferGenerationByYear`, `searchGenerations`를 추가했다. Supabase 미적용 환경은 mock/asset fallback으로 동작한다.

## 12. UI 변경

5단계는 “세대 선택”이며 세대명, 코드명, 판매 기간, 현재/예정 badge, 연료, 차급, 파워트레인 수, 검증 상태를 표시한다. 범주 필터는 `승용`, `SUV`, `EV`, `PBV`, `RV`, `택시 & 버스 & 상용`처럼 넓은 묶음으로 단순화했다.

## 13. 테스트 계획

단위 테스트는 broad category, generation summary, powertrain 적용 기간 grouping을 검증한다. Widget test는 아반떼 CN7 세대 선택과 K3 GT가 K3의 트림으로 표시되는 흐름을 검증한다.

## 14. P0/P1

P0:
- 세대 없이 기본 연식 선택으로 회귀
- source 없는 verified generation
- BMW source 없는 verified 노출
- K3 GT 별도 모델 재생성

P1:
- 제조사별 세대 coverage 부족
- 관리자 CRUD 실제 연결
- 공식 출처 수집 자동화
- 세대 내 연식별 제원 변경 보조 선택 UI
