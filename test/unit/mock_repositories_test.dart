import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_arena/shared/repositories/fuel_arena_repositories.dart';

void main() {
  test('MockAuthRepository supports signup and login', () async {
    final repository = MockAuthRepository();
    final signup = await repository.signUp(
      email: 'new@fuelarena.net',
      password: 'fuelarena!',
      nickname: 'NewDriver',
    );
    expect(signup.nickname, 'NewDriver');

    final login = await repository.loginWithEmail(
      email: 'driver@fuelarena.net',
      password: 'fuelarena!',
    );
    expect(login.id, mockProfile.id);
  });

  test('MockVehicleRepository saves and lists vehicles', () async {
    final repository = MockVehicleRepository();
    final vehicle = await repository.saveVehicle(
      manufacturer: 'Hyundai',
      modelName: 'Avante Hybrid',
      modelYear: 2024,
      fuelType: 'Hybrid',
      vehicleClass: '준중형',
      nickname: '테스트 차량',
    );
    expect(vehicle.nickname, '테스트 차량');
    expect(await repository.getPrimaryVehicle(), isNotNull);
  });

  test('MockDriveRepository finishes with verified score', () async {
    final repository = MockDriveRepository();
    final session = await repository.startDriveSession();
    final score = await repository.finishDriveSession();
    expect(session.status, 'recording');
    expect(score.totalScore, greaterThan(0));
  });

  test('MockAdsRepository returns reward', () async {
    final repository = MockAdsRepository();
    expect(await repository.isRewardAdAvailable(), isTrue);
    final reward = await repository.watchRewardAd();
    expect(reward.claimed, isTrue);
  });
}

