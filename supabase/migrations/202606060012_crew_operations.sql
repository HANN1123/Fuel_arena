create index if not exists crew_members_user_joined_at_idx
  on public.crew_members (user_id, joined_at desc);

create index if not exists crew_members_crew_score_idx
  on public.crew_members (crew_id, weekly_contribution desc);

alter table public.crews enable row level security;
alter table public.crew_members enable row level security;

create or replace function public.is_crew_member(target_crew_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.crew_members
    where crew_id = target_crew_id
      and user_id = auth.uid()
  );
$$;

drop policy if exists "crews_member_select" on public.crews;
create policy "crews_member_select" on public.crews
  for select using (public.is_admin_user() or public.is_crew_member(id));

drop policy if exists "crews_admin_write" on public.crews;
create policy "crews_admin_write" on public.crews
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "crew_members_member_select" on public.crew_members;
create policy "crew_members_member_select" on public.crew_members
  for select using (
    public.is_admin_user()
    or public.is_crew_member(crew_id)
  );

drop policy if exists "crew_members_admin_write" on public.crew_members;
create policy "crew_members_admin_write" on public.crew_members
  for all using (public.is_admin_user()) with check (public.is_admin_user());

create or replace function public.get_my_crew_summary()
returns table (
  id uuid,
  name text,
  description text,
  member_count integer,
  weekly_score integer
)
language sql
stable
security definer
set search_path = public
as $$
  select
    c.id,
    c.name,
    c.description,
    count(cm_all.user_id)::integer as member_count,
    coalesce(sum(cm_all.weekly_contribution), 0)::integer as weekly_score
  from public.crew_members mine
  join public.crews c on c.id = mine.crew_id
  left join public.crew_members cm_all on cm_all.crew_id = c.id
  where mine.user_id = auth.uid()
  group by c.id, c.name, c.description
  order by max(mine.joined_at) desc
  limit 1;
$$;

create or replace function public.get_my_crew_members()
returns table (
  crew_id uuid,
  user_id uuid,
  nickname text,
  role text,
  weekly_contribution integer
)
language sql
stable
security definer
set search_path = public
as $$
  with my_crew as (
    select crew_id
    from public.crew_members
    where user_id = auth.uid()
    order by joined_at desc
    limit 1
  )
  select
    cm.crew_id,
    cm.user_id,
    coalesce(nullif(p.nickname, ''), 'Fuel Driver') as nickname,
    cm.role,
    cm.weekly_contribution
  from public.crew_members cm
  join my_crew mine on mine.crew_id = cm.crew_id
  left join public.profiles p on p.id = cm.user_id
  order by cm.weekly_contribution desc, nickname asc;
$$;

revoke all on function public.is_crew_member(uuid) from public;
grant execute on function public.is_crew_member(uuid) to authenticated;

revoke all on function public.get_my_crew_summary() from public;
grant execute on function public.get_my_crew_summary() to authenticated;

revoke all on function public.get_my_crew_members() from public;
grant execute on function public.get_my_crew_members() to authenticated;
