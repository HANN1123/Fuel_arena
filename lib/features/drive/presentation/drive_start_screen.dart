import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class DriveStartScreen extends ConsumerWidget {
  const DriveStartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(driveRepositoryProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '주행 준비', showBack: true),
      child: FutureBuilder<(Vehicle, SeasonMission)>(
        future: Future.wait([
          repository.getRepresentativeVehicle(),
          repository.getTodayMission(),
        ]).then((values) => (values[0] as Vehicle, values[1] as SeasonMission)),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingSkeletonView(lines: 4);
          }
          final (vehicle, mission) = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('오늘의 주행을\n기록할까요?', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
              const SizedBox(height: AppSpacing.sm),
              Text('주행 중에는 광고와 팝업을 완전히 차단합니다.', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: '대표 차량'),
              VehicleCard(vehicle: vehicle),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: '오늘 적용되는 미션'),
              MissionCard(mission: mission),
              const SizedBox(height: AppSpacing.lg),
              const SafetyModePanel(),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: '안전 모드로 주행 시작',
                icon: Icons.shield_rounded,
                onPressed: () => context.go('/drive/safety'),
              ),
            ],
          );
        },
      ),
    );
  }
}
