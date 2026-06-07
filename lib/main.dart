import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap.dart';
import 'app/fuel_arena_app.dart';
import 'shared/services/app_logger.dart';

Future<void> main() async {
  const logger = AppLogger();
  await (runZonedGuarded<Future<void>>(
        () async {
          _installGlobalErrorLogging(logger);
          final bootstrap = await bootstrapFuelArena();
          runApp(
            ProviderScope(
              child: FuelArenaApp(
                bootstrap: bootstrap,
              ),
            ),
          );
        },
        (error, stackTrace) {
          logger.fatal(
            'Uncaught zone error',
            error: error,
            stackTrace: stackTrace,
          );
        },
      ) ??
      Future<void>.value());
}

void _installGlobalErrorLogging(AppLogger logger) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logger.flutterError(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger.fatal(
      'Uncaught platform error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
}
