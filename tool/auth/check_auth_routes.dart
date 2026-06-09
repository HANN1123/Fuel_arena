// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  print('Running static check on authentication routes and UI fields...');

  final loginScreenFile =
      File('lib/features/auth/presentation/login_screen.dart');
  if (!loginScreenFile.existsSync()) {
    print('[ERROR] login_screen.dart not found.');
    exit(1);
  }

  final loginContent = loginScreenFile.readAsStringSync();
  final prohibitedPatterns = [
    'TextField',
    'TextFormField',
    'emailController',
    'passwordController',
    'controller:',
  ];

  for (final pattern in prohibitedPatterns) {
    if (loginContent.contains(pattern)) {
      print(
          '[ERROR] Prohibited UI element or controller found in login_screen.dart: "$pattern"');
      print(
          'Google-only login screens must not contain manual email/password text fields.');
      exit(1);
    }
  }

  final routerFile = File('lib/app/router.dart');
  if (!routerFile.existsSync()) {
    print('[ERROR] router.dart not found.');
    exit(1);
  }

  final routerContent = routerFile.readAsStringSync();

  // Static check on route guards
  // Admin routes must use AdminRequiredRoute
  final adminRoutes = [
    '/admin',
    '/admin/vehicles',
    '/admin/powertrain',
  ];

  for (final route in adminRoutes) {
    // Check if the route exists and has AdminRequiredRoute in its block
    final routeIdx = routerContent.indexOf("path: '$route'");
    if (routeIdx == -1) {
      print(
          '[WARNING] Admin route path "$route" was not found in router.dart.');
      continue;
    }

    final end = (routeIdx + 250 > routerContent.length)
        ? routerContent.length
        : routeIdx + 250;
    final nextBlock = routerContent.substring(routeIdx, end);
    if (!nextBlock.contains('AdminRequiredRoute') &&
        !nextBlock.contains('redirect:')) {
      print(
          '[ERROR] Admin route "$route" does not appear to be protected by AdminRequiredRoute.');
      exit(1);
    }
  }

  print('[SUCCESS] Auth routes and login UI fields validation passed.');
}
