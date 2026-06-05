import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap.dart';
import 'app/fuel_arena_app.dart';

Future<void> main() async {
  final bootstrap = await bootstrapFuelArena();
  runApp(
    ProviderScope(
      child: FuelArenaApp(
        bootstrap: bootstrap,
      ),
    ),
  );
}
