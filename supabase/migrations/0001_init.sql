-- Enable needed extension for UUIDs (should already be enabled on Supabase)
create extension if not exists pgcrypto;

-- Tournaments table
create table if not exists public.tournaments (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sport text not null check (sport in ('volleyball','pickleball')),
  location text default '',
  start_date date not null,
  end_date date not null,
  created_by uuid not null,
  inserted_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Update timestamp trigger
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;$$;

drop trigger if exists set_tournaments_updated_at on public.tournaments;
create trigger set_tournaments_updated_at
before update on public.tournaments
for each row execute procedure public.set_updated_at();

-- Basic subordinate tables
create table if not exists public.pools (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  name text not null,
  position int not null default 0
);

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  name text not null,
  inserted_at timestamptz not null default now()
);

create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  pool_id uuid references public.pools(id) on delete set null,
  court text default null,
  start_time timestamptz,
  team_a uuid references public.teams(id) on delete set null,
  team_b uuid references public.teams(id) on delete set null,
  score_a int default 0,
  score_b int default 0,
  status text not null default 'scheduled' check (status in ('scheduled','in_progress','final','forfeit','cancelled'))
);

-- RLS
alter table public.tournaments enable row level security;
alter table public.pools enable row level security;
alter table public.teams enable row level security;
alter table public.games enable row level security;

-- Policies
-- Public read for basic browsing
create policy tournaments_select_all on public.tournaments for select using (true);
create policy pools_select_all on public.pools for select using (true);
create policy teams_select_all on public.teams for select using (true);
create policy games_select_all on public.games for select using (true);

-- Organizers (owners) can manage their tournaments and related rows
create policy tournaments_modify_own on public.tournaments
for all using (auth.uid() = created_by)
with check (auth.uid() = created_by);

create policy pools_modify_if_owner on public.pools
for all using (
  exists(select 1 from public.tournaments t where t.id = tournament_id and t.created_by = auth.uid())
)
with check (
  exists(select 1 from public.tournaments t where t.id = tournament_id and t.created_by = auth.uid())
);

create policy teams_modify_if_owner on public.teams
for all using (
  exists(select 1 from public.tournaments t where t.id = tournament_id and t.created_by = auth.uid())
)
with check (
  exists(select 1 from public.tournaments t where t.id = tournament_id and t.created_by = auth.uid())
);

create policy games_modify_if_owner on public.games
for all using (
  exists(select 1 from public.tournaments t where t.id = tournament_id and t.created_by = auth.uid())
)
with check (
  exists(select 1 from public.tournaments t where t.id = tournament_id and t.created_by = auth.uid())
);

-- Convenience: default created_by via auth.uid() enforced in API (client must send it or use RPC)
-- You can add a trigger to auto-fill created_by on insert if desired with service role.
