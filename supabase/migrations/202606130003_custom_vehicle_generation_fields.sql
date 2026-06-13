-- Store generation information for manually entered vehicle review requests.
-- This keeps direct-input vehicles aligned with the generation-first catalog UX.

alter table public.custom_vehicle_requests
  add column if not exists generation_name text not null default '',
  add column if not exists generation_code text not null default '';

create index if not exists custom_vehicle_requests_generation_code_idx
  on public.custom_vehicle_requests (generation_code)
  where generation_code <> '';
