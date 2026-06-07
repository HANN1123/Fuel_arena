import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_arena/core/utils/fuel_arena_calculations.dart';

void main() {
  test('점수 계산 helper가 효율과 안정 주행을 반영한다', () {
    final score = calculateDriveScore(
      distanceKm: 24,
      averageEfficiency: 18,
      harshAccelerationCount: 1,
      harshBrakingCount: 1,
      idleMinutes: 2,
      classAverageEfficiency: 15,
    );

    expect(score, greaterThan(800));
    expect(score, lessThanOrEqualTo(1000));
  });

  test('거리 계산 helper가 서울 도심 구간 거리를 계산한다', () {
    final distance = calculateDistanceKm(
      startLatitude: 37.5665,
      startLongitude: 126.9780,
      endLatitude: 37.5700,
      endLongitude: 126.9920,
    );

    expect(distance, greaterThan(1));
    expect(distance, lessThan(2));
  });

  test('ranking change 계산은 순위 상승을 양수로 반환한다', () {
    expect(calculateRankingChange(previousRank: 21, currentRank: 18), 3);
  });

  test('mission progress 계산은 0과 1 사이로 제한된다', () {
    expect(
        calculateMissionProgress(current: 8, target: 12), closeTo(0.66, 0.02));
    expect(calculateMissionProgress(current: 20, target: 12), 1);
  });

  test('ad reward limit 계산은 일일 제한과 프리미엄 예외를 반영한다', () {
    expect(
      canClaimAdReward(
        usedToday: 3,
        dailyLimit: 3,
        adAvailable: true,
        premiumUser: false,
      ),
      isFalse,
    );
    expect(
      canClaimAdReward(
        usedToday: 3,
        dailyLimit: 3,
        adAvailable: false,
        premiumUser: true,
      ),
      isTrue,
    );
  });

  test('premium access 계산은 구독 만료일을 확인한다', () {
    final now = DateTime(2026, 6, 5);
    expect(
      hasPremiumAccess(
        isPremium: true,
        subscriptionEndsAt: DateTime(2026, 7, 5),
        now: now,
      ),
      isTrue,
    );
    expect(
      hasPremiumAccess(
        isPremium: true,
        subscriptionEndsAt: DateTime(2026, 5, 5),
        now: now,
      ),
      isFalse,
    );
  });
}
