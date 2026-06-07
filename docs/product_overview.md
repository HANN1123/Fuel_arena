# Fuel Arena Product Overview

Fuel Arena는 단순한 연비 기록 앱이 아니다. 연비와 주행 효율 점수로 경쟁심을 자극하는 게임형 드라이빙 플랫폼이다.

핵심 문장:

- 기름값을 아끼는 앱이 아니라, 이기고 싶어서 자연스럽게 아끼게 만드는 앱.
- 연비를 관리하는 앱이 아니라, 연비로 경쟁하는 게임형 드라이빙 플랫폼.

## 사용자 감정

Fuel Arena는 사용자가 다음 감정을 느끼도록 설계한다.

- 지금 내가 경쟁 중이다.
- 누가 내 순위를 추월했는지 궁금하다.
- 라이벌을 이기고 싶다.
- 승급까지 조금 남아서 한 번 더 주행하고 싶다.
- 오늘 미션을 놓치고 싶지 않다.
- 내 차량과 기록을 자랑하고 싶다.
- 광고는 억지 시청이 아니라 보상 선택지처럼 느껴진다.
- 프리미엄을 쓰면 더 깊게 분석하고 더 멋지게 경쟁할 수 있을 것 같다.

## 초기 구현 범위

Phase 1:

- Splash
- Onboarding
- Google Login
- Additional Setup
- Vehicle Setup
- Main Shell
- Home
- Bottom Navigation

Phase 2:

- Drive Start
- Safety Drive
- Drive Result
- Ranking
- Battle
- Season
- Profile

차량 설정은 로그인 직후 강제하지 않는다. 사용자는 홈에 먼저 들어갈 수 있고, 주행/랭킹/배틀/시즌 참여 시 대표 차량을 설정한다.

랭킹과 배틀은 가솔린, 디젤, 하이브리드, 전기차, LPG, 플러그인 하이브리드, 기타 리그를 분리한다.

Phase 3:

- Reward Ads
- Premium
- Sponsor Challenge
- Reward Wallet
- Stats
- Fairness Center
- Settings

Phase 3은 route와 mock 데이터 기반 실제 화면 흐름을 함께 구현한다.

## 디자인 방향

전체 콘셉트는 프리미엄 자동차 디지털 계기판, 경쟁형 모바일 게임 UI, e-sports 리더보드의 교집합이다.

- 다크 테마 기반
- 블랙, 차콜, 그라파이트 배경
- 네온 그린은 핵심 액션과 점수 강조
- 전기 블루는 데이터, 분석, 신뢰 요소
- 앰버는 경고, 긴장감, 시즌 종료 임박
- 골드는 프리미엄, 한정 보상, 상위권 보상
- 레드는 패배, 순위 하락, 오류, 비정상 기록 감지
- 숫자, 점수, 랭킹, 티어, 보상 진행도를 크게 보여준다.
- Stitch HTML/CSS는 분위기와 구조 참고용이며 Flutter 네이티브 위젯으로 재구현한다.

## 광고 원칙

- 주행 중 광고 금지
- 주행 시작 전 광고 금지
- 배틀 진행 중 광고 금지
- 광고는 선택형 보상으로만 제공
- 광고를 보지 않아도 기본 보상 지급
- 프리미엄 사용자는 광고 제거
- 광고 라벨을 명확히 표시

## 금지 범위

- HTML WebView 기반 UI
- 클라이언트에 Supabase service_role key 포함
- 현금성 베팅 기능
- 주행 중 광고, 팝업, 도전장
- 모든 로직을 `main.dart`에 집중시키는 구조
