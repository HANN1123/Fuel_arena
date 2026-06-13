# 제조사별 모델/세대 Coverage 계획

## 우선순위

국산 우선순위:
- 현대
- 기아
- 제네시스
- 쉐보레
- 르노코리아
- KG모빌리티

수입 우선순위:
- BMW
- 메르세데스-벤츠
- 아우디
- 폭스바겐
- 토요타
- 렉서스
- 혼다
- 테슬라
- 볼보
- 포르쉐
- MINI
- 푸조
- 지프
- 랜드로버
- 폴스타

## 필수 데이터

- 제조사
- 모델
- 세대명
- 세대 코드
- 판매 기간
- 연료 타입
- 파워트레인
- 차급
- bodyType
- marketRegion
- sourceStatus
- confidenceScore
- sourceName/sourceUrl/sourceFileName

## 처리 방식

- 모델/세대/파워트레인을 임의 생성하지 않는다.
- 공식 출처가 없으면 `unverified` 또는 `pending_review`로 둔다.
- source 없는 `verified_official`, `verified_admin`은 validation 실패로 처리한다.
- K3 GT처럼 모델이 아니라 트림인 항목은 모델 row를 만들지 않고 K3의 powertrain/trim으로 관리한다.
- 직접 입력 차량은 `pending_review`로 저장하고 공식 리그에는 즉시 반영하지 않는다.

## Import 구조

- `assets/data/vehicle_catalog_sources/generation_template.csv`
- `assets/data/vehicle_catalog_sources/powertrain_generation_template.csv`
- JSON seed의 `generations` 배열
- Supabase `vehicle_generations`, `vehicle_generation_years`

## Coverage 리포트

`dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`

출력 기준:
- total generations
- models without generation
- generations without powertrain
- powertrains without generation
- verified generations without source
- BMW pending_review count
- generation coverage by manufacturer

자동 산출물:
- `docs/61_vehicle_catalog_coverage_report.md`
- `docs/62_bmw_catalog_audit_matrix.md`

## 현재 known gaps

- 모든 seed 모델은 세대 row에 연결되어 있고, 자동 리포트 기준 `models without generation = 0`이다. 다만 Volkswagen/Toyota/Lexus/Honda/Nissan/Tesla/Porsche/MINI/Peugeot/Jeep/Land Rover/Polestar의 다수 row는 아직 보수적 `공식 라인업` 세대이므로 세대 코드/플랫폼 코드/상세 powertrain 검증 전까지 `pending_review`로 유지한다.
- BMW는 모든 seed 모델에 세대 row를 연결했고, 5시리즈 2015-2016 placeholder는 BMW Korea PressClub `F10 LCI` 자료를 근거로 `generation-bmw-5series-f10`에 연결했다. 공식 모델 라인업에서 확인한 X2, X4, X6, XM, Z4, i7, iX1, iX2, i3에 더해 2시리즈 그란 쿠페, 8시리즈, M2, M3, M4, M5, M8, X5 M, X6 M을 2026 현재 공식 라인업 모델로 보강했다. 세부 파워트레인은 공식 제원 출처가 붙기 전까지 `pending_review`, `is_selectable=false`로 유지하고, placeholder 수치 제원은 비워 둔다.
- 기아는 모든 seed 모델에 세대 row를 연결했다. K3 2015-2017 placeholder는 Kia 공식 소프트웨어 버전 목록의 `K3 YD` 표기 근거로 `generation-kia-k3-yd`에 연결했고, K3 2018-2024는 기존 BD row를 유지한다. K8, 셀토스, 니로, EV3, EV6, EV9의 출시 전 placeholder 연식은 seed에서 제거하고 Supabase legacy row는 deprecated/non-selectable로 낮춘다. EV4, EV5, PV5, 타스만은 Kia Korea 공식 모델/EV 라인업 페이지에서 확인한 2026 현재 모델 row로 추가했고, 상세 세대/파워트레인 제원 감사 전까지 `pending_review`, `is_selectable=false` placeholder를 유지한다. Kia EV/PBV/택시&상용 공식 카드의 EV3 GT, EV4 GT, EV5 GT, EV6 GT, EV9 GT, PV5 패신저/카고/WAV/오픈베드/택시, K8 택시, 봉고 특장/EV 카드는 독립 모델 row가 아니라 기존 모델의 powertrain/trim 후보로 보강했으며, row-level 제원 검증 전까지 모두 비선택 pending 상태로 둔다.
- 현대는 모든 seed 모델에 세대 row를 연결했다. 아반떼 AD/CN7, 아반떼 N CN7 N, 아반떼 스포츠 AD Sport, 쏘나타 LF/DN8, 그랜저 HG/IG/GN7, 코나 OS/SX2, 투싼 TL/NX4, 싼타페 DM/TM/MX5, 팰리세이드 LX2/LX3, 캐스퍼 AX1, 아이오닉 5 NE/NE PE, 아이오닉 6 CE/CE PE, 스타리아 US4, 포터 II HR을 포함한다. 베뉴, 캐스퍼 Electric, 아이오닉 5 N, 아이오닉 6 N, 아이오닉 9, 넥쏘, 스타리아 Electric, ST1은 현대 공식 모델 페이지 기준 2026 현재 row로 추가했고, 넥쏘는 수소전기차 리그 `hydrogen`/`km/kg`를 사용한다. 아반떼 AD는 Hyundai Motor 공식 아반떼 History와 현대 AutoEver 소프트웨어 버전 목록 근거로 2015-2019 model_year만 연결했고, 아반떼 스포츠 AD Sport는 코드 출처 추가 확인 전까지 `pending_review`로 유지한다.
- 제네시스는 10개 seed 모델 모두 세대 row에 연결했다. G70 슈팅 브레이크, Electrified G80, Electrified GV70, GV80 Coupe는 공식 라인업 기준의 명시 모델 ID로 추가했고, G80/GV70의 전기차 placeholder는 별도 Electrified 모델로 분리한다.
- 르노코리아는 기존 seed 모델 모두 세대 row에 연결했다. Arkana와 Filante는 공식 라인업 기준 명시 모델 ID로 추가했고, Scenic E-Tech는 르노코리아 공식 가격표/브로슈어 근거의 2025~현재 `pending_review` 모델 row로 보강했다. SM6/QM6/XM3는 현행 공식 모델 페이지가 없어 `pending_review`로 유지하고, 단종 후 placeholder는 생성하지 않는다.
- KG모빌리티는 공식 국내 모델 목록 기준으로 세대 row를 정리했다. 액티언/액티언 하이브리드, 토레스 하이브리드/EVX, 토레스 밴/EVX 밴, 렉스턴 써밋, 무쏘/무쏘 EV를 공식 라인업 기준 명시 모델 ID로 추가했다. 공식 페이지에서 확인되지 않는 코드명은 비워 두고, 코란도는 국내 현재 MODEL_LIST 카드에 없어 2019~2024 `pending_review`로 유지한다. 토레스 밴/EVX 밴과 렉스턴 써밋은 모델 카드 존재만 확인했으므로 상세 제원 감사 전까지 `pending_review`, `is_selectable=false` powertrain으로 유지한다.
- Mercedes-Benz는 모든 seed 모델에 세대 row를 연결했다. EQA는 2021년, EQB/EQE는 2022년, EQS는 2021년 이전 placeholder 연식을 seed에서 제거하고 Supabase legacy row는 deprecated/non-selectable로 낮춘다. Mercedes-Benz Korea 모델 overview에서 확인한 S-Class Long, Mercedes-Maybach S-Class, EQE SUV, Mercedes-Maybach EQS SUV, GLB, GLC Coupé, GLE Coupé, Mercedes-Maybach GLS, G-Class, CLA Coupé, CLE Coupé, Mercedes-AMG GT Coupé, Mercedes-AMG GT 4-Door Coupé, CLE Cabriolet, SL Roadster, Mercedes-Maybach SL Monogram Series는 2026 현재 공식 라인업 row로 추가했고, 상세 세대 코드/국내 파워트레인 제원 감사 전까지 `pending_review`, `is_selectable=false`로 유지한다.
- Audi는 모든 seed 모델에 세대 row를 연결했다. A4는 2024년까지, A7/e-tron은 2025년까지 seed model_year를 생성하고, Q8은 2018년, Q4 e-tron은 2021년부터 생성한다. Supabase legacy placeholder는 deprecated/non-selectable로 낮춘다. Audi Korea 모델 overview에서 확인한 e-tron GT, A6 e-tron, Q6 e-tron은 2026 현재 공식 라인업 row로 추가했고, 상세 세대 코드/국내 파워트레인 제원 감사 전까지 `pending_review`, `is_selectable=false`로 유지한다.
- Chevrolet은 모든 seed 모델에 세대 row를 연결했다. Chevrolet Korea 공식 SUV 라인업 페이지에서 확인한 이쿼녹스는 명시 모델 ID로 추가했고, 트래버스/타호는 2026 현재 공식 홈페이지 노출 경계로 보강했다. 스파크/말리부/볼트 EV의 단종 후 placeholder와 트레일블레이저/콜로라도/볼트 EV의 출시 전 placeholder는 seed에서 제거하고 Supabase legacy row는 deprecated/non-selectable로 낮춘다. 단, row-level 공식 제원 출처가 부족한 row가 섞여 있어 source_status는 `pending_review`로 유지한다.
- Volvo는 모든 seed 모델에 세대 row를 연결했다. S60 P3/SPA, S90 SPA, XC40 CMA, XC60 P3/SPA, XC90 SPA, C40 CMA, EX40, EC40, EX30, EX90, V60 Cross Country SPA를 포함하며, Volvo Korea 현재 라인업에 있는 V60 Cross Country는 명시 ID `model-volvo-v60-cross-country-kr`로 추가했다. EX40/EC40은 Volvo 공식 명칭 변경 공지와 지원 자료 기준으로 XC40 Recharge/C40 Recharge의 2025년 이후 공식명 row로 분리했고, EX30 Cross Country와 ES90은 Volvo 공식 출시/사전계약 자료 기준의 2026 현재 라인업 row로 추가했다. 국내 상세 가격표/제원 감사를 마치기 전까지 source_status는 `pending_review`로 유지한다.
- 공식 홈페이지에서 확인한 누락 모델 Toyota Alphard, Lexus LM/LX/LC/RC, Chevrolet Equinox, MINI Aceman, MINI Cooper 5-Door, All-Electric MINI Cooper, All-Electric MINI Countryman, John Cooper Works, Peugeot 408, Jeep Gladiator, Jeep Grand Cherokee L, Land Rover Discovery Sport, Range Rover Velar, Volkswagen Golf GTI, Atlas, ID.5, Tesla Cybertruck, Jeep Avenger, Polestar 5를 명시 모델 ID로 추가했다. Lexus LS 500은 별도 모델이 아니라 LS 모델의 가솔린 powertrain 후보로 반영했다. Peugeot 308/3008/5008/408은 현행 공식 라인업의 SMART HYBRID 후보를 2026년 `pending_review` powertrain으로 반영했다. 모델 존재는 공식 출처로 확인했지만 상세 세대 코드/국내 powertrain 제원 감사 전까지 `pending_review`로 유지한다. Jeep Trail Hunt 같은 edition/trim 명칭, Kia GT/PBV/택시/상용 카드명, Tesla Model Y L 같은 모델 버전은 별도 모델 row로 올리지 않고 기존 모델의 powertrain/trim 후보로 관리한다.
- Porsche Macan Electric과 Cayenne Electric은 공식 Porsche Korea 모델 버전으로 확인했지만 독립 모델 row로 분리하지 않고 기존 마칸/카이엔의 전기 파워트레인 경계로 관리한다. 2026년 전기차 placeholder만 남기고 이전 연식 전기 placeholder는 제거하며, 상세 제원 출처가 붙기 전까지 `pending_review`, `is_selectable=false`를 유지한다.
- 관리자 화면은 skeleton 구조만 있으며 실제 CRUD/RPC 연결이 필요하다.
- 세대 내 연식별 제원 변경 시 보조 연식 선택 UI가 아직 자동 노출되지 않는다.

## 다음 공식화 우선순위

자동 리포트 기준 generation 미연결 모델과 generation 미연결 powertrain은 모두 0이다. 다음 우선순위는 공식 한국 홈페이지 또는 공식 미디어/가격표를 기준으로 보수적 `공식 라인업` row를 실제 세대명/코드명/플랫폼/판매 기간으로 쪼개고, 공식 제원표가 붙은 powertrain만 `verified_official` 승격 후보로 분리하는 것이다. 추가 확인 후보는 현대/기아/Volkswagen/Lexus/Porsche 신규 row의 국내 가격표 제원 감사, Lexus LX/LS 500의 상세 제원표 확인, Toyota/Honda의 현행 국내 라인업 주기적 재확인, Mercedes-Benz/Audi의 body-style 모델별 실제 국내 세대 코드 감사 등이며 공식 출처 확인 전에는 seed에 `verified`로 넣지 않는다.

## 2026-06-13 Jeep Wrangler Trail Hunt Boundary Update

- Jeep Korea official home and edition pages were re-checked for `WRANGLER TRAIL HUNT EDITION`.
- Trail Hunt is treated as a Wrangler edition/trim card, not a standalone `vehicle_models` row.
- Added one 2026 Wrangler gasoline powertrain/trim candidate (`variant-jeep-wrangler-2026-trail-hunt-pending`) under `model-jeep-152-kr`; the base 2026 Wrangler gasoline placeholder now carries official Wrangler page source metadata.
- Both rows stay `pending_review`, `is_selectable=false`, `is_verified=false`, with null numeric specifications until official row-level domestic specs are attached.
- Migration: `supabase/migrations/202606130034_jeep_trail_hunt_official_card_placeholder.sql`.
