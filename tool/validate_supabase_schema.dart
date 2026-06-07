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

  final migrationFiles = _migrationFiles();
  check(
    'supabase/migrations',
    migrationFiles.isNotEmpty,
    'Supabase migration files are missing',
  );
  final sql = migrationFiles.map((file) => file.readAsStringSync()).join('\n');

  _validateRequiredTables(sql, check);
  _validateRls(sql, check);
  _validatePolicies(sql, check);
  _validateProfileSelfWriteHardening(check);
  _validateViews(sql, check);
  _validateRpcFunctions(sql, check);
  _validateRpcGrants(sql, check);
  _validateAppSettingsSeeds(sql, check);
  _validateSubscriptionProductSeeds(sql, check);
  _validateIntegrityGuards(sql, check);
  _validateVehicleCatalogSeed(check);

  if (failures.isEmpty) {
    stdout.writeln('supabase schema valid: $checkCount checks');
    return;
  }

  stderr.writeln('supabase schema validation failed:');
  for (final failure in failures) {
    stderr.writeln('- $failure');
  }
  exitCode = 1;
}

void _validateRequiredTables(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final table in _requiredTables) {
    check(
      'supabase/migrations/$table',
      _hasCreateTable(sql, table),
      'required table public.$table is missing',
    );
  }
}

void _validateRls(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  final tables = {..._requiredTables, ..._createdPublicTables(sql)}..removeAll({
      'spatial_ref_sys',
    });
  for (final table in tables) {
    check(
      'supabase/migrations/$table',
      _hasRls(sql, table),
      'public.$table must enable row level security',
    );
  }
}

void _validatePolicies(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final entry in _requiredPolicies.entries) {
    final table = entry.key;
    for (final policy in entry.value) {
      check(
        'supabase/migrations/$table',
        _hasPolicy(sql, table, policy),
        'public.$table must define policy "$policy"',
      );
    }
  }
}

void _validateViews(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final view in [
    'public_rankings',
    'vehicle_catalog_view',
    'vehicle_manufacturer_catalog_view',
  ]) {
    check(
      'supabase/migrations/$view',
      _hasView(sql, view),
      'public.$view view is missing',
    );
  }

  final publicRankings = _viewSql(sql, 'public_rankings').toLowerCase();
  for (final forbidden in [
    'drive_points',
    'latitude',
    'longitude',
    ' email',
    '.email',
  ]) {
    check(
      'supabase/migrations/public_rankings',
      !publicRankings.contains(forbidden),
      'public_rankings must not expose $forbidden',
    );
  }

  final manufacturerCatalog =
      _viewSql(sql, 'vehicle_manufacturer_catalog_view').toLowerCase();
  for (final token in [
    'with (security_invoker = true)',
    'count(distinct vm.id)::integer as model_count',
    'coalesce(min(vmy.year), 0)::integer as min_year',
    'coalesce(max(vmy.year), 0)::integer as max_year',
    'left join public.vehicle_models vm',
    'left join public.vehicle_model_years vmy',
  ]) {
    check(
      'supabase/migrations/vehicle_manufacturer_catalog_view',
      manufacturerCatalog.contains(token),
      'vehicle_manufacturer_catalog_view must expose catalog stat "$token"',
    );
  }
}

void _validateRpcFunctions(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final functionName in [
    'fuel_league_for_type',
    'is_admin_user',
    'recompute_rankings',
    'claim_mission_reward',
    'is_crew_member',
    'get_my_crew_summary',
    'get_my_crew_members',
    'get_admin_dashboard_metrics',
  ]) {
    check(
      'supabase/migrations/$functionName',
      _hasFunction(sql, functionName),
      'required RPC function public.$functionName is missing',
    );
  }

  for (final functionName in [
    'is_admin_user',
    'recompute_rankings',
    'claim_mission_reward',
    'is_crew_member',
    'get_my_crew_summary',
    'get_my_crew_members',
    'get_admin_dashboard_metrics',
  ]) {
    final functionSql = _functionSql(sql, functionName).toLowerCase();
    check(
      'supabase/migrations/$functionName',
      functionSql.contains('security definer'),
      'public.$functionName must be security definer',
    );
    check(
      'supabase/migrations/$functionName',
      functionSql.contains('set search_path = public'),
      'public.$functionName must pin search_path to public',
    );
  }
}

void _validateRpcGrants(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  final normalized = sql.toLowerCase();
  for (final entry in {
    'recompute_rankings': 'public.recompute_rankings(text)',
    'claim_mission_reward': 'public.claim_mission_reward(uuid, uuid)',
  }.entries) {
    final functionName = entry.key;
    final signature = entry.value;
    for (final role in ['public', 'anon', 'authenticated']) {
      check(
        'supabase/migrations/$functionName',
        normalized.contains('revoke all on function $signature from $role'),
        'edge-only RPC $signature must revoke execute from $role',
      );
    }
    check(
      'supabase/migrations/$functionName',
      normalized.contains(
        'grant execute on function $signature to service_role',
      ),
      'edge-only RPC $signature must grant execute to service_role only',
    );
  }
}

void _validateAppSettingsSeeds(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final key in _requiredPublicAppSettings) {
    check(
      'supabase/migrations/app_settings/$key',
      RegExp(
        "\\(\\s*'$key'\\s*,\\s*'\\{[^']+\\}'\\s*,\\s*'[^']*'\\s*,\\s*true\\s*\\)",
        caseSensitive: false,
      ).hasMatch(sql),
      'public app_settings seed "$key" is missing or not public',
    );
  }
}

void _validateSubscriptionProductSeeds(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final productId in _requiredIapProductIds) {
    check(
      'supabase/migrations/subscription_plans/$productId',
      sql.contains("'$productId'"),
      'subscription_plans seed must include product_id $productId',
    );
  }
}

void _validateIntegrityGuards(
  String sql,
  void Function(String scope, bool condition, String message) check,
) {
  for (final index in [
    'drive_scores_drive_session_id_uidx',
    'purchase_verifications_provider_tx_uidx',
    'user_subscriptions_user_plan_uidx',
    'ranking_update_jobs_active_period_uidx',
    'user_coupons_user_coupon_uidx',
    'edge_function_idempotency_user_function_idx',
    'privacy_requests_active_type_uidx',
  ]) {
    check(
      'supabase/migrations/$index',
      sql.contains(index),
      'integrity guard $index is missing',
    );
  }

  check(
    'supabase/migrations/edge_function_idempotency_keys',
    RegExp(
      r'unique\s*\(\s*user_id\s*,\s*function_name\s*,\s*idempotency_key\s*\)',
      caseSensitive: false,
    ).hasMatch(sql),
    'edge_function_idempotency_keys must be unique by user/function/key',
  );
  check(
    'supabase/migrations/ranking_update_jobs',
    sql.toLowerCase().contains("where status in ('pending', 'running')"),
    'ranking_update_jobs must dedupe active jobs by period',
  );
  check(
    'supabase/migrations/custom_vehicle_requests',
    sql
            .toLowerCase()
            .contains('user_vehicle_id uuid references public.user_vehicles') &&
        sql.toLowerCase().contains('custom_vehicle_requests_user_vehicle_idx'),
    'custom_vehicle_requests must link review rows to user_vehicles',
  );
  check(
    'supabase/migrations/custom_vehicle_requests_self_insert',
    sql.toLowerCase().contains('custom_vehicle_requests_self_insert') &&
        sql.toLowerCase().contains('user_vehicle_id is not null') &&
        sql.toLowerCase().contains('from public.user_vehicles uv') &&
        sql.toLowerCase().contains('uv.user_id = auth.uid()'),
    'custom_vehicle_requests insert policy must require owned user_vehicles',
  );
  check(
    'supabase/migrations/privacy_requests',
    sql.toLowerCase().contains('privacy_requests_active_type_uidx') &&
        sql.toLowerCase().contains("where status in ('open', 'review')"),
    'privacy_requests must dedupe active requests by user and request type',
  );
}

void _validateProfileSelfWriteHardening(
  void Function(String scope, bool condition, String message) check,
) {
  final migration =
      File('supabase/migrations/202606060023_profile_self_write_hardening.sql');
  check(
    migration.path,
    migration.existsSync(),
    'profile self-write hardening migration is missing',
  );
  if (!migration.existsSync()) {
    return;
  }

  final source = migration.readAsStringSync().toLowerCase();
  for (final token in [
    'drop policy if exists "profiles_insert_self"',
    'create policy "profiles_insert_self" on public.profiles',
    'coalesce(is_admin, false) = false',
    'coalesce(is_premium, false) = false',
    'coalesce(total_score, 0) = 0',
    'coalesce(season_score, 0) = 0',
    'coalesce(current_streak, 0) = 0',
    'coalesce(best_streak, 0) = 0',
    "coalesce(nullif(tier, ''), 'bronze i') = 'bronze i'",
    'revoke insert on public.profiles from anon, authenticated',
    'revoke update on public.profiles from anon, authenticated',
    'grant insert (',
    'grant update (',
    'on public.profiles to authenticated',
  ]) {
    check(
      migration.path,
      source.contains(token),
      'profile self-write hardening must keep "$token"',
    );
  }

  final insertColumns = _profileGrantColumns(source, 'insert');
  final updateColumns = _profileGrantColumns(source, 'update');
  check(
    migration.path,
    insertColumns.isNotEmpty && updateColumns.isNotEmpty,
    'profile self-write hardening must grant explicit profile column lists',
  );

  for (final sensitiveColumn in [
    'tier',
    'total_score',
    'season_score',
    'current_streak',
    'best_streak',
    'is_premium',
    'is_admin',
    'created_at',
  ]) {
    check(
      migration.path,
      !insertColumns.contains(sensitiveColumn),
      'profile insert grant must not allow client-set $sensitiveColumn',
    );
    check(
      migration.path,
      !updateColumns.contains(sensitiveColumn),
      'profile update grant must not allow client-set $sensitiveColumn',
    );
  }
}

void _validateVehicleCatalogSeed(
  void Function(String scope, bool condition, String message) check,
) {
  final schemaSql = File(
    'supabase/migrations/202606060001_google_vehicle_leagues.sql',
  ).readAsStringSync();
  final seedFile = File(
    'supabase/migrations/202606060002_vehicle_catalog_seed.sql',
  );
  final seedSql = seedFile.existsSync() ? seedFile.readAsStringSync() : '';

  check(
    'supabase/migrations/vehicle_variants',
    schemaSql.contains('efficiency_unit text not null default'),
    'vehicle_variants must define efficiency_unit before catalog seed runs',
  );
  check(
    'supabase/migrations/vehicle_catalog_seed',
    seedSql.contains('year-hyundai-001-kr-2008') &&
        seedSql.contains('variant-hyundai-001-kr-2008-gasoline'),
    'vehicle catalog migration seed must include 2008 powertrain rows',
  );
  check(
    'supabase/migrations/vehicle_catalog_seed',
    seedSql.contains('model-hyundai-001-kr') &&
        seedSql.contains('model-hyundai-avante-n-kr') &&
        seedSql.contains('model-hyundai-avante-sport-kr'),
    'vehicle catalog migration seed must include current Hyundai model ids',
  );
  check(
    'supabase/migrations/vehicle_catalog_seed',
    !seedSql.contains("'model-avante'") &&
        !seedSql.contains("'variant-avante-2024-gasoline'"),
    'vehicle catalog migration seed must not contain stale compact Avante rows',
  );
  check(
    'supabase/migrations/vehicle_catalog_seed',
    !seedSql.contains('variant-hyundai-avante-2026-g16-smart') &&
        !seedSql.contains('variant-hyundai-avante-2026-g16-modern') &&
        !seedSql.contains('variant-hyundai-avante-2026-g16-inspiration') &&
        !seedSql.contains('variant-hyundai-avante-2026-g16-nline') &&
        !seedSql.contains('variant-hyundai-avante-2026-hybrid-modern') &&
        !seedSql.contains('variant-hyundai-avante-2026-lpi-modern'),
    'vehicle catalog migration seed must not contain sales-trim Avante rows',
  );
  check(
    'supabase/migrations/vehicle_catalog_seed',
    RegExp(r"^  \('variant-", multiLine: true).allMatches(seedSql).length >=
        5000,
    'vehicle catalog migration seed must include the full generated variant set',
  );
}

bool _hasCreateTable(String sql, String table) {
  return RegExp(
    'create\\s+table\\s+(if\\s+not\\s+exists\\s+)?public\\.$table\\b',
    caseSensitive: false,
  ).hasMatch(sql);
}

Set<String> _createdPublicTables(String sql) {
  final tables = <String>{};
  final regex = RegExp(
    r'create\s+table\s+(if\s+not\s+exists\s+)?public\.([a-zA-Z0-9_]+)\b',
    caseSensitive: false,
  );
  for (final match in regex.allMatches(sql)) {
    tables.add(match.group(2)!.toLowerCase());
  }
  return tables;
}

bool _hasRls(String sql, String table) {
  return RegExp(
    'alter\\s+table\\s+public\\.$table\\s+enable\\s+row\\s+level\\s+security',
    caseSensitive: false,
  ).hasMatch(sql);
}

bool _hasPolicy(String sql, String table, String policy) {
  return RegExp(
    'create\\s+policy\\s+"$policy"\\s+on\\s+public\\.$table\\b',
    caseSensitive: false,
  ).hasMatch(sql);
}

bool _hasView(String sql, String view) {
  return RegExp(
    'create\\s+or\\s+replace\\s+view\\s+public\\.$view\\b',
    caseSensitive: false,
  ).hasMatch(sql);
}

bool _hasFunction(String sql, String functionName) {
  return RegExp(
    'create\\s+or\\s+replace\\s+function\\s+public\\.$functionName\\b',
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

String _functionSql(String sql, String functionName) {
  final lower = sql.toLowerCase();
  final start =
      lower.indexOf('create or replace function public.$functionName');
  if (start < 0) return '';
  final next = lower.indexOf('\ncreate or replace function public.', start + 1);
  final end = next < 0 ? sql.length : next;
  return sql.substring(start, end);
}

Set<String> _profileGrantColumns(String sql, String verb) {
  final match = RegExp(
    'grant\\s+$verb\\s*\\(([\\s\\S]*?)\\)\\s+on\\s+public\\.profiles\\s+to\\s+authenticated',
    caseSensitive: false,
  ).firstMatch(sql);
  final body = match?.group(1);
  if (body == null) {
    return const {};
  }
  return body
      .split(',')
      .map((column) => column.trim().replaceAll(RegExp(r'\s+'), ' '))
      .where((column) => column.isNotEmpty)
      .toSet();
}

List<File> _migrationFiles() {
  final directory = Directory('supabase/migrations');
  if (!directory.existsSync()) return const [];
  return directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

const _requiredTables = [
  'profiles',
  'app_consents',
  'consent_logs',
  'vehicles',
  'fuel_leagues',
  'vehicle_manufacturers',
  'vehicle_models',
  'vehicle_model_years',
  'vehicle_variants',
  'user_vehicles',
  'league_memberships',
  'custom_vehicle_requests',
  'drive_sessions',
  'drive_points',
  'drive_scores',
  'rankings',
  'ranking_update_jobs',
  'battles',
  'battle_participants',
  'seasons',
  'season_missions',
  'mission_progress',
  'badges',
  'user_badges',
  'achievements',
  'user_achievements',
  'crews',
  'crew_members',
  'notifications',
  'sponsors',
  'sponsor_challenges',
  'advertisements',
  'ad_rewards',
  'coupons',
  'user_coupons',
  'subscription_plans',
  'user_subscriptions',
  'purchase_verifications',
  'fraud_reviews',
  'report_items',
  'support_tickets',
  'support_ticket_messages',
  'app_settings',
  'app_release_notes',
  'analytics_events',
  'user_local_sync_logs',
  'vehicle_catalog_change_logs',
  'admin_action_logs',
  'privacy_requests',
  'edge_function_idempotency_keys',
];

const _requiredPolicies = {
  'profiles': [
    'profiles_select_self',
    'profiles_update_self',
    'profiles_insert_self',
  ],
  'app_consents': ['consents_self'],
  'consent_logs': [
    'consent_logs_self_insert',
    'consent_logs_self_select_or_admin',
  ],
  'vehicles': ['vehicles_self'],
  'fuel_leagues': ['fuel_leagues_read_all'],
  'vehicle_manufacturers': [
    'vehicle_manufacturers_read_all',
    'vehicle_manufacturers_admin_write',
  ],
  'vehicle_models': [
    'vehicle_models_read_all',
    'vehicle_models_admin_write',
  ],
  'vehicle_model_years': [
    'vehicle_model_years_read_all',
    'vehicle_model_years_admin_write',
  ],
  'vehicle_variants': [
    'vehicle_variants_read_all',
    'vehicle_variants_admin_write',
  ],
  'user_vehicles': ['user_vehicles_self'],
  'league_memberships': ['league_memberships_self'],
  'custom_vehicle_requests': [
    'custom_vehicle_requests_self_select_or_admin',
    'custom_vehicle_requests_self_insert',
    'custom_vehicle_requests_admin_update',
    'custom_vehicle_requests_admin_delete',
  ],
  'drive_sessions': ['drive_sessions_self'],
  'drive_points': ['drive_points_private_self'],
  'drive_scores': ['drive_scores_self'],
  'rankings': ['rankings_read_all'],
  'ranking_update_jobs': [
    'ranking_update_jobs_admin_select',
    'ranking_update_jobs_admin_write',
  ],
  'battles': ['battles_read_all', 'battles_create_auth'],
  'battle_participants': ['battle_participants_member'],
  'seasons': ['seasons_read_all'],
  'season_missions': ['season_missions_read_all'],
  'mission_progress': ['mission_progress_self'],
  'badges': ['badges_read_all', 'badges_admin_write'],
  'user_badges': ['user_badges_self'],
  'achievements': ['achievements_read_all', 'achievements_admin_write'],
  'user_achievements': ['user_achievements_self'],
  'crews': ['crews_member_select', 'crews_admin_write'],
  'crew_members': ['crew_members_member_select', 'crew_members_admin_write'],
  'notifications': ['notifications_self'],
  'sponsors': ['sponsors_active_read', 'sponsors_admin_write'],
  'sponsor_challenges': [
    'sponsor_challenges_active_read',
    'sponsor_challenges_admin_write',
  ],
  'advertisements': [
    'advertisements_active_read',
    'advertisements_admin_write',
  ],
  'ad_rewards': ['ad_rewards_self_select', 'ad_rewards_admin_select'],
  'coupons': ['coupons_active_read', 'coupons_admin_write'],
  'user_coupons': ['user_coupons_self'],
  'subscription_plans': [
    'subscription_plans_public_read',
    'subscription_plans_admin_write',
  ],
  'user_subscriptions': ['subscriptions_self'],
  'purchase_verifications': ['purchase_verifications_self_select'],
  'fraud_reviews': ['fraud_reviews_self'],
  'report_items': [
    'reports_create_self',
    'reports_read_self',
    'reports_admin_select',
    'reports_admin_update',
  ],
  'support_tickets': [
    'support_tickets_self_select_or_admin',
    'support_tickets_self_insert',
    'support_tickets_self_update_or_admin',
  ],
  'support_ticket_messages': [
    'support_messages_ticket_participant_select',
    'support_messages_ticket_participant_insert',
  ],
  'app_settings': ['app_settings_public_read', 'app_settings_admin_write'],
  'app_release_notes': [
    'app_release_notes_public_read',
    'app_release_notes_admin_write',
  ],
  'analytics_events': [
    'analytics_events_self_insert',
    'analytics_events_admin_select',
  ],
  'user_local_sync_logs': ['user_local_sync_logs_self'],
  'vehicle_catalog_change_logs': ['vehicle_catalog_change_logs_admin'],
  'admin_action_logs': [
    'admin_action_logs_admin_select',
    'admin_action_logs_admin_insert',
  ],
  'privacy_requests': [
    'privacy_requests_self_select_or_admin',
    'privacy_requests_self_insert',
    'privacy_requests_admin_update',
  ],
  'edge_function_idempotency_keys': [
    'edge_function_idempotency_self_select',
    'edge_function_idempotency_admin_select',
  ],
};

const _requiredPublicAppSettings = [
  'reward_ad_daily_limit',
  'reward_ads_enabled',
  'new_user_ad_protection_days',
  'season_ending_soon_days',
  'official_drive_min_distance_km',
  'official_drive_min_duration_seconds',
  'abnormal_speed_kmh',
  'allow_custom_vehicle_official_ranking',
  'split_plug_in_hybrid_league',
  'friendly_battle_enabled',
  'premium_price_label',
  'coupons_enabled',
  'fairness_guidelines',
];

const _requiredIapProductIds = [
  'fuel_arena_premium_monthly',
  'fuel_arena_premium_yearly',
  'fuel_arena_season_pass',
  'fuel_arena_premium_bundle',
];
