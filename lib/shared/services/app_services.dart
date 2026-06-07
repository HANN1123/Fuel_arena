import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fuel_arena_models.dart';
import '../repositories/fuel_arena_repositories.dart';

class LocalStateService {
  static const _latestDriveResultSummaryKey = 'latest_drive_result_summary';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<bool> getBool(String key, {bool fallback = false}) async {
    return (await _instance).getBool(key) ?? fallback;
  }

  Future<void> setBool(String key, bool value) async {
    await (await _instance).setBool(key, value);
  }

  Future<String> getString(String key, {String fallback = ''}) async {
    return (await _instance).getString(key) ?? fallback;
  }

  Future<void> setString(String key, String value) async {
    await (await _instance).setString(key, value);
  }

  Future<void> remove(String key) async {
    await (await _instance).remove(key);
  }

  Future<void> markOnboardingCompleted() =>
      setBool('onboarding_completed', true);
  Future<void> markConsentCompleted() => setBool('consent_completed', true);
  Future<void> markVehicleSetupCompleted() =>
      setBool('vehicle_setup_completed', true);
  Future<void> saveRecentRankingFilter(String filter) =>
      setString('recent_ranking_filter', filter);
  Future<void> saveRecentPrimaryVehicle(String vehicleId) =>
      setString('recent_primary_vehicle_id', vehicleId);
  Future<void> saveActiveDriveSession(String sessionId) =>
      setString('active_drive_session_id', sessionId);
  Future<void> clearActiveDriveSession() => remove('active_drive_session_id');

  Future<void> saveLatestDriveResultSummary({
    required String sessionId,
    required Duration duration,
    required double distanceKm,
    required double averageEfficiency,
    double fuelUsedLiters = 0,
  }) {
    return setString(
      _latestDriveResultSummaryKey,
      jsonEncode({
        'session_id': sessionId,
        'duration_seconds': duration.inSeconds,
        'distance_km': distanceKm,
        'average_efficiency': averageEfficiency,
        'fuel_used_liters': fuelUsedLiters,
        'created_at': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<LocalDriveResultSummary?> getLatestDriveResultSummary(
      String sessionId) async {
    final raw = await getString(_latestDriveResultSummaryKey);
    if (raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final summary =
          LocalDriveResultSummary.fromJson(Map<String, dynamic>.from(decoded));
      return summary.sessionId == sessionId ? summary : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearLatestDriveResultSummary(String sessionId) async {
    final summary = await getLatestDriveResultSummary(sessionId);
    if (summary != null) {
      await remove(_latestDriveResultSummaryKey);
    }
  }

  Future<void> clearCachedDriveResultSummary() =>
      remove(_latestDriveResultSummaryKey);
}

class LocalDriveResultSummary {
  const LocalDriveResultSummary({
    required this.sessionId,
    required this.duration,
    required this.distanceKm,
    required this.averageEfficiency,
    required this.fuelUsedLiters,
    required this.createdAt,
  });

  final String sessionId;
  final Duration duration;
  final double distanceKm;
  final double averageEfficiency;
  final double fuelUsedLiters;
  final DateTime createdAt;

  factory LocalDriveResultSummary.fromJson(Map<String, dynamic> json) {
    return LocalDriveResultSummary(
      sessionId: '${json['session_id'] ?? ''}',
      duration:
          Duration(seconds: (json['duration_seconds'] as num?)?.toInt() ?? 0),
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      averageEfficiency: (json['average_efficiency'] as num?)?.toDouble() ?? 0,
      fuelUsedLiters: (json['fuel_used_liters'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
    );
  }
}

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> writeSessionHint(String value) =>
      _storage.write(key: 'session_hint', value: value);
  Future<String?> readSessionHint() => _storage.read(key: 'session_hint');
  Future<void> clearSessionHint() => _storage.delete(key: 'session_hint');
}

class RestoredSessionState {
  const RestoredSessionState({
    required this.user,
    required this.onboardingCompleted,
    required this.consentCompleted,
    required this.vehicleSetupCompleted,
    required this.activeDriveSessionId,
    required this.recentRankingFilter,
    required this.recentPrimaryVehicleId,
  });

  final UserProfile? user;
  final bool onboardingCompleted;
  final bool consentCompleted;
  final bool vehicleSetupCompleted;
  final String activeDriveSessionId;
  final String recentRankingFilter;
  final String recentPrimaryVehicleId;

  bool get hasActiveDrive => activeDriveSessionId.isNotEmpty;
}

class AppSessionService {
  const AppSessionService({
    required this.authRepository,
    required this.localState,
    required this.secureStorage,
  });

  final AuthRepository authRepository;
  final LocalStateService localState;
  final SecureStorageService secureStorage;

  Future<RestoredSessionState> restore() async {
    final user = await authRepository.currentUser();
    if (user != null) {
      try {
        await secureStorage.writeSessionHint(user.id);
      } catch (_) {
        // Session recovery must not fail because the secure hint backend is
        // temporarily unavailable in a browser/test runtime.
      }
    }
    final localOnboardingCompleted =
        await localState.getBool('onboarding_completed');
    final localConsentCompleted = await localState.getBool('consent_completed');
    final localVehicleSetupCompleted =
        await localState.getBool('vehicle_setup_completed');
    final onboardingCompleted =
        localOnboardingCompleted || (user?.onboardingCompleted ?? false);
    final consentCompleted =
        localConsentCompleted || (user?.consentCompleted ?? false);
    final vehicleSetupCompleted =
        localVehicleSetupCompleted || (user?.vehicleSetupCompleted ?? false);
    if (user?.onboardingCompleted == true && !localOnboardingCompleted) {
      await localState.markOnboardingCompleted();
    }
    if (user?.consentCompleted == true && !localConsentCompleted) {
      await localState.markConsentCompleted();
    }
    if (user?.vehicleSetupCompleted == true && !localVehicleSetupCompleted) {
      await localState.markVehicleSetupCompleted();
    }
    final activeDriveSessionId =
        await localState.getString('active_drive_session_id');
    final recentRankingFilter =
        await localState.getString('recent_ranking_filter', fallback: '내 리그');
    final recentPrimaryVehicleId =
        await localState.getString('recent_primary_vehicle_id');
    return RestoredSessionState(
      user: user,
      onboardingCompleted: onboardingCompleted,
      consentCompleted: consentCompleted,
      vehicleSetupCompleted: vehicleSetupCompleted,
      activeDriveSessionId: activeDriveSessionId,
      recentRankingFilter: recentRankingFilter,
      recentPrimaryVehicleId: recentPrimaryVehicleId,
    );
  }

  Future<void> rememberLogin(UserProfile user) async {
    try {
      await secureStorage.writeSessionHint(user.id);
    } catch (_) {
      // Login has already succeeded; the secure hint is only a recovery aid.
    }
  }

  Future<void> signOut() async {
    Object? authError;
    StackTrace? authStackTrace;
    try {
      await authRepository.signOut();
    } catch (error, stackTrace) {
      authError = error;
      authStackTrace = stackTrace;
    }
    await _clearUserScopedLocalState();
    if (authError != null) {
      Error.throwWithStackTrace(
          authError, authStackTrace ?? StackTrace.current);
    }
  }

  Future<void> _clearUserScopedLocalState() async {
    await localState.remove('consent_completed');
    await localState.remove('vehicle_setup_completed');
    await localState.clearActiveDriveSession();
    await localState.remove('recent_ranking_filter');
    await localState.remove('recent_primary_vehicle_id');
    await localState.clearCachedDriveResultSummary();
    await OfflineQueueService(localState: localState)
        .clear(includeCorruptBackup: true);
    await secureStorage.clearSessionHint();
  }
}

class AppLifecycleService with WidgetsBindingObserver {
  AppLifecycleService({required this.localState});

  final LocalStateService localState;
  final _stateController = StreamController<AppLifecycleState>.broadcast();

  Stream<AppLifecycleState> get states => _stateController.stream;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
    _stateController.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _stateController.add(state);
  }
}

class NetworkSnapshot {
  const NetworkSnapshot({
    required this.isOnline,
    required this.label,
  });

  final bool isOnline;
  final String label;
}

class NetworkStatusService {
  NetworkStatusService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<NetworkSnapshot> watch() {
    return _connectivity.onConnectivityChanged.map(_fromConnectivityResult);
  }

  Future<NetworkSnapshot> current() async {
    return _fromConnectivityResult(await _connectivity.checkConnectivity());
  }

  NetworkSnapshot _fromConnectivityResult(Object result) {
    final results = result is Iterable ? result : [result];
    final isOnline = results.any((item) => item != ConnectivityResult.none);
    return NetworkSnapshot(
      isOnline: isOnline,
      label: isOnline ? '온라인' : '오프라인',
    );
  }
}

class OfflineQueueItem {
  const OfflineQueueItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) {
    return OfflineQueueItem(
      id: '${json['id'] ?? ''}',
      type: '${json['type'] ?? ''}',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
      createdAt:
          DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
      };
}

class OfflineQueueService {
  OfflineQueueService({required this.localState});

  static const _maxPendingItems = 200;
  static const _queueKey = 'offline_queue';
  static const _corruptQueueBackupKey = 'offline_queue_corrupt_backup';
  static const _driveSessionIdMapKey = 'offline_drive_session_id_map';

  final LocalStateService localState;

  Future<List<OfflineQueueItem>> pendingItems() async {
    final raw = await localState.getString(_queueKey, fallback: '[]');
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await _quarantineCorruptQueue(raw, reason: 'not_list');
        return const [];
      }
      final items = <OfflineQueueItem>[];
      var skipped = 0;
      for (final item in decoded) {
        final parsed = _tryParseItem(item);
        if (parsed == null) {
          skipped += 1;
        } else {
          items.add(parsed);
        }
      }
      if (skipped > 0) {
        await _quarantineCorruptQueue(raw, reason: 'invalid_items');
        await _save(items);
      }
      return items;
    } catch (_) {
      await _quarantineCorruptQueue(raw, reason: 'decode_error');
      return const [];
    }
  }

  Future<void> enqueue(OfflineQueueItem item) async {
    final items = await pendingItems();
    items.add(item);
    final startIndex =
        items.length > _maxPendingItems ? items.length - _maxPendingItems : 0;
    await _save(items.sublist(startIndex));
  }

  Future<void> enqueueDriveSession(DriveSession session) {
    return enqueue(
      OfflineQueueItem(
        id: session.id,
        type: 'drive_session',
        payload: session.toJson(),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> enqueueDrivePoints(List<DrivePoint> points) {
    if (points.isEmpty) {
      return Future<void>.value();
    }
    final sessionId = points.first.driveSessionId;
    return enqueue(
      OfflineQueueItem(
        id: 'drive-points-$sessionId-${DateTime.now().microsecondsSinceEpoch}',
        type: 'drive_points',
        payload: {
          'drive_session_id': sessionId,
          'points': points.map((point) => point.toPrivateJson()).toList(),
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> remove(String id) async {
    final items = await pendingItems();
    await _save(items.where((item) => item.id != id).toList());
  }

  Future<void> clear({bool includeCorruptBackup = false}) async {
    await _save(const []);
    await localState.remove(_driveSessionIdMapKey);
    if (includeCorruptBackup) {
      await localState.remove(_corruptQueueBackupKey);
    }
  }

  Future<String> corruptQueueBackup() {
    return localState.getString(_corruptQueueBackupKey);
  }

  Future<Map<String, String>> driveSessionIdMap() async {
    final raw =
        await localState.getString(_driveSessionIdMapKey, fallback: '{}');
    try {
      final decoded = jsonDecode(raw) as Map;
      return decoded.map(
        (key, value) => MapEntry('$key', '$value'),
      )..removeWhere((key, value) => key.isEmpty || value.isEmpty);
    } catch (_) {
      return const {};
    }
  }

  Future<void> rememberDriveSessionMapping(
    String localSessionId,
    String remoteSessionId,
  ) async {
    if (localSessionId.isEmpty ||
        remoteSessionId.isEmpty ||
        localSessionId == remoteSessionId) {
      return;
    }
    final mapping = await driveSessionIdMap();
    mapping[localSessionId] = remoteSessionId;
    await localState.setString(_driveSessionIdMapKey, jsonEncode(mapping));
  }

  Future<String> resolveDriveSessionId(String sessionId) async {
    final mapping = await driveSessionIdMap();
    return mapping[sessionId] ?? sessionId;
  }

  Future<void> _save(List<OfflineQueueItem> items) async {
    await localState.setString(
        _queueKey, jsonEncode(items.map((item) => item.toJson()).toList()));
  }

  OfflineQueueItem? _tryParseItem(Object? item) {
    if (item is! Map) {
      return null;
    }
    try {
      final parsed = OfflineQueueItem.fromJson(Map<String, dynamic>.from(item));
      if (parsed.id.trim().isEmpty || parsed.type.trim().isEmpty) {
        return null;
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  Future<void> _quarantineCorruptQueue(
    String raw, {
    required String reason,
  }) async {
    await localState.setString(
      _corruptQueueBackupKey,
      jsonEncode({
        'reason': reason,
        'raw': raw,
        'captured_at': DateTime.now().toIso8601String(),
      }),
    );
    if (reason != 'invalid_items') {
      await _save(const []);
    }
  }
}

class SyncService {
  SyncService({
    required this.networkStatus,
    required this.offlineQueue,
    required this.driveRepository,
    this.syncLogRepository = const NoopLocalSyncLogRepository(),
    Future<NetworkSnapshot> Function()? networkSnapshotLoader,
  }) : _networkSnapshotLoader = networkSnapshotLoader;

  final NetworkStatusService networkStatus;
  final OfflineQueueService offlineQueue;
  final DriveRepository driveRepository;
  final LocalSyncLogRepository syncLogRepository;
  final Future<NetworkSnapshot> Function()? _networkSnapshotLoader;
  var _isUploading = false;

  Future<int> uploadPending() async {
    if (_isUploading) {
      return 0;
    }
    _isUploading = true;
    try {
      final network =
          await (_networkSnapshotLoader?.call() ?? networkStatus.current());
      if (!network.isOnline) {
        return 0;
      }
      var uploaded = 0;
      final sessionIdMap = await offlineQueue.driveSessionIdMap();
      final pending = await offlineQueue.pendingItems();
      for (final item in pending) {
        final result = await _uploadItem(item, sessionIdMap);
        await _recordSyncLog(item, result);
        if (result.shouldRemoveFromQueue) {
          await offlineQueue.remove(item.id);
        }
        if (result.countsAsUpload) {
          uploaded += 1;
        }
      }
      return uploaded;
    } finally {
      _isUploading = false;
    }
  }

  Future<_SyncUploadResult> _uploadItem(
    OfflineQueueItem item,
    Map<String, String> sessionIdMap,
  ) async {
    try {
      switch (item.type) {
        case 'drive_points':
          final rawPoints = item.payload['points'];
          if (rawPoints is! List) {
            return const _SyncUploadResult.discarded(
              '손상된 주행 포인트 동기화 항목입니다.',
            );
          }
          if (rawPoints.isEmpty) {
            return const _SyncUploadResult.discarded(
              '비어 있는 주행 포인트 동기화 항목입니다.',
            );
          }
          final points = <DrivePoint>[];
          for (final rawPoint in rawPoints) {
            if (rawPoint is! Map) {
              return const _SyncUploadResult.discarded(
                '손상된 주행 포인트 동기화 항목입니다.',
              );
            }
            try {
              points.add(
                DrivePoint.fromPrivateJson(
                  Map<String, dynamic>.from(rawPoint),
                ),
              );
            } catch (error) {
              return _SyncUploadResult.discarded(
                _safeSyncErrorMessage(
                  '손상된 주행 포인트 동기화 항목입니다: $error',
                ),
              );
            }
          }
          final remappedPoints = points.map((point) {
            final remoteSessionId = sessionIdMap[point.driveSessionId];
            return remoteSessionId == null
                ? point
                : point.copyWith(driveSessionId: remoteSessionId);
          }).toList();
          await driveRepository.recordDrivePoints(remappedPoints);
          return const _SyncUploadResult.uploaded();
        case 'drive_session':
          final session = DriveSession.fromJson(item.payload);
          final uploadedSession =
              await driveRepository.uploadQueuedDriveSession(session);
          if (session.id.isNotEmpty && uploadedSession.id.isNotEmpty) {
            sessionIdMap[session.id] = uploadedSession.id;
            await offlineQueue.rememberDriveSessionMapping(
              session.id,
              uploadedSession.id,
            );
          }
          return const _SyncUploadResult.uploaded();
        default:
          return _SyncUploadResult.discarded(
            '지원하지 않는 동기화 항목입니다: ${item.type}',
          );
      }
    } catch (error) {
      return _SyncUploadResult.failed(_safeSyncErrorMessage(error));
    }
  }

  Future<void> _recordSyncLog(
    OfflineQueueItem item,
    _SyncUploadResult result,
  ) async {
    await syncLogRepository.recordQueueItem(
      item: item,
      status: result.status,
      errorMessage: result.errorMessage,
    );
  }
}

class _SyncUploadResult {
  const _SyncUploadResult._({
    required this.status,
    required this.shouldRemoveFromQueue,
    required this.countsAsUpload,
    this.errorMessage,
  });

  const _SyncUploadResult.uploaded()
      : this._(
          status: 'uploaded',
          shouldRemoveFromQueue: true,
          countsAsUpload: true,
        );

  const _SyncUploadResult.discarded(String errorMessage)
      : this._(
          status: 'discarded',
          shouldRemoveFromQueue: true,
          countsAsUpload: false,
          errorMessage: errorMessage,
        );

  const _SyncUploadResult.failed(String errorMessage)
      : this._(
          status: 'failed',
          shouldRemoveFromQueue: false,
          countsAsUpload: false,
          errorMessage: errorMessage,
        );

  final String status;
  final bool shouldRemoveFromQueue;
  final bool countsAsUpload;
  final String? errorMessage;
}

String _safeSyncErrorMessage(Object error) {
  final message = '$error'
      .replaceAll(
          RegExp(r'latitude|longitude|drive_points', caseSensitive: false),
          'redacted')
      .trim();
  if (message.length <= 180) {
    return message;
  }
  return '${message.substring(0, 180)}...';
}

abstract class LocalSyncLogRepository {
  Future<void> recordQueueItem({
    required OfflineQueueItem item,
    required String status,
    String? errorMessage,
  });
}

class NoopLocalSyncLogRepository implements LocalSyncLogRepository {
  const NoopLocalSyncLogRepository();

  @override
  Future<void> recordQueueItem({
    required OfflineQueueItem item,
    required String status,
    String? errorMessage,
  }) async {}
}

class SupabaseLocalSyncLogRepository implements LocalSyncLogRepository {
  SupabaseLocalSyncLogRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<void> recordQueueItem({
    required OfflineQueueItem item,
    required String status,
    String? errorMessage,
  }) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    try {
      await _client.from('user_local_sync_logs').insert({
        'user_id': userId,
        'item_type': item.type,
        'item_id': item.id,
        'sync_status': status,
        'error_message': errorMessage,
        if (status != 'failed') 'synced_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Sync logs are operational telemetry and must never block queue upload.
    }
  }
}

abstract class AnalyticsRepository {
  Future<void> track(String eventName,
      {Map<String, Object?> properties = const {}});
  Future<void> identify(String userId,
      {Map<String, Object?> properties = const {}});
  Future<void> setUserProperty(String key, Object? value);
}

Map<String, Object?> sanitizedAnalyticsProperties(
    Map<String, Object?> properties) {
  return Map<String, Object?>.from(properties)
    ..removeWhere((key, value) {
      return isSensitiveAnalyticsKey(key);
    });
}

bool isSensitiveAnalyticsKey(String key) {
  final normalized = key.toLowerCase();
  return normalized.contains('location') ||
      normalized.contains('latitude') ||
      normalized.contains('longitude') ||
      normalized.contains('drive_points');
}

class MockAnalyticsRepository implements AnalyticsRepository {
  final List<Map<String, Object?>> events = [];

  @override
  Future<void> identify(String userId,
      {Map<String, Object?> properties = const {}}) async {
    events.add({
      'event': 'identify',
      'user_id': userId,
      ...sanitizedAnalyticsProperties(properties),
    });
  }

  @override
  Future<void> setUserProperty(String key, Object? value) async {
    if (isSensitiveAnalyticsKey(key)) {
      return;
    }
    events.add({'event': 'set_user_property', 'key': key, 'value': value});
  }

  @override
  Future<void> track(String eventName,
      {Map<String, Object?> properties = const {}}) async {
    final safeProperties = sanitizedAnalyticsProperties(properties);
    events.add({'event': eventName, ...safeProperties});
  }
}

class SupabaseAnalyticsRepository implements AnalyticsRepository {
  SupabaseAnalyticsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<void> identify(String userId,
      {Map<String, Object?> properties = const {}}) {
    return track('identify',
        properties: {'identified_user_id': userId, ...properties});
  }

  @override
  Future<void> setUserProperty(String key, Object? value) {
    if (isSensitiveAnalyticsKey(key)) {
      return Future<void>.value();
    }
    return track('set_user_property', properties: {'key': key, 'value': value});
  }

  @override
  Future<void> track(String eventName,
      {Map<String, Object?> properties = const {}}) async {
    final safeProperties = sanitizedAnalyticsProperties(properties);
    try {
      await _client.from('analytics_events').insert({
        'user_id': _userId,
        'event_name': eventName,
        'properties': safeProperties,
      });
    } catch (_) {
      // Analytics should never block the driving or onboarding flow.
    }
  }
}

class AppRemoteConfig {
  const AppRemoteConfig({
    this.rewardAdDailyLimit = 3,
    this.rewardAdsEnabled = true,
    this.newUserAdProtectionDays = 3,
    this.seasonEndingSoonDays = 3,
    this.officialDriveMinDistanceKm = 1.0,
    this.officialDriveMinDurationSeconds = 180,
    this.abnormalSpeedKmh = 180,
    this.allowCustomVehicleOfficialRanking = false,
    this.splitPlugInHybridLeague = true,
    this.friendlyBattleEnabled = true,
    this.premiumPriceLabel = '월 4,900원',
    this.couponsEnabled = true,
  });

  factory AppRemoteConfig.fromSettingsMap(Map<String, dynamic> map) {
    return AppRemoteConfig(
      rewardAdDailyLimit: _intSetting(
        map['reward_ad_daily_limit'],
        3,
        min: 0,
        max: 20,
      ),
      rewardAdsEnabled: _boolSetting(map['reward_ads_enabled'], true),
      newUserAdProtectionDays: _intSetting(
        map['new_user_ad_protection_days'],
        3,
        min: 0,
        max: 30,
      ),
      seasonEndingSoonDays: _intSetting(
        map['season_ending_soon_days'],
        3,
        min: 1,
        max: 30,
      ),
      officialDriveMinDistanceKm: _doubleSetting(
        map['official_drive_min_distance_km'],
        1.0,
        min: 0.1,
        max: 50,
      ),
      officialDriveMinDurationSeconds: _intSetting(
        map['official_drive_min_duration_seconds'],
        180,
        min: 30,
        max: 7200,
      ),
      abnormalSpeedKmh: _intSetting(
        map['abnormal_speed_kmh'],
        180,
        min: 60,
        max: 300,
      ),
      allowCustomVehicleOfficialRanking: _boolSetting(
        map['allow_custom_vehicle_official_ranking'],
        false,
      ),
      splitPlugInHybridLeague: _boolSetting(
        map['split_plug_in_hybrid_league'],
        true,
      ),
      friendlyBattleEnabled: _boolSetting(
        map['friendly_battle_enabled'],
        true,
      ),
      premiumPriceLabel: _stringSetting(map['premium_price_label'], '월 4,900원'),
      couponsEnabled: _boolSetting(map['coupons_enabled'], true),
    );
  }

  final int rewardAdDailyLimit;
  final bool rewardAdsEnabled;
  final int newUserAdProtectionDays;
  final int seasonEndingSoonDays;
  final double officialDriveMinDistanceKm;
  final int officialDriveMinDurationSeconds;
  final int abnormalSpeedKmh;
  final bool allowCustomVehicleOfficialRanking;
  final bool splitPlugInHybridLeague;
  final bool friendlyBattleEnabled;
  final String premiumPriceLabel;
  final bool couponsEnabled;

  static Object? _settingValue(Object? raw) {
    if (raw is Map) {
      return raw['value'] ?? raw['text'];
    }
    return raw;
  }

  static int _intSetting(
    Object? raw,
    int fallback, {
    int? min,
    int? max,
  }) {
    final value = _settingValue(raw);
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    if (parsed == null) {
      return fallback;
    }
    if (min != null && parsed < min) {
      return fallback;
    }
    if (max != null && parsed > max) {
      return fallback;
    }
    return parsed;
  }

  static double _doubleSetting(
    Object? raw,
    double fallback, {
    double? min,
    double? max,
  }) {
    final value = _settingValue(raw);
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    if (parsed == null) {
      return fallback;
    }
    if (min != null && parsed < min) {
      return fallback;
    }
    if (max != null && parsed > max) {
      return fallback;
    }
    return parsed;
  }

  static bool _boolSetting(Object? raw, bool fallback) {
    final value = _settingValue(raw);
    return value is bool ? value : bool.tryParse('$value') ?? fallback;
  }

  static String _stringSetting(Object? raw, String fallback) {
    final value = _settingValue(raw);
    final text = value == null ? '' : '$value'.trim();
    return text.isEmpty ? fallback : text;
  }
}

abstract class AppRemoteConfigRepository {
  Future<AppRemoteConfig> getConfig();
}

class MockAppRemoteConfigRepository implements AppRemoteConfigRepository {
  const MockAppRemoteConfigRepository();

  @override
  Future<AppRemoteConfig> getConfig() async => const AppRemoteConfig();
}

class SupabaseAppRemoteConfigRepository implements AppRemoteConfigRepository {
  SupabaseAppRemoteConfigRepository({
    SupabaseClient? client,
    this.allowDefaultFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowDefaultFallback;

  @override
  Future<AppRemoteConfig> getConfig() async {
    try {
      final rows =
          await _client.from('app_settings').select().eq('is_public', true);
      if (rows.isEmpty && !allowDefaultFallback) {
        throw StateError('공개 운영 설정을 찾을 수 없습니다.');
      }
      final map = <String, dynamic>{};
      for (final row in rows) {
        map['${row['key'] ?? ''}'] = row['value'];
      }
      return AppRemoteConfig.fromSettingsMap(map);
    } catch (_) {
      if (!allowDefaultFallback) {
        rethrow;
      }
      return const AppRemoteConfig();
    }
  }
}
