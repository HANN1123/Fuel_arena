import 'dart:io';

const _iosRunnerBundleId = 'com.fuelarena.fuelArena';

const _requiredIapProductIds = [
  'fuel_arena_premium_monthly',
  'fuel_arena_premium_yearly',
  'fuel_arena_season_pass',
  'fuel_arena_premium_bundle',
];

const _mojibakeTokens = [
  '�',
  '荑',
  '由',
  '愿',
  '諛',
  '蹂',
  '紐',
  '寃곗',
  '援щ',
  '媛쒕',
  '怨좉',
  '源딄',
  '遺덈',
  '吏꾪',
  '李얠',
  '紐삵',
  '踰덈',
  '愿묎',
  '蹂듭',
  '異쒖',
  '?댁',
  '?ㅼ',
  '?ㅽ',
  '?ъ',
  '?쒖',
  '?곗',
  '?붾',
  '?꾩',
  '?좉',
  '?덈',
  '?⑸',
];

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

  _validateClientSecrets(check);
  _validateRuntimeConfigSafety(check);
  _validateProductionAuthConsentFallbackPolicy(check);
  _validateProfileSelfWriteHardening(check);
  _validateProductionVehicleCatalogFallbackPolicy(check);
  _validateViewportLimits(check);
  _validateVehicleCatalogRuntimeFallback(check);
  _validateVehicleModelRangeSelection(check);
  _validateCustomVehicleReviewFlow(check);
  _validateUserFacingTextHygiene(check);
  _validateCoreRouteSmokeCoverage(check);
  _validateSplashRestoreRecovery(check);
  _validateKoreanFontRenderingPolicy(check);
  _validateLocationPrivacyInPresentation(check);
  _validateBattleRewardModel(check);
  _validateReviewRequestFlow(check);
  _validateSupportFaqFlow(check);
  _validateDriveHistoryAnalysisFlow(check);
  _validateUserJourneyRecoveryStates(check);
  _validateDrivingModeNoInterruptions(check);
  _validateDriveStartReadinessFlow(check);
  _validateOfflineDriveSyncFlow(check);
  _validateSessionSignOutPrivacy(check);
  _validateAnalyticsSanitization(check);
  _validateStructuredLogging(check);
  _validateProductionDriveFallbackPolicy(check);
  _validateProductionPurchaseFallbackPolicy(check);
  _validateProductionPremiumPlanFallbackPolicy(check);
  _validateProductionAdRewardPolicy(check);
  _validateProductionUserDataFallbackPolicy(check);
  _validateProductionCoreExperienceFallbackPolicy(check);
  _validateProductionOperationalFallbackPolicy(check);
  _validatePrivacyRequestOperations(check);
  _validateRemoteConfigParsing(check);
  _validatePublicRankingPrivacy(check);
  _validateRankingDetailFlow(check);
  _validateRivalRankingFlow(check);
  _validatePublicProfileFlow(check);
  _validateDrivePointRls(check);
  _validateDependencyPolicy(check);
  _validatePlatformPermissionDeclarations(check);
  _validateIosReleaseConfig(check);
  _validateAndroidReleaseSigning(check);
  _validateWebReleaseMetadata(check);
  _validateWebRuntimeSmokeTool(check);
  _validateReleaseEnvironmentPreflightTool(check);
  _validateBrandAssets(check);
  _validateLegalDisclosureArtifacts(check);
  _validateStoreSubmissionPreflightTool(check);
  _validateStorePrivacyDisclosureArtifacts(check);
  _validateStoreListingAssets(check);
  _validateReleaseReadinessArtifacts(check);

  if (failures.isEmpty) {
    stdout.writeln('product invariants valid: $checkCount checks');
    return;
  }

  stderr.writeln('product invariant validation failed:');
  for (final failure in failures) {
    stderr.writeln('- $failure');
  }
  exitCode = 1;
}

void _validateSessionSignOutPrivacy(
  void Function(String scope, bool condition, String message) check,
) {
  final servicesFile = File('lib/shared/services/app_services.dart');
  check(
    servicesFile.path,
    servicesFile.existsSync(),
    'app services file is missing',
  );
  if (servicesFile.existsSync()) {
    final source = servicesFile.readAsStringSync();
    for (final token in [
      'user?.onboardingCompleted',
      'user?.consentCompleted',
      'user?.vehicleSetupCompleted',
      'localConsentCompleted ||',
      'localVehicleSetupCompleted ||',
      'await localState.markConsentCompleted();',
      'await localState.markVehicleSetupCompleted();',
      'Future<void> signOut() async',
      'await localState.clearCachedDriveResultSummary();',
      'OfflineQueueService(localState: localState)',
      '.clear(includeCorruptBackup: true)',
      'await secureStorage.clearSessionHint();',
      'try {\n      await authRepository.signOut();',
      'await _clearUserScopedLocalState();',
      'Error.throwWithStackTrace(',
      'authStackTrace ?? StackTrace.current',
    ]) {
      check(
        servicesFile.path,
        source.contains(token),
        'sign out must clear user scoped local sync/privacy data $token',
      );
    }
  }

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync() &&
        serviceTest.readAsStringSync().contains(
            'AppSessionService signOut clears user scoped local hints') &&
        serviceTest.readAsStringSync().contains(
            'AppSessionService signOut clears local hints even when auth fails') &&
        serviceTest
            .readAsStringSync()
            .contains('_FailingSignOutAuthRepository') &&
        serviceTest
            .readAsStringSync()
            .contains('offline_queue_corrupt_backup') &&
        serviceTest.readAsStringSync().contains(
            'AppSessionService restore hydrates completed profile flags') &&
        serviceTest
            .readAsStringSync()
            .contains('vehicleSetupCompleted: true') &&
        serviceTest.readAsStringSync().contains(
            "expect(await localState.getBool('consent_completed'), isTrue)") &&
        serviceTest.readAsStringSync().contains(
            "expect(await localState.getBool('vehicle_setup_completed'), isTrue)") &&
        serviceTest
            .readAsStringSync()
            .contains('expect(await offlineQueue.pendingItems(), isEmpty)') &&
        serviceTest.readAsStringSync().contains(
            'expect(await offlineQueue.corruptQueueBackup(), isEmpty)') &&
        serviceTest.readAsStringSync().contains(
            'Logout screens invalidate shared user scoped provider caches'),
    'session restore/sign out must have unit coverage for server-completed flags and local privacy cleanup',
  );

  final providersFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providersFile.path,
    providersFile.existsSync(),
    'repository providers file is missing',
  );
  if (providersFile.existsSync()) {
    final source = providersFile.readAsStringSync();
    for (final token in [
      'void invalidateUserScopedSessionProviders(WidgetRef ref)',
      'restoredSessionProvider',
      'appConsentProvider',
      'homeSnapshotProvider',
      'primaryVehicleProvider',
      'vehiclesProvider',
      'profileProvider',
      'badgesProvider',
      'achievementsProvider',
      'couponsProvider',
      'notificationsProvider',
      'supportTicketsProvider',
      'privacyRequestsProvider',
      'myCrewProvider',
      'crewMembersProvider',
    ]) {
      check(
        providersFile.path,
        source.contains(token),
        'logout must invalidate user scoped provider cache $token',
      );
    }
  }

  for (final path in [
    'lib/features/profile/presentation/profile_screen.dart',
    'lib/features/settings/presentation/settings_screen.dart',
  ]) {
    final file = File(path);
    check(path, file.existsSync(), '$path is missing');
    if (!file.existsSync()) {
      continue;
    }
    final source = file.readAsStringSync();
    check(
      path,
      source.contains('invalidateUserScopedSessionProviders(ref)'),
      '$path must use shared user scoped provider invalidation on logout',
    );
  }
}

void _validateVehicleCatalogRuntimeFallback(
  void Function(String scope, bool condition, String message) check,
) {
  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync(),
    'repository file is missing',
  );
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    check(
      repositoryFile.path,
      source.contains('variant-hyundai-avante-2026-gasoline') &&
          source.contains('year-hyundai-001-kr-2026'),
      'runtime fallback catalog must use current 2015+ powertrain IDs',
    );
    for (final stale in [
      'model-avante',
      'year-avante-2024',
      'variant-avante-2024-gasoline',
      'variant-avante-2024-nline',
      'N Line 가솔린',
    ]) {
      check(
        repositoryFile.path,
        !source.contains(stale),
        'runtime fallback catalog must not contain stale vehicle row "$stale"',
      );
    }
  }

  final integrationTest =
      File('test/integration/mock_signup_drive_flow_test.dart');
  check(
    integrationTest.path,
    integrationTest.existsSync(),
    'mock signup integration test is missing',
  );
  if (integrationTest.existsSync()) {
    final source = integrationTest.readAsStringSync();
    check(
      integrationTest.path,
      source.contains('variant-hyundai-avante-2026-gasoline') &&
          !source.contains('variant-avante-2024-gasoline'),
      'mock signup flow must use the current Avante powertrain variant ID',
    );
  }
}

void _validateProductionAuthConsentFallbackPolicy(
  void Function(String scope, bool condition, String message) check,
) {
  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync(),
    'repository file is missing',
  );
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      'class UnavailableAuthRepository',
      'class UnavailableConsentRepository',
      'class SupabaseConsentRepository',
      "return StateError('인증 설정을 완료해야 합니다.')",
      "return StateError('동의 저장소 설정을 완료해야 합니다.')",
      "throw StateError('로그인이 필요합니다.')",
      'final bool allowMockFallback;',
      'class AuthRedirectInProgressException implements Exception',
      'signInWithIdToken(',
      'signInWithOAuth(',
      'Uri.base.origin',
      '_client.auth.signOut()',
      '_accountDeletionRequiresPrivacyRequest',
      "StateError('계정 삭제는 개인정보 설정에서 요청해야 합니다.')",
      'Future<UserProfile> _startSupabaseOAuthRedirect()',
      'if (kIsWeb) {\n'
          '      return _startSupabaseOAuthRedirect();\n'
          '    }\n\n'
          '    await _initializeGoogleSignIn();',
      'if (!kIsWeb) {\n'
          '        await _initializeGoogleSignIn();\n'
          '        await _googleSignIn.signOut();\n'
          '      }',
      'TargetPlatform.android =>\n'
          '        hasServerTokenClient && googleAndroidClientId.isNotEmpty',
      'TargetPlatform.iOS ||\n'
          '      TargetPlatform.macOS =>\n'
          '        hasServerTokenClient && googleIosClientId.isNotEmpty',
      'googleAndroidClientId.isNotEmpty',
      'googleIosClientId.isNotEmpty',
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'production auth/consent fallback policy must keep $token',
      );
    }
    check(
      repositoryFile.path,
      !source.contains(
          'Future<void> deleteAccount() async {\n    await signOut();'),
      'deleteAccount must not silently perform signOut instead of deletion request processing',
    );
    check(
      repositoryFile.path,
      !source.contains('LegacySupabaseAuthRepository'),
      'auth repositories must not keep a legacy Supabase mock fallback class',
    );
  }

  final providerFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providerFile.path,
    providerFile.existsSync(),
    'repository providers file is missing',
  );
  if (providerFile.existsSync()) {
    final source = providerFile.readAsStringSync();
    for (final token in [
      'if (config.canUseMockRepositories)',
      'return MockAuthRepository();',
      'return const UnavailableAuthRepository();',
      'SupabaseConsentRepository(allowMockFallback: config.isDev)',
      'return config.canUseMockRepositories',
      ': const UnavailableConsentRepository()',
    ]) {
      check(
        providerFile.path,
        source.contains(token),
        'production providers must disable auth/consent mock fallback $token',
      );
    }
  }

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync(),
    'service completion tests missing',
  );
  if (serviceTest.existsSync()) {
    final source = serviceTest.readAsStringSync();
    check(
      serviceTest.path,
      source.contains(
        'Production auth and consent repositories never fall back to mock',
      ),
      'production auth/consent fallback policy must have unit coverage',
    );
    check(
      serviceTest.path,
      source.contains(
          'Supabase Google web auth bypasses Google SDK initialization'),
      'web Google OAuth redirect must have regression coverage',
    );
    check(
      serviceTest.path,
      source.contains(
        'AppSessionService rememberLogin ignores session hint write failure',
      ),
      'login session hint write failure must not block completed auth',
    );
  }

  final repositoryTest = File('test/unit/mock_repositories_test.dart');
  check(
    repositoryTest.path,
    repositoryTest.existsSync() &&
        repositoryTest
            .readAsStringSync()
            .contains('deleteAccount requires privacy request queue') &&
        repositoryTest.readAsStringSync().contains(
              '계정 삭제는 개인정보 설정에서 요청해야 합니다.',
            ),
    'direct account deletion API must have unit coverage for privacy request queue handoff',
  );

  final loginScreen = File('lib/features/auth/presentation/login_screen.dart');
  check(
    loginScreen.path,
    loginScreen.existsSync(),
    'login screen is missing',
  );
  if (loginScreen.existsSync()) {
    final source = loginScreen.readAsStringSync();
    for (final token in [
      'String _nextRouteAfterLogin(UserProfile user)',
      '!user.consentCompleted',
      '!user.vehicleSetupCompleted',
      'ref.invalidate(restoredSessionProvider)',
      '_trackAuthEvent',
      '_identifyLoginUser',
    ]) {
      check(
        loginScreen.path,
        source.contains(token),
        'Google login must refresh session and route by completed profile state $token',
      );
    }
  }

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(
    widgetTest.path,
    widgetTest.existsSync() &&
        widgetTest.readAsStringSync().contains(
              'LoginScreen refreshes stale signed-out session after Google login',
            ) &&
        widgetTest
            .readAsStringSync()
            .contains('LoginScreen routes consented profile to setup') &&
        widgetTest
            .readAsStringSync()
            .contains('LoginScreen routes completed profile to home') &&
        widgetTest.readAsStringSync().contains('_StagedGoogleAuthRepository'),
    'Google login routing and stale session refresh must have widget coverage',
  );

  final completionAudit = File('docs/20_product_completion_audit.md');
  check(
    completionAudit.path,
    completionAudit.existsSync(),
    'completion audit document is missing',
  );
  if (completionAudit.existsSync()) {
    final source = completionAudit.readAsStringSync();
    check(
      completionAudit.path,
      source.contains('Production Auth Consent Fallback') &&
          source.contains('mock 로그인/동의 데이터를 표시하거나 저장하지 않는다'),
      'completion audit must document production auth/consent fallback policy',
    );
  }

  final runbook = File('docs/21_production_runbook.md');
  check(runbook.path, runbook.existsSync(), 'production runbook is missing');
  if (runbook.existsSync()) {
    final source = runbook.readAsStringSync();
    check(
      runbook.path,
      source.contains('Production Auth Consent Fallback') &&
          source.contains('mock 로그인/동의 데이터를 표시하거나 저장하지 않는다'),
      'production runbook must document auth/consent fallback policy',
    );
  }
}

void _validateProfileSelfWriteHardening(
  void Function(String scope, bool condition, String message) check,
) {
  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync(),
    'repository file is missing',
  );
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    final ensureProfileSection = _sectionBetween(
      source,
      'class SupabaseGoogleAuthRepository implements AuthRepository',
      'class SupabaseAuthRepository extends SupabaseGoogleAuthRepository',
    );
    for (final token in [
      'final insertProfile = <String, dynamic>',
      '.insert(insertProfile)',
      'final updateProfile = <String, dynamic>',
      '.update(updateProfile)',
      "'auth_provider': 'google'",
      "'updated_at': updatedAt",
      '_nicknameFromGoogleMetadata(metadata, email)',
      'final preservedNickname = existingProfile.nickname.trim().isEmpty',
      '? nickname',
      ': existingProfile.nickname',
      'final preservedEmail =',
      '? existingProfile.email',
      ': email.trim()',
      'final preservedAvatarUrl = existingProfile.avatarUrl.trim().isEmpty',
      '? avatarUrl.trim()',
      ': existingProfile.avatarUrl',
    ]) {
      check(
        repositoryFile.path,
        ensureProfileSection.contains(token),
        'Google auth profile repair must use safe profile write token $token',
      );
    }
    final updateProfileSection = _sectionBetween(
      ensureProfileSection,
      'final updateProfile = <String, dynamic>',
      'final updated = await _client',
    );
    for (final token in [
      "'email': preservedEmail",
      "'nickname': preservedNickname",
      "updateProfile['avatar_url'] = preservedAvatarUrl",
    ]) {
      check(
        repositoryFile.path,
        updateProfileSection.contains(token),
        'Google auth existing profile repair must preserve user-owned field $token',
      );
    }
    check(
      repositoryFile.path,
      !ensureProfileSection.contains('.upsert(') &&
          !ensureProfileSection.contains('.toJson()'),
      'Google auth profile repair must not upsert the full UserProfile JSON',
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
        repositoryFile.path,
        !ensureProfileSection.contains("'$sensitiveColumn'"),
        'Google auth profile repair must not write $sensitiveColumn from client',
      );
    }
  }

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
    'revoke insert on public.profiles from anon, authenticated',
    'revoke update on public.profiles from anon, authenticated',
    'grant insert (',
    'grant update (',
    'coalesce(is_admin, false) = false',
    'coalesce(is_premium, false) = false',
    'coalesce(total_score, 0) = 0',
    'coalesce(season_score, 0) = 0',
    'coalesce(current_streak, 0) = 0',
    'coalesce(best_streak, 0) = 0',
  ]) {
    check(
      migration.path,
      source.contains(token),
      'profile self-write hardening migration must keep $token',
    );
  }

  final insertColumns = _profileGrantColumns(source, 'insert');
  final updateColumns = _profileGrantColumns(source, 'update');
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
      'profile insert grant must not include $sensitiveColumn',
    );
    check(
      migration.path,
      !updateColumns.contains(sensitiveColumn),
      'profile update grant must not include $sensitiveColumn',
    );
  }
}

void _validateProductionVehicleCatalogFallbackPolicy(
  void Function(String scope, bool condition, String message) check,
) {
  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync(),
    'repository file is missing',
  );
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      'class SupabaseVehicleCatalogRepository',
      'class SupabaseLeagueRepository',
      "from('vehicle_manufacturer_catalog_view')",
      'final bool allowMockFallback;',
      'if (!allowMockFallback) {\n        rethrow;',
      "throw StateError('로그인이 필요합니다.')",
      'allowMockFallback: allowMockFallback',
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'production vehicle catalog fallback policy must keep $token',
      );
    }
  }

  final providerFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providerFile.path,
    providerFile.existsSync(),
    'repository providers file is missing',
  );
  if (providerFile.existsSync()) {
    final source = providerFile.readAsStringSync();
    for (final token in [
      'SupabaseVehicleCatalogRepository(',
      'allowMockFallback: !config.isProduction',
      'SupabaseLeagueRepository(allowMockFallback: !config.isProduction)',
    ]) {
      check(
        providerFile.path,
        source.contains(token),
        'production providers must disable vehicle catalog mock fallback $token',
      );
    }
  }

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(serviceTest.path, serviceTest.existsSync(), 'service tests missing');
  if (serviceTest.existsSync()) {
    final source = serviceTest.readAsStringSync();
    check(
      serviceTest.path,
      source.contains(
        'Production vehicle catalog repository never falls back to mock asset',
      ),
      'production vehicle catalog fallback policy must have unit coverage',
    );
  }

  final completionAudit = File('docs/20_product_completion_audit.md');
  check(
    completionAudit.path,
    completionAudit.existsSync(),
    'completion audit document is missing',
  );
  if (completionAudit.existsSync()) {
    final source = completionAudit.readAsStringSync();
    check(
      completionAudit.path,
      source.contains('Production Vehicle Catalog Fallback') &&
          source.contains('mock 차량 카탈로그 seed로 대체하지 않는다') &&
          source.contains('vehicle_manufacturer_catalog_view'),
      'completion audit must document production vehicle catalog fallback',
    );
  }

  final runbook = File('docs/21_production_runbook.md');
  check(runbook.path, runbook.existsSync(), 'production runbook is missing');
  if (runbook.existsSync()) {
    final source = runbook.readAsStringSync();
    check(
      runbook.path,
      source.contains('Production Vehicle Catalog Fallback') &&
          source.contains('vehicle_manufacturers') &&
          source.contains('vehicle_manufacturer_catalog_view') &&
          source.contains('vehicle_catalog_view'),
      'production runbook must document vehicle catalog fallback recovery',
    );
  }

  final modelFile = File('lib/shared/models/fuel_arena_models.dart');
  check(modelFile.path, modelFile.existsSync(), 'models file is missing');
  if (modelFile.existsSync()) {
    final source = modelFile.readAsStringSync();
    for (final token in [
      'final int modelCount;',
      'final int minYear;',
      'final int maxYear;',
      "json['model_count']",
      "json['min_year']",
      "json['max_year']",
    ]) {
      check(
        modelFile.path,
        source.contains(token),
        'vehicle manufacturer model must keep catalog stat field $token',
      );
    }
  }
}

void _validateVehicleModelRangeSelection(
  void Function(String scope, bool condition, String message) check,
) {
  final modelFile = File('lib/shared/models/fuel_arena_models.dart');
  check(modelFile.path, modelFile.existsSync(), 'models file is missing');
  if (modelFile.existsSync()) {
    final source = modelFile.readAsStringSync();
    check(
      modelFile.path,
      source.contains('selectedModelRangeLabel') &&
          source.contains('selectedModelRangeDisplay'),
      'vehicle selection state must preserve the selected model range label',
    );
  }

  final screenFile =
      File('lib/features/vehicle/presentation/vehicle_setup_screen.dart');
  check(
    screenFile.path,
    screenFile.existsSync(),
    'vehicle setup screen is missing',
  );
  if (screenFile.existsSync()) {
    final source = screenFile.readAsStringSync();
    for (final token in [
      'VehicleModelRangeChoice',
      'buildVehicleModelRanges',
      'VehicleModelRangePickerField',
      'showVehicleModelRangePicker',
      'Future<void> _refreshVehicleSetupState',
      'invalidate(restoredSessionProvider)',
      '차량 설정을 저장하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.',
      '차량 검토 요청을 접수하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.',
      'representativeYear',
      'VehicleModelBodyTypeFilter',
      '_modelBodyTypes',
      "'3/4 기준 연식 선택'",
      '기준 연식 선택',
      '개 연식',
      'vehicle_model_range_selected',
    ]) {
      check(
        screenFile.path,
        source.contains(token),
        'vehicle setup must use model range picker token $token',
      );
    }
    check(
      screenFile.path,
      !source.contains('VehicleYearPickerField') &&
          !source.contains('showVehicleYearPicker') &&
          !source.contains('세대'),
      'vehicle setup must not expose old year picker or generation labels',
    );
  }

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(widgetTest.path, widgetTest.existsSync(), 'flow widget tests missing');
  if (widgetTest.existsSync()) {
    final source = widgetTest.readAsStringSync();
    check(
      widgetTest.path,
      source.contains('year picker selects model year') &&
          source.contains("expect(find.text('아반떼 2026년식')") &&
          source.contains("expect(selected?.label, '2026년식')") &&
          source.contains('representativeYear.year') &&
          source.contains('filters models by body type') &&
          source.contains('separates K3 GT by engine and transmission') &&
          source.contains("expect(find.textContaining('세대'), findsNothing)") &&
          source.contains("expect(find.text('1.6T 가솔린 DCT'), findsOneWidget)"),
      'model year picker must have widget coverage',
    );
    check(
      widgetTest.path,
      source.contains('VehicleSetupScreen shows retryable save failure') &&
          source.contains(
            'CustomVehicleRequestScreen shows retryable save failure',
          ) &&
          source.contains('_FailingUserVehicleRepository') &&
          source.contains('_FailingVehicleCatalogRepository'),
      'vehicle setup save failures must have widget recovery coverage',
    );
  }
}

void _validateCustomVehicleReviewFlow(
  void Function(String scope, bool condition, String message) check,
) {
  final modelFile = File('lib/shared/models/fuel_arena_models.dart');
  check(modelFile.path, modelFile.existsSync(), 'models file is missing');
  if (modelFile.existsSync()) {
    final source = modelFile.readAsStringSync();
    for (final token in [
      'class CustomVehicleReviewRequest',
      'userVehicleId',
      'copyWith({',
    ]) {
      check(
        modelFile.path,
        source.contains(token),
        'custom vehicle review model must keep $token',
      );
    }
  }

  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(repositoryFile.path, repositoryFile.existsSync(), 'repository missing');
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      'listCustomVehicleReviewRequests',
      'reviewCustomVehicleRequest',
      "'review_custom_vehicle'",
      "'user_vehicle_id': row['id']",
      '_mockCustomVehicleReviewRequests',
      '_mockNotifications',
      "'vehicle_review'",
      '직접 입력 차량 검수가 완료됐어요',
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'custom vehicle review repository must keep $token',
      );
    }
  }

  final providerFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providerFile.path,
    providerFile.existsSync() &&
        providerFile
            .readAsStringSync()
            .contains('customVehicleReviewRequestsProvider'),
    'custom vehicle review queue must have a provider',
  );

  final adminScreen =
      File('lib/features/admin/presentation/admin_vehicle_catalog_screen.dart');
  check(adminScreen.path, adminScreen.existsSync(),
      'admin vehicle screen missing');
  if (adminScreen.existsSync()) {
    final source = adminScreen.readAsStringSync();
    for (final token in [
      'customVehicleReviewRequestsProvider',
      'reviewCustomVehicleRequest',
      '직접 입력 차량을 공식 리그에 반영했어요.',
      '연결된 사용자 차량 ID가 없어 검수를 처리할 수 없어요.',
      '직접 입력 승인',
    ]) {
      check(
        adminScreen.path,
        source.contains(token),
        'admin custom vehicle review UI must keep $token',
      );
    }
  }

  final migration =
      File('supabase/migrations/202606060004_vehicle_catalog_completion.sql');
  final migrationSource =
      migration.existsSync() ? migration.readAsStringSync().toLowerCase() : '';
  check(
    migration.path,
    migration.existsSync() &&
        migrationSource.contains('user_vehicle_id uuid') &&
        migrationSource.contains('custom_vehicle_requests_user_vehicle_idx') &&
        migrationSource.contains('custom_vehicle_requests_self_insert') &&
        migrationSource.contains('user_vehicle_id is not null') &&
        migrationSource.contains('from public.user_vehicles uv') &&
        migrationSource.contains('uv.user_id = auth.uid()'),
    'custom vehicle requests migration must link to owned user_vehicles',
  );

  final unitTest = File('test/unit/mock_repositories_test.dart');
  check(
    unitTest.path,
    unitTest.existsSync() &&
        unitTest.readAsStringSync().contains(
              'Custom catalog request stays pending review',
            ) &&
        unitTest.readAsStringSync().contains('reviewCustomVehicleRequest') &&
        unitTest.readAsStringSync().contains('vehicle_review'),
    'custom vehicle review queue and notification must have unit coverage',
  );

  final edgeFunction =
      File('supabase/functions/review_custom_vehicle/index.ts');
  check(
    edgeFunction.path,
    edgeFunction.existsSync() &&
        edgeFunction.readAsStringSync().contains('.from("notifications")') &&
        edgeFunction.readAsStringSync().contains('request_vehicle_mismatch') &&
        edgeFunction
            .readAsStringSync()
            .contains('request_vehicle_owner_mismatch') &&
        edgeFunction
            .readAsStringSync()
            .contains('notification_type: "vehicle_review"') &&
        edgeFunction.readAsStringSync().contains('notificationQueued'),
    'custom vehicle review edge function must notify users',
  );

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(
    widgetTest.path,
    widgetTest.existsSync() &&
        widgetTest.readAsStringSync().contains(
              'AdminVehicleCatalogScreen renders custom vehicle review queue',
            ),
    'admin custom vehicle review queue must have widget coverage',
  );
}

void _validateRuntimeConfigSafety(
  void Function(String scope, bool condition, String message) check,
) {
  final configFile = File('lib/app/app_config.dart');
  check(configFile.path, configFile.existsSync(), 'app config file is missing');
  if (configFile.existsSync()) {
    final source = configFile.readAsStringSync();
    check(
      configFile.path,
      source.contains('bool get hasValidSupabaseUrl') &&
          source.contains("uri.scheme != 'https'"),
      'AppConfig must validate production Supabase URLs as https',
    );
    check(
      configFile.path,
      source.contains(
                  'bool get requiresSupabase => isStaging || isProduction') &&
              source.contains(
                'bool get canUseMockRepositories =>\n      (isDev || (isStaging && stagingAllowMockAuth)) && !hasSupabase',
              ) ||
          source.contains(
            'bool get canUseMockRepositories => (isDev || (isStaging && stagingAllowMockAuth)) && !hasSupabase',
          ),
      'AppConfig must restrict mock repositories to dev without Supabase',
    );
    check(
      configFile.path,
      source.contains('uri.host.isEmpty') &&
          source.contains('uri.scheme.isEmpty'),
      'AppConfig must reject malformed Supabase URLs',
    );
    for (final token in [
      'hasValidGoogleOAuthClientIds',
      '_looksLikeGoogleOAuthClientId',
      '.apps.googleusercontent.com',
      'expectedGoogleReversedIosClientId',
      'hasMatchingGoogleIosReversedClientId',
      'hasProductionGoogleOAuthConfig',
    ]) {
      check(
        configFile.path,
        source.contains(token),
        'AppConfig must validate production Google OAuth configuration token $token',
      );
    }
  }

  final runtimeConfigFile = File('lib/supabase/supabase_config.dart');
  check(
    runtimeConfigFile.path,
    runtimeConfigFile.existsSync(),
    'Supabase runtime config file is missing',
  );
  if (runtimeConfigFile.existsSync()) {
    final source = runtimeConfigFile.readAsStringSync();
    for (final token in [
      'bool get hasValidUrl',
      'bool get canCreateClient',
      "isProduction && uri.scheme != 'https'",
    ]) {
      check(
        runtimeConfigFile.path,
        source.contains(token),
        'SupabaseRuntimeConfig must enforce safe client URL creation',
      );
    }
  }

  final clientProvider = File('lib/supabase/supabase_client_provider.dart');
  check(
    clientProvider.path,
    clientProvider.existsSync(),
    'Supabase client provider file is missing',
  );
  if (clientProvider.existsSync()) {
    final source = clientProvider.readAsStringSync();
    check(
      clientProvider.path,
      source.contains('!config.canCreateClient'),
      'Supabase client provider must not create clients for invalid runtime config',
    );
  }

  final bootstrapFile = File('lib/app/bootstrap.dart');
  check(
    bootstrapFile.path,
    bootstrapFile.existsSync(),
    'bootstrap file is missing',
  );
  if (bootstrapFile.existsSync()) {
    final source = bootstrapFile.readAsStringSync();
    for (final token in [
      'config.requiresSupabase && !config.hasSupabase',
      'staging/production',
      '!config.hasValidSupabaseUrl',
      'config.isProduction && !config.hasProductionGoogleOAuthConfig',
      'authOptions: const FlutterAuthClientOptions(',
      'authFlowType: AuthFlowType.pkce',
      'detectSessionInUri: true',
      'SUPABASE_URL 형식이 올바르지 않습니다',
      'try {',
      'Supabase 초기화에 실패했습니다',
    ]) {
      check(
        bootstrapFile.path,
        source.contains(token),
        'bootstrap must surface Supabase configuration failures safely',
      );
    }
  }

  final appFile = File('lib/app/fuel_arena_app.dart');
  check(appFile.path, appFile.existsSync(), 'FuelArenaApp file is missing');
  if (appFile.existsSync()) {
    final source = appFile.readAsStringSync();
    check(
      appFile.path,
      source.contains('String _configurationRecoveryHint') &&
          source.contains('bootstrap.config.isDev') &&
          source.contains('운영/스테이징 빌드') &&
          source.contains('Supabase/Google 콘솔 설정'),
      'configuration error screen must show environment-specific recovery guidance',
    );
  }

  final configTest = File('test/unit/mock_repositories_test.dart');
  check(configTest.path, configTest.existsSync(), 'config unit tests missing');
  if (configTest.existsSync()) {
    final source = configTest.readAsStringSync();
    check(
      configTest.path,
      source.contains('AppConfig validates Supabase URL by environment') &&
          source.contains(
            'AppConfig permits mock repositories only in dev without Supabase',
          ) &&
          source.contains(
            'Dev auth provider keeps mock login when only Google values exist',
          ) &&
          source.contains(
            'Production config requires complete Google OAuth client set',
          ) &&
          source.contains(
            'Supabase Google auth requires token and platform client on native',
          ),
      'Supabase URL and mock repository environment validation must have unit coverage',
    );
  }

  final appWidgetTest = File('test/widget_test.dart');
  check(appWidgetTest.path, appWidgetTest.existsSync(),
      'app widget tests missing');
  if (appWidgetTest.existsSync()) {
    final source = appWidgetTest.readAsStringSync();
    check(
      appWidgetTest.path,
      source.contains('운영/스테이징 빌드') &&
          source.contains('로컬 확인 환경') &&
          source.contains('findsNothing'),
      'production configuration error screen must have widget coverage for non-dev guidance',
    );
    check(
      appWidgetTest.path,
      source.contains(
            'Fuel Arena app shows production Google OAuth configuration error',
          ) &&
          source.contains('Web/Android/iOS/Server Google OAuth') &&
          source.contains('iOS reversed client ID') &&
          source.contains('Supabase/Google 콘솔 설정'),
      'production Google OAuth configuration error screen must have widget coverage',
    );
  }
}

void _validateClientSecrets(
  void Function(String scope, bool condition, String message) check,
) {
  const clientRoots = ['lib', 'android', 'ios', 'assets'];
  for (final file in _dartAndTextFiles(clientRoots)) {
    final source = file.readAsStringSync();
    check(
      file.path,
      !source.contains('SUPABASE_SERVICE_ROLE_KEY'),
      'Flutter client bundle must not contain the Supabase service role env key',
    );
  }

  final pubspec = File('pubspec.yaml');
  check(pubspec.path, pubspec.existsSync(), 'pubspec.yaml is missing');
  if (pubspec.existsSync()) {
    final source = pubspec.readAsStringSync();
    check(
      pubspec.path,
      !RegExp(r'^\s*-\s*\.env\s*$', multiLine: true).hasMatch(source),
      'Flutter assets must not bundle .env files',
    );
  }

  final envExample = File('.env.example');
  check(envExample.path, envExample.existsSync(), '.env.example is missing');
  if (envExample.existsSync()) {
    final lines = envExample.readAsLinesSync();
    for (var i = 0; i < lines.length; i += 1) {
      final line = lines[i].trimLeft();
      check(
        '${envExample.path}:${i + 1}',
        !line.startsWith('SUPABASE_SERVICE_ROLE_KEY='),
        '.env.example must not expose a client-side service role key slot',
      );
    }
  }
}

void _validateViewportLimits(
  void Function(String scope, bool condition, String message) check,
) {
  final layoutFile = File('lib/design_system/app_layout.dart');
  check(
    layoutFile.path,
    layoutFile.existsSync(),
    'AppLayout tokens are required for mobile scale limits',
  );
  if (layoutFile.existsSync()) {
    final source = layoutFile.readAsStringSync();
    for (final token in [
      'class AppLayout',
      'static const double mobileDesignWidth = 390',
      'static const double mobileMinWidth = 320',
      'static const double mobileMaxWidth = 430',
      'static const double adminMinWidth = 1024',
      'static const double bottomNavHeight = 72',
      'class AppIconSize',
      'static const double xs = 16',
      'static const double sm = 20',
      'static const double md = 24',
      'static const double lg = 32',
      'static const double xl = 40',
      'static const double hero = 56',
      'class AppCardSize',
      'static const double manufacturerHeight = 104',
      'static const double vehicleModelHeight = 88',
      'static const double vehicleVariantHeight = 112',
      'class AppButtonHeight',
      'static const double primary = 52',
    ]) {
      check(
        layoutFile.path,
        source.contains(token),
        'mobile design token must keep $token',
      );
    }
  }

  final scaffoldFile = File('lib/shared/widgets/app_scaffold.dart');
  check(
    scaffoldFile.path,
    scaffoldFile.existsSync(),
    'AppScaffold is required to centralize viewport limits',
  );
  if (scaffoldFile.existsSync()) {
    final source = scaffoldFile.readAsStringSync();
    for (final token in [
      'static const double mobileDesignWidth = AppLayout.mobileDesignWidth',
      'static const double mobileMinWidth = AppLayout.mobileMinWidth',
      'static const double mobileMaxWidth = AppLayout.mobileMaxWidth',
      'static const double adminMinWidth = AppLayout.adminMinWidth',
    ]) {
      check(
        scaffoldFile.path,
        source.contains(token),
        'AppScaffold must source viewport limit from $token',
      );
    }
    check(
      scaffoldFile.path,
      source.contains(
          'return MobileViewportShell(maxWidth: maxWidth!, child: child);'),
      'non-admin app surfaces must route through MobileViewportShell',
    );
    check(
      scaffoldFile.path,
      source.contains('return AdminViewportShell(child: child);'),
      'maxWidth: null surfaces must route through AdminViewportShell',
    );
    check(
      scaffoldFile.path,
      !source.contains('SafeArea('),
      'AppScaffold body must not wrap route content in SafeArea; hash web routes can render a blank body',
    );
  }

  final vehicleSetup =
      File('lib/features/vehicle/presentation/vehicle_setup_screen.dart');
  check(
    vehicleSetup.path,
    vehicleSetup.existsSync(),
    'vehicle setup screen is required for compact manufacturer grid',
  );
  if (vehicleSetup.existsSync()) {
    final source = vehicleSetup.readAsStringSync();
    for (final token in [
      'class CompactManufacturerCard',
      'class ManufacturerLogoBadge',
      'class VehicleCatalogStatsChip',
      'class VehicleManufacturerCountryFilter',
      "value: 'KR'",
      "value: 'IMPORT'",
      'mainAxisExtent: AppCardSize.manufacturerHeight',
      'width: AppIconSize.xl',
      'height: AppIconSize.xl',
    ]) {
      check(
        vehicleSetup.path,
        source.contains(token),
        'vehicle manufacturer UI must keep compact tokenized surface $token',
      );
    }
    check(
      vehicleSetup.path,
      !source.contains('childAspectRatio: 1.18'),
      'manufacturer grid must not rely on viewport-ratio card sizing',
    );
  }

  final providerFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providerFile.path,
    providerFile.existsSync() &&
        providerFile
            .readAsStringSync()
            .contains('class VehicleManufacturerQuery') &&
        providerFile.readAsStringSync().contains('country: query.country'),
    'vehicle manufacturer provider must carry keyword and country filter',
  );

  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync() &&
        repositoryFile
            .readAsStringSync()
            .contains('_manufacturerCountryMatches(item, country)') &&
        repositoryFile.readAsStringSync().contains("normalized == 'IMPORT'"),
    'vehicle manufacturer repositories must support domestic/import filtering',
  );

  for (final path in [
    'lib/features/home/presentation/home_screen.dart',
    'lib/features/battle/presentation/battle_screen.dart',
    'lib/features/ranking/presentation/ranking_screen.dart',
    'lib/features/season/presentation/season_screen.dart',
    'lib/features/profile/presentation/profile_screen.dart',
  ]) {
    final file = File(path);
    check(path, file.existsSync(), 'main tab screen is missing');
    if (!file.existsSync()) continue;
    final source = file.readAsStringSync();
    check(
      path,
      !source.contains('SafeArea('),
      'main tab screens must not add a nested SafeArea that hides hash-route web content',
    );
  }

  final dartFiles = _dartAndTextFiles(['lib'])
      .where((file) => file.path.endsWith('.dart'))
      .toList();
  final numericMaxWidth = RegExp(r'maxWidth\s*:\s*(\d+(?:\.\d+)?)');
  final directScaffold = RegExp(r'(^|[^A-Za-z0-9_])Scaffold\s*\(');

  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    final normalizedPath = file.path.replaceAll('\\', '/');
    for (var i = 0; i < lines.length; i += 1) {
      final line = lines[i];
      final lineNumber = i + 1;
      final isAdminSurface = normalizedPath.contains('/features/admin/') ||
          _isAdminDashboardLine(normalizedPath, lines, i);
      if (directScaffold.hasMatch(line)) {
        check(
          '$normalizedPath:$lineNumber',
          normalizedPath.endsWith('/shared/widgets/app_scaffold.dart'),
          'screens must use AppScaffold so mobile viewport limits are enforced',
        );
      }
      if (line.contains('maxWidth: null')) {
        check(
          '$normalizedPath:$lineNumber',
          isAdminSurface,
          'maxWidth: null is only allowed for admin dashboard surfaces',
        );
      }
      for (final match in numericMaxWidth.allMatches(line)) {
        final width = double.tryParse(match.group(1) ?? '') ?? 0;
        if (width <= AppViewportPolicy.mobileMaxWidth) continue;
        check(
          '$normalizedPath:$lineNumber',
          isAdminSurface,
          'non-admin maxWidth must not exceed ${AppViewportPolicy.mobileMaxWidth}px',
        );
      }
    }
  }
}

class AppViewportPolicy {
  static const double mobileMaxWidth = 430;
}

void _validateUserFacingTextHygiene(
  void Function(String scope, bool condition, String message) check,
) {
  final blockedTerms = [
    'TODO',
    'FIXME',
    'Placeholder',
    'Coming soon',
    '\uC900\uBE44 \uC911',
    '\uC784\uC2DC',
    '\uC0D8\uD50C \uD654\uBA74',
    '\uBE48 \uD654\uBA74',
    'test only',
    'lorem ipsum',
    'pendingReview',
    'error.toString()',
    'exception.toString()',
    "replaceFirst('Bad state:",
    '개발 모드',
    '개발용',
    '개발 저장소',
    'local fallback',
    "label: 'Premium'",
    "title: 'Premium'",
    "title: 'FAQ'",
    'FAQ 보기',
    'Safety Mode',
    "label: 'Admin'",
    "title: 'ADMIN'",
    "subtitle: 'Operations Dashboard'",
    "subtitle: 'Admin Catalog'",
  ];
  final files = _dartAndTextFiles([
    'lib/features',
    'lib/shared/widgets',
  ]).where((file) {
    final normalizedPath = file.path.replaceAll('\\', '/');
    return normalizedPath.endsWith('.dart') &&
        (normalizedPath.contains('/presentation/') ||
            normalizedPath.contains('/shared/widgets/'));
  });

  var violationCount = 0;
  for (final file in files) {
    final normalizedPath = file.path.replaceAll('\\', '/');
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i += 1) {
      final lowerLine = lines[i].toLowerCase();
      for (final term in blockedTerms) {
        final contains = term == term.toLowerCase()
            ? lowerLine.contains(term)
            : lines[i].contains(term);
        if (!contains) continue;
        if (term == '\uC900\uBE44 \uC911' &&
            (lines[i].contains('공식 효율 정보 준비 중') ||
                lines[i].contains('정보 준비 중'))) {
          continue;
        }
        violationCount += 1;
        check(
          '$normalizedPath:${i + 1}',
          false,
          'user-facing app code must not contain placeholder/dev term "$term"',
        );
      }
    }
  }

  final encodingFiles = _dartAndTextFiles(['lib']).where(
    (file) => file.path.replaceAll('\\', '/').endsWith('.dart'),
  );
  final cjkIdeographPattern = RegExp(r'[\u4E00-\u9FFF\uF900-\uFAFF]');
  for (final file in encodingFiles) {
    final normalizedPath = file.path.replaceAll('\\', '/');
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i += 1) {
      var matchedKnownMojibakeToken = false;
      for (final term in _mojibakeTokens) {
        if (!lines[i].contains(term)) continue;
        matchedKnownMojibakeToken = true;
        violationCount += 1;
        check(
          '$normalizedPath:${i + 1}',
          false,
          'app source must not contain mojibake text',
        );
      }
      if (!matchedKnownMojibakeToken &&
          cjkIdeographPattern.hasMatch(lines[i])) {
        violationCount += 1;
        check(
          '$normalizedPath:${i + 1}',
          false,
          'app source must not contain CJK ideograph mojibake text',
        );
      }
    }
  }

  if (violationCount == 0) {
    check(
      'lib/app source',
      true,
      'user-facing presentation/widgets contain no placeholder/dev terms and lib contains no mojibake/CJK ideograph text',
    );
  }
}

void _validateCoreRouteSmokeCoverage(
  void Function(String scope, bool condition, String message) check,
) {
  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(
    widgetTest.path,
    widgetTest.existsSync(),
    'flow screen widget tests are missing',
  );
  if (!widgetTest.existsSync()) {
    return;
  }

  final source = widgetTest.readAsStringSync();
  for (final token in [
    'Core user routes render body content through app router',
    'createAppRouter(initialLocation: route.location)',
    'appConfigProvider.overrideWithValue(AppConfig.devMock())',
    'find.textContaining(route.expectedText, findRichText: true)',
    "_RouteSmokeCase('/home', '주행 시작하기')",
    "_RouteSmokeCase('/home?tab=battle', '새 배틀 만들기')",
    "_RouteSmokeCase('/home?tab=ranking', '내 차량은')",
    "_RouteSmokeCase('/home?tab=season', '일일 미션')",
    "_RouteSmokeCase('/home?tab=profile', '대표 차량')",
    "_RouteSmokeCase('/setup/vehicle', '제조사 검색')",
    "_RouteSmokeCase('/settings/vehicles', '차량 추가')",
    "_RouteSmokeCase('/legal/privacy', '필요한 데이터만 수집하고')",
    "_RouteSmokeCase('/legal/location', '위치는 주행 검증에만')",
    "_RouteSmokeCase('/legal/account-deletion', '삭제 요청은 운영 큐에서')",
    "_RouteSmokeCase('/notifications', '전체 읽음 처리')",
    "_RouteSmokeCase('/support', '문의 접수')",
  ]) {
    check(
      widgetTest.path,
      source.contains(token),
      'core route smoke coverage must keep $token',
    );
  }

  final routerFile = File('lib/app/router.dart');
  final authRequiredRoute = File('lib/app/auth_required_route.dart');
  final flowScreensFile =
      File('lib/features/common/presentation/flow_screens.dart');
  check(
    routerFile.path,
    routerFile.existsSync() &&
        routerFile.readAsStringSync().contains('GoRouter createAppRouter'),
    'app router must expose a fresh router factory for route smoke tests',
  );
  check(
    authRequiredRoute.path,
    authRequiredRoute.existsSync() &&
        authRequiredRoute.readAsStringSync().contains(
              'class AuthRequiredRoute extends ConsumerWidget',
            ) &&
        authRequiredRoute.readAsStringSync().contains('requireConsent') &&
        authRequiredRoute
            .readAsStringSync()
            .contains('class _ConsentRequiredView extends StatelessWidget'),
    'protected route gate widget must include login and consent gates',
  );
  if (routerFile.existsSync()) {
    final routerSource = routerFile.readAsStringSync();
    for (final token in [
      "import 'auth_required_route.dart';",
      "path: '/home'",
      'AuthRequiredRoute(',
      'requireConsent: false',
      'AdminRequiredRoute(',
      "path: '/drive/start'",
      "path: '/settings'",
      "path: '/admin'",
    ]) {
      check(
        routerFile.path,
        routerSource.contains(token),
        'protected route coverage must keep $token',
      );
    }
  }
  check(
    widgetTest.path,
    source.contains('Protected app routes require restored login session') &&
        source.contains('_signedOutSessionState()') &&
        source.contains("createAppRouter(initialLocation: '/drive/start')"),
    'protected route gate must have widget coverage',
  );
  check(
    widgetTest.path,
    source.contains('Private app routes require completed consent') &&
        source.contains('_noConsentSessionState()') &&
        source.contains("createAppRouter(initialLocation: '/home')") &&
        source.contains(
            "expect(router.routeInformationProvider.value.uri.path, '/consent')"),
    'protected route gate must have consent completion widget coverage',
  );
  check(
    widgetTest.path,
    source.contains(
          'Consent completion refreshes restored session before setup route',
        ) &&
        source.contains('Consent screen shows retryable save failure') &&
        source.contains('_FailingConsentRepository'),
    'consent completion must have cache refresh and failure widget coverage',
  );
  check(
    widgetTest.path,
    source.contains('Admin app routes require admin session') &&
        source.contains('_nonAdminSessionState()') &&
        source.contains("createAppRouter(initialLocation: '/admin')"),
    'admin route gate must have widget coverage',
  );
  check(
    authRequiredRoute.path,
    authRequiredRoute.readAsStringSync().contains(
              'class AdminRequiredRoute extends ConsumerWidget',
            ) &&
        authRequiredRoute.readAsStringSync().contains('user.isAdmin'),
    'admin route gate must check UserProfile.isAdmin before rendering admin UI',
  );
  check(
    flowScreensFile.path,
    flowScreensFile.existsSync() &&
        flowScreensFile
            .readAsStringSync()
            .contains('invalidate(restoredSessionProvider)') &&
        flowScreensFile.readAsStringSync().contains(
              '동의 저장을 완료하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.',
            ),
    'consent completion must refresh restored session and expose save failure recovery',
  );
}

void _validateSplashRestoreRecovery(
  void Function(String scope, bool condition, String message) check,
) {
  final splashFile =
      File('lib/features/splash/presentation/splash_screen.dart');
  check(
    splashFile.path,
    splashFile.existsSync(),
    'splash screen file is missing',
  );
  if (splashFile.existsSync()) {
    final source = splashFile.readAsStringSync();
    for (final token in [
      'Future<void> _restoreAndRoute() async',
      'try {',
      '} catch (error) {',
      'setState(() => _restoreError = error)',
      'void _retryRestore()',
      'ErrorStateView(',
      '앱 시작 상태를 확인하지 못했어요.',
    ]) {
      check(
        splashFile.path,
        source.contains(token),
        'splash restore recovery must keep $token',
      );
    }
  }

  final widgetTest = File('test/widget_test.dart');
  check(
    widgetTest.path,
    widgetTest.existsSync(),
    'root widget tests are missing',
  );
  if (widgetTest.existsSync()) {
    final source = widgetTest.readAsStringSync();
    check(
      widgetTest.path,
      source.contains('SplashScreen shows retry when session restore fails') &&
          source.contains('_FailingRestoreSessionService') &&
          source.contains('앱 시작 상태를 확인하지 못했어요.') &&
          source.contains("find.text('다시 시도')") &&
          source.contains('expect(service.attempts, 2)'),
      'splash restore failure must have retry widget coverage',
    );
  }
}

void _validateKoreanFontRenderingPolicy(
  void Function(String scope, bool condition, String message) check,
) {
  final typography = File('lib/design_system/app_typography.dart');
  check(
    typography.path,
    typography.existsSync(),
    'app typography tokens are missing',
  );
  if (typography.existsSync()) {
    final source = typography.readAsStringSync();
    check(
      typography.path,
      source.contains("static const fontFamily = 'NotoSansKR'"),
      'default app font must be NotoSansKR so Korean text renders on Flutter Web CanvasKit',
    );
    check(
      typography.path,
      !source.contains("static const fontFamily = 'Sora'"),
      'default app font must not use an unbundled Latin-only font',
    );
  }

  final pubspec = File('pubspec.yaml');
  check(pubspec.path, pubspec.existsSync(), 'pubspec.yaml is missing');
  if (pubspec.existsSync()) {
    final source = pubspec.readAsStringSync();
    check(
      pubspec.path,
      source.contains('family: NotoSansKR') &&
          source.contains('assets/fonts/NotoSansKR-VF.ttf'),
      'pubspec must bundle the NotoSansKR font asset',
    );
  }

  final fontFile = File('assets/fonts/NotoSansKR-VF.ttf');
  check(
    fontFile.path,
    fontFile.existsSync(),
    'NotoSansKR font asset is missing',
  );
  if (fontFile.existsSync()) {
    check(
      fontFile.path,
      fontFile.lengthSync() > 1000000,
      'NotoSansKR font asset must contain full Korean glyph coverage',
    );
  }
}

void _validateLocationPrivacyInPresentation(
  void Function(String scope, bool condition, String message) check,
) {
  final files = _dartAndTextFiles(['lib/features']).where((file) {
    final normalizedPath = file.path.replaceAll('\\', '/');
    return normalizedPath.endsWith('.dart') &&
        normalizedPath.contains('/presentation/');
  });
  final forbiddenTokens = ['latitude', 'longitude', 'drive_points'];
  var violationCount = 0;

  for (final file in files) {
    final normalizedPath = file.path.replaceAll('\\', '/');
    final isDriveRecorder =
        normalizedPath.endsWith('/drive/presentation/safety_drive_screen.dart');
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i += 1) {
      final line = lines[i];
      final normalizedLine = line.toLowerCase();
      final isPrivacyCopy = normalizedLine.contains('drive_points') &&
          (line.contains('노출하지') || line.contains('공개'));
      for (final token in forbiddenTokens) {
        if (!normalizedLine.contains(token)) continue;
        if (isDriveRecorder || isPrivacyCopy) continue;
        violationCount += 1;
        check(
          '$normalizedPath:${i + 1}',
          false,
          'public presentation code must not expose precise location/raw $token',
        );
      }
    }
  }

  if (violationCount == 0) {
    check(
      'lib/features/*/presentation',
      true,
      'presentation screens do not expose precise location or raw drive_points',
    );
  }
}

bool _isAdminDashboardLine(
  String normalizedPath,
  List<String> lines,
  int lineIndex,
) {
  if (!normalizedPath
      .endsWith('/features/common/presentation/flow_screens.dart')) {
    return false;
  }
  final start = lines.indexWhere(
    (line) => line.contains('class AdminDashboardScreen'),
  );
  if (start < 0 || lineIndex < start) return false;
  final end = lines.indexWhere(
    (line) => line.contains('class FuelArenaInfoScreen'),
  );
  return end < 0 ? true : lineIndex < end;
}

void _validateBattleRewardModel(
  void Function(String scope, bool condition, String message) check,
) {
  final files = [
    ..._dartAndTextFiles(['lib']).where((file) => file.path.endsWith('.dart')),
    ..._dartAndTextFiles(['supabase/migrations'])
        .where((file) => file.path.endsWith('.sql')),
  ];
  final allowedValues = {'non_cash_reward', '비금전 보상'};

  for (final file in files) {
    final source = file.readAsStringSync();
    for (final value in _stringValuesFor(source, 'wagerTemplate')) {
      check(
        file.path,
        allowedValues.contains(value),
        'battle wagerTemplate must stay non-cash, found "$value"',
      );
    }
    for (final value in _mapStringValuesFor(source, 'wager_template')) {
      check(
        file.path,
        value == 'non_cash_reward',
        'battle wager_template DB value must be non_cash_reward, found "$value"',
      );
    }
    for (final value in _sqlDefaultsFor(source, 'wager_template')) {
      check(
        file.path,
        value == 'non_cash_reward',
        'battle wager_template SQL default must be non_cash_reward, found "$value"',
      );
    }
  }
}

void _validateReviewRequestFlow(
  void Function(String scope, bool condition, String message) check,
) {
  final supportScreen =
      File('lib/features/support/presentation/support_screens.dart');
  check(
    supportScreen.path,
    supportScreen.existsSync(),
    'support screens file is missing',
  );
  if (supportScreen.existsSync()) {
    final source = supportScreen.readAsStringSync();
    for (final token in [
      'class ReviewRequestScreen',
      'supportRepositoryProvider',
      'reportRepositoryProvider',
      "'drive_review_request'",
      "'review_request_submitted'",
      '검토 요청 제출',
    ]) {
      check(
        supportScreen.path,
        source.contains(token),
        'review request screen must keep $token',
      );
    }
  }

  final router = File('lib/app/router.dart');
  check(router.path, router.existsSync(), 'app router is missing');
  if (router.existsSync()) {
    final source = router.readAsStringSync();
    for (final route in [
      "'/support/review-request'",
      "'/support/review-request/:driveId'",
    ]) {
      check(
        router.path,
        source.contains(route),
        'review request route $route must stay registered',
      );
    }
  }

  final driveResult =
      File('lib/features/drive/presentation/drive_result_screen.dart');
  check(driveResult.path, driveResult.existsSync(),
      'drive result screen is missing');
  if (driveResult.existsSync()) {
    final source = driveResult.readAsStringSync();
    check(
      driveResult.path,
      source.contains('이 기록 검토 요청') &&
          source.contains('/support/review-request/\${payload.sessionId}'),
      'drive result must link the current session to review request',
    );
  }

  final fairness =
      File('lib/features/fairness/presentation/fairness_center_screen.dart');
  check(fairness.path, fairness.existsSync(), 'fairness center is missing');
  if (fairness.existsSync()) {
    final source = fairness.readAsStringSync();
    check(
      fairness.path,
      source.contains('검토 요청하기') &&
          source.contains('/support/review-request') &&
          source.contains('LoadingSkeletonView(lines: 5)') &&
          source.contains('공정성 기준을 불러오지 못했어요') &&
          source.contains('공정성 기준을 확인할 수 없어요'),
      'fairness center must offer a review request CTA',
    );
  }

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(widgetTest.path, widgetTest.existsSync(), 'flow widget tests missing');
  if (widgetTest.existsSync()) {
    final source = widgetTest.readAsStringSync();
    check(
      widgetTest.path,
      source
          .contains('ReviewRequestScreen submits ticket and report queue item'),
      'review request screen must have widget coverage',
    );
    check(
      widgetTest.path,
      source.contains('AdminDashboardScreen resolves report queue item'),
      'admin reports queue resolution must have widget coverage',
    );
  }

  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(repositoryFile.path, repositoryFile.existsSync(), 'repository missing');
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      'Future<ReportItem?> updateReportStatus',
      '_mockReportAdminRecords',
      '_adminRecordFromReportItem',
      '_reportTargetTypeAdminLabel',
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'reports queue must support admin status handling $token',
      );
    }
  }

  final flowScreens =
      File('lib/features/common/presentation/flow_screens.dart');
  check(flowScreens.path, flowScreens.existsSync(), 'flow screens missing');
  if (flowScreens.existsSync()) {
    final source = flowScreens.readAsStringSync();
    check(
      flowScreens.path,
      source.contains("widget.section == 'Reports'") &&
          source.contains("updateReportStatus(record.id, 'resolved')"),
      'admin reports action must update the report row status',
    );
  }

  final analyticsDocs = File('docs/13_analytics_events.md');
  check(
    analyticsDocs.path,
    analyticsDocs.existsSync() &&
        analyticsDocs.readAsStringSync().contains('review_request_submitted'),
    'analytics docs must document review_request_submitted',
  );

  final audit = File('docs/20_product_completion_audit.md');
  check(
    audit.path,
    audit.existsSync() &&
        audit.readAsStringSync().contains('이의제기 화면') &&
        audit.readAsStringSync().contains('관리자 Reports 섹션은 실제 report_items 큐'),
    'product audit must mention the review request screen and admin report queue',
  );
}

void _validateUserJourneyRecoveryStates(
  void Function(String scope, bool condition, String message) check,
) {
  final stats = File('lib/features/stats/presentation/stats_screen.dart');
  check(stats.path, stats.existsSync(), 'stats screen is missing');
  if (stats.existsSync()) {
    final source = stats.readAsStringSync();
    for (final token in [
      '주행 기록이 아직 없어요',
      '첫 주행 시작하기',
      "'/drive/start'",
      'ref.invalidate(statsRepositoryProvider)',
    ]) {
      check(
        stats.path,
        source.contains(token),
        'stats empty/error recovery must keep $token',
      );
    }
  }

  final rewards =
      File('lib/features/rewards/presentation/reward_wallet_screen.dart');
  check(rewards.path, rewards.existsSync(), 'reward wallet screen is missing');
  if (rewards.existsSync()) {
    final source = rewards.readAsStringSync();
    for (final token in [
      'class RewardWalletScreen extends ConsumerStatefulWidget',
      'appRemoteConfigProvider',
      'remoteConfig.when',
      '쿠폰 운영 설정을 불러오지 못했어요.',
      'ref.invalidate(appRemoteConfigProvider)',
      'couponRepositoryProvider',
      'issueCoupon(coupon.id)',
      'coupon_issue_requested',
      'coupon_issue_succeeded',
      '쿠폰 받기',
      '발급 완료',
      '사용 가능한 쿠폰이 없어요',
      '리워드 광고 보기',
      '쿠폰 발급이 잠시 쉬고 있어요',
      "'/ads/reward'",
      'ref.invalidate(couponsProvider)',
    ]) {
      check(
        rewards.path,
        source.contains(token),
        'reward wallet empty/error recovery must keep $token',
      );
    }
    check(
      rewards.path,
      !source.contains('orElse: () => true'),
      'reward wallet must not enable coupons from missing remote config',
    );
  }

  final sponsor =
      File('lib/features/sponsor/presentation/sponsor_challenge_screen.dart');
  check(
    sponsor.path,
    sponsor.existsSync(),
    'sponsor challenge screen is missing',
  );
  if (sponsor.existsSync()) {
    final source = sponsor.readAsStringSync();
    for (final token in [
      'sponsorChallengesProvider',
      'LoadingSkeletonView(lines: 3)',
      '스폰서 챌린지를 불러오지 못했어요',
      '참여 가능한 챌린지가 없어요',
      "'/drive/start'",
    ]) {
      check(
        sponsor.path,
        source.contains(token),
        'sponsor challenge loading/error/empty recovery must keep $token',
      );
    }
  }

  final premium = File('lib/features/premium/presentation/premium_screen.dart');
  check(premium.path, premium.existsSync(), 'premium screen is missing');
  if (premium.existsSync()) {
    final source = premium.readAsStringSync();
    for (final token in [
      'snapshot.connectionState == ConnectionState.waiting',
      'snapshot.hasError',
      'if (items.isEmpty)',
      'for (final plan in items)',
      '요금제를 확인할 수 없어요',
      "'/support/contact'",
    ]) {
      check(
        premium.path,
        source.contains(token),
        'premium loading/error/empty recovery must keep $token',
      );
    }
  }

  final flowScreens =
      File('lib/features/common/presentation/flow_screens.dart');
  check(flowScreens.path, flowScreens.existsSync(), 'flow screens missing');
  if (flowScreens.existsSync()) {
    final source = flowScreens.readAsStringSync();
    for (final token in [
      '배틀 정보를 찾지 못했어요',
      '배틀 결과가 없어요',
      '챌린지를 찾을 수 없어요',
      'battleDetailProvider(battleId)',
      'ref.invalidate(battleDetailProvider(battleId))',
      'ref.invalidate(battlesProvider)',
      '배틀 정산 요청',
      'battle_settle_requested',
      'battle_settle_succeeded',
      'ref.invalidate(sponsorChallengesProvider)',
      '_firstWhereOrNull',
    ]) {
      check(
        flowScreens.path,
        source.contains(token),
        'detail screens must keep missing-record recovery token $token',
      );
    }
    check(
      flowScreens.path,
      !source.contains('orElse: () => items.first'),
      'detail screens must not silently replace missing ids with the first item',
    );
  }

  final repositories =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositories.path,
    repositories.existsSync(),
    'fuel arena repositories file missing',
  );
  if (repositories.existsSync()) {
    final source = repositories.readAsStringSync();
    check(
      repositories.path,
      source.contains('Future<Battle?> getBattleById') &&
          source.contains('Future<Battle> settleBattle') &&
          source.contains("'settle_battle'") &&
          source.contains('_mockBattles = [battle, ..._mockBattles]'),
      'battle repository must support id lookup, settlement, and persist created mock battles',
    );
  }

  final providers = File('lib/shared/providers/repository_providers.dart');
  check(providers.path, providers.existsSync(), 'repository providers missing');
  if (providers.existsSync()) {
    check(
      providers.path,
      providers.readAsStringSync().contains('battleDetailProvider'),
      'battle detail provider must expose id-based battle lookup',
    );
  }

  final router = File('lib/app/router.dart');
  check(router.path, router.existsSync(), 'app router missing');
  if (router.existsSync()) {
    final source = router.readAsStringSync();
    for (final forbidden in [
      "?? 'battle-001'",
      "?? 'user-001'",
      "?? 'sponsor-001'",
    ]) {
      check(
        router.path,
        !source.contains(forbidden),
        'router detail routes must not fall back to example ids $forbidden',
      );
    }
    for (final token in [
      "state.pathParameters['battleId'] ?? ''",
      "state.pathParameters['userId'] ?? ''",
      "state.pathParameters['challengeId'] ?? ''",
    ]) {
      check(
        router.path,
        source.contains(token),
        'router detail routes must pass missing ids through as empty values $token',
      );
    }
  }

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(widgetTest.path, widgetTest.existsSync(), 'flow widget tests missing');
  if (widgetTest.existsSync()) {
    final source = widgetTest.readAsStringSync();
    for (final testName in [
      'StatsScreen empty state starts first drive',
      'RewardWalletScreen empty coupons links to reward ad',
      'RewardWalletScreen issues selected coupon',
      'RewardWalletScreen blocks coupon issuing on remote config error',
      'SponsorChallengeScreen empty state starts drive',
      'PremiumScreen empty plans shows support CTA',
      'Battle detail renders battle by id',
      'Battle result settles pending battle',
      'Battle detail missing id shows empty state',
      'Sponsor detail missing id shows empty state',
    ]) {
      check(
        widgetTest.path,
        source.contains(testName),
        'user journey recovery must have widget coverage',
      );
    }
  }

  final emptyStateGuide = File('docs/18_empty_state_guide.md');
  check(
    emptyStateGuide.path,
    emptyStateGuide.existsSync() &&
        emptyStateGuide.readAsStringSync().contains('/ads/reward') &&
        emptyStateGuide.readAsStringSync().contains('/support/contact'),
    'empty state guide must document concrete recovery routes',
  );

  final behaviorSpec = File('docs/06_behavior_spec.md');
  check(
    behaviorSpec.path,
    behaviorSpec.existsSync() &&
        behaviorSpec.readAsStringSync().contains('빈 상태 복구') &&
        behaviorSpec
            .readAsStringSync()
            .contains('CouponRepository.issueCoupon') &&
        behaviorSpec.readAsStringSync().contains('settle_battle'),
    'behavior spec must document empty state recovery, coupon issuing, and battle settlement policy',
  );

  final analyticsDocs = File('docs/13_analytics_events.md');
  check(
    analyticsDocs.path,
    analyticsDocs.existsSync() &&
        analyticsDocs.readAsStringSync().contains('coupon_issue_requested') &&
        analyticsDocs.readAsStringSync().contains('coupon_issue_succeeded') &&
        analyticsDocs.readAsStringSync().contains('battle_settle_requested') &&
        analyticsDocs.readAsStringSync().contains('battle_settle_succeeded'),
    'analytics docs must document coupon issue and battle settlement events',
  );

  final repositoryTest = File('test/unit/mock_repositories_test.dart');
  check(
    repositoryTest.path,
    repositoryTest.existsSync() &&
        repositoryTest
            .readAsStringSync()
            .contains('MockCouponRepository issues user coupon'),
    'coupon issuing must have repository unit coverage',
  );
}

void _validateSupportFaqFlow(
  void Function(String scope, bool condition, String message) check,
) {
  final screen = File('lib/features/support/presentation/support_screens.dart');
  check(screen.path, screen.existsSync(), 'support screens file missing');
  if (screen.existsSync()) {
    final source = screen.readAsStringSync();
    for (final token in [
      'class FAQScreen extends StatelessWidget',
      '자주 묻는 질문',
      '검토 요청하기',
      "'/support/review-request'",
      "'/support/contact?category=\${Uri.encodeComponent(category)}'",
      '쿠폰 문제로 문의',
    ]) {
      check(
        screen.path,
        source.contains(token),
        'FAQ screen must keep support recovery token $token',
      );
    }
    check(
      screen.path,
      !source.contains("return const FuelArenaInfoScreen(\n      title: 'FAQ'"),
      'FAQ route must not return to static info copy',
    );
  }

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(
    widgetTest.path,
    widgetTest.existsSync() &&
        widgetTest
            .readAsStringSync()
            .contains('FAQScreen renders recovery actions') &&
        widgetTest
            .readAsStringSync()
            .contains('FAQScreen opens support contact with category'),
    'FAQ support recovery must have widget coverage',
  );

  final behaviorSpec = File('docs/06_behavior_spec.md');
  check(
    behaviorSpec.path,
    behaviorSpec.existsSync() &&
        behaviorSpec.readAsStringSync().contains('/support/faq') &&
        behaviorSpec.readAsStringSync().contains('/support/contact?category='),
    'behavior spec must document FAQ recovery behavior',
  );
}

void _validateDriveHistoryAnalysisFlow(
  void Function(String scope, bool condition, String message) check,
) {
  final screen =
      File('lib/features/drive/presentation/drive_history_screen.dart');
  check(screen.path, screen.existsSync(), 'drive history screen is missing');
  if (screen.existsSync()) {
    final source = screen.readAsStringSync();
    for (final token in [
      'class DriveHistoryScreen',
      'class DriveAnalysisScreen',
      'listDriveSessions(limit: 20)',
      'listDriveScores(limit: 20)',
      'DriveScoreAnalysisCard',
      "'/support/review-request/\${session.id}'",
      '정확한 위치 좌표',
    ]) {
      check(
        screen.path,
        source.contains(token),
        'drive history/analysis screen must keep $token',
      );
    }
    check(
      screen.path,
      !source.contains('DrivePoint') &&
          !source.contains('latitude') &&
          !source.contains('longitude'),
      'drive history/analysis screen must not render raw drive point fields',
    );
  }

  final repository =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(repository.path, repository.existsSync(), 'repositories file missing');
  if (repository.existsSync()) {
    final source = repository.readAsStringSync();
    for (final token in [
      'Future<List<DriveSession>> listDriveSessions',
      'Future<List<DriveScore>> listDriveScores',
      "from('drive_sessions')",
      "from('drive_scores')",
      'DriveSession.fromJson',
    ]) {
      check(
        repository.path,
        source.contains(token),
        'DriveRepository must keep recent drive history contract',
      );
    }
    final listSessionsSection = RegExp(
      r'Future<List<DriveSession>> listDriveSessions[\s\S]*?Future<List<DriveScore>> listDriveScores',
    ).firstMatch(source);
    check(
      repository.path,
      listSessionsSection != null &&
          !listSessionsSection.group(0)!.contains('drive_points'),
      'drive history repository query must not fetch raw drive_points',
    );
  }

  final router = File('lib/app/router.dart');
  check(router.path, router.existsSync(), 'app router is missing');
  if (router.existsSync()) {
    final source = router.readAsStringSync();
    check(
      router.path,
      source.contains('DriveHistoryScreen') &&
          source.contains('DriveAnalysisScreen') &&
          !source.contains("title: '주행 기록'") &&
          !source.contains("title: '주행 분석'"),
      'drive history and analysis routes must use real screens, not static info screens',
    );
  }

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(widgetTest.path, widgetTest.existsSync(), 'flow widget tests missing');
  if (widgetTest.existsSync()) {
    final source = widgetTest.readAsStringSync();
    for (final testName in [
      'DriveHistoryScreen opens analysis route',
      'DriveAnalysisScreen links to review request',
    ]) {
      check(
        widgetTest.path,
        source.contains(testName),
        'drive history/analysis routes must have widget coverage',
      );
    }
  }

  final repositoryTest = File('test/unit/mock_repositories_test.dart');
  check(
    repositoryTest.path,
    repositoryTest.existsSync() &&
        repositoryTest
            .readAsStringSync()
            .contains('MockDriveRepository lists recent sessions'),
    'DriveRepository list methods must have unit coverage',
  );

  final docs = [
    File('docs/02_ia.md'),
    File('docs/04_data_schema.md'),
    File('docs/06_behavior_spec.md'),
  ];
  for (final doc in docs) {
    check(
      doc.path,
      doc.existsSync() &&
          doc.readAsStringSync().contains('주행 기록') &&
          doc.readAsStringSync().contains('좌표'),
      'drive history/analysis docs must describe route and privacy behavior',
    );
  }
}

Iterable<String> _stringValuesFor(String source, String fieldName) sync* {
  final regex = RegExp("$fieldName\\s*[:=]\\s*'([^']+)'");
  for (final match in regex.allMatches(source)) {
    final value = match.group(1)!;
    if (value.startsWith(r'$')) continue;
    yield value;
  }
}

Iterable<String> _mapStringValuesFor(String source, String keyName) sync* {
  final regex = RegExp("'$keyName'\\s*:\\s*'([^']+)'");
  for (final match in regex.allMatches(source)) {
    yield match.group(1)!;
  }
}

Iterable<String> _sqlDefaultsFor(String source, String columnName) sync* {
  final regex = RegExp(
    "$columnName\\s+[^\\n,]+default\\s+'([^']+)'",
    caseSensitive: false,
  );
  for (final match in regex.allMatches(source)) {
    yield match.group(1)!;
  }
}

void _validateAnalyticsSanitization(
  void Function(String scope, bool condition, String message) check,
) {
  final file = File('lib/shared/services/app_services.dart');
  check(file.path, file.existsSync(), 'app services file is missing');
  if (!file.existsSync()) return;

  final source = file.readAsStringSync();
  for (final key in ['location', 'latitude', 'longitude', 'drive_points']) {
    check(
      file.path,
      source.contains("normalized.contains('$key')"),
      'analytics sanitizer must remove "$key" properties',
    );
  }
  check(
    file.path,
    source.contains(
        'final safeProperties = sanitizedAnalyticsProperties(properties);'),
    'analytics track implementations must sanitize properties before storing',
  );
  check(
    file.path,
    source.contains('bool isSensitiveAnalyticsKey(String key)') &&
        source.contains('if (isSensitiveAnalyticsKey(key))'),
    'analytics user properties must block sensitive keys before storing',
  );

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync() &&
        serviceTest.readAsStringSync().contains("event['key'] == 'latitude'"),
    'analytics sanitizer tests must cover sensitive user property keys',
  );
}

void _validateDrivingModeNoInterruptions(
  void Function(String scope, bool condition, String message) check,
) {
  final safetyScreen =
      File('lib/features/drive/presentation/safety_drive_screen.dart');
  check(
    safetyScreen.path,
    safetyScreen.existsSync(),
    'safety drive screen is missing',
  );
  if (safetyScreen.existsSync()) {
    final source = safetyScreen.readAsStringSync();
    check(
      safetyScreen.path,
      !source.contains('showDialog') &&
          !source.contains('showModalBottomSheet') &&
          !source.contains('SnackBar('),
      'driving mode must not show popup, sheet, or snackbar interruptions',
    );
    for (final route in [
      '/battle',
      '/notifications',
      '/rewards',
      '/sponsor',
      '/premium',
    ]) {
      check(
        safetyScreen.path,
        !source.contains(route),
        'driving mode must not route to interruption surface $route',
      );
    }
    check(
      safetyScreen.path,
      source.contains('한 번 더 눌러 종료') && source.contains('팝업 없이 한 번 더 누르면'),
      'driving mode finish confirmation must stay inline',
    );
  }

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(
    widgetTest.path,
    widgetTest.existsSync(),
    'flow widget tests missing',
  );
  if (widgetTest.existsSync()) {
    final source = widgetTest.readAsStringSync();
    check(
      widgetTest.path,
      source.contains(
            'SafetyDriveScreen confirms finish inline without popup',
          ) &&
          source.contains('find.byType(AlertDialog), findsNothing'),
      'safety drive inline finish confirmation must have widget coverage',
    );
  }
}

void _validateDriveStartReadinessFlow(
  void Function(String scope, bool condition, String message) check,
) {
  final driveStartScreen =
      File('lib/features/drive/presentation/drive_start_screen.dart');
  check(
    driveStartScreen.path,
    driveStartScreen.existsSync(),
    'drive start screen is missing',
  );
  if (driveStartScreen.existsSync()) {
    final source = driveStartScreen.readAsStringSync();
    for (final token in [
      'ConsumerStatefulWidget',
      'Future<_DriveReadiness>? _readinessFuture',
      'String? _readinessVehicleId',
      '_readinessFor(',
      'snapshot.hasError',
      'MappedErrorStateView',
    ]) {
      check(
        driveStartScreen.path,
        source.contains(token),
        'drive start readiness must keep stable error-aware state token $token',
      );
    }
    check(
      driveStartScreen.path,
      !source.contains('Future.wait(['),
      'drive start readiness must not create a fresh Future.wait in every build',
    );
  }

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(
    widgetTest.path,
    widgetTest.existsSync() &&
        widgetTest
            .readAsStringSync()
            .contains('DriveStartScreen readiness error shows retry state'),
    'drive start readiness error state must have widget coverage',
  );
}

void _validateOfflineDriveSyncFlow(
  void Function(String scope, bool condition, String message) check,
) {
  final driveStartScreen =
      File('lib/features/drive/presentation/drive_start_screen.dart');
  check(
    driveStartScreen.path,
    driveStartScreen.existsSync(),
    'drive start screen is missing',
  );
  if (driveStartScreen.existsSync()) {
    final source = driveStartScreen.readAsStringSync();
    for (final token in [
      'network.isOnline',
      'local-drive-',
      'enqueueDriveSession(session)',
      "'storage_mode'",
      "'local_queue'",
    ]) {
      check(
        driveStartScreen.path,
        source.contains(token),
        'offline drive start must keep local queue token $token',
      );
    }
  }

  final driveResultScreen =
      File('lib/features/drive/presentation/drive_result_screen.dart');
  check(
    driveResultScreen.path,
    driveResultScreen.existsSync(),
    'drive result screen is missing',
  );
  if (driveResultScreen.existsSync()) {
    final source = driveResultScreen.readAsStringSync();
    for (final token in [
      'resolveDriveSessionId(routeSessionId)',
      'sessionId: resolvedSessionId',
      "context.go('/support/review-request/\${payload.sessionId}')",
      '_MissingDriveResultSummaryException',
      '주행 결과 기록이 없어요',
    ]) {
      check(
        driveResultScreen.path,
        source.contains(token),
        'drive result must resolve local sessions before finish/review $token',
      );
    }
    for (final forbidden in [
      '?? 24.8',
      'Duration(minutes: 38, seconds: 12)',
      '?? 18.4',
    ]) {
      check(
        driveResultScreen.path,
        !source.contains(forbidden),
        'drive result must not calculate scores from sample fallback $forbidden',
      );
    }
  }

  final servicesFile = File('lib/shared/services/app_services.dart');
  check(
    servicesFile.path,
    servicesFile.existsSync(),
    'app services file is missing',
  );
  if (servicesFile.existsSync()) {
    final source = servicesFile.readAsStringSync();
    for (final token in [
      "'offline_drive_session_id_map'",
      'Future<Map<String, String>> driveSessionIdMap()',
      'rememberDriveSessionMapping(',
      'Future<String> resolveDriveSessionId(',
      "'offline_queue_corrupt_backup'",
      '_quarantineCorruptQueue',
      '_tryParseItem',
      "reason: 'decode_error'",
      "reason: 'invalid_items'",
      'final sessionIdMap = await offlineQueue.driveSessionIdMap();',
      "case 'drive_session':",
      'uploadQueuedDriveSession(session)',
      'point.copyWith(driveSessionId: remoteSessionId)',
      'class SupabaseLocalSyncLogRepository',
      "'user_local_sync_logs'",
      '_recordSyncLog(item, result)',
      '_SyncUploadResult.discarded',
      'shouldRemoveFromQueue',
      'countsAsUpload',
      "status != 'failed'",
      '_safeSyncErrorMessage',
      'latitude|longitude|drive_points',
    ]) {
      check(
        servicesFile.path,
        source.contains(token),
        'offline drive sync must upload sessions before remapped points $token',
      );
    }
    check(
      servicesFile.path,
      !source.contains('final sessionIdMap = <String, String>{};') &&
          source.contains(
              'final sessionIdMap = await offlineQueue.driveSessionIdMap();'),
      'offline drive sync must persist session id mapping across retry runs',
    );
  }

  final providerFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providerFile.path,
    providerFile.existsSync() &&
        providerFile
            .readAsStringSync()
            .contains('final localSyncLogRepositoryProvider') &&
        providerFile.readAsStringSync().contains(
              'syncLogRepository: ref.watch(localSyncLogRepositoryProvider)',
            ),
    'sync service must receive the local sync log repository provider',
  );

  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync(),
    'repository file is missing',
  );
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      'Future<DriveSession> uploadQueuedDriveSession',
      '_drivePointInsertPayload',
      "if (_isUuidLike(point.id)) 'id': point.id",
      "value.startsWith('local-drive-')",
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'drive repository must support queued local sessions and local point ids $token',
      );
    }
  }

  final modelsFile = File('lib/shared/models/fuel_arena_models.dart');
  check(
    modelsFile.path,
    modelsFile.existsSync() &&
        modelsFile.readAsStringSync().contains('DrivePoint copyWith'),
    'DrivePoint must support remapping queued local session ids',
  );

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync() &&
        serviceTest.readAsStringSync().contains(
              'SyncService uploads local drive session before remapped points',
            ) &&
        serviceTest.readAsStringSync().contains(
              'SyncService persists local drive session mapping after point failure',
            ) &&
        serviceTest.readAsStringSync().contains(
              'SyncService records local sync success and failure logs',
            ) &&
        serviceTest.readAsStringSync().contains(
              'SyncService discards malformed and unsupported queued items with logs',
            ) &&
        serviceTest.readAsStringSync().contains(
              'OfflineQueueService quarantines corrupted queue storage',
            ) &&
        serviceTest.readAsStringSync().contains(
              'OfflineQueueService preserves valid items from partially bad queue',
            ) &&
        serviceTest.readAsStringSync().contains("everyElement('discarded')") &&
        serviceTest.readAsStringSync().contains(
              "isNot(contains('latitude'))",
            ),
    'offline drive session remapping, retry persistence, and sync logs must have unit coverage',
  );

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(
    widgetTest.path,
    widgetTest.existsSync() &&
        widgetTest.readAsStringSync().contains(
              'DriveResultScreen resolves local drive session before finish',
            ) &&
        widgetTest.readAsStringSync().contains(
              'DriveResultScreen missing local summary shows recovery without finish',
            ),
    'drive result local session resolution and missing summary recovery must have widget coverage',
  );
}

void _validateStructuredLogging(
  void Function(String scope, bool condition, String message) check,
) {
  final loggerFile = File('lib/shared/services/app_logger.dart');
  check(loggerFile.path, loggerFile.existsSync(), 'app logger file is missing');
  if (loggerFile.existsSync()) {
    final source = loggerFile.readAsStringSync();
    for (final token in [
      'class AppLogger',
      'class AppLogRecord',
      'sanitizedLogContext',
      'developer.log',
    ]) {
      check(
        loggerFile.path,
        source.contains(token),
        'structured logging must keep $token',
      );
    }
    for (final sensitiveKey in [
      'drive_points',
      'latitude',
      'longitude',
      'service_role',
      'access_token',
      'authorization',
    ]) {
      check(
        loggerFile.path,
        source.contains("'$sensitiveKey'"),
        'structured logging must redact sensitive key "$sensitiveKey"',
      );
    }
  }

  final mainFile = File('lib/main.dart');
  check(mainFile.path, mainFile.existsSync(), 'main.dart is missing');
  if (mainFile.existsSync()) {
    final source = mainFile.readAsStringSync();
    for (final token in [
      'runZonedGuarded',
      'FlutterError.onError',
      'PlatformDispatcher.instance.onError',
      'AppLogger',
    ]) {
      check(
        mainFile.path,
        source.contains(token),
        'app startup must install structured error logging with $token',
      );
    }
  }

  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync(),
    'repository file is missing',
  );
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    check(
      repositoryFile.path,
      !source.contains('debugPrint('),
      'repositories must not rely on debugPrint for operational failures',
    );
    check(
      repositoryFile.path,
      source.contains('record_drive_points failed') &&
          source.contains('finish_drive_session edge call failed'),
      'drive operational fallbacks must use structured log messages',
    );
  }

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync(),
    'service completion tests missing',
  );
  if (serviceTest.existsSync()) {
    final source = serviceTest.readAsStringSync();
    check(
      serviceTest.path,
      source.contains('AppLogger sanitizes structured log context') &&
          source.contains('AppLogger writes structured records through sink'),
      'structured logging must have unit coverage',
    );
  }
}

void _validateProductionDriveFallbackPolicy(
  void Function(String scope, bool condition, String message) check,
) {
  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync(),
    'repository file is missing',
  );
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      'this.allowMockFallback = true',
      'final bool allowMockFallback;',
      '_finishDriveSessionFallback',
      'if (!allowMockFallback)',
      'Error.throwWithStackTrace(error, stackTrace)',
      '공식 주행 세션 검증을 완료하지 못했습니다.',
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'production drive finish fallback policy must keep $token',
      );
    }
  }

  final providerFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providerFile.path,
    providerFile.existsSync(),
    'repository providers file is missing',
  );
  if (providerFile.existsSync()) {
    final source = providerFile.readAsStringSync();
    check(
      providerFile.path,
      source.contains(
        'SupabaseDriveRepository(allowMockFallback: !config.isProduction)',
      ),
      'production providers must disable Supabase drive mock fallback',
    );
  }

  final verifyPurchaseFunction =
      File('supabase/functions/verify_purchase/index.ts');
  check(
    verifyPurchaseFunction.path,
    verifyPurchaseFunction.existsSync(),
    'verify_purchase Edge Function is missing',
  );
  if (verifyPurchaseFunction.existsSync()) {
    final source = verifyPurchaseFunction.readAsStringSync();
    check(
      verifyPurchaseFunction.path,
      source.contains('requireSecret("APP_STORE_BUNDLE_ID")') &&
          source.contains('APP_STORE_BUNDLE_ID is invalid') &&
          source.contains('GOOGLE_PLAY_PACKAGE_NAME') &&
          !source.contains('optionalString(body.packageName)') &&
          !source.contains(
            'Deno.env.get("APP_STORE_BUNDLE_ID") ?? "com.fuelarena.fuel_arena"',
          ),
      'verify_purchase must require server-owned store identifiers',
    );
  }

  final modelsFile = File('lib/shared/models/fuel_arena_models.dart');
  check(modelsFile.path, modelsFile.existsSync(), 'models file is missing');
  if (modelsFile.existsSync()) {
    final source = modelsFile.readAsStringSync();
    check(
      modelsFile.path,
      source.contains('class PurchaseVerificationRequest') &&
          !source.contains("'packageName': packageName") &&
          !source.contains('final String packageName;'),
      'purchase verification request must not send client-controlled packageName',
    );
  }

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync(),
    'service completion tests missing',
  );
  if (serviceTest.existsSync()) {
    final source = serviceTest.readAsStringSync();
    check(
      serviceTest.path,
      source.contains('Production drive finish never falls back to mock score'),
      'production drive fallback policy must have unit coverage',
    );
  }
}

void _validateProductionPurchaseFallbackPolicy(
  void Function(String scope, bool condition, String message) check,
) {
  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync(),
    'repository file is missing',
  );
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      'class SupabaseSubscriptionRepository',
      'this.allowMockFallback = true',
      'final bool allowMockFallback;',
      "throw StateError('스토어 결제 검증이 필요합니다.')",
      'verify_purchase',
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'production purchase fallback policy must keep $token',
      );
    }
  }

  final providerFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providerFile.path,
    providerFile.existsSync(),
    'repository providers file is missing',
  );
  if (providerFile.existsSync()) {
    final source = providerFile.readAsStringSync();
    check(
      providerFile.path,
      source.contains(
        'SupabaseSubscriptionRepository(allowMockFallback: !config.isProduction)',
      ),
      'production providers must disable Supabase subscription mock fallback',
    );
  }

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync(),
    'service completion tests missing',
  );
  if (serviceTest.existsSync()) {
    final source = serviceTest.readAsStringSync();
    check(
      serviceTest.path,
      source.contains(
            'Production subscription start never activates mock premium',
          ) &&
          source.contains('requireSecret("APP_STORE_BUNDLE_ID")') &&
          source.contains('GOOGLE_PLAY_PACKAGE_NAME') &&
          source.contains(
            "isNot(contains('optionalString(body.packageName)'))",
          ),
      'production purchase fallback policy must have unit coverage',
    );
  }
}

void _validateProductionPremiumPlanFallbackPolicy(
  void Function(String scope, bool condition, String message) check,
) {
  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync(),
    'repository file is missing',
  );
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      'class SupabasePremiumRepository',
      'return allowMockFallback',
      '? _fallback.getPlans()',
      ': const <SubscriptionPlan>[]',
      'if (!allowMockFallback)',
      'allowMockFallback: allowMockFallback',
      '_subscriptionPlanSortRank',
      "'monthly' => 0",
      "'yearly' => 1",
      "'season_pass' => 2",
      "'bundle' => 3",
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'production premium plan fallback policy must keep $token',
      );
    }
  }

  final subscriptionProductMigration = File(
      'supabase/migrations/202606060021_subscription_product_completion.sql');
  check(
    subscriptionProductMigration.path,
    subscriptionProductMigration.existsSync(),
    'subscription product completion migration is missing',
  );
  if (subscriptionProductMigration.existsSync()) {
    final source = subscriptionProductMigration.readAsStringSync();
    for (final productId in _requiredIapProductIds) {
      check(
        subscriptionProductMigration.path,
        source.contains("'$productId'"),
        'subscription_plans seed must include $productId',
      );
    }
    for (final planType in ['season_pass', 'bundle']) {
      check(
        subscriptionProductMigration.path,
        source.contains("'$planType'"),
        'subscription_plans seed must include $planType plan type',
      );
    }
  }

  final premiumScreen =
      File('lib/features/premium/presentation/premium_screen.dart');
  check(
    premiumScreen.path,
    premiumScreen.existsSync(),
    'premium screen is missing',
  );
  if (premiumScreen.existsSync()) {
    final source = premiumScreen.readAsStringSync();
    for (final token in [
      'for (final plan in items)',
      '_PremiumPlanCard',
      '_planIdByProductId',
      '_planIdForProductId(purchase.productID)',
      'InAppPurchase.instance.purchaseStream.listen(_handlePurchaseUpdates)',
      'InAppPurchase.instance.restorePurchases()',
      '시즌패스 시작하기',
      '번들 시작하기',
    ]) {
      check(
        premiumScreen.path,
        source.contains(token),
        'premium purchase UI must keep $token',
      );
    }
  }

  final providerFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providerFile.path,
    providerFile.existsSync(),
    'repository providers file is missing',
  );
  if (providerFile.existsSync()) {
    final source = providerFile.readAsStringSync();
    check(
      providerFile.path,
      source.contains(
        'SupabasePremiumRepository(allowMockFallback: !config.isProduction)',
      ),
      'production providers must disable Supabase premium plan mock fallback',
    );
  }

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync(),
    'service completion tests missing',
  );
  if (serviceTest.existsSync()) {
    final source = serviceTest.readAsStringSync();
    check(
      serviceTest.path,
      source.contains(
            'Production premium plans never fall back to mock catalog',
          ) &&
          source.contains(
            'Subscription product seed includes all release IAP product ids',
          ) &&
          source.contains(
            'Premium purchase UI exposes all store plans and restore flow',
          ),
      'production premium plan fallback policy must have unit coverage',
    );
  }

  final completionAudit = File('docs/20_product_completion_audit.md');
  check(
    completionAudit.path,
    completionAudit.existsSync(),
    'completion audit document is missing',
  );
  if (completionAudit.existsSync()) {
    final source = completionAudit.readAsStringSync();
    check(
      completionAudit.path,
      source.contains('Production Premium Plan Fallback') &&
          source.contains('mock 프리미엄 요금제'),
      'completion audit must document production premium plan fallback policy',
    );
  }
}

void _validateProductionAdRewardPolicy(
  void Function(String scope, bool condition, String message) check,
) {
  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync(),
    'repository file is missing',
  );
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      'class SupabaseAdsRepository',
      'allowClientRewardGrant',
      'rewardAdsConfigured',
      "eq('key', 'reward_ad_daily_limit')",
      ".from('advertisements')",
      'return const <Advertisement>[];',
      'if (ads.isEmpty && allowClientRewardGrant)',
      'int _boundedRewardAdLimit(Object? value)',
      'if (!allowClientRewardGrant && !verifiedByAdSdk)',
      "throw StateError('광고 시청 검증이 필요합니다.')",
      'grant_ad_reward',
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'production ad reward policy must keep $token',
      );
    }
  }

  final providerFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providerFile.path,
    providerFile.existsSync(),
    'repository providers file is missing',
  );
  if (providerFile.existsSync()) {
    final source = providerFile.readAsStringSync();
    check(
      providerFile.path,
      source.contains('allowClientRewardGrant: !config.isProduction') &&
          source.contains('rewardAdsConfigured: config.hasRewardedAds'),
      'production providers must disable direct client ad reward grants',
    );
  }

  final rewardService = File('lib/shared/services/admob_reward_service.dart');
  check(
    rewardService.path,
    rewardService.existsSync(),
    'AdMob rewarded ad service is missing',
  );
  if (rewardService.existsSync()) {
    final source = rewardService.readAsStringSync();
    for (final token in [
      'MobileAds.instance.initialize()',
      'RewardedAd.load',
      'onUserEarnedReward',
      'kIsWeb',
      'TargetPlatform.android',
      'TargetPlatform.iOS',
    ]) {
      check(
        rewardService.path,
        source.contains(token),
        'rewarded ad service must keep $token',
      );
    }
  }

  final driveResultScreen =
      File('lib/features/drive/presentation/drive_result_screen.dart');
  check(
    driveResultScreen.path,
    driveResultScreen.existsSync(),
    'drive result screen is missing',
  );
  if (driveResultScreen.existsSync()) {
    final source = driveResultScreen.readAsStringSync();
    check(
      driveResultScreen.path,
      source.contains('광고 보상을 확인하지 못했어요') && source.contains('기본 보상은 유지됩니다'),
      'drive result ad reward failure must preserve base reward copy',
    );
    check(
      driveResultScreen.path,
      source.contains('rewardedAdServiceProvider') &&
          source.contains('verifiedByAdSdk: verifiedByAdSdk'),
      'drive result ad reward must pass AdMob verification before Supabase grant',
    );
  }

  final rewardAdScreen =
      File('lib/features/ads/presentation/reward_ad_screen.dart');
  check(rewardAdScreen.path, rewardAdScreen.existsSync(),
      'reward ad screen is missing');
  if (rewardAdScreen.existsSync()) {
    final source = rewardAdScreen.readAsStringSync();
    check(
      rewardAdScreen.path,
      source.contains('광고 보상을 확인하지 못했어요') && source.contains('잠시 후 다시 시도해주세요'),
      'reward ad screen must recover from failed reward verification',
    );
    check(
      rewardAdScreen.path,
      source.contains('remoteConfig.when') &&
          source.contains('리워드 광고 운영 설정을 불러오지 못했어요.') &&
          source.contains('ref.invalidate(appRemoteConfigProvider)') &&
          !source.contains('asData?.value'),
      'reward ad screen must not enable ads from missing remote config',
    );
    check(
      rewardAdScreen.path,
      source.contains('rewardedAdServiceProvider') &&
          source.contains('verifiedByAdSdk: verifiedByAdSdk'),
      'reward ad screen must pass AdMob verification before Supabase grant',
    );
  }

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync(),
    'service completion tests missing',
  );
  if (serviceTest.existsSync()) {
    final source = serviceTest.readAsStringSync();
    check(
      serviceTest.path,
      source.contains(
        'Production ad reward never grants without ad verification',
      ),
      'production ad reward policy must have unit coverage',
    );
  }
}

void _validateProductionUserDataFallbackPolicy(
  void Function(String scope, bool condition, String message) check,
) {
  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync(),
    'repository file is missing',
  );
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      'class SupabaseProfileRepository',
      'class SupabaseStatsRepository',
      'allowMockFallback ? _fallback.getAchievements() : const []',
      'allowMockFallback ? _fallback.getBadges() : const []',
      "throw StateError('로그인이 필요합니다.')",
      "throw StateError('프로필을 찾을 수 없습니다.')",
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'production user data fallback policy must keep $token',
      );
    }
  }

  final providerFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providerFile.path,
    providerFile.existsSync(),
    'repository providers file is missing',
  );
  if (providerFile.existsSync()) {
    final source = providerFile.readAsStringSync();
    for (final token in [
      'SupabaseProfileRepository(allowMockFallback: !config.isProduction)',
      'SupabaseStatsRepository(allowMockFallback: !config.isProduction)',
    ]) {
      check(
        providerFile.path,
        source.contains(token),
        'production providers must disable user-scoped mock fallback $token',
      );
    }
  }

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync(),
    'service completion tests missing',
  );
  if (serviceTest.existsSync()) {
    final source = serviceTest.readAsStringSync();
    check(
      serviceTest.path,
      source.contains(
        'Production user scoped repositories never show mock user data',
      ),
      'production user data fallback policy must have unit coverage',
    );
  }

  final completionAudit = File('docs/20_product_completion_audit.md');
  check(
    completionAudit.path,
    completionAudit.existsSync(),
    'completion audit document is missing',
  );
  if (completionAudit.existsSync()) {
    final source = completionAudit.readAsStringSync();
    check(
      completionAudit.path,
      source.contains('Production User Data Fallback') &&
          source.contains('mock 프로필/통계가 표시되지 않는다'),
      'completion audit must document production user data fallback policy',
    );
  }

  final runbook = File('docs/21_production_runbook.md');
  check(runbook.path, runbook.existsSync(), 'production runbook is missing');
  if (runbook.existsSync()) {
    final source = runbook.readAsStringSync();
    check(
      runbook.path,
      source.contains('Production Failure Policy') &&
          source.contains('mock 사용자 데이터를 표시하지 않는다'),
      'production runbook must document user data fallback policy',
    );
    check(
      runbook.path,
      !source.contains('mock score로 화면 흐름을 유지할 수'),
      'production runbook must not allow finish_drive_session mock score fallback',
    );
  }
}

void _validateProductionCoreExperienceFallbackPolicy(
  void Function(String scope, bool condition, String message) check,
) {
  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync(),
    'repository file is missing',
  );
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      'class SupabaseHomeRepository',
      'class SupabaseSeasonRepository',
      'class SupabaseDriveRepository',
      '_emptyBattle()',
      '_emptySeason(',
      '_emptySeasonMission()',
      '_emptyDriveScore(userId)',
      "throw StateError('프로필을 찾을 수 없습니다.')",
      "throw StateError('대표 차량을 먼저 설정해주세요.')",
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'production core experience fallback policy must keep $token',
      );
    }
  }

  final providerFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providerFile.path,
    providerFile.existsSync(),
    'repository providers file is missing',
  );
  if (providerFile.existsSync()) {
    final source = providerFile.readAsStringSync();
    for (final token in [
      'SupabaseHomeRepository(allowMockFallback: !config.isProduction)',
      'SupabaseSeasonRepository(allowMockFallback: !config.isProduction)',
      'SupabaseDriveRepository(allowMockFallback: !config.isProduction)',
    ]) {
      check(
        providerFile.path,
        source.contains(token),
        'production providers must disable core mock fallback $token',
      );
    }
  }

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync(),
    'service completion tests missing',
  );
  if (serviceTest.existsSync()) {
    final source = serviceTest.readAsStringSync();
    check(
      serviceTest.path,
      source.contains(
        'Production core experience repositories never show mock home data',
      ),
      'production core fallback policy must have unit coverage',
    );
  }

  final completionAudit = File('docs/20_product_completion_audit.md');
  check(
    completionAudit.path,
    completionAudit.existsSync(),
    'completion audit document is missing',
  );
  if (completionAudit.existsSync()) {
    final source = completionAudit.readAsStringSync();
    check(
      completionAudit.path,
      source.contains('Production Core Experience Fallback') &&
          source.contains('mock 홈/시즌/주행 데이터를 표시하지 않는다'),
      'completion audit must document production core fallback policy',
    );
  }

  final runbook = File('docs/21_production_runbook.md');
  check(runbook.path, runbook.existsSync(), 'production runbook is missing');
  if (runbook.existsSync()) {
    final source = runbook.readAsStringSync();
    check(
      runbook.path,
      source.contains('Production Core Experience Fallback') &&
          source.contains('mock 홈/시즌/주행 데이터를 표시하지 않는다'),
      'production runbook must document core fallback policy',
    );
  }
}

void _validateProductionOperationalFallbackPolicy(
  void Function(String scope, bool condition, String message) check,
) {
  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositoryFile.path,
    repositoryFile.existsSync(),
    'repository file is missing',
  );
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      'class SupabaseSponsorRepository',
      'class SupabaseCouponRepository',
      'class SupabaseNotificationRepository',
      'class SupabaseSupportRepository',
      'class SupabaseReportRepository',
      'class SupabasePrivacyRequestRepository',
      'class SupabaseCrewRepository',
      'class SupabaseAdminRepository',
      'class SupabaseFairnessRepository',
      ': const <SponsorChallenge>[]',
      ': const <Coupon>[]',
      "eq('key', 'fairness_guidelines')",
      ': const <String>[]',
      "throw StateError('관리자 권한이 필요합니다.')",
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'production operational fallback policy must keep $token',
      );
    }
  }

  final providerFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providerFile.path,
    providerFile.existsSync(),
    'repository providers file is missing',
  );
  if (providerFile.existsSync()) {
    final source = providerFile.readAsStringSync();
    for (final token in [
      'sponsorRepositoryProvider',
      'couponRepositoryProvider',
      'notificationRepositoryProvider',
      'supportRepositoryProvider',
      'reportRepositoryProvider',
      'privacyRequestRepositoryProvider',
      'crewRepositoryProvider',
      'adminRepositoryProvider',
      'fairnessRepositoryProvider',
      'allowMockFallback: !config.isProduction',
    ]) {
      check(
        providerFile.path,
        source.contains(token),
        'production providers must disable operational mock fallback $token',
      );
    }
  }

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync(),
    'service completion tests missing',
  );
  if (serviceTest.existsSync()) {
    final source = serviceTest.readAsStringSync();
    check(
      serviceTest.path,
      source.contains(
        'Production operational repositories never show mock operational data',
      ),
      'production operational fallback policy must have unit coverage',
    );
  }

  final completionAudit = File('docs/20_product_completion_audit.md');
  check(
    completionAudit.path,
    completionAudit.existsSync(),
    'completion audit document is missing',
  );
  if (completionAudit.existsSync()) {
    final source = completionAudit.readAsStringSync();
    check(
      completionAudit.path,
      source.contains('Production Operational Data Fallback') &&
          source.contains('mock 운영/콘텐츠 데이터를 표시하지 않는다'),
      'completion audit must document production operational fallback policy',
    );
  }

  final runbook = File('docs/21_production_runbook.md');
  check(runbook.path, runbook.existsSync(), 'production runbook is missing');
  if (runbook.existsSync()) {
    final source = runbook.readAsStringSync();
    check(
      runbook.path,
      source.contains('Production Operational Data Fallback') &&
          source.contains('mock 운영/콘텐츠 데이터를 표시하지 않는다'),
      'production runbook must document operational fallback policy',
    );
  }
}

void _validatePrivacyRequestOperations(
  void Function(String scope, bool condition, String message) check,
) {
  final modelFile = File('lib/shared/models/fuel_arena_models.dart');
  check(
    modelFile.path,
    modelFile.existsSync() &&
        modelFile
            .readAsStringSync()
            .contains('class ActivePrivacyRequestException'),
    'privacy requests must expose an active-request exception for UI handling',
  );

  final repositoryFile =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(repositoryFile.path, repositoryFile.existsSync(), 'repository missing');
  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      '_activePrivacyRequestForType',
      '_findActivePrivacyRequest',
      'throw ActivePrivacyRequestException(existingRequest)',
      '_isActivePrivacyRequestStatus',
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'privacy request repository must prevent duplicate active requests $token',
      );
    }
  }

  final flowScreens =
      File('lib/features/common/presentation/flow_screens.dart');
  check(flowScreens.path, flowScreens.existsSync(), 'flow screens missing');
  if (flowScreens.existsSync()) {
    final source = flowScreens.readAsStringSync();
    for (final token in [
      '이미 진행 중인 개인정보 요청이 있어요',
      '이미 접수된 요청이 진행 중입니다.',
      "label: hasActiveRequest ? '진행 중' : '요청'",
      '_privacyRequestRequiresConfirmation',
      '_privacyRequestConfirmationPhrase',
      '계속하려면 확인 문구를 직접 입력해 주세요.',
      '계정 삭제 요청 접수',
      '_adminFiltersFor',
      "'보류 처리' => 'rejected'",
    ]) {
      check(
        flowScreens.path,
        source.contains(token),
        'privacy settings UI must show duplicate active request state $token',
      );
    }
  }

  if (repositoryFile.existsSync()) {
    final source = repositoryFile.readAsStringSync();
    for (final token in [
      '_mockPrivacyRequestAdminRecords',
      '_adminRecordFromPrivacyRequest',
      '_privacyRequestTypeAdminLabel',
    ]) {
      check(
        repositoryFile.path,
        source.contains(token),
        'admin privacy request records must use the actual privacy queue $token',
      );
    }
  }

  final migration =
      File('supabase/migrations/202606060017_privacy_request_operations.sql');
  check(
    migration.path,
    migration.existsSync() &&
        migration.readAsStringSync().contains(
              'privacy_requests_active_type_uidx',
            ) &&
        migration.readAsStringSync().contains(
              "where status in ('open', 'review')",
            ),
    'privacy request migration must keep active type unique index',
  );

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync() &&
        serviceTest
            .readAsStringSync()
            .contains('prevents duplicate active privacy requests'),
    'privacy request duplicate prevention must have unit coverage',
  );

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(
    widgetTest.path,
    widgetTest.existsSync() &&
        widgetTest
            .readAsStringSync()
            .contains('blocks duplicate active privacy request'),
    'privacy request duplicate prevention must have widget coverage',
  );
  check(
    widgetTest.path,
    widgetTest.existsSync() &&
        widgetTest.readAsStringSync().contains(
              'requires account deletion confirmation',
            ) &&
        widgetTest.readAsStringSync().contains('정확히 "계정 삭제"') &&
        widgetTest.readAsStringSync().contains(
            "expect(requests.single.requestType, 'account_deletion')"),
    'account deletion request must require typed confirmation widget coverage',
  );
  check(
    widgetTest.path,
    widgetTest.existsSync() &&
        widgetTest
            .readAsStringSync()
            .contains('updates privacy request status'),
    'admin privacy request status handling must have widget coverage',
  );

  final completionAudit = File('docs/20_product_completion_audit.md');
  check(
    completionAudit.path,
    completionAudit.existsSync() &&
        completionAudit.readAsStringSync().contains(
              '진행 중인 같은 유형의 개인정보 요청은 하나만 허용',
            ),
    'completion audit must document duplicate privacy request prevention',
  );
}

void _validateRemoteConfigParsing(
  void Function(String scope, bool condition, String message) check,
) {
  final servicesFile = File('lib/shared/services/app_services.dart');
  check(
    servicesFile.path,
    servicesFile.existsSync(),
    'app services file is missing',
  );
  if (servicesFile.existsSync()) {
    final source = servicesFile.readAsStringSync();
    for (final token in [
      'factory AppRemoteConfig.fromSettingsMap',
      'reward_ad_daily_limit',
      'official_drive_min_distance_km',
      'official_drive_min_duration_seconds',
      'abnormal_speed_kmh',
      'AppRemoteConfig.fromSettingsMap(map)',
      'allowDefaultFallback',
      'if (rows.isEmpty && !allowDefaultFallback)',
      'if (!allowDefaultFallback)',
      'rethrow',
    ]) {
      check(
        servicesFile.path,
        source.contains(token),
        'remote config parsing must keep $token',
      );
    }
    check(
      servicesFile.path,
      source.contains('min: 0.1') &&
          source.contains('max: 50') &&
          source.contains('min: 60') &&
          source.contains('max: 300'),
      'remote config parsing must bound drive validation settings',
    );
  }

  final providerFile = File('lib/shared/providers/repository_providers.dart');
  check(
    providerFile.path,
    providerFile.existsSync() &&
        providerFile
            .readAsStringSync()
            .contains('allowDefaultFallback: !config.isProduction'),
    'production remote config provider must disable default fallback',
  );

  final serviceTest = File('test/unit/service_completion_test.dart');
  check(
    serviceTest.path,
    serviceTest.existsSync(),
    'service completion tests missing',
  );
  if (serviceTest.existsSync()) {
    final source = serviceTest.readAsStringSync();
    for (final testName in [
      'AppRemoteConfig parses public app settings safely',
      'AppRemoteConfig falls back for out-of-range settings',
      'Production remote config never falls back to default settings',
    ]) {
      check(
        serviceTest.path,
        source.contains(testName),
        'remote config parsing must have unit coverage',
      );
    }
  }

  final analyticsDocs = File('docs/13_analytics_events.md');
  check(
    analyticsDocs.path,
    analyticsDocs.existsSync() &&
        analyticsDocs.readAsStringSync().contains('RemoteConfig') &&
        analyticsDocs
            .readAsStringSync()
            .contains('official_drive_min_distance_km'),
    'analytics docs must document RemoteConfig safety bounds',
  );
}

void _validatePublicRankingPrivacy(
  void Function(String scope, bool condition, String message) check,
) {
  final migrationFiles = _dartAndTextFiles(['supabase/migrations'])
      .where((file) => file.path.endsWith('.sql'))
      .toList();
  var viewCount = 0;
  for (final file in migrationFiles) {
    final source = file.readAsStringSync();
    for (final viewSql in _publicRankingViews(source)) {
      viewCount += 1;
      final normalized = viewSql.toLowerCase();
      for (final forbidden in [
        'drive_points',
        'latitude',
        'longitude',
        ' email',
        '.email',
      ]) {
        check(
          file.path,
          !normalized.contains(forbidden),
          'public_rankings view must not expose $forbidden',
        );
      }
    }
  }
  check(
    'supabase/migrations',
    viewCount > 0,
    'public_rankings view definition is missing',
  );
}

void _validateRivalRankingFlow(
  void Function(String scope, bool condition, String message) check,
) {
  final flowScreens =
      File('lib/features/common/presentation/flow_screens.dart');
  check(flowScreens.path, flowScreens.existsSync(), 'flow screens missing');
  if (flowScreens.existsSync()) {
    final source = flowScreens.readAsStringSync();
    for (final token in [
      'class RivalScreen extends ConsumerWidget',
      "rankingEntriesProvider('내 리그')",
      'class _RivalCard',
      '_currentRankingEntry',
      '_rivalEntriesFor',
      '닉네임, 티어, 점수, 차급, 연료 리그',
    ]) {
      check(
        flowScreens.path,
        source.contains(token),
        'rival screen must keep ranking-driven public comparison token $token',
      );
    }
    check(
      flowScreens.path,
      !source.contains("FuelArenaInfoScreen(\n      title: '라이벌'"),
      'rival screen must not return to a static info screen',
    );
  }

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(
    widgetTest.path,
    widgetTest.existsSync() &&
        widgetTest
            .readAsStringSync()
            .contains('RivalScreen renders ranking based rivals'),
    'rival screen must have widget coverage',
  );

  for (final doc in [File('docs/02_ia.md'), File('docs/06_behavior_spec.md')]) {
    check(
      doc.path,
      doc.existsSync() &&
          doc.readAsStringSync().contains('라이벌') &&
          doc.readAsStringSync().contains('추월 목표'),
      'rival docs must describe ranking based target selection',
    );
  }
}

Iterable<String> _publicRankingViews(String source) sync* {
  const needle = 'create or replace view public.public_rankings as';
  var start = 0;
  final lower = source.toLowerCase();
  while (true) {
    final index = lower.indexOf(needle, start);
    if (index < 0) return;
    final end = source.indexOf(';', index);
    if (end < 0) return;
    yield source.substring(index, end + 1);
    start = end + 1;
  }
}

void _validateRankingDetailFlow(
  void Function(String scope, bool condition, String message) check,
) {
  final screen =
      File('lib/features/ranking/presentation/ranking_detail_screen.dart');
  check(screen.path, screen.existsSync(), 'ranking detail screen is missing');
  if (screen.existsSync()) {
    final source = screen.readAsStringSync();
    for (final token in [
      'class RankingDetailScreen',
      "rankingEntriesProvider('내 리그')",
      'primaryVehicleProvider',
      '상위 랭커',
      '내 주변 순위',
      '정확한 위치와 상세 주행 경로',
    ]) {
      check(
        screen.path,
        source.contains(token),
        'ranking detail screen must keep data-driven token $token',
      );
    }
  }

  final router = File('lib/app/router.dart');
  check(router.path, router.existsSync(), 'app router is missing');
  if (router.existsSync()) {
    final source = router.readAsStringSync();
    check(
      router.path,
      source.contains('RankingDetailScreen') &&
          !source.contains(
              "path: '/ranking/detail',\n      builder: (context, state) => const FuelArenaInfoScreen"),
      'ranking detail route must use the real screen, not static info copy',
    );
  }

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(
    widgetTest.path,
    widgetTest.existsSync() &&
        widgetTest
            .readAsStringSync()
            .contains('RankingDetailScreen renders league detail'),
    'ranking detail screen must have widget coverage',
  );

  for (final doc in [File('docs/02_ia.md'), File('docs/06_behavior_spec.md')]) {
    check(
      doc.path,
      doc.existsSync() &&
          doc.readAsStringSync().contains('ranking/detail') &&
          doc.readAsStringSync().contains('주변 순위') &&
          doc.readAsStringSync().contains('공개'),
      'ranking detail docs must describe ranking/detail behavior',
    );
  }
}

void _validatePublicProfileFlow(
  void Function(String scope, bool condition, String message) check,
) {
  final flowScreens =
      File('lib/features/common/presentation/flow_screens.dart');
  check(flowScreens.path, flowScreens.existsSync(), 'flow screens missing');
  if (flowScreens.existsSync()) {
    final source = flowScreens.readAsStringSync();
    for (final token in [
      'class OtherUserProfileScreen extends ConsumerWidget',
      'publicRankingProfileProvider(userId)',
      '공개 랭킹 기록으로만 구성한 프로필',
      '원본 주행 포인트',
      "'/support/report-user/\$userId'",
    ]) {
      check(
        flowScreens.path,
        source.contains(token),
        'public profile screen must keep public ranking token $token',
      );
    }
    check(
      flowScreens.path,
      !source.contains("FuelArenaInfoScreen(\n      title: '운전자 프로필'"),
      'public profile route must not return to static info copy',
    );
  }

  final repositories =
      File('lib/shared/repositories/fuel_arena_repositories.dart');
  check(
    repositories.path,
    repositories.existsSync(),
    'fuel arena repositories file missing',
  );
  if (repositories.existsSync()) {
    final source = repositories.readAsStringSync();
    check(
      repositories.path,
      source.contains('Future<RankingEntry?> getPublicEntryByUserId') &&
          source.contains("from('public_rankings')") &&
          !source.contains("from('profiles').select().eq('id', userId)"),
      'public profile lookup must use public_rankings instead of raw profiles',
    );
  }

  final providers = File('lib/shared/providers/repository_providers.dart');
  check(
    providers.path,
    providers.existsSync() &&
        providers.readAsStringSync().contains('publicRankingProfileProvider'),
    'public ranking profile provider must exist',
  );

  final rankingScreen =
      File('lib/features/ranking/presentation/ranking_screen.dart');
  check(
    rankingScreen.path,
    rankingScreen.existsSync() &&
        rankingScreen.readAsStringSync().contains('/profile/\${entry.userId}'),
    'ranking rows must link to public profile when a public user id is available',
  );

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(
    widgetTest.path,
    widgetTest.existsSync() &&
        widgetTest.readAsStringSync().contains(
            'OtherUserProfileScreen renders public ranking profile') &&
        widgetTest
            .readAsStringSync()
            .contains('OtherUserProfileScreen missing user shows recovery'),
    'public profile screen must have widget coverage',
  );

  final unitTest = File('test/unit/mock_repositories_test.dart');
  check(
    unitTest.path,
    unitTest.existsSync() &&
        unitTest.readAsStringSync().contains(
            'Ranking repository returns public profile entry by user id'),
    'public profile repository lookup must have unit coverage',
  );

  for (final doc in [File('docs/02_ia.md'), File('docs/06_behavior_spec.md')]) {
    check(
      doc.path,
      doc.existsSync() &&
          doc.readAsStringSync().contains('/profile/:userId') &&
          doc.readAsStringSync().contains('public_rankings') &&
          doc.readAsStringSync().contains('raw drive_points'),
      'public profile docs must describe public_rankings and privacy behavior',
    );
  }
}

void _validateDrivePointRls(
  void Function(String scope, bool condition, String message) check,
) {
  final migrationSql = _dartAndTextFiles(['supabase/migrations'])
      .where((file) => file.path.endsWith('.sql'))
      .map((file) => file.readAsStringSync().toLowerCase())
      .join('\n');
  check(
    'supabase/migrations',
    migrationSql
        .contains('alter table public.drive_points enable row level security'),
    'drive_points RLS must be enabled',
  );
  check(
    'supabase/migrations',
    migrationSql.contains('drive_points_private_self'),
    'drive_points must keep a private self-only RLS policy',
  );
}

void _validateDependencyPolicy(
  void Function(String scope, bool condition, String message) check,
) {
  final file = File('pubspec.yaml');
  check(file.path, file.existsSync(), 'pubspec.yaml is missing');
  if (!file.existsSync()) return;

  final lines = file.readAsLinesSync();
  for (var i = 0; i < lines.length; i += 1) {
    final line = lines[i].trim();
    if (line.startsWith('#') || !line.endsWith(': any')) continue;
    check(
      '${file.path}:${i + 1}',
      false,
      'direct dependencies must use explicit version ranges, not any',
    );
  }
}

void _validatePlatformPermissionDeclarations(
  void Function(String scope, bool condition, String message) check,
) {
  final androidManifest = File('android/app/src/main/AndroidManifest.xml');
  check(
    androidManifest.path,
    androidManifest.existsSync(),
    'AndroidManifest.xml is missing',
  );
  if (androidManifest.existsSync()) {
    final source = androidManifest.readAsStringSync();
    for (final permission in [
      'android.permission.INTERNET',
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.ACCESS_COARSE_LOCATION',
      'android.permission.POST_NOTIFICATIONS',
    ]) {
      check(
        androidManifest.path,
        source.contains(permission),
        'Android manifest must declare $permission',
      );
    }
    for (final token in [
      'android.intent.action.VIEW',
      'android.intent.category.DEFAULT',
      'android.intent.category.BROWSABLE',
      r'android:scheme="${APP_AUTH_REDIRECT_SCHEME}"',
      r'android:host="${APP_AUTH_REDIRECT_HOST}"',
    ]) {
      check(
        androidManifest.path,
        source.contains(token),
        'Android manifest must declare OAuth callback token $token',
      );
    }
  }

  final iosInfoPlist = File('ios/Runner/Info.plist');
  check(iosInfoPlist.path, iosInfoPlist.existsSync(), 'Info.plist is missing');
  if (iosInfoPlist.existsSync()) {
    final source = iosInfoPlist.readAsStringSync();
    for (final key in [
      'CFBundleDevelopmentRegion',
      'CFBundleDisplayName',
      'CFBundleExecutable',
      'CFBundleIdentifier',
      'CFBundleInfoDictionaryVersion',
      'CFBundleName',
      'CFBundlePackageType',
      'CFBundleShortVersionString',
      'CFBundleVersion',
      'LSRequiresIPhoneOS',
      'NSLocationWhenInUseUsageDescription',
      'NSUserNotificationUsageDescription',
      'GADApplicationIdentifier',
      'GIDClientID',
      'GIDServerClientID',
      'CFBundleURLSchemes',
      'UIApplicationSupportsIndirectInputEvents',
      'UILaunchStoryboardName',
      'UIMainStoryboardFile',
      'UISupportedInterfaceOrientations',
    ]) {
      check(
        iosInfoPlist.path,
        source.contains(key),
        'iOS Info.plist must declare $key',
      );
    }
    for (final value in [
      r'$(PRODUCT_BUNDLE_IDENTIFIER)',
      r'$(FLUTTER_BUILD_NAME)',
      r'$(FLUTTER_BUILD_NUMBER)',
      r'$(ADMOB_IOS_APP_ID)',
      r'$(GOOGLE_IOS_CLIENT_ID)',
      r'$(GOOGLE_SERVER_CLIENT_ID)',
      r'$(GOOGLE_REVERSED_IOS_CLIENT_ID)',
      'fuelarena',
    ]) {
      check(
        iosInfoPlist.path,
        source.contains(value),
        'iOS Info.plist must contain $value',
      );
    }
  }

  final iosProject = File('ios/Runner.xcodeproj/project.pbxproj');
  check(
    iosProject.path,
    iosProject.existsSync(),
    'iOS Runner.xcodeproj/project.pbxproj is missing',
  );
  if (iosProject.existsSync()) {
    final source = iosProject.readAsStringSync();
    check(
      iosProject.path,
      source.contains('PRODUCT_BUNDLE_IDENTIFIER ='),
      'iOS project must declare PRODUCT_BUNDLE_IDENTIFIER',
    );
    check(
      iosProject.path,
      !source.contains('com.example'),
      'iOS bundle identifier must not use com.example',
    );
    check(
      iosProject.path,
      source.contains('PRODUCT_BUNDLE_IDENTIFIER = $_iosRunnerBundleId;'),
      'iOS project bundle identifier must be $_iosRunnerBundleId',
    );
    check(
      iosProject.path,
      !source.contains('PRODUCT_BUNDLE_IDENTIFIER = com.fuelarena.fuel_arena;'),
      'iOS project must not reuse the Android application id as bundle id',
    );
  }
}

void _validateAndroidReleaseSigning(
  void Function(String scope, bool condition, String message) check,
) {
  final buildFile = File('android/app/build.gradle.kts');
  check(
    buildFile.path,
    buildFile.existsSync(),
    'Android app build.gradle.kts is missing',
  );
  if (buildFile.existsSync()) {
    final source = buildFile.readAsStringSync();
    check(
      buildFile.path,
      source.contains('rootProject.file("key.properties")'),
      'release signing must be configured from android/key.properties',
    );
    check(
      buildFile.path,
      source.contains('create("release")'),
      'release signingConfig must be declared explicitly',
    );
    check(
      buildFile.path,
      source.contains('signingConfig = signingConfigs.getByName("release")'),
      'release build type must use the release signing config',
    );
    check(
      buildFile.path,
      !source.contains('signingConfig = signingConfigs.getByName("debug")'),
      'release build type must not use debug signing',
    );
    check(
      buildFile.path,
      source.contains('Release signing requires android/key.properties'),
      'release build must fail clearly when key.properties is missing',
    );
    check(
      buildFile.path,
      source.contains('testAdMobAndroidAppId'),
      'Android build must keep the test AdMob app id named and isolated',
    );
    check(
      buildFile.path,
      source.contains('adMobAndroidAppId.ifEmpty { testAdMobAndroidAppId }'),
      'debug builds may fallback to the test AdMob app id explicitly',
    );
    check(
      buildFile.path,
      source.contains('stringPropertyOrEnv("ADMOB_ANDROID_APP_ID")') &&
          source.contains('project.findProperty(name)') &&
          source.contains('providers.environmentVariable(name)'),
      'Android build must read ADMOB_ANDROID_APP_ID from Gradle property or environment',
    );
    check(
      buildFile.path,
      source
          .contains('Release builds require a production ADMOB_ANDROID_APP_ID'),
      'release build must fail when production ADMOB_ANDROID_APP_ID is missing',
    );
    check(
      buildFile.path,
      source.contains('stringPropertyOrEnv("APP_AUTH_REDIRECT_SCHEME")') &&
          source.contains('manifestPlaceholders["APP_AUTH_REDIRECT_SCHEME"]'),
      'Android build must provide APP_AUTH_REDIRECT_SCHEME manifest placeholder',
    );
    check(
      buildFile.path,
      source.contains('stringPropertyOrEnv("APP_AUTH_REDIRECT_HOST")') &&
          source.contains('manifestPlaceholders["APP_AUTH_REDIRECT_HOST"]'),
      'Android build must provide APP_AUTH_REDIRECT_HOST manifest placeholder',
    );
  }

  final ignoreFile = File('android/.gitignore');
  check(ignoreFile.path, ignoreFile.existsSync(),
      'android/.gitignore is missing');
  if (ignoreFile.existsSync()) {
    final source = ignoreFile.readAsStringSync();
    check(
      ignoreFile.path,
      source.contains('key.properties'),
      'android/key.properties must be ignored',
    );
    check(
      ignoreFile.path,
      source.contains('**/*.jks') && source.contains('**/*.keystore'),
      'Android keystore files must be ignored',
    );
  }

  final exampleFile = File('android/key.properties.example');
  check(
    exampleFile.path,
    exampleFile.existsSync(),
    'android/key.properties.example is required for release signing setup',
  );
  if (exampleFile.existsSync()) {
    final source = exampleFile.readAsStringSync();
    for (final key in [
      'storeFile',
      'storePassword',
      'keyAlias',
      'keyPassword'
    ]) {
      check(
        exampleFile.path,
        source.contains('$key='),
        'key.properties.example must include $key',
      );
    }
  }
}

void _validateIosReleaseConfig(
  void Function(String scope, bool condition, String message) check,
) {
  for (final path in [
    'ios/Flutter/Debug.xcconfig',
    'ios/Flutter/Release.xcconfig',
  ]) {
    final file = File(path);
    check(file.path, file.existsSync(), '$path is missing');
    if (!file.existsSync()) continue;
    final source = file.readAsStringSync();
    check(
      file.path,
      source.contains('#include? "FuelArenaSecrets.xcconfig"'),
      '$path must optionally include FuelArenaSecrets.xcconfig',
    );
  }

  final exampleFile = File('ios/Flutter/FuelArenaSecrets.xcconfig.example');
  check(
    exampleFile.path,
    exampleFile.existsSync(),
    'iOS FuelArenaSecrets.xcconfig.example is required',
  );
  if (exampleFile.existsSync()) {
    final source = exampleFile.readAsStringSync();
    for (final key in [
      'ADMOB_IOS_APP_ID',
      'GOOGLE_IOS_CLIENT_ID',
      'GOOGLE_SERVER_CLIENT_ID',
      'GOOGLE_REVERSED_IOS_CLIENT_ID',
    ]) {
      check(
        exampleFile.path,
        source.contains('$key ='),
        'iOS secrets example must include $key',
      );
    }
    check(
      exampleFile.path,
      source.contains(
            'GOOGLE_REVERSED_IOS_CLIENT_ID = com.googleusercontent.apps.replace-with-ios-client-id',
          ) &&
          !source.contains('replace-with-reversed-ios-client-id'),
      'iOS secrets example must show reversed client ID derived from GOOGLE_IOS_CLIENT_ID',
    );
  }

  final ignoreFile = File('ios/.gitignore');
  check(ignoreFile.path, ignoreFile.existsSync(), 'ios/.gitignore is missing');
  if (ignoreFile.existsSync()) {
    final source = ignoreFile.readAsStringSync();
    check(
      ignoreFile.path,
      source.contains('Flutter/FuelArenaSecrets.xcconfig'),
      'iOS local secrets xcconfig must be ignored',
    );
  }
}

void _validateReleaseReadinessArtifacts(
  void Function(String scope, bool condition, String message) check,
) {
  final workflow = File('.github/workflows/flutter_ci.yml');
  check(
    workflow.path,
    workflow.existsSync(),
    'Flutter CI workflow is required for release readiness',
  );
  if (workflow.existsSync()) {
    final source = workflow.readAsStringSync();
    for (final command in [
      'flutter pub get',
      'python -m pip install -r requirements-dev.txt',
      'dart run tool/validate_vehicle_catalog.dart',
      'dart run tool/validate_edge_functions.dart',
      'dart run tool/validate_supabase_schema.dart',
      'dart run tool/validate_product_invariants.dart',
      'python tool/validate_store_submission_assets.py',
      'python tool/validate_store_privacy_disclosures.py',
      'python tool/validate_secret_hygiene.py',
      'python tool/validate_release_environment_selftest.py',
      'python tool/validate_release_native_sources.py',
      'python tool/validate_release_example_placeholders.py',
      'python tool/run_web_smoke.py',
      'dart format --set-exit-if-changed .',
      'flutter analyze',
      'flutter test',
      'flutter build apk --debug',
      'flutter build web --wasm',
      'flutter build web',
    ]) {
      check(
        workflow.path,
        source.contains(command),
        'Flutter CI workflow must run "$command"',
      );
    }
    check(
      workflow.path,
      !source.contains('--pwa-strategy'),
      'Flutter CI must not use deprecated --pwa-strategy',
    );
    check(
      workflow.path,
      !source.contains('sleep 2'),
      'Flutter CI web smoke must wait for server readiness, not fixed sleep',
    );
    final wasmBuildIndex = source.indexOf('flutter build web --wasm');
    final webBuildIndex =
        source.indexOf('flutter build web', wasmBuildIndex + 1);
    final webSmokeOccurrences =
        source.split('python tool/run_web_smoke.py').length - 1;
    check(
      workflow.path,
      webSmokeOccurrences >= 2,
      'Flutter CI must run web smoke after both Wasm and CanvasKit builds',
    );
    check(
      workflow.path,
      wasmBuildIndex >= 0 &&
          source.indexOf('python tool/run_web_smoke.py', wasmBuildIndex) >
              wasmBuildIndex,
      'Flutter CI must smoke test the Wasm compatibility build',
    );
    check(
      workflow.path,
      webBuildIndex > wasmBuildIndex &&
          source.indexOf('python tool/run_web_smoke.py', webBuildIndex) >
              webBuildIndex,
      'Flutter CI must smoke test the final Web runtime build',
    );
  }

  final localReleaseGate = File('tool/run_local_release_gate.py');
  check(
    localReleaseGate.path,
    localReleaseGate.existsSync(),
    'local release gate tool is required',
  );
  if (localReleaseGate.existsSync()) {
    final source = localReleaseGate.readAsStringSync();
    for (final token in [
      'validate_vehicle_catalog.dart',
      'requirements-dev.txt',
      '-m',
      'pip',
      'install',
      'validate_edge_functions.dart',
      'validate_supabase_schema.dart',
      'validate_product_invariants.dart',
      'validate_store_submission_assets.py',
      'validate_store_privacy_disclosures.py',
      'validate_secret_hygiene.py',
      'validate_release_environment_selftest.py',
      'validate_release_native_sources.py',
      'Release native source validation',
      'validate_release_example_placeholders.py',
      'Release example placeholder rejection',
      'Secret hygiene validation',
      'run_web_smoke.py',
      'Web Wasm compatibility smoke',
      'Web runtime smoke',
      'format',
      'analyze',
      'test',
      'build',
      '6173',
    ]) {
      check(
        localReleaseGate.path,
        source.contains(token),
        'local release gate must mirror CI and avoid stale web smoke token $token',
      );
    }
    check(
      localReleaseGate.path,
      !source.contains('--pwa-strategy'),
      'local release gate must not use deprecated --pwa-strategy',
    );
    for (final command in [
      '_run("Build Android debug", [flutter, "build", "apk", "--debug"])',
      '"Build web Wasm compatibility"',
      '[flutter, "build", "web", "--wasm"]',
      '_web_smoke(python, "Web Wasm compatibility smoke", args.port)',
      '_run("Build web", [flutter, "build", "web"])',
      '_web_smoke(python, "Web runtime smoke", args.port)',
    ]) {
      check(
        localReleaseGate.path,
        source.contains(command),
        'local release gate must keep exact full-gate command $command',
      );
    }
  }

  final secretHygieneTool = File('tool/validate_secret_hygiene.py');
  check(
    secretHygieneTool.path,
    secretHygieneTool.existsSync(),
    'secret hygiene validator is required',
  );
  if (secretHygieneTool.existsSync()) {
    final source = secretHygieneTool.readAsStringSync();
    for (final token in [
      'git',
      'ls-files',
      '--others',
      '--exclude-standard',
      'check-ignore',
      'FORBIDDEN_TRACKED_NAMES',
      'FORBIDDEN_TRACKED_SUFFIXES',
      'REQUIRED_GITIGNORE_TOKENS',
      'SECRET_IGNORE_CANDIDATES',
      'FuelArenaSecrets.xcconfig',
      'google-services.json',
      'GoogleService-Info.plist',
      '*.p8',
      '*.mobileprovision',
      'secret hygiene valid',
    ]) {
      check(
        secretHygieneTool.path,
        source.contains(token),
        'secret hygiene validator must keep $token',
      );
    }
  }

  final edgeFunctionTool = File('tool/validate_edge_functions.dart');
  check(
    edgeFunctionTool.path,
    edgeFunctionTool.existsSync(),
    'edge function validator is required',
  );
  if (edgeFunctionTool.existsSync()) {
    final source = edgeFunctionTool.readAsStringSync();
    for (final token in [
      'Access-Control-Allow-Origin',
      'CORS preflight must send Access-Control-Allow-Origin',
      'Access-Control-Allow-Headers',
      'x-idempotency-key',
      'CORS preflight must allow x-idempotency-key',
    ]) {
      check(
        edgeFunctionTool.path,
        source.contains(token),
        'edge function validator must keep CORS check token $token',
      );
    }
  }

  const requiredReleaseDocPaths = [
    'README.md',
    'AGENTS.md',
    'docs/00_project_overview.md',
    'docs/01_prd.md',
    'docs/02_ia.md',
    'docs/03_ui_ux_design_guide.md',
    'docs/04_data_schema.md',
    'docs/05_frontend_architecture.md',
    'docs/06_behavior_spec.md',
    'docs/07_supabase_setup.md',
    'docs/08_rls_policy_notes.md',
    'docs/09_release_checklist.md',
    'docs/10_completion_audit.md',
    'docs/11_accessibility_checklist.md',
    'docs/12_performance_notes.md',
    'docs/13_analytics_events.md',
    'docs/14_rls_test_plan.md',
    'docs/15_product_gap_audit.md',
    'docs/16_vehicle_catalog_guide.md',
    'docs/17_mobile_layout_guide.md',
    'docs/18_empty_state_guide.md',
    'docs/19_vehicle_catalog_import_format.md',
    'docs/20_product_completion_audit.md',
    'docs/21_production_runbook.md',
  ];
  for (final path in requiredReleaseDocPaths) {
    final file = File(path);
    check(path, file.existsSync(), 'release documentation is missing');
  }

  final documentationFiles = <File>[
    File('README.md'),
    File('AGENTS.md'),
    ...Directory('docs')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.replaceAll('\\', '/').endsWith('.md')),
  ]..sort((a, b) => a.path.compareTo(b.path));
  for (final file in documentationFiles) {
    final path = file.path.replaceAll('\\', '/');
    if (!file.existsSync()) {
      continue;
    }
    final source = file.readAsStringSync();
    check(
      path,
      !_mojibakeTokens.any(source.contains),
      'release documentation must not contain mojibake text',
    );
  }

  for (final path in [
    'README.md',
    'docs/09_release_checklist.md',
    'docs/15_product_gap_audit.md',
    'docs/20_product_completion_audit.md',
  ]) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    final source = file.readAsStringSync();
    check(
      path,
      source.contains('python tool/run_local_release_gate.py'),
      'release docs must document the local release gate',
    );
  }

  final agentGuide = File('AGENTS.md');
  if (agentGuide.existsSync()) {
    final source = agentGuide.readAsStringSync();
    for (final token in [
      'Web/Android/iOS/Server Google OAuth client ID',
      'iOS reversed client ID',
      'fuelarena://login-callback',
      '설정 오류 화면',
    ]) {
      check(
        agentGuide.path,
        source.contains(token),
        'AGENTS.md production rule must mention $token',
      );
    }
  }

  final productGapAudit = File('docs/15_product_gap_audit.md');
  if (productGapAudit.existsSync()) {
    final source = productGapAudit.readAsStringSync();
    check(
      productGapAudit.path,
      source.contains('코드 안에서 닫은 주요 리스크') &&
          source.contains('운영 검증 우선순위') &&
          source.contains('현재 결론'),
      'product gap audit must clearly separate closed code risks and external validation',
    );
  }

  final releaseChecklist = File('docs/09_release_checklist.md');
  if (releaseChecklist.existsSync()) {
    final source = releaseChecklist.readAsStringSync();
    check(
      releaseChecklist.path,
      source.contains('App Store Bundle ID `$_iosRunnerBundleId`') &&
          source.contains('PRODUCT_BUNDLE_IDENTIFIER'),
      'release checklist must pin App Store Bundle ID to iOS project bundle id',
    );
  }

  final runbook = File('docs/21_production_runbook.md');
  if (runbook.existsSync()) {
    final source = runbook.readAsStringSync();
    for (final token in [
      'supabase db push',
      'supabase functions deploy',
      'Google OAuth',
      'AdMob',
      'IAP',
      'ADMOB_ANDROID_APP_ID',
      'android/key.properties',
      'GOOGLE_ANDROID_RELEASE_SHA1',
      'GOOGLE_ANDROID_RELEASE_SHA256',
      'GOOGLE_REVERSED_IOS_CLIENT_ID',
      "APP_STORE_BUNDLE_ID='$_iosRunnerBundleId'",
      'iOS Bundle ID `$_iosRunnerBundleId`',
    ]) {
      check(
        runbook.path,
        source.contains(token),
        'production runbook must mention "$token"',
      );
    }
    for (final token in [
      '- `GOOGLE_WEB_CLIENT_ID`',
      '- `GOOGLE_ANDROID_CLIENT_ID`',
      '- `GOOGLE_ANDROID_RELEASE_PACKAGE_NAME`',
      '- `GOOGLE_ANDROID_RELEASE_SHA1`',
      '- `GOOGLE_ANDROID_RELEASE_SHA256`',
      '- `GOOGLE_IOS_CLIENT_ID`',
      '- `GOOGLE_SERVER_CLIENT_ID`',
      '- `GOOGLE_REVERSED_IOS_CLIENT_ID`',
      '- `APP_AUTH_REDIRECT_SCHEME`',
      '- `APP_AUTH_REDIRECT_HOST`',
      '- `ADMOB_REWARDED_ANDROID_UNIT_ID`',
      '- `ADMOB_REWARDED_IOS_UNIT_ID`',
      '- `ADMOB_NATIVE_ANDROID_UNIT_ID`',
      '- `ADMOB_NATIVE_IOS_UNIT_ID`',
      '- `ADMOB_INTERSTITIAL_ANDROID_UNIT_ID`',
      '- `ADMOB_INTERSTITIAL_IOS_UNIT_ID`',
      '- `IAP_PREMIUM_MONTHLY_ID`',
      '- `IAP_PREMIUM_YEARLY_ID`',
      '- `IAP_SEASON_PASS_ID`',
      '- `IAP_PREMIUM_BUNDLE_ID`',
    ]) {
      check(
        runbook.path,
        source.contains(token),
        'production runbook required env list must include $token',
      );
    }
    final functionNames = <String>[];
    final functionsDirectory = Directory('supabase/functions');
    if (functionsDirectory.existsSync()) {
      functionNames.addAll(
        functionsDirectory
            .listSync()
            .whereType<Directory>()
            .map((directory) => directory.uri.pathSegments
                .where((segment) => segment.isNotEmpty)
                .last)
            .where((name) => !name.startsWith('_')),
      );
    }
    for (final functionName in functionNames..sort()) {
      check(
        runbook.path,
        source.contains('supabase functions deploy $functionName'),
        'production runbook must deploy Edge Function $functionName',
      );
    }
  }

  final envExample = File('.env.example');
  if (envExample.existsSync()) {
    final source = envExample.readAsStringSync();
    for (final key in [
      'APP_ENV',
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
      'GOOGLE_WEB_CLIENT_ID',
      'GOOGLE_ANDROID_CLIENT_ID',
      'GOOGLE_ANDROID_RELEASE_PACKAGE_NAME',
      'GOOGLE_ANDROID_RELEASE_SHA1',
      'GOOGLE_ANDROID_RELEASE_SHA256',
      'GOOGLE_IOS_CLIENT_ID',
      'GOOGLE_SERVER_CLIENT_ID',
      'GOOGLE_REVERSED_IOS_CLIENT_ID',
      'APP_AUTH_REDIRECT_SCHEME',
      'APP_AUTH_REDIRECT_HOST',
      'ADMOB_ANDROID_APP_ID',
      'ADMOB_IOS_APP_ID',
      'IAP_PREMIUM_MONTHLY_ID',
      'IAP_PREMIUM_YEARLY_ID',
      'IAP_SEASON_PASS_ID',
      'IAP_PREMIUM_BUNDLE_ID',
    ]) {
      check(
        envExample.path,
        RegExp('^$key=', multiLine: true).hasMatch(source),
        '.env.example must include $key',
      );
    }
    check(
      envExample.path,
      source.contains('# APP_STORE_BUNDLE_ID=$_iosRunnerBundleId'),
      '.env.example Edge-only App Store Bundle ID comment must match iOS bundle id',
    );
    check(
      envExample.path,
      !source.contains('# APP_STORE_BUNDLE_ID=com.fuelarena.fuel_arena'),
      '.env.example must not show the Android application id as the App Store bundle id',
    );
  }

  final gitignore = File('.gitignore');
  check(gitignore.path, gitignore.existsSync(), '.gitignore is missing');
  if (gitignore.existsSync()) {
    final source = gitignore.readAsStringSync();
    for (final pattern in [
      '.env',
      '.env.*',
      'build/',
      'coverage/',
      '*.log',
    ]) {
      check(
        gitignore.path,
        source.contains(pattern),
        '.gitignore must ignore $pattern',
      );
    }
  }
}

void _validateWebReleaseMetadata(
  void Function(String scope, bool condition, String message) check,
) {
  final manifest = File('web/manifest.json');
  check(manifest.path, manifest.existsSync(), 'web manifest is missing');
  if (manifest.existsSync()) {
    final source = manifest.readAsStringSync();
    check(
      manifest.path,
      source.contains('"name": "Fuel Arena"') &&
          source.contains('"short_name": "Fuel Arena"'),
      'web manifest must use Fuel Arena product name',
    );
    check(
      manifest.path,
      source.contains('게임형 드라이빙 플랫폼'),
      'web manifest must use Fuel Arena product description',
    );
    check(
      manifest.path,
      !source.contains('A new Flutter project.') &&
          !source.contains('"fuel_arena"') &&
          !source.contains('#0175C2'),
      'web manifest must not keep Flutter template metadata',
    );
  }

  final index = File('web/index.html');
  check(index.path, index.existsSync(), 'web index.html is missing');
  if (index.existsSync()) {
    final source = index.readAsStringSync();
    check(
      index.path,
      source.contains('<title>Fuel Arena</title>') &&
          source.contains('apple-mobile-web-app-title" content="Fuel Arena"'),
      'web index must use Fuel Arena product title',
    );
    check(
      index.path,
      source.contains(
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
      ),
      'web index must keep viewport width pinned to device width',
    );
    for (final token in [
      'overflow: hidden;',
      'flutter-view',
      'flt-glass-pane',
      'width: 100vw !important;',
      'height: 100vh !important;',
      'max-width: 100vw;',
      'max-height: 100vh;',
    ]) {
      check(
        index.path,
        source.contains(token),
        'web index must constrain Flutter web host viewport $token',
      );
    }
    check(
      index.path,
      source.contains('연비와 주행 효율로 경쟁하는 게임형 드라이빙 플랫폼 Fuel Arena'),
      'web index must use Fuel Arena product description',
    );
    check(
      index.path,
      !source.contains('A new Flutter project.') &&
          !source.contains('<title>fuel_arena</title>') &&
          !source.contains('content="fuel_arena"'),
      'web index must not keep Flutter template metadata',
    );
  }
}

void _validateBrandAssets(
  void Function(String scope, bool condition, String message) check,
) {
  final generator = File('tool/generate_brand_assets.py');
  check(generator.path, generator.existsSync(),
      'brand asset generator is missing');
  if (generator.existsSync()) {
    final source = generator.readAsStringSync();
    for (final token in [
      'fuel_arena_icon_1024.png',
      'fuel_arena_mark.png',
      'android_icons(source)',
      'ios_icons(source)',
      'web_icons(source)',
    ]) {
      check(
        generator.path,
        source.contains(token),
        'brand asset generator must cover $token',
      );
    }
  }

  final pubspec = File('pubspec.yaml');
  check(pubspec.path, pubspec.existsSync(), 'pubspec.yaml is missing');
  if (pubspec.existsSync()) {
    check(
      pubspec.path,
      pubspec.readAsStringSync().contains('- assets/brand/'),
      'pubspec must bundle Fuel Arena brand assets',
    );
  }

  final splash = File('lib/features/splash/presentation/splash_screen.dart');
  check(splash.path, splash.existsSync(), 'splash screen is missing');
  if (splash.existsSync()) {
    final source = splash.readAsStringSync();
    check(
      splash.path,
      source.contains('Image.asset(') &&
          source.contains('assets/brand/fuel_arena_mark.png'),
      'Flutter splash screen must render the Fuel Arena brand mark asset',
    );
  }

  for (final asset in {
    'assets/brand/fuel_arena_icon_1024.png': 100000,
    'assets/brand/fuel_arena_mark.png': 60000,
    'web/favicon.png': 1000,
    'web/icons/Icon-192.png': 10000,
    'web/icons/Icon-512.png': 60000,
    'web/icons/Icon-maskable-192.png': 10000,
    'web/icons/Icon-maskable-512.png': 60000,
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 2000,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 10000,
    'android/app/src/main/res/drawable-nodpi/launch_mark.png': 30000,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png':
        100000,
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png': 30000,
  }.entries) {
    final file = File(asset.key);
    check(file.path, file.existsSync(), 'brand asset ${asset.key} is missing');
    if (file.existsSync()) {
      check(
        file.path,
        file.lengthSync() >= asset.value,
        'brand asset ${asset.key} is too small and may be a template placeholder',
      );
    }
  }

  for (final path in [
    'android/app/src/main/res/drawable/launch_background.xml',
    'android/app/src/main/res/drawable-v21/launch_background.xml',
  ]) {
    final file = File(path);
    check(file.path, file.existsSync(), '$path is missing');
    if (file.existsSync()) {
      final source = file.readAsStringSync();
      check(
        file.path,
        source.contains('#07140F') && source.contains('@drawable/launch_mark'),
        'Android launch background must use the Fuel Arena splash background and mark',
      );
      check(
        file.path,
        !source.contains('@android:color/white') &&
            !source.contains('Modify this file to customize'),
        'Android launch background must not keep Flutter template splash content',
      );
    }
  }

  final launchStoryboard =
      File('ios/Runner/Base.lproj/LaunchScreen.storyboard');
  check(launchStoryboard.path, launchStoryboard.existsSync(),
      'iOS launch storyboard is missing');
  if (launchStoryboard.existsSync()) {
    final source = launchStoryboard.readAsStringSync();
    check(
      launchStoryboard.path,
      source.contains('image="LaunchImage"') &&
          source.contains('0.027450980392156862') &&
          source.contains('contentMode="scaleAspectFit"'),
      'iOS launch storyboard must use the Fuel Arena launch image on brand background',
    );
  }
}

void _validateLegalDisclosureArtifacts(
  void Function(String scope, bool condition, String message) check,
) {
  final loginScreen = File('lib/features/auth/presentation/login_screen.dart');
  check(
    loginScreen.path,
    loginScreen.existsSync(),
    'login screen source is missing',
  );
  if (loginScreen.existsSync()) {
    final source = loginScreen.readAsStringSync();
    for (final token in [
      '가입 전 문서를 먼저 확인할 수 있어요.',
      "'약관 보기'",
      "'개인정보 보기'",
      "'위치정보 보기'",
      "route: '/legal/terms'",
      "route: '/legal/privacy'",
      "route: '/legal/location'",
      'GoRouter.of(context).push(route)',
    ]) {
      check(
        loginScreen.path,
        source.contains(token),
        'login screen must expose public legal document link $token',
      );
    }
  }

  final router = File('lib/app/router.dart');
  check(router.path, router.existsSync(), 'app router is missing');
  if (router.existsSync()) {
    final source = router.readAsStringSync();
    check(
      router.path,
      source.contains("path: '/legal/:document'") &&
          source.contains('LegalDocumentScreen('),
      'app router must expose legal disclosure routes',
    );
  }

  final legalScreen =
      File('lib/features/common/presentation/flow_screens.dart');
  check(legalScreen.path, legalScreen.existsSync(),
      'legal disclosure screen source is missing');
  if (legalScreen.existsSync()) {
    final source = legalScreen.readAsStringSync();
    for (final token in [
      'class LegalDocumentScreen',
      "'terms'",
      "'location'",
      "'account-deletion'",
      '개인정보 처리방침',
      '위치정보 이용 고지',
      '계정 및 데이터 삭제',
      '정확한 위치 좌표와 raw drive_points는 공개 화면에 노출하지 않습니다',
      'service_role key와 결제 검증 secret은 Flutter 앱에 포함하지 않습니다',
      "context.push('/legal/privacy')",
      "context.push('/legal/location')",
      "context.push('/legal/account-deletion')",
    ]) {
      check(
        legalScreen.path,
        source.contains(token),
        'legal disclosure screen must keep $token',
      );
    }
  }

  final widgetTest = File('test/widget/flow_screens_test.dart');
  check(widgetTest.path, widgetTest.existsSync(),
      'flow screen widget tests are missing');
  if (widgetTest.existsSync()) {
    final source = widgetTest.readAsStringSync();
    for (final token in [
      'LoginScreen opens public legal documents before login',
      "'개인정보 보기'",
      '필요한 데이터만 수집하고 공개 범위를 제한합니다',
      "_RouteSmokeCase('/legal/terms', '연비 경쟁을 안전하고 공정하게')",
      "_RouteSmokeCase('/legal/privacy', '필요한 데이터만 수집하고')",
      "_RouteSmokeCase('/legal/location', '위치는 주행 검증에만')",
      "_RouteSmokeCase('/legal/account-deletion', '삭제 요청은 운영 큐에서')",
    ]) {
      check(
        widgetTest.path,
        source.contains(token),
        'legal disclosure routes must have widget smoke coverage $token',
      );
    }
  }

  for (final entry in {
    'web/legal/privacy/index.html': [
      'Fuel Arena 개인정보 처리방침',
      'raw drive_points는 공개 화면에 노출하지 않습니다',
      'service_role key',
    ],
    'web/legal/location/index.html': [
      'Fuel Arena 위치정보 이용 고지',
      '정확한 좌표와 원본 주행 포인트는 공개 화면에 노출하지 않습니다',
      '모의 위치',
    ],
    'web/legal/account-deletion/index.html': [
      'Fuel Arena 계정 및 데이터 삭제 안내',
      'privacy_requests 운영 큐',
      '계정 삭제가 완료되면',
    ],
    'web/legal/terms/index.html': [
      'Fuel Arena 서비스 이용약관',
      '현금성 배틀 보상은 제공하지 않으며',
      '주행 중에는 광고, 팝업, 도전장',
    ],
  }.entries) {
    final file = File(entry.key);
    check(file.path, file.existsSync(), '${entry.key} is missing');
    if (file.existsSync()) {
      final source = file.readAsStringSync();
      check(
        file.path,
        source.contains('<html lang="ko">') &&
            source.contains('시행일 2026.06.06') &&
            source.contains('<meta name="viewport"'),
        '${entry.key} must be a Korean public legal HTML page',
      );
      for (final token in entry.value) {
        check(
          file.path,
          source.contains(token),
          '${entry.key} must contain $token',
        );
      }
    }
  }
}

void _validateStoreListingAssets(
  void Function(String scope, bool condition, String message) check,
) {
  final generator = File('tool/generate_store_assets.py');
  check(generator.path, generator.existsSync(),
      'store listing asset generator is missing');
  if (generator.existsSync()) {
    final source = generator.readAsStringSync();
    for (final token in [
      'feature_graphic_1024x500.png',
      'store_listing_ko.json',
      '01_home_league.png',
      '02_vehicle_catalog.png',
      '03_drive_score.png',
      '04_battle_season.png',
      '05_privacy_fairness.png',
      'raw drive_points는 공개 화면에 노출하지 않습니다',
      '주행 중에는 광고, 팝업, 도전장',
    ]) {
      check(
        generator.path,
        source.contains(token),
        'store listing generator must keep $token',
      );
    }
  }

  final listing = File('assets/store/store_listing_ko.json');
  check(listing.path, listing.existsSync(),
      'Korean store listing copy is missing');
  if (listing.existsSync()) {
    final source = listing.readAsStringSync();
    for (final token in [
      '"app_name": "Fuel Arena"',
      '연비와 주행 효율로 경쟁하는 게임형 드라이빙 플랫폼',
      '차량 제조사, 모델, 기준 연식, 엔진·미션 파워트레인',
      'raw drive_points는 공개 화면에 노출하지 않습니다',
      '/legal/privacy/',
      '/legal/location/',
      '/legal/account-deletion/',
      '/legal/terms/',
      'assets/store/screenshots/phone/01_home_league.png',
      'assets/store/feature_graphic_1024x500.png',
    ]) {
      check(
        listing.path,
        source.contains(token),
        'Korean store listing copy must keep $token',
      );
    }
  }

  final feature = File('assets/store/feature_graphic_1024x500.png');
  _checkPngAsset(
    check,
    feature,
    expectedWidth: 1024,
    expectedHeight: 500,
    minimumBytes: 25000,
  );

  for (final name in [
    '01_home_league.png',
    '02_vehicle_catalog.png',
    '03_drive_score.png',
    '04_battle_season.png',
    '05_privacy_fairness.png',
  ]) {
    _checkPngAsset(
      check,
      File('assets/store/screenshots/phone/$name'),
      expectedWidth: 1080,
      expectedHeight: 1920,
      minimumBytes: 120000,
    );
  }

  final docs = File('docs/22_store_listing_assets.md');
  check(docs.path, docs.existsSync(), 'store listing asset guide is missing');
  if (docs.existsSync()) {
    final source = docs.readAsStringSync();
    for (final token in [
      'python tool/generate_store_assets.py',
      'assets/store/store_listing_ko.json',
      'assets/store/feature_graphic_1024x500.png',
      '/legal/privacy/',
      'raw drive_points',
    ]) {
      check(
        docs.path,
        source.contains(token),
        'store listing asset guide must document $token',
      );
    }
  }
}

void _validateStoreSubmissionPreflightTool(
  void Function(String scope, bool condition, String message) check,
) {
  final tool = File('tool/validate_store_submission_assets.py');
  check(tool.path, tool.existsSync(),
      'store submission preflight tool is missing');
  if (tool.existsSync()) {
    final source = tool.readAsStringSync();
    for (final token in [
      'store_listing_ko.json',
      'REQUIRED_LEGAL_ROUTES',
      'LEGAL_ROUTE_CONTENT_TOKENS',
      'REQUIRED_SCREENSHOTS',
      'FEATURE_GRAPHIC',
      'MOJIBAKE_RE',
      'HANGUL_RE',
      'from PIL import Image',
      'inspect_png_content',
      'min_color_buckets',
      'min_ui_ratio',
      'has too few color buckets',
      'has too little visible UI/text contrast',
      'does not look like the expected Fuel Arena legal page',
      '주행 효율을 게임처럼 비교',
      '--base-url',
      'store submission assets valid',
    ]) {
      check(
        tool.path,
        source.contains(token),
        'store submission preflight tool must keep $token',
      );
    }
  }

  final workflow = File('.github/workflows/flutter_ci.yml');
  check(
    workflow.path,
    workflow.existsSync() &&
        workflow
            .readAsStringSync()
            .contains('python tool/validate_store_submission_assets.py'),
    'CI must run store submission asset validation',
  );

  final readme = File('README.md');
  check(
    readme.path,
    readme.existsSync() &&
        readme
            .readAsStringSync()
            .contains('python tool/validate_store_submission_assets.py') &&
        readme.readAsStringSync().contains('스토어 등록용 한국어 문구가 UTF-8/Hangul 상태인지'),
    'README must document store submission asset validation',
  );

  final checklist = File('docs/09_release_checklist.md');
  check(
    checklist.path,
    checklist.existsSync() &&
        checklist
            .readAsStringSync()
            .contains('python tool/validate_store_submission_assets.py') &&
        checklist.readAsStringSync().contains('--base-url'),
    'release checklist must include store submission asset validation',
  );

  final guide = File('docs/22_store_listing_assets.md');
  check(
    guide.path,
    guide.existsSync() &&
        guide
            .readAsStringSync()
            .contains('python tool/validate_store_submission_assets.py') &&
        guide.readAsStringSync().contains('--base-url https://example.com'),
    'store listing guide must document store submission preflight',
  );
}

void _validateStorePrivacyDisclosureArtifacts(
  void Function(String scope, bool condition, String message) check,
) {
  final disclosure = File('assets/store/privacy_disclosures_ko.json');
  check(
    disclosure.path,
    disclosure.existsSync(),
    'store privacy disclosure JSON is missing',
  );
  if (disclosure.existsSync()) {
    final source = disclosure.readAsStringSync();
    for (final token in [
      'Fuel Arena',
      'raw drive_points는 공개',
      'NSPrivacyCollectedDataTypePreciseLocation',
      'NSPrivacyCollectedDataTypeUserID',
      'Google AdMob',
      'Google OAuth',
      'Apple App Store / Google Play',
      '/legal/privacy/',
    ]) {
      check(
        disclosure.path,
        source.contains(token),
        'store privacy disclosure JSON must keep $token',
      );
    }
  }

  final iosPrivacy = File('ios/Runner/PrivacyInfo.xcprivacy');
  check(
    iosPrivacy.path,
    iosPrivacy.existsSync(),
    'iOS PrivacyInfo.xcprivacy is missing',
  );
  if (iosPrivacy.existsSync()) {
    final source = iosPrivacy.readAsStringSync();
    for (final token in [
      '<key>NSPrivacyTracking</key>',
      '<false/>',
      'NSPrivacyCollectedDataTypePreciseLocation',
      'NSPrivacyCollectedDataTypeCoarseLocation',
      'NSPrivacyCollectedDataTypePurchaseHistory',
      'NSPrivacyCollectedDataTypeAdvertisingData',
      'NSPrivacyAccessedAPICategoryUserDefaults',
      '<string>CA92.1</string>',
    ]) {
      check(
        iosPrivacy.path,
        source.contains(token),
        'iOS privacy manifest must keep $token',
      );
    }
  }

  final xcodeProject = File('ios/Runner.xcodeproj/project.pbxproj');
  check(
    xcodeProject.path,
    xcodeProject.existsSync() &&
        xcodeProject
            .readAsStringSync()
            .contains('PrivacyInfo.xcprivacy in Resources'),
    'iOS Runner target must include PrivacyInfo.xcprivacy in resources',
  );

  final iosInfo = File('ios/Runner/Info.plist');
  check(
    iosInfo.path,
    iosInfo.existsSync() &&
        iosInfo.readAsStringSync().contains('NSUserTrackingUsageDescription') &&
        iosInfo.readAsStringSync().contains('개인 맞춤 광고'),
    'iOS Info.plist must include Korean tracking usage disclosure',
  );

  final androidManifest = File('android/app/src/main/AndroidManifest.xml');
  check(
    androidManifest.path,
    androidManifest.existsSync() &&
        androidManifest
            .readAsStringSync()
            .contains('com.google.android.gms.permission.AD_ID'),
    'Android manifest must declare AD_ID permission for ads data safety',
  );

  final tool = File('tool/validate_store_privacy_disclosures.py');
  check(
    tool.path,
    tool.existsSync(),
    'store privacy disclosure validator is missing',
  );
  if (tool.existsSync()) {
    final source = tool.readAsStringSync();
    for (final token in [
      'REQUIRED_APPLE_TYPES',
      'REQUIRED_PLAY_CATEGORIES',
      'MOJIBAKE_RE',
      'HANGUL_RE',
      'validate_no_mojibake_tree',
      'validate_korean_text',
      'contains mojibake or non-Korean CJK glyphs',
      'PrivacyInfo.xcprivacy',
      'NSUserTrackingUsageDescription',
      'com.google.android.gms.permission.AD_ID',
      'store privacy disclosures valid',
    ]) {
      check(
        tool.path,
        source.contains(token),
        'store privacy disclosure validator must keep $token',
      );
    }
  }

  final docs = File('docs/23_store_privacy_disclosures.md');
  check(
    docs.path,
    docs.existsSync() &&
        docs
            .readAsStringSync()
            .contains('python tool/validate_store_privacy_disclosures.py') &&
        docs.readAsStringSync().contains('PrivacyInfo.xcprivacy') &&
        docs.readAsStringSync().contains('Android Data Safety') &&
        docs.readAsStringSync().contains('AdMob/Google SDK'),
    'store privacy disclosure guide must document the validation flow',
  );

  final workflow = File('.github/workflows/flutter_ci.yml');
  check(
    workflow.path,
    workflow.existsSync() &&
        workflow
            .readAsStringSync()
            .contains('python tool/validate_store_privacy_disclosures.py'),
    'CI must run store privacy disclosure validation',
  );

  final readme = File('README.md');
  check(
    readme.path,
    readme.existsSync() &&
        readme
            .readAsStringSync()
            .contains('python tool/validate_store_privacy_disclosures.py') &&
        readme.readAsStringSync().contains('Play Console 데이터 보안'),
    'README must document store privacy disclosure validation',
  );
}

void _validateWebRuntimeSmokeTool(
  void Function(String scope, bool condition, String message) check,
) {
  final pythonRequirements = File('requirements-dev.txt');
  check(
    pythonRequirements.path,
    pythonRequirements.existsSync(),
    'Python dev requirements file missing',
  );
  if (pythonRequirements.existsSync()) {
    final source = pythonRequirements.readAsStringSync();
    check(
      pythonRequirements.path,
      source.contains('Pillow>=11.0,<12.0'),
      'Python dev requirements must pin Pillow for screenshot and asset tooling',
    );
  }

  final smokeTool = File('tool/verify_web_render.py');
  check(
      smokeTool.path, smokeTool.existsSync(), 'web render smoke tool missing');
  if (smokeTool.existsSync()) {
    final source = smokeTool.readAsStringSync();
    for (final token in [
      'DEFAULT_URL',
      'CHROME_PATH',
      '--virtual-time-budget',
      '--min-ui-ratio',
      'Screenshot is too small',
      'web render smoke passed',
      'Expected visible text, cards, or navigation.',
    ]) {
      check(
        smokeTool.path,
        source.contains(token),
        'web render smoke tool must keep $token',
      );
    }
  }

  final routeSmokeTool = File('tool/verify_web_core_routes.py');
  check(
    routeSmokeTool.path,
    routeSmokeTool.existsSync(),
    'web core route smoke tool missing',
  );
  if (routeSmokeTool.existsSync()) {
    final source = routeSmokeTool.readAsStringSync();
    for (final token in [
      'DEFAULT_ROUTE_CASES',
      'DEFAULT_ROUTES',
      '/auth/login',
      '/home?tab=profile',
      '/premium',
      '/fairness',
      '/admin',
      '/admin/vehicles',
      '1440,1000',
      'verify_route',
      'web core routes smoke passed',
    ]) {
      check(
        routeSmokeTool.path,
        source.contains(token),
        'web core route smoke tool must keep $token',
      );
    }
  }

  final webSmokeRunner = File('tool/run_web_smoke.py');
  check(
    webSmokeRunner.path,
    webSmokeRunner.existsSync(),
    'web smoke runner missing',
  );
  if (webSmokeRunner.existsSync()) {
    final source = webSmokeRunner.readAsStringSync();
    for (final token in [
      'assert_port_free',
      'wait_for_port',
      '--startup-timeout',
      'tool/serve_web.py',
      'tool/verify_web_render.py',
      'tool/verify_web_core_routes.py',
      'server did not open',
      'web smoke passed',
    ]) {
      check(
        webSmokeRunner.path,
        source.contains(token),
        'web smoke runner must keep $token',
      );
    }
  }

  final webIndex = File('web/index.html');
  check(webIndex.path, webIndex.existsSync(), 'web index template missing');
  if (webIndex.existsSync()) {
    final source = webIndex.readAsStringSync();
    for (final token in [
      "canvasKitBaseUrl: 'canvaskit/'",
      "renderer: 'canvaskit'",
      'useLocalCanvasKit: true',
      'wasmAllowList',
      'blink: false',
      'gecko: false',
      'webkit: false',
      'unknown: false',
      'navigator.serviceWorker.getRegistrations()',
      'registration.unregister()',
      'caches.keys()',
      'caches.delete(key)',
    ]) {
      check(
        webIndex.path,
        source.contains(token),
        'web runtime template must keep stable CanvasKit fallback token $token',
      );
    }
  }

  final webServer = File('tool/serve_web.py');
  check(webServer.path, webServer.existsSync(), 'web static server missing');
  if (webServer.existsSync()) {
    final source = webServer.readAsStringSync();
    for (final token in [
      'Cross-Origin-Opener-Policy',
      'Cross-Origin-Embedder-Policy',
      'Cross-Origin-Resource-Policy',
      'same-origin',
      'require-corp',
    ]) {
      check(
        webServer.path,
        source.contains(token),
        'web static server must keep Wasm/CanvasKit isolation header $token',
      );
    }
  }

  final checklist = File('docs/09_release_checklist.md');
  check(checklist.path, checklist.existsSync(), 'release checklist missing');
  if (checklist.existsSync()) {
    final source = checklist.readAsStringSync();
    for (final token in [
      'python tool/serve_web.py --directory build/web',
      'python tool/verify_web_render.py',
      'python tool/verify_web_core_routes.py',
      'CHROME_PATH',
      'CanvasKit',
      'COOP/COEP',
    ]) {
      check(
        checklist.path,
        source.contains(token),
        'release checklist must document web render smoke token $token',
      );
    }
  }

  final layoutGuide = File('docs/17_mobile_layout_guide.md');
  check(layoutGuide.path, layoutGuide.existsSync(),
      'mobile layout guide missing');
  if (layoutGuide.existsSync()) {
    final source = layoutGuide.readAsStringSync();
    check(
      layoutGuide.path,
      source.contains('tool/verify_web_render.py') &&
          source.contains('tool/verify_web_core_routes.py') &&
          source.contains('초록 배경만 보이는 회귀'),
      'mobile layout guide must document web render smoke coverage',
    );
  }
}

void _validateReleaseEnvironmentPreflightTool(
  void Function(String scope, bool condition, String message) check,
) {
  final preflight = File('tool/validate_release_environment.py');
  check(
    preflight.path,
    preflight.existsSync(),
    'release environment preflight tool missing',
  );
  if (preflight.existsSync()) {
    final source = preflight.readAsStringSync();
    for (final token in [
      'CLIENT_REQUIRED',
      'IOS_XCCONFIG_REQUIRED',
      'ADMOB_UNIT_ID_KEYS',
      '*ADMOB_UNIT_ID_KEYS',
      'EDGE_FUNCTION_NAMES',
      'PUBLIC_REST_CHECKS',
      'REDIRECT_STATUSES',
      'NoRedirectHandler',
      'IOS_RUNNER_BUNDLE_ID',
      'ANDROID_PACKAGE_NAME',
      'ANDROID_KEY_PROPERTIES_REQUIRED',
      'PUBLIC_LEGAL_URL_PATHS',
      'PUBLIC_LEGAL_URL_CONTENT_TOKENS',
      'legal_url_origins',
      'SHA1_FINGERPRINT_PATTERN',
      'SHA256_FINGERPRINT_PATTERN',
      'HANGUL_PATTERN',
      'CJK_PATTERN',
      'IOS_BUNDLE_ID_PATTERN',
      'EDGE_REQUIRED',
      'IAP_PRODUCT_IDS',
      'APPLE_ISSUER_ID_PATTERN',
      'APPLE_KEY_ID_PATTERN',
      'decode_jwt_part',
      'validate_supabase_anon_key',
      'parse_xcconfig_file',
      'parse_properties_file',
      'parse_plist_file',
      'parse_xml_file',
      'validate_ios_xcconfig',
      'validate_ios_info_plist',
      'validate_android_key_properties',
      'validate_android_manifest',
      'SUPABASE_ANON_KEY JWT role claim must be anon',
      'expected_reversed_ios_client_id',
      'GOOGLE_REVERSED_IOS_CLIENT_ID must match GOOGLE_IOS_CLIENT_ID',
      'GOOGLE_ANDROID_RELEASE_PACKAGE_NAME must be',
      'GOOGLE_ANDROID_RELEASE_SHA1 must be a colon-separated SHA-1 fingerprint',
      'GOOGLE_ANDROID_RELEASE_SHA256 must be a colon-separated SHA-256 fingerprint',
      'storeFile must not point at a debug keystore',
      'storeFile does not exist',
      'GADApplicationIdentifier',
      'NSLocationWhenInUseUsageDescription',
      'must use approved Korean copy',
      'must contain readable Korean copy without mojibake',
      '주행 거리와 지역 리그 계산을 위해 위치 정보가 필요합니다.',
      r'$(ADMOB_IOS_APP_ID)',
      r'$(GOOGLE_REVERSED_IOS_CLIENT_ID)',
      'OAuth callback data must use APP_AUTH_REDIRECT_SCHEME/HOST placeholders',
      'expected {expected_reversed_id}',
      'must match seeded subscription product_id',
      'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON type must be service_account',
      'APP_STORE_CONNECT_ISSUER_ID must be an App Store Connect UUID',
      'APP_STORE_CONNECT_KEY_ID must be 10 uppercase alphanumeric characters',
      'FORBIDDEN_CLIENT_KEYS',
      'SUPABASE_SERVICE_ROLE_KEY',
      'PUBLIC_PRIVACY_POLICY_URL',
      'ALLOW_MOCK_PURCHASE_VERIFICATION',
      'TEST_ADMOB_APP_IDS',
      'project-ref',
      'web-client',
      '1234567890123456',
      '--edge-secrets-file',
      '--ios-xcconfig',
      '--ios-info-plist',
      '--android-key-properties',
      '--android-manifest',
      '--check-public-urls',
      '--check-supabase-live',
      'check_public_urls',
      'no_redirect_urlopen',
      'public_web_origin',
      'cors_origin = public_web_origin(values)',
      'google_oauth_redirect_checks',
      'check_google_oauth_live',
      'check_supabase_live',
      '/auth/v1/authorize',
      'accounts.google.com',
      '"Origin": cors_origin',
      'x-idempotency-key',
      'SUPABASE_URL must look like https://<project-ref>.supabase.co',
      'must point to {expected_path}',
      'must not include query or fragment',
      'does not look like the expected Fuel Arena legal page',
      'PUBLIC legal URLs must share the same origin',
      'APP_STORE_BUNDLE_ID must match iOS',
      'release environment valid: production',
    ]) {
      check(
        preflight.path,
        source.contains(token),
        'release environment preflight tool must keep $token',
      );
    }
    final functionsDirectory = Directory('supabase/functions');
    if (functionsDirectory.existsSync()) {
      final functionNames = functionsDirectory
          .listSync()
          .whereType<Directory>()
          .map((directory) => directory.uri.pathSegments
              .where((segment) => segment.isNotEmpty)
              .last)
          .where((name) => !name.startsWith('_'))
          .toList()
        ..sort();
      for (final functionName in functionNames) {
        check(
          preflight.path,
          source.contains('"$functionName"'),
          'release live preflight must check Edge Function $functionName',
        );
      }
    }
  }

  final selftest = File('tool/validate_release_environment_selftest.py');
  check(
    selftest.path,
    selftest.existsSync(),
    'release environment validator self-test missing',
  );
  if (selftest.existsSync()) {
    final source = selftest.readAsStringSync();
    for (final token in [
      'test_valid_release_env_passes',
      'test_release_env_rejects_example_placeholders',
      'test_release_env_requires_interstitial_ad_units',
      'test_client_rejects_bad_anon_jwt_and_wrong_iap_product_id',
      'test_release_env_rejects_wrong_native_redirect',
      'test_release_env_rejects_wrong_legal_url_paths',
      'test_release_env_rejects_split_legal_url_origins',
      'test_public_url_check_requires_legal_page_content',
      '_public_urlopen_factory',
      'PUBLIC_TERMS_URL does not look like the expected Fuel Arena legal page',
      'test_release_env_rejects_bad_android_oauth_evidence',
      'test_release_env_rejects_mismatched_ios_reversed_client_id',
      'test_ios_xcconfig_must_match_client_env',
      'test_android_key_properties_preflight',
      'test_native_source_config_preflight',
      'expected com.googleusercontent.apps.fuelarena-ios-9876543210',
      'test_edge_rejects_store_and_service_account_metadata',
      'test_edge_rejects_android_package_as_app_store_bundle',
      'test_supabase_live_preflight_passes_with_public_rest_and_edge_cors',
      'test_supabase_live_preflight_uses_public_legal_origin_for_edge_cors',
      'expected_edge_origin',
      'request.get_header("Origin")',
      'test_supabase_live_preflight_requires_edge_idempotency_cors_header',
      'test_supabase_live_preflight_requires_seeded_public_rest_rows',
      'test_supabase_live_preflight_requires_google_oauth_redirect',
      'SUPABASE_SERVICE_ROLE_KEY',
      'Google test App ID',
      'ALLOW_MOCK_PURCHASE_VERIFICATION must be false',
      'GOOGLE_REVERSED_IOS_CLIENT_ID must match GOOGLE_IOS_CLIENT_ID',
      'GOOGLE_ANDROID_RELEASE_SHA1 must be a colon-separated SHA-1 fingerprint',
      'GOOGLE_IOS_CLIENT_ID must match .env.production',
      'keyAlias must not use androiddebugkey',
      r'GIDClientID must be $(GOOGLE_IOS_CLIENT_ID)',
      'NSLocationWhenInUseUsageDescription must use approved Korean copy',
      'NSUserNotificationUsageDescription must contain readable Korean copy',
      r'AdMob APPLICATION_ID must use ${ADMOB_ANDROID_APP_ID}',
      'CORS headers must allow x-idempotency-key',
      'Google OAuth web origin authorize',
      'accounts.google.com',
      'com.fuelarena.fuelArena',
      'release environment selftest valid',
    ]) {
      check(
        selftest.path,
        source.contains(token),
        'release environment validator self-test must keep $token',
      );
    }
  }

  final examplePlaceholderTool =
      File('tool/validate_release_example_placeholders.py');
  check(
    examplePlaceholderTool.path,
    examplePlaceholderTool.existsSync(),
    'release example placeholder validator missing',
  );
  if (examplePlaceholderTool.existsSync()) {
    final source = examplePlaceholderTool.readAsStringSync();
    for (final token in [
      'validate_release_environment.py',
      '.env.production.example',
      '.env.edge.production.example',
      'release environment validation failed',
      'SUPABASE_URL is missing or placeholder',
      'SUPABASE_ANON_KEY is missing or placeholder',
      'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON is missing or placeholder',
      'APP_STORE_CONNECT_KEY_ID must be 10 uppercase alphanumeric',
      'unexpectedly passed',
      'release example placeholders rejected as expected',
    ]) {
      check(
        examplePlaceholderTool.path,
        source.contains(token),
        'release example placeholder validator must keep $token',
      );
    }
  }

  final nativeSourceTool = File('tool/validate_release_native_sources.py');
  check(
    nativeSourceTool.path,
    nativeSourceTool.existsSync(),
    'release native source validator missing',
  );
  if (nativeSourceTool.existsSync()) {
    final source = nativeSourceTool.readAsStringSync();
    for (final token in [
      'validate_release_environment',
      'validate_ios_info_plist',
      'validate_android_manifest',
      'ios',
      'Runner',
      'Info.plist',
      'AndroidManifest.xml',
      'release native sources valid',
    ]) {
      check(
        nativeSourceTool.path,
        source.contains(token),
        'release native source validator must keep $token',
      );
    }
  }

  final workflow = File('.github/workflows/flutter_ci.yml');
  check(workflow.path, workflow.existsSync(), 'Flutter CI workflow missing');
  if (workflow.existsSync()) {
    final source = workflow.readAsStringSync();
    check(
      workflow.path,
      source.contains('python tool/validate_release_environment_selftest.py'),
      'Flutter CI must run release environment validator self-test',
    );
    check(
      workflow.path,
      source.contains('python tool/validate_release_native_sources.py'),
      'Flutter CI must run release native source validation',
    );
    check(
      workflow.path,
      source.contains('python tool/validate_release_example_placeholders.py'),
      'Flutter CI must run release example placeholder rejection',
    );
  }

  final envExample = File('.env.example');
  check(envExample.path, envExample.existsSync(), '.env.example missing');
  if (envExample.existsSync()) {
    final source = envExample.readAsStringSync();
    for (final token in [
      'PUBLIC_PRIVACY_POLICY_URL=',
      'PUBLIC_LOCATION_NOTICE_URL=',
      'PUBLIC_ACCOUNT_DELETION_URL=',
      'PUBLIC_TERMS_URL=',
      '# GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=',
      '# ALLOW_MOCK_PURCHASE_VERIFICATION=false',
    ]) {
      check(
        envExample.path,
        source.contains(token),
        '.env.example must keep release preflight token $token',
      );
    }
  }

  final productionEnvExample = File('.env.production.example');
  check(
    productionEnvExample.path,
    productionEnvExample.existsSync(),
    '.env.production.example missing',
  );
  if (productionEnvExample.existsSync()) {
    final source = productionEnvExample.readAsStringSync();
    for (final token in [
      'APP_ENV=production',
      'SUPABASE_URL=replace-with-production-supabase-url',
      'GOOGLE_WEB_CLIENT_ID=replace-with-google-web-client-id.apps.googleusercontent.com',
      'GOOGLE_ANDROID_RELEASE_PACKAGE_NAME=com.fuelarena.fuel_arena',
      'GOOGLE_ANDROID_RELEASE_SHA1=replace-with-google-android-release-sha1',
      'GOOGLE_ANDROID_RELEASE_SHA256=replace-with-google-android-release-sha256',
      'GOOGLE_IOS_CLIENT_ID=replace-with-google-ios-client-id.apps.googleusercontent.com',
      'GOOGLE_REVERSED_IOS_CLIENT_ID=com.googleusercontent.apps.replace-with-google-ios-client-id',
      'ADMOB_ANDROID_APP_ID=replace-with-admob-android-app-id',
      'PUBLIC_PRIVACY_POLICY_URL=replace-with-public-privacy-policy-url',
    ]) {
      check(
        productionEnvExample.path,
        source.contains(token),
        '.env.production.example must keep client preflight token $token',
      );
    }
    for (final forbidden in [
      'SUPABASE_SERVICE_ROLE_KEY=',
      'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=',
      'APP_STORE_CONNECT_PRIVATE_KEY=',
      'RANKING_JOB_SECRET=',
      'replace-with-reversed-ios-client-id',
    ]) {
      check(
        productionEnvExample.path,
        !source.contains(forbidden),
        '.env.production.example must not contain Edge-only key $forbidden',
      );
    }
  }

  final edgeEnvExample = File('.env.edge.production.example');
  check(
    edgeEnvExample.path,
    edgeEnvExample.existsSync(),
    '.env.edge.production.example missing',
  );
  if (edgeEnvExample.existsSync()) {
    final source = edgeEnvExample.readAsStringSync();
    for (final token in [
      'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=',
      'APP_STORE_CONNECT_PRIVATE_KEY=replace-with-app-store-connect-private-key',
      'APP_STORE_BUNDLE_ID=$_iosRunnerBundleId',
      'ALLOW_MOCK_PURCHASE_VERIFICATION=false',
      'RANKING_JOB_SECRET=replace-with-strong-random-ranking-job-secret',
      'supabase secrets set',
    ]) {
      check(
        edgeEnvExample.path,
        source.contains(token),
        '.env.edge.production.example must keep Edge preflight token $token',
      );
    }
  }

  for (final path in [
    'README.md',
    'docs/09_release_checklist.md',
    'docs/15_product_gap_audit.md',
    'docs/21_production_runbook.md',
  ]) {
    final file = File(path);
    check(path, file.existsSync(), '$path missing');
    if (!file.existsSync()) {
      continue;
    }
    final source = file.readAsStringSync();
    for (final token in [
      '.env.production.example',
      '.env.edge.production.example',
      'python tool/validate_release_environment.py',
      '--env-file .env.production',
      '--edge-secrets-file .env.edge.production',
      '--ios-xcconfig ios/Flutter/FuelArenaSecrets.xcconfig',
      '--ios-info-plist ios/Runner/Info.plist',
      '--android-key-properties android/key.properties',
      '--android-manifest android/app/src/main/AndroidManifest.xml',
      '--check-supabase-live',
      'accounts.google.com',
    ]) {
      check(
        path,
        source.contains(token),
        '$path must document release environment preflight token $token',
      );
    }
  }
}

void _checkPngAsset(
  void Function(String scope, bool condition, String message) check,
  File file, {
  required int expectedWidth,
  required int expectedHeight,
  required int minimumBytes,
}) {
  check(file.path, file.existsSync(), '${file.path} is missing');
  if (!file.existsSync()) {
    return;
  }
  final bytes = file.readAsBytesSync();
  check(
    file.path,
    bytes.length >= minimumBytes,
    '${file.path} is too small for a release asset',
  );
  final size = _pngSize(bytes);
  check(
    file.path,
    size != null &&
        size.width == expectedWidth &&
        size.height == expectedHeight,
    '${file.path} must be ${expectedWidth}x$expectedHeight',
  );
}

String _sectionBetween(String source, String startToken, String endToken) {
  final normalizedSource = source.replaceAll('\r\n', '\n');
  final start = normalizedSource.indexOf(startToken);
  if (start < 0) {
    return '';
  }
  final end = normalizedSource.indexOf(endToken, start + startToken.length);
  return end < 0
      ? normalizedSource.substring(start)
      : normalizedSource.substring(start, end);
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

({int width, int height})? _pngSize(List<int> bytes) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 24) {
    return null;
  }
  for (var index = 0; index < signature.length; index += 1) {
    if (bytes[index] != signature[index]) {
      return null;
    }
  }
  int readInt32(int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  return (width: readInt32(16), height: readInt32(20));
}

List<File> _dartAndTextFiles(List<String> roots) {
  final files = <File>[];
  for (final root in roots) {
    final entity = FileSystemEntity.typeSync(root);
    if (entity == FileSystemEntityType.notFound) continue;
    if (entity == FileSystemEntityType.file) {
      files.add(File(root));
      continue;
    }
    files.addAll(
      Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => !_isGeneratedBuildOutput(file.path))
          .where(_isTextLike)
          .toList(),
    );
  }
  return files;
}

bool _isTextLike(File file) {
  final path = file.path.toLowerCase();
  return path.endsWith('.dart') ||
      path.endsWith('.kt') ||
      path.endsWith('.java') ||
      path.endsWith('.xml') ||
      path.endsWith('.plist') ||
      path.endsWith('.sql') ||
      path.endsWith('.yaml') ||
      path.endsWith('.yml') ||
      path.endsWith('.json');
}

bool _isGeneratedBuildOutput(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.contains('/build/') ||
      normalized.contains('/.dart_tool/') ||
      normalized.contains('/Pods/') ||
      normalized.endsWith('/flutter_export_environment.sh');
}
