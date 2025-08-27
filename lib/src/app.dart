import 'package:flutter/material.dart';

import 'package:clevertournament/src/core/theme/app_theme.dart';
import 'package:clevertournament/src/core/supabase/supabase_service.dart';
import 'package:clevertournament/src/features/auth/login_page.dart';
import 'package:clevertournament/src/features/auth/register_page.dart';
import 'package:clevertournament/src/features/home/home_shell.dart';
import 'package:clevertournament/src/features/tournaments/join_team_page.dart';

class CleverTournamentApp extends StatelessWidget {
  const CleverTournamentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.buildTheme(Brightness.light);
    final darkTheme = AppTheme.buildTheme(Brightness.dark);
    final session = SupabaseService.client.auth.currentSession;

    return MaterialApp(
      title: 'CleverTournament',
      theme: theme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: session != null ? '/home' : '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomeShell(),
      },
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        try {
          final uri = Uri.parse(name);
          if (uri.path == '/join') {
            final code = uri.queryParameters['code'];
            return MaterialPageRoute(builder: (_) => JoinTeamPage(initialCode: code));
          }
        } catch (_) {}
        return null;
      },
    );
  }
}

Future<void> initAppServices() async {
  await SupabaseService.init();
}
