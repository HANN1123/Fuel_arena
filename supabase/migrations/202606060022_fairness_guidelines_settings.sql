insert into public.app_settings (key, value, description, is_public)
values
  (
    'fairness_guidelines',
    '{"items":["전기차는 전기차끼리, 하이브리드는 하이브리드끼리 비교합니다.","공정한 비교를 위해 연료 타입과 차급을 함께 사용합니다.","다른 리그와의 배틀은 친선전으로 기록됩니다.","정확한 위치 경로는 공개 랭킹에 노출하지 않습니다.","비정상 급가속, 급제동, GPS 이상 기록은 검증 대기 상태가 됩니다.","최종 점수는 서버 검증 후 랭킹에 반영됩니다."]}',
    '공정성 센터 공개 가이드 문구',
    true
  )
on conflict (key) do update set
  value = excluded.value,
  description = excluded.description,
  is_public = excluded.is_public;
