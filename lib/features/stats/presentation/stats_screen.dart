import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsRepositoryProvider).getUserStats();
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '고급 통계', showBack: true),
      child: FutureBuilder(
        future: stats,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('숫자로 보는\n나의 주행 스타일', style: AppTypography.displayScore.copyWith(color: AppColors.electricBlue)),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: items
                    .map(
                      (metric) => SizedBox(
                        width: 156,
                        child: StatMetricCard(
                          label: metric.label,
                          value: metric.value,
                          unit: metric.unit,
                          color: metric.id == 'avg-efficiency' ? AppColors.neonGreen : AppColors.electricBlue,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              const LockedPremiumCard(
                title: '라이벌 분석',
                description: '프리미엄에서는 라이벌 대비 강점과 약점을 더 자세히 확인합니다.',
              ),
            ],
          );
        },
      ),
    );
  }
}
