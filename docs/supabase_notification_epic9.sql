-- Epic 9 — notificações in-app + tokens FCM (executar no SQL Editor se o projeto já existia antes desta epic).
-- Depois: Database → Replication → adicione `jbc_notifications` e `fcm_device_tokens` ao publication `supabase_realtime` (ou equivalente).

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

-- Tokens FCM por perfil (um token por instalação; conflito atualiza perfil/hora).
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
