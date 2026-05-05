-- Epic 12 — modo conchinha (pedidos + aceites + realtime).
-- Execute no SQL Editor em projetos que já existiam antes desta epic.
-- Depois: Database → Replication → inclua `conchinha_requests` e `conchinha_acceptances` na publication do Realtime.

create table if not exists public.conchinha_requests (
  id uuid primary key default gen_random_uuid(),
  requester text not null check (requester in ('caio', 'jojo', 'bibi')),
  address jsonb not null,
  status text not null check (status in ('open', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists conchinha_one_open_per_requester
  on public.conchinha_requests (requester)
  where status = 'open';

create index if not exists conchinha_requests_status_idx
  on public.conchinha_requests (status, updated_at desc);

alter table public.conchinha_requests enable row level security;

drop policy if exists "dev_allow_all_conchinha_requests" on public.conchinha_requests;
create policy "dev_allow_all_conchinha_requests"
  on public.conchinha_requests for all
  using (true) with check (true);

create table if not exists public.conchinha_acceptances (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.conchinha_requests(id) on delete cascade,
  profile text not null check (profile in ('caio', 'jojo', 'bibi')),
  created_at timestamptz not null default now(),
  constraint conchinha_acceptances_one_per_profile unique (request_id, profile)
);

create index if not exists conchinha_acceptances_request_idx
  on public.conchinha_acceptances (request_id);

alter table public.conchinha_acceptances enable row level security;

drop policy if exists "dev_allow_all_conchinha_acceptances" on public.conchinha_acceptances;
create policy "dev_allow_all_conchinha_acceptances"
  on public.conchinha_acceptances for all
  using (true) with check (true);
