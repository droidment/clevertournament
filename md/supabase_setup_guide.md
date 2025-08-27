# Supabase Database Setup Guide

This guide will help you set up the Tournament Management App database in your Supabase project.

## Prerequisites

1. A Supabase project (create one at [supabase.com](https://supabase.com))
2. Access to the Supabase SQL Editor or a PostgreSQL client

## Setup Steps

### 1. Run the Database Schema

Execute the SQL files in the following order:

1. **First, run `supabase_schema.sql`**
   - This creates all the tables, enums, and indexes
   - Copy and paste the entire content into the Supabase SQL Editor
   - Click "Run" to execute

2. **Second, run `supabase_functions.sql`**
   - This creates database functions and triggers
   - Copy and paste the entire content into the Supabase SQL Editor
   - Click "Run" to execute

3. **Third, run `supabase_rls_policies.sql`**
   - This sets up Row Level Security policies
   - Copy and paste the entire content into the Supabase SQL Editor
   - Click "Run" to execute

### 2. Enable Authentication

In your Supabase dashboard:

1. Go to **Authentication** > **Settings**
2. Enable **Email** authentication
3. Configure any additional authentication providers as needed
4. Set up email templates if desired

### 3. Configure Storage (Optional)

If you plan to store tournament logos, team photos, or other files:

1. Go to **Storage**
2. Create a bucket named `tournament-assets`
3. Set appropriate policies for file access

### 4. Environment Variables

For your Flutter app, you'll need these environment variables:

```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

You can find these in your Supabase project settings under **API**.

## Database Structure Overview

### Core Tables

- **profiles**: User profiles (extends Supabase auth.users)
- **tournaments**: Tournament information and settings
- **teams**: Teams registered for tournaments
- **players**: Individual players on teams
- **pools**: Divisions/groups within tournaments
- **games**: Individual matches/games
- **courts**: Available courts/venues
- **flights**: Playoff brackets/divisions

### Supporting Tables

- **tournament_admins**: Additional administrators for tournaments
- **team_standings**: Calculated standings and statistics
- **tournament_tiebreakers**: Custom tie-breaking rules
- **flights** & **flight_teams**: Playoff bracket management
- **notifications**: Tournament announcements and updates
- **user_notification_status**: Read/unread status for notifications

### Key Features

1. **Automatic Standings Calculation**: Standings are automatically updated when game results are entered
2. **Flexible Tournament Formats**: Support for Round Robin, Single/Double Elimination, Swiss, and Hybrid formats
3. **Role-Based Security**: Different access levels for organizers, team captains, players, and spectators
4. **Real-time Updates**: Built on Supabase's real-time capabilities
5. **Scalable Design**: Optimized for tournaments with 20+ teams

## Security Model

The database uses Row Level Security (RLS) to ensure:

- Users can only access tournaments they're involved in
- Team captains can manage their own teams
- Tournament organizers have full control over their tournaments
- Public information (schedules, standings) is viewable by everyone
- Private information is protected

## Testing the Setup

After running all the SQL files, you can test the setup by:

1. Creating a test user account through Supabase Auth
2. Creating a test tournament
3. Adding test teams and players
4. Generating a schedule using the provided functions

## Troubleshooting

### Common Issues

1. **Permission Errors**: Make sure RLS policies are applied correctly
2. **Function Errors**: Ensure all functions are created before the triggers
3. **Foreign Key Errors**: Check that parent records exist before creating child records

### Useful Queries

```sql
-- Check if all tables were created
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies WHERE schemaname = 'public';

-- Test standings calculation
SELECT * FROM calculate_team_standings('tournament-uuid-here');
```

## Next Steps

1. Set up your Flutter app with the Supabase Flutter package
2. Implement authentication flows
3. Create UI screens for tournament management
4. Test real-time updates
5. Deploy your app

For Flutter integration, refer to the [Supabase Flutter documentation](https://supabase.com/docs/reference/dart/introduction).

