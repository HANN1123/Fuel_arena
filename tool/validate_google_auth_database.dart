import 'dart:io';

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

  final sql = _migrationSql();
  final normalized = sql.toLowerCase();

  for (final table in [
    'profiles',
    'consent_logs',
    'account_deletion_requests',
    'data_export_requests',
    'auth_audit_logs',
    'admin_audit_logs',
  ]) {
    check(
      'public.$table',
      _hasTable(sql, table) || normalized.contains('alter table public.$table'),
      'public.$table must exist or be hardened by migration',
    );
    check(
      'public.$table',
      _hasRls(sql, table),
      'public.$table must enable row level security',
    );
  }

  for (final column in [
    'google_subject',
    'auth_provider',
    'onboarding_completed',
    'consent_completed',
    'additional_setup_completed',
    'vehicle_setup_completed',
    'representative_vehicle_id',
    'selected_fuel_league',
    'selected_vehicle_class',
    'tier',
    'total_score',
    'season_score',
    'current_streak',
    'best_streak',
    'is_premium',
    'is_admin',
    'status',
    'last_login_at',
    'deleted_at',
  ]) {
    check(
      'public.profiles.$column',
      normalized.contains(column),
      'profiles must include or harden $column',
    );
  }

  for (final functionName in [
    'handle_new_auth_user',
    'handle_new_auth_user_profile',
    'handle_auth_user_login_update',
    'ensure_my_profile',
    'update_my_profile',
    'set_my_profile_vehicle',
    'record_my_consent',
    'revoke_my_consent',
    'request_account_deletion',
    'request_data_export',
    'record_auth_event',
    'get_my_auth_state',
    'is_admin',
    'current_user_role',
    'prevent_profile_protected_field_update',
    'set_updated_at',
  ]) {
    check(
      'public.$functionName',
      _hasFunction(sql, functionName),
      'required auth database function public.$functionName is missing',
    );
  }

  for (final trigger in [
    'on_auth_user_created',
    'on_auth_user_login_updated',
    'prevent_profile_protected_field_update',
  ]) {
    check(
      'trigger.$trigger',
      normalized.contains('create trigger $trigger'),
      'required trigger $trigger is missing',
    );
  }

  for (final policy in [
    'profiles_select_self',
    'profiles_update_self',
    'profiles_insert_self',
    'profiles_admin_select',
    'profiles_admin_update',
    'consent_logs_self_insert',
    'consent_logs_self_select_or_admin',
    'account_deletion_requests_self_select',
    'account_deletion_requests_self_insert',
    'account_deletion_requests_admin_select',
    'account_deletion_requests_admin_update',
    'data_export_requests_self_select',
    'data_export_requests_self_insert',
    'data_export_requests_admin_select',
    'data_export_requests_admin_update',
    'auth_audit_logs_self_select',
    'auth_audit_logs_admin_select',
    'admin_audit_logs_admin_select',
    'admin_audit_logs_admin_insert',
  ]) {
    check(
      'policy.$policy',
      normalized.contains('create policy "$policy"'),
      'required RLS policy "$policy" is missing',
    );
  }

  for (final view in [
    'public_profiles_view',
    'public_rankings_view',
    'public_user_primary_vehicle_view',
  ]) {
    check(
      'view.$view',
      _hasView(sql, view),
      'safe public view public.$view is missing',
    );
  }

  final publicProfiles = _viewSql(sql, 'public_profiles_view').toLowerCase();
  final publicRankings = _viewSql(sql, 'public_rankings_view').toLowerCase();
  for (final forbidden in [
    ' email',
    '.email',
    'google_subject',
    'last_login_at',
    'is_admin',
    'deleted_at',
    'drive_points',
    'latitude',
    'longitude',
  ]) {
    check(
      'safe public views',
      !publicProfiles.contains(forbidden) &&
          !publicRankings.contains(forbidden),
      'safe public views must not expose $forbidden',
    );
  }

  final envExample = File('.env.example').readAsStringSync();
  final productionEnv = File('.env.production.example').readAsStringSync();
  for (final envSource in {
    '.env.example': envExample,
    '.env.production.example': productionEnv,
  }.entries) {
    check(
      envSource.key,
      !RegExp(
        r'^\s*SUPABASE_SERVICE_ROLE_KEY\s*=',
        multiLine: true,
      ).hasMatch(envSource.value),
      '${envSource.key} must not define SUPABASE_SERVICE_ROLE_KEY',
    );
    check(
      envSource.key,
      !RegExp(
        r'^\s*GOOGLE_.*CLIENT_SECRET\s*=',
        multiLine: true,
      ).hasMatch(envSource.value),
      '${envSource.key} must not define Google OAuth client secrets',
    );
  }

  for (final seedKey in [
    'required_terms_version',
    'required_privacy_version',
    'required_location_version',
    'google_auth_enabled',
    'mock_auth_allowed_dev_only',
    'account_deletion_enabled',
    'data_export_enabled',
  ]) {
    check(
      'app_settings.$seedKey',
      normalized.contains("'$seedKey'"),
      'app_settings seed $seedKey is missing',
    );
  }

  final testSql = File('supabase/tests/google_auth_rls_tests.sql');
  check(
    testSql.path,
    testSql.existsSync(),
    'RLS test SQL file is missing',
  );

  if (failures.isEmpty) {
    stdout.writeln('google auth database valid: $checkCount checks');
    return;
  }

  stderr.writeln('google auth database validation failed:');
  for (final failure in failures) {
    stderr.writeln('- $failure');
  }
  exitCode = 1;
}

String _migrationSql() {
  final directory = Directory('supabase/migrations');
  if (!directory.existsSync()) return '';
  final files = directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files.map((file) => file.readAsStringSync()).join('\n');
}

bool _hasTable(String sql, String table) {
  return RegExp(
    'create\\s+table\\s+(if\\s+not\\s+exists\\s+)?public\\.$table\\b',
    caseSensitive: false,
  ).hasMatch(sql);
}

bool _hasRls(String sql, String table) {
  return RegExp(
    'alter\\s+table\\s+public\\.$table\\s+enable\\s+row\\s+level\\s+security',
    caseSensitive: false,
  ).hasMatch(sql);
}

bool _hasFunction(String sql, String functionName) {
  return RegExp(
    'create\\s+or\\s+replace\\s+function\\s+public\\.$functionName\\b',
    caseSensitive: false,
  ).hasMatch(sql);
}

bool _hasView(String sql, String view) {
  return RegExp(
    'create\\s+or\\s+replace\\s+view\\s+public\\.$view\\b',
    caseSensitive: false,
  ).hasMatch(sql);
}

String _viewSql(String sql, String view) {
  final lower = sql.toLowerCase();
  final start = lower.indexOf('create or replace view public.$view');
  if (start < 0) return '';
  final end = sql.indexOf(';', start);
  return end < 0 ? sql.substring(start) : sql.substring(start, end + 1);
}
