import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

/// StatsScreen displays detailed driving performance analytics for the user.
///
/// It fetches user performance metrics such as average fuel efficiency,
/// verification run counts, and percentiles relative to their vehicle class.
/// If no driving history is found, it renders an EmptyStateView to guide the
/// user to start their first drive.
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingSkeletonView(lines: 5);
          }
          if (snapshot.hasError) {
            return ErrorStateView(
              message: '통계를 불러오지 못했어요.',
              onRetry: () => ref.invalidate(statsRepositoryProvider),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return EmptyStateView(
              title: '주행 기록이 아직 없어요',
              message: '첫 검증 주행이 끝나면 평균 연비, 검증 주행 수, 동급 백분위가 자동으로 채워집니다.',
              actionLabel: '첫 주행 시작하기',
              onAction: () => context.go('/drive/start'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('숫자로 보는\n나의 주행 스타일',
                  style: AppTypography.displayScore
                      .copyWith(color: AppColors.electricBlue)),
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
                          color: metric.id == 'avg-efficiency'
                              ? AppColors.neonGreen
                              : AppColors.electricBlue,
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
