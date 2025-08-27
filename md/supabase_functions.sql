-- Tournament Management App - Database Functions
-- This file contains useful database functions for tournament operations

-- =============================================
-- TRIGGER FUNCTIONS
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to relevant tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tournaments_updated_at BEFORE UPDATE ON public.tournaments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON public.teams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_games_updated_at BEFORE UPDATE ON public.games
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_team_standings_updated_at BEFORE UPDATE ON public.team_standings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- STANDINGS CALCULATION FUNCTIONS
-- =============================================

-- Function to calculate team standings for a tournament
CREATE OR REPLACE FUNCTION calculate_team_standings(tournament_uuid UUID)
RETURNS VOID AS $$
BEGIN
    -- Delete existing standings for this tournament
    DELETE FROM public.team_standings WHERE tournament_id = tournament_uuid;
    
    -- Calculate and insert new standings
    INSERT INTO public.team_standings (
        tournament_id,
        team_id,
        pool_id,
        games_played,
        wins,
        losses,
        points_for,
        points_against,
        point_differential,
        win_percentage
    )
    SELECT 
        t.tournament_id,
        t.id as team_id,
        t.pool_id,
        COALESCE(stats.games_played, 0) as games_played,
        COALESCE(stats.wins, 0) as wins,
        COALESCE(stats.losses, 0) as losses,
        COALESCE(stats.points_for, 0) as points_for,
        COALESCE(stats.points_against, 0) as points_against,
        COALESCE(stats.points_for, 0) - COALESCE(stats.points_against, 0) as point_differential,
        CASE 
            WHEN COALESCE(stats.games_played, 0) = 0 THEN 0.0000
            ELSE ROUND(COALESCE(stats.wins, 0)::DECIMAL / stats.games_played, 4)
        END as win_percentage
    FROM public.teams t
    LEFT JOIN (
        SELECT 
            team_id,
            COUNT(*) as games_played,
            SUM(CASE WHEN winner_id = team_id THEN 1 ELSE 0 END) as wins,
            SUM(CASE WHEN winner_id != team_id AND status = 'completed' THEN 1 ELSE 0 END) as losses,
            SUM(points_for) as points_for,
            SUM(points_against) as points_against
        FROM (
            -- Games where team is team1
            SELECT 
                team1_id as team_id,
                winner_id,
                status,
                team1_score as points_for,
                team2_score as points_against
            FROM public.games 
            WHERE tournament_id = tournament_uuid AND status = 'completed'
            
            UNION ALL
            
            -- Games where team is team2
            SELECT 
                team2_id as team_id,
                winner_id,
                status,
                team2_score as points_for,
                team1_score as points_against
            FROM public.games 
            WHERE tournament_id = tournament_uuid AND status = 'completed'
        ) team_games
        GROUP BY team_id
    ) stats ON t.id = stats.team_id
    WHERE t.tournament_id = tournament_uuid;
    
    -- Update rankings within each pool
    UPDATE public.team_standings 
    SET ranking = ranked.rank
    FROM (
        SELECT 
            id,
            ROW_NUMBER() OVER (
                PARTITION BY tournament_id, COALESCE(pool_id, 'no_pool'::UUID)
                ORDER BY win_percentage DESC, point_differential DESC, points_for DESC
            ) as rank
        FROM public.team_standings 
        WHERE tournament_id = tournament_uuid
    ) ranked
    WHERE public.team_standings.id = ranked.id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- GAME RESULT TRIGGER FUNCTION
-- =============================================

-- Function to automatically update standings when game results are entered
CREATE OR REPLACE FUNCTION update_standings_on_game_result()
RETURNS TRIGGER AS $$
BEGIN
    -- Only update if the game status changed to completed or the scores changed
    IF (NEW.status = 'completed' AND OLD.status != 'completed') OR
       (NEW.status = 'completed' AND (NEW.team1_score != OLD.team1_score OR NEW.team2_score != OLD.team2_score)) THEN
        
        -- Determine winner
        IF NEW.team1_score > NEW.team2_score THEN
            NEW.winner_id = NEW.team1_id;
        ELSIF NEW.team2_score > NEW.team1_score THEN
            NEW.winner_id = NEW.team2_id;
        ELSE
            NEW.winner_id = NULL; -- Tie game
        END IF;
        
        -- Recalculate standings for the tournament
        PERFORM calculate_team_standings(NEW.tournament_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic standings updates
CREATE TRIGGER update_standings_on_game_completion
    BEFORE UPDATE ON public.games
    FOR EACH ROW
    EXECUTE FUNCTION update_standings_on_game_result();

-- =============================================
-- SCHEDULE GENERATION HELPER FUNCTIONS
-- =============================================

-- Function to generate round robin schedule for a pool
CREATE OR REPLACE FUNCTION generate_round_robin_schedule(
    tournament_uuid UUID,
    pool_uuid UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    team_record RECORD;
    team_ids UUID[];
    team_count INTEGER;
    round_num INTEGER;
    game_num INTEGER := 1;
    i INTEGER;
    j INTEGER;
BEGIN
    -- Get teams for the pool (or all teams if no pool specified)
    IF pool_uuid IS NOT NULL THEN
        SELECT array_agg(id ORDER BY seed NULLS LAST, name) INTO team_ids
        FROM public.teams 
        WHERE tournament_id = tournament_uuid AND pool_id = pool_uuid AND registration_status = 'approved';
    ELSE
        SELECT array_agg(id ORDER BY seed NULLS LAST, name) INTO team_ids
        FROM public.teams 
        WHERE tournament_id = tournament_uuid AND registration_status = 'approved';
    END IF;
    
    team_count := array_length(team_ids, 1);
    
    -- Need at least 2 teams
    IF team_count < 2 THEN
        RETURN;
    END IF;
    
    -- Generate round robin matches
    FOR round_num IN 1..(team_count - 1) LOOP
        FOR i IN 1..(team_count / 2) LOOP
            j := team_count + 1 - i;
            
            -- Skip if same team (shouldn't happen but safety check)
            IF i != j AND team_ids[i] IS NOT NULL AND team_ids[j] IS NOT NULL THEN
                INSERT INTO public.games (
                    tournament_id,
                    pool_id,
                    round_number,
                    game_number,
                    team1_id,
                    team2_id,
                    status
                ) VALUES (
                    tournament_uuid,
                    pool_uuid,
                    round_num,
                    game_num,
                    team_ids[i],
                    team_ids[j],
                    'scheduled'
                );
                
                game_num := game_num + 1;
            END IF;
        END LOOP;
        
        -- Rotate teams (keep first team fixed, rotate others)
        IF team_count > 2 THEN
            team_ids := team_ids[1:1] || team_ids[team_count:team_count] || team_ids[2:team_count-1];
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- UTILITY FUNCTIONS
-- =============================================

-- Function to get tournament participants (all users involved in a tournament)
CREATE OR REPLACE FUNCTION get_tournament_participants(tournament_uuid UUID)
RETURNS TABLE(user_id UUID, role TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT p.id, 'player'::TEXT as role
    FROM public.profiles p
    JOIN public.players pl ON pl.user_id = p.id
    JOIN public.teams t ON t.id = pl.team_id
    WHERE t.tournament_id = tournament_uuid
    
    UNION
    
    SELECT DISTINCT p.id, 'captain'::TEXT as role
    FROM public.profiles p
    JOIN public.teams t ON t.captain_id = p.id
    WHERE t.tournament_id = tournament_uuid
    
    UNION
    
    SELECT DISTINCT ta.user_id, ta.role::TEXT
    FROM public.tournament_admins ta
    WHERE ta.tournament_id = tournament_uuid
    
    UNION
    
    SELECT DISTINCT t.created_by, 'creator'::TEXT as role
    FROM public.tournaments t
    WHERE t.id = tournament_uuid;
END;
$$ LANGUAGE plpgsql;

-- Function to check if user has admin access to tournament
CREATE OR REPLACE FUNCTION user_is_tournament_admin(tournament_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.tournaments 
        WHERE id = tournament_uuid AND created_by = user_uuid
    ) OR EXISTS (
        SELECT 1 FROM public.tournament_admins 
        WHERE tournament_id = tournament_uuid AND user_id = user_uuid
    );
END;
$$ LANGUAGE plpgsql;

-- Function to check if user is team captain
CREATE OR REPLACE FUNCTION user_is_team_captain(team_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.teams 
        WHERE id = team_uuid AND captain_id = user_uuid
    );
END;
$$ LANGUAGE plpgsql;

