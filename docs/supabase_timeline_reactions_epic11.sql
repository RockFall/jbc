-- Epic 11 — reações emoji no detalhe da timeline (um emoji por perfil por evento).
-- Executar no SQL Editor em projetos já existentes. Depois habilite Realtime em `timeline_event_reactions`.

create table if not exists public.timeline_event_reactions (
  id uuid primary key default gen_random_uuid(),
  timeline_event_id uuid not null references public.timeline_events(id) on delete cascade,
  profile text not null check (profile in ('caio', 'jojo', 'bibi')),
  emoji text not null,
  updated_at timestamptz not null default now(),
  constraint timeline_event_reactions_emoji_trim check (char_length(trim(emoji)) > 0),
  constraint timeline_event_reactions_one_per_profile unique (timeline_event_id, profile)
);

create index if not exists timeline_event_reactions_event_idx
  on public.timeline_event_reactions (timeline_event_id);

alter table public.timeline_event_reactions enable row level security;

drop policy if exists "dev_allow_all_timeline_event_reactions" on public.timeline_event_reactions;
create policy "dev_allow_all_timeline_event_reactions"
  on public.timeline_event_reactions for all
  using (true) with check (true);
