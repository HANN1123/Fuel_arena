import 'dart:math';

double calculateDistanceKm({
  required double startLatitude,
  required double startLongitude,
  required double endLatitude,
  required double endLongitude,
}) {
  const earthRadiusKm = 6371.0;
  final dLat = _degreesToRadians(endLatitude - startLatitude);
  final dLon = _degreesToRadians(endLongitude - startLongitude);
  final lat1 = _degreesToRadians(startLatitude);
  final lat2 = _degreesToRadians(endLatitude);

  final a = pow(sin(dLat / 2), 2) +
      cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

int calculateDriveScore({
  required double distanceKm,
  required double averageEfficiency,
  required int harshAccelerationCount,
  required int harshBrakingCount,
  required int idleMinutes,
  required double classAverageEfficiency,
}) {
  final efficiencyRatio = classAverageEfficiency <= 0
      ? 1.0
      : averageEfficiency / classAverageEfficiency;
  final efficiencyScore = (efficiencyRatio * 620).clamp(0, 760).round();
  final stabilityScore = (260 -
          harshAccelerationCount * 12 -
          harshBrakingCount * 14 -
          idleMinutes * 3)
      .clamp(0, 260)
      .round();
  final distanceBonus = (distanceKm * 3).clamp(0, 120).round();
  return (efficiencyScore + stabilityScore + distanceBonus).clamp(0, 1000);
}

int calculateRankingChange({
  required int previousRank,
  required int currentRank,
}) {
  return previousRank - currentRank;
}

double calculateMissionProgress({
  required int current,
  required int target,
}) {
  if (target <= 0) {
    return 0;
  }
  return (current / target).clamp(0.0, 1.0);
}

bool canClaimAdReward({
  required int usedToday,
  required int dailyLimit,
  required bool adAvailable,
  required bool premiumUser,
}) {
  if (premiumUser) {
    return true;
  }
  return adAvailable && usedToday < dailyLimit;
}

bool hasPremiumAccess({
  required bool isPremium,
  required DateTime? subscriptionEndsAt,
  DateTime? now,
}) {
  if (!isPremium) {
    return false;
  }
  final reference = now ?? DateTime.now();
  return subscriptionEndsAt == null || subscriptionEndsAt.isAfter(reference);
}

double _degreesToRadians(double degrees) => degrees * pi / 180;

