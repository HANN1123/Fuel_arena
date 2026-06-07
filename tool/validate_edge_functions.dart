import 'dart:io';

const expectedFunctions = {
  'assign_vehicle_league',
  'calculate_drive_score',
  'claim_season_reward',
  'finish_drive_session',
  'grant_ad_reward',
  'issue_coupon',
  'process_fraud_review',
  'review_custom_vehicle',
  'send_notification',
  'settle_battle',
  'update_mission_progress',
  'update_rankings',
  'verify_drive_session',
  'verify_purchase',
};

const idempotentFunctions = {
  'claim_season_reward',
  'grant_ad_reward',
  'issue_coupon',
  'settle_battle',
  'update_mission_progress',
};

const requiredSharedFiles = {
  'adminClient.ts',
  'auth.ts',
  'cors.ts',
  'errors.ts',
  'idempotency.ts',
  'response.ts',
  'validators.ts',
};

class CheckFailure {
  const CheckFailure(this.scope, this.message);

  final String scope;
  final String message;

  @override
  String toString() => '$scope: $message';
}

void main() {
  final failures = <CheckFailure>[];
  var checkCount = 0;

  void check(String scope, bool condition, String message) {
    checkCount += 1;
    if (!condition) failures.add(CheckFailure(scope, message));
  }

  final functionsRoot = Directory('supabase/functions');
  check(
    'supabase/functions',
    functionsRoot.existsSync(),
    'directory is missing',
  );
  if (!functionsRoot.existsSync()) {
    _finish(failures, checkCount, 0);
    return;
  }

  final sharedRoot = Directory('${functionsRoot.path}/_shared');
  check('_shared', sharedRoot.existsSync(), 'shared directory is missing');
  for (final fileName in requiredSharedFiles) {
    check(
      '_shared/$fileName',
      File('${sharedRoot.path}/$fileName').existsSync(),
      'required shared helper is missing',
    );
  }

  final functionNames = functionsRoot
      .listSync()
      .whereType<Directory>()
      .map((directory) => _basename(directory.path))
      .where((name) => name != '_shared')
      .toSet();

  for (final expected in expectedFunctions) {
    check(expected, functionNames.contains(expected), 'function is missing');
  }

  for (final functionName in functionNames.toList()..sort()) {
    final file = File('${functionsRoot.path}/$functionName/index.ts');
    check(functionName, file.existsSync(), 'index.ts is missing');
    if (!file.existsSync()) continue;

    final source = file.readAsStringSync();
    _checkFunctionSource(functionName, source, check);
  }

  final sharedAdminClient = File('${sharedRoot.path}/adminClient.ts');
  if (sharedAdminClient.existsSync()) {
    final source = sharedAdminClient.readAsStringSync();
    check(
      '_shared/adminClient.ts',
      source.contains('SUPABASE_SERVICE_ROLE_KEY'),
      'service role key must be read only by shared admin client',
    );
  }

  final sharedCors = File('${sharedRoot.path}/cors.ts');
  if (sharedCors.existsSync()) {
    final source = sharedCors.readAsStringSync();
    check(
      '_shared/cors.ts',
      source.contains('Access-Control-Allow-Headers') &&
          source.contains('x-idempotency-key'),
      'CORS preflight must allow x-idempotency-key for web idempotent requests',
    );
  }

  _finish(failures, checkCount, functionNames.length);
}

void _checkFunctionSource(
  String functionName,
  String source,
  void Function(String scope, bool condition, String message) check,
) {
  check(
    functionName,
    source.contains('import { serve }') &&
        source.contains('https://deno.land/std@'),
    'must import Deno serve from std http server',
  );
  check(functionName, source.contains('serve(async (req) =>'),
      'must register an async request handler');
  check(functionName, source.contains('../_shared/cors.ts'),
      'must import shared CORS helper');
  check(functionName, source.contains('const options = handleOptions(req);'),
      'must evaluate CORS preflight');
  check(functionName, source.contains('if (options) return options;'),
      'must return CORS preflight response before mutation logic');
  check(functionName, source.contains('req.method !== "POST"'),
      'must reject non-POST requests');
  check(functionName, source.contains('../_shared/response.ts'),
      'must import shared response helper');
  check(functionName, source.contains('jsonResponse('),
      'must use shared jsonResponse');
  check(functionName, source.contains('errorResponse('),
      'must use shared errorResponse');
  check(functionName, source.contains('toEdgeFunctionError'),
      'must normalize thrown errors');
  check(functionName, source.contains('catch (error)'),
      'must catch and normalize errors');
  check(functionName, !source.contains('return Response.json('),
      'must not bypass shared response helper');
  check(functionName, !source.contains('SUPABASE_SERVICE_ROLE_KEY'),
      'must not read service role key outside _shared/adminClient.ts');

  if (idempotentFunctions.contains(functionName)) {
    check(functionName, source.contains('../_shared/idempotency.ts'),
        'idempotent function must import shared idempotency helper');
    check(functionName, source.contains('runIdempotentRequest('),
        'idempotent function must wrap mutation in runIdempotentRequest');
    check(functionName, source.contains('requireKey: true'),
        'idempotent function must require an idempotency key');
    check(functionName, source.contains('functionName: "$functionName"'),
        'idempotency functionName must match folder name');
  }

  if (functionName == 'send_notification') {
    check(functionName, source.contains('held_during_drive'),
        'notification function must persist held_during_drive');
    check(functionName, source.contains('body.isDriving === true'),
        'notification function must respect driving mode hold flag');
  }

  if (functionName == 'grant_ad_reward') {
    check(
        functionName,
        source.contains('"reward_ad_daily_limit"') &&
            source.contains('max = 20'),
        'ad reward function must bound remote daily reward limit');
  }

  if (functionName == 'update_rankings') {
    check(functionName, source.contains('RANKING_JOB_SECRET'),
        'ranking job must support server job secret');
    check(functionName, source.contains('isAdminUser'),
        'ranking job must allow admin user authorization');
  }

  if (functionName == 'verify_purchase') {
    check(functionName, source.contains('ALLOW_MOCK_PURCHASE_VERIFICATION'),
        'purchase verification must gate mock verification by env');
    check(functionName, source.contains('purchase_verifications'),
        'purchase verification must write verification records');
    check(functionName, source.contains('requireSecret("APP_STORE_BUNDLE_ID")'),
        'purchase verification must require the App Store bundle id secret');
    check(functionName, source.contains('GOOGLE_PLAY_PACKAGE_NAME'),
        'purchase verification must use the server-owned Google Play package name');
    check(functionName, !source.contains('optionalString(body.packageName)'),
        'purchase verification must not trust client packageName');
    check(
        functionName,
        !source.contains(
            'Deno.env.get("APP_STORE_BUNDLE_ID") ?? "com.fuelarena.fuel_arena"'),
        'purchase verification must not fall back to the Android application id for App Store bundle id');
  }

  if (functionName == 'review_custom_vehicle') {
    check(functionName, source.contains('"invalid_decision"'),
        'vehicle review must reject unknown decisions');
    check(functionName, source.contains('"request_vehicle_mismatch"'),
        'vehicle review must reject request and vehicle mismatches');
    check(functionName, source.contains('"request_vehicle_owner_mismatch"'),
        'vehicle review must reject request and vehicle owner mismatches');
    check(functionName, source.contains('.from("notifications")'),
        'vehicle review must notify the user');
    check(functionName, source.contains('notification_type: "vehicle_review"'),
        'vehicle review notification must use vehicle_review type');
    check(functionName, source.contains('notificationQueued'),
        'vehicle review response must expose notification queue result');
  }

  if (functionName == 'finish_drive_session') {
    check(functionName, source.contains('drive_points'),
        'drive finish must read private drive_points');
    check(functionName, source.contains('is_mocked'),
        'drive finish must consider mocked location signals');
    for (final settingKey in [
      'official_drive_min_distance_km',
      'official_drive_min_duration_seconds',
      'abnormal_speed_kmh',
    ]) {
      check(
        functionName,
        source.contains(settingKey),
        'drive finish must read app_settings.$settingKey',
      );
    }
    check(functionName, source.contains('numericSetting('),
        'drive finish must validate remote numeric settings');
    check(functionName, source.contains('drive_scores'),
        'drive finish must write drive_scores');
    check(functionName, source.contains('ranking_update_jobs'),
        'drive finish must enqueue ranking update jobs');
  }
}

String _basename(String path) {
  return path.split(RegExp(r'[\\/]')).last;
}

void _finish(
  List<CheckFailure> failures,
  int checkCount,
  int functionCount,
) {
  if (failures.isEmpty) {
    stdout.writeln(
      'edge functions valid: $functionCount functions, $checkCount checks',
    );
    return;
  }

  stderr.writeln('edge function validation failed:');
  for (final failure in failures) {
    stderr.writeln('- $failure');
  }
  exitCode = 1;
}
