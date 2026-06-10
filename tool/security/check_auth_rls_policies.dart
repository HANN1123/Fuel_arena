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

  final sql = _migrationSql().toLowerCase();

  for (final table in _tablesThatMustHaveRls) {
    check(
      'rls.$table',
      sql.contains('alter table public.$table enable row level security'),
      'public.$table must enable RLS',
    );
  }

  for (final token in [
    'auth.uid() = id',
    'auth.uid() = user_id',
    'public.is_admin()',
    'profile protected fields can be changed only by secure rpc',
    'revoke update on public.profiles from anon, authenticated',
    'grant update (',
    'record_my_consent',
    'revoke_my_consent',
    'request_account_deletion',
    'request_data_export',
  ]) {
    check(
      'rls.policy_token',
      sql.contains(token),
      'RLS hardening token "$token" is missing',
    );
  }

  final authAuditFunction = _functionSql(sql, 'record_auth_event');
  for (final forbiddenToken in [
    'idtoken',
    'id_token',
    'accesstoken',
    'access_token',
    'refreshtoken',
    'refresh_token',
    'client_secret',
    'oauth_client_secret',
    'authorization',
  ]) {
    check(
      'record_auth_event',
      authAuditFunction.contains("'$forbiddenToken'"),
      'record_auth_event must redact $forbiddenToken from metadata',
    );
  }

  for (final viewName in [
    'public_profiles_view',
    'public_rankings_view',
  ]) {
    final view = _viewSql(sql, viewName);
    check(
      'view.$viewName',
      view.isNotEmpty,
      'public.$viewName must exist',
    );
    for (final forbidden in [
      'email',
      'google_subject',
      'last_login_at',
      'drive_points',
      'latitude',
      'longitude',
    ]) {
      check(
        'view.$viewName',
        !view.contains(forbidden),
        'public.$viewName must not expose $forbidden',
      );
    }
  }

  final testSql = File('supabase/tests/google_auth_rls_tests.sql');
  check(
    testSql.path,
    testSql.existsSync(),
    'google auth RLS SQL tests are missing',
  );
  if (testSql.existsSync()) {
    final testSource = testSql.readAsStringSync().toLowerCase();
    for (final scenario in [
      'anonymous cannot select profiles directly',
      'user_a can select own profile',
      'user_a cannot update is_admin',
      'user_a cannot update is_premium',
      'user_a cannot update total_score',
      'user_a can insert own consent_logs',
      'user_a cannot select user_b consent_logs',
      'user_a can request account deletion',
      'user_a cannot select user_b account deletion request',
      'user_a cannot select user_b drive_points',
      'public_rankings_view exposes no email',
      'vehicle catalog read succeeds',
      'vehicle catalog write fails for non-admin',
      'admin can update app_settings',
    ]) {
      check(
        testSql.path,
        testSource.contains(scenario),
        'RLS test scenario "$scenario" is missing',
      );
    }
  }

  if (failures.isEmpty) {
    stdout.writeln('auth RLS policies valid: $checkCount checks');
    return;
  }

  stderr.writeln('auth RLS policy validation failed:');
  for (final failure in failures) {
    stderr.writeln('- $failure');
  }
  exitCode = 1;
}

const _tablesThatMustHaveRls = [
  'profiles',
  'consent_logs',
  'account_deletion_requests',
  'data_export_requests',
  'auth_audit_logs',
  'admin_audit_logs',
  'user_vehicles',
  'drive_sessions',
  'drive_points',
  'drive_scores',
  'notifications',
  'user_coupons',
  'user_subscriptions',
  'custom_vehicle_requests',
  'support_tickets',
  'support_ticket_messages',
  'app_settings',
  'vehicle_manufacturers',
  'vehicle_models',
  'vehicle_model_years',
  'vehicle_variants',
  'vehicle_data_sources',
  'rankings',
  'battles',
  'battle_participants',
];

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

String _viewSql(String sql, String view) {
  final start = sql.indexOf('create or replace view public.$view');
  if (start < 0) return '';
  final end = sql.indexOf(';', start);
  return end < 0 ? sql.substring(start) : sql.substring(start, end + 1);
}

String _functionSql(String sql, String functionName) {
  final start = sql.indexOf('create or replace function public.$functionName');
  if (start < 0) return '';
  final next = sql.indexOf('\ncreate or replace function public.', start + 1);
  final end = next < 0 ? sql.length : next;
  return sql.substring(start, end);
}
