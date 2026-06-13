-- K3 GT is a K3 trim/powertrain, not a standalone vehicle model.
-- The canonical K3 GT variants live under model-kia-013-k3.

update public.user_vehicles uv
set
  vehicle_variant_id = null,
  verification_status = 'pending_review',
  updated_at = now()
where uv.vehicle_variant_id in (
  select vv.id
  from public.vehicle_variants vv
  join public.vehicle_model_years vmy on vmy.id = vv.model_year_id
  where vmy.model_id = 'model-kia-k3-gt-kr'
);

delete from public.vehicle_models
where id = 'model-kia-k3-gt-kr';
