# Store Privacy Disclosures

Fuel Arena의 Play Console 데이터 보안 섹션과 App Store Connect 앱 개인정보 라벨 초안은 `assets/store/privacy_disclosures_ko.json`에 정리한다.

## 검증 명령

```bash
python tool/validate_store_privacy_disclosures.py
```

## 제출 원칙

- 정확한 위치와 대략적 위치는 주행 검증, 리그 계산, 부정 이용 방지 목적의 수집 항목으로 신고한다.
- Google 계정 식별자와 Supabase 사용자 ID는 사용자 ID로 신고한다.
- 프리미엄 결제 상품 ID와 transaction id는 구매 내역으로 신고한다. 카드번호 같은 결제 정보는 앱이 직접 수집하지 않는다.
- 광고 이벤트, 광고 ID 또는 SDK 식별자는 AdMob 설정과 맞춰 광고/마케팅 및 보상형 광고 검증 항목으로 신고한다.
- 고객지원, 신고, 이의제기, 개인정보 요청은 고객지원/앱 기능 목적의 사용자 제공 데이터로 신고한다.
- raw drive_points와 정확한 좌표는 공개 화면에 노출하지 않는다고 legal 페이지와 스토어 설명에 함께 명시한다.

## iOS Privacy Manifest

- `ios/Runner/PrivacyInfo.xcprivacy`는 Runner target resources에 포함한다.
- 앱 자체 manifest는 `NSPrivacyTracking=false`로 둔다. AdMob/Google SDK privacy manifest, ATT 필요 여부, UMP 동의 흐름은 실제 production 광고 콘솔 설정 후 다시 확인한다.
- `NSPrivacyAccessedAPICategoryUserDefaults`는 앱 내부 설정 저장 목적의 `CA92.1` reason으로 선언한다.

## Android Data Safety

- Android manifest에는 위치 권한, 알림 권한, 광고 ID 권한을 명시한다.
- Play Console 제출 전 실제 AdMob live App ID, reward/native unit ID, 개인 맞춤 광고 동의 흐름, 데이터 공유 항목이 `privacy_disclosures_ko.json`과 일치하는지 확인한다.
