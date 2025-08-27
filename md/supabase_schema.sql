-- Tournament Management App - Supabase Database Schema
-- This file contains all the database tables, indexes, and Row Level Security (RLS) policies
-- for the Tournament Management App built with Flutter and Supabase

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- USERS AND AUTHENTICATION
-- =============================================

-- User profiles table (extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- =============================================
-- TOURNAMENTS
-- =============================================

-- Tournament formats enum
CREATE TYPE tournament_format AS ENUM (
    'round_robin',
    'single_elimination', 
    'double_elimination',
    'swiss_system',
    'hybrid_pool_playoff'
);

-- Tournament status enum
CREATE TYPE tournament_status AS ENUM (
    'draft',
    'registration_open',
    'registration_closed',
    'in_progress',
    'completed',
    'cancelled'
);

-- Sports enum
CREATE TYPE sport_type AS ENUM (
    'volleyball',
    'pickleball',
    'other'
);

-- Tournaments table
CREATE TABLE public.tournaments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    sport sport_type NOT NULL DEFAULT 'volleyball',
    format tournament_format NOT NULL DEFAULT 'round_robin',
    status tournament_status NOT NULL DEFAULT 'draft',
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    location TEXT,
    venue_address TEXT,
    max_teams INTEGER DEFAULT 32,
    registration_deadline TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on tournaments
ALTER TABLE public.tournaments ENABLE ROW LEVEL SECURITY;

-- Tournament administrators (many-to-many relationship)
CREATE TABLE public.tournament_admins (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    role TEXT DEFAULT 'admin' CHECK (role IN ('admin', 'moderator')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tournament_id, user_id)
);

-- Enable RLS on tournament_admins
ALTER TABLE public.tournament_admins ENABLE ROW LEVEL SECURITY;

-- =============================================
-- TEAMS AND PLAYERS
-- =============================================

-- Teams table
CREATE TABLE public.teams (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    captain_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    contact_email TEXT,
    contact_phone TEXT,
    seed INTEGER,
    pool_id UUID, -- Will reference pools table
    registration_status TEXT DEFAULT 'pending' CHECK (registration_status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tournament_id, name)
);

-- Enable RLS on teams
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

-- Players table
CREATE TABLE public.players (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    jersey_number INTEGER,
    position TEXT,
    is_captain BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, jersey_number)
);

-- Enable RLS on players
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;

-- =============================================
-- POOLS AND DIVISIONS
-- =============================================

-- Pools table (for organizing teams within tournaments)
CREATE TABLE public.pools (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    max_teams INTEGER DEFAULT 8,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tournament_id, name)
);

-- Enable RLS on pools
ALTER TABLE public.pools ENABLE ROW LEVEL SECURITY;

-- Add foreign key constraint to teams.pool_id
ALTER TABLE public.teams ADD CONSTRAINT fk_teams_pool 
    FOREIGN KEY (pool_id) REFERENCES public.pools(id) ON DELETE SET NULL;

-- =============================================
-- COURTS AND VENUES
-- =============================================

-- Courts table
CREATE TABLE public.courts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    location TEXT,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tournament_id, name)
);

-- Enable RLS on courts
ALTER TABLE public.courts ENABLE ROW LEVEL SECURITY;

-- =============================================
-- GAMES AND MATCHES
-- =============================================

-- Game status enum
CREATE TYPE game_status AS ENUM (
    'scheduled',
    'in_progress',
    'completed',
    'forfeited',
    'cancelled'
);

-- Games table
CREATE TABLE public.games (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE NOT NULL,
    pool_id UUID REFERENCES public.pools(id) ON DELETE SET NULL,
    round_number INTEGER NOT NULL DEFAULT 1,
    game_number INTEGER NOT NULL,
    team1_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
    team2_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
    court_id UUID REFERENCES public.courts(id) ON DELETE SET NULL,
    scheduled_time TIMESTAMP WITH TIME ZONE,
    actual_start_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    status game_status DEFAULT 'scheduled',
    team1_score INTEGER DEFAULT 0,
    team2_score INTEGER DEFAULT 0,
    winner_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
    forfeit_reason TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (team1_id != team2_id)
);

-- Enable RLS on games
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;

-- =============================================
-- FLIGHTS (FOR PLAYOFF BRACKETS)
-- =============================================

-- Flight types enum
CREATE TYPE flight_type AS ENUM (
    'championship',
    'consolation',
    'placement'
);

-- Flights table
CREATE TABLE public.flights (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    type flight_type NOT NULL DEFAULT 'championship',
    description TEXT,
    min_seed INTEGER,
    max_seed INTEGER,
    bracket_format tournament_format NOT NULL DEFAULT 'single_elimination',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tournament_id, name)
);

-- Enable RLS on flights
ALTER TABLE public.flights ENABLE ROW LEVEL SECURITY;

-- Flight teams (many-to-many relationship)
CREATE TABLE public.flight_teams (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    flight_id UUID REFERENCES public.flights(id) ON DELETE CASCADE NOT NULL,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
    seed_in_flight INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(flight_id, team_id),
    UNIQUE(flight_id, seed_in_flight)
);

-- Enable RLS on flight_teams
ALTER TABLE public.flight_teams ENABLE ROW LEVEL SECURITY;

-- =============================================
-- STANDINGS AND STATISTICS
-- =============================================

-- Team standings table (calculated from game results)
CREATE TABLE public.team_standings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE NOT NULL,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
    pool_id UUID REFERENCES public.pools(id) ON DELETE SET NULL,
    games_played INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    points_for INTEGER DEFAULT 0,
    points_against INTEGER DEFAULT 0,
    point_differential INTEGER DEFAULT 0,
    win_percentage DECIMAL(5,4) DEFAULT 0.0000,
    ranking INTEGER,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tournament_id, team_id, pool_id)
);

-- Enable RLS on team_standings
ALTER TABLE public.team_standings ENABLE ROW LEVEL SECURITY;

-- =============================================
-- TIE-BREAKING RULES
-- =============================================

-- Tiebreaker types enum
CREATE TYPE tiebreaker_type AS ENUM (
    'head_to_head',
    'point_differential',
    'points_for',
    'points_against',
    'win_percentage',
    'coin_toss'
);

-- Tournament tiebreakers table
CREATE TABLE public.tournament_tiebreakers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE NOT NULL,
    tiebreaker_type tiebreaker_type NOT NULL,
    priority_order INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tournament_id, priority_order)
);

-- Enable RLS on tournament_tiebreakers
ALTER TABLE public.tournament_tiebreakers ENABLE ROW LEVEL SECURITY;

-- =============================================
-- NOTIFICATIONS AND ANNOUNCEMENTS
-- =============================================

-- Notification types enum
CREATE TYPE notification_type AS ENUM (
    'announcement',
    'game_reminder',
    'score_update',
    'schedule_change',
    'registration_update'
);

-- Notifications table
CREATE TABLE public.notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    type notification_type NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    target_audience TEXT DEFAULT 'all' CHECK (target_audience IN ('all', 'teams', 'admins', 'pool', 'flight')),
    target_pool_id UUID REFERENCES public.pools(id) ON DELETE SET NULL,
    target_flight_id UUID REFERENCES public.flights(id) ON DELETE SET NULL,
    is_push_notification BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- User notification read status
CREATE TABLE public.user_notification_status (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    notification_id UUID REFERENCES public.notifications(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(notification_id, user_id)
);

-- Enable RLS on user_notification_status
ALTER TABLE public.user_notification_status ENABLE ROW LEVEL SECURITY;

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Tournaments indexes
CREATE INDEX idx_tournaments_created_by ON public.tournaments(created_by);
CREATE INDEX idx_tournaments_status ON public.tournaments(status);
CREATE INDEX idx_tournaments_sport ON public.tournaments(sport);
CREATE INDEX idx_tournaments_start_date ON public.tournaments(start_date);

-- Teams indexes
CREATE INDEX idx_teams_tournament_id ON public.teams(tournament_id);
CREATE INDEX idx_teams_captain_id ON public.teams(captain_id);
CREATE INDEX idx_teams_pool_id ON public.teams(pool_id);

-- Players indexes
CREATE INDEX idx_players_team_id ON public.players(team_id);
CREATE INDEX idx_players_user_id ON public.players(user_id);

-- Games indexes
CREATE INDEX idx_games_tournament_id ON public.games(tournament_id);
CREATE INDEX idx_games_team1_id ON public.games(team1_id);
CREATE INDEX idx_games_team2_id ON public.games(team2_id);
CREATE INDEX idx_games_scheduled_time ON public.games(scheduled_time);
CREATE INDEX idx_games_status ON public.games(status);
CREATE INDEX idx_games_pool_id ON public.games(pool_id);

-- Standings indexes
CREATE INDEX idx_team_standings_tournament_id ON public.team_standings(tournament_id);
CREATE INDEX idx_team_standings_team_id ON public.team_standings(team_id);
CREATE INDEX idx_team_standings_ranking ON public.team_standings(ranking);

-- Notifications indexes
CREATE INDEX idx_notifications_tournament_id ON public.notifications(tournament_id);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at);
CREATE INDEX idx_user_notification_status_user_id ON public.user_notification_status(user_id);


