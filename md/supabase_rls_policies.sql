-- Tournament Management App - Row Level Security (RLS) Policies
-- This file contains all the RLS policies for secure data access

-- =============================================
-- PROFILES RLS POLICIES
-- =============================================

-- Users can view all profiles (for team member selection, etc.)
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
    FOR SELECT USING (true);

-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- =============================================
-- TOURNAMENTS RLS POLICIES
-- =============================================

-- Anyone can view tournaments (public visibility)
CREATE POLICY "Tournaments are viewable by everyone" ON public.tournaments
    FOR SELECT USING (true);

-- Authenticated users can create tournaments
CREATE POLICY "Authenticated users can create tournaments" ON public.tournaments
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Tournament creators and admins can update tournaments
CREATE POLICY "Tournament creators and admins can update tournaments" ON public.tournaments
    FOR UPDATE USING (
        auth.uid() = created_by OR 
        auth.uid() IN (
            SELECT user_id FROM public.tournament_admins 
            WHERE tournament_id = tournaments.id
        )
    );

-- Tournament creators can delete tournaments
CREATE POLICY "Tournament creators can delete tournaments" ON public.tournaments
    FOR DELETE USING (auth.uid() = created_by);

-- =============================================
-- TOURNAMENT ADMINS RLS POLICIES
-- =============================================

-- Tournament admins are viewable by tournament participants
CREATE POLICY "Tournament admins viewable by participants" ON public.tournament_admins
    FOR SELECT USING (
        -- Tournament is public, so admins are viewable
        true
    );

-- Tournament creators can manage admins
CREATE POLICY "Tournament creators can manage admins" ON public.tournament_admins
    FOR ALL USING (
        auth.uid() IN (
            SELECT created_by FROM public.tournaments 
            WHERE id = tournament_admins.tournament_id
        )
    );

-- =============================================
-- TEAMS RLS POLICIES
-- =============================================

-- Teams are viewable by everyone (public tournaments)
CREATE POLICY "Teams are viewable by everyone" ON public.teams
    FOR SELECT USING (true);

-- Authenticated users can create teams (register for tournaments)
CREATE POLICY "Authenticated users can create teams" ON public.teams
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Team captains and tournament admins can update teams
CREATE POLICY "Team captains and tournament admins can update teams" ON public.teams
    FOR UPDATE USING (
        auth.uid() = captain_id OR
        auth.uid() IN (
            SELECT user_id FROM public.tournament_admins 
            WHERE tournament_id = teams.tournament_id
        ) OR
        auth.uid() IN (
            SELECT created_by FROM public.tournaments 
            WHERE id = teams.tournament_id
        )
    );

-- Team captains and tournament admins can delete teams
CREATE POLICY "Team captains and tournament admins can delete teams" ON public.teams
    FOR DELETE USING (
        auth.uid() = captain_id OR
        auth.uid() IN (
            SELECT user_id FROM public.tournament_admins 
            WHERE tournament_id = teams.tournament_id
        ) OR
        auth.uid() IN (
            SELECT created_by FROM public.tournaments 
            WHERE id = teams.tournament_id
        )
    );

-- =============================================
-- PLAYERS RLS POLICIES
-- =============================================

-- Players are viewable by everyone
CREATE POLICY "Players are viewable by everyone" ON public.players
    FOR SELECT USING (true);

-- Team captains and tournament admins can manage players
CREATE POLICY "Team captains and tournament admins can manage players" ON public.players
    FOR ALL USING (
        auth.uid() IN (
            SELECT captain_id FROM public.teams 
            WHERE id = players.team_id
        ) OR
        auth.uid() IN (
            SELECT ta.user_id FROM public.tournament_admins ta
            JOIN public.teams t ON t.tournament_id = ta.tournament_id
            WHERE t.id = players.team_id
        ) OR
        auth.uid() IN (
            SELECT t2.created_by FROM public.tournaments t2
            JOIN public.teams t ON t.tournament_id = t2.id
            WHERE t.id = players.team_id
        )
    );

-- =============================================
-- POOLS RLS POLICIES
-- =============================================

-- Pools are viewable by everyone
CREATE POLICY "Pools are viewable by everyone" ON public.pools
    FOR SELECT USING (true);

-- Tournament admins can manage pools
CREATE POLICY "Tournament admins can manage pools" ON public.pools
    FOR ALL USING (
        auth.uid() IN (
            SELECT user_id FROM public.tournament_admins 
            WHERE tournament_id = pools.tournament_id
        ) OR
        auth.uid() IN (
            SELECT created_by FROM public.tournaments 
            WHERE id = pools.tournament_id
        )
    );

-- =============================================
-- COURTS RLS POLICIES
-- =============================================

-- Courts are viewable by everyone
CREATE POLICY "Courts are viewable by everyone" ON public.courts
    FOR SELECT USING (true);

-- Tournament admins can manage courts
CREATE POLICY "Tournament admins can manage courts" ON public.courts
    FOR ALL USING (
        auth.uid() IN (
            SELECT user_id FROM public.tournament_admins 
            WHERE tournament_id = courts.tournament_id
        ) OR
        auth.uid() IN (
            SELECT created_by FROM public.tournaments 
            WHERE id = courts.tournament_id
        )
    );

-- =============================================
-- GAMES RLS POLICIES
-- =============================================

-- Games are viewable by everyone
CREATE POLICY "Games are viewable by everyone" ON public.games
    FOR SELECT USING (true);

-- Tournament admins can create games
CREATE POLICY "Tournament admins can create games" ON public.games
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT user_id FROM public.tournament_admins 
            WHERE tournament_id = games.tournament_id
        ) OR
        auth.uid() IN (
            SELECT created_by FROM public.tournaments 
            WHERE id = games.tournament_id
        )
    );

-- Tournament admins and team captains can update games (for score reporting)
CREATE POLICY "Tournament admins and team captains can update games" ON public.games
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT user_id FROM public.tournament_admins 
            WHERE tournament_id = games.tournament_id
        ) OR
        auth.uid() IN (
            SELECT created_by FROM public.tournaments 
            WHERE id = games.tournament_id
        ) OR
        auth.uid() IN (
            SELECT captain_id FROM public.teams 
            WHERE id = games.team1_id OR id = games.team2_id
        )
    );

-- Tournament admins can delete games
CREATE POLICY "Tournament admins can delete games" ON public.games
    FOR DELETE USING (
        auth.uid() IN (
            SELECT user_id FROM public.tournament_admins 
            WHERE tournament_id = games.tournament_id
        ) OR
        auth.uid() IN (
            SELECT created_by FROM public.tournaments 
            WHERE id = games.tournament_id
        )
    );

-- =============================================
-- FLIGHTS RLS POLICIES
-- =============================================

-- Flights are viewable by everyone
CREATE POLICY "Flights are viewable by everyone" ON public.flights
    FOR SELECT USING (true);

-- Tournament admins can manage flights
CREATE POLICY "Tournament admins can manage flights" ON public.flights
    FOR ALL USING (
        auth.uid() IN (
            SELECT user_id FROM public.tournament_admins 
            WHERE tournament_id = flights.tournament_id
        ) OR
        auth.uid() IN (
            SELECT created_by FROM public.tournaments 
            WHERE id = flights.tournament_id
        )
    );

-- =============================================
-- FLIGHT TEAMS RLS POLICIES
-- =============================================

-- Flight teams are viewable by everyone
CREATE POLICY "Flight teams are viewable by everyone" ON public.flight_teams
    FOR SELECT USING (true);

-- Tournament admins can manage flight teams
CREATE POLICY "Tournament admins can manage flight teams" ON public.flight_teams
    FOR ALL USING (
        auth.uid() IN (
            SELECT ta.user_id FROM public.tournament_admins ta
            JOIN public.flights f ON f.tournament_id = ta.tournament_id
            WHERE f.id = flight_teams.flight_id
        ) OR
        auth.uid() IN (
            SELECT t.created_by FROM public.tournaments t
            JOIN public.flights f ON f.tournament_id = t.id
            WHERE f.id = flight_teams.flight_id
        )
    );

-- =============================================
-- TEAM STANDINGS RLS POLICIES
-- =============================================

-- Standings are viewable by everyone
CREATE POLICY "Standings are viewable by everyone" ON public.team_standings
    FOR SELECT USING (true);

-- Tournament admins can manage standings (usually auto-calculated)
CREATE POLICY "Tournament admins can manage standings" ON public.team_standings
    FOR ALL USING (
        auth.uid() IN (
            SELECT user_id FROM public.tournament_admins 
            WHERE tournament_id = team_standings.tournament_id
        ) OR
        auth.uid() IN (
            SELECT created_by FROM public.tournaments 
            WHERE id = team_standings.tournament_id
        )
    );

-- =============================================
-- TOURNAMENT TIEBREAKERS RLS POLICIES
-- =============================================

-- Tiebreakers are viewable by everyone
CREATE POLICY "Tiebreakers are viewable by everyone" ON public.tournament_tiebreakers
    FOR SELECT USING (true);

-- Tournament admins can manage tiebreakers
CREATE POLICY "Tournament admins can manage tiebreakers" ON public.tournament_tiebreakers
    FOR ALL USING (
        auth.uid() IN (
            SELECT user_id FROM public.tournament_admins 
            WHERE tournament_id = tournament_tiebreakers.tournament_id
        ) OR
        auth.uid() IN (
            SELECT created_by FROM public.tournaments 
            WHERE id = tournament_tiebreakers.tournament_id
        )
    );

-- =============================================
-- NOTIFICATIONS RLS POLICIES
-- =============================================

-- Users can view notifications for tournaments they're involved in
CREATE POLICY "Users can view relevant notifications" ON public.notifications
    FOR SELECT USING (
        -- Tournament participants can see notifications
        auth.uid() IN (
            SELECT t.captain_id FROM public.teams t 
            WHERE t.tournament_id = notifications.tournament_id
        ) OR
        auth.uid() IN (
            SELECT p.user_id FROM public.players p
            JOIN public.teams t ON t.id = p.team_id
            WHERE t.tournament_id = notifications.tournament_id
        ) OR
        auth.uid() IN (
            SELECT user_id FROM public.tournament_admins 
            WHERE tournament_id = notifications.tournament_id
        ) OR
        auth.uid() IN (
            SELECT created_by FROM public.tournaments 
            WHERE id = notifications.tournament_id
        )
    );

-- Tournament admins can create notifications
CREATE POLICY "Tournament admins can create notifications" ON public.notifications
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT user_id FROM public.tournament_admins 
            WHERE tournament_id = notifications.tournament_id
        ) OR
        auth.uid() IN (
            SELECT created_by FROM public.tournaments 
            WHERE id = notifications.tournament_id
        )
    );

-- Tournament admins can update/delete their notifications
CREATE POLICY "Tournament admins can manage their notifications" ON public.notifications
    FOR ALL USING (
        auth.uid() = sender_id AND (
            auth.uid() IN (
                SELECT user_id FROM public.tournament_admins 
                WHERE tournament_id = notifications.tournament_id
            ) OR
            auth.uid() IN (
                SELECT created_by FROM public.tournaments 
                WHERE id = notifications.tournament_id
            )
        )
    );

-- =============================================
-- USER NOTIFICATION STATUS RLS POLICIES
-- =============================================

-- Users can view their own notification status
CREATE POLICY "Users can view their own notification status" ON public.user_notification_status
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own notification status
CREATE POLICY "Users can insert their own notification status" ON public.user_notification_status
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own notification status
CREATE POLICY "Users can update their own notification status" ON public.user_notification_status
    FOR UPDATE USING (auth.uid() = user_id);

