# Supabase Setup

1. Supabase 프로젝트를 생성한다.
2. `.env`에 `SUPABASE_URL`과 `SUPABASE_ANON_KEY`를 설정한다.
3. `supabase db push` 또는 Dashboard SQL editor로 migration을 적용한다.
4. `supabase functions deploy calculate_drive_score`처럼 각 Edge Function을 배포한다.
5. Storage bucket `vehicle-images`를 생성한다.
6. service_role key는 Edge Function secrets에만 저장하고 Flutter 앱에는 넣지 않는다.

## 실행 모드
- dev: Supabase 키가 없어도 mock repository 사용
- staging: Supabase 필수, test ad unit 사용
- production: Supabase 필수, live ad와 실제 IAP 상품 필요

