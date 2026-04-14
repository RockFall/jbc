-- Esquema inicial JBC (Supabase / PostgreSQL).
-- Execute no SQL Editor do projeto Supabase após criar o projeto.
-- Depois, em Database > Replication, habilite o Realtime para cada tabela usada em `.stream()`.

create table if not exists public.hangouts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  date date not null,
  start_time text not null,
  end_time text,
  status text not null check (status in ('planned', 'happened', 'cancelled')),
  created_by text not null check (created_by in ('caio', 'jojo', 'bibi')),
  notes text,
  timeline_event_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.timeline_events (
  id uuid primary key default gen_random_uuid(),
  occurred_at timestamptz not null,
  title text not null,
  description text not null default '',
  image_url text,
  created_by text not null check (created_by in ('caio', 'jojo', 'bibi')),
  origin text not null check (origin in ('manual', 'from_hangout')),
  hangout_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.availabilities (
  id uuid primary key default gen_random_uuid(),
  person text not null check (person in ('caio', 'jojo', 'bibi')),
  weekday int not null check (weekday >= 1 and weekday <= 7),
  start_time text not null,
  end_time text not null
);

create table if not exists public.ideas (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category text check (category in ('hangout', 'food', 'movie', 'series', 'travel', 'other')),
  status text not null check (status in ('active', 'done', 'archived')),
  created_by text not null check (created_by in ('caio', 'jojo', 'bibi')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- RLS: política permissiva apenas para desenvolvimento / app privado.
-- Em produção, substitua por políticas baseadas em auth.uid() e papéis, ou App Check.
alter table public.timeline_events enable row level security;
alter table public.hangouts enable row level security;
alter table public.availabilities enable row level security;
alter table public.ideas enable row level security;

drop policy if exists "dev_allow_all_timeline_events" on public.timeline_events;
drop policy if exists "dev_allow_all_hangouts" on public.hangouts;
drop policy if exists "dev_allow_all_availabilities" on public.availabilities;
drop policy if exists "dev_allow_all_ideas" on public.ideas;

create policy "dev_allow_all_timeline_events"
  on public.timeline_events for all
  using (true) with check (true);

create policy "dev_allow_all_hangouts"
  on public.hangouts for all
  using (true) with check (true);

create policy "dev_allow_all_availabilities"
  on public.availabilities for all
  using (true) with check (true);

create policy "dev_allow_all_ideas"
  on public.ideas for all
  using (true) with check (true);

-- Storage: imagens da timeline (bucket público para leitura via URL no app).
insert into storage.buckets (id, name, public)
values ('timeline-images', 'timeline-images', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "dev_timeline_images_select" on storage.objects;
drop policy if exists "dev_timeline_images_insert" on storage.objects;
drop policy if exists "dev_timeline_images_update" on storage.objects;
drop policy if exists "dev_timeline_images_delete" on storage.objects;

create policy "dev_timeline_images_select"
  on storage.objects for select
  using (bucket_id = 'timeline-images');

create policy "dev_timeline_images_insert"
  on storage.objects for insert
  with check (bucket_id = 'timeline-images');

create policy "dev_timeline_images_update"
  on storage.objects for update
  using (bucket_id = 'timeline-images');

create policy "dev_timeline_images_delete"
  on storage.objects for delete
  using (bucket_id = 'timeline-images');
