import 'package:flutter/material.dart';

import 'package:clevertournament/src/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initAppServices().then((_) {
    runApp(const CleverTournamentApp());
  });
}
