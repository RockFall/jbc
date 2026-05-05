-- Epic 13 — Piaditas (piadas internas no pote).
-- Execute no SQL Editor em projetos existentes.
-- Depois: Database → Replication → inclua `inside_jokes` na publication do Realtime (se usar .stream()).

create table if not exists public.inside_jokes (
  id uuid primary key default gen_random_uuid(),
  body text not null,
  author text not null check (author in ('caio', 'jojo', 'bibi')),
  tags text[] not null default '{}',
  created_at timestamptz not null default now(),
  constraint inside_jokes_body_trim check (char_length(trim(body)) > 0),
  constraint inside_jokes_body_len check (char_length(body) <= 10000)
);

create index if not exists inside_jokes_created_at_idx
  on public.inside_jokes (created_at desc);

alter table public.inside_jokes enable row level security;

drop policy if exists "dev_allow_all_inside_jokes" on public.inside_jokes;
create policy "dev_allow_all_inside_jokes"
  on public.inside_jokes for all
  using (true) with check (true);
