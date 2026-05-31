import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class FuelArenaApp extends StatelessWidget {
  const FuelArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fuel Arena',
      debugShowCheckedModeBanner: false,
      theme: FuelArenaTheme.dark,
      routerConfig: appRouter,
    );
  }
}
