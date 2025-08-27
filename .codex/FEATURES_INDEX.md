# CleverTournament – Feature Map and File Index

This document tracks implemented features and the primary files involved, plus backend schema and tooling. It’s meant as a quick map to get back on track fast.

## How To Run (Web)
- Chrome on port 3000:
  - `flutter pub get`
  - `flutter run -d chrome --web-port 3000 --dart-define=SUPABASE_URL=https://qqmsiddtjjmyqfndqywe.supabase.co --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>`
- Anon key defaults are embedded in `lib/src/core/config/env.dart`, but prefer passing via `--dart-define`.

## Supabase Integration
- Client init: `lib/src/core/supabase/supabase_service.dart`
- Env defaults: `lib/src/core/config/env.dart`
- App wiring: `lib/main.dart`, `lib/src/app.dart`
- Packages: `supabase_flutter`, `postgrest` (via supabase), `realtime_client`

## MCP SQL Tooling (SQL Management API)
- Server: `.codex/tools/supabase-sql/server.mjs`
  - Tool: `exec_sql(query)`
  - Endpoint: `https://api.supabase.com/v1/projects/<projectRef>/database/query`
- Config: `.codex/config.toml` under `[mcp_servers.supabase_sql]` (uses project ref + PAT)
- Local helper: `scripts/supabase_sql.ps1` for ad-hoc SQL posts

## Database Schema (Summary)
- Tables:
  - `public.tournaments(id, name, sport, location, start_date, end_date, created_by, inserted_at, updated_at, settings jsonb)`
  - `public.pools(id, tournament_id, name, position)`
  - `public.teams(id, tournament_id, name, pool_id, seed, captain_name, captain_email, captain_phone, jersey_color, join_code)`
  - `public.players(id, team_id, name, number, email, inserted_at)`
  - `public.games(id, tournament_id, pool_id, court, start_time, team_a, team_b, score_a, score_b, status)`
  - `public.announcements(id, tournament_id, content, target, inserted_at, created_by)`
  - `public.team_registrations(id, tournament_id, team_name, captain_name, captain_email, captain_phone, notes, status, created_by, team_id, inserted_at)`
- Functions/Triggers:
  - `public.set_updated_at()` + trigger on `tournaments` (update updated_at)
  - `public.set_tournaments_created_by()` + trigger to fill `created_by = auth.uid()` on insert
  - `public.join_team(p_code text, p_name text, p_number int, p_email text)` SECURITY DEFINER (adds player by join code)
- RLS:
  - Enabled on `tournaments`, `pools`, `teams`, `players`, `games`, `announcements`, `team_registrations`
  - Public read policies for browse on most tables
  - Owner write policies: organizer (tournaments.created_by) can modify tournaments and related rows
  - Registrations: insert if signed in; select by creator or organizer; organizer can update

## App Structure (Key)
- Theme: `lib/src/core/theme/app_theme.dart`
- App shell: `lib/src/app.dart`, `lib/main.dart`
- Auth: `lib/src/features/auth/login_page.dart`, `lib/src/features/auth/register_page.dart`
- Home: `lib/src/features/home/home_shell.dart`
- Shared tournament data:
  - Models: `lib/src/features/tournaments/models/*.dart`
  - Repository: `lib/src/features/tournaments/data/tournament_repo.dart`

## Feature Map

### 1) Tournaments List + Create
- UI: `lib/src/features/tournaments/tournaments_page.dart`
- Model: `tournament_model.dart`
- Behavior:
  - List tournaments (public read)
  - Create tournament (requires session); `created_by` set (DB trigger backstop)

### 2) Pools/Divisions + Seeding
- UI (inside details): `tournament_detail_page.dart` → `_PoolsTab`
- Models: `pool_model.dart`, `team_model.dart`
- Repo: `fetchPools`, `addPool`, `removePool`, `fetchTeams`, `addTeam`, `setSeeds`, `assignTeamToPool`
- Behavior:
  - Add/remove pools; add teams to pool
  - Seeding drag-and-drop; persisted via `seed`
  - Chip per team (tap opens roster; long-press actions)

### 3) Schedule (Round Robin), Edit, Scores
- UI: `tournament_detail_page.dart` → `_PoolsTab` (generate), `_ScheduleTab` (view/edit)
- Model: `game_model.dart`
- Repo: `insertGames`, `clearGamesForPool`, `updateGame`, `updateScore`, `fetchGames`, `streamGames`
- Behavior:
  - Generate round-robin per pool
  - Edit court/time (long-press)
  - Enter scores (tap)

### 4) Standings (Live)
- UI: `tournament_detail_page.dart` → `_StandingsTab`
- Live recompute based on games stream (`repo.streamGames`)
- 2 points per win; shows W-L, PF-PA, Points

### 5) Announcements (Realtime)
- UI: `tournament_detail_page.dart` → `_AnnouncementsPanel`
- Model: `announcement_model.dart`
- Repo: `fetchAnnouncements`, `addAnnouncement`, `streamAnnouncements`
- Behavior: Organizer sends; stream renders live list

### 6) Tournament Settings
- UI: `tournament_settings_page.dart`
- Repo: `fetchSettings`, `saveSettings` (tournaments.settings jsonb)
- Controls: format, tie-breakers order, courts list used in schedule editor

### 7) Team Rosters
- UI: `team_roster_page.dart`
- Model: `player_model.dart`, `team_model.dart` (captain/contact, jersey, join_code)
- Repo: players CRUD, team updates, `regenerateJoinCode`
- Extras: bulk import players; copy join code; copy share link `/#/join?code=...`

### 8) Team Registration (Public) + Approvals (Organizer)
- UI: `team_registration_page.dart` (submit), `approvals_page.dart` (review)
- Model: `team_registration_model.dart`
- Repo: `submitRegistration`, `fetchRegistrations`, `approveRegistration`, `updateRegistrationStatus`
- Behavior:
  - Signed-in users submit registrations
  - Organizer approves → creates team (with join_code); or rejects

### 9) Join Team with Code (Public)
- UI: `join_team_page.dart` (form)
- Deep link: `/join?code=ABC123` handled in `lib/src/app.dart` `onGenerateRoute`
- Repo: `joinTeam` RPC wrapper
- DB: `public.join_team(...)` function (SECURITY DEFINER), GRANT EXECUTE to anon

## Realtime
- Games: `repo.streamGames()` → Schedule auto-refresh; Standings recompute
- Announcements: `repo.streamAnnouncements()`
- Subscriptions created per tab; relies on Supabase Realtime over WebSocket

## Notable Scripts/Files
- SQL migration (reference): `supabase/migrations/0001_init.sql`
- SQL helper: `scripts/supabase_sql.ps1`
- MCP server: `.codex/tools/supabase-sql/server.mjs` + `package.json`

## TODO / Ideas
- Owner-only guards in UI for edit/move/delete (currently implied by RLS)
- Brackets/playoffs and Swiss support
- Court/time calendar view and batch editor
- Notifications (email/push) on approvals/announcements
- QR for join link; polish visuals and transitions

