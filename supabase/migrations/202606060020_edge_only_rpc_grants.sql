revoke all on function public.recompute_rankings(text) from public;
revoke all on function public.recompute_rankings(text) from anon;
revoke all on function public.recompute_rankings(text) from authenticated;
grant execute on function public.recompute_rankings(text) to service_role;

revoke all on function public.claim_mission_reward(uuid, uuid) from public;
revoke all on function public.claim_mission_reward(uuid, uuid) from anon;
revoke all on function public.claim_mission_reward(uuid, uuid) from authenticated;
grant execute on function public.claim_mission_reward(uuid, uuid) to service_role;
