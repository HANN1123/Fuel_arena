import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class SeasonScreen extends ConsumerWidget {
  const SeasonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(seasonProvider);
    final missions = ref.watch(seasonMissionsProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.mobileMargin, AppSpacing.md, AppSpacing.mobileMargin, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('시즌', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
            const SizedBox(height: AppSpacing.xs),
            Text('승급과 보상을 향해 달리는 시즌 트랙', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
            const SizedBox(height: AppSpacing.lg),
            season.when(
              loading: () => const LoadingSkeletonView(lines: 2),
              error: (error, stackTrace) => const ErrorStateView(message: '시즌 정보를 불러오지 못했어요.'),
              data: (value) => SeasonProgressCard(season: value),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: '일일 미션과 주간 챌린지'),
            missions.when(
              loading: () => const LoadingSkeletonView(lines: 2),
              error: (error, stackTrace) => const ErrorStateView(message: '미션을 불러오지 못했어요.'),
              data: (items) => Column(
                children: items
                    .map(
                      (mission) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: MissionCard(mission: mission),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SectionHeader(title: '시즌패스 보상 트랙'),
            const RewardCard(title: '무료 보상', description: '배지 조각, 시즌 XP, 쿠폰 응모권을 획득하세요.'),
            const SizedBox(height: AppSpacing.md),
            const LockedPremiumCard(
              title: '프리미엄 보상 잠금',
              description: '프리미엄 배지와 시즌패스 추가 보상이 기다리고 있어요.',
            ),
          ],
        ),
      ),
    );
  }
}
