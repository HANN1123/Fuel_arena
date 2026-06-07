import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_arena/shared/repositories/fuel_arena_repositories.dart';

void main() {
  setUp(() {
    resetMockFuelArenaState();
  });

  test('mock Google login to vehicle setup to drive result flow', () async {
    final auth = MockAuthRepository();
    final userVehicleRepository = MockUserVehicleRepository(
        catalogRepository: const MockVehicleCatalogRepository());
    final driveRepository = MockDriveRepository();

    final user = await auth.signInWithGoogle();
    final userVehicle = await userVehicleRepository.addUserVehicleFromVariant(
      'variant-hyundai-avante-2026-gasoline',
      '플로우 차량',
      true,
    );
    final membership =
        await userVehicleRepository.assignLeagueForVehicle(userVehicle.id);
    final session = await driveRepository.startDriveSession();
    final score = await driveRepository.finishDriveSession();

    expect(user.authProvider, 'google');
    expect(userVehicle.isPrimary, isTrue);
    expect(membership.fuelLeague, 'gasoline');
    expect(session.status, 'recording');
    expect(score.verificationStatus, 'verified');
  });
}
