# Release Checklist

## Android
- 앱 이름 Fuel Arena 확인
- 위치 권한, 인터넷 권한 확인
- AdMob App ID 설정 확인
- debug signing과 release signing 분리

## iOS
- 앱 이름 Fuel Arena 확인
- 위치 권한 설명 확인
- 광고 추적 안내 필요 여부 확인
- App Store 인앱결제 상품 ID 확인

## 개인정보와 위치정보
- 개인정보 처리방침 URL 준비
- 위치정보 이용 고지 준비
- 회원 탈퇴와 데이터 삭제 요청 UI 확인
- drive_points 공개 노출 차단 확인

## 광고와 결제
- test ad unit 제거
- live ad ID 설정
- IAP 상품 ID와 가격 확인
- dev/mock purchase가 production에서 비활성 또는 실제 결제로 전환되는지 확인

## Supabase
- production migration 적용
- RLS 활성화 확인
- Edge Function secrets 설정
- service_role key 클라이언트 미포함 확인

