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
  image_urls text[] not null default '{}',
  primary_image_index int not null default 0,
  created_by text not null check (created_by in ('caio', 'jojo', 'bibi')),
  origin text not null check (origin in ('manual', 'from_hangout')),
  hangout_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.timeline_event_comments (
  id uuid primary key default gen_random_uuid(),
  timeline_event_id uuid not null references public.timeline_events(id) on delete cascade,
  author text not null check (author in ('caio', 'jojo', 'bibi')),
  body text not null,
  created_at timestamptz not null default now(),
  constraint timeline_event_comments_body_trim check (char_length(trim(body)) > 0)
);

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

create table if not exists public.availabilities (
  id uuid primary key default gen_random_uuid(),
  person text not null check (person in ('caio', 'jojo', 'bibi')),
  weekday int not null check (weekday >= 1 and weekday <= 7),
  start_time text not null,
  end_time text not null,
  title text
);

create table if not exists public.ideas (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category text check (category in (
    'hangout', 'cozinhaaar', 'filmin', 'series_anime', 'travel', 'hobby', 'other'
  )),
  status text not null check (status in ('active', 'done', 'archived')),
  created_by text not null check (created_by in ('caio', 'jojo', 'bibi')),
  archived_by text check (archived_by is null or archived_by in ('caio', 'jojo', 'bibi')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- RLS: política permissiva apenas para desenvolvimento / app privado.
-- Em produção, substitua por políticas baseadas em auth.uid() e papéis, ou App Check.
alter table public.timeline_events enable row level security;
alter table public.hangouts enable row level security;
alter table public.availabilities enable row level security;
alter table public.ideas enable row level security;
alter table public.timeline_event_comments enable row level security;
alter table public.timeline_event_reactions enable row level security;

drop policy if exists "dev_allow_all_timeline_events" on public.timeline_events;
drop policy if exists "dev_allow_all_hangouts" on public.hangouts;
drop policy if exists "dev_allow_all_availabilities" on public.availabilities;
drop policy if exists "dev_allow_all_ideas" on public.ideas;

create policy "dev_allow_all_timeline_events"
  on public.timeline_events for all
  using (true) with check (true);

drop policy if exists "dev_allow_all_timeline_event_comments" on public.timeline_event_comments;
create policy "dev_allow_all_timeline_event_comments"
  on public.timeline_event_comments for all
  using (true) with check (true);

drop policy if exists "dev_allow_all_timeline_event_reactions" on public.timeline_event_reactions;
create policy "dev_allow_all_timeline_event_reactions"
  on public.timeline_event_reactions for all
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

-- Notificações in-app + tokens FCM (Epic 9). Ver também docs/supabase_notification_epic9.sql para projetos existentes.
create table if not exists public.jbc_notifications (
  id uuid primary key default gen_random_uuid(),
  module text not null,
  event_type text not null,
  actor text not null check (actor in ('caio', 'jojo', 'bibi')),
  title text not null,
  body text,
  entity_id text,
  read_at timestamptz,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists jbc_notifications_created_at_idx
  on public.jbc_notifications (created_at desc);

create index if not exists jbc_notifications_unread_idx
  on public.jbc_notifications (read_at)
  where read_at is null;

alter table public.jbc_notifications enable row level security;

drop policy if exists "dev_allow_all_jbc_notifications" on public.jbc_notifications;
create policy "dev_allow_all_jbc_notifications"
  on public.jbc_notifications for all
  using (true) with check (true);

create table if not exists public.fcm_device_tokens (
  id uuid primary key default gen_random_uuid(),
  profile text not null check (profile in ('caio', 'jojo', 'bibi')),
  token text not null,
  updated_at timestamptz not null default now(),
  constraint fcm_device_tokens_token_unique unique (token)
);

create index if not exists fcm_device_tokens_profile_idx
  on public.fcm_device_tokens (profile);

alter table public.fcm_device_tokens enable row level security;

drop policy if exists "dev_allow_all_fcm_device_tokens" on public.fcm_device_tokens;
create policy "dev_allow_all_fcm_device_tokens"
  on public.fcm_device_tokens for all
  using (true) with check (true);

-- Conchinha — pedidos presenciais (Epic 12). Habilitar Realtime nas duas tabelas no Dashboard.
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

-- Piaditas (Epic 13). Habilitar Realtime em `inside_jokes` se necessário.
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

-- Emoção do momento (Epic 14). Habilitar Realtime em `moment_emotions` se necessário.
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

-- Continhas — Caixa + split por rolê (Epic 15). Ver docs/supabase_continhas_epic15.sql.
create table if not exists public.continhas_guest (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  emoji text not null,
  created_by text not null check (created_by in ('caio', 'jojo', 'bibi')),
  created_at timestamptz not null default now(),
  constraint continhas_guest_name_trim check (char_length(trim(display_name)) > 0),
  constraint continhas_guest_emoji_trim check (char_length(trim(emoji)) > 0)
);

create index if not exists continhas_guest_created_at_idx
  on public.continhas_guest (created_at desc);

alter table public.continhas_guest enable row level security;

drop policy if exists "dev_allow_all_continhas_guest" on public.continhas_guest;
create policy "dev_allow_all_continhas_guest"
  on public.continhas_guest for all
  using (true) with check (true);

create table if not exists public.continhas_hangout (
  hangout_id uuid primary key references public.hangouts(id) on delete cascade,
  status text not null default 'open' check (status in ('open', 'closed')),
  closed_at timestamptz,
  closed_by text check (closed_by is null or closed_by in ('caio', 'jojo', 'bibi')),
  settlement_json jsonb,
  created_at timestamptz not null default now()
);

alter table public.continhas_hangout enable row level security;

drop policy if exists "dev_allow_all_continhas_hangout" on public.continhas_hangout;
create policy "dev_allow_all_continhas_hangout"
  on public.continhas_hangout for all
  using (true) with check (true);

create table if not exists public.continhas_hangout_guest (
  hangout_id uuid not null references public.continhas_hangout(hangout_id) on delete cascade,
  guest_id uuid not null references public.continhas_guest(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (hangout_id, guest_id)
);

create index if not exists continhas_hangout_guest_guest_idx
  on public.continhas_hangout_guest (guest_id);

alter table public.continhas_hangout_guest enable row level security;

drop policy if exists "dev_allow_all_continhas_hangout_guest" on public.continhas_hangout_guest;
create policy "dev_allow_all_continhas_hangout_guest"
  on public.continhas_hangout_guest for all
  using (true) with check (true);

create table if not exists public.continhas_expense (
  id uuid primary key default gen_random_uuid(),
  hangout_id uuid not null references public.hangouts(id) on delete cascade,
  amount_brl numeric(12, 2) not null check (amount_brl > 0),
  payer_profile text not null check (payer_profile in ('caio', 'jojo', 'bibi')),
  payment_source text not null check (payment_source in ('self', 'jbc_cash')),
  description text not null default '',
  created_by text not null check (created_by in ('caio', 'jojo', 'bibi')),
  created_at timestamptz not null default now()
);

create index if not exists continhas_expense_hangout_created_idx
  on public.continhas_expense (hangout_id, created_at desc);

alter table public.continhas_expense enable row level security;

drop policy if exists "dev_allow_all_continhas_expense" on public.continhas_expense;
create policy "dev_allow_all_continhas_expense"
  on public.continhas_expense for all
  using (true) with check (true);

create table if not exists public.continhas_expense_share (
  id uuid primary key default gen_random_uuid(),
  expense_id uuid not null references public.continhas_expense(id) on delete cascade,
  participant_type text not null check (participant_type in ('profile', 'guest')),
  participant_id text not null,
  unique (expense_id, participant_type, participant_id)
);

create index if not exists continhas_expense_share_expense_idx
  on public.continhas_expense_share (expense_id);

alter table public.continhas_expense_share enable row level security;

drop policy if exists "dev_allow_all_continhas_expense_share" on public.continhas_expense_share;
create policy "dev_allow_all_continhas_expense_share"
  on public.continhas_expense_share for all
  using (true) with check (true);

create table if not exists public.jbc_cash_ledger (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('deposit', 'hangout_expense_debit')),
  amount_brl numeric(12, 2) not null check (amount_brl > 0),
  recorded_by text not null check (recorded_by in ('caio', 'jojo', 'bibi')),
  hangout_expense_id uuid references public.continhas_expense(id) on delete cascade,
  note text,
  created_at timestamptz not null default now(),
  constraint jbc_cash_ledger_debit_has_expense check (
    (type = 'hangout_expense_debit' and hangout_expense_id is not null)
    or (type = 'deposit' and hangout_expense_id is null)
  )
);

create index if not exists jbc_cash_ledger_created_at_idx
  on public.jbc_cash_ledger (created_at desc);

alter table public.jbc_cash_ledger enable row level security;

drop policy if exists "dev_allow_all_jbc_cash_ledger" on public.jbc_cash_ledger;
create policy "dev_allow_all_jbc_cash_ledger"
  on public.jbc_cash_ledger for all
  using (true) with check (true);
