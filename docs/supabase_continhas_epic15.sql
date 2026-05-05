-- Epic 15 — Continhas: Caixa do JBC + divisão por rolê.
-- Execute no SQL Editor em projetos existentes.
-- Realtime: habilite `jbc_cash_ledger`, `continhas_guest`, `continhas_hangout`,
-- `continhas_hangout_guest`, `continhas_expense`, `continhas_expense_share` na publication.

-- v1: não permitir saldo da Caixa negativo — validado no app antes do débito.

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
