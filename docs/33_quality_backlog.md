# 제품 품질 및 데이터 백로그 (docs/33)

본 백로그는 Fuel Arena 플랫폼의 안정성과 데이터 신뢰도를 유지하기 위해 관리되는 이슈 트래킹 목록입니다.

---

## 1. 품질 이슈 목록

| ID | 우선순위 | 영역 | 경로/컴포넌트 | 이슈 내용 | 기대 동작 | 상태 | 담당자 |
|---|---|---|---|---|---|---|---|
| **QA-001** | 🔴 P0 | 데이터 | `assets/data/vehicle_catalog_kr_seed.json` | 포르쉐 박스터 모델의 구동방식이 FWD로 오지정되어 있음 | drivetrain을 RWD로 전면 수정 | `Progress` | 데이터 품질팀 |
| **QA-002** | 🔴 P0 | 스키마 | Supabase DB / `vehicle_powertrains` | 차량 카탈로그에 `source_status` 및 `confidence_score` 컬럼 부재 | 스키마 보강 및 RLS 정책 강화 | `Progress` | 시스템 백엔드 |
| **QA-003** | 🔴 P0 | 정책 | `lib/features/vehicle/domain/powertrain_validator.dart` | `source` 정보가 명시되지 않은 데이터가 `verified_official`로 간주될 수 있음 | 출처 없는 verified 등급 지정을 차단하고 unverified 상태로 자동 강등 | `Progress` | 도메인 개발 |
| **QA-004** | 🟡 P1 | 파이프라인 | `tool/vehicle_catalog/` | 한국에너지공단(KEA) 공인 연비 및 효율 CSV import 파이프라인 부재 | 외부 KEA 연비 데이터 CSV를 읽어 fuzzy match 및 conflict 감지 후 DB에 반영하는 스크립트 작성 | `Progress` | 데이터 품질팀 |
| **QA-005** | 🟡 P1 | UI/UX | `VehicleSetupScreen` | 차량 트림/엔진 선택 시 검증 상태(verified 배지)와 출처 정보(source)가 노출되지 않음 | 각 카드에 신뢰 뱃지를 보여주고, 출처 보기 BottomSheet를 연동해 공신력 있는 출처 표시 | `Progress` | 프론트엔드 |
| **QA-006** | 🟡 P1 | 정책 | `lib/features/vehicle/domain/vehicle_catalog_integrity_validator.dart` | 전기차인데 배기량(displacement_cc)이 있거나, 내연기관인데 배터리 사양만 있는 모순된 데이터 검출 실패 | 무결성 검증기(Integrity Validator)를 통해 위반 시 validation error 처리 | `Progress` | 도메인 개발 |
| **QA-007** | 🟢 P2 | 관리자 | `AdminVehicleCatalogScreen` | 사용자 직접 입력 차량(`custom_vehicle_requests`)에 대한 승인/반려 및 충돌 해결 UI의 연동 미흡 | 관리자 전용 custom request 검수 화면 및 conflict 해결 화면 추가 | `Progress` | 프론트엔드 (Admin) |
| **QA-008** | 🟢 P2 | UI/UX | `/support/faq`, `/profile/badges` | FAQ 및 배지 화면 등에 Lorem Ipsum 및 미구현 임시 placeholder 화면 존재 | 실제 연동 가능한 도움말 DB 및 badges mock 데이터로 뷰 연동 | `Progress` | 프론트엔드 |
| **QA-009** | 🔵 P3 | CI/CD | `.github/workflows/` | GitHub Actions CI 빌드에 차량 카탈로그 무결성 검증 단계 부재 | P0 이슈 및 UI placeholder 발견 시 빌드를 실패하게 하는 커스텀 dart 스크립트를 CI 워크플로우에 연동 | `Progress` | DevOps |
