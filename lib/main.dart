import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/fuel_arena_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } on Exception {
    // Local mock mode works without .env. Supabase is opt-in until configured.
  }
  runApp(const ProviderScope(child: FuelArenaApp()));
}
