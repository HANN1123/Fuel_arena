# Store Listing Assets

Fuel Arena의 스토어 등록 초안 자산은 `tool/generate_store_assets.py`로 생성한다.

## 생성 명령

```bash
python tool/generate_store_assets.py
python tool/validate_store_submission_assets.py
```

## 생성 산출물

- `assets/store/store_listing_ko.json`: 한국어 앱 이름, 짧은 설명, 긴 설명, 키워드, legal URL, 스크린샷 목록
- `assets/store/feature_graphic_1024x500.png`: Google Play feature graphic 초안
- `assets/store/screenshots/phone/01_home_league.png`
- `assets/store/screenshots/phone/02_vehicle_catalog.png`
- `assets/store/screenshots/phone/03_drive_score.png`
- `assets/store/screenshots/phone/04_battle_season.png`
- `assets/store/screenshots/phone/05_privacy_fairness.png`

## 메시지 원칙

- Fuel Arena는 연비 기록장이 아니라 주행 효율 경쟁 플랫폼이라는 점을 첫 화면에서 드러낸다.
- 차량 선택은 판매 트림/휠 인치가 아니라 차종, 기준 연식, 엔진·미션 파워트레인 기준임을 명확히 한다.
- 주행 중 광고, 팝업, 도전장, 불필요한 알림을 표시하지 않는 안전 정책을 포함한다.
- 정확한 위치 좌표와 raw drive_points가 공개 화면에 노출되지 않는다는 privacy guard를 포함한다.
- 스토어 등록 전 실제 배포 도메인의 `/legal/privacy/`, `/legal/location/`, `/legal/account-deletion/`, `/legal/terms/` URL을 연결한다.
- 제출 전 `python tool/validate_store_submission_assets.py`로 한국어 문구 깨짐, 이미지 크기·용량·색상 복잡도·UI 대비, legal 정적 페이지 누락과 문서별 핵심 한국어 문구를 검사한다.
- 배포 도메인이 준비되면 `python tool/validate_store_submission_assets.py --base-url https://example.com` 형태로 실제 공개 legal URL의 Fuel Arena legal 본문도 확인한다.

## 남은 외부 작업

- Play Console/App Store Connect에 실제 앱 ID, IAP 상품 ID, 개인정보 URL, 스크린샷을 등록한다.
- 스토어 심사 전 실기기에서 로그인, 주행, 결제 sandbox, 광고 SDK live/test 전환을 확인한다.
