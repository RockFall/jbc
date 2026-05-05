-- Epic 14 — Emoção do momento (sticker por perfil, upsert por perfil).
-- Execute no SQL Editor em projetos existentes.
-- Depois: Database → Replication → inclua `moment_emotions` na publication do Realtime.

create table if not exists public.moment_emotions (
  profile text primary key check (profile in ('caio', 'jojo', 'bibi')),
  sticker_id text not null,
  updated_at timestamptz not null default now(),
  constraint moment_emotions_sticker_trim check (char_length(trim(sticker_id)) > 0)
);

create index if not exists moment_emotions_updated_at_idx
  on public.moment_emotions (updated_at desc);

alter table public.moment_emotions enable row level security;

drop policy if exists "dev_allow_all_moment_emotions" on public.moment_emotions;
create policy "dev_allow_all_moment_emotions"
  on public.moment_emotions for all
  using (true) with check (true);
