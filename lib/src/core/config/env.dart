class Env {
  // Prefer passing these via --dart-define at build/run time.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qqmsiddtjjmyqfndqywe.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFxbXNpZGR0ampteXFmbmRxeXdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYyOTk0OTEsImV4cCI6MjA3MTg3NTQ5MX0.qnm2D4OmvmwEvKlSq4DmPnhtpyMmpgiKeEC2VyTuj60',
  );
}
