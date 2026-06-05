# RLS Policy Notes

## 원칙
사용자 개인 데이터는 본인만 접근한다. 공개 경쟁 화면은 제한된 public view 또는 ranking row만 사용한다.

## 보호 데이터
- drive_points: 정확한 좌표 raw path, 본인만 접근
- drive_sessions: 본인 주행 상세, 본인만 접근
- app_consents: 본인 동의 내역, 본인만 접근
- user_coupons, user_subscriptions: 본인만 접근

## 공개 데이터
rankings와 battles는 공개 경쟁에 필요한 제한 정보만 읽을 수 있다. 위치 좌표와 이메일은 공개하지 않는다.

## Admin
관리자 작업은 profiles.is_admin 또는 admin claim을 확인하는 Edge Function과 admin 전용 view로 확장한다.

## service_role
service_role key는 Flutter 앱에 포함하지 않는다. 서버 권한 작업은 Edge Function에서 처리한다.

