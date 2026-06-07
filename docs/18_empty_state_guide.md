# Empty State Guide

## 원칙
- 검은 빈 화면을 만들지 않는다.
- 검색 결과 없음, 차량 없음, 권한 없음, 네트워크 없음은 각각 행동 가능한 CTA를 제공한다.
- “준비 중입니다”만 표시하지 않는다.

## 필수 요소
- 제목.
- 왜 비어 있는지 설명.
- 사용자가 다음에 할 수 있는 CTA.
- retry가 가능한 경우 retry action.

## 대표 카피
- 차량 없음: “차량을 설정하면 내 연료 타입과 차급에 맞는 리그에 배정됩니다.”
- 검색 결과 없음: “차량을 직접 입력하면 운영팀 검토 후 공식 리그에 반영됩니다.”
- 오프라인: “주행 기록은 기기에 임시 저장했어요. 연결되면 자동으로 업로드됩니다.”
- 권한 없음: “정확한 주행 기록을 위해 위치 권한이 필요해요.”

## 구현 기준
- `EmptyStateView`를 우선 사용한다.
- 사용자 route의 CTA는 실제 route 이동 또는 repository action에 연결한다.
- 관리자 route의 작업 안내는 명령 dialog나 운영 화면으로 연결한다.

## 제품 route 기준
- 통계 없음: `/stats` → `/drive/start`.
- 쿠폰 없음: `/rewards` → `/ads/reward`.
- 스폰서 챌린지 없음: `/sponsor` → `/drive/start`.
- 프리미엄 요금제 없음: `/premium` → `/support/contact`.
- 네트워크/저장소 오류: retry action으로 관련 provider를 invalidate한다.
