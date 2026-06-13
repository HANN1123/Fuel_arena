# BMW 카탈로그 정리 리포트

## 요약

BMW 데이터는 공식 출처가 붙지 않은 상태로 verified 처리된 variant가 많았다. 첫 정리 단계에서 BMW variant를 `pending_review`로 낮추고 `is_selectable=false`로 전환했다. 이후 BMW 전기 모델 중 i4/i5/iX/iX3는 공식 BMW Group/BMW Korea 출처로 세대 row를 추가하고, 출시 전 placeholder 연식/variant를 seed 재생성 대상에서 제거했다. 추가로 BMW 1시리즈 F20/F40/F70, 2시리즈 쿠페 F22/G42, 3시리즈 F30/G20, 4시리즈 F32/G22 계열, 5시리즈 F10/G30/G60, 7시리즈 G11/G70, X1/X3/X5/X7 세대 row를 공식 출처 기반으로 연결하고, 1시리즈 F20, 2시리즈 쿠페, 3/4/5/7시리즈와 X3/X5/X7 placeholder 구동방식이 잘못 생성되지 않도록 검증을 추가했다.

## 현재 수량

- 현재 BMW 모델 row: 32개
- 현재 BMW generation row: 45개
- 현재 BMW powertrain/variant row: 280개
- 모델별 자동 감사 매트릭스: `docs/62_bmw_catalog_audit_matrix.md`

## 처리 내용

- `manufacturer_name=BMW`인 variant:
  - `is_verified=false`
  - `source_status=pending_review`
  - `confidence_score=0.1`
  - `is_selectable=false`
- BMW model row:
  - `source_status=pending_review`
- BMW generation row:
  - `1시리즈`: `2세대 F20`, `2012.10~2019`; `3세대 F40`, `2020.1~2024`; `4세대 F70`, `2024.10~현재`
  - `2시리즈 쿠페`: `1세대 F22`, `2013~2021`; `2세대 G42`, `2021.7~현재`
  - `3시리즈`: `6세대 F30`, `2012~2018`; `7세대 G20`, `2019.3~현재`
  - `4시리즈`: `1세대 F32/F33/F36`, `2013.10~2020`; `2세대 G22/G23/G26`, `2021.2~현재`
  - `5시리즈`: `6세대 F10 LCI`, `2015~2016`; `7세대 G30`, `2017~2023`; `8세대 G60`, `2023.10~현재`
  - `7시리즈`: `6세대 G11/G12`, `2015.10~2022`; `7세대 G70`, `2022.12~현재`
  - `X1`: `1세대 E84`, `2010.2~2015`; `2세대 F48`, `2016.2~2022`; `3세대 U11`, `2023.3~현재`
  - `X3`: `2세대 F25`, `2011~2017`; `3세대 G01`, `2017.11~2024`; `4세대 G45`, `2024.11~현재`
  - `X5`: `3세대 F15`, `2013.11~2018`; `4세대 G05`, `2018.11~현재`
  - `X7`: `1세대 G07`, `2019~현재`
  - `i4`: `1세대 G26`, `2022.4~현재`
  - `i5`: `1세대 G60`, `2024.3~현재`
  - `iX`: `1세대 i20`, `2022~현재`
  - `iX3`: `1세대 G08`, `2022~현재`
- BMW electric 출시 전 placeholder:
  - Supabase migration에서는 backend 호환을 위해 기존 model_year row를 삭제하지 않고 pre-launch variant를 `source_status=deprecated`, `is_selectable=false`, `is_deprecated=true`로 정리한다.
- BMW X7 출시 전 placeholder:
  - JSON seed에서는 2019년 이전 X7 model_year/variant를 생성하지 않는다.
  - Supabase migration에서는 기존 2015-2018 X7 variant가 있으면 `source_status=deprecated`, `is_selectable=false`, `is_deprecated=true`로 정리한다.

## 오류/감사 대상

- 잘못된 모델명: 전수 검토 필요
- 중복 모델: 2시리즈 쿠페처럼 Series/X/i/M/Z 계열 기준으로 재분류 필요
- fuelType 오류: electric, plug_in_hybrid, gasoline, diesel 분리 필요
- electric/PHEV/ICE 혼동: i 계열과 530e/750e 등 PHEV 분리 필요
- generation code 누락: 미처리 BMW 모델의 G/F/U/CLAR 등 코드 출처 확인 필요
- source 없는 verified: 이번 변경에서 선택 불가 pending_review로 낮춤
- deprecated 처리: i4 2022년 전, i5 2024년 전, iX/iX3 2022년 전, X7 2019년 전 placeholder variant는 deprecated 처리 대상이다.

## 검증 기준

- 공식 BMW Korea 가격표/제원표, 환경부/한국에너지공단 공개 데이터, 운영자 검수 파일 중 하나가 있어야 verified 가능
- source_name/source_url/source_file_name 없는 데이터는 verified 금지
- 한국 시장 판매 여부가 확인되지 않으면 selectable 금지
- `dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs`는 출처 없는 BMW row가 선택 가능하면 실패해야 한다.

## 추가 수급 필요

- 3/4/5/7 Series 세부 파워트레인/한국 판매 트림별 제원
- 1 Series와 2 Series Coupe 세부 파워트레인/한국 판매 트림별 제원
- i4/i5/iX/iX3 electric 파워트레인 세부 제원
- X1/X3/X5/X7 PHEV와 ICE 세부 파워트레인/한국 판매 트림별 제원
- M 모델과 일반 모델의 모델/트림 경계
