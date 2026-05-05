-- Conchinha match pool (3 perfis) + estado global de match.
-- Após aplicar: Database → Replication → incluir `conchinha_search_pool` e `conchinha_match_state` no Realtime.
-- O cliente chama `conchinha_try_match()` após inserir/remover do pool; as notificações FCM/in-app saem do Flutter.

create table if not exists public.conchinha_search_pool (
  id uuid primary key default gen_random_uuid(),
  profile text not null check (profile in ('caio', 'jojo', 'bibi')),
  preference text not null check (preference in ('home', 'anywhere')),
  created_at timestamptz not null default now()
);

create unique index if not exists conchinha_search_pool_one_profile
  on public.conchinha_search_pool (profile);

create index if not exists conchinha_search_pool_created_idx
  on public.conchinha_search_pool (created_at desc);

alter table public.conchinha_search_pool enable row level security;

drop policy if exists "dev_allow_all_conchinha_search_pool" on public.conchinha_search_pool;
create policy "dev_allow_all_conchinha_search_pool"
  on public.conchinha_search_pool for all
  using (true) with check (true);

create table if not exists public.conchinha_match_state (
  id text primary key default 'singleton',
  wave_id uuid not null default gen_random_uuid(),
  tier text not null default 'idle' check (tier in ('idle', 'dual', 'supreme')),
  dual_notified boolean not null default false,
  supreme_notified boolean not null default false,
  updated_at timestamptz not null default now()
);

insert into public.conchinha_match_state (id) values ('singleton')
  on conflict (id) do nothing;

alter table public.conchinha_match_state enable row level security;

drop policy if exists "dev_allow_all_conchinha_match_state" on public.conchinha_match_state;
create policy "dev_allow_all_conchinha_match_state"
  on public.conchinha_match_state for all
  using (true) with check (true);

create or replace function public.conchinha_try_match()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  n int;
  st public.conchinha_match_state%rowtype;
  participants jsonb;
  new_wave uuid;
begin
  select * into st from public.conchinha_match_state where id = 'singleton' for update;
  select count(*)::int into n from public.conchinha_search_pool;

  select coalesce(
    jsonb_agg(
      jsonb_build_object('profile', p.profile, 'preference', p.preference)
      order by p.profile
    ),
    '[]'::jsonb
  ) into participants
  from public.conchinha_search_pool p;

  if n < 2 then
    update public.conchinha_match_state
    set
      tier = 'idle',
      dual_notified = false,
      supreme_notified = false,
      wave_id = gen_random_uuid(),
      updated_at = now()
    where id = 'singleton';
    return jsonb_build_object('action', 'wait', 'pool_count', n, 'participants', participants, 'wave_id', st.wave_id);
  end if;

  if n >= 3 then
    if st.supreme_notified then
      return jsonb_build_object('action', 'wait', 'pool_count', n, 'participants', participants, 'wave_id', st.wave_id, 'tier', st.tier);
    end if;
    if st.tier = 'dual' and st.dual_notified and not st.supreme_notified then
      update public.conchinha_match_state
      set
        tier = 'supreme',
        supreme_notified = true,
        updated_at = now()
      where id = 'singleton'
      returning wave_id into new_wave;
      return jsonb_build_object(
        'action', 'supreme_upgrade',
        'pool_count', n,
        'participants', participants,
        'wave_id', coalesce(new_wave, st.wave_id)
      );
    end if;
    if not st.dual_notified and not st.supreme_notified then
      new_wave := st.wave_id;
      update public.conchinha_match_state
      set
        tier = 'supreme',
        dual_notified = true,
        supreme_notified = true,
        updated_at = now()
      where id = 'singleton';
      return jsonb_build_object(
        'action', 'supreme_direct',
        'pool_count', n,
        'participants', participants,
        'wave_id', st.wave_id
      );
    end if;
  end if;

  if n = 2 then
    if st.supreme_notified or st.tier = 'supreme' then
      return jsonb_build_object('action', 'wait', 'pool_count', n, 'participants', participants, 'wave_id', st.wave_id, 'tier', st.tier);
    end if;
    if not st.dual_notified then
      update public.conchinha_match_state
      set
        tier = 'dual',
        dual_notified = true,
        updated_at = now()
      where id = 'singleton';
      return jsonb_build_object(
        'action', 'dual',
        'pool_count', n,
        'participants', participants,
        'wave_id', st.wave_id
      );
    end if;
  end if;

  return jsonb_build_object('action', 'wait', 'pool_count', n, 'participants', participants, 'wave_id', st.wave_id, 'tier', st.tier);
end;
$$;

grant execute on function public.conchinha_try_match() to anon, authenticated, service_role;
