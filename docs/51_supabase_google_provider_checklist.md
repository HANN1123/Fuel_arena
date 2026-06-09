# Supabase Google Provider 설정 및 DB 검증 체크리스트 (Supabase Google Provider Setup Guide)

Supabase 프로젝트 대시보드와 데이터베이스단에서 구글 로그인 통합의 무결성을 확보하기 위한 운영 체크리스트입니다.

---

## 1. Supabase 대시보드 인증 공급자 설정
Supabase 콘솔 -> **Project Settings** -> **Authentication** -> **OAuth Providers** -> **Google**로 진입합니다:
1. **Google Enabled**: 활성화 (토글 ON)
2. **Client ID**: Google Cloud Console에서 발급받은 **Web Client ID** 입력 (Android/iOS 클라이언트 ID가 아님에 주의)
3. **Client Secret**: Google Cloud Console에서 발급받은 **Web Client Secret** 입력
4. **Skip Nonce Check**: 기본값 유지 (또는 네이티브 인증을 위해 비활성화 상태 확인)

---

## 2. Site URL & Redirect Allow-list 등록 규정
사용자가 구글 로그인을 거친 후 올바른 호스트로 리다이렉트되도록 구성합니다.
- **Site URL**:
  - Staging: `https://staging.fuelarena.example.com`
  - Production: `https://fuelarena.example.com` (실제 배포 도메인)
- **Redirect URL Allow-list (승인된 리디렉션 목록)**:
  - `fuelarena://login-callback` (모바일 Native 앱 딥링크 콜백)
  - `http://localhost:5000` (Local Web 개발용 - **Production 프로젝트에서는 반드시 제거해야 함**)
  - `https://staging-web.fuelarena.example.com` (Staging 웹 버전)

---

## 3. Google Cloud Console Redirect URI 동기화
- Supabase Google OAuth Provider 카드 상단의 **Redirect URI** (`https://<project-id>.supabase.co/auth/v1/callback`)를 복사합니다.
- **Google Cloud Console** -> **사용자 인증 정보** -> **Web Client ID** 상세 설정으로 이동합니다.
- **승인된 리디렉션 URI** 아래에 해당 값을 추가합니다.

---

## 4. 데이터베이스 마이그레이션 및 트리거 무결성 검증
구글 로그인 성공 시 `auth.users` 테이블과 `public.profiles` 테이블의 레코드가 정상적으로 동기화되고 `last_login_at` 속성이 연동되는지 검증합니다.

### A. RLS (Row Level Security) 정책 및 트리거 존재 점검 SQL
```sql
-- public.profiles 테이블 RLS 정책 활성화 여부 확인
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'profiles';

-- auth.users의 insert 발생 시 profiles에 행을 삽입하는 트리거 점검
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers
WHERE event_object_table = 'users' AND event_object_schema = 'auth';
```

### B. 사용자 연동 상태 및 last_login_at 갱신 검증 SQL
실제 구글 로그인 시도 후 데이터가 올바르게 입수되었는지 모니터링하기 위한 유용한 SQL 쿼리 목록입니다:

```sql
-- 1. 최근 구글 로그인을 성공한 사용자 목록 및 last_login_at 시점 검증
SELECT 
  u.id AS user_id,
  u.email,
  p.nickname,
  p.auth_provider,
  p.last_login_at
FROM auth.users u
JOIN public.profiles p ON u.id = p.id
ORDER BY p.last_login_at DESC
LIMIT 5;

-- 2. profiles가 성공적으로 자동 연동 생성(Bootstrap) 되었는지 확인
SELECT COUNT(*) 
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL; -- 결과값이 0이어야 동기화 오류가 없는 상태입니다.
```
