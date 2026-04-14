-- Migração Epic 5 — execute no SQL Editor se o projeto já existia antes destas colunas/regras.
-- Ordem sugerida: backup → rodar este script → publicar o app atualizado.

-- 1) Timeline: múltiplas imagens
alter table public.timeline_events
  add column if not exists image_urls text[] not null default '{}';
alter table public.timeline_events
  add column if not exists primary_image_index int not null default 0;

update public.timeline_events
set
  image_urls = array[image_url]::text[],
  primary_image_index = 0
where
  image_url is not null
  and trim(image_url) <> ''
  and (image_urls is null or cardinality(image_urls) = 0);

-- 2) Indisponibilidades: título opcional
alter table public.availabilities
  add column if not exists title text;

-- 3) Ideias: novas categorias (remove constraint antigo e recria)
alter table public.ideas drop constraint if exists ideas_category_check;

update public.ideas set category = 'cozinhaaar' where category = 'food';
update public.ideas set category = 'filmin' where category = 'movie';
update public.ideas set category = 'series_anime' where category = 'series';

alter table public.ideas add constraint ideas_category_check check (
  category is null
  or category in (
    'hangout',
    'cozinhaaar',
    'filmin',
    'series_anime',
    'travel',
    'hobby',
    'other'
  )
);

-- 4) Ideias: quem marcou “Odiei”
alter table public.ideas
  add column if not exists archived_by text
  check (archived_by is null or archived_by in ('caio', 'jojo', 'bibi'));

-- 5) Comentários nas memórias da timeline
create table if not exists public.timeline_event_comments (
  id uuid primary key default gen_random_uuid(),
  timeline_event_id uuid not null references public.timeline_events(id) on delete cascade,
  author text not null check (author in ('caio', 'jojo', 'bibi')),
  body text not null,
  created_at timestamptz not null default now(),
  constraint timeline_event_comments_body_trim check (char_length(trim(body)) > 0)
);

alter table public.timeline_event_comments enable row level security;

drop policy if exists "dev_allow_all_timeline_event_comments" on public.timeline_event_comments;
create policy "dev_allow_all_timeline_event_comments"
  on public.timeline_event_comments for all
  using (true) with check (true);

-- Opcional: em Database > Replication, habilite Realtime em `timeline_event_comments`.
