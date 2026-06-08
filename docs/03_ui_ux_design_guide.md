# UI/UX 디자인 가이드

## 방향
프리미엄 자동차 디지털 계기판, 경쟁형 모바일 게임 UI, e-sports 리더보드의 균형을 유지한다.

## 색상
- Deep Black: 전체 배경
- Graphite/Charcoal: 카드와 보조 표면
- Neon Green: 핵심 CTA, 상승, 보상, 효율
- Electric Blue: 데이터, 분석, 신뢰
- Amber/Gold: 경고, 시즌, 프리미엄, 한정 보상
- Red: 오류, 하락, 비정상 기록

## 타이포그래피
숫자는 굵고 명확하게 표시한다. letter spacing은 0으로 유지한다.

## 컴포넌트
AppScaffold, FuelArenaAppBar, MainBottomNavigation, AppCard, StatusChip, TierBadge, ScoreGauge, BattleCard, MissionCard, SeasonProgressCard, DriveResultCard, AdRewardCard, PremiumBadge 계열을 재사용한다.

## 인증 UX
로그인 화면은 Google 계정 단일 CTA만 제공한다. 이메일/비밀번호 입력, 소셜 로그인 다중 선택, 가입 폼 링크는 노출하지 않는다. production 모드에서 Web/Android/iOS/Server Google OAuth client ID, iOS reversed client ID, `fuelarena://login-callback` callback 설정이 누락되거나 형식이 맞지 않으면 로그인 화면이 아니라 설정 오류 화면으로 안내한다.

## 차량 설정 UX
차량 설정은 제조사 → 모델/파생모델 → 기준 연식 → 엔진·미션 파워트레인 → 확인 순서의 스텝퍼다. 각 단계는 뒤로 돌아가도 이전 선택을 유지하고, 다음 선택이 바뀌면 하위 단계만 초기화한다. 기준 연식은 카드 그리드가 아니라 클릭 후 하단에서 펼쳐지는 피커/스크롤 리스트로 선택한다. 판매 트림과 휠 인치수는 선택 축으로 쓰지 않고, 카탈로그에 없는 차량은 검토 대기 요청으로 접수한다.

## 리그 UX
대표 차량이 없으면 홈, 랭킹, 배틀, 시즌, 주행 시작에서 차량 설정 CTA를 보여준다. 대표 차량이 있으면 `가솔린 준중형 리그`처럼 연료 리그와 차급을 함께 보여준다. 다른 연료 리그와의 배틀은 친선전 칩으로 표시한다.

## 광고 UX
광고는 배너가 아니라 선택형 보상 카드로 표현한다. 주행 중에는 광고를 표시하지 않는다.

## 안전 모드 UX
주행 중에는 알림, 광고, 팝업, 도전장을 차단하고 기록과 종료 버튼만 명확하게 유지한다. 종료 확인이 필요할 때도 모달을 띄우지 않고 같은 화면 안에서 `한 번 더 눌러 종료` 상태로 확인한다.

