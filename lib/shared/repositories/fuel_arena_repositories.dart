import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/fuel_arena_models.dart';
import '../services/app_logger.dart';

const _uuid = Uuid();
const _logger = AppLogger();

Map<String, dynamic> _functionResponseMap(Object? data) {
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  if (data is String && data.isNotEmpty) {
    final decoded = jsonDecode(data);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
  }
  return const <String, dynamic>{};
}

int _intFrom(Object? value, int fallback) {
  return value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
}

bool _boolFrom(Object? value, bool fallback) {
  if (value is bool) {
    return value;
  }
  final normalized = '$value'.toLowerCase();
  if (normalized == 'true' || normalized == '1') {
    return true;
  }
  if (normalized == 'false' || normalized == '0') {
    return false;
  }
  return fallback;
}

abstract class AuthRepository {
  Future<UserProfile?> currentUser();

  Future<UserProfile> signInWithGoogle();

  Future<UserProfile> ensureProfileAfterGoogleLogin();

  bool isGoogleAuthConfigured();

  Future<UserProfile> loginWithEmail({
    required String email,
    required String password,
  });

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String nickname,
  });

  Future<UserProfile?> getCurrentUser();

  Future<void> signOut();

  Future<void> deleteAccount();
}

StateError _accountDeletionRequiresPrivacyRequest() {
  return StateError('계정 삭제는 개인정보 설정에서 요청해야 합니다.');
}

class AuthRedirectInProgressException implements Exception {
  const AuthRedirectInProgressException();

  @override
  String toString() => 'Google 로그인 화면으로 이동 중입니다.';
}

class MockAuthRepository implements AuthRepository {
  UserProfile? _currentUser = _mockSignedInProfile;

  @override
  Future<UserProfile?> currentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _currentUser;
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    return currentUser();
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _currentUser = _mockSignedInProfile.copyWith(
      authProvider: 'google',
      updatedAt: DateTime.now(),
    );
    _mockSignedInProfile = _currentUser!;
    return _currentUser!;
  }

  @override
  Future<UserProfile> ensureProfileAfterGoogleLogin() async {
    return _currentUser ?? await signInWithGoogle();
  }

  @override
  bool isGoogleAuthConfigured() => true;

  UserProfile get debugProfile => _currentUser ?? _mockSignedInProfile;

  void debugSetProfile(UserProfile profile) {
    _currentUser = profile;
    _mockSignedInProfile = profile;
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    _currentUser = UserProfile(
      id: _uuid.v4(),
      email: email,
      nickname: nickname.isEmpty ? 'NeonDriver' : nickname,
      avatarUrl: '',
      tier: 'Bronze I',
      totalScore: 0,
      seasonScore: 0,
      currentStreak: 0,
      bestStreak: 0,
      representativeVehicleName: '',
      isPremium: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _mockSignedInProfile = _currentUser!;
    return _currentUser!;
  }

  @override
  Future<UserProfile> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    _currentUser = _mockSignedInProfile;
    return _mockSignedInProfile;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _currentUser = null;
  }

  @override
  Future<void> deleteAccount() async {
    throw _accountDeletionRequiresPrivacyRequest();
  }
}

class UnavailableAuthRepository implements AuthRepository {
  const UnavailableAuthRepository();

  StateError _configurationError() {
    return StateError('인증 설정을 완료해야 합니다.');
  }

  @override
  Future<UserProfile?> currentUser() async {
    throw _configurationError();
  }

  @override
  Future<UserProfile?> getCurrentUser() => currentUser();

  @override
  Future<UserProfile> signInWithGoogle() async {
    throw _configurationError();
  }

  @override
  Future<UserProfile> ensureProfileAfterGoogleLogin() async {
    throw _configurationError();
  }

  @override
  bool isGoogleAuthConfigured() => false;

  @override
  Future<UserProfile> loginWithEmail({
    required String email,
    required String password,
  }) async {
    throw _configurationError();
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    throw _configurationError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {
    throw _configurationError();
  }
}

class SupabaseGoogleAuthRepository implements AuthRepository {
  SupabaseGoogleAuthRepository({
    SupabaseClient? client,
    GoogleSignIn? googleSignIn,
    this.googleWebClientId = '',
    this.googleAndroidClientId = '',
    this.googleIosClientId = '',
    this.googleServerClientId = '',
    this.redirectUri = '',
  })  : _client = client ?? Supabase.instance.client,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;
  final String googleWebClientId;
  final String googleAndroidClientId;
  final String googleIosClientId;
  final String googleServerClientId;
  final String redirectUri;
  var _initialized = false;

  static const _googleScopes = <String>[
    'email',
    'profile',
  ];

  String get _serverClientId => googleServerClientId.isNotEmpty
      ? googleServerClientId
      : googleWebClientId;

  String? get _oauthRedirectTo {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return redirectUri.isEmpty ? null : redirectUri;
  }

  String get _platformClientId {
    if (kIsWeb) {
      return googleWebClientId;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => googleIosClientId,
      TargetPlatform.android => googleAndroidClientId,
      _ => googleWebClientId,
    };
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_initialized) {
      return;
    }
    await _googleSignIn.initialize(
      clientId: _platformClientId.isEmpty ? null : _platformClientId,
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
    _initialized = true;
  }

  @override
  bool isGoogleAuthConfigured() {
    final hasServerTokenClient = _serverClientId.isNotEmpty;
    if (kIsWeb) {
      return hasServerTokenClient;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        hasServerTokenClient && googleAndroidClientId.isNotEmpty,
      TargetPlatform.iOS ||
      TargetPlatform.macOS =>
        hasServerTokenClient && googleIosClientId.isNotEmpty,
      _ => hasServerTokenClient,
    };
  }

  @override
  Future<UserProfile?> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) {
        return UserProfile.fromJson(row);
      }
    } catch (_) {
      // Missing profile rows are repaired below; dev environments may not have
      // run the latest migration yet.
    }
    return ensureProfileAfterGoogleLogin();
  }

  @override
  Future<UserProfile?> getCurrentUser() => currentUser();

  Future<UserProfile> _startSupabaseOAuthRedirect() async {
    final launched = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _oauthRedirectTo,
    );
    if (!launched) {
      throw StateError('Google 로그인 화면을 열지 못했습니다.');
    }
    throw const AuthRedirectInProgressException();
  }

  String _metadataText(
    Map<String, dynamic> metadata,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = '${metadata[key] ?? ''}'.trim();
      if (value.isNotEmpty && value != 'null') {
        return value;
      }
    }
    return fallback;
  }

  String _nicknameFromGoogleMetadata(
    Map<String, dynamic> metadata,
    String email,
  ) {
    final nickname = _metadataText(
      metadata,
      const ['name', 'full_name', 'display_name', 'preferred_username'],
    );
    if (nickname.isNotEmpty) {
      return nickname;
    }
    final localPart = email.split('@').first.trim();
    return localPart.isEmpty ? 'Fuel Driver' : localPart;
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    if (!isGoogleAuthConfigured()) {
      throw StateError('Google 로그인 설정이 필요합니다.');
    }

    if (kIsWeb) {
      return _startSupabaseOAuthRedirect();
    }

    await _initializeGoogleSignIn();

    if (!_googleSignIn.supportsAuthenticate()) {
      return _startSupabaseOAuthRedirect();
    }

    final account = await _googleSignIn.authenticate(scopeHint: _googleScopes);
    final auth = account.authentication;
    final idToken = auth.idToken;
    final authorization = await account.authorizationClient
            .authorizationForScopes(_googleScopes) ??
        await account.authorizationClient.authorizeScopes(_googleScopes);
    final accessToken = authorization.accessToken;

    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google ID 토큰을 찾을 수 없습니다.');
    }
    if (accessToken.isEmpty) {
      throw StateError('Google Access Token을 찾을 수 없습니다.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    return ensureProfileAfterGoogleLogin();
  }

  @override
  Future<UserProfile> ensureProfileAfterGoogleLogin() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('로그인된 사용자를 찾을 수 없습니다.');
    }

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final email = user.email ?? '${metadata['email'] ?? ''}';
    final nickname = _nicknameFromGoogleMetadata(metadata, email);
    final avatarUrl = _metadataText(
      metadata,
      const ['avatar_url', 'picture'],
    );
    final updatedAt = DateTime.now().toIso8601String();
    final existingRow =
        await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    if (existingRow == null) {
      final insertProfile = <String, dynamic>{
        'id': user.id,
        'email': email,
        'nickname': nickname,
        if (avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
        'auth_provider': 'google',
        'updated_at': updatedAt,
      };
      final inserted = await _client
          .from('profiles')
          .insert(insertProfile)
          .select()
          .single();
      return UserProfile.fromJson(inserted);
    }

    final existingProfile = UserProfile.fromJson(existingRow);
    final preservedNickname = existingProfile.nickname.trim().isEmpty
        ? nickname
        : existingProfile.nickname;
    final preservedEmail =
        email.trim().isEmpty ? existingProfile.email : email.trim();
    final preservedAvatarUrl = existingProfile.avatarUrl.trim().isEmpty
        ? avatarUrl.trim()
        : existingProfile.avatarUrl;
    final updateProfile = <String, dynamic>{
      'email': preservedEmail,
      'nickname': preservedNickname,
      'auth_provider': 'google',
      'updated_at': updatedAt,
    };
    if (preservedAvatarUrl.isNotEmpty) {
      updateProfile['avatar_url'] = preservedAvatarUrl;
    }
    final updated = await _client
        .from('profiles')
        .update(updateProfile)
        .eq('id', user.id)
        .select()
        .single();
    return UserProfile.fromJson(updated);
  }

  @override
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _initializeGoogleSignIn();
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Supabase 세션 종료는 Google SDK 캐시 정리 실패와 별개로 반드시 진행한다.
    }
    await _client.auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    throw _accountDeletionRequiresPrivacyRequest();
  }

  @override
  Future<UserProfile> loginWithEmail({
    required String email,
    required String password,
  }) {
    throw UnsupportedError('초기 버전은 Google 로그인만 지원합니다.');
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String nickname,
  }) {
    throw UnsupportedError('초기 버전은 Google 회원가입만 지원합니다.');
  }
}

class SupabaseAuthRepository extends SupabaseGoogleAuthRepository {
  SupabaseAuthRepository({
    super.client,
    super.googleSignIn,
    super.googleWebClientId,
    super.googleAndroidClientId,
    super.googleIosClientId,
    super.googleServerClientId,
    super.redirectUri,
  });
}

abstract class ConsentRepository {
  Future<AppConsent> getConsent();

  Future<AppConsent> saveConsent({
    required bool termsAccepted,
    required bool privacyAccepted,
    required bool locationAccepted,
    required bool personalizedAdsAccepted,
    required bool marketingAccepted,
  });
}

class MockConsentRepository implements ConsentRepository {
  @override
  Future<AppConsent> getConsent() async {
    return _mockAppConsent ?? _defaultMockConsent();
  }

  @override
  Future<AppConsent> saveConsent({
    required bool termsAccepted,
    required bool privacyAccepted,
    required bool locationAccepted,
    required bool personalizedAdsAccepted,
    required bool marketingAccepted,
  }) async {
    final item = AppConsent(
      userId: _mockSignedInProfile.id,
      termsAccepted: termsAccepted,
      privacyAccepted: privacyAccepted,
      locationAccepted: locationAccepted,
      personalizedAdsAccepted: personalizedAdsAccepted,
      marketingAccepted: marketingAccepted,
      updatedAt: DateTime.now(),
    );
    _mockAppConsent = item;
    _mockConsentLogs = [item, ..._mockConsentLogs];
    _mockSignedInProfile = _mockSignedInProfile.copyWith(
      consentCompleted: termsAccepted && privacyAccepted && locationAccepted,
      updatedAt: item.updatedAt,
    );
    return item;
  }

  List<AppConsent> get debugConsentLogs => _mockConsentLogs;
}

class UnavailableConsentRepository implements ConsentRepository {
  const UnavailableConsentRepository();

  StateError _configurationError() {
    return StateError('동의 저장소 설정을 완료해야 합니다.');
  }

  @override
  Future<AppConsent> getConsent() async {
    throw _configurationError();
  }

  @override
  Future<AppConsent> saveConsent({
    required bool termsAccepted,
    required bool privacyAccepted,
    required bool locationAccepted,
    required bool personalizedAdsAccepted,
    required bool marketingAccepted,
  }) async {
    throw _configurationError();
  }
}

class SupabaseConsentRepository implements ConsentRepository {
  SupabaseConsentRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockConsentRepository _fallback = MockConsentRepository();

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<AppConsent> getConsent() async {
    final userId = _userId;
    if (userId == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.getConsent();
    }
    try {
      final row = await _client
          .from('app_consents')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) {
        return _defaultConsent(userId);
      }
      return AppConsent.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getConsent();
    }
  }

  @override
  Future<AppConsent> saveConsent({
    required bool termsAccepted,
    required bool privacyAccepted,
    required bool locationAccepted,
    required bool personalizedAdsAccepted,
    required bool marketingAccepted,
  }) async {
    final userId = _userId;
    if (userId == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.saveConsent(
        termsAccepted: termsAccepted,
        privacyAccepted: privacyAccepted,
        locationAccepted: locationAccepted,
        personalizedAdsAccepted: personalizedAdsAccepted,
        marketingAccepted: marketingAccepted,
      );
    }
    final consent = AppConsent(
      userId: userId,
      termsAccepted: termsAccepted,
      privacyAccepted: privacyAccepted,
      locationAccepted: locationAccepted,
      personalizedAdsAccepted: personalizedAdsAccepted,
      marketingAccepted: marketingAccepted,
      updatedAt: DateTime.now(),
    );
    try {
      final row = await _client
          .from('app_consents')
          .upsert(consent.toJson(), onConflict: 'user_id')
          .select()
          .single();
      await _client.from('consent_logs').insert({
        'user_id': userId,
        'terms_accepted': termsAccepted,
        'privacy_accepted': privacyAccepted,
        'location_accepted': locationAccepted,
        'personalized_ads_accepted': personalizedAdsAccepted,
        'marketing_accepted': marketingAccepted,
      });
      await _client.from('profiles').update({
        'consent_completed':
            termsAccepted && privacyAccepted && locationAccepted,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      return AppConsent.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.saveConsent(
        termsAccepted: termsAccepted,
        privacyAccepted: privacyAccepted,
        locationAccepted: locationAccepted,
        personalizedAdsAccepted: personalizedAdsAccepted,
        marketingAccepted: marketingAccepted,
      );
    }
  }
}

AppConsent _defaultConsent(String userId) {
  return AppConsent(
    userId: userId,
    termsAccepted: false,
    privacyAccepted: false,
    locationAccepted: false,
    personalizedAdsAccepted: false,
    marketingAccepted: false,
    updatedAt: DateTime.now(),
  );
}

AppConsent _defaultMockConsent() => _defaultConsent(_mockSignedInProfile.id);

abstract class VehicleRepository {
  Future<List<Vehicle>> listVehicles();

  Future<Vehicle?> getPrimaryVehicle();

  Future<Vehicle> saveVehicle({
    required String manufacturer,
    required String modelName,
    required int modelYear,
    required String fuelType,
    required String vehicleClass,
    required String nickname,
  });

  Future<Vehicle> updateVehicle(Vehicle vehicle);

  Future<void> deleteVehicle(String vehicleId);

  Future<void> setPrimaryVehicle(String vehicleId);
}

class MockVehicleRepository implements VehicleRepository {
  @override
  Future<List<Vehicle>> listVehicles() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return [
      if (_mockPrimaryVehicle != null) _mockPrimaryVehicle!,
      ..._mockCustomVehicles.map((vehicle) => vehicle.toVehicle()),
      ...mockGarage.where((vehicle) => vehicle.id != _mockPrimaryVehicle?.id),
    ];
  }

  @override
  Future<Vehicle?> getPrimaryVehicle() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _mockPrimaryVehicle;
  }

  @override
  Future<Vehicle> saveVehicle({
    required String manufacturer,
    required String modelName,
    required int modelYear,
    required String fuelType,
    required String vehicleClass,
    required String nickname,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _mockPrimaryVehicle = Vehicle(
      id: _uuid.v4(),
      userId: _mockSignedInProfile.id,
      manufacturer: manufacturer,
      modelName: modelName,
      modelYear: modelYear,
      fuelType: fuelType,
      fuelLeague: FuelLeague.keyForFuelType(fuelType),
      vehicleClass: vehicleClass,
      nickname: nickname,
      isPrimary: true,
    );
    _mockSignedInProfile = _mockSignedInProfile.copyWith(
      representativeVehicleId: _mockPrimaryVehicle!.id,
      representativeVehicleName: _mockPrimaryVehicle!.displayName,
      selectedFuelLeague: _mockPrimaryVehicle!.leagueKey,
      selectedVehicleClass: _mockPrimaryVehicle!.vehicleClass,
      vehicleSetupCompleted: true,
      additionalSetupCompleted: true,
      updatedAt: DateTime.now(),
    );
    return _mockPrimaryVehicle!;
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _mockPrimaryVehicle = vehicle;
    return vehicle;
  }

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (_mockPrimaryVehicle?.id == vehicleId) {
      _mockPrimaryVehicle = null;
      _mockSignedInProfile = _mockSignedInProfile.copyWith(
        representativeVehicleId: '',
        representativeVehicleName: '',
        selectedFuelLeague: '',
        selectedVehicleClass: '',
        vehicleSetupCompleted: false,
        updatedAt: DateTime.now(),
      );
    }
    _mockCustomVehicles = _mockCustomVehicles
        .where((vehicle) => vehicle.id != vehicleId)
        .toList();
  }

  @override
  Future<void> setPrimaryVehicle(String vehicleId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _mockPrimaryVehicle = mockGarage.firstWhere(
      (vehicle) => vehicle.id == vehicleId,
      orElse: () => mockVehicle,
    );
    _mockSignedInProfile = _mockSignedInProfile.copyWith(
      representativeVehicleId: _mockPrimaryVehicle!.id,
      representativeVehicleName: _mockPrimaryVehicle!.displayName,
      selectedFuelLeague: _mockPrimaryVehicle!.leagueKey,
      selectedVehicleClass: _mockPrimaryVehicle!.vehicleClass,
      vehicleSetupCompleted: true,
      additionalSetupCompleted: true,
      updatedAt: DateTime.now(),
    );
  }
}

class SupabaseVehicleRepository implements VehicleRepository {
  SupabaseVehicleRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('로그인된 사용자를 찾을 수 없습니다.');
    }
    return user.id;
  }

  @override
  Future<List<Vehicle>> listVehicles() async {
    final rows = await _client
        .from('vehicles')
        .select()
        .eq('user_id', _userId)
        .order('created_at');
    return rows.map((row) => Vehicle.fromJson(row)).toList();
  }

  @override
  Future<Vehicle?> getPrimaryVehicle() async {
    final row = await _client
        .from('vehicles')
        .select()
        .eq('user_id', _userId)
        .eq('is_primary', true)
        .maybeSingle();
    return row == null ? null : Vehicle.fromJson(row);
  }

  @override
  Future<Vehicle> saveVehicle({
    required String manufacturer,
    required String modelName,
    required int modelYear,
    required String fuelType,
    required String vehicleClass,
    required String nickname,
  }) async {
    await _client
        .from('vehicles')
        .update({'is_primary': false}).eq('user_id', _userId);
    final league = FuelLeague.keyForFuelType(fuelType);
    final row = await _client
        .from('vehicles')
        .insert({
          'user_id': _userId,
          'manufacturer': manufacturer,
          'model_name': modelName,
          'model_year': modelYear,
          'fuel_type': fuelType,
          'fuel_league': league,
          'vehicle_class': vehicleClass,
          'nickname': nickname,
          'is_primary': true,
        })
        .select()
        .single();
    final vehicle = Vehicle.fromJson(row);
    await _client.from('profiles').update({
      'representative_vehicle_id': vehicle.id,
      'representative_vehicle_name': vehicle.displayName,
      'selected_fuel_league': vehicle.leagueKey,
      'selected_vehicle_class': vehicle.vehicleClass,
      'vehicle_setup_completed': true,
      'additional_setup_completed': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _userId);
    return vehicle;
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    final data = vehicle.toJson()
      ..remove('id')
      ..remove('user_id')
      ..remove('created_at')
      ..removeWhere((key, value) => value == null);
    data['updated_at'] = DateTime.now().toIso8601String();
    final row = await _client
        .from('vehicles')
        .update(data)
        .eq('id', vehicle.id)
        .eq('user_id', _userId)
        .select()
        .single();
    return Vehicle.fromJson(row);
  }

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    final existing = await _client
        .from('vehicles')
        .select('is_primary')
        .eq('id', vehicleId)
        .eq('user_id', _userId)
        .maybeSingle();
    final wasPrimary = existing?['is_primary'] == true;
    await _client
        .from('vehicles')
        .delete()
        .eq('id', vehicleId)
        .eq('user_id', _userId);
    if (!wasPrimary) {
      return;
    }
    final next = await _client
        .from('vehicles')
        .select()
        .eq('user_id', _userId)
        .order('created_at')
        .limit(1)
        .maybeSingle();
    if (next == null) {
      await _client.from('profiles').update({
        'representative_vehicle_id': null,
        'representative_vehicle_name': '',
        'selected_fuel_league': '',
        'selected_vehicle_class': '',
        'vehicle_setup_completed': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _userId);
      return;
    }
    await _client
        .from('vehicles')
        .update({'is_primary': false}).eq('user_id', _userId);
    final row = await _client
        .from('vehicles')
        .update({
          'is_primary': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', next['id'])
        .eq('user_id', _userId)
        .select()
        .single();
    final vehicle = Vehicle.fromJson(row);
    await _client.from('profiles').update({
      'representative_vehicle_id': vehicle.id,
      'representative_vehicle_name': vehicle.displayName,
      'selected_fuel_league': vehicle.leagueKey,
      'selected_vehicle_class': vehicle.vehicleClass,
      'vehicle_setup_completed': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _userId);
  }

  @override
  Future<void> setPrimaryVehicle(String vehicleId) async {
    await _client
        .from('vehicles')
        .update({'is_primary': false}).eq('user_id', _userId);
    final row = await _client
        .from('vehicles')
        .update({
          'is_primary': true,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('id', vehicleId)
        .eq('user_id', _userId)
        .select()
        .single();
    final vehicle = Vehicle.fromJson(row);
    await _client.from('profiles').update({
      'representative_vehicle_id': vehicle.id,
      'representative_vehicle_name': vehicle.displayName,
      'selected_fuel_league': vehicle.leagueKey,
      'selected_vehicle_class': vehicle.vehicleClass,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _userId);
  }
}

abstract class VehicleCatalogRepository {
  Future<List<VehicleManufacturer>> listManufacturers(
      {String? country, String? keyword});

  Future<List<VehicleModel>> listModels(String manufacturerId,
      {String? keyword});

  Future<List<VehicleModelYear>> listYears(String modelId);

  Future<List<VehicleVariant>> listVariants(String modelYearId);

  Future<List<VehicleVariant>> searchVehicleCatalog(String keyword);

  Future<VehicleVariant?> getVariant(String variantId);

  Future<UserVehicle> createCustomVehicleRequest({
    required String manufacturer,
    required String modelName,
    required int year,
    required String trimName,
    required String fuelType,
    required String vehicleClass,
    String nickname = '',
    String memo = '',
  });

  Future<List<CustomVehicleReviewRequest>> listCustomVehicleReviewRequests({
    String status = 'pending_review',
  });

  Future<CustomVehicleReviewRequest?> reviewCustomVehicleRequest({
    required String requestId,
    required String decision,
    String reviewNote = '',
  });

  Future<List<FuelLeague>> getFuelLeagues();
}

class MockVehicleCatalogRepository implements VehicleCatalogRepository {
  const MockVehicleCatalogRepository();

  @override
  Future<List<VehicleManufacturer>> listManufacturers(
      {String? country, String? keyword}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final catalog = await _loadVehicleCatalogAsset();
    final statsByManufacturer = _manufacturerStatsById(catalog);
    final normalized = keyword?.trim().toLowerCase() ?? '';
    return catalog.manufacturers.map((item) {
      final stats = statsByManufacturer[item.id];
      return item.copyWith(
        modelCount: stats?.modelCount,
        minYear: stats?.minYear,
        maxYear: stats?.maxYear,
      );
    }).where((item) {
      final countryMatches = _manufacturerCountryMatches(item, country);
      final keywordMatches = normalized.isEmpty ||
          item.nameKo.toLowerCase().contains(normalized) ||
          item.nameEn.toLowerCase().contains(normalized);
      return countryMatches && keywordMatches;
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<List<VehicleModel>> listModels(String manufacturerId,
      {String? keyword}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final catalog = await _loadVehicleCatalogAsset();
    final normalized = keyword?.trim().toLowerCase() ?? '';
    return catalog.models.where((item) {
      final keywordMatches = normalized.isEmpty ||
          item.nameKo.toLowerCase().contains(normalized) ||
          item.nameEn.toLowerCase().contains(normalized);
      return item.manufacturerId == manufacturerId && keywordMatches;
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<List<VehicleModelYear>> listYears(String modelId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final catalog = await _loadVehicleCatalogAsset();
    return catalog.years.where((item) => item.modelId == modelId).toList()
      ..sort((a, b) => b.year.compareTo(a.year));
  }

  @override
  Future<List<VehicleVariant>> listVariants(String modelYearId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final catalog = await _loadVehicleCatalogAsset();
    return catalog.variants
        .where((item) => item.modelYearId == modelYearId && item.isVerified)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<List<VehicleVariant>> searchVehicleCatalog(String keyword) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final normalized = keyword.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }
    final catalog = await _loadVehicleCatalogAsset();
    return catalog.variants.where((item) {
      return item.isVerified &&
          (item.manufacturerName.toLowerCase().contains(normalized) ||
              item.modelName.toLowerCase().contains(normalized) ||
              item.trimName.toLowerCase().contains(normalized));
    }).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  @override
  Future<VehicleVariant?> getVariant(String variantId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final catalog = await _loadVehicleCatalogAsset();
    for (final item in catalog.variants) {
      if (item.id == variantId) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<UserVehicle> createCustomVehicleRequest({
    required String manufacturer,
    required String modelName,
    required int year,
    required String trimName,
    required String fuelType,
    required String vehicleClass,
    String nickname = '',
    String memo = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final league = FuelLeague.keyForFuelType(fuelType);
    final userVehicle = UserVehicle(
      id: _uuid.v4(),
      userId: _mockSignedInProfile.id,
      nickname: nickname,
      isPrimary: false,
      verificationStatus: 'pendingReview',
      fuelType: fuelType,
      fuelLeague: league,
      vehicleClass: vehicleClass,
      variant: VehicleVariant(
        id: 'custom-${_uuid.v4()}',
        modelYearId: 'custom',
        manufacturerName: manufacturer,
        modelName: modelName,
        year: year,
        trimName: trimName,
        fuelType: fuelType,
        vehicleClass: vehicleClass,
        fuelLeague: league,
        isVerified: false,
      ),
    );
    _mockCustomVehicles = [
      ..._mockCustomVehicles.where((item) => item.id != userVehicle.id),
      userVehicle,
    ];
    _mockCustomVehicleReviewRequests = [
      CustomVehicleReviewRequest(
        id: _uuid.v4(),
        userId: _mockSignedInProfile.id,
        userVehicleId: userVehicle.id,
        manufacturerName: manufacturer,
        modelName: modelName,
        year: year,
        trimName: trimName,
        fuelType: fuelType,
        fuelLeague: league,
        vehicleClass: vehicleClass,
        memo: memo,
        status: 'pending_review',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ..._mockCustomVehicleReviewRequests,
    ];
    return userVehicle;
  }

  @override
  Future<List<CustomVehicleReviewRequest>> listCustomVehicleReviewRequests({
    String status = 'pending_review',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _mockCustomVehicleReviewRequests
        .where((item) => status == '전체' || item.status == status)
        .toList();
  }

  @override
  Future<CustomVehicleReviewRequest?> reviewCustomVehicleRequest({
    required String requestId,
    required String decision,
    String reviewNote = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (decision != 'approve' && decision != 'reject') {
      throw ArgumentError.value(
          decision, 'decision', 'approve 또는 reject만 지원합니다.');
    }
    final nextRequestStatus = decision == 'approve' ? 'approved' : 'rejected';
    final nextVehicleStatus = decision == 'approve' ? 'verified' : 'rejected';
    CustomVehicleReviewRequest? updated;
    _mockCustomVehicleReviewRequests =
        _mockCustomVehicleReviewRequests.map((item) {
      if (item.id != requestId) {
        return item;
      }
      updated = item.copyWith(
        status: nextRequestStatus,
        reviewNote: reviewNote,
        reviewedBy: _mockSignedInProfile.id,
        reviewedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return updated!;
    }).toList();
    if (updated == null) {
      return null;
    }
    _mockCustomVehicles = _mockCustomVehicles
        .map((vehicle) => vehicle.id == updated!.userVehicleId
            ? vehicle.copyWith(verificationStatus: nextVehicleStatus)
            : vehicle)
        .toList();
    final approved = decision == 'approve';
    _mockNotifications = [
      NotificationItem(
        id: _uuid.v4(),
        title: approved ? '직접 입력 차량 검수가 완료됐어요' : '직접 입력 차량 검수가 보류됐어요',
        body: approved
            ? '차량이 공식 리그에 반영됐어요. 랭킹과 배틀에 사용할 수 있습니다.'
            : '입력 정보를 다시 확인해 주세요. 차량 설정에서 다시 제출할 수 있습니다.',
        createdAt: DateTime.now(),
        isRead: false,
        notificationType: 'vehicle_review',
        targetRoute: '/settings/vehicles',
      ),
      ..._mockNotifications,
    ];
    return updated;
  }

  @override
  Future<List<FuelLeague>> getFuelLeagues() async => FuelLeague.all;
}

class SupabaseVehicleCatalogRepository implements VehicleCatalogRepository {
  SupabaseVehicleCatalogRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockVehicleCatalogRepository _fallback =
      const MockVehicleCatalogRepository();

  @override
  Future<List<VehicleManufacturer>> listManufacturers(
      {String? country, String? keyword}) async {
    try {
      var query = _client.from('vehicle_manufacturer_catalog_view').select();
      final rows = await query.order('sort_order');
      return rows.map((row) => VehicleManufacturer.fromJson(row)).where((item) {
        final countryMatches = _manufacturerCountryMatches(item, country);
        final normalized = keyword?.trim().toLowerCase() ?? '';
        final keywordMatches = normalized.isEmpty ||
            item.nameKo.toLowerCase().contains(normalized) ||
            item.nameEn.toLowerCase().contains(normalized);
        return countryMatches && keywordMatches;
      }).toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.listManufacturers(country: country, keyword: keyword);
    }
  }

  @override
  Future<List<VehicleModel>> listModels(String manufacturerId,
      {String? keyword}) async {
    try {
      final rows = await _client
          .from('vehicle_models')
          .select()
          .eq('manufacturer_id', manufacturerId)
          .order('sort_order');
      final normalized = keyword?.trim().toLowerCase() ?? '';
      return rows.map((row) => VehicleModel.fromJson(row)).where((item) {
        return normalized.isEmpty ||
            item.nameKo.toLowerCase().contains(normalized) ||
            item.nameEn.toLowerCase().contains(normalized);
      }).toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.listModels(manufacturerId, keyword: keyword);
    }
  }

  @override
  Future<List<VehicleModelYear>> listYears(String modelId) async {
    try {
      final rows = await _client
          .from('vehicle_model_years')
          .select()
          .eq('model_id', modelId)
          .order('year', ascending: false);
      return rows.map((row) => VehicleModelYear.fromJson(row)).toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.listYears(modelId);
    }
  }

  @override
  Future<List<VehicleVariant>> listVariants(String modelYearId) async {
    try {
      final rows = await _client
          .from('vehicle_catalog_view')
          .select()
          .eq('model_year_id', modelYearId)
          .eq('is_verified', true);
      return rows.map((row) => VehicleVariant.fromJson(row)).toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.listVariants(modelYearId);
    }
  }

  @override
  Future<List<VehicleVariant>> searchVehicleCatalog(String keyword) async {
    try {
      final normalized = keyword.trim();
      if (normalized.isEmpty) {
        return const [];
      }
      final rows = await _client
          .from('vehicle_catalog_view')
          .select()
          .eq('is_verified', true)
          .ilike('search_text', '%$normalized%')
          .limit(20);
      return rows.map((row) => VehicleVariant.fromJson(row)).toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.searchVehicleCatalog(keyword);
    }
  }

  @override
  Future<VehicleVariant?> getVariant(String variantId) async {
    try {
      final row = await _client
          .from('vehicle_catalog_view')
          .select()
          .eq('id', variantId)
          .maybeSingle();
      return row == null ? null : VehicleVariant.fromJson(row);
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getVariant(variantId);
    }
  }

  @override
  Future<UserVehicle> createCustomVehicleRequest({
    required String manufacturer,
    required String modelName,
    required int year,
    required String trimName,
    required String fuelType,
    required String vehicleClass,
    String nickname = '',
    String memo = '',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.createCustomVehicleRequest(
        manufacturer: manufacturer,
        modelName: modelName,
        year: year,
        trimName: trimName,
        fuelType: fuelType,
        vehicleClass: vehicleClass,
        nickname: nickname,
        memo: memo,
      );
    }
    final fuelLeague = FuelLeague.keyForFuelType(fuelType);
    try {
      final row = await _client
          .from('user_vehicles')
          .insert({
            'user_id': userId,
            'nickname': nickname.isEmpty ? '$modelName $trimName' : nickname,
            'is_primary': false,
            'verification_status': 'pendingReview',
            'fuel_type': fuelType,
            'fuel_league': fuelLeague,
            'vehicle_class': vehicleClass,
          })
          .select()
          .single();

      await _client.from('custom_vehicle_requests').insert({
        'user_id': userId,
        'user_vehicle_id': row['id'],
        'manufacturer_name': manufacturer,
        'model_name': modelName,
        'year': year,
        'trim_name': trimName,
        'fuel_type': fuelType,
        'fuel_league': fuelLeague,
        'vehicle_class': vehicleClass,
        'memo': memo,
        'status': 'pending_review',
      });

      return UserVehicle(
        id: '${row['id'] ?? ''}',
        userId: userId,
        nickname: '${row['nickname'] ?? nickname}',
        isPrimary: row['is_primary'] == true,
        verificationStatus: '${row['verification_status'] ?? 'pendingReview'}',
        fuelType: fuelType,
        fuelLeague: fuelLeague,
        vehicleClass: vehicleClass,
        variant: VehicleVariant(
          id: 'custom-${row['id'] ?? _uuid.v4()}',
          modelYearId: 'custom',
          manufacturerName: manufacturer,
          modelName: modelName,
          year: year,
          trimName: trimName,
          fuelType: fuelType,
          vehicleClass: vehicleClass,
          fuelLeague: fuelLeague,
          efficiencyUnit: fuelLeague == 'electric' ? 'km/kWh' : 'km/L',
          isVerified: false,
        ),
      );
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.createCustomVehicleRequest(
        manufacturer: manufacturer,
        modelName: modelName,
        year: year,
        trimName: trimName,
        fuelType: fuelType,
        vehicleClass: vehicleClass,
        nickname: nickname,
        memo: memo,
      );
    }
  }

  @override
  Future<List<CustomVehicleReviewRequest>> listCustomVehicleReviewRequests({
    String status = 'pending_review',
  }) async {
    try {
      var builder = _client.from('custom_vehicle_requests').select();
      if (status != '전체') {
        builder = builder.eq('status', status);
      }
      final rows =
          await builder.order('created_at', ascending: false).limit(50);
      return rows
          .map((row) => _customVehicleReviewRequestFromJson(
              Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.listCustomVehicleReviewRequests(status: status);
    }
  }

  @override
  Future<CustomVehicleReviewRequest?> reviewCustomVehicleRequest({
    required String requestId,
    required String decision,
    String reviewNote = '',
  }) async {
    try {
      final request = await _getCustomVehicleReviewRequest(requestId);
      if (request == null) {
        return null;
      }
      final response = await _client.functions.invoke(
        'review_custom_vehicle',
        body: {
          'customVehicleRequestId': request.id,
          'userVehicleId': request.userVehicleId,
          'decision': decision,
          'fuelType': request.fuelType,
          'fuelLeague': request.fuelLeague,
          'vehicleClass': request.vehicleClass,
          'reviewNote': reviewNote,
        },
      );
      final data = _functionResponseMap(response.data);
      if (data['error'] != null) {
        throw StateError('${data['error']}');
      }
      return _getCustomVehicleReviewRequest(requestId);
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.reviewCustomVehicleRequest(
        requestId: requestId,
        decision: decision,
        reviewNote: reviewNote,
      );
    }
  }

  Future<CustomVehicleReviewRequest?> _getCustomVehicleReviewRequest(
    String requestId,
  ) async {
    final row = await _client
        .from('custom_vehicle_requests')
        .select()
        .eq('id', requestId)
        .maybeSingle();
    return row == null
        ? null
        : _customVehicleReviewRequestFromJson(Map<String, dynamic>.from(row));
  }

  CustomVehicleReviewRequest _customVehicleReviewRequestFromJson(
    Map<String, dynamic> json,
  ) {
    return CustomVehicleReviewRequest(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      userVehicleId: '${json['user_vehicle_id'] ?? ''}',
      manufacturerName: '${json['manufacturer_name'] ?? ''}',
      modelName: '${json['model_name'] ?? ''}',
      year: _intFrom(json['year'], DateTime.now().year),
      trimName: '${json['trim_name'] ?? ''}',
      fuelType: '${json['fuel_type'] ?? ''}',
      fuelLeague: '${json['fuel_league'] ?? ''}',
      vehicleClass: '${json['vehicle_class'] ?? ''}',
      memo: '${json['memo'] ?? ''}',
      status: '${json['status'] ?? 'pending_review'}',
      reviewNote: '${json['review_note'] ?? ''}',
      reviewedBy: '${json['reviewed_by'] ?? ''}',
      reviewedAt: DateTime.tryParse('${json['reviewed_at'] ?? ''}'),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  @override
  Future<List<FuelLeague>> getFuelLeagues() async {
    try {
      final rows = await _client
          .from('fuel_leagues')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      return rows.map((row) => FuelLeague.fromJson(row)).toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getFuelLeagues();
    }
  }
}

abstract class UserVehicleRepository {
  Future<List<UserVehicle>> listUserVehicles();

  Future<UserVehicle> addUserVehicleFromVariant(
      String variantId, String nickname, bool isPrimary);

  Future<UserVehicle> addCustomUserVehicle(UserVehicle vehicle);

  Future<void> setPrimaryVehicle(String userVehicleId);

  Future<UserVehicle> updateUserVehicle(UserVehicle vehicle);

  Future<void> deleteUserVehicle(String userVehicleId);

  Future<UserVehicle?> getPrimaryVehicle();

  Future<LeagueMembership> assignLeagueForVehicle(String userVehicleId);
}

class MockUserVehicleRepository implements UserVehicleRepository {
  MockUserVehicleRepository(
      {VehicleCatalogRepository catalogRepository =
          const MockVehicleCatalogRepository()})
      : _catalogRepository = catalogRepository;

  final VehicleCatalogRepository _catalogRepository;

  @override
  Future<List<UserVehicle>> listUserVehicles() async {
    final primary = _mockPrimaryVehicle;
    return [
      if (primary != null)
        UserVehicle(
          id: primary.id,
          userId: primary.userId,
          nickname: primary.nickname,
          isPrimary: true,
          fuelType: primary.fuelType,
          fuelLeague: primary.leagueKey,
          vehicleClass: primary.vehicleClass,
        ),
      ..._mockCustomVehicles,
    ];
  }

  @override
  Future<UserVehicle?> getPrimaryVehicle() async {
    final primary = _mockPrimaryVehicle;
    if (primary == null) {
      return null;
    }
    return UserVehicle(
      id: primary.id,
      userId: primary.userId,
      nickname: primary.nickname,
      isPrimary: true,
      fuelType: primary.fuelType,
      fuelLeague: primary.leagueKey,
      vehicleClass: primary.vehicleClass,
    );
  }

  @override
  Future<UserVehicle> addUserVehicleFromVariant(
      String variantId, String nickname, bool isPrimary) async {
    final variant = await _catalogRepository.getVariant(variantId);
    if (variant == null) {
      throw StateError('선택한 차량 파워트레인을 찾을 수 없습니다.');
    }
    final userVehicle = UserVehicle(
      id: _uuid.v4(),
      userId: _mockSignedInProfile.id,
      vehicleVariantId: variant.id,
      variant: variant,
      nickname: nickname.isEmpty
          ? '${variant.modelName} ${variant.trimName}'
          : nickname,
      isPrimary: isPrimary,
      verificationStatus: variant.isVerified ? 'verified' : 'pendingReview',
      fuelType: variant.fuelType,
      fuelLeague: variant.fuelLeague,
      vehicleClass: variant.vehicleClass,
    );
    if (isPrimary) {
      _mockPrimaryVehicle = userVehicle.toVehicle();
      _mockSignedInProfile = _mockSignedInProfile.copyWith(
        representativeVehicleId: userVehicle.id,
        representativeVehicleName: variant.displayName,
        selectedFuelLeague: variant.fuelLeague,
        selectedVehicleClass: variant.vehicleClass,
        vehicleSetupCompleted: true,
        additionalSetupCompleted: true,
        updatedAt: DateTime.now(),
      );
    }
    return userVehicle;
  }

  @override
  Future<UserVehicle> addCustomUserVehicle(UserVehicle vehicle) async {
    _mockCustomVehicles = [
      ..._mockCustomVehicles.where((item) => item.id != vehicle.id),
      vehicle,
    ];
    if (vehicle.isPrimary) {
      _mockPrimaryVehicle = vehicle.toVehicle();
    }
    return vehicle;
  }

  @override
  Future<void> setPrimaryVehicle(String userVehicleId) async {
    await MockVehicleRepository().setPrimaryVehicle(userVehicleId);
  }

  @override
  Future<UserVehicle> updateUserVehicle(UserVehicle vehicle) async => vehicle;

  @override
  Future<void> deleteUserVehicle(String userVehicleId) async {
    await MockVehicleRepository().deleteVehicle(userVehicleId);
  }

  @override
  Future<LeagueMembership> assignLeagueForVehicle(String userVehicleId) async {
    final primary = _mockPrimaryVehicle;
    if (primary == null || primary.id != userVehicleId) {
      throw StateError('대표 차량을 먼저 설정해주세요.');
    }
    return LeagueMembership(
      id: _uuid.v4(),
      userId: primary.userId,
      userVehicleId: primary.id,
      fuelLeague: primary.leagueKey,
      vehicleClass: primary.vehicleClass,
      seasonId: mockSeason.id,
    );
  }
}

class SupabaseUserVehicleRepository implements UserVehicleRepository {
  SupabaseUserVehicleRepository({
    VehicleCatalogRepository catalogRepository =
        const MockVehicleCatalogRepository(),
    SupabaseClient? client,
  })  : _catalogRepository = catalogRepository,
        _client = client ?? Supabase.instance.client;

  final VehicleCatalogRepository _catalogRepository;
  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('로그인된 사용자를 찾을 수 없습니다.');
    }
    return user.id;
  }

  UserVehicle _fromRow(Map<String, dynamic> row, {VehicleVariant? variant}) {
    return UserVehicle(
      id: '${row['id'] ?? ''}',
      userId: '${row['user_id'] ?? ''}',
      vehicleVariantId: '${row['vehicle_variant_id'] ?? ''}',
      variant: variant,
      nickname: '${row['nickname'] ?? ''}',
      isPrimary: row['is_primary'] == true,
      verificationStatus: '${row['verification_status'] ?? 'verified'}',
      fuelType: '${row['fuel_type'] ?? variant?.fuelType ?? ''}',
      fuelLeague: '${row['fuel_league'] ?? variant?.fuelLeague ?? 'other'}',
      vehicleClass: '${row['vehicle_class'] ?? variant?.vehicleClass ?? ''}',
    );
  }

  Future<UserVehicle> _withVariant(UserVehicle userVehicle) async {
    if (userVehicle.variant != null || userVehicle.vehicleVariantId.isEmpty) {
      return userVehicle;
    }
    final variant =
        await _catalogRepository.getVariant(userVehicle.vehicleVariantId);
    if (variant == null) {
      return userVehicle;
    }
    return UserVehicle(
      id: userVehicle.id,
      userId: userVehicle.userId,
      vehicleVariantId: userVehicle.vehicleVariantId,
      variant: variant,
      nickname: userVehicle.nickname,
      isPrimary: userVehicle.isPrimary,
      verificationStatus: userVehicle.verificationStatus,
      fuelType: userVehicle.fuelType,
      fuelLeague: userVehicle.fuelLeague,
      vehicleClass: userVehicle.vehicleClass,
    );
  }

  Future<void> _syncLegacyVehicle(UserVehicle userVehicle) async {
    final vehicle = userVehicle.toVehicle();
    await _client.from('vehicles').upsert({
      'id': vehicle.id,
      'user_id': vehicle.userId,
      'vehicle_variant_id': userVehicle.vehicleVariantId.isEmpty
          ? null
          : userVehicle.vehicleVariantId,
      'manufacturer': vehicle.manufacturer,
      'model_name': vehicle.modelName,
      'model_year': vehicle.modelYear,
      'fuel_type': vehicle.fuelType,
      'fuel_league': vehicle.leagueKey,
      'displacement': vehicle.displacement,
      'vehicle_class': vehicle.vehicleClass,
      'nickname': vehicle.nickname,
      'is_primary': vehicle.isPrimary,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _updateProfileForPrimary(UserVehicle userVehicle) async {
    final vehicle = userVehicle.toVehicle();
    await _client.from('profiles').update({
      'representative_vehicle_id': vehicle.id,
      'representative_vehicle_name': vehicle.displayName,
      'selected_fuel_league': vehicle.leagueKey,
      'selected_vehicle_class': vehicle.vehicleClass,
      'vehicle_setup_completed': true,
      'additional_setup_completed': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _userId);
  }

  @override
  Future<List<UserVehicle>> listUserVehicles() async {
    final rows = await _client
        .from('user_vehicles')
        .select()
        .eq('user_id', _userId)
        .order('created_at');
    return rows.map((row) => _fromRow(row)).toList();
  }

  @override
  Future<UserVehicle?> getPrimaryVehicle() async {
    final row = await _client
        .from('user_vehicles')
        .select()
        .eq('user_id', _userId)
        .eq('is_primary', true)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return _withVariant(_fromRow(row));
  }

  @override
  Future<UserVehicle> addUserVehicleFromVariant(
      String variantId, String nickname, bool isPrimary) async {
    final variant = await _catalogRepository.getVariant(variantId);
    if (variant == null) {
      throw StateError('선택한 차량 파워트레인을 찾을 수 없습니다.');
    }
    if (isPrimary) {
      await _client
          .from('user_vehicles')
          .update({'is_primary': false}).eq('user_id', _userId);
      await _client
          .from('vehicles')
          .update({'is_primary': false}).eq('user_id', _userId);
    }
    final row = await _client
        .from('user_vehicles')
        .insert({
          'user_id': _userId,
          'vehicle_variant_id': variant.id,
          'nickname': nickname.isEmpty
              ? '${variant.modelName} ${variant.trimName}'
              : nickname,
          'is_primary': isPrimary,
          'verification_status':
              variant.isVerified ? 'verified' : 'pendingReview',
          'fuel_type': variant.fuelType,
          'fuel_league': variant.fuelLeague,
          'vehicle_class': variant.vehicleClass,
        })
        .select()
        .single();
    final userVehicle = _fromRow(row, variant: variant);
    await _syncLegacyVehicle(userVehicle);
    if (isPrimary) {
      await _updateProfileForPrimary(userVehicle);
    }
    return userVehicle;
  }

  @override
  Future<UserVehicle> addCustomUserVehicle(UserVehicle vehicle) async {
    if (vehicle.isPrimary) {
      await _client
          .from('user_vehicles')
          .update({'is_primary': false}).eq('user_id', _userId);
      await _client
          .from('vehicles')
          .update({'is_primary': false}).eq('user_id', _userId);
    }
    final row = await _client
        .from('user_vehicles')
        .insert({
          'user_id': _userId,
          'vehicle_variant_id': vehicle.vehicleVariantId.isEmpty
              ? null
              : vehicle.vehicleVariantId,
          'nickname': vehicle.nickname,
          'is_primary': vehicle.isPrimary,
          'verification_status': vehicle.verificationStatus,
          'fuel_type': vehicle.fuelType,
          'fuel_league': vehicle.fuelLeague,
          'vehicle_class': vehicle.vehicleClass,
        })
        .select()
        .single();
    final saved = _fromRow(row, variant: vehicle.variant);
    await _syncLegacyVehicle(saved);
    if (saved.isPrimary) {
      await _updateProfileForPrimary(saved);
    }
    return saved;
  }

  @override
  Future<void> setPrimaryVehicle(String userVehicleId) async {
    await _client
        .from('user_vehicles')
        .update({'is_primary': false}).eq('user_id', _userId);
    await _client
        .from('vehicles')
        .update({'is_primary': false}).eq('user_id', _userId);
    final row = await _client
        .from('user_vehicles')
        .update({
          'is_primary': true,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('id', userVehicleId)
        .eq('user_id', _userId)
        .select()
        .single();
    final userVehicle = await _withVariant(_fromRow(row));
    await _client
        .from('vehicles')
        .update({
          'is_primary': true,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('id', userVehicleId)
        .eq('user_id', _userId);
    await _updateProfileForPrimary(userVehicle);
  }

  @override
  Future<UserVehicle> updateUserVehicle(UserVehicle vehicle) async {
    final row = await _client
        .from('user_vehicles')
        .update({
          'nickname': vehicle.nickname,
          'is_primary': vehicle.isPrimary,
          'verification_status': vehicle.verificationStatus,
          'fuel_type': vehicle.fuelType,
          'fuel_league': vehicle.fuelLeague,
          'vehicle_class': vehicle.vehicleClass,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', vehicle.id)
        .eq('user_id', _userId)
        .select()
        .single();
    final updated = _fromRow(row, variant: vehicle.variant);
    await _syncLegacyVehicle(updated);
    if (updated.isPrimary) {
      await _updateProfileForPrimary(updated);
    }
    return updated;
  }

  @override
  Future<void> deleteUserVehicle(String userVehicleId) async {
    await _client
        .from('user_vehicles')
        .delete()
        .eq('id', userVehicleId)
        .eq('user_id', _userId);
    await _client
        .from('vehicles')
        .delete()
        .eq('id', userVehicleId)
        .eq('user_id', _userId);
  }

  @override
  Future<LeagueMembership> assignLeagueForVehicle(String userVehicleId) async {
    final row = await _client
        .from('user_vehicles')
        .select()
        .eq('id', userVehicleId)
        .eq('user_id', _userId)
        .single();
    final userVehicle = await _withVariant(_fromRow(row));
    await _client
        .from('league_memberships')
        .update({'is_active': false}).eq('user_id', _userId);
    final membership = await _client
        .from('league_memberships')
        .upsert({
          'user_id': _userId,
          'user_vehicle_id': userVehicle.id,
          'fuel_league': userVehicle.fuelLeague,
          'vehicle_class': userVehicle.vehicleClass,
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,user_vehicle_id,fuel_league,vehicle_class')
        .select()
        .single();
    return LeagueMembership(
      id: '${membership['id'] ?? ''}',
      userId: '${membership['user_id'] ?? ''}',
      userVehicleId: '${membership['user_vehicle_id'] ?? ''}',
      fuelLeague: '${membership['fuel_league'] ?? ''}',
      vehicleClass: '${membership['vehicle_class'] ?? ''}',
      seasonId: '${membership['season_id'] ?? ''}',
      isActive: membership['is_active'] != false,
    );
  }
}

abstract class LeagueRepository {
  Future<List<FuelLeague>> getFuelLeagues();

  Future<LeagueMembership?> getMyLeague();

  Future<List<RankingEntry>> getLeagueRankings(
      {required String fuelLeague, required String vehicleClass});

  Future<LeagueMembership> assignLeagueMembership(String userVehicleId);

  Future<LeagueMembership> switchActiveVehicleLeague(String userVehicleId);
}

class MockLeagueRepository implements LeagueRepository {
  @override
  Future<List<FuelLeague>> getFuelLeagues() async => FuelLeague.all;

  @override
  Future<LeagueMembership?> getMyLeague() async {
    final primary = _mockPrimaryVehicle;
    if (primary == null) {
      return null;
    }
    return LeagueMembership(
      id: 'membership-${primary.id}',
      userId: primary.userId,
      userVehicleId: primary.id,
      fuelLeague: primary.leagueKey,
      vehicleClass: primary.vehicleClass,
      seasonId: mockSeason.id,
    );
  }

  @override
  Future<List<RankingEntry>> getLeagueRankings(
      {required String fuelLeague, required String vehicleClass}) async {
    return mockRankings
        .where((entry) =>
            entry.leagueKey == fuelLeague &&
            (vehicleClass.isEmpty || entry.vehicleClass == vehicleClass))
        .toList();
  }

  @override
  Future<LeagueMembership> assignLeagueMembership(String userVehicleId) {
    return MockUserVehicleRepository().assignLeagueForVehicle(userVehicleId);
  }

  @override
  Future<LeagueMembership> switchActiveVehicleLeague(String userVehicleId) {
    return assignLeagueMembership(userVehicleId);
  }
}

class SupabaseLeagueRepository implements LeagueRepository {
  SupabaseLeagueRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('로그인된 사용자를 찾을 수 없습니다.');
    }
    return user.id;
  }

  LeagueMembership _membershipFromRow(Map<String, dynamic> row) {
    return LeagueMembership(
      id: '${row['id'] ?? ''}',
      userId: '${row['user_id'] ?? ''}',
      userVehicleId: '${row['user_vehicle_id'] ?? ''}',
      fuelLeague: '${row['fuel_league'] ?? ''}',
      vehicleClass: '${row['vehicle_class'] ?? ''}',
      seasonId: '${row['season_id'] ?? ''}',
      isActive: row['is_active'] != false,
    );
  }

  @override
  Future<List<FuelLeague>> getFuelLeagues() async {
    final rows = await _client
        .from('fuel_leagues')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return rows.map((row) => FuelLeague.fromJson(row)).toList();
  }

  @override
  Future<LeagueMembership?> getMyLeague() async {
    final row = await _client
        .from('league_memberships')
        .select()
        .eq('user_id', _userId)
        .eq('is_active', true)
        .maybeSingle();
    return row == null ? null : _membershipFromRow(row);
  }

  @override
  Future<List<RankingEntry>> getLeagueRankings(
      {required String fuelLeague, required String vehicleClass}) async {
    final rows = vehicleClass.isEmpty
        ? await _client
            .from('public_rankings')
            .select()
            .eq('fuel_league', fuelLeague)
            .order('rank')
        : await _client
            .from('public_rankings')
            .select()
            .eq('fuel_league', fuelLeague)
            .eq('vehicle_class', vehicleClass)
            .order('rank');
    return rows
        .map(
          (row) => RankingEntry(
            rank: (row['rank'] as num?)?.toInt() ?? 0,
            previousRank: (row['previous_rank'] as num?)?.toInt() ?? 0,
            nickname: '${row['nickname'] ?? 'Driver'}',
            tier: '${row['tier'] ?? 'Bronze I'}',
            score: (row['score'] as num?)?.toInt() ?? 0,
            vehicleClass: '${row['vehicle_class'] ?? ''}',
            fuelType: '${row['fuel_type'] ?? ''}',
            fuelLeague: '${row['fuel_league'] ?? fuelLeague}',
            isCurrentUser: '${row['user_id'] ?? ''}' == _userId,
          ),
        )
        .toList();
  }

  @override
  Future<LeagueMembership> assignLeagueMembership(String userVehicleId) {
    return SupabaseUserVehicleRepository(
        client: _client,
        catalogRepository: SupabaseVehicleCatalogRepository(
          client: _client,
          allowMockFallback: allowMockFallback,
        )).assignLeagueForVehicle(userVehicleId);
  }

  @override
  Future<LeagueMembership> switchActiveVehicleLeague(String userVehicleId) {
    return assignLeagueMembership(userVehicleId);
  }
}

abstract class HomeRepository {
  Future<HomeSnapshot> getHomeSnapshot();
}

class MockHomeRepository implements HomeRepository {
  @override
  Future<HomeSnapshot> getHomeSnapshot() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return HomeSnapshot(
      profile: _mockSignedInProfile,
      vehicle: _mockPrimaryVehicle,
      activeBattle: mockBattles.first,
      todayMission: mockMissions.first,
      season: mockSeason,
      rival: mockRival,
      latestDriveScore: mockDriveScore,
      sponsorChallenge: mockSponsorChallenge,
      classRank: 18,
      totalRank: 1284,
      overtakenToday: 3,
    );
  }
}

Battle _emptyBattle() {
  final now = DateTime.now();
  return Battle(
    id: 'no-active-battle',
    title: '진행 중인 배틀이 없어요',
    battleType: '공개 매칭',
    status: '비활성',
    ruleType: '연비 점수',
    startAt: now,
    endAt: now,
    myScore: 0,
    opponentScore: 0,
    opponentNickname: '매칭 대기',
    rewardSummary: '배틀이 열리면 표시됩니다',
  );
}

Season _emptySeason({
  int seasonScore = 0,
  String currentLeague = '리그 미설정',
}) {
  final now = DateTime.now();
  return Season(
    id: 'no-active-season',
    name: '시즌 데이터가 아직 없어요',
    description: '운영 시즌이 설정되면 점수와 보상이 표시됩니다.',
    startAt: now,
    currentLeague: currentLeague,
    seasonScore: seasonScore,
    promotionTargetScore: 1,
    endsAt: now,
    status: 'inactive',
    rewardProgress: 0,
  );
}

SeasonMission _emptySeasonMission() {
  return const SeasonMission(
    id: 'no-active-mission',
    title: '오늘 표시할 미션이 없어요',
    description: '시즌 미션이 열리면 이곳에서 진행률을 확인할 수 있습니다.',
    progress: 0,
    target: 1,
    rewardXp: 0,
    isWeekly: false,
  );
}

Rival _emptyRival() {
  return const Rival(
    id: 'no-rival',
    nickname: '리그 라이벌',
    scoreGap: 0,
    message: '랭킹이 집계되면 추월 목표가 표시됩니다.',
  );
}

DriveScore _emptyDriveScore(String userId) {
  return DriveScore(
    id: 'no-drive-score',
    driveSessionId: '',
    userId: userId,
    totalScore: 0,
    efficiencyScore: 0,
    stabilityScore: 0,
    classPercentile: 0,
    accelerationPenalty: 0,
    brakingPenalty: 0,
    idlePenalty: 0,
    distanceBonus: 0,
    consistencyBonus: 0,
    verificationStatus: 'not_started',
    createdAt: DateTime.now(),
  );
}

SponsorChallenge _emptySponsorChallenge() {
  return SponsorChallenge(
    id: 'no-sponsor-challenge',
    sponsorName: 'Fuel Arena',
    title: '참여 가능한 스폰서 챌린지가 없어요',
    description: '새 챌린지가 열리면 보상 조건이 표시됩니다.',
    rewardSummary: '보상 없음',
    endsAt: DateTime.now(),
  );
}

class SupabaseHomeRepository implements HomeRepository {
  SupabaseHomeRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;

  @override
  Future<HomeSnapshot> getHomeSnapshot() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return MockHomeRepository().getHomeSnapshot();
    }
    final profileRow =
        await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    if (profileRow == null && !allowMockFallback) {
      throw StateError('프로필을 찾을 수 없습니다.');
    }
    final profile =
        profileRow == null ? mockProfile : UserProfile.fromJson(profileRow);
    final vehicle =
        await SupabaseVehicleRepository(client: _client).getPrimaryVehicle();
    final battles = await _loadBattles();
    final seasonRepository = SupabaseSeasonRepository(
      client: _client,
      allowMockFallback: allowMockFallback,
    );
    final season = await _loadSeason(seasonRepository);
    final missions = await _loadMissions(seasonRepository);
    final sponsorChallenges = await _loadSponsorChallenges();

    int classRank = 18;
    int totalRank = 1284;
    int overtakenToday = 3;

    try {
      final rankingRepo = SupabaseRankingRepository(client: _client);
      final classRankings = await rankingRepo.getRankings('내 리그');
      final myClass = classRankings.where((e) => e.userId == user.id).firstOrNull;
      if (myClass != null) {
        classRank = myClass.rank;
      }
      
      final allRankings = await rankingRepo.getRankings('');
      final myTotal = allRankings.where((e) => e.userId == user.id).firstOrNull;
      if (myTotal != null) {
        totalRank = myTotal.rank;
      }
    } catch (_) {
      // ignore
    }

    return HomeSnapshot(
      profile: profile,
      vehicle: vehicle,
      activeBattle: _selectHomeBattle(battles),
      todayMission: _selectTodayMission(missions),
      season: season,
      rival: allowMockFallback ? mockRival : _emptyRival(),
      latestDriveScore: await _loadLatestDriveScore(user.id),
      sponsorChallenge: sponsorChallenges.isEmpty
          ? (allowMockFallback
              ? mockSponsorChallenge
              : _emptySponsorChallenge())
          : sponsorChallenges.first,
      classRank: classRank,
      totalRank: totalRank,
      overtakenToday: overtakenToday,
    );
  }

  Future<List<Battle>> _loadBattles() async {
    try {
      return await SupabaseBattleRepository(client: _client).getBattles();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _mockBattles;
    }
  }

  Future<Season> _loadSeason(SupabaseSeasonRepository repository) async {
    try {
      return await repository.getCurrentSeason();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return mockSeason;
    }
  }

  Future<List<SeasonMission>> _loadMissions(
    SupabaseSeasonRepository repository,
  ) async {
    try {
      return await repository.getMissions();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return mockMissions;
    }
  }

  Future<List<SponsorChallenge>> _loadSponsorChallenges() async {
    try {
      return await SupabaseSponsorRepository(
        client: _client,
        allowMockFallback: allowMockFallback,
      ).getChallenges();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return mockSponsorChallenges;
    }
  }

  Future<DriveScore> _loadLatestDriveScore(String userId) async {
    try {
      final row = await _client
          .from('drive_scores')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null
          ? (allowMockFallback
              ? DriveScore.fromJson({
                  ...mockDriveScore.toJson(),
                  'user_id': userId,
                })
              : _emptyDriveScore(userId))
          : DriveScore.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return DriveScore.fromJson(
          {...mockDriveScore.toJson(), 'user_id': userId});
    }
  }

  Battle _selectHomeBattle(List<Battle> battles) {
    if (battles.isEmpty) {
      return allowMockFallback ? mockBattles.first : _emptyBattle();
    }
    return battles.firstWhere(
      (battle) => !['completed', '종료'].contains(battle.status),
      orElse: () => battles.first,
    );
  }

  SeasonMission _selectTodayMission(List<SeasonMission> missions) {
    if (missions.isEmpty) {
      return allowMockFallback ? mockMissions.first : _emptySeasonMission();
    }
    return missions.firstWhere(
      (mission) => !mission.isWeekly && !mission.rewardClaimed,
      orElse: () => missions.firstWhere(
        (mission) => !mission.rewardClaimed,
        orElse: () => missions.first,
      ),
    );
  }
}

abstract class DriveRepository {
  Future<Vehicle> getRepresentativeVehicle();

  Future<SeasonMission> getTodayMission();

  Future<DriveSession> startDriveSession();

  Future<DriveSession> uploadQueuedDriveSession(DriveSession session);

  Future<void> recordDrivePoints(List<DrivePoint> points);

  Future<List<DriveSession>> listDriveSessions({int limit = 20});

  Future<List<DriveScore>> listDriveScores({int limit = 20});

  Future<DriveScore> finishDriveSession({
    String? sessionId,
    double? distanceKm,
    Duration? duration,
    double? averageEfficiency,
    double? fuelUsedLiters,
  });
}

class MockDriveRepository implements DriveRepository {
  int _boundedLimit(int limit) => limit < 1 ? 1 : (limit > 100 ? 100 : limit);

  @override
  Future<void> recordDrivePoints(List<DrivePoint> points) async {}

  @override
  Future<List<DriveSession>> listDriveSessions({int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return mockDriveSessions.take(_boundedLimit(limit)).toList();
  }

  @override
  Future<List<DriveScore>> listDriveScores({int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return mockDriveScores.take(_boundedLimit(limit)).toList();
  }

  @override
  Future<DriveScore> finishDriveSession({
    String? sessionId,
    double? distanceKm,
    Duration? duration,
    double? averageEfficiency,
    double? fuelUsedLiters,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return DriveScore.fromJson({
      ...mockDriveScore.toJson(),
      'drive_session_id': sessionId ?? mockDriveScore.driveSessionId,
      'user_id': mockProfile.id,
    });
  }

  @override
  Future<Vehicle> getRepresentativeVehicle() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _mockPrimaryVehicle ?? mockVehicle;
  }

  @override
  Future<SeasonMission> getTodayMission() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return mockMissions.first;
  }

  @override
  Future<DriveSession> startDriveSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return DriveSession(
      id: _uuid.v4(),
      vehicleId: (_mockPrimaryVehicle ?? mockVehicle).id,
      startedAt: DateTime.now(),
      duration: Duration.zero,
      distanceKm: 0,
      averageFuelEfficiency: 0,
      status: 'recording',
    );
  }

  @override
  Future<DriveSession> uploadQueuedDriveSession(DriveSession session) async {
    return session;
  }
}

class SupabaseDriveRepository implements DriveRepository {
  SupabaseDriveRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockDriveRepository _fallback = MockDriveRepository();

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('로그인된 사용자를 찾을 수 없습니다.');
    }
    return user.id;
  }

  int _boundedLimit(int limit) => limit < 1 ? 1 : (limit > 100 ? 100 : limit);

  @override
  Future<void> recordDrivePoints(List<DrivePoint> points) async {
    if (points.isEmpty) {
      return;
    }
    try {
      await _client.from('drive_points').insert(
            points.map((point) => _drivePointInsertPayload(point)).toList(),
          );
    } catch (error, stackTrace) {
      final driveSessionId = points.first.driveSessionId;
      _logger.warning(
        'record_drive_points skipped',
        context: {
          'drive_session_id': driveSessionId,
          'point_count': points.length,
        },
      );
      _logger.error(
        'record_drive_points failed',
        error: error,
        stackTrace: stackTrace,
        context: {
          'drive_session_id': driveSessionId,
          'point_count': points.length,
        },
      );
      rethrow;
    }
  }

  Map<String, dynamic> _drivePointInsertPayload(DrivePoint point) {
    return {
      if (_isUuidLike(point.id)) 'id': point.id,
      'drive_session_id': point.driveSessionId,
      'latitude': point.latitude,
      'longitude': point.longitude,
      'speed_kmh': point.speedKmh,
      'accuracy': point.accuracy,
      'recorded_at': point.recordedAt.toIso8601String(),
      'is_mocked': point.isMocked,
      'user_id': _userId,
    };
  }

  bool _isUuidLike(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  @override
  Future<List<DriveSession>> listDriveSessions({int limit = 20}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.listDriveSessions(limit: limit);
    }
    try {
      final rows = await _client
          .from('drive_sessions')
          .select(
              'id,user_id,vehicle_id,started_at,ended_at,duration_seconds,distance_km,fuel_used_liters,average_efficiency,source_type,drive_context,status,created_at')
          .eq('user_id', user.id)
          .order('started_at', ascending: false)
          .limit(_boundedLimit(limit));
      final sessions = rows
          .map<DriveSession>(
            (row) => DriveSession.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
      return sessions;
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.listDriveSessions(limit: limit);
    }
  }

  @override
  Future<List<DriveScore>> listDriveScores({int limit = 20}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.listDriveScores(limit: limit);
    }
    try {
      final rows = await _client
          .from('drive_scores')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(_boundedLimit(limit));
      return rows
          .map<DriveScore>(
            (row) => DriveScore.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.listDriveScores(limit: limit);
    }
  }

  @override
  Future<DriveScore> finishDriveSession({
    String? sessionId,
    double? distanceKm,
    Duration? duration,
    double? averageEfficiency,
    double? fuelUsedLiters,
  }) async {
    try {
      final resolvedSessionId = await _resolveDriveSessionId(sessionId);
      if (resolvedSessionId.isEmpty || _isLocalSessionId(resolvedSessionId)) {
        return _finishDriveSessionFallback(
          sessionId: sessionId,
          distanceKm: distanceKm,
          duration: duration,
          averageEfficiency: averageEfficiency,
          fuelUsedLiters: fuelUsedLiters,
        );
      }

      final response = await _client.functions.invoke(
        'finish_drive_session',
        body: {
          'sessionId': resolvedSessionId,
          'distanceKm': _nonNegativeDouble(distanceKm),
          'durationSeconds': _nonNegativeInt(duration?.inSeconds),
          'averageEfficiency': _nonNegativeDouble(averageEfficiency),
          'fuelUsedLiters': _nonNegativeDouble(fuelUsedLiters),
        },
      );
      final data = _functionResponseMap(response.data);
      if (data['error'] != null) {
        throw StateError('${data['error']}');
      }
      final scoreData = data['score'];
      if (scoreData is Map) {
        return DriveScore.fromJson(Map<String, dynamic>.from(scoreData));
      }
      return DriveScore.fromJson(data);
    } catch (error, stackTrace) {
      _logger.warning(
        'finish_drive_session fallback',
        context: {'session_id': sessionId},
      );
      _logger.error(
        'finish_drive_session edge call failed',
        error: error,
        stackTrace: stackTrace,
        context: {'session_id': sessionId},
      );
      if (!allowMockFallback) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      return _finishDriveSessionFallback(
        sessionId: sessionId,
        distanceKm: distanceKm,
        duration: duration,
        averageEfficiency: averageEfficiency,
        fuelUsedLiters: fuelUsedLiters,
      );
    }
  }

  Future<DriveScore> _finishDriveSessionFallback({
    String? sessionId,
    double? distanceKm,
    Duration? duration,
    double? averageEfficiency,
    double? fuelUsedLiters,
  }) {
    if (!allowMockFallback) {
      throw StateError('공식 주행 세션 검증을 완료하지 못했습니다.');
    }
    return _fallback.finishDriveSession(
      sessionId: sessionId,
      distanceKm: distanceKm,
      duration: duration,
      averageEfficiency: averageEfficiency,
      fuelUsedLiters: fuelUsedLiters,
    );
  }

  Future<String> _resolveDriveSessionId(String? sessionId) async {
    final trimmed = sessionId?.trim() ?? '';
    if (trimmed.isNotEmpty && !_isLocalSessionId(trimmed)) {
      return trimmed;
    }
    final row = await _client
        .from('drive_sessions')
        .select('id')
        .eq('user_id', _userId)
        .eq('status', 'recording')
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return '${row?['id'] ?? ''}';
  }

  bool _isLocalSessionId(String value) =>
      value == 'local-session' ||
      value == 'mock-session' ||
      value.startsWith('local-drive-');

  double _nonNegativeDouble(double? value) {
    if (value == null || value.isNaN || value.isInfinite || value < 0) {
      return 0;
    }
    return value;
  }

  int _nonNegativeInt(int? value) {
    if (value == null || value < 0) {
      return 0;
    }
    return value;
  }

  @override
  Future<Vehicle> getRepresentativeVehicle() async {
    final vehicle =
        await SupabaseVehicleRepository(client: _client).getPrimaryVehicle();
    if (vehicle != null) {
      return vehicle;
    }
    if (!allowMockFallback) {
      throw StateError('대표 차량을 먼저 설정해주세요.');
    }
    return _fallback.getRepresentativeVehicle();
  }

  @override
  Future<SeasonMission> getTodayMission() async {
    if (allowMockFallback) {
      return _fallback.getTodayMission();
    }
    final missions = await SupabaseSeasonRepository(
      client: _client,
      allowMockFallback: false,
    ).getMissions();
    if (missions.isEmpty) {
      return _emptySeasonMission();
    }
    return missions.firstWhere(
      (mission) => !mission.isWeekly && !mission.rewardClaimed,
      orElse: () => missions.firstWhere(
        (mission) => !mission.rewardClaimed,
        orElse: () => missions.first,
      ),
    );
  }

  @override
  Future<DriveSession> startDriveSession() async {
    final vehicle =
        await SupabaseVehicleRepository(client: _client).getPrimaryVehicle();
    if (vehicle == null) {
      throw StateError('대표 차량을 먼저 설정해주세요.');
    }
    final row = await _client
        .from('drive_sessions')
        .insert({
          'user_id': _userId,
          'vehicle_id': vehicle.id,
          'status': 'recording',
          'source_type': 'geolocator',
          'drive_context': 'commute',
        })
        .select()
        .single();
    return DriveSession(
      id: '${row['id'] ?? ''}',
      userId: '${row['user_id'] ?? ''}',
      vehicleId: '${row['vehicle_id'] ?? vehicle.id}',
      startedAt:
          DateTime.tryParse('${row['started_at'] ?? ''}') ?? DateTime.now(),
      duration:
          Duration(seconds: (row['duration_seconds'] as num?)?.toInt() ?? 0),
      distanceKm: (row['distance_km'] as num?)?.toDouble() ?? 0,
      fuelUsedLiters: (row['fuel_used_liters'] as num?)?.toDouble() ?? 0,
      averageFuelEfficiency:
          (row['average_efficiency'] as num?)?.toDouble() ?? 0,
      sourceType: '${row['source_type'] ?? 'geolocator'}',
      driveContext: '${row['drive_context'] ?? 'commute'}',
      status: '${row['status'] ?? 'recording'}',
      createdAt: DateTime.tryParse('${row['created_at'] ?? ''}'),
    );
  }

  @override
  Future<DriveSession> uploadQueuedDriveSession(DriveSession session) async {
    final vehicleId = session.vehicleId.isNotEmpty
        ? session.vehicleId
        : (await SupabaseVehicleRepository(client: _client).getPrimaryVehicle())
                ?.id ??
            '';
    if (vehicleId.isEmpty) {
      throw StateError('대표 차량을 먼저 설정해주세요.');
    }
    final row = await _client
        .from('drive_sessions')
        .insert({
          'user_id': _userId,
          'vehicle_id': vehicleId,
          'started_at': session.startedAt.toIso8601String(),
          'duration_seconds': session.durationSeconds,
          'distance_km': session.distanceKm,
          'fuel_used_liters': session.fuelUsedLiters,
          'average_efficiency': session.averageFuelEfficiency,
          'status': session.status,
          'source_type':
              session.sourceType == 'local' ? 'geolocator' : session.sourceType,
          'drive_context': session.driveContext,
        })
        .select()
        .single();
    return DriveSession.fromJson(Map<String, dynamic>.from(row));
  }
}

abstract class RankingRepository {
  Future<List<RankingEntry>> getRankings(String scope);

  Future<RankingEntry?> getPublicEntryByUserId(String userId);
}

class MockRankingRepository implements RankingRepository {
  @override
  Future<List<RankingEntry>> getRankings(String scope) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final key = switch (scope) {
      '내 리그' => _mockPrimaryVehicle?.leagueKey ?? '',
      '가솔린' => 'gasoline',
      '디젤' => 'diesel',
      '하이브리드' => 'hybrid',
      '전기차' => 'electric',
      'LPG' => 'lpg',
      _ => '',
    };
    final items = key.isEmpty
        ? [...mockRankings]
        : mockRankings.where((entry) => entry.leagueKey == key).toList();
    return items..sort((a, b) => a.rank.compareTo(b.rank));
  }

  @override
  Future<RankingEntry?> getPublicEntryByUserId(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    for (final entry in mockRankings) {
      if (entry.userId == userId) {
        return entry;
      }
    }
    return null;
  }
}

class SupabaseRankingRepository implements RankingRepository {
  SupabaseRankingRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<RankingEntry>> getRankings(String scope) async {
    final currentUserId = _currentUserId;
    String key = switch (scope) {
      '가솔린' => 'gasoline',
      '디젤' => 'diesel',
      '하이브리드' => 'hybrid',
      '전기차' => 'electric',
      'LPG' => 'lpg',
      _ => '',
    };
    String vehicleClass = '';
    if (scope == '내 리그' && currentUserId != null) {
      final vehicle =
          await SupabaseVehicleRepository(client: _client).getPrimaryVehicle();
      key = vehicle?.leagueKey ?? '';
      vehicleClass = vehicle?.vehicleClass ?? '';
    }
    final rows = key.isEmpty
        ? await _client
            .from('public_rankings')
            .select()
            .order('rank')
            .limit(100)
        : vehicleClass.isEmpty
            ? await _client
                .from('public_rankings')
                .select()
                .eq('fuel_league', key)
                .order('rank')
                .limit(100)
            : await _client
                .from('public_rankings')
                .select()
                .eq('fuel_league', key)
                .eq('vehicle_class', vehicleClass)
                .order('rank')
                .limit(100);
    return rows
        .map(
          (row) => _rankingEntryFromRow(
            Map<String, dynamic>.from(row),
            currentUserId: currentUserId,
            fallbackLeague: key,
          ),
        )
        .toList();
  }

  @override
  Future<RankingEntry?> getPublicEntryByUserId(String userId) async {
    final row = await _client
        .from('public_rankings')
        .select()
        .eq('user_id', userId)
        .order('rank')
        .limit(1)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return _rankingEntryFromRow(
      Map<String, dynamic>.from(row),
      currentUserId: _currentUserId,
    );
  }

  RankingEntry _rankingEntryFromRow(
    Map<String, dynamic> row, {
    required String? currentUserId,
    String fallbackLeague = '',
  }) {
    return RankingEntry(
      userId: '${row['user_id'] ?? ''}',
      rank: (row['rank'] as num?)?.toInt() ?? 0,
      previousRank: (row['previous_rank'] as num?)?.toInt() ?? 0,
      nickname: '${row['nickname'] ?? 'Driver'}',
      tier: '${row['tier'] ?? 'Bronze I'}',
      score: (row['score'] as num?)?.toInt() ?? 0,
      vehicleClass: '${row['vehicle_class'] ?? ''}',
      fuelType: '${row['fuel_type'] ?? ''}',
      fuelLeague: '${row['fuel_league'] ?? fallbackLeague}',
      isCurrentUser:
          currentUserId != null && '${row['user_id'] ?? ''}' == currentUserId,
    );
  }
}

abstract class BattleRepository {
  Future<List<Battle>> getBattles();

  Future<Battle?> getBattleById(String battleId);

  Future<Battle> settleBattle({
    required String battleId,
    required int myScore,
    required int opponentScore,
  });

  Future<Battle> createBattle({
    required String title,
    required String battleType,
    required String ruleType,
    required Duration duration,
    required String rewardSummary,
    String requiredFuelLeague = '',
    String requiredVehicleClass = '',
    bool isFriendlyCrossLeague = false,
    String opponentNickname = '공개 참가자',
  });
}

Battle _copyBattle(
  Battle battle, {
  String? status,
  int? myScore,
  int? opponentScore,
}) {
  return Battle(
    id: battle.id,
    createdBy: battle.createdBy,
    title: battle.title,
    battleType: battle.battleType,
    status: status ?? battle.status,
    ruleType: battle.ruleType,
    startAt: battle.startAt,
    endAt: battle.endAt,
    wagerTemplate: battle.wagerTemplate,
    participants: battle.participants,
    myScore: myScore ?? battle.myScore,
    opponentScore: opponentScore ?? battle.opponentScore,
    opponentNickname: battle.opponentNickname,
    rewardSummary: battle.rewardSummary,
    requiredFuelLeague: battle.requiredFuelLeague,
    requiredVehicleClass: battle.requiredVehicleClass,
    isFriendlyCrossLeague: battle.isFriendlyCrossLeague,
    createdAt: battle.createdAt,
  );
}

class MockBattleRepository implements BattleRepository {
  @override
  Future<List<Battle>> getBattles() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _mockBattles;
  }

  @override
  Future<Battle?> getBattleById(String battleId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    for (final battle in _mockBattles) {
      if (battle.id == battleId) {
        return battle;
      }
    }
    return null;
  }

  @override
  Future<Battle> settleBattle({
    required String battleId,
    required int myScore,
    required int opponentScore,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final index = _mockBattles.indexWhere((battle) => battle.id == battleId);
    if (index < 0) {
      throw StateError('배틀을 찾을 수 없습니다.');
    }
    final settled = _copyBattle(
      _mockBattles[index],
      status: 'completed',
      myScore: myScore,
      opponentScore: opponentScore,
    );
    _mockBattles = [
      ..._mockBattles.take(index),
      settled,
      ..._mockBattles.skip(index + 1),
    ];
    return settled;
  }

  @override
  Future<Battle> createBattle({
    required String title,
    required String battleType,
    required String ruleType,
    required Duration duration,
    required String rewardSummary,
    String requiredFuelLeague = '',
    String requiredVehicleClass = '',
    bool isFriendlyCrossLeague = false,
    String opponentNickname = '공개 참가자',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final now = DateTime.now();
    final battle = Battle(
      id: _uuid.v4(),
      createdBy: mockProfile.id,
      title: title,
      battleType: battleType,
      status: '모집 중',
      ruleType: ruleType,
      startAt: now,
      endAt: now.add(duration),
      wagerTemplate: 'non_cash_reward',
      myScore: 0,
      opponentScore: 0,
      opponentNickname: opponentNickname,
      rewardSummary: rewardSummary,
      requiredFuelLeague:
          requiredFuelLeague.isEmpty ? null : requiredFuelLeague,
      requiredVehicleClass:
          requiredVehicleClass.isEmpty ? null : requiredVehicleClass,
      isFriendlyCrossLeague: isFriendlyCrossLeague,
      createdAt: now,
    );
    _mockBattles = [battle, ..._mockBattles];
    return battle;
  }
}

class SupabaseBattleRepository implements BattleRepository {
  SupabaseBattleRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('로그인된 사용자를 찾을 수 없습니다.');
    }
    return user.id;
  }

  @override
  Future<List<Battle>> getBattles() async {
    final rows = await _client
        .from('battles')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return rows
        .map(
          (row) => _battleFromRow(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  @override
  Future<Battle?> getBattleById(String battleId) async {
    final row =
        await _client.from('battles').select().eq('id', battleId).maybeSingle();
    if (row == null) {
      return null;
    }
    return _battleFromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<Battle> settleBattle({
    required String battleId,
    required int myScore,
    required int opponentScore,
  }) async {
    final current = await getBattleById(battleId);
    final response = await _client.functions.invoke(
      'settle_battle',
      body: {
        'battleId': battleId,
        'myScore': myScore,
        'opponentScore': opponentScore,
        'idempotencyKey': 'battle-settle-$battleId-${_uuid.v4()}',
      },
    );
    final data = _functionResponseMap(response.data);
    if (data['error'] != null) {
      throw StateError('${data['error']}');
    }
    final refreshed = await getBattleById(battleId);
    if (refreshed != null) {
      return refreshed;
    }
    if (current != null) {
      return _copyBattle(
        current,
        status: 'completed',
        myScore: myScore,
        opponentScore: opponentScore,
      );
    }
    throw StateError('배틀을 찾을 수 없습니다.');
  }

  @override
  Future<Battle> createBattle({
    required String title,
    required String battleType,
    required String ruleType,
    required Duration duration,
    required String rewardSummary,
    String requiredFuelLeague = '',
    String requiredVehicleClass = '',
    bool isFriendlyCrossLeague = false,
    String opponentNickname = '공개 참가자',
  }) async {
    final now = DateTime.now().toUtc();
    final row = await _client
        .from('battles')
        .insert({
          'created_by': _userId,
          'battle_type': battleType,
          'title': title,
          'rule_type': ruleType,
          'start_at': now.toIso8601String(),
          'end_at': now.add(duration).toIso8601String(),
          'status': '모집 중',
          'wager_template': 'non_cash_reward',
          'reward_summary': rewardSummary,
          'required_fuel_league':
              requiredFuelLeague.isEmpty ? null : requiredFuelLeague,
          'required_vehicle_class':
              requiredVehicleClass.isEmpty ? null : requiredVehicleClass,
          'is_friendly_cross_league': isFriendlyCrossLeague,
        })
        .select()
        .single();
    await _client.from('battle_participants').upsert(
      {
        'battle_id': row['id'],
        'user_id': _userId,
        'score': 0,
        'result': 'pending',
      },
      onConflict: 'battle_id,user_id',
    );
    return _battleFromRow(
      Map<String, dynamic>.from(row),
      opponentNickname: opponentNickname,
    );
  }

  Battle _battleFromRow(
    Map<String, dynamic> row, {
    String opponentNickname = '공개 참가자',
  }) {
    return Battle(
      id: '${row['id'] ?? ''}',
      createdBy: '${row['created_by'] ?? ''}',
      title: '${row['title'] ?? '배틀'}',
      battleType: '${row['battle_type'] ?? '공개 매칭'}',
      status: '${row['status'] ?? '모집 중'}',
      ruleType: '${row['rule_type'] ?? '최고 효율 점수'}',
      startAt: DateTime.tryParse('${row['start_at'] ?? ''}') ?? DateTime.now(),
      endAt: DateTime.tryParse('${row['end_at'] ?? ''}') ?? DateTime.now(),
      wagerTemplate: '${row['wager_template'] ?? 'non_cash_reward'}',
      myScore: 0,
      opponentScore: 0,
      opponentNickname: opponentNickname,
      rewardSummary: '${row['reward_summary'] ?? '시즌 XP'}',
      requiredFuelLeague: row['required_fuel_league'] as String?,
      requiredVehicleClass: row['required_vehicle_class'] as String?,
      isFriendlyCrossLeague: row['is_friendly_cross_league'] == true,
      createdAt: DateTime.tryParse('${row['created_at'] ?? ''}'),
    );
  }
}

abstract class SeasonRepository {
  Future<Season> getCurrentSeason();

  Future<List<SeasonMission>> getMissions();

  Future<MissionProgress> updateMissionProgress({
    required String missionId,
    required int progress,
  });

  Future<MissionProgress> claimMissionReward(String missionId);
}

class MockSeasonRepository implements SeasonRepository {
  @override
  Future<Season> getCurrentSeason() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return mockSeason;
  }

  @override
  Future<List<SeasonMission>> getMissions() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return mockMissions;
  }

  @override
  Future<MissionProgress> updateMissionProgress({
    required String missionId,
    required int progress,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final mission = mockMissions.firstWhere(
      (item) => item.id == missionId,
      orElse: () => mockMissions.first,
    );
    return MissionProgress(
      id: 'mock-progress-$missionId',
      userId: mockProfile.id,
      missionId: missionId,
      progress: progress.clamp(0, mission.target),
      target: mission.target,
      rewardClaimed: false,
    );
  }

  @override
  Future<MissionProgress> claimMissionReward(String missionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final mission = mockMissions.firstWhere(
      (item) => item.id == missionId,
      orElse: () => mockMissions.first,
    );
    return MissionProgress(
      id: 'mock-progress-$missionId',
      userId: mockProfile.id,
      missionId: missionId,
      progress: mission.target,
      target: mission.target,
      rewardClaimed: true,
    );
  }
}

class SupabaseSeasonRepository implements SeasonRepository {
  SupabaseSeasonRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockSeasonRepository _fallback = MockSeasonRepository();

  @override
  Future<Season> getCurrentSeason() async {
    try {
      final seasonRow = await _loadCurrentSeasonRow();
      if (seasonRow == null) {
        return allowMockFallback
            ? _fallback.getCurrentSeason()
            : _emptySeason();
      }
      final user = _client.auth.currentUser;
      Map<String, dynamic>? profileRow;
      if (user != null) {
        final row = await _client
            .from('profiles')
            .select(
                'season_score,tier,selected_fuel_league,selected_vehicle_class')
            .eq('id', user.id)
            .maybeSingle();
        profileRow = row == null ? null : Map<String, dynamic>.from(row);
      }

      final promotionTargetScore =
          await _integerSetting('season_promotion_target_score', 3000);
      final seasonScore = _intFrom(profileRow?['season_score'], 0);
      final fuelLeague = '${profileRow?['selected_fuel_league'] ?? ''}'.trim();
      final vehicleClass =
          '${profileRow?['selected_vehicle_class'] ?? ''}'.trim();
      final currentLeague = fuelLeague.isEmpty
          ? '${profileRow?['tier'] ?? 'Bronze League'}'
          : FuelLeague.leagueLabel(fuelLeague, vehicleClass);

      return Season(
        id: '${seasonRow['id'] ?? ''}',
        name: '${seasonRow['name'] ?? 'Fuel Arena Season'}',
        description: '${seasonRow['description'] ?? ''}',
        startAt: DateTime.tryParse('${seasonRow['start_at'] ?? ''}'),
        currentLeague: currentLeague,
        seasonScore: seasonScore,
        promotionTargetScore: promotionTargetScore,
        endsAt: DateTime.tryParse('${seasonRow['end_at'] ?? ''}') ??
            DateTime.now().add(const Duration(days: 14)),
        status: '${seasonRow['status'] ?? 'active'}',
        theme: '${seasonRow['theme'] ?? 'neon_efficiency'}',
        rewardProgress: promotionTargetScore == 0
            ? 0
            : (seasonScore / promotionTargetScore).clamp(0.0, 1.0),
      );
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getCurrentSeason();
    }
  }

  @override
  Future<List<SeasonMission>> getMissions() async {
    try {
      final seasonRow = await _loadCurrentSeasonRow();
      if (seasonRow == null) {
        return allowMockFallback
            ? _fallback.getMissions()
            : const <SeasonMission>[];
      }
      final missionRows = await _client
          .from('season_missions')
          .select('id,title,description,target,reward_xp,is_weekly,created_at')
          .eq('season_id', '${seasonRow['id'] ?? ''}')
          .order('is_weekly')
          .order('created_at');
      final user = _client.auth.currentUser;
      final progressByMissionId = <String, Map<String, dynamic>>{};
      if (user != null) {
        final progressRows = await _client
            .from('mission_progress')
            .select('id,mission_id,progress,reward_claimed')
            .eq('user_id', user.id);
        for (final row in progressRows) {
          final data = Map<String, dynamic>.from(row);
          progressByMissionId['${data['mission_id'] ?? ''}'] = data;
        }
      }
      final missions = missionRows.map<SeasonMission>((row) {
        final data = Map<String, dynamic>.from(row);
        final progress = progressByMissionId['${data['id'] ?? ''}'];
        return SeasonMission(
          id: '${data['id'] ?? ''}',
          title: '${data['title'] ?? '시즌 미션'}',
          description: '${data['description'] ?? ''}',
          progress: _intFrom(progress?['progress'], 0),
          target: _intFrom(data['target'], 1),
          rewardXp: _intFrom(data['reward_xp'], 0),
          isWeekly: data['is_weekly'] == true,
          rewardClaimed: progress?['reward_claimed'] == true,
        );
      }).toList();
      if (missions.isEmpty) {
        return allowMockFallback
            ? _fallback.getMissions()
            : const <SeasonMission>[];
      }
      return missions;
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getMissions();
    }
  }

  @override
  Future<MissionProgress> updateMissionProgress({
    required String missionId,
    required int progress,
  }) async {
    final response = await _client.functions.invoke(
      'update_mission_progress',
      body: {
        'missionId': missionId,
        'progress': progress,
        'idempotencyKey': 'mission-progress-$missionId-${_uuid.v4()}',
      },
    );
    final data = _functionResponseMap(response.data);
    if (data['error'] != null) {
      throw StateError('${data['error']}');
    }
    return _missionProgressFromFunction(data, fallbackMissionId: missionId);
  }

  @override
  Future<MissionProgress> claimMissionReward(String missionId) async {
    final response = await _client.functions.invoke(
      'claim_season_reward',
      body: {
        'missionId': missionId,
        'idempotencyKey': 'mission-claim-$missionId-${_uuid.v4()}',
      },
    );
    final data = _functionResponseMap(response.data);
    if (data['error'] != null) {
      throw StateError('${data['error']}');
    }
    return _missionProgressFromFunction(data, fallbackMissionId: missionId);
  }

  Future<Map<String, dynamic>?> _loadCurrentSeasonRow() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final activeRow = await _client
        .from('seasons')
        .select('id,name,description,start_at,end_at,status,theme')
        .eq('status', 'active')
        .lte('start_at', now)
        .gte('end_at', now)
        .order('start_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (activeRow != null) {
      return Map<String, dynamic>.from(activeRow);
    }
    final latestRow = await _client
        .from('seasons')
        .select('id,name,description,start_at,end_at,status,theme')
        .eq('status', 'active')
        .order('start_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return latestRow == null ? null : Map<String, dynamic>.from(latestRow);
  }

  Future<int> _integerSetting(String key, int fallback) async {
    try {
      final row = await _client
          .from('app_settings')
          .select('value')
          .eq('key', key)
          .maybeSingle();
      final raw = row?['value'];
      final value = raw is Map ? raw['value'] : raw;
      return _intFrom(value, fallback);
    } catch (_) {
      return fallback;
    }
  }

  MissionProgress _missionProgressFromFunction(
    Map<String, dynamic> data, {
    required String fallbackMissionId,
  }) {
    final missionId = '${data['missionId'] ?? fallbackMissionId}';
    final target = _intFrom(data['target'], 0);
    final progress = _intFrom(data['progress'], target);
    return MissionProgress(
      id: '${data['progressId'] ?? data['id'] ?? 'mission-progress-$missionId'}',
      userId: '${data['userId'] ?? _client.auth.currentUser?.id ?? ''}',
      missionId: missionId,
      progress: progress,
      target: target,
      rewardClaimed: data['rewardClaimed'] == true ||
          data['claimed'] == true ||
          data['alreadyClaimed'] == true,
    );
  }
}

abstract class ProfileRepository {
  Future<UserProfile> getProfile();

  Future<List<Badge>> getBadges();

  Future<List<Achievement>> getAchievements();
}

class MockProfileRepository implements ProfileRepository {
  @override
  Future<List<Achievement>> getAchievements() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return mockAchievements;
  }

  @override
  Future<List<Badge>> getBadges() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return mockBadges;
  }

  @override
  Future<UserProfile> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _mockSignedInProfile;
  }
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockProfileRepository _fallback = MockProfileRepository();

  @override
  Future<List<Achievement>> getAchievements() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return allowMockFallback ? _fallback.getAchievements() : const [];
    }
    try {
      final achievementRows = await _client
          .from('achievements')
          .select('id,title,description,target')
          .order('title');
      final progressRows = await _client
          .from('user_achievements')
          .select('achievement_id,progress,completed')
          .eq('user_id', user.id);
      final progressByAchievementId = <String, Map<String, dynamic>>{};
      for (final row in progressRows) {
        final data = Map<String, dynamic>.from(row);
        progressByAchievementId['${data['achievement_id'] ?? ''}'] = data;
      }
      return achievementRows.map<Achievement>((row) {
        final data = Map<String, dynamic>.from(row);
        final progress = progressByAchievementId['${data['id'] ?? ''}'];
        final target = _intFrom(data['target'], 1);
        return Achievement(
          id: '${data['id'] ?? ''}',
          title: '${data['title'] ?? '업적'}',
          description: '${data['description'] ?? ''}',
          progress: progress?['completed'] == true
              ? target
              : _intFrom(progress?['progress'], 0).clamp(0, target),
          target: target,
        );
      }).toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getAchievements();
    }
  }

  @override
  Future<List<Badge>> getBadges() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return allowMockFallback ? _fallback.getBadges() : const [];
    }
    try {
      final rows = await _client
          .from('user_badges')
          .select(
              'badge_id,earned_at,equipped,badges(id,name,description,rarity)')
          .eq('user_id', user.id)
          .order('equipped', ascending: false)
          .order('earned_at', ascending: false)
          .limit(12);
      return rows
          .map<Badge?>((row) {
            final data = Map<String, dynamic>.from(row);
            final badge = _nestedBadge(data['badges']);
            if (badge.isEmpty) return null;
            return Badge(
              id: '${badge['id'] ?? data['badge_id'] ?? ''}',
              name: '${badge['name'] ?? '배지'}',
              description: '${badge['description'] ?? ''}',
              rarity: '${badge['rarity'] ?? 'Common'}',
            );
          })
          .whereType<Badge>()
          .toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getBadges();
    }
  }

  @override
  Future<UserProfile> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.getProfile();
    }
    final row =
        await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    if (row == null) {
      if (!allowMockFallback) {
        throw StateError('프로필을 찾을 수 없습니다.');
      }
      return _fallback.getProfile();
    }
    return UserProfile.fromJson(row);
  }

  Map<String, dynamic> _nestedBadge(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return const <String, dynamic>{};
  }
}

abstract class AdsRepository {
  Future<bool> isRewardAdAvailable();

  Future<AdReward> watchRewardAd({bool verifiedByAdSdk = false});

  Future<int> getDailyRewardAdLimit();

  Future<List<Advertisement>> getNativeAdCards();
}

class MockAdsRepository implements AdsRepository {
  @override
  Future<int> getDailyRewardAdLimit() async => 3;

  @override
  Future<List<Advertisement>> getNativeAdCards() async => mockAds;

  @override
  Future<bool> isRewardAdAvailable() async => true;

  @override
  Future<AdReward> watchRewardAd({bool verifiedByAdSdk = false}) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return const AdReward(
      id: 'reward-xp-double',
      title: '시즌 XP 2배',
      description: '이번 주행 보상이 두 배로 적용됐어요.',
      claimed: true,
    );
  }
}

class SupabaseAdsRepository implements AdsRepository {
  SupabaseAdsRepository({
    SupabaseClient? client,
    this.allowClientRewardGrant = true,
    this.rewardAdsConfigured = false,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowClientRewardGrant;
  final bool rewardAdsConfigured;
  final MockAdsRepository _fallback = MockAdsRepository();

  @override
  Future<int> getDailyRewardAdLimit() async {
    try {
      final row = await _client
          .from('app_settings')
          .select('value')
          .eq('key', 'reward_ad_daily_limit')
          .eq('is_public', true)
          .maybeSingle();
      return _boundedRewardAdLimit(_settingValue(row?['value']));
    } catch (_) {
      if (!allowClientRewardGrant) {
        return 0;
      }
      return _fallback.getDailyRewardAdLimit();
    }
  }

  @override
  Future<List<Advertisement>> getNativeAdCards() async {
    try {
      final rows = await _client
          .from('advertisements')
          .select(
            'id,ad_type,placement,title,description,sponsor_id,image_url,cta_label,is_active,starts_at,ends_at',
          )
          .eq('ad_type', 'native')
          .eq('is_active', true)
          .limit(5);
      final ads = rows
          .map<Advertisement>(
            (row) => _advertisementFromRow(Map<String, dynamic>.from(row)),
          )
          .toList();
      if (ads.isEmpty && allowClientRewardGrant) {
        return _fallback.getNativeAdCards();
      }
      return ads;
    } catch (_) {
      if (!allowClientRewardGrant) {
        return const <Advertisement>[];
      }
      return _fallback.getNativeAdCards();
    }
  }

  @override
  Future<bool> isRewardAdAvailable() {
    if (!allowClientRewardGrant) {
      return Future<bool>.value(rewardAdsConfigured);
    }
    return _fallback.isRewardAdAvailable();
  }

  @override
  Future<AdReward> watchRewardAd({bool verifiedByAdSdk = false}) async {
    if (!allowClientRewardGrant && !verifiedByAdSdk) {
      throw StateError('광고 시청 검증이 필요합니다.');
    }
    if (!allowClientRewardGrant && !rewardAdsConfigured) {
      throw StateError('리워드 광고 설정이 필요합니다.');
    }
    final response = await _client.functions.invoke(
      'grant_ad_reward',
      body: {
        'rewardType': 'season_xp_double',
        'idempotencyKey': 'ad-reward-${_uuid.v4()}',
      },
    );
    final data = _functionResponseMap(response.data);
    if (data['error'] != null) {
      throw StateError('${data['error']}');
    }
    return AdReward(
      id: '${data['rewardId'] ?? _uuid.v4()}',
      title: '시즌 XP 2배',
      description: '${data['message'] ?? '리워드 광고 보상이 지급되었습니다.'}',
      claimed: data['granted'] == true,
    );
  }

  Object? _settingValue(Object? raw) {
    if (raw is Map) {
      return raw['value'] ?? raw['text'];
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return decoded['value'] ?? decoded['text'];
        }
      } catch (_) {
        return raw;
      }
    }
    return raw;
  }

  int _boundedRewardAdLimit(Object? value) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    if (parsed == null || parsed < 0 || parsed > 20) {
      return 0;
    }
    return parsed;
  }

  Advertisement _advertisementFromRow(Map<String, dynamic> row) {
    final title = '${row['title'] ?? ''}'.trim();
    final ctaLabel = '${row['cta_label'] ?? ''}'.trim();
    return Advertisement(
      id: '${row['id'] ?? _uuid.v4()}',
      adType: '${row['ad_type'] ?? 'native'}',
      placement: '${row['placement'] ?? 'home'}',
      title: title,
      description: '${row['description'] ?? ''}',
      sponsorId: '${row['sponsor_id'] ?? ''}',
      imageUrl: '${row['image_url'] ?? ''}',
      ctaLabel: ctaLabel,
      isActive: _boolFrom(row['is_active'], true),
      startsAt: DateTime.tryParse('${row['starts_at'] ?? ''}'),
      endsAt: DateTime.tryParse('${row['ends_at'] ?? ''}'),
      rewardType: '${row['ad_type'] ?? 'native'}',
      label: ctaLabel.isNotEmpty ? ctaLabel : title,
    );
  }
}

abstract class PremiumRepository {
  Future<List<SubscriptionPlan>> getPlans();
}

class MockPremiumRepository implements PremiumRepository {
  @override
  Future<List<SubscriptionPlan>> getPlans() async => mockPlans;
}

class SupabasePremiumRepository implements PremiumRepository {
  SupabasePremiumRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockPremiumRepository _fallback = MockPremiumRepository();

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final rows =
          await _client.from('subscription_plans').select().order('plan_type');
      final plans = rows
          .map<SubscriptionPlan>((row) =>
              SubscriptionPlan.fromJson(Map<String, dynamic>.from(row)))
          .toList()
        ..sort(_compareSubscriptionPlans);
      if (plans.isEmpty) {
        return allowMockFallback
            ? _fallback.getPlans()
            : const <SubscriptionPlan>[];
      }
      return plans;
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getPlans();
    }
  }
}

int _compareSubscriptionPlans(SubscriptionPlan a, SubscriptionPlan b) {
  final rankComparison = _subscriptionPlanSortRank(
    a.planType,
  ).compareTo(_subscriptionPlanSortRank(b.planType));
  if (rankComparison != 0) {
    return rankComparison;
  }
  return a.id.compareTo(b.id);
}

int _subscriptionPlanSortRank(String planType) {
  return switch (planType) {
    'monthly' => 0,
    'yearly' => 1,
    'season_pass' => 2,
    'bundle' => 3,
    _ => 99,
  };
}

abstract class SubscriptionRepository {
  Future<List<SubscriptionPlan>> getPlans();

  Future<bool> startSubscription(String planId);

  Future<PurchaseVerificationResult> verifyPurchase(
    PurchaseVerificationRequest request,
  );
}

class MockSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<SubscriptionPlan>> getPlans() async => mockPlans;

  @override
  Future<bool> startSubscription(String planId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<PurchaseVerificationResult> verifyPurchase(
    PurchaseVerificationRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return PurchaseVerificationResult(
      verified: true,
      premiumActive: true,
      provider: request.provider,
      productId: request.productId,
      planId: request.planId,
      expiresAt: DateTime.now().add(const Duration(days: 31)),
    );
  }
}

class SupabaseSubscriptionRepository implements SubscriptionRepository {
  SupabaseSubscriptionRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockSubscriptionRepository _fallback = MockSubscriptionRepository();

  @override
  Future<List<SubscriptionPlan>> getPlans() {
    return SupabasePremiumRepository(
      client: _client,
      allowMockFallback: allowMockFallback,
    ).getPlans();
  }

  @override
  Future<bool> startSubscription(String planId) {
    if (!allowMockFallback) {
      throw StateError('스토어 결제 검증이 필요합니다.');
    }
    return _fallback.startSubscription(planId);
  }

  @override
  Future<PurchaseVerificationResult> verifyPurchase(
    PurchaseVerificationRequest request,
  ) async {
    try {
      final response = await _client.functions.invoke(
        'verify_purchase',
        body: request.toJson(),
      );
      final data = _functionResponseMap(response.data);
      if (data['error'] != null) {
        throw StateError('${data['error']}');
      }
      return PurchaseVerificationResult.fromJson(data);
    } catch (_) {
      rethrow;
    }
  }
}

abstract class SponsorRepository {
  Future<List<SponsorChallenge>> getChallenges();
}

class MockSponsorRepository implements SponsorRepository {
  @override
  Future<List<SponsorChallenge>> getChallenges() async => mockSponsorChallenges;
}

class SupabaseSponsorRepository implements SponsorRepository {
  SupabaseSponsorRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockSponsorRepository _fallback = MockSponsorRepository();

  @override
  Future<List<SponsorChallenge>> getChallenges() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final rows = await _client
          .from('sponsor_challenges')
          .select('id,title,description,reward_summary,ends_at,sponsors(name)')
          .eq('is_active', true)
          .lte('starts_at', now)
          .gt('ends_at', now)
          .order('ends_at')
          .limit(20);
      final challenges = rows.map<SponsorChallenge>((row) {
        final data = Map<String, dynamic>.from(row);
        final sponsor = _nestedSponsor(data['sponsors']);
        return SponsorChallenge(
          id: '${data['id'] ?? ''}',
          sponsorName: '${sponsor['name'] ?? 'Fuel Arena'}',
          title: '${data['title'] ?? '스폰서 챌린지'}',
          description: '${data['description'] ?? ''}',
          rewardSummary: '${data['reward_summary'] ?? '시즌 XP'}',
          endsAt: DateTime.tryParse('${data['ends_at'] ?? ''}') ??
              DateTime.now().add(const Duration(days: 7)),
        );
      }).toList();
      if (challenges.isEmpty) {
        return allowMockFallback
            ? _fallback.getChallenges()
            : const <SponsorChallenge>[];
      }
      return challenges;
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getChallenges();
    }
  }

  Map<String, dynamic> _nestedSponsor(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return const <String, dynamic>{};
  }
}

abstract class FairnessRepository {
  Future<List<String>> getGuidelines();
}

class MockFairnessRepository implements FairnessRepository {
  @override
  Future<List<String>> getGuidelines() async => const [
        '전기차는 전기차끼리, 하이브리드는 하이브리드끼리 비교합니다.',
        '공정한 비교를 위해 연료 타입과 차급을 함께 사용합니다.',
        '다른 리그와의 배틀은 친선전으로 기록됩니다.',
        '정확한 위치 경로는 공개 랭킹에 노출하지 않습니다.',
        '비정상 급가속, 급제동, GPS 이상 기록은 검증 대기 상태가 됩니다.',
        '최종 점수는 서버 검증 후 랭킹에 반영됩니다.',
      ];
}

class SupabaseFairnessRepository implements FairnessRepository {
  SupabaseFairnessRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockFairnessRepository _fallback = MockFairnessRepository();

  @override
  Future<List<String>> getGuidelines() async {
    try {
      final row = await _client
          .from('app_settings')
          .select('value')
          .eq('key', 'fairness_guidelines')
          .eq('is_public', true)
          .maybeSingle();
      final value = row?['value'];
      final items = value is Map ? value['items'] : null;
      final guidelines = items is List
          ? items
              .map((item) => '$item'.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
          : const <String>[];
      if (guidelines.isEmpty) {
        return allowMockFallback ? _fallback.getGuidelines() : const <String>[];
      }
      return guidelines;
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getGuidelines();
    }
  }
}

abstract class StatsRepository {
  Future<List<AdminMetric>> getUserStats();
}

class MockStatsRepository implements StatsRepository {
  @override
  Future<List<AdminMetric>> getUserStats() async => const [
        AdminMetric(
            id: 'avg-efficiency', label: '평균 연비', value: '18.4', unit: 'km/L'),
        AdminMetric(
            id: 'verified-drives', label: '검증 주행', value: '20', unit: '회'),
        AdminMetric(id: 'class-top', label: '동급 백분위', value: '18', unit: '%'),
        AdminMetric(id: 'streak', label: '연속 주행', value: '5', unit: '일'),
      ];
}

class SupabaseStatsRepository implements StatsRepository {
  SupabaseStatsRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockStatsRepository _fallback = MockStatsRepository();

  @override
  Future<List<AdminMetric>> getUserStats() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.getUserStats();
    }
    try {
      final profileRow = await _client
          .from('profiles')
          .select('current_streak,selected_fuel_league')
          .eq('id', user.id)
          .maybeSingle();
      final sessionRows = await _client
          .from('drive_sessions')
          .select(
              'average_efficiency,distance_km,duration_seconds,status,ended_at')
          .eq('user_id', user.id)
          .order('started_at', ascending: false)
          .limit(100);
      final scoreRows = await _client
          .from('drive_scores')
          .select('verification_status,class_percentile,total_score')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(100);
      final rankingRow = await _client
          .from('public_rankings')
          .select('rank,percentile')
          .eq('user_id', user.id)
          .eq('period', 'season')
          .order('rank')
          .limit(1)
          .maybeSingle();

      final completedSessions = sessionRows
          .map((row) => Map<String, dynamic>.from(row))
          .where((row) =>
              '${row['status'] ?? ''}' != 'recording' &&
              DateTime.tryParse('${row['ended_at'] ?? ''}') != null)
          .toList();
      final scores =
          scoreRows.map((row) => Map<String, dynamic>.from(row)).toList();
      final avgEfficiency = _average(
        completedSessions
            .map((row) => _doubleFrom(row['average_efficiency'], 0))
            .where((value) => value > 0),
      );
      final totalDistance = completedSessions.fold<double>(
        0,
        (sum, row) => sum + _doubleFrom(row['distance_km'], 0),
      );
      final verifiedDrives = scores
          .where((row) => '${row['verification_status'] ?? ''}' == 'verified')
          .length;
      final latestPercentile = rankingRow == null
          ? _intFrom(
              scores.isEmpty ? null : scores.first['class_percentile'], 0)
          : _intFrom(rankingRow['percentile'], 0);
      final currentStreak = profileRow == null
          ? 0
          : _intFrom(
              Map<String, dynamic>.from(profileRow)['current_streak'],
              0,
            );
      final profile = profileRow == null
          ? const <String, dynamic>{}
          : Map<String, dynamic>.from(profileRow);
      final fuelLeague = '${profile['selected_fuel_league'] ?? ''}';

      return [
        AdminMetric(
          id: 'avg-efficiency',
          label: '평균 연비',
          value: _metricNumber(avgEfficiency, fractionDigits: 1),
          unit: fuelLeague == 'electric' ? 'km/kWh' : 'km/L',
        ),
        AdminMetric(
          id: 'verified-drives',
          label: '검증 주행',
          value: '$verifiedDrives',
          unit: '회',
        ),
        AdminMetric(
          id: 'class-top',
          label: '동급 백분위',
          value: '$latestPercentile',
          unit: '%',
        ),
        AdminMetric(
          id: 'total-distance',
          label: '누적 거리',
          value: _metricNumber(totalDistance, fractionDigits: 1),
          unit: 'km',
        ),
        AdminMetric(
          id: 'streak',
          label: '연속 주행',
          value: '$currentStreak',
          unit: '일',
        ),
      ];
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getUserStats();
    }
  }

  double _average(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (sum, value) => sum + value) / list.length;
  }

  double _doubleFrom(Object? value, double fallback) {
    return value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? fallback;
  }

  String _metricNumber(double value, {int fractionDigits = 0}) {
    if (value == 0) return '0';
    final text = value.toStringAsFixed(fractionDigits);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }
}

abstract class CouponRepository {
  Future<List<Coupon>> listCoupons();

  Future<UserCoupon> issueCoupon(String couponId);
}

class MockCouponRepository implements CouponRepository {
  @override
  Future<UserCoupon> issueCoupon(String couponId) async => UserCoupon(
        id: _uuid.v4(),
        userId: mockProfile.id,
        couponId: couponId,
        status: 'issued',
        issuedAt: DateTime.now(),
      );

  @override
  Future<List<Coupon>> listCoupons() async => mockCoupons;
}

class SupabaseCouponRepository implements CouponRepository {
  SupabaseCouponRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockCouponRepository _fallback = MockCouponRepository();

  @override
  Future<UserCoupon> issueCoupon(String couponId) async {
    try {
      final response = await _client.functions.invoke(
        'issue_coupon',
        body: {
          'couponId': couponId,
          'idempotencyKey': 'coupon-$couponId-${_uuid.v4()}',
        },
      );
      final data = _functionResponseMap(response.data);
      if (data['error'] != null) {
        throw StateError('${data['error']}');
      }
      return UserCoupon(
        id: '${data['userCouponId'] ?? data['id'] ?? _uuid.v4()}',
        userId: '${data['userId'] ?? ''}',
        couponId: '${data['couponId'] ?? couponId}',
        status: '${data['status'] ?? 'issued'}',
        issuedAt:
            DateTime.tryParse('${data['issuedAt'] ?? ''}') ?? DateTime.now(),
        usedAt: DateTime.tryParse('${data['usedAt'] ?? ''}'),
      );
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.issueCoupon(couponId);
    }
  }

  @override
  Future<List<Coupon>> listCoupons() async {
    try {
      final rows = await _client
          .from('coupons')
          .select('id,title,description,expires_at')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at')
          .limit(50);
      final coupons = rows
          .map<Coupon>(
            (row) => Coupon(
              id: '${row['id'] ?? ''}',
              title: '${row['title'] ?? ''}',
              description: '${row['description'] ?? ''}',
              expiresAt: DateTime.tryParse('${row['expires_at'] ?? ''}') ??
                  DateTime.now(),
            ),
          )
          .toList();
      if (coupons.isEmpty) {
        return allowMockFallback ? _fallback.listCoupons() : const <Coupon>[];
      }
      return coupons;
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.listCoupons();
    }
  }
}

abstract class NotificationRepository {
  Future<List<NotificationItem>> listNotifications();

  Future<void> markRead(String notificationId);

  Future<void> markAllRead();
}

class MockNotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationItem>> listNotifications() async =>
      _mockNotifications;

  @override
  Future<void> markRead(String notificationId) async {
    _mockNotifications = _mockNotifications
        .map((item) =>
            item.id == notificationId ? item.copyWith(isRead: true) : item)
        .toList();
  }

  @override
  Future<void> markAllRead() async {
    _mockNotifications =
        _mockNotifications.map((item) => item.copyWith(isRead: true)).toList();
  }
}

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockNotificationRepository _fallback = MockNotificationRepository();

  @override
  Future<List<NotificationItem>> listNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.listNotifications();
    }
    try {
      final rows = await _client
          .from('notifications')
          .select(
              'id,title,body,is_read,created_at,notification_type,target_route,held_during_drive')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);
      return rows.map<NotificationItem>((row) {
        final data = Map<String, dynamic>.from(row);
        final targetRoute = data['target_route'];
        return NotificationItem(
          id: '${data['id'] ?? ''}',
          title: '${data['title'] ?? 'Fuel Arena'}',
          body: '${data['body'] ?? ''}',
          createdAt: DateTime.tryParse('${data['created_at'] ?? ''}') ??
              DateTime.now(),
          isRead: data['is_read'] == true,
          notificationType: '${data['notification_type'] ?? 'general'}',
          targetRoute: targetRoute == null ? '' : '$targetRoute',
          heldDuringDrive: data['held_during_drive'] == true,
        );
      }).toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.listNotifications();
    }
  }

  @override
  Future<void> markRead(String notificationId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.markRead(notificationId);
    }
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', user.id);
  }

  @override
  Future<void> markAllRead() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.markAllRead();
    }
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);
  }
}

abstract class SupportRepository {
  Future<SupportTicket> createSupportTicket({
    required String category,
    required String title,
    required String description,
  });

  Future<List<SupportTicket>> listMyTickets();

  Future<SupportTicket?> getTicketDetail(String ticketId);

  Future<List<SupportTicketMessage>> listMessages(String ticketId);

  Future<SupportTicketMessage> addMessage(
    String ticketId,
    String message, {
    bool isAdminReply = false,
  });

  Future<SupportTicket?> updateTicketStatus(String ticketId, String status);
}

abstract class ReportRepository {
  Future<ReportItem> createReport(ReportRequest request);

  Future<ReportItem?> updateReportStatus(String reportId, String status);
}

abstract class PrivacyRequestRepository {
  Future<PrivacyRequest> createRequest(PrivacyRequestSubmission request);

  Future<List<PrivacyRequest>> listMyRequests();

  Future<PrivacyRequest?> updateRequestStatus(String requestId, String status);
}

class MockSupportRepository implements SupportRepository {
  @override
  Future<SupportTicket> createSupportTicket({
    required String category,
    required String title,
    required String description,
  }) async {
    final now = DateTime.now();
    final ticket = SupportTicket(
      id: _uuid.v4(),
      userId: _mockSignedInProfile.id,
      category: category,
      title: title,
      description: description,
      status: 'open',
      createdAt: now,
      updatedAt: now,
    );
    _mockSupportTickets = [ticket, ..._mockSupportTickets];
    return ticket;
  }

  @override
  Future<List<SupportTicket>> listMyTickets() async => _mockSupportTickets;

  @override
  Future<SupportTicket?> getTicketDetail(String ticketId) async {
    for (final ticket in _mockSupportTickets) {
      if (ticket.id == ticketId) {
        return ticket;
      }
    }
    return null;
  }

  @override
  Future<List<SupportTicketMessage>> listMessages(String ticketId) async {
    return _mockSupportMessages
        .where((item) => item.ticketId == ticketId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<SupportTicketMessage> addMessage(
    String ticketId,
    String message, {
    bool isAdminReply = false,
  }) async {
    final now = DateTime.now();
    final item = SupportTicketMessage(
      id: _uuid.v4(),
      ticketId: ticketId,
      senderId: isAdminReply
          ? 'admin-${_mockSignedInProfile.id}'
          : _mockSignedInProfile.id,
      message: message,
      createdAt: now,
      isAdminReply: isAdminReply,
    );
    _mockSupportMessages = [item, ..._mockSupportMessages];
    _mockSupportTickets = _mockSupportTickets
        .map(
          (ticket) => ticket.id == ticketId
              ? ticket.copyWith(
                  status: isAdminReply ? 'review' : 'open',
                  updatedAt: now,
                )
              : ticket,
        )
        .toList();
    return item;
  }

  @override
  Future<SupportTicket?> updateTicketStatus(
    String ticketId,
    String status,
  ) async {
    final now = DateTime.now();
    SupportTicket? updated;
    _mockSupportTickets = _mockSupportTickets.map((ticket) {
      if (ticket.id != ticketId) {
        return ticket;
      }
      updated = ticket.copyWith(status: status, updatedAt: now);
      return updated!;
    }).toList();
    return updated;
  }
}

class MockReportRepository implements ReportRepository {
  @override
  Future<ReportItem> createReport(ReportRequest request) async {
    final item = ReportItem(
      id: _uuid.v4(),
      reporterId: _mockSignedInProfile.id,
      targetType: request.targetType,
      targetId:
          request.targetId.isEmpty ? _mockSignedInProfile.id : request.targetId,
      reason: request.reason,
      status: 'open',
      createdAt: DateTime.now(),
    );
    _mockReports = [item, ..._mockReports];
    return item;
  }

  @override
  Future<ReportItem?> updateReportStatus(String reportId, String status) async {
    ReportItem? updated;
    _mockReports = _mockReports.map((item) {
      if (item.id != reportId) {
        return item;
      }
      updated = item.copyWith(status: status);
      return updated!;
    }).toList();
    return updated;
  }

  List<ReportItem> get debugReports => _mockReports;
}

class MockPrivacyRequestRepository implements PrivacyRequestRepository {
  @override
  Future<PrivacyRequest> createRequest(
    PrivacyRequestSubmission request,
  ) async {
    final existingRequest = _activePrivacyRequestForType(
      _mockPrivacyRequests,
      userId: _mockSignedInProfile.id,
      requestType: request.requestType,
    );
    if (existingRequest != null) {
      throw ActivePrivacyRequestException(existingRequest);
    }

    final now = DateTime.now();
    final item = PrivacyRequest(
      id: _uuid.v4(),
      userId: _mockSignedInProfile.id,
      requestType: request.requestType,
      description: request.description,
      status: 'open',
      createdAt: now,
      updatedAt: now,
    );
    _mockPrivacyRequests = [item, ..._mockPrivacyRequests];
    return item;
  }

  @override
  Future<List<PrivacyRequest>> listMyRequests() async => _mockPrivacyRequests;

  @override
  Future<PrivacyRequest?> updateRequestStatus(
    String requestId,
    String status,
  ) async {
    final now = DateTime.now();
    PrivacyRequest? updated;
    _mockPrivacyRequests = _mockPrivacyRequests.map((item) {
      if (item.id != requestId) {
        return item;
      }
      updated = item.copyWith(status: status, updatedAt: now);
      return updated!;
    }).toList();
    return updated;
  }

  List<PrivacyRequest> get debugRequests => _mockPrivacyRequests;
}

PrivacyRequest? _activePrivacyRequestForType(
  Iterable<PrivacyRequest> requests, {
  required String userId,
  required String requestType,
}) {
  for (final request in requests) {
    if (request.userId == userId &&
        request.requestType == requestType &&
        _isActivePrivacyRequestStatus(request.status)) {
      return request;
    }
  }
  return null;
}

bool _isActivePrivacyRequestStatus(String status) {
  final normalized = status.toLowerCase();
  return normalized == 'open' || normalized == 'review';
}

class SupabaseSupportRepository implements SupportRepository {
  SupabaseSupportRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockSupportRepository _fallback = MockSupportRepository();

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<SupportTicket> createSupportTicket({
    required String category,
    required String title,
    required String description,
  }) async {
    final userId = _userId;
    if (userId == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.createSupportTicket(
          category: category, title: title, description: description);
    }
    try {
      final row = await _client
          .from('support_tickets')
          .insert({
            'user_id': userId,
            'category': category,
            'title': title,
            'description': description,
          })
          .select()
          .single();
      return _ticketFromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.createSupportTicket(
          category: category, title: title, description: description);
    }
  }

  @override
  Future<List<SupportTicket>> listMyTickets() async {
    final userId = _userId;
    if (userId == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.listMyTickets();
    }
    try {
      final rows = await _client
          .from('support_tickets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows
          .map((row) => _ticketFromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.listMyTickets();
    }
  }

  @override
  Future<SupportTicket?> getTicketDetail(String ticketId) async {
    if (_userId == null && !allowMockFallback) {
      throw StateError('로그인이 필요합니다.');
    }
    try {
      final row = await _client
          .from('support_tickets')
          .select()
          .eq('id', ticketId)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return _ticketFromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getTicketDetail(ticketId);
    }
  }

  @override
  Future<List<SupportTicketMessage>> listMessages(String ticketId) async {
    if (_userId == null && !allowMockFallback) {
      throw StateError('로그인이 필요합니다.');
    }
    try {
      final rows = await _client
          .from('support_ticket_messages')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);
      return rows
          .map((row) => _messageFromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.listMessages(ticketId);
    }
  }

  @override
  Future<SupportTicketMessage> addMessage(
    String ticketId,
    String message, {
    bool isAdminReply = false,
  }) async {
    final userId = _userId;
    if (userId == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.addMessage(
        ticketId,
        message,
        isAdminReply: isAdminReply,
      );
    }
    try {
      final row = await _client
          .from('support_ticket_messages')
          .insert({
            'ticket_id': ticketId,
            'sender_id': userId,
            'message': message,
            'is_admin_reply': isAdminReply,
          })
          .select()
          .single();
      await _client.from('support_tickets').update({
        'status': isAdminReply ? 'review' : 'open',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', ticketId);
      return _messageFromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.addMessage(
        ticketId,
        message,
        isAdminReply: isAdminReply,
      );
    }
  }

  @override
  Future<SupportTicket?> updateTicketStatus(
    String ticketId,
    String status,
  ) async {
    if (_userId == null && !allowMockFallback) {
      throw StateError('로그인이 필요합니다.');
    }
    try {
      final row = await _client
          .from('support_tickets')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId)
          .select()
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return _ticketFromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.updateTicketStatus(ticketId, status);
    }
  }

  SupportTicket _ticketFromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      category: '${json['category'] ?? ''}',
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      status: '${json['status'] ?? 'open'}',
      createdAt:
          DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse('${json['updated_at'] ?? ''}') ?? DateTime.now(),
    );
  }

  SupportTicketMessage _messageFromJson(Map<String, dynamic> json) {
    return SupportTicketMessage(
      id: '${json['id'] ?? ''}',
      ticketId: '${json['ticket_id'] ?? ''}',
      senderId: '${json['sender_id'] ?? ''}',
      message: '${json['message'] ?? ''}',
      createdAt:
          DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      isAdminReply: _boolFrom(json['is_admin_reply'], false),
    );
  }
}

class SupabaseReportRepository implements ReportRepository {
  SupabaseReportRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockReportRepository _fallback = MockReportRepository();

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<ReportItem> createReport(ReportRequest request) async {
    final userId = _userId;
    if (userId == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.createReport(request);
    }
    try {
      final row = await _client
          .from('report_items')
          .insert({
            'reporter_id': userId,
            'target_type': request.targetType,
            'target_id': request.targetId.isEmpty ? userId : request.targetId,
            'reason': request.reason,
            'status': 'open',
          })
          .select()
          .single();
      return _reportFromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.createReport(request);
    }
  }

  @override
  Future<ReportItem?> updateReportStatus(
    String reportId,
    String status,
  ) async {
    if (_userId == null && !allowMockFallback) {
      throw StateError('관리자 권한이 필요합니다.');
    }
    try {
      final row = await _client
          .from('report_items')
          .update({'status': status})
          .eq('id', reportId)
          .select()
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return _reportFromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.updateReportStatus(reportId, status);
    }
  }

  ReportItem _reportFromJson(Map<String, dynamic> json) {
    return ReportItem(
      id: '${json['id'] ?? ''}',
      reporterId: '${json['reporter_id'] ?? ''}',
      targetType: '${json['target_type'] ?? ''}',
      targetId: '${json['target_id'] ?? ''}',
      reason: '${json['reason'] ?? ''}',
      status: '${json['status'] ?? 'open'}',
      createdAt:
          DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
    );
  }
}

class SupabasePrivacyRequestRepository implements PrivacyRequestRepository {
  SupabasePrivacyRequestRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockPrivacyRequestRepository _fallback = MockPrivacyRequestRepository();

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<PrivacyRequest> createRequest(
    PrivacyRequestSubmission request,
  ) async {
    final userId = _userId;
    if (userId == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.createRequest(request);
    }
    try {
      final existingRequest =
          await _findActivePrivacyRequest(userId, request.requestType);
      if (existingRequest != null) {
        throw ActivePrivacyRequestException(existingRequest);
      }

      final row = await _client
          .from('privacy_requests')
          .insert({
            'user_id': userId,
            'request_type': request.requestType,
            'description': request.description,
            'status': 'open',
          })
          .select()
          .single();
      return _privacyRequestFromJson(Map<String, dynamic>.from(row));
    } on ActivePrivacyRequestException {
      rethrow;
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.createRequest(request);
    }
  }

  @override
  Future<List<PrivacyRequest>> listMyRequests() async {
    final userId = _userId;
    if (userId == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.listMyRequests();
    }
    try {
      final rows = await _client
          .from('privacy_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows
          .map((row) => _privacyRequestFromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.listMyRequests();
    }
  }

  @override
  Future<PrivacyRequest?> updateRequestStatus(
    String requestId,
    String status,
  ) async {
    if (_userId == null && !allowMockFallback) {
      throw StateError('로그인이 필요합니다.');
    }
    try {
      final row = await _client
          .from('privacy_requests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
            if (status == 'completed' || status == 'rejected')
              'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .select()
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return _privacyRequestFromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.updateRequestStatus(requestId, status);
    }
  }

  Future<PrivacyRequest?> _findActivePrivacyRequest(
    String userId,
    String requestType,
  ) async {
    final rows = await _client
        .from('privacy_requests')
        .select()
        .eq('user_id', userId)
        .eq('request_type', requestType)
        .order('updated_at', ascending: false)
        .limit(8);
    for (final row in rows) {
      final request = _privacyRequestFromJson(Map<String, dynamic>.from(row));
      if (_isActivePrivacyRequestStatus(request.status)) {
        return request;
      }
    }
    return null;
  }

  PrivacyRequest _privacyRequestFromJson(Map<String, dynamic> json) {
    return PrivacyRequest(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      requestType: '${json['request_type'] ?? ''}',
      description: '${json['description'] ?? ''}',
      status: '${json['status'] ?? 'open'}',
      createdAt:
          DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse('${json['updated_at'] ?? ''}') ?? DateTime.now(),
    );
  }
}

abstract class CrewRepository {
  Future<Crew?> getMyCrew();

  Future<List<CrewMember>> listMembers();
}

class MockCrewRepository implements CrewRepository {
  @override
  Future<Crew?> getMyCrew() async => const Crew(
        id: 'crew-001',
        name: 'Neon Commuters',
        description: '출퇴근 효율을 경쟁하는 크루',
        memberCount: 8,
        weeklyScore: 18420,
      );

  @override
  Future<List<CrewMember>> listMembers() async => mockCrewMembers;
}

class SupabaseCrewRepository implements CrewRepository {
  SupabaseCrewRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockCrewRepository _fallback = MockCrewRepository();

  @override
  Future<Crew?> getMyCrew() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.getMyCrew();
    }
    try {
      final result = await _client.rpc('get_my_crew_summary');
      if (result is! List || result.isEmpty) {
        return null;
      }
      return _crewFromJson(Map<String, dynamic>.from(result.first as Map));
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getMyCrew();
    }
  }

  @override
  Future<List<CrewMember>> listMembers() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!allowMockFallback) {
        throw StateError('로그인이 필요합니다.');
      }
      return _fallback.listMembers();
    }
    try {
      final result = await _client.rpc('get_my_crew_members');
      if (result is! List) {
        return const [];
      }
      return result
          .map((row) => _memberFromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.listMembers();
    }
  }

  Crew _crewFromJson(Map<String, dynamic> json) {
    return Crew(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? '내 크루'}',
      description: '${json['description'] ?? ''}',
      memberCount: _intFrom(json['member_count'], 0),
      weeklyScore: _intFrom(json['weekly_score'], 0),
    );
  }

  CrewMember _memberFromJson(Map<String, dynamic> json) {
    return CrewMember(
      crewId: '${json['crew_id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      nickname: '${json['nickname'] ?? 'Fuel Driver'}',
      role: '${json['role'] ?? 'member'}',
      weeklyContribution: _intFrom(json['weekly_contribution'], 0),
    );
  }
}

abstract class AdminRepository {
  Future<List<AdminMetric>> getMetrics();

  Future<AdminRecordPage> getRecords(AdminRecordQuery query);

  Future<AdminActionLog> recordAction(AdminActionRequest request);
}

class MockAdminRepository implements AdminRepository {
  @override
  Future<List<AdminMetric>> getMetrics() async => mockAdminMetrics;

  @override
  Future<AdminRecordPage> getRecords(AdminRecordQuery query) async {
    if (query.section == 'Reports') {
      return _mockReportAdminRecords(query);
    }
    if (query.section == 'Privacy Requests') {
      return _mockPrivacyRequestAdminRecords(query);
    }
    final filtered = _mockAdminRecordsFor(query.section).where((record) {
      final search = query.search.trim();
      final queryMatched = search.isEmpty ||
          record.id.contains(search) ||
          record.title.contains(search) ||
          record.owner.contains(search) ||
          record.metadata.values.any((value) => value.contains(search));
      final statusMatched =
          query.status == '전체' || record.status == query.status;
      return queryMatched && statusMatched;
    }).toList();
    final start = (query.page * query.pageSize).clamp(0, filtered.length);
    final end = (start + query.pageSize).clamp(start, filtered.length);
    return AdminRecordPage(
      section: query.section,
      items: filtered.sublist(start, end),
      page: query.page,
      pageSize: query.pageSize,
      totalCount: filtered.length,
    );
  }

  @override
  Future<AdminActionLog> recordAction(AdminActionRequest request) async {
    final now = DateTime.now();
    final log = AdminActionLog(
      id: _uuid.v4(),
      section: request.section,
      action: request.action,
      adminUserId: _mockSignedInProfile.id,
      targetId: request.record?.id ?? '',
      targetTitle: request.record?.title ?? '',
      targetStatus: request.record?.status ?? '',
      createdAt: now,
    );
    _mockAdminActionLogs = [log, ..._mockAdminActionLogs];
    return log;
  }

  List<AdminActionLog> get debugActionLogs => _mockAdminActionLogs;
}

AdminRecordPage _mockReportAdminRecords(AdminRecordQuery query) {
  final filtered = _mockReports.map(_adminRecordFromReportItem).where(
    (record) {
      final search = query.search.trim();
      final queryMatched = search.isEmpty ||
          record.id.contains(search) ||
          record.title.contains(search) ||
          record.owner.contains(search) ||
          record.description.contains(search) ||
          record.metadata.values.any((value) => value.contains(search));
      final statusMatched =
          query.status == '전체' || record.status == query.status;
      return queryMatched && statusMatched;
    },
  ).toList();
  final start = (query.page * query.pageSize).clamp(0, filtered.length);
  final end = (start + query.pageSize).clamp(start, filtered.length);
  return AdminRecordPage(
    section: query.section,
    items: filtered.sublist(start, end),
    page: query.page,
    pageSize: query.pageSize,
    totalCount: filtered.length,
  );
}

AdminRecord _adminRecordFromReportItem(ReportItem report) {
  return AdminRecord(
    id: report.id,
    title: _reportTargetTypeAdminLabel(report.targetType),
    status: report.status,
    owner: report.reporterId,
    description: report.reason,
    createdAt: report.createdAt,
    metadata: {
      'target_type': report.targetType,
      'target_id': report.targetId,
    },
  );
}

String _reportTargetTypeAdminLabel(String targetType) {
  return switch (targetType) {
    'drive_review_request' => '주행 기록 이의제기',
    'drive_record' => '주행 기록 신고',
    'user' => '사용자 신고',
    _ => targetType,
  };
}

AdminRecordPage _mockPrivacyRequestAdminRecords(AdminRecordQuery query) {
  final filtered =
      _mockPrivacyRequests.map(_adminRecordFromPrivacyRequest).where(
    (record) {
      final search = query.search.trim();
      final queryMatched = search.isEmpty ||
          record.id.contains(search) ||
          record.title.contains(search) ||
          record.owner.contains(search) ||
          record.description.contains(search);
      final statusMatched =
          query.status == '전체' || record.status == query.status;
      return queryMatched && statusMatched;
    },
  ).toList();
  final start = (query.page * query.pageSize).clamp(0, filtered.length);
  final end = (start + query.pageSize).clamp(start, filtered.length);
  return AdminRecordPage(
    section: query.section,
    items: filtered.sublist(start, end),
    page: query.page,
    pageSize: query.pageSize,
    totalCount: filtered.length,
  );
}

AdminRecord _adminRecordFromPrivacyRequest(PrivacyRequest request) {
  return AdminRecord(
    id: request.id,
    title: _privacyRequestTypeAdminLabel(request.requestType),
    status: request.status,
    owner: request.userId,
    description: request.description,
    createdAt: request.createdAt,
    metadata: {
      'request_type': request.requestType,
      'updated_at': request.updatedAt.toIso8601String(),
    },
  );
}

String _privacyRequestTypeAdminLabel(String type) {
  return switch (type) {
    'data_download' => '데이터 다운로드',
    'data_delete' => '데이터 삭제',
    'account_deletion' => '계정 삭제',
    'consent_withdrawal' => '동의 철회',
    _ => type,
  };
}

class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository({
    SupabaseClient? client,
    this.allowMockFallback = true,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final bool allowMockFallback;
  final MockAdminRepository _fallback = MockAdminRepository();

  @override
  Future<List<AdminMetric>> getMetrics() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!allowMockFallback) {
        throw StateError('관리자 권한이 필요합니다.');
      }
      return _fallback.getMetrics();
    }
    try {
      final result = await _client.rpc('get_admin_dashboard_metrics');
      if (result is! List) {
        if (!allowMockFallback) {
          throw StateError('관리자 지표 응답 형식이 올바르지 않습니다.');
        }
        return _fallback.getMetrics();
      }
      return result
          .map((row) => _adminMetricFromRow(Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getMetrics();
    }
  }

  @override
  Future<AdminRecordPage> getRecords(AdminRecordQuery query) async {
    final config = _adminSectionConfig(query.section);
    if (config == null) {
      if (!allowMockFallback) {
        return AdminRecordPage(
          section: query.section,
          items: const [],
          page: query.page,
          pageSize: query.pageSize,
          totalCount: 0,
        );
      }
      return _fallback.getRecords(query);
    }
    if (_client.auth.currentUser == null && !allowMockFallback) {
      throw StateError('관리자 권한이 필요합니다.');
    }
    try {
      final start = query.page * query.pageSize;
      final end = start + query.pageSize - 1;
      var builder = _client.from(config.table).select(config.selectColumns);
      if (query.status != '전체' && config.statusColumn.isNotEmpty) {
        builder = builder.eq(config.statusColumn, query.status);
      }
      final search = query.search.trim();
      if (search.isNotEmpty && config.searchColumn.isNotEmpty) {
        builder = builder.ilike(config.searchColumn, '%$search%');
      }
      final rows = await builder
          .order(config.orderColumn, ascending: false)
          .range(start, end);
      final items = rows
          .map<AdminRecord>((row) => _adminRecordFromRow(config, row))
          .toList();
      final optimisticTotal =
          start + items.length + (items.length == query.pageSize ? 1 : 0);
      return AdminRecordPage(
        section: query.section,
        items: items,
        page: query.page,
        pageSize: query.pageSize,
        totalCount: optimisticTotal,
      );
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.getRecords(query);
    }
  }

  @override
  Future<AdminActionLog> recordAction(AdminActionRequest request) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!allowMockFallback) {
        throw StateError('관리자 권한이 필요합니다.');
      }
      return _fallback.recordAction(request);
    }
    final config = _adminSectionConfig(request.section);
    final record = request.record;
    try {
      final row = await _client
          .from('admin_action_logs')
          .insert({
            'admin_user_id': user.id,
            'section': request.section,
            'action': request.action,
            'target_table': config?.table,
            'target_id': record?.id,
            'target_title': record?.title,
            'target_status': record?.status,
            'metadata': {
              if (record != null) ...record.metadata,
              if (record?.description.isNotEmpty == true)
                'description': record!.description,
            },
          })
          .select()
          .single();
      return _adminActionLogFromRow(Map<String, dynamic>.from(row));
    } catch (_) {
      if (!allowMockFallback) {
        rethrow;
      }
      return _fallback.recordAction(request);
    }
  }
}

AdminMetric _adminMetricFromRow(Map<String, dynamic> row) {
  return AdminMetric(
    id: '${row['id'] ?? ''}',
    label: '${row['label'] ?? ''}',
    value: '${row['value'] ?? '0'}',
    unit: row['unit'] == null ? null : '${row['unit']}',
    healthy: _boolFrom(row['healthy'], true),
  );
}

AdminActionLog _adminActionLogFromRow(Map<String, dynamic> row) {
  return AdminActionLog(
    id: '${row['id'] ?? ''}',
    section: '${row['section'] ?? ''}',
    action: '${row['action'] ?? ''}',
    adminUserId: '${row['admin_user_id'] ?? ''}',
    targetId: '${row['target_id'] ?? ''}',
    targetTitle: '${row['target_title'] ?? ''}',
    targetStatus: '${row['target_status'] ?? ''}',
    createdAt:
        DateTime.tryParse('${row['created_at'] ?? ''}') ?? DateTime.now(),
  );
}

class _AdminSectionConfig {
  const _AdminSectionConfig({
    required this.table,
    required this.selectColumns,
    required this.titleColumn,
    required this.statusColumn,
    required this.ownerColumn,
    required this.orderColumn,
    this.searchColumn = '',
    this.descriptionColumn = '',
  });

  final String table;
  final String selectColumns;
  final String titleColumn;
  final String statusColumn;
  final String ownerColumn;
  final String orderColumn;
  final String searchColumn;
  final String descriptionColumn;
}

_AdminSectionConfig? _adminSectionConfig(String section) {
  return switch (section) {
    'Users' => const _AdminSectionConfig(
        table: 'profiles',
        selectColumns:
            'id,nickname,tier,auth_provider,is_admin,created_at,season_score',
        titleColumn: 'nickname',
        statusColumn: 'tier',
        ownerColumn: 'auth_provider',
        orderColumn: 'created_at',
        searchColumn: 'nickname',
        descriptionColumn: 'season_score',
      ),
    'User Vehicles' => const _AdminSectionConfig(
        table: 'user_vehicles',
        selectColumns:
            'id,nickname,manufacturer_name,model_name,verification_status,user_id,created_at',
        titleColumn: 'nickname',
        statusColumn: 'verification_status',
        ownerColumn: 'user_id',
        orderColumn: 'created_at',
        searchColumn: 'nickname',
        descriptionColumn: 'model_name',
      ),
    'Drive Sessions' => const _AdminSectionConfig(
        table: 'drive_sessions',
        selectColumns:
            'id,status,user_id,vehicle_id,distance_km,duration_seconds,created_at',
        titleColumn: 'vehicle_id',
        statusColumn: 'status',
        ownerColumn: 'user_id',
        orderColumn: 'created_at',
        searchColumn: 'id',
        descriptionColumn: 'distance_km',
      ),
    'Drive Scores' => const _AdminSectionConfig(
        table: 'drive_scores',
        selectColumns:
            'id,verification_status,user_id,drive_session_id,total_score,created_at',
        titleColumn: 'drive_session_id',
        statusColumn: 'verification_status',
        ownerColumn: 'user_id',
        orderColumn: 'created_at',
        searchColumn: 'drive_session_id',
        descriptionColumn: 'total_score',
      ),
    'Rankings' => const _AdminSectionConfig(
        table: 'rankings',
        selectColumns:
            'id,period,user_id,tier,score,rank,vehicle_class,fuel_type,created_at',
        titleColumn: 'tier',
        statusColumn: 'period',
        ownerColumn: 'user_id',
        orderColumn: 'created_at',
        searchColumn: 'tier',
        descriptionColumn: 'score',
      ),
    'Battles' => const _AdminSectionConfig(
        table: 'battles',
        selectColumns:
            'id,title,status,created_by,battle_type,reward_summary,created_at',
        titleColumn: 'title',
        statusColumn: 'status',
        ownerColumn: 'created_by',
        orderColumn: 'created_at',
        searchColumn: 'title',
        descriptionColumn: 'reward_summary',
      ),
    'Seasons' => const _AdminSectionConfig(
        table: 'seasons',
        selectColumns: 'id,name,status,theme,start_at,end_at',
        titleColumn: 'name',
        statusColumn: 'status',
        ownerColumn: 'theme',
        orderColumn: 'start_at',
        searchColumn: 'name',
        descriptionColumn: 'theme',
      ),
    'Support Tickets' => const _AdminSectionConfig(
        table: 'support_tickets',
        selectColumns:
            'id,title,status,user_id,category,description,created_at,updated_at',
        titleColumn: 'title',
        statusColumn: 'status',
        ownerColumn: 'user_id',
        orderColumn: 'created_at',
        searchColumn: 'title',
        descriptionColumn: 'description',
      ),
    'Reports' => const _AdminSectionConfig(
        table: 'report_items',
        selectColumns:
            'id,target_type,target_id,status,reporter_id,reason,created_at',
        titleColumn: 'target_type',
        statusColumn: 'status',
        ownerColumn: 'reporter_id',
        orderColumn: 'created_at',
        searchColumn: 'target_id',
        descriptionColumn: 'reason',
      ),
    'Privacy Requests' => const _AdminSectionConfig(
        table: 'privacy_requests',
        selectColumns:
            'id,request_type,status,user_id,description,created_at,updated_at,resolved_at',
        titleColumn: 'request_type',
        statusColumn: 'status',
        ownerColumn: 'user_id',
        orderColumn: 'created_at',
        searchColumn: 'description',
        descriptionColumn: 'description',
      ),
    'Fraud Reviews' => const _AdminSectionConfig(
        table: 'fraud_reviews',
        selectColumns: 'id,reason,status,drive_session_id,created_at',
        titleColumn: 'reason',
        statusColumn: 'status',
        ownerColumn: 'drive_session_id',
        orderColumn: 'created_at',
        searchColumn: 'reason',
        descriptionColumn: 'drive_session_id',
      ),
    'Consent Logs' => const _AdminSectionConfig(
        table: 'consent_logs',
        selectColumns:
            'id,user_id,terms_accepted,privacy_accepted,location_accepted,personalized_ads_accepted,marketing_accepted,created_at',
        titleColumn: 'id',
        statusColumn: '',
        ownerColumn: 'user_id',
        orderColumn: 'created_at',
        searchColumn: 'user_id',
        descriptionColumn: 'created_at',
      ),
    'Admin Actions' => const _AdminSectionConfig(
        table: 'admin_action_logs',
        selectColumns:
            'id,section,action,admin_user_id,target_title,target_status,created_at',
        titleColumn: 'action',
        statusColumn: 'section',
        ownerColumn: 'admin_user_id',
        orderColumn: 'created_at',
        searchColumn: 'action',
        descriptionColumn: 'target_title',
      ),
    _ => null,
  };
}

AdminRecord _adminRecordFromRow(
  _AdminSectionConfig config,
  Map<String, dynamic> row,
) {
  final id = '${row['id'] ?? ''}';
  final title = '${row[config.titleColumn] ?? id}';
  final status = '${row[config.statusColumn] ?? 'active'}';
  final owner = '${row[config.ownerColumn] ?? 'System'}';
  final description = config.descriptionColumn.isEmpty
      ? ''
      : '${row[config.descriptionColumn] ?? ''}';
  final metadata = <String, String>{};
  for (final entry in row.entries) {
    if (entry.key == 'id') {
      continue;
    }
    metadata[entry.key] = '${entry.value ?? ''}';
  }
  return AdminRecord(
    id: id,
    title: title,
    status: status,
    owner: owner,
    description: description,
    createdAt:
        DateTime.tryParse('${row['created_at'] ?? row['start_at'] ?? ''}'),
    metadata: metadata,
  );
}

List<AdminRecord> _mockAdminRecordsFor(String section) {
  final normalized = section.toLowerCase().replaceAll(' ', '-');
  return List.generate(28, (index) {
    final number = (index + 1).toString().padLeft(3, '0');
    final status = switch (index % 5) {
      0 => 'active',
      1 => 'pending',
      2 => section.contains('Drive') ? 'blocked' : 'review',
      3 => 'verified',
      _ => 'resolved',
    };
    return AdminRecord(
      id: '$normalized-$number',
      title: '$section 운영 항목 $number',
      status: status,
      owner: ['Ops', 'Review', 'System', 'Support'][index % 4],
      description: '$section 운영 상세와 변경 이력을 확인합니다.',
      createdAt: DateTime.now().subtract(Duration(hours: index * 3)),
      metadata: {
        'priority': index % 4 == 0 ? 'high' : 'normal',
        'page_source': 'local',
        'section': section,
      },
    );
  });
}

Future<_VehicleCatalogAsset>? _vehicleCatalogAssetFuture;

Future<_VehicleCatalogAsset> _loadVehicleCatalogAsset() {
  return _vehicleCatalogAssetFuture ??= _readVehicleCatalogAsset();
}

Future<_VehicleCatalogAsset> _readVehicleCatalogAsset() async {
  try {
    final raw = await rootBundle.loadString(
      'assets/data/vehicle_catalog_kr_seed.json',
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return _VehicleCatalogAsset.fromJson(data);
  } catch (_) {
    return _VehicleCatalogAsset.fallback();
  }
}

class _VehicleCatalogAsset {
  const _VehicleCatalogAsset({
    required this.manufacturers,
    required this.models,
    required this.years,
    required this.variants,
  });

  factory _VehicleCatalogAsset.fromJson(Map<String, dynamic> json) {
    return _VehicleCatalogAsset(
      manufacturers: (json['manufacturers'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(VehicleManufacturer.fromJson)
          .toList(),
      models: (json['models'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(VehicleModel.fromJson)
          .toList(),
      years: (json['years'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(VehicleModelYear.fromJson)
          .toList(),
      variants: (json['variants'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(VehicleVariant.fromJson)
          .toList(),
    );
  }

  factory _VehicleCatalogAsset.fallback() {
    return const _VehicleCatalogAsset(
      manufacturers: _catalogManufacturers,
      models: _catalogModels,
      years: _catalogYears,
      variants: _catalogVariants,
    );
  }

  final List<VehicleManufacturer> manufacturers;
  final List<VehicleModel> models;
  final List<VehicleModelYear> years;
  final List<VehicleVariant> variants;
}

Map<String, _ManufacturerCatalogStats> _manufacturerStatsById(
  _VehicleCatalogAsset catalog,
) {
  final modelCounts = <String, Set<String>>{};
  final yearRanges = <String, List<int>>{};
  final modelManufacturerById = {
    for (final model in catalog.models) model.id: model.manufacturerId,
  };

  for (final model in catalog.models) {
    modelCounts
        .putIfAbsent(model.manufacturerId, () => <String>{})
        .add(model.id);
  }
  for (final year in catalog.years) {
    final manufacturerId = modelManufacturerById[year.modelId];
    if (manufacturerId == null) {
      continue;
    }
    final range =
        yearRanges.putIfAbsent(manufacturerId, () => [year.year, year.year]);
    if (year.year < range[0]) {
      range[0] = year.year;
    }
    if (year.year > range[1]) {
      range[1] = year.year;
    }
  }

  return {
    for (final manufacturer in catalog.manufacturers)
      manufacturer.id: _ManufacturerCatalogStats(
        modelCount: modelCounts[manufacturer.id]?.length ?? 0,
        minYear: yearRanges[manufacturer.id]?[0] ?? 0,
        maxYear: yearRanges[manufacturer.id]?[1] ?? 0,
      ),
  };
}

class _ManufacturerCatalogStats {
  const _ManufacturerCatalogStats({
    required this.modelCount,
    required this.minYear,
    required this.maxYear,
  });

  final int modelCount;
  final int minYear;
  final int maxYear;
}

bool _manufacturerCountryMatches(VehicleManufacturer item, String? country) {
  final normalized = country?.trim().toUpperCase() ?? '';
  if (normalized.isEmpty) {
    return true;
  }
  if (normalized == 'IMPORT') {
    return item.country.toUpperCase() != 'KR';
  }
  return item.country.toUpperCase() == normalized;
}

const _catalogManufacturers = [
          VehicleManufacturer(
      id: 'm-hyundai',
      nameKo: '현대',
      nameEn: 'Hyundai',
      country: 'KR',
      isPopular: true,
      sortOrder: 10),
  VehicleManufacturer(
      id: 'm-kia',
      nameKo: '기아',
      nameEn: 'Kia',
      country: 'KR',
      isPopular: true,
      sortOrder: 20),
  VehicleManufacturer(
      id: 'm-genesis',
      nameKo: '제네시스',
      nameEn: 'Genesis',
      country: 'KR',
      isPopular: true,
      sortOrder: 30),
  VehicleManufacturer(
      id: 'm-chevrolet',
      nameKo: '쉐보레',
      nameEn: 'Chevrolet',
      country: 'US',
      isPopular: false,
      sortOrder: 40),
  VehicleManufacturer(
      id: 'm-renault',
      nameKo: '르노코리아',
      nameEn: 'Renault Korea',
      country: 'KR',
      isPopular: false,
      sortOrder: 50),
  VehicleManufacturer(
      id: 'm-kgm',
      nameKo: 'KG모빌리티',
      nameEn: 'KG Mobility',
      country: 'KR',
      isPopular: false,
      sortOrder: 60),
  VehicleManufacturer(
      id: 'm-bmw',
      nameKo: 'BMW',
      nameEn: 'BMW',
      country: 'DE',
      isPopular: true,
      sortOrder: 70),
  VehicleManufacturer(
      id: 'm-benz',
      nameKo: '메르세데스-벤츠',
      nameEn: 'Mercedes-Benz',
      country: 'DE',
      isPopular: false,
      sortOrder: 80),
  VehicleManufacturer(
      id: 'm-audi',
      nameKo: '아우디',
      nameEn: 'Audi',
      country: 'DE',
      isPopular: false,
      sortOrder: 90),
  VehicleManufacturer(
      id: 'm-volkswagen',
      nameKo: '폭스바겐',
      nameEn: 'Volkswagen',
      country: 'DE',
      isPopular: false,
      sortOrder: 100),
  VehicleManufacturer(
      id: 'm-toyota',
      nameKo: '토요타',
      nameEn: 'Toyota',
      country: 'JP',
      isPopular: false,
      sortOrder: 110),
  VehicleManufacturer(
      id: 'm-lexus',
      nameKo: '렉서스',
      nameEn: 'Lexus',
      country: 'JP',
      isPopular: false,
      sortOrder: 120),
  VehicleManufacturer(
      id: 'm-honda',
      nameKo: '혼다',
      nameEn: 'Honda',
      country: 'JP',
      isPopular: false,
      sortOrder: 130),
  VehicleManufacturer(
      id: 'm-nissan',
      nameKo: '닛산',
      nameEn: 'Nissan',
      country: 'JP',
      isPopular: false,
      sortOrder: 140),
  VehicleManufacturer(
      id: 'm-tesla',
      nameKo: '테슬라',
      nameEn: 'Tesla',
      country: 'US',
      isPopular: true,
      sortOrder: 150),
  VehicleManufacturer(
      id: 'm-volvo',
      nameKo: '볼보',
      nameEn: 'Volvo',
      country: 'SE',
      isPopular: false,
      sortOrder: 160),
  VehicleManufacturer(
      id: 'm-porsche',
      nameKo: '포르쉐',
      nameEn: 'Porsche',
      country: 'DE',
      isPopular: false,
      sortOrder: 170),
  VehicleManufacturer(
      id: 'm-mini',
      nameKo: 'MINI',
      nameEn: 'MINI',
      country: 'GB',
      isPopular: false,
      sortOrder: 180),
  VehicleManufacturer(
      id: 'm-peugeot',
      nameKo: '푸조',
      nameEn: 'Peugeot',
      country: 'FR',
      isPopular: false,
      sortOrder: 190),
  VehicleManufacturer(
      id: 'm-jeep',
      nameKo: '지프',
      nameEn: 'Jeep',
      country: 'US',
      isPopular: false,
      sortOrder: 200),
  VehicleManufacturer(
      id: 'm-landrover',
      nameKo: '랜드로버',
      nameEn: 'Land Rover',
      country: 'GB',
      isPopular: false,
      sortOrder: 210),
  VehicleManufacturer(
      id: 'm-polestar',
      nameKo: '폴스타',
      nameEn: 'Polestar',
      country: 'SE',
      isPopular: false,
      sortOrder: 220)




];

const _catalogModels = [
          VehicleModel(
      id: 'model-hyundai-001-kr',
      manufacturerId: 'm-hyundai',
      nameKo: '아반떼',
      nameEn: 'Avante',
      bodyType: '세단',
      availableFuelTypes: ['가솔린', '하이브리드', 'LPG'],
      isPopular: true,
      sortOrder: 10),
  VehicleModel(
      id: 'model-hyundai-002-kr',
      manufacturerId: 'm-hyundai',
      nameKo: '쏘나타',
      nameEn: 'Sonata',
      bodyType: '세단',
      availableFuelTypes: ['가솔린', '하이브리드', 'LPG'],
      isPopular: false,
      sortOrder: 20),
  VehicleModel(
      id: 'model-hyundai-003-kr',
      manufacturerId: 'm-hyundai',
      nameKo: '그랜저',
      nameEn: 'Grandeur',
      bodyType: '세단',
      availableFuelTypes: ['가솔린', '하이브리드'],
      isPopular: false,
      sortOrder: 30),
  VehicleModel(
      id: 'model-hyundai-004-kr',
      manufacturerId: 'm-hyundai',
      nameKo: '코나',
      nameEn: 'Kona',
      bodyType: 'SUV',
      availableFuelTypes: ['가솔린', '하이브리드', '전기차'],
      isPopular: false,
      sortOrder: 40),
  VehicleModel(
      id: 'model-hyundai-005-kr',
      manufacturerId: 'm-hyundai',
      nameKo: '투싼',
      nameEn: 'Tucson',
      bodyType: 'SUV',
      availableFuelTypes: ['가솔린', '디젤', '하이브리드'],
      isPopular: false,
      sortOrder: 50),
  VehicleModel(
      id: 'model-hyundai-006-kr',
      manufacturerId: 'm-hyundai',
      nameKo: '싼타페',
      nameEn: 'Santa Fe',
      bodyType: 'SUV',
      availableFuelTypes: ['가솔린', '하이브리드'],
      isPopular: false,
      sortOrder: 60),
  VehicleModel(
      id: 'model-hyundai-007-kr',
      manufacturerId: 'm-hyundai',
      nameKo: '팰리세이드',
      nameEn: 'Palisade',
      bodyType: 'SUV',
      availableFuelTypes: ['가솔린', '디젤'],
      isPopular: false,
      sortOrder: 70),
  VehicleModel(
      id: 'model-hyundai-008-kr',
      manufacturerId: 'm-hyundai',
      nameKo: '캐스퍼',
      nameEn: 'Casper',
      bodyType: '경형 SUV',
      availableFuelTypes: ['가솔린'],
      isPopular: false,
      sortOrder: 80),
  VehicleModel(
      id: 'model-hyundai-009-5',
      manufacturerId: 'm-hyundai',
      nameKo: '아이오닉 5',
      nameEn: 'IONIQ 5',
      bodyType: '전기 SUV',
      availableFuelTypes: ['전기차'],
      isPopular: false,
      sortOrder: 90),
  VehicleModel(
      id: 'model-hyundai-010-6',
      manufacturerId: 'm-hyundai',
      nameKo: '아이오닉 6',
      nameEn: 'IONIQ 6',
      bodyType: '전기 세단',
      availableFuelTypes: ['전기차'],
      isPopular: false,
      sortOrder: 100),
  VehicleModel(
      id: 'model-kia-014-k5',
      manufacturerId: 'm-kia',
      nameKo: 'K5',
      nameEn: 'K5',
      bodyType: '세단',
      availableFuelTypes: ['가솔린', '하이브리드', 'LPG'],
      isPopular: true,
      sortOrder: 20),
  VehicleModel(
      id: 'model-kia-021-kr',
      manufacturerId: 'm-kia',
      nameKo: '스포티지',
      nameEn: 'Sportage',
      bodyType: 'SUV',
      availableFuelTypes: ['가솔린', '디젤', '하이브리드'],
      isPopular: false,
      sortOrder: 90),
  VehicleModel(
      id: 'model-kia-025-ev6',
      manufacturerId: 'm-kia',
      nameKo: 'EV6',
      nameEn: 'EV6',
      bodyType: '전기 SUV',
      availableFuelTypes: ['전기차'],
      isPopular: false,
      sortOrder: 130),
  VehicleModel(
      id: 'model-tesla-120-model-3',
      manufacturerId: 'm-tesla',
      nameKo: 'Model 3',
      nameEn: 'Model 3',
      bodyType: '전기 세단',
      availableFuelTypes: ['전기차'],
      isPopular: true,
      sortOrder: 10),
  VehicleModel(
      id: 'model-tesla-121-model-y',
      manufacturerId: 'm-tesla',
      nameKo: 'Model Y',
      nameEn: 'Model Y',
      bodyType: '전기 SUV',
      availableFuelTypes: ['전기차'],
      isPopular: true,
      sortOrder: 20),
  VehicleModel(
      id: 'model-toyota-096-kr',
      manufacturerId: 'm-toyota',
      nameKo: '프리우스',
      nameEn: 'Prius',
      bodyType: '해치백',
      availableFuelTypes: ['하이브리드', '플러그인 하이브리드'],
      isPopular: false,
      sortOrder: 10),
  VehicleModel(
      id: 'model-toyota-097-kr',
      manufacturerId: 'm-toyota',
      nameKo: '캠리',
      nameEn: 'Camry',
      bodyType: '세단',
      availableFuelTypes: ['하이브리드'],
      isPopular: false,
      sortOrder: 20)




];

const _catalogYears = [
          VehicleModelYear(
      id: 'year-hyundai-001-kr-2026',
      modelId: 'model-hyundai-001-kr',
      year: 2026),
  VehicleModelYear(
      id: 'year-hyundai-002-kr-2026',
      modelId: 'model-hyundai-002-kr',
      year: 2026),
  VehicleModelYear(
      id: 'year-hyundai-003-kr-2026',
      modelId: 'model-hyundai-003-kr',
      year: 2026),
  VehicleModelYear(
      id: 'year-hyundai-004-kr-2026',
      modelId: 'model-hyundai-004-kr',
      year: 2026),
  VehicleModelYear(
      id: 'year-hyundai-005-kr-2026',
      modelId: 'model-hyundai-005-kr',
      year: 2026),
  VehicleModelYear(
      id: 'year-hyundai-006-kr-2026',
      modelId: 'model-hyundai-006-kr',
      year: 2026),
  VehicleModelYear(
      id: 'year-hyundai-007-kr-2026',
      modelId: 'model-hyundai-007-kr',
      year: 2026),
  VehicleModelYear(
      id: 'year-hyundai-008-kr-2026',
      modelId: 'model-hyundai-008-kr',
      year: 2026),
  VehicleModelYear(
      id: 'year-hyundai-009-5-2026',
      modelId: 'model-hyundai-009-5',
      year: 2026),
  VehicleModelYear(
      id: 'year-hyundai-010-6-2026',
      modelId: 'model-hyundai-010-6',
      year: 2026),
  VehicleModelYear(
      id: 'year-kia-014-k5-2026',
      modelId: 'model-kia-014-k5',
      year: 2026),
  VehicleModelYear(
      id: 'year-kia-021-kr-2026',
      modelId: 'model-kia-021-kr',
      year: 2026),
  VehicleModelYear(
      id: 'year-kia-025-ev6-2026',
      modelId: 'model-kia-025-ev6',
      year: 2026),
  VehicleModelYear(
      id: 'year-tesla-120-model-3-2026',
      modelId: 'model-tesla-120-model-3',
      year: 2026),
  VehicleModelYear(
      id: 'year-tesla-121-model-y-2026',
      modelId: 'model-tesla-121-model-y',
      year: 2026),
  VehicleModelYear(
      id: 'year-toyota-096-kr-2026',
      modelId: 'model-toyota-096-kr',
      year: 2026),
  VehicleModelYear(
      id: 'year-toyota-097-kr-2026',
      modelId: 'model-toyota-097-kr',
      year: 2026)




];

const _catalogVariants = [
          VehicleVariant(
      id: 'variant-hyundai-avante-2026-gasoline',
      modelYearId: 'year-hyundai-001-kr-2026',
      manufacturerName: '현대',
      modelName: '아반떼',
      year: 2026,
      trimName: '1.6 가솔린',
      engineName: 'Smartstream G1.6',
      fuelType: '가솔린',
      displacementCc: 1598,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: 'IVT',
      officialEfficiency: 15.0,
      efficiencyUnit: 'km/L',
      vehicleClass: '준중형',
      fuelLeague: 'gasoline',
      isVerified: true,
      sortOrder: 10),
  VehicleVariant(
      id: 'variant-hyundai-avante-2026-hybrid',
      modelYearId: 'year-hyundai-001-kr-2026',
      manufacturerName: '현대',
      modelName: '아반떼',
      year: 2026,
      trimName: '1.6 하이브리드',
      engineName: 'Smartstream G1.6 Hybrid',
      fuelType: '하이브리드',
      displacementCc: 1580,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '6단 DCT',
      officialEfficiency: 21.1,
      efficiencyUnit: 'km/L',
      vehicleClass: '준중형',
      fuelLeague: 'hybrid',
      isVerified: true,
      sortOrder: 20),
  VehicleVariant(
      id: 'variant-hyundai-avante-2026-lpi',
      modelYearId: 'year-hyundai-001-kr-2026',
      manufacturerName: '현대',
      modelName: '아반떼',
      year: 2026,
      trimName: '1.6 LPi',
      engineName: 'LPi 1.6',
      fuelType: 'LPG',
      displacementCc: 1591,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동 6단',
      officialEfficiency: 10.5,
      efficiencyUnit: 'km/L',
      vehicleClass: '준중형',
      fuelLeague: 'lpg',
      isVerified: true,
      sortOrder: 30),
  VehicleVariant(
      id: 'variant-hyundai-sonata-2026-20-gasoline',
      modelYearId: 'year-hyundai-002-kr-2026',
      manufacturerName: '현대',
      modelName: '쏘나타',
      year: 2026,
      trimName: '2.0 가솔린',
      engineName: 'Smartstream G2.0',
      fuelType: '가솔린',
      displacementCc: 1999,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동 6단',
      officialEfficiency: 12.6,
      efficiencyUnit: 'km/L',
      vehicleClass: '중형',
      fuelLeague: 'gasoline',
      isVerified: true,
      sortOrder: 10),
  VehicleVariant(
      id: 'variant-hyundai-sonata-2026-16t-gasoline',
      modelYearId: 'year-hyundai-002-kr-2026',
      manufacturerName: '현대',
      modelName: '쏘나타',
      year: 2026,
      trimName: '1.6T 가솔린',
      engineName: 'Smartstream G1.6T',
      fuelType: '가솔린',
      displacementCc: 1598,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동 8단',
      officialEfficiency: 13.5,
      efficiencyUnit: 'km/L',
      vehicleClass: '중형',
      fuelLeague: 'gasoline',
      isVerified: true,
      sortOrder: 11),
  VehicleVariant(
      id: 'variant-hyundai-sonata-2026-20-hybrid',
      modelYearId: 'year-hyundai-002-kr-2026',
      manufacturerName: '현대',
      modelName: '쏘나타',
      year: 2026,
      trimName: '2.0 하이브리드',
      engineName: 'Smartstream G2.0 Hybrid',
      fuelType: '하이브리드',
      displacementCc: 1999,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동 6단',
      officialEfficiency: 19.4,
      efficiencyUnit: 'km/L',
      vehicleClass: '중형',
      fuelLeague: 'hybrid',
      isVerified: true,
      sortOrder: 20),
  VehicleVariant(
      id: 'variant-hyundai-002-kr-2026-lpg',
      modelYearId: 'year-hyundai-002-kr-2026',
      manufacturerName: '현대',
      modelName: '쏘나타',
      year: 2026,
      trimName: '2.0 LPi',
      engineName: '2.0 LPi',
      fuelType: 'LPG',
      displacementCc: 1999,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동',
      officialEfficiency: 8.8,
      efficiencyUnit: 'km/L',
      vehicleClass: '중형',
      fuelLeague: 'lpg',
      isVerified: true,
      sortOrder: 30),
  VehicleVariant(
      id: 'variant-hyundai-grandeur-2026-25-gasoline',
      modelYearId: 'year-hyundai-003-kr-2026',
      manufacturerName: '현대',
      modelName: '그랜저',
      year: 2026,
      trimName: '2.5 가솔린',
      engineName: 'Smartstream G2.5',
      fuelType: '가솔린',
      displacementCc: 2497,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동 8단',
      officialEfficiency: 11.7,
      efficiencyUnit: 'km/L',
      vehicleClass: '대형',
      fuelLeague: 'gasoline',
      isVerified: true,
      sortOrder: 10),
  VehicleVariant(
      id: 'variant-hyundai-grandeur-2026-35-gasoline',
      modelYearId: 'year-hyundai-003-kr-2026',
      manufacturerName: '현대',
      modelName: '그랜저',
      year: 2026,
      trimName: '3.5 가솔린',
      engineName: 'Smartstream G3.5',
      fuelType: '가솔린',
      displacementCc: 3470,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동 8단',
      officialEfficiency: 10.4,
      efficiencyUnit: 'km/L',
      vehicleClass: '대형',
      fuelLeague: 'gasoline',
      isVerified: true,
      sortOrder: 11),
  VehicleVariant(
      id: 'variant-hyundai-grandeur-2026-16t-hybrid',
      modelYearId: 'year-hyundai-003-kr-2026',
      manufacturerName: '현대',
      modelName: '그랜저',
      year: 2026,
      trimName: '1.6T 하이브리드',
      engineName: 'Smartstream G1.6T Hybrid',
      fuelType: '하이브리드',
      displacementCc: 1598,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동 6단',
      officialEfficiency: 18.0,
      efficiencyUnit: 'km/L',
      vehicleClass: '대형',
      fuelLeague: 'hybrid',
      isVerified: true,
      sortOrder: 20),
  VehicleVariant(
      id: 'variant-hyundai-004-kr-2026-gasoline',
      modelYearId: 'year-hyundai-004-kr-2026',
      manufacturerName: '현대',
      modelName: '코나',
      year: 2026,
      trimName: '1.6 가솔린',
      engineName: '1.6 Gasoline',
      fuelType: '가솔린',
      displacementCc: 1598,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동',
      officialEfficiency: 14.3,
      efficiencyUnit: 'km/L',
      vehicleClass: '소형 SUV',
      fuelLeague: 'gasoline',
      isVerified: true,
      sortOrder: 10),
  VehicleVariant(
      id: 'variant-hyundai-004-kr-2026-hybrid',
      modelYearId: 'year-hyundai-004-kr-2026',
      manufacturerName: '현대',
      modelName: '코나',
      year: 2026,
      trimName: '1.6 하이브리드',
      engineName: '1.6 Hybrid',
      fuelType: '하이브리드',
      displacementCc: 1598,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '하이브리드 전용 변속기',
      officialEfficiency: 20.2,
      efficiencyUnit: 'km/L',
      vehicleClass: '소형 SUV',
      fuelLeague: 'hybrid',
      isVerified: true,
      sortOrder: 20),
  VehicleVariant(
      id: 'variant-hyundai-004-kr-2026-electric',
      modelYearId: 'year-hyundai-004-kr-2026',
      manufacturerName: '현대',
      modelName: '코나',
      year: 2026,
      trimName: '코나 일렉트릭',
      engineName: 'Electric Motor',
      fuelType: '전기차',
      displacementCc: null,
      batteryKwh: 64.8,
      drivetrain: '전동 구동',
      transmission: '감속기',
      officialEfficiency: 5.6,
      efficiencyUnit: 'km/kWh',
      vehicleClass: '소형 SUV',
      fuelLeague: 'electric',
      isVerified: true,
      sortOrder: 50),
  VehicleVariant(
      id: 'variant-hyundai-005-kr-2026-gasoline',
      modelYearId: 'year-hyundai-005-kr-2026',
      manufacturerName: '현대',
      modelName: '투싼',
      year: 2026,
      trimName: '2.0 가솔린',
      engineName: '2.0 Gasoline',
      fuelType: '가솔린',
      displacementCc: 1999,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동',
      officialEfficiency: 12.0,
      efficiencyUnit: 'km/L',
      vehicleClass: 'SUV',
      fuelLeague: 'gasoline',
      isVerified: true,
      sortOrder: 10),
  VehicleVariant(
      id: 'variant-hyundai-005-kr-2026-hybrid',
      modelYearId: 'year-hyundai-005-kr-2026',
      manufacturerName: '현대',
      modelName: '투싼',
      year: 2026,
      trimName: '1.6 하이브리드',
      engineName: '1.6 Hybrid',
      fuelType: '하이브리드',
      displacementCc: 1598,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '하이브리드 전용 변속기',
      officialEfficiency: 16.2,
      efficiencyUnit: 'km/L',
      vehicleClass: 'SUV',
      fuelLeague: 'hybrid',
      isVerified: true,
      sortOrder: 20),
  VehicleVariant(
      id: 'variant-hyundai-005-kr-2026-diesel',
      modelYearId: 'year-hyundai-005-kr-2026',
      manufacturerName: '현대',
      modelName: '투싼',
      year: 2026,
      trimName: '2.0 디젤',
      engineName: '2.0 Diesel',
      fuelType: '디젤',
      displacementCc: 1998,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동',
      officialEfficiency: 15.2,
      efficiencyUnit: 'km/L',
      vehicleClass: 'SUV',
      fuelLeague: 'diesel',
      isVerified: true,
      sortOrder: 40),
  VehicleVariant(
      id: 'variant-hyundai-santafe-2026-25t-gasoline',
      modelYearId: 'year-hyundai-006-kr-2026',
      manufacturerName: '현대',
      modelName: '싼타페',
      year: 2026,
      trimName: '2.5T 가솔린',
      engineName: 'Smartstream G2.5T',
      fuelType: '가솔린',
      displacementCc: 2497,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '8단 DCT',
      officialEfficiency: 11.0,
      efficiencyUnit: 'km/L',
      vehicleClass: 'SUV',
      fuelLeague: 'gasoline',
      isVerified: true,
      sortOrder: 10),
  VehicleVariant(
      id: 'variant-hyundai-santafe-2026-16t-hybrid',
      modelYearId: 'year-hyundai-006-kr-2026',
      manufacturerName: '현대',
      modelName: '싼타페',
      year: 2026,
      trimName: '1.6T 하이브리드',
      engineName: 'Smartstream G1.6T Hybrid',
      fuelType: '하이브리드',
      displacementCc: 1598,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동 6단',
      officialEfficiency: 15.5,
      efficiencyUnit: 'km/L',
      vehicleClass: 'SUV',
      fuelLeague: 'hybrid',
      isVerified: true,
      sortOrder: 20),
  VehicleVariant(
      id: 'variant-hyundai-007-kr-2026-gasoline',
      modelYearId: 'year-hyundai-007-kr-2026',
      manufacturerName: '현대',
      modelName: '팰리세이드',
      year: 2026,
      trimName: '2.5 가솔린',
      engineName: '2.5 Gasoline',
      fuelType: '가솔린',
      displacementCc: 2497,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동',
      officialEfficiency: 9.6,
      efficiencyUnit: 'km/L',
      vehicleClass: '대형 SUV',
      fuelLeague: 'gasoline',
      isVerified: true,
      sortOrder: 10),
  VehicleVariant(
      id: 'variant-hyundai-007-kr-2026-diesel',
      modelYearId: 'year-hyundai-007-kr-2026',
      manufacturerName: '현대',
      modelName: '팰리세이드',
      year: 2026,
      trimName: '2.5 디젤',
      engineName: '2.5 Diesel',
      fuelType: '디젤',
      displacementCc: 2199,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동',
      officialEfficiency: 12.1,
      efficiencyUnit: 'km/L',
      vehicleClass: '대형 SUV',
      fuelLeague: 'diesel',
      isVerified: true,
      sortOrder: 40),
  VehicleVariant(
      id: 'variant-hyundai-casper-2026-10-gasoline',
      modelYearId: 'year-hyundai-008-kr-2026',
      manufacturerName: '현대',
      modelName: '캐스퍼',
      year: 2026,
      trimName: '1.0 가솔린',
      engineName: 'Smartstream G1.0',
      fuelType: '가솔린',
      displacementCc: 998,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동 4단',
      officialEfficiency: 14.3,
      efficiencyUnit: 'km/L',
      vehicleClass: '경형',
      fuelLeague: 'gasoline',
      isVerified: true,
      sortOrder: 10),
  VehicleVariant(
      id: 'variant-hyundai-casper-2026-10t-gasoline',
      modelYearId: 'year-hyundai-008-kr-2026',
      manufacturerName: '현대',
      modelName: '캐스퍼',
      year: 2026,
      trimName: '1.0T 가솔린',
      engineName: 'Kappa 1.0 T-GDI',
      fuelType: '가솔린',
      displacementCc: 998,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동 4단',
      officialEfficiency: 12.8,
      efficiencyUnit: 'km/L',
      vehicleClass: '경형',
      fuelLeague: 'gasoline',
      isVerified: true,
      sortOrder: 11),
  VehicleVariant(
      id: 'variant-hyundai-009-5-2026-electric',
      modelYearId: 'year-hyundai-009-5-2026',
      manufacturerName: '현대',
      modelName: '아이오닉 5',
      year: 2026,
      trimName: '아이오닉 5 스탠다드',
      engineName: 'Electric Motor',
      fuelType: '전기차',
      displacementCc: null,
      batteryKwh: 77.4,
      drivetrain: '전동 구동',
      transmission: '감속기',
      officialEfficiency: 5.2,
      efficiencyUnit: 'km/kWh',
      vehicleClass: 'SUV',
      fuelLeague: 'electric',
      isVerified: true,
      sortOrder: 50),
  VehicleVariant(
      id: 'variant-hyundai-010-6-2026-electric',
      modelYearId: 'year-hyundai-010-6-2026',
      manufacturerName: '현대',
      modelName: '아이오닉 6',
      year: 2026,
      trimName: '아이오닉 6 스탠다드',
      engineName: 'Electric Motor',
      fuelType: '전기차',
      displacementCc: null,
      batteryKwh: 77.4,
      drivetrain: '전동 구동',
      transmission: '감속기',
      officialEfficiency: 6.2,
      efficiencyUnit: 'km/kWh',
      vehicleClass: '중형',
      fuelLeague: 'electric',
      isVerified: true,
      sortOrder: 50),
  VehicleVariant(
      id: 'variant-kia-014-k5-2026-gasoline',
      modelYearId: 'year-kia-014-k5-2026',
      manufacturerName: '기아',
      modelName: 'K5',
      year: 2026,
      trimName: '2.0 가솔린',
      engineName: '2.0 Gasoline',
      fuelType: '가솔린',
      displacementCc: 1999,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동',
      officialEfficiency: 13.0,
      efficiencyUnit: 'km/L',
      vehicleClass: '중형',
      fuelLeague: 'gasoline',
      isVerified: true,
      sortOrder: 10),
  VehicleVariant(
      id: 'variant-kia-014-k5-2026-hybrid',
      modelYearId: 'year-kia-014-k5-2026',
      manufacturerName: '기아',
      modelName: 'K5',
      year: 2026,
      trimName: '1.6 하이브리드',
      engineName: '1.6 Hybrid',
      fuelType: '하이브리드',
      displacementCc: 1598,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '하이브리드 전용 변속기',
      officialEfficiency: 19.5,
      efficiencyUnit: 'km/L',
      vehicleClass: '중형',
      fuelLeague: 'hybrid',
      isVerified: true,
      sortOrder: 20),
  VehicleVariant(
      id: 'variant-kia-014-k5-2026-lpg',
      modelYearId: 'year-kia-014-k5-2026',
      manufacturerName: '기아',
      modelName: 'K5',
      year: 2026,
      trimName: '2.0 LPi',
      engineName: '2.0 LPi',
      fuelType: 'LPG',
      displacementCc: 1999,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동',
      officialEfficiency: 9.0,
      efficiencyUnit: 'km/L',
      vehicleClass: '중형',
      fuelLeague: 'lpg',
      isVerified: true,
      sortOrder: 30),
  VehicleVariant(
      id: 'variant-kia-sportage-2026-16t-gasoline',
      modelYearId: 'year-kia-021-kr-2026',
      manufacturerName: '기아',
      modelName: '스포티지',
      year: 2026,
      trimName: '1.6T 가솔린',
      engineName: 'Smartstream G1.6T',
      fuelType: '가솔린',
      displacementCc: 1598,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동 8단',
      officialEfficiency: 12.5,
      efficiencyUnit: 'km/L',
      vehicleClass: 'SUV',
      fuelLeague: 'gasoline',
      isVerified: true,
      sortOrder: 10),
  VehicleVariant(
      id: 'variant-kia-sportage-2026-16t-hybrid',
      modelYearId: 'year-kia-021-kr-2026',
      manufacturerName: '기아',
      modelName: '스포티지',
      year: 2026,
      trimName: '1.6T 하이브리드',
      engineName: 'Smartstream G1.6T Hybrid',
      fuelType: '하이브리드',
      displacementCc: 1598,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동 6단',
      officialEfficiency: 16.7,
      efficiencyUnit: 'km/L',
      vehicleClass: 'SUV',
      fuelLeague: 'hybrid',
      isVerified: true,
      sortOrder: 20),
  VehicleVariant(
      id: 'variant-kia-sportage-2026-20-diesel',
      modelYearId: 'year-kia-021-kr-2026',
      manufacturerName: '기아',
      modelName: '스포티지',
      year: 2026,
      trimName: '2.0 디젤',
      engineName: 'Smartstream D2.0',
      fuelType: '디젤',
      displacementCc: 1998,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: '자동 8단',
      officialEfficiency: 14.6,
      efficiencyUnit: 'km/L',
      vehicleClass: 'SUV',
      fuelLeague: 'diesel',
      isVerified: true,
      sortOrder: 40),
  VehicleVariant(
      id: 'variant-kia-025-ev6-2026-electric',
      modelYearId: 'year-kia-025-ev6-2026',
      manufacturerName: '기아',
      modelName: 'EV6',
      year: 2026,
      trimName: 'EV6 스탠다드',
      engineName: 'Electric Motor',
      fuelType: '전기차',
      displacementCc: null,
      batteryKwh: 77.4,
      drivetrain: '전동 구동',
      transmission: '감속기',
      officialEfficiency: 5.0,
      efficiencyUnit: 'km/kWh',
      vehicleClass: 'SUV',
      fuelLeague: 'electric',
      isVerified: true,
      sortOrder: 50),
  VehicleVariant(
      id: 'variant-tesla-120-model-3-2026-electric',
      modelYearId: 'year-tesla-120-model-3-2026',
      manufacturerName: '테슬라',
      modelName: 'Model 3',
      year: 2026,
      trimName: '스탠다드 레인지 플러스',
      engineName: 'Electric Motor',
      fuelType: '전기차',
      displacementCc: null,
      batteryKwh: 60.0,
      drivetrain: 'RWD',
      transmission: '감속기',
      officialEfficiency: 6.4,
      efficiencyUnit: 'km/kWh',
      vehicleClass: '중형',
      fuelLeague: 'electric',
      isVerified: true,
      sortOrder: 50),
  VehicleVariant(
      id: 'variant-tesla-121-model-y-2026-electric',
      modelYearId: 'year-tesla-121-model-y-2026',
      manufacturerName: '테슬라',
      modelName: 'Model Y',
      year: 2026,
      trimName: '롱레인지 AWD',
      engineName: 'Electric Motor',
      fuelType: '전기차',
      displacementCc: null,
      batteryKwh: 75.0,
      drivetrain: 'AWD',
      transmission: '감속기',
      officialEfficiency: 5.6,
      efficiencyUnit: 'km/kWh',
      vehicleClass: 'SUV',
      fuelLeague: 'electric',
      isVerified: true,
      sortOrder: 50),
  VehicleVariant(
      id: 'variant-toyota-096-kr-2026-hybrid',
      modelYearId: 'year-toyota-096-kr-2026',
      manufacturerName: '토요타',
      modelName: '프리우스',
      year: 2026,
      trimName: '1.8 하이브리드',
      engineName: '1.6 Hybrid',
      fuelType: '하이브리드',
      displacementCc: 1798,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: 'e-CVT',
      officialEfficiency: 24.5,
      efficiencyUnit: 'km/L',
      vehicleClass: '준중형',
      fuelLeague: 'hybrid',
      isVerified: true,
      sortOrder: 20),
  VehicleVariant(
      id: 'variant-toyota-096-kr-2026-plug_in_hybrid',
      modelYearId: 'year-toyota-096-kr-2026',
      manufacturerName: '토요타',
      modelName: '프리우스',
      year: 2026,
      trimName: '2.0 PHEV',
      engineName: '1.6 PHEV',
      fuelType: '플러그인 하이브리드',
      displacementCc: 1987,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: 'e-CVT',
      officialEfficiency: 26.0,
      efficiencyUnit: 'km/L',
      vehicleClass: '준중형',
      fuelLeague: 'plug_in_hybrid',
      isVerified: true,
      sortOrder: 60),
  VehicleVariant(
      id: 'variant-toyota-097-kr-2026-hybrid',
      modelYearId: 'year-toyota-097-kr-2026',
      manufacturerName: '토요타',
      modelName: '캠리',
      year: 2026,
      trimName: '2.5 하이브리드',
      engineName: '1.6 Hybrid',
      fuelType: '하이브리드',
      displacementCc: 2487,
      batteryKwh: null,
      drivetrain: 'FWD',
      transmission: 'e-CVT',
      officialEfficiency: 19.0,
      efficiencyUnit: 'km/L',
      vehicleClass: '중형',
      fuelLeague: 'hybrid',
      isVerified: true,
      sortOrder: 20)




];

final mockProfile = UserProfile(
  id: 'user-001',
  email: 'driver@fuelarena.net',
  nickname: 'ApexDriver',
  avatarUrl: '',
  tier: 'Gold III',
  totalScore: 128420,
  seasonScore: 2842,
  currentStreak: 5,
  bestStreak: 13,
  representativeVehicleName: '',
  authProvider: 'google',
  isPremium: false,
  isAdmin: true,
);

final mockVehicle = Vehicle(
  id: 'vehicle-001',
  userId: mockProfile.id,
  manufacturer: '현대',
  modelName: '아반떼',
  modelYear: 2024,
  fuelType: '가솔린',
  fuelLeague: 'gasoline',
  vehicleClass: '준중형',
  nickname: '아반떼 가솔린',
  isPrimary: true,
);

UserProfile _mockSignedInProfile = mockProfile;
Vehicle? _mockPrimaryVehicle;
List<UserVehicle> _mockCustomVehicles = [];
List<CustomVehicleReviewRequest> _mockCustomVehicleReviewRequests = [];
AppConsent? _mockAppConsent;
var _mockConsentLogs = <AppConsent>[];

void resetMockFuelArenaState({bool withPrimaryVehicle = false}) {
  _mockSignedInProfile = withPrimaryVehicle
      ? mockProfile.copyWith(
          representativeVehicleId: mockVehicle.id,
          representativeVehicleName: mockVehicle.displayName,
          additionalSetupCompleted: true,
          vehicleSetupCompleted: true,
          selectedFuelLeague: mockVehicle.leagueKey,
          selectedVehicleClass: mockVehicle.vehicleClass,
        )
      : mockProfile;
  _mockPrimaryVehicle = withPrimaryVehicle ? mockVehicle : null;
  _mockCustomVehicles = [];
  _mockCustomVehicleReviewRequests = [];
  _mockAppConsent = null;
  _mockConsentLogs = [];
  _mockNotifications = [...mockNotifications];
  _mockBattles = [...mockBattles];
  _mockSupportTickets = [
    SupportTicket(
      id: 'ticket-001',
      userId: mockProfile.id,
      category: '주행 기록 문제',
      title: '주행 기록 검증 상태 문의',
      description: '검증 대기 상태가 오래 유지되고 있어요.',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];
  _mockSupportMessages = [];
  _mockReports = [];
  _mockPrivacyRequests = [];
  _mockAdminActionLogs = [];
}

const mockDriveScore = DriveScore(
  totalScore: 984,
  efficiencyScore: 93,
  stabilityScore: 88,
  classPercentile: 18,
  accelerationPenalty: -12,
  brakingPenalty: -8,
  idlePenalty: -4,
  distanceBonus: 42,
  consistencyBonus: 31,
  verificationStatus: 'verified',
);

final mockRankings = [
  const RankingEntry(
    userId: 'user-ecoblade',
    rank: 1,
    previousRank: 2,
    nickname: 'EcoBlade',
    tier: 'Diamond I',
    score: 3910,
    vehicleClass: '준중형',
    fuelType: 'Hybrid',
    fuelLeague: 'hybrid',
    isCurrentUser: false,
  ),
  const RankingEntry(
    userId: 'user-bluetorque',
    rank: 2,
    previousRank: 1,
    nickname: 'BlueTorque',
    tier: 'Diamond II',
    score: 3722,
    vehicleClass: '중형',
    fuelType: 'Diesel',
    fuelLeague: 'diesel',
    isCurrentUser: false,
  ),
  const RankingEntry(
    userId: 'user-voltrunner',
    rank: 3,
    previousRank: 5,
    nickname: 'VoltRunner',
    tier: 'Platinum I',
    score: 3512,
    vehicleClass: 'SUV',
    fuelType: 'Electric',
    fuelLeague: 'electric',
    isCurrentUser: false,
  ),
  RankingEntry(
    userId: mockProfile.id,
    rank: 18,
    previousRank: 21,
    nickname: mockProfile.nickname,
    tier: mockProfile.tier,
    score: mockProfile.seasonScore,
    vehicleClass: mockVehicle.vehicleClass,
    fuelType: mockVehicle.fuelType,
    fuelLeague: mockVehicle.leagueKey,
    isCurrentUser: true,
  ),
  const RankingEntry(
    userId: 'user-nightcruise',
    rank: 19,
    previousRank: 17,
    nickname: 'NightCruise',
    tier: 'Gold III',
    score: 2811,
    vehicleClass: '준중형',
    fuelType: 'Gasoline',
    fuelLeague: 'gasoline',
    isCurrentUser: false,
  ),
  ...List.generate(45, (index) {
    final rank = index < 14 ? index + 4 : index + 20;
    final names = [
      'GreenLine',
      'EcoPulse',
      'QuietTorque',
      'FuelBlade',
      'CityRunner'
    ];
    final classes = ['준중형', '중형', 'SUV', '소형', '전기'];
    final fuels = ['Hybrid', 'Gasoline', 'Diesel', 'Electric', 'LPG'];
    return RankingEntry(
      userId: 'user-ranker-${index + 1}',
      rank: rank,
      previousRank: rank + (index.isEven ? 1 : -1),
      nickname: '${names[index % names.length]}${index + 1}',
      tier: rank < 10 ? 'Platinum II' : 'Gold IV',
      score: 2780 - (index * 23),
      vehicleClass: classes[index % classes.length],
      fuelType: fuels[index % fuels.length],
      fuelLeague: FuelLeague.keyForFuelType(fuels[index % fuels.length]),
      isCurrentUser: false,
    );
  }),
];

final mockBattles = [
  Battle(
    id: 'battle-001',
    title: '퇴근길 효율전',
    battleType: '1:1 배틀',
    status: '진행 중',
    ruleType: '최고 효율 점수',
    startAt: DateTime.now().subtract(const Duration(hours: 2)),
    endAt: DateTime.now().add(const Duration(hours: 8)),
    myScore: 984,
    opponentScore: 1008,
    opponentNickname: 'NightCruise',
    rewardSummary: '시즌 XP 120',
    requiredFuelLeague: 'gasoline',
    requiredVehicleClass: '준중형',
  ),
  Battle(
    id: 'battle-002',
    title: '커피 내기 없는 커피런',
    battleType: '공개 매칭',
    status: '모집 중',
    ruleType: '주간 평균 연비',
    startAt: DateTime.now(),
    endAt: DateTime.now().add(const Duration(days: 3)),
    myScore: 0,
    opponentScore: 0,
    opponentNickname: '공개 참가자',
    rewardSummary: '배지 조각 3개',
    requiredFuelLeague: 'gasoline',
    requiredVehicleClass: '준중형',
  ),
  Battle(
    id: 'battle-003',
    title: '크루 점심길 미션',
    battleType: '그룹 배틀',
    status: '추천',
    ruleType: '팀 평균 안정 점수',
    startAt: DateTime.now(),
    endAt: DateTime.now().add(const Duration(days: 1)),
    myScore: 0,
    opponentScore: 0,
    opponentNickname: 'Crew Match',
    rewardSummary: '쿠폰 응모권',
    requiredFuelLeague: 'hybrid',
    requiredVehicleClass: '중형',
    isFriendlyCrossLeague: true,
  ),
  ...List.generate(
    5,
    (index) => Battle(
      id: 'battle-${(index + 4).toString().padLeft(3, '0')}',
      title: [
        '아침 출근 효율전',
        '주말 도심 챌린지',
        '동급 하이브리드전',
        '크루 안정 주행전',
        '퇴근길 재대결'
      ][index],
      battleType: index.isEven ? '공개 매칭' : '1:1 배틀',
      status: index == 4 ? '종료' : '모집 중',
      ruleType: index.isEven ? '최고 효율 점수' : '평균 안정 점수',
      startAt: DateTime.now().subtract(Duration(hours: index)),
      endAt: DateTime.now().add(Duration(days: index + 1)),
      myScore: index == 4 ? 942 : 0,
      opponentScore: index == 4 ? 918 : 0,
      opponentNickname: [
        'EcoPulse',
        'BlueTorque',
        'GreenLine',
        'VoltRunner',
        'NightCruise'
      ][index],
      rewardSummary:
          index.isEven ? '시즌 XP ${80 + index * 20}' : '배지 조각 ${index + 1}개',
      requiredFuelLeague: [
        'gasoline',
        'diesel',
        'hybrid',
        'electric',
        'gasoline'
      ][index],
      requiredVehicleClass: ['준중형', '중형', '준중형', 'SUV', '준중형'][index],
      isFriendlyCrossLeague: index == 3,
    ),
  ),
];

var _mockBattles = [...mockBattles];

final mockSeason = Season(
  id: 'season-001',
  name: 'Neon Efficiency Season',
  currentLeague: 'Gold League',
  seasonScore: 2842,
  promotionTargetScore: 3000,
  endsAt: DateTime.now().add(const Duration(days: 18)),
  rewardProgress: 0.68,
);

final mockMissions = [
  const SeasonMission(
    id: 'mission-001',
    title: '급가속 없이 12km 주행',
    description: '안정 주행 점수를 올리고 시즌 XP를 획득하세요.',
    progress: 8,
    target: 12,
    rewardXp: 120,
    isWeekly: false,
  ),
  const SeasonMission(
    id: 'mission-002',
    title: '동급 상위 20% 3회 달성',
    description: '주간 챌린지 보상으로 한정 배지 조각을 획득합니다.',
    progress: 1,
    target: 3,
    rewardXp: 360,
    isWeekly: true,
  ),
  ...List.generate(
    8,
    (index) => SeasonMission(
      id: 'mission-${(index + 3).toString().padLeft(3, '0')}',
      title: [
        '광고 보상 1회 선택',
        '배틀 참가',
        '15km 이상 주행',
        '급제동 없이 주행',
        '랭킹 확인',
        '쿠폰 챌린지 참가',
        '크루 점수 기여',
        '공정성 기준 확인'
      ][index],
      description: '주행과 경쟁 루프를 따라 시즌 XP를 획득하세요.',
      progress: index % 3,
      target: 3 + index % 4,
      rewardXp: 90 + index * 30,
      isWeekly: index.isOdd,
    ),
  ),
];

const mockRival = Rival(
  id: 'rival-001',
  nickname: 'NightCruise',
  scoreGap: 24,
  message: '라이벌이 앞서가고 있어요',
);

final mockSponsorChallenge = SponsorChallenge(
  id: 'sponsor-001',
  sponsorName: 'Charge Lab',
  title: '도심 효율 챌린지',
  description: '오늘 15km 이상 주행하고 동급 대비 상위 30% 안에 들어보세요.',
  rewardSummary: '쿠폰 응모권 1장',
  endsAt: DateTime.now().add(const Duration(days: 2)),
);

final mockSponsorChallenges = [
  mockSponsorChallenge,
  ...List.generate(
    4,
    (index) => SponsorChallenge(
      id: 'sponsor-${(index + 2).toString().padLeft(3, '0')}',
      sponsorName: ['Clean Bay', 'Fuel Mate', 'Eco Tire', 'Drive Cafe'][index],
      title: ['세차 쿠폰 챌린지', '연비 상위권 보너스', '타이어 점검 미션', '퇴근길 커피 리워드'][index],
      description: '검증된 주행과 동급 대비 성과를 달성하면 쿠폰 응모권을 지급합니다.',
      rewardSummary: '쿠폰 응모권 ${index + 1}장',
      endsAt: DateTime.now().add(Duration(days: index + 3)),
    ),
  ),
];

final mockBadges = <Badge>[
  const Badge(
    id: 'badge-001',
    name: '연비 검투사',
    description: '첫 배틀 승리',
    rarity: 'Rare',
  ),
  const Badge(
    id: 'badge-002',
    name: '정속 장인',
    description: '안정 점수 90점 이상',
    rarity: 'Epic',
  ),
  const Badge(
    id: 'badge-003',
    name: '시즌 질주',
    description: '7일 연속 주행',
    rarity: 'Gold',
  ),
  ...List.generate(
    17,
    (index) => Badge(
      id: 'badge-${(index + 4).toString().padLeft(3, '0')}',
      name: ['추월자', '효율 장인', '안전 모드', '도심 챔피언'][index % 4],
      description: 'Fuel Arena 경쟁 루프에서 획득하는 배지입니다.',
      rarity: ['Common', 'Rare', 'Epic', 'Gold'][index % 4],
    ),
  ),
];

final mockAchievements = <Achievement>[
  const Achievement(
    id: 'achievement-001',
    title: '첫 검증 완료',
    description: '검증된 주행 기록 1회 달성',
    progress: 1,
    target: 1,
  ),
  const Achievement(
    id: 'achievement-002',
    title: '라이벌 추월',
    description: '라이벌 순위 10회 추월',
    progress: 4,
    target: 10,
  ),
  ...List.generate(
    13,
    (index) => Achievement(
      id: 'achievement-${(index + 3).toString().padLeft(3, '0')}',
      title: ['주행 루틴', '배틀 루틴', '미션 루틴', '보상 루틴'][index % 4],
      description: '실제 앱 흐름을 반복하며 성장하는 업적입니다.',
      progress: index + 1,
      target: 10 + index,
    ),
  ),
];

const mockAds = [
  Advertisement(
    id: 'ad-001',
    placement: 'drive_result',
    rewardType: 'season_xp_double',
    label: '광고 보고 시즌 XP 2배 받기',
  ),
];

const mockPlans = [
  SubscriptionPlan(
    id: 'premium-monthly',
    planType: 'monthly',
    name: 'Fuel Arena 프리미엄',
    priceLabel: '월 4,900원',
    benefits: [
      '광고 제거',
      '고급 통계',
      '라이벌 분석',
      '동급 차량 상세 비교',
      '시즌패스 추가 보상',
    ],
    productId: 'fuel_arena_premium_monthly',
    isRecommended: true,
  ),
  SubscriptionPlan(
    id: 'premium-yearly',
    planType: 'yearly',
    name: 'Fuel Arena 프리미엄 연간',
    priceLabel: '연 49,000원',
    benefits: [
      '월간 대비 할인',
      '광고 제거',
      '고급 통계',
      '라이벌 분석',
      '시즌 추가 보상',
    ],
    productId: 'fuel_arena_premium_yearly',
    isRecommended: false,
  ),
  SubscriptionPlan(
    id: 'season-pass',
    planType: 'season_pass',
    name: 'Fuel Arena 시즌패스',
    priceLabel: '시즌 9,900원',
    benefits: [
      '시즌 미션 추가 보상',
      '시즌 전용 보너스',
      '보상 지갑 추가 슬롯',
      '랭킹 도전 보상',
    ],
    productId: 'fuel_arena_season_pass',
    isRecommended: false,
  ),
  SubscriptionPlan(
    id: 'premium-bundle',
    planType: 'bundle',
    name: 'Fuel Arena 프리미엄 번들',
    priceLabel: '번들 14,900원',
    benefits: [
      '프리미엄 혜택',
      '시즌패스 혜택',
      '라이벌 분석',
      '광고 제거',
    ],
    productId: 'fuel_arena_premium_bundle',
    isRecommended: false,
  ),
];

final mockGarage = [
  mockVehicle,
  Vehicle(
    id: 'vehicle-002',
    userId: mockProfile.id,
    manufacturer: 'Kia',
    modelName: 'K5',
    modelYear: 2023,
    fuelType: 'Gasoline',
    fuelLeague: 'gasoline',
    vehicleClass: '중형',
    nickname: '고속 안정형',
    isPrimary: false,
  ),
  Vehicle(
    id: 'vehicle-003',
    userId: mockProfile.id,
    manufacturer: 'Hyundai',
    modelName: 'Ioniq 5',
    modelYear: 2024,
    fuelType: 'Electric',
    fuelLeague: 'electric',
    vehicleClass: '전기',
    nickname: '전기 질주',
    isPrimary: false,
  ),
  Vehicle(
    id: 'vehicle-004',
    userId: mockProfile.id,
    manufacturer: 'Kia',
    modelName: 'Sportage',
    modelYear: 2022,
    fuelType: 'Hybrid',
    fuelLeague: 'hybrid',
    vehicleClass: 'SUV',
    nickname: '패밀리 아레나',
    isPrimary: false,
  ),
  Vehicle(
    id: 'vehicle-005',
    userId: mockProfile.id,
    manufacturer: 'Toyota',
    modelName: 'Prius',
    modelYear: 2023,
    fuelType: 'Hybrid',
    fuelLeague: 'hybrid',
    vehicleClass: '준중형',
    nickname: '효율의 정석',
    isPrimary: false,
  ),
];

final mockDriveSessions = List.generate(
  20,
  (index) => DriveSession(
    id: 'drive-${(index + 1).toString().padLeft(3, '0')}',
    userId: mockProfile.id,
    vehicleId: mockVehicle.id,
    startedAt:
        DateTime.now().subtract(Duration(days: index, minutes: index * 7)),
    endedAt: DateTime.now()
        .subtract(Duration(days: index))
        .add(const Duration(minutes: 38)),
    duration: Duration(minutes: 24 + index),
    distanceKm: 12.4 + index,
    fuelUsedLiters: 0.8 + index * 0.04,
    averageFuelEfficiency: 16.2 + (index % 5),
    status: index % 6 == 0 ? 'pending_review' : 'verified',
  ),
);

final mockDriveScores = List.generate(
  20,
  (index) => DriveScore(
    id: 'score-${(index + 1).toString().padLeft(3, '0')}',
    driveSessionId: 'drive-${(index + 1).toString().padLeft(3, '0')}',
    userId: mockProfile.id,
    totalScore: 880 + index * 7,
    efficiencyScore: 82 + index % 12,
    stabilityScore: 78 + index % 16,
    classPercentile: 18 + index % 20,
    fuelEfficiencyScore: 84 + index % 10,
    accelerationPenalty: -8 - index % 6,
    brakingPenalty: -5 - index % 5,
    idlePenalty: -2 - index % 4,
    distanceBonus: 24 + index,
    consistencyBonus: 18 + index % 9,
    verificationStatus: index % 6 == 0 ? 'pending_review' : 'verified',
  ),
);

final mockCoupons = List.generate(
  10,
  (index) => Coupon(
    id: 'coupon-${(index + 1).toString().padLeft(3, '0')}',
    title: ['세차 쿠폰 응모권', '커피 리워드', '충전 포인트', '정비 할인'][index % 4],
    description: '스폰서 챌린지 완료 보상입니다.',
    expiresAt: DateTime.now().add(Duration(days: 7 + index)),
  ),
);

final mockNotifications = List.generate(
  15,
  (index) => NotificationItem(
    id: 'notification-${(index + 1).toString().padLeft(3, '0')}',
    title: ['랭킹 추월', '배틀 결과', '시즌 보상', '공정성 검증', '쿠폰 만료'][index % 5],
    body: [
      '오늘 3명을 추월했어요.',
      '퇴근길 효율전 결과가 확정됐어요.',
      '시즌 XP 보상이 도착했어요.',
      '검증 완료 후 랭킹에 반영됩니다.',
      '세차 쿠폰이 곧 만료됩니다.'
    ][index % 5],
    createdAt: DateTime.now().subtract(Duration(hours: index + 1)),
    isRead: index.isEven,
    notificationType: [
      'ranking_overtaken',
      'battle_result',
      'season_reward',
      'drive_verified',
      'coupon_expiring'
    ][index % 5],
    targetRoute: [
      '/home?tab=ranking',
      '/battle/result/battle-001',
      '/season/pass',
      '/fairness',
      '/rewards'
    ][index % 5],
    heldDuringDrive: index % 6 == 0,
  ),
);

var _mockNotifications = [...mockNotifications];

var _mockSupportTickets = <SupportTicket>[
  SupportTicket(
    id: 'ticket-001',
    userId: mockProfile.id,
    category: '주행 기록 문제',
    title: '주행 기록 검증 상태 문의',
    description: '검증 대기 상태가 오래 유지되고 있어요.',
    status: 'open',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
];

var _mockSupportMessages = <SupportTicketMessage>[];

var _mockReports = <ReportItem>[];

var _mockPrivacyRequests = <PrivacyRequest>[];

var _mockAdminActionLogs = <AdminActionLog>[];

const mockCrewMembers = [
  CrewMember(
      crewId: 'crew-001',
      userId: 'user-001',
      nickname: 'ApexDriver',
      role: 'owner',
      weeklyContribution: 2842),
  CrewMember(
      crewId: 'crew-001',
      userId: 'user-002',
      nickname: 'NightCruise',
      role: 'member',
      weeklyContribution: 2811),
  CrewMember(
      crewId: 'crew-001',
      userId: 'user-003',
      nickname: 'EcoBlade',
      role: 'member',
      weeklyContribution: 3910),
  CrewMember(
      crewId: 'crew-001',
      userId: 'user-004',
      nickname: 'BlueTorque',
      role: 'member',
      weeklyContribution: 3722),
  CrewMember(
      crewId: 'crew-001',
      userId: 'user-005',
      nickname: 'VoltRunner',
      role: 'member',
      weeklyContribution: 3512),
  CrewMember(
      crewId: 'crew-001',
      userId: 'user-006',
      nickname: 'GreenLine',
      role: 'member',
      weeklyContribution: 2660),
  CrewMember(
      crewId: 'crew-001',
      userId: 'user-007',
      nickname: 'EcoPulse',
      role: 'member',
      weeklyContribution: 2544),
  CrewMember(
      crewId: 'crew-001',
      userId: 'user-008',
      nickname: 'FuelBlade',
      role: 'member',
      weeklyContribution: 2491),
];

const mockAdminMetrics = [
  AdminMetric(id: 'dau', label: 'DAU', value: '12.4', unit: 'K'),
  AdminMetric(id: 'mau', label: 'MAU', value: '118', unit: 'K'),
  AdminMetric(id: 'drives', label: '총 주행 수', value: '482', unit: 'K'),
  AdminMetric(id: 'completion', label: '평균 주행 완료율', value: '87', unit: '%'),
  AdminMetric(id: 'battles', label: '배틀 생성 수', value: '18.2', unit: 'K'),
  AdminMetric(id: 'season', label: '시즌 참여율', value: '72', unit: '%'),
  AdminMetric(id: 'ranking', label: '랭킹 참여율', value: '81', unit: '%'),
  AdminMetric(id: 'ad_view', label: '광고 시청률', value: '34', unit: '%'),
  AdminMetric(id: 'ad_complete', label: '광고 완료율', value: '92', unit: '%'),
  AdminMetric(id: 'premium', label: '프리미엄 전환율', value: '6.8', unit: '%'),
  AdminMetric(id: 'season_pass', label: '시즌패스 구매율', value: '4.1', unit: '%'),
  AdminMetric(
      id: 'coupon_download', label: '쿠폰 다운로드 수', value: '9.4', unit: 'K'),
  AdminMetric(id: 'coupon_use', label: '쿠폰 사용률', value: '38', unit: '%'),
  AdminMetric(id: 'sponsor', label: '스폰서 챌린지 참여율', value: '21', unit: '%'),
  AdminMetric(id: 'privacy', label: '개인정보 요청', value: '7', unit: '건'),
  AdminMetric(
      id: 'fraud',
      label: '부정 기록 감지 수',
      value: '128',
      unit: '건',
      healthy: false),
  AdminMetric(id: 'reports', label: '신고 처리율', value: '94', unit: '%'),
];
