class UserProfile {
  const UserProfile({
    required this.id,
    this.email = '',
    required this.nickname,
    required this.avatarUrl,
    required this.tier,
    required this.totalScore,
    required this.seasonScore,
    required this.currentStreak,
    required this.bestStreak,
    this.representativeVehicleId = '',
    required this.representativeVehicleName,
    this.authProvider = 'google',
    this.onboardingCompleted = false,
    this.consentCompleted = false,
    this.additionalSetupCompleted = false,
    this.vehicleSetupCompleted = false,
    this.selectedFuelLeague = '',
    this.selectedVehicleClass = '',
    required this.isPremium,
    this.isAdmin = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String nickname;
  final String avatarUrl;
  final String tier;
  final int totalScore;
  final int seasonScore;
  final int currentStreak;
  final int bestStreak;
  final String representativeVehicleId;
  final String representativeVehicleName;
  final String authProvider;
  final bool onboardingCompleted;
  final bool consentCompleted;
  final bool additionalSetupCompleted;
  final bool vehicleSetupCompleted;
  final String selectedFuelLeague;
  final String selectedVehicleClass;
  final bool isPremium;
  final bool isAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: '${json['id'] ?? ''}',
      email: '${json['email'] ?? ''}',
      nickname: '${json['nickname'] ?? 'Driver'}',
      avatarUrl: '${json['avatar_url'] ?? ''}',
      tier: '${json['tier'] ?? 'Bronze III'}',
      totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
      seasonScore: (json['season_score'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      representativeVehicleId: '${json['representative_vehicle_id'] ?? ''}',
      representativeVehicleName: '${json['representative_vehicle_name'] ?? ''}',
      authProvider: '${json['auth_provider'] ?? 'google'}',
      onboardingCompleted: json['onboarding_completed'] == true,
      consentCompleted: json['consent_completed'] == true,
      additionalSetupCompleted: json['additional_setup_completed'] == true,
      vehicleSetupCompleted: json['vehicle_setup_completed'] == true,
      selectedFuelLeague: '${json['selected_fuel_league'] ?? ''}',
      selectedVehicleClass: '${json['selected_vehicle_class'] ?? ''}',
      isPremium: json['is_premium'] == true,
      isAdmin: json['is_admin'] == true,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nickname': nickname,
        'avatar_url': avatarUrl,
        'tier': tier,
        'total_score': totalScore,
        'season_score': seasonScore,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'representative_vehicle_id':
            representativeVehicleId.isEmpty ? null : representativeVehicleId,
        'representative_vehicle_name': representativeVehicleName,
        'auth_provider': authProvider,
        'onboarding_completed': onboardingCompleted,
        'consent_completed': consentCompleted,
        'additional_setup_completed': additionalSetupCompleted,
        'vehicle_setup_completed': vehicleSetupCompleted,
        'selected_fuel_league': selectedFuelLeague,
        'selected_vehicle_class': selectedVehicleClass,
        'is_premium': isPremium,
        'is_admin': isAdmin,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  UserProfile copyWith({
    String? id,
    String? email,
    String? nickname,
    String? avatarUrl,
    String? tier,
    int? totalScore,
    int? seasonScore,
    int? currentStreak,
    int? bestStreak,
    String? representativeVehicleId,
    String? representativeVehicleName,
    String? authProvider,
    bool? onboardingCompleted,
    bool? consentCompleted,
    bool? additionalSetupCompleted,
    bool? vehicleSetupCompleted,
    String? selectedFuelLeague,
    String? selectedVehicleClass,
    bool? isPremium,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tier: tier ?? this.tier,
      totalScore: totalScore ?? this.totalScore,
      seasonScore: seasonScore ?? this.seasonScore,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      representativeVehicleId:
          representativeVehicleId ?? this.representativeVehicleId,
      representativeVehicleName:
          representativeVehicleName ?? this.representativeVehicleName,
      authProvider: authProvider ?? this.authProvider,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      consentCompleted: consentCompleted ?? this.consentCompleted,
      additionalSetupCompleted:
          additionalSetupCompleted ?? this.additionalSetupCompleted,
      vehicleSetupCompleted:
          vehicleSetupCompleted ?? this.vehicleSetupCompleted,
      selectedFuelLeague: selectedFuelLeague ?? this.selectedFuelLeague,
      selectedVehicleClass: selectedVehicleClass ?? this.selectedVehicleClass,
      isPremium: isPremium ?? this.isPremium,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AppConsent {
  const AppConsent({
    required this.userId,
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.locationAccepted,
    required this.personalizedAdsAccepted,
    required this.marketingAccepted,
    required this.updatedAt,
  });

  final String userId;
  final bool termsAccepted;
  final bool privacyAccepted;
  final bool locationAccepted;
  final bool personalizedAdsAccepted;
  final bool marketingAccepted;
  final DateTime updatedAt;

  factory AppConsent.fromJson(Map<String, dynamic> json) {
    return AppConsent(
      userId: '${json['user_id'] ?? ''}',
      termsAccepted: json['terms_accepted'] == true,
      privacyAccepted: json['privacy_accepted'] == true,
      locationAccepted: json['location_accepted'] == true,
      personalizedAdsAccepted: json['personalized_ads_accepted'] == true,
      marketingAccepted: json['marketing_accepted'] == true,
      updatedAt:
          DateTime.tryParse('${json['updated_at'] ?? ''}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'terms_accepted': termsAccepted,
        'privacy_accepted': privacyAccepted,
        'location_accepted': locationAccepted,
        'personalized_ads_accepted': personalizedAdsAccepted,
        'marketing_accepted': marketingAccepted,
        'updated_at': updatedAt.toIso8601String(),
      };

  AppConsent copyWith({
    bool? termsAccepted,
    bool? privacyAccepted,
    bool? locationAccepted,
    bool? personalizedAdsAccepted,
    bool? marketingAccepted,
    DateTime? updatedAt,
  }) {
    return AppConsent(
      userId: userId,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      privacyAccepted: privacyAccepted ?? this.privacyAccepted,
      locationAccepted: locationAccepted ?? this.locationAccepted,
      personalizedAdsAccepted:
          personalizedAdsAccepted ?? this.personalizedAdsAccepted,
      marketingAccepted: marketingAccepted ?? this.marketingAccepted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.userId,
    required this.manufacturer,
    required this.modelName,
    required this.modelYear,
    required this.fuelType,
    this.fuelLeague = '',
    this.displacement,
    required this.vehicleClass,
    required this.nickname,
    this.imageUrl = '',
    required this.isPrimary,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String manufacturer;
  final String modelName;
  final int modelYear;
  final String fuelType;
  final String fuelLeague;
  final int? displacement;
  final String vehicleClass;
  final String nickname;
  final String imageUrl;
  final bool isPrimary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      manufacturer: '${json['manufacturer'] ?? ''}',
      modelName: '${json['model_name'] ?? ''}',
      modelYear: (json['model_year'] as num?)?.toInt() ?? DateTime.now().year,
      fuelType: '${json['fuel_type'] ?? ''}',
      fuelLeague:
          '${json['fuel_league'] ?? FuelLeague.keyForFuelType('${json['fuel_type'] ?? ''}')}',
      displacement: (json['displacement'] as num?)?.toInt(),
      vehicleClass: '${json['vehicle_class'] ?? ''}',
      nickname: '${json['nickname'] ?? ''}',
      imageUrl: '${json['image_url'] ?? ''}',
      isPrimary: json['is_primary'] != false,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'manufacturer': manufacturer,
        'model_name': modelName,
        'model_year': modelYear,
        'fuel_type': fuelType,
        'fuel_league': fuelLeague,
        'displacement': displacement,
        'vehicle_class': vehicleClass,
        'nickname': nickname,
        'image_url': imageUrl,
        'is_primary': isPrimary,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  String get displayName => '$manufacturer $modelName $modelYear';

  String get leagueKey =>
      fuelLeague.isEmpty ? FuelLeague.keyForFuelType(fuelType) : fuelLeague;

  String get leagueName => FuelLeague.nameForKey(leagueKey);

  String get leagueDisplayName =>
      FuelLeague.leagueLabel(leagueKey, vehicleClass);

  Vehicle copyWith({
    String? id,
    String? userId,
    String? manufacturer,
    String? modelName,
    int? modelYear,
    String? fuelType,
    String? fuelLeague,
    int? displacement,
    String? vehicleClass,
    String? nickname,
    String? imageUrl,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      manufacturer: manufacturer ?? this.manufacturer,
      modelName: modelName ?? this.modelName,
      modelYear: modelYear ?? this.modelYear,
      fuelType: fuelType ?? this.fuelType,
      fuelLeague: fuelLeague ?? this.fuelLeague,
      displacement: displacement ?? this.displacement,
      vehicleClass: vehicleClass ?? this.vehicleClass,
      nickname: nickname ?? this.nickname,
      imageUrl: imageUrl ?? this.imageUrl,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FuelLeague {
  const FuelLeague({
    required this.key,
    required this.nameKo,
    required this.description,
    required this.fuelType,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String key;
  final String nameKo;
  final String description;
  final String fuelType;
  final bool isActive;
  final int sortOrder;

  factory FuelLeague.fromJson(Map<String, dynamic> json) {
    return FuelLeague(
      key: '${json['key'] ?? ''}',
      nameKo: '${json['name_ko'] ?? ''}',
      description: '${json['description'] ?? ''}',
      fuelType: '${json['fuel_type'] ?? ''}',
      isActive: json['is_active'] != false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'name_ko': nameKo,
        'description': description,
        'fuel_type': fuelType,
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  static const all = [
    FuelLeague(
        key: 'gasoline',
        nameKo: '가솔린 리그',
        description: '가솔린 차량끼리 경쟁합니다.',
        fuelType: 'gasoline',
        sortOrder: 10),
    FuelLeague(
        key: 'diesel',
        nameKo: '디젤 리그',
        description: '디젤 차량끼리 경쟁합니다.',
        fuelType: 'diesel',
        sortOrder: 20),
    FuelLeague(
        key: 'hybrid',
        nameKo: '하이브리드 리그',
        description: '하이브리드 차량끼리 경쟁합니다.',
        fuelType: 'hybrid',
        sortOrder: 30),
    FuelLeague(
        key: 'electric',
        nameKo: '전기차 리그',
        description: '전기차끼리 경쟁합니다.',
        fuelType: 'electric',
        sortOrder: 40),
    FuelLeague(
        key: 'lpg',
        nameKo: 'LPG 리그',
        description: 'LPG 차량끼리 경쟁합니다.',
        fuelType: 'lpg',
        sortOrder: 50),
    FuelLeague(
        key: 'plug_in_hybrid',
        nameKo: '플러그인 하이브리드 리그',
        description: '플러그인 하이브리드는 별도 리그로 운영합니다.',
        fuelType: 'plug_in_hybrid',
        sortOrder: 60),
    FuelLeague(
        key: 'other',
        nameKo: '기타 리그',
        description: '검증 대기 또는 기타 연료 타입입니다.',
        fuelType: 'other',
        sortOrder: 90),
  ];

  static String keyForFuelType(String fuelType) {
    final normalized =
        fuelType.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    return switch (normalized) {
      'gasoline' || 'gas' || '가솔린' => 'gasoline',
      'diesel' || '디젤' => 'diesel',
      'hybrid' || '하이브리드' => 'hybrid',
      'electric' || 'ev' || '전기' || '전기차' => 'electric',
      'lpg' || 'lpi' || 'lp_i' => 'lpg',
      'phev' ||
      'plug_in_hybrid' ||
      'plugin_hybrid' ||
      '플러그인_하이브리드' =>
        'plug_in_hybrid',
      _ => 'other',
    };
  }

  static String nameForKey(String key) {
    return all
        .firstWhere(
          (league) => league.key == key,
          orElse: () => all.last,
        )
        .nameKo;
  }

  static String leagueLabel(String key, String vehicleClass) {
    final prefix = nameForKey(key).replaceAll(' 리그', '');
    return vehicleClass.isEmpty ? '$prefix 리그' : '$prefix $vehicleClass 리그';
  }
}

class VehicleManufacturer {
  const VehicleManufacturer({
    required this.id,
    required this.nameKo,
    this.nameEn = '',
    this.country = '',
    this.logoUrl = '',
    this.isPopular = false,
    this.sortOrder = 0,
    this.modelCount = 0,
    this.minYear = 0,
    this.maxYear = 0,
  });

  final String id;
  final String nameKo;
  final String nameEn;
  final String country;
  final String logoUrl;
  final bool isPopular;
  final int sortOrder;
  final int modelCount;
  final int minYear;
  final int maxYear;

  factory VehicleManufacturer.fromJson(Map<String, dynamic> json) {
    return VehicleManufacturer(
      id: '${json['id'] ?? ''}',
      nameKo: '${json['name_ko'] ?? ''}',
      nameEn: '${json['name_en'] ?? ''}',
      country: '${json['country'] ?? ''}',
      logoUrl: '${json['logo_url'] ?? ''}',
      isPopular: json['is_popular'] == true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      modelCount: (json['model_count'] as num?)?.toInt() ?? 0,
      minYear: (json['min_year'] as num?)?.toInt() ?? 0,
      maxYear: (json['max_year'] as num?)?.toInt() ?? 0,
    );
  }

  VehicleManufacturer copyWith({
    int? modelCount,
    int? minYear,
    int? maxYear,
  }) {
    return VehicleManufacturer(
      id: id,
      nameKo: nameKo,
      nameEn: nameEn,
      country: country,
      logoUrl: logoUrl,
      isPopular: isPopular,
      sortOrder: sortOrder,
      modelCount: modelCount ?? this.modelCount,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
    );
  }
}

class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.manufacturerId,
    required this.nameKo,
    this.nameEn = '',
    this.bodyType = '',
    this.availableFuelTypes = const [],
    this.isPopular = false,
    this.sortOrder = 0,
  });

  final String id;
  final String manufacturerId;
  final String nameKo;
  final String nameEn;
  final String bodyType;
  final List<String> availableFuelTypes;
  final bool isPopular;
  final int sortOrder;

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: '${json['id'] ?? ''}',
      manufacturerId: '${json['manufacturer_id'] ?? ''}',
      nameKo: '${json['name_ko'] ?? ''}',
      nameEn: '${json['name_en'] ?? ''}',
      bodyType: '${json['body_type'] ?? ''}',
      availableFuelTypes: (json['available_fuel_types'] as List?)
              ?.map((item) => '$item')
              .toList() ??
          const [],
      isPopular: json['is_popular'] == true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class VehicleModelYear {
  const VehicleModelYear({
    required this.id,
    required this.modelId,
    required this.year,
  });

  final String id;
  final String modelId;
  final int year;

  factory VehicleModelYear.fromJson(Map<String, dynamic> json) {
    return VehicleModelYear(
      id: '${json['id'] ?? ''}',
      modelId: '${json['model_id'] ?? ''}',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
    );
  }
}

class VehicleVariant {
  const VehicleVariant({
    required this.id,
    required this.modelYearId,
    required this.manufacturerName,
    required this.modelName,
    required this.year,
    required this.trimName,
    this.engineName = '',
    required this.fuelType,
    this.displacementCc,
    this.batteryKwh,
    this.drivetrain = '',
    this.transmission = '',
    this.officialEfficiency,
    this.efficiencyUnit = '',
    required this.vehicleClass,
    required this.fuelLeague,
    this.isVerified = true,
    this.sortOrder = 0,
    this.sourceStatus = 'unknown',
    this.sourceName,
    this.sourceUrl,
    this.confidenceScore,
  });

  final String id;
  final String modelYearId;
  final String manufacturerName;
  final String modelName;
  final int year;
  final String trimName;
  final String engineName;
  final String fuelType;
  final int? displacementCc;
  final double? batteryKwh;
  final String drivetrain;
  final String transmission;
  final double? officialEfficiency;
  final String efficiencyUnit;
  final String vehicleClass;
  final String fuelLeague;
  final bool isVerified;
  final int sortOrder;
  final String sourceStatus;
  final String? sourceName;
  final String? sourceUrl;
  final double? confidenceScore;

  factory VehicleVariant.fromJson(Map<String, dynamic> json) {
    final isVerifiedVal = json['is_verified'] != false;
    final defaultStatus = isVerifiedVal ? 'verified_official' : 'pending_review';
    return VehicleVariant(
      id: '${json['id'] ?? ''}',
      modelYearId: '${json['model_year_id'] ?? ''}',
      manufacturerName:
          '${json['manufacturer_name'] ?? json['manufacturer'] ?? ''}',
      modelName: '${json['model_name'] ?? ''}',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      trimName: '${json['trim_name'] ?? ''}',
      engineName: '${json['engine_name'] ?? ''}',
      fuelType: '${json['fuel_type'] ?? ''}',
      displacementCc: (json['displacement_cc'] as num?)?.toInt(),
      batteryKwh: (json['battery_kwh'] as num?)?.toDouble(),
      drivetrain: '${json['drivetrain'] ?? ''}',
      transmission: '${json['transmission'] ?? ''}',
      officialEfficiency: (json['official_efficiency'] as num?)?.toDouble(),
      efficiencyUnit: '${json['efficiency_unit'] ?? ''}',
      vehicleClass: '${json['vehicle_class'] ?? ''}',
      fuelLeague:
          '${json['fuel_league'] ?? FuelLeague.keyForFuelType('${json['fuel_type'] ?? ''}')}',
      isVerified: isVerifiedVal,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      sourceStatus: '${json['source_status'] ?? defaultStatus}',
      sourceName: json['source_name'] != null ? '${json['source_name']}' : null,
      sourceUrl: json['source_url'] != null ? '${json['source_url']}' : null,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
    );
  }

  String get displayName => '$manufacturerName $modelName $year $trimName';

  String get breadcrumb =>
      '$manufacturerName > $modelName > $year년식 > $trimName';

  String get fuelTypeLabel =>
      FuelLeague.nameForKey(fuelLeague).replaceAll(' 리그', '');

  String get leagueDisplayName =>
      FuelLeague.leagueLabel(fuelLeague, vehicleClass);

  String get statusLabel {
    if (!isVerified) {
      return '검토 중';
    }
    return officialEfficiency == null ? '카탈로그' : '공식';
  }

  String get resolvedEfficiencyUnit {
    if (efficiencyUnit.isNotEmpty) {
      return efficiencyUnit;
    }
    return fuelLeague == 'electric' ? 'km/kWh' : 'km/L';
  }

  String get specSummary {
    final power = batteryKwh != null
        ? '${batteryKwh!.toStringAsFixed(1)} kWh'
        : displacementCc != null
            ? '${displacementCc}cc'
            : '제원 확인 중';
    final gear = transmission.isEmpty ? '변속기 확인 중' : transmission;
    final engine = engineName.trim();
    final drivetrain = engine.isEmpty ? gear : '$engine · $gear';
    final efficiency = officialEfficiency == null
        ? '공식 효율 정보 준비 중'
        : '${officialEfficiency!.toStringAsFixed(1)} $resolvedEfficiencyUnit';
    return '$power · $drivetrain · $efficiency';
  }
}

class UserVehicle {
  const UserVehicle({
    required this.id,
    required this.userId,
    this.vehicleVariantId = '',
    this.variant,
    this.nickname = '',
    this.isPrimary = false,
    this.verificationStatus = 'verified',
    required this.fuelType,
    required this.fuelLeague,
    required this.vehicleClass,
  });

  final String id;
  final String userId;
  final String vehicleVariantId;
  final VehicleVariant? variant;
  final String nickname;
  final bool isPrimary;
  final String verificationStatus;
  final String fuelType;
  final String fuelLeague;
  final String vehicleClass;

  UserVehicle copyWith({
    String? id,
    String? userId,
    String? vehicleVariantId,
    VehicleVariant? variant,
    String? nickname,
    bool? isPrimary,
    String? verificationStatus,
    String? fuelType,
    String? fuelLeague,
    String? vehicleClass,
  }) {
    return UserVehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleVariantId: vehicleVariantId ?? this.vehicleVariantId,
      variant: variant ?? this.variant,
      nickname: nickname ?? this.nickname,
      isPrimary: isPrimary ?? this.isPrimary,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      fuelType: fuelType ?? this.fuelType,
      fuelLeague: fuelLeague ?? this.fuelLeague,
      vehicleClass: vehicleClass ?? this.vehicleClass,
    );
  }

  Vehicle toVehicle() {
    final selected = variant;
    return Vehicle(
      id: id,
      userId: userId,
      manufacturer: selected?.manufacturerName ?? '',
      modelName: selected?.modelName ?? '',
      modelYear: selected?.year ?? DateTime.now().year,
      fuelType: fuelType,
      fuelLeague: fuelLeague,
      displacement: selected?.displacementCc,
      vehicleClass: vehicleClass,
      nickname: nickname.isEmpty ? selected?.trimName ?? '내 차량' : nickname,
      isPrimary: isPrimary,
    );
  }
}

class CustomVehicleReviewRequest {
  const CustomVehicleReviewRequest({
    required this.id,
    required this.userId,
    required this.userVehicleId,
    required this.manufacturerName,
    required this.modelName,
    required this.year,
    required this.trimName,
    required this.fuelType,
    required this.fuelLeague,
    required this.vehicleClass,
    required this.memo,
    required this.status,
    this.reviewNote = '',
    this.reviewedBy = '',
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String userVehicleId;
  final String manufacturerName;
  final String modelName;
  final int year;
  final String trimName;
  final String fuelType;
  final String fuelLeague;
  final String vehicleClass;
  final String memo;
  final String status;
  final String reviewNote;
  final String reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName =>
      '$manufacturerName $modelName $year년식 $trimName'.trim();

  CustomVehicleReviewRequest copyWith({
    String? status,
    String? reviewNote,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? updatedAt,
  }) {
    return CustomVehicleReviewRequest(
      id: id,
      userId: userId,
      userVehicleId: userVehicleId,
      manufacturerName: manufacturerName,
      modelName: modelName,
      year: year,
      trimName: trimName,
      fuelType: fuelType,
      fuelLeague: fuelLeague,
      vehicleClass: vehicleClass,
      memo: memo,
      status: status ?? this.status,
      reviewNote: reviewNote ?? this.reviewNote,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LeagueMembership {
  const LeagueMembership({
    required this.id,
    required this.userId,
    required this.userVehicleId,
    required this.fuelLeague,
    required this.vehicleClass,
    this.seasonId = '',
    this.isActive = true,
  });

  final String id;
  final String userId;
  final String userVehicleId;
  final String fuelLeague;
  final String vehicleClass;
  final String seasonId;
  final bool isActive;
}

enum VehicleSelectionStep {
  manufacturer,
  model,
  year,
  variant,
  confirm,
}

class VehicleSelectionState {
  const VehicleSelectionState({
    this.selectedManufacturer,
    this.selectedModel,
    this.selectedYear,
    this.selectedModelRangeLabel = '',
    this.selectedVariant,
    this.nickname = '',
    this.isPrimary = true,
    this.currentStep = VehicleSelectionStep.manufacturer,
  });

  final VehicleManufacturer? selectedManufacturer;
  final VehicleModel? selectedModel;
  final VehicleModelYear? selectedYear;
  final String selectedModelRangeLabel;
  final VehicleVariant? selectedVariant;
  final String nickname;
  final bool isPrimary;
  final VehicleSelectionStep currentStep;

  String get selectedModelRangeDisplay {
    if (selectedModelRangeLabel.isNotEmpty) {
      return selectedModelRangeLabel;
    }
    return selectedYear == null ? '' : '${selectedYear!.year}년식';
  }

  String get breadcrumb {
    final parts = [
      selectedManufacturer?.nameKo,
      selectedModel?.nameKo,
      if (selectedYear != null) selectedModelRangeDisplay,
      selectedVariant?.trimName,
    ].whereType<String>().where((value) => value.isNotEmpty);
    return parts.join(' > ');
  }

  VehicleSelectionState copyWith({
    VehicleManufacturer? selectedManufacturer,
    VehicleModel? selectedModel,
    VehicleModelYear? selectedYear,
    String? selectedModelRangeLabel,
    VehicleVariant? selectedVariant,
    String? nickname,
    bool? isPrimary,
    VehicleSelectionStep? currentStep,
    bool clearModel = false,
    bool clearYear = false,
    bool clearVariant = false,
  }) {
    return VehicleSelectionState(
      selectedManufacturer: selectedManufacturer ?? this.selectedManufacturer,
      selectedModel: clearModel ? null : selectedModel ?? this.selectedModel,
      selectedYear: clearYear ? null : selectedYear ?? this.selectedYear,
      selectedModelRangeLabel: clearYear
          ? ''
          : selectedModelRangeLabel ?? this.selectedModelRangeLabel,
      selectedVariant:
          clearVariant ? null : selectedVariant ?? this.selectedVariant,
      nickname: nickname ?? this.nickname,
      isPrimary: isPrimary ?? this.isPrimary,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class DriveSession {
  const DriveSession({
    required this.id,
    this.userId = '',
    required this.vehicleId,
    required this.startedAt,
    this.endedAt,
    required this.duration,
    required this.distanceKm,
    this.fuelUsedLiters = 0,
    required this.averageFuelEfficiency,
    this.sourceType = 'local',
    this.driveContext = 'commute',
    required this.status,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String vehicleId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration duration;
  final double distanceKm;
  final double fuelUsedLiters;
  final double averageFuelEfficiency;
  final String sourceType;
  final String driveContext;
  final String status;
  final DateTime? createdAt;

  int get durationSeconds => duration.inSeconds;

  factory DriveSession.fromJson(Map<String, dynamic> json) {
    final durationSeconds = (json['duration_seconds'] as num?)?.toInt() ?? 0;
    return DriveSession(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      vehicleId: '${json['vehicle_id'] ?? ''}',
      startedAt:
          DateTime.tryParse('${json['started_at'] ?? ''}') ?? DateTime.now(),
      endedAt: DateTime.tryParse('${json['ended_at'] ?? ''}'),
      duration: Duration(seconds: durationSeconds),
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      fuelUsedLiters: (json['fuel_used_liters'] as num?)?.toDouble() ?? 0,
      averageFuelEfficiency:
          (json['average_efficiency'] as num?)?.toDouble() ?? 0,
      sourceType: '${json['source_type'] ?? 'local'}',
      driveContext: '${json['drive_context'] ?? 'commute'}',
      status: '${json['status'] ?? 'recording'}',
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'vehicle_id': vehicleId,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'duration_seconds': durationSeconds,
        'distance_km': distanceKm,
        'fuel_used_liters': fuelUsedLiters,
        'average_efficiency': averageFuelEfficiency,
        'source_type': sourceType,
        'drive_context': driveContext,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
      };
}

class DrivePoint {
  const DrivePoint({
    required this.id,
    required this.driveSessionId,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.accuracy,
    required this.recordedAt,
    this.isMocked = false,
  });

  final String id;
  final String driveSessionId;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double accuracy;
  final DateTime recordedAt;
  final bool isMocked;

  factory DrivePoint.fromPrivateJson(Map<String, dynamic> json) {
    return DrivePoint(
      id: '${json['id'] ?? ''}',
      driveSessionId: '${json['drive_session_id'] ?? ''}',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      recordedAt:
          DateTime.tryParse('${json['recorded_at'] ?? ''}') ?? DateTime.now(),
      isMocked: json['is_mocked'] == true,
    );
  }

  Map<String, dynamic> toPrivateJson() => {
        'id': id,
        'drive_session_id': driveSessionId,
        'latitude': latitude,
        'longitude': longitude,
        'speed_kmh': speedKmh,
        'accuracy': accuracy,
        'recorded_at': recordedAt.toIso8601String(),
        'is_mocked': isMocked,
      };

  DrivePoint copyWith({
    String? id,
    String? driveSessionId,
    double? latitude,
    double? longitude,
    double? speedKmh,
    double? accuracy,
    DateTime? recordedAt,
    bool? isMocked,
  }) {
    return DrivePoint(
      id: id ?? this.id,
      driveSessionId: driveSessionId ?? this.driveSessionId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedKmh: speedKmh ?? this.speedKmh,
      accuracy: accuracy ?? this.accuracy,
      recordedAt: recordedAt ?? this.recordedAt,
      isMocked: isMocked ?? this.isMocked,
    );
  }
}

class DriveScore {
  const DriveScore({
    this.id = '',
    this.driveSessionId = '',
    this.userId = '',
    required this.totalScore,
    required this.efficiencyScore,
    required this.stabilityScore,
    required this.classPercentile,
    this.fuelEfficiencyScore = 0,
    required this.accelerationPenalty,
    required this.brakingPenalty,
    required this.idlePenalty,
    required this.distanceBonus,
    required this.consistencyBonus,
    required this.verificationStatus,
    this.createdAt,
  });

  final String id;
  final String driveSessionId;
  final String userId;
  final int totalScore;
  final int efficiencyScore;
  final int stabilityScore;
  final int classPercentile;
  final int fuelEfficiencyScore;
  final int accelerationPenalty;
  final int brakingPenalty;
  final int idlePenalty;
  final int distanceBonus;
  final int consistencyBonus;
  final String verificationStatus;
  final DateTime? createdAt;

  factory DriveScore.fromJson(Map<String, dynamic> json) {
    return DriveScore(
      id: '${json['id'] ?? ''}',
      driveSessionId: '${json['drive_session_id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
      efficiencyScore: (json['efficiency_score'] as num?)?.toInt() ?? 0,
      stabilityScore: (json['stability_score'] as num?)?.toInt() ?? 0,
      classPercentile: (json['class_percentile'] as num?)?.toInt() ?? 0,
      fuelEfficiencyScore:
          (json['fuel_efficiency_score'] as num?)?.toInt() ?? 0,
      accelerationPenalty: (json['acceleration_penalty'] as num?)?.toInt() ?? 0,
      brakingPenalty: (json['braking_penalty'] as num?)?.toInt() ?? 0,
      idlePenalty: (json['idle_penalty'] as num?)?.toInt() ?? 0,
      distanceBonus: (json['distance_bonus'] as num?)?.toInt() ?? 0,
      consistencyBonus: (json['consistency_bonus'] as num?)?.toInt() ?? 0,
      verificationStatus: '${json['verification_status'] ?? 'pending_review'}',
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'drive_session_id': driveSessionId,
        'user_id': userId,
        'total_score': totalScore,
        'efficiency_score': efficiencyScore,
        'stability_score': stabilityScore,
        'class_percentile': classPercentile,
        'fuel_efficiency_score': fuelEfficiencyScore,
        'acceleration_penalty': accelerationPenalty,
        'braking_penalty': brakingPenalty,
        'idle_penalty': idlePenalty,
        'distance_bonus': distanceBonus,
        'consistency_bonus': consistencyBonus,
        'verification_status': verificationStatus,
        'created_at': createdAt?.toIso8601String(),
      };
}

class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.previousRank,
    required this.nickname,
    required this.tier,
    required this.score,
    required this.vehicleClass,
    required this.fuelType,
    this.fuelLeague = '',
    this.userId = '',
    required this.isCurrentUser,
  });

  final String userId;
  final int rank;
  final int previousRank;
  final String nickname;
  final String tier;
  final int score;
  final String vehicleClass;
  final String fuelType;
  final String fuelLeague;
  final bool isCurrentUser;

  String get leagueKey =>
      fuelLeague.isEmpty ? FuelLeague.keyForFuelType(fuelType) : fuelLeague;
}

class Battle {
  const Battle({
    required this.id,
    this.createdBy = '',
    required this.title,
    required this.battleType,
    required this.status,
    required this.ruleType,
    required this.startAt,
    required this.endAt,
    this.wagerTemplate = '비금전 보상',
    this.participants = const [],
    required this.myScore,
    required this.opponentScore,
    required this.opponentNickname,
    required this.rewardSummary,
    this.requiredFuelLeague,
    this.requiredVehicleClass,
    this.isFriendlyCrossLeague = false,
    this.createdAt,
  });

  final String id;
  final String createdBy;
  final String title;
  final String battleType;
  final String status;
  final String ruleType;
  final DateTime startAt;
  final DateTime endAt;
  final String wagerTemplate;
  final List<BattleParticipant> participants;
  final int myScore;
  final int opponentScore;
  final String opponentNickname;
  final String rewardSummary;
  final String? requiredFuelLeague;
  final String? requiredVehicleClass;
  final bool isFriendlyCrossLeague;
  final DateTime? createdAt;
}

class BattleParticipant {
  const BattleParticipant({
    required this.userId,
    required this.nickname,
    required this.score,
    required this.result,
  });

  final String userId;
  final String nickname;
  final int score;
  final String result;
}

class Season {
  const Season({
    required this.id,
    required this.name,
    this.description = '',
    this.startAt,
    required this.currentLeague,
    required this.seasonScore,
    required this.promotionTargetScore,
    required this.endsAt,
    this.status = 'active',
    this.theme = 'neon_efficiency',
    required this.rewardProgress,
  });

  final String id;
  final String name;
  final String description;
  final DateTime? startAt;
  final String currentLeague;
  final int seasonScore;
  final int promotionTargetScore;
  final DateTime endsAt;
  final String status;
  final String theme;
  final double rewardProgress;
}

class SeasonMission {
  const SeasonMission({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.rewardXp,
    required this.isWeekly,
    this.rewardClaimed = false,
  });

  final String id;
  final String title;
  final String description;
  final int progress;
  final int target;
  final int rewardXp;
  final bool isWeekly;
  final bool rewardClaimed;
}

class MissionProgress {
  const MissionProgress({
    required this.id,
    required this.userId,
    required this.missionId,
    required this.progress,
    required this.target,
    required this.rewardClaimed,
  });

  final String id;
  final String userId;
  final String missionId;
  final int progress;
  final int target;
  final bool rewardClaimed;
}

class Badge {
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
  });

  final String id;
  final String name;
  final String description;
  final String rarity;
}

class UserBadge {
  const UserBadge({
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    required this.equipped,
  });

  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final bool equipped;
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
  });

  final String id;
  final String title;
  final String description;
  final int progress;
  final int target;
}

class UserAchievement {
  const UserAchievement({
    required this.userId,
    required this.achievementId,
    required this.progress,
    required this.completed,
  });

  final String userId;
  final String achievementId;
  final int progress;
  final bool completed;
}

class Rival {
  const Rival({
    required this.id,
    required this.nickname,
    required this.scoreGap,
    required this.message,
  });

  final String id;
  final String nickname;
  final int scoreGap;
  final String message;
}

class Rivalry {
  const Rivalry({
    required this.id,
    required this.userId,
    required this.rivalUserId,
    required this.scoreGap,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String rivalUserId;
  final int scoreGap;
  final DateTime updatedAt;
}

class Crew {
  const Crew({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.weeklyScore,
  });

  final String id;
  final String name;
  final String description;
  final int memberCount;
  final int weeklyScore;
}

class CrewMember {
  const CrewMember({
    required this.crewId,
    required this.userId,
    required this.nickname,
    required this.role,
    required this.weeklyContribution,
  });

  final String crewId;
  final String userId;
  final String nickname;
  final String role;
  final int weeklyContribution;
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.notificationType = 'general',
    this.targetRoute = '',
    this.heldDuringDrive = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String notificationType;
  final String targetRoute;
  final bool heldDuringDrive;

  NotificationItem copyWith({
    bool? isRead,
    String? targetRoute,
    bool? heldDuringDrive,
  }) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      notificationType: notificationType,
      targetRoute: targetRoute ?? this.targetRoute,
      heldDuringDrive: heldDuringDrive ?? this.heldDuringDrive,
    );
  }
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String category;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket copyWith({
    String? status,
    DateTime? updatedAt,
  }) {
    return SupportTicket(
      id: id,
      userId: userId,
      category: category,
      title: title,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SupportTicketMessage {
  const SupportTicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    this.isAdminReply = false,
  });

  final String id;
  final String ticketId;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final bool isAdminReply;
}

class PrivacyRequestSubmission {
  const PrivacyRequestSubmission({
    required this.requestType,
    required this.description,
  });

  final String requestType;
  final String description;
}

class ActivePrivacyRequestException implements Exception {
  const ActivePrivacyRequestException(this.request);

  final PrivacyRequest request;

  @override
  String toString() =>
      'ActivePrivacyRequestException(${request.requestType}, ${request.status})';
}

class PrivacyRequest {
  const PrivacyRequest({
    required this.id,
    required this.userId,
    required this.requestType,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String requestType;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrivacyRequest copyWith({
    String? status,
    DateTime? updatedAt,
  }) {
    return PrivacyRequest(
      id: id,
      userId: userId,
      requestType: requestType,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AppSetting {
  const AppSetting({
    required this.key,
    required this.value,
    required this.description,
    required this.isPublic,
    required this.updatedAt,
  });

  final String key;
  final Map<String, dynamic> value;
  final String description;
  final bool isPublic;
  final DateTime updatedAt;
}

class Sponsor {
  const Sponsor({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.description,
    required this.isActive,
  });

  final String id;
  final String name;
  final String logoUrl;
  final String description;
  final bool isActive;
}

class SponsorChallenge {
  const SponsorChallenge({
    required this.id,
    required this.sponsorName,
    required this.title,
    required this.description,
    required this.rewardSummary,
    required this.endsAt,
  });

  final String id;
  final String sponsorName;
  final String title;
  final String description;
  final String rewardSummary;
  final DateTime endsAt;
}

class Advertisement {
  const Advertisement({
    required this.id,
    this.adType = 'native',
    required this.placement,
    this.title = '',
    this.description = '',
    this.sponsorId = '',
    this.imageUrl = '',
    this.ctaLabel = '',
    this.isActive = true,
    this.startsAt,
    this.endsAt,
    required this.rewardType,
    required this.label,
  });

  final String id;
  final String adType;
  final String placement;
  final String title;
  final String description;
  final String sponsorId;
  final String imageUrl;
  final String ctaLabel;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String rewardType;
  final String label;
}

class AdReward {
  const AdReward({
    required this.id,
    required this.title,
    required this.description,
    required this.claimed,
  });

  final String id;
  final String title;
  final String description;
  final bool claimed;
}

class Coupon {
  const Coupon({
    required this.id,
    required this.title,
    required this.description,
    required this.expiresAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime expiresAt;
}

class UserCoupon {
  const UserCoupon({
    required this.id,
    required this.userId,
    required this.couponId,
    required this.status,
    required this.issuedAt,
    this.usedAt,
  });

  final String id;
  final String userId;
  final String couponId;
  final String status;
  final DateTime issuedAt;
  final DateTime? usedAt;
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    this.title = '',
    this.description = '',
    this.planType = 'monthly',
    required this.name,
    required this.priceLabel,
    required this.benefits,
    this.productId = '',
    required this.isRecommended,
  });

  final String id;
  final String title;
  final String description;
  final String planType;
  final String name;
  final String priceLabel;
  final List<String> benefits;
  final String productId;
  final bool isRecommended;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final benefits = json['benefits'];
    return SubscriptionPlan(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      planType: '${json['plan_type'] ?? 'monthly'}',
      name: '${json['title'] ?? json['name'] ?? ''}',
      priceLabel: '${json['price_text'] ?? json['price_label'] ?? ''}',
      benefits: benefits is List
          ? benefits.map((item) => '$item').toList()
          : const <String>[],
      productId: '${json['product_id'] ?? ''}',
      isRecommended: json['is_recommended'] == true ||
          '${json['plan_type'] ?? ''}' == 'monthly',
    );
  }
}

class UserSubscription {
  const UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.startedAt,
    this.renewsAt,
  });

  final String id;
  final String userId;
  final String planId;
  final String status;
  final DateTime startedAt;
  final DateTime? renewsAt;
}

class PurchaseVerificationRequest {
  const PurchaseVerificationRequest({
    required this.provider,
    required this.productId,
    required this.purchaseToken,
    required this.transactionId,
    this.planId = '',
  });

  final String provider;
  final String productId;
  final String purchaseToken;
  final String transactionId;
  final String planId;

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'productId': productId,
        'purchaseToken': purchaseToken,
        'transactionId': transactionId,
        if (planId.isNotEmpty) 'planId': planId,
      };
}

class PurchaseVerificationResult {
  const PurchaseVerificationResult({
    required this.verified,
    required this.premiumActive,
    required this.provider,
    required this.productId,
    this.planId = '',
    this.expiresAt,
  });

  final bool verified;
  final bool premiumActive;
  final String provider;
  final String productId;
  final String planId;
  final DateTime? expiresAt;

  factory PurchaseVerificationResult.fromJson(Map<String, dynamic> json) {
    return PurchaseVerificationResult(
      verified: json['verified'] == true,
      premiumActive: json['premiumActive'] == true,
      provider: '${json['provider'] ?? ''}',
      productId: '${json['productId'] ?? ''}',
      planId: '${json['planId'] ?? ''}',
      expiresAt: DateTime.tryParse('${json['expiresAt'] ?? ''}'),
    );
  }
}

class FraudReview {
  const FraudReview({
    required this.id,
    required this.driveSessionId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String driveSessionId;
  final String reason;
  final String status;
  final DateTime createdAt;
}

class ReportItem {
  const ReportItem({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String reason;
  final String status;
  final DateTime createdAt;

  ReportItem copyWith({String? status}) {
    return ReportItem(
      id: id,
      reporterId: reporterId,
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class ReportRequest {
  const ReportRequest({
    required this.targetType,
    required this.reason,
    this.targetId = '',
  });

  final String targetType;
  final String targetId;
  final String reason;
}

class AdminMetric {
  const AdminMetric({
    required this.id,
    required this.label,
    required this.value,
    this.unit,
    this.healthy = true,
  });

  final String id;
  final String label;
  final String value;
  final String? unit;
  final bool healthy;
}

class AdminRecord {
  const AdminRecord({
    required this.id,
    required this.title,
    required this.status,
    required this.owner,
    this.description = '',
    this.createdAt,
    this.metadata = const {},
  });

  final String id;
  final String title;
  final String status;
  final String owner;
  final String description;
  final DateTime? createdAt;
  final Map<String, String> metadata;
}

class AdminRecordPage {
  const AdminRecordPage({
    required this.section,
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  final String section;
  final List<AdminRecord> items;
  final int page;
  final int pageSize;
  final int totalCount;

  int get totalPages {
    if (totalCount <= 0) {
      return 1;
    }
    return (totalCount / pageSize).ceil();
  }

  bool get hasPrevious => page > 0;
  bool get hasNext => page + 1 < totalPages;
}

class AdminRecordQuery {
  const AdminRecordQuery({
    required this.section,
    this.search = '',
    this.status = '전체',
    this.page = 0,
    this.pageSize = 10,
  });

  final String section;
  final String search;
  final String status;
  final int page;
  final int pageSize;

  AdminRecordQuery copyWith({
    String? section,
    String? search,
    String? status,
    int? page,
    int? pageSize,
  }) {
    return AdminRecordQuery(
      section: section ?? this.section,
      search: search ?? this.search,
      status: status ?? this.status,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminRecordQuery &&
        other.section == section &&
        other.search == search &&
        other.status == status &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(section, search, status, page, pageSize);
}

class AdminActionRequest {
  const AdminActionRequest({
    required this.section,
    required this.action,
    this.record,
  });

  final String section;
  final String action;
  final AdminRecord? record;
}

class AdminActionLog {
  const AdminActionLog({
    required this.id,
    required this.section,
    required this.action,
    required this.adminUserId,
    required this.createdAt,
    this.targetId = '',
    this.targetTitle = '',
    this.targetStatus = '',
  });

  final String id;
  final String section;
  final String action;
  final String adminUserId;
  final String targetId;
  final String targetTitle;
  final String targetStatus;
  final DateTime createdAt;
}

class HomeSnapshot {
  const HomeSnapshot({
    required this.profile,
    this.vehicle,
    required this.activeBattle,
    required this.todayMission,
    required this.season,
    required this.rival,
    required this.latestDriveScore,
    required this.sponsorChallenge,
    this.classRank = 0,
    this.totalRank = 0,
    this.overtakenToday = 0,
  });

  final UserProfile profile;
  final Vehicle? vehicle;
  final Battle activeBattle;
  final SeasonMission todayMission;
  final Season season;
  final Rival rival;
  final DriveScore latestDriveScore;
  final SponsorChallenge sponsorChallenge;
  final int classRank;
  final int totalRank;
  final int overtakenToday;
}

