import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_arena/shared/repositories/fuel_arena_repositories.dart';

void main() {
  test('mock login to vehicle to drive result flow', () async {
    final auth = MockAuthRepository();
    final vehicleRepository = MockVehicleRepository();
    final driveRepository = MockDriveRepository();

    final user = await auth.signUp(
      email: 'flow@fuelarena.net',
      password: 'fuelarena!',
      nickname: 'FlowDriver',
    );
    final vehicle = await vehicleRepository.saveVehicle(
      manufacturer: 'Kia',
      modelName: 'K5',
      modelYear: 2024,
      fuelType: 'Gasoline',
      vehicleClass: '중형',
      nickname: '플로우 차량',
    );
    final session = await driveRepository.startDriveSession();
    final score = await driveRepository.finishDriveSession();

    expect(user.nickname, 'FlowDriver');
    expect(vehicle.isPrimary, isTrue);
    expect(session.status, 'recording');
    expect(score.verificationStatus, 'verified');
  });
}
