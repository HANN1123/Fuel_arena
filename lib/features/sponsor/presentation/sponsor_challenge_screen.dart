import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class SponsorChallengeScreen extends ConsumerWidget {
  const SponsorChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(sponsorChallengesProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '스폰서 챌린지', showBack: true),
      child: challenges.when(
        loading: () => const LoadingSkeletonView(lines: 3),
        error: (error, stackTrace) => ErrorStateView(
          message: '스폰서 챌린지를 불러오지 못했어요.',
          onRetry: () => ref.invalidate(sponsorChallengesProvider),
        ),
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('선택형 챌린지로\n보상을 노리세요',
                style: AppTypography.displayScore
                    .copyWith(color: AppColors.electricBlue)),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              EmptyStateView(
                title: '참여 가능한 챌린지가 없어요',
                message: '새 챌린지가 열리기 전까지 시즌 미션과 주행 보상으로 XP를 모아보세요.',
                actionLabel: '주행 시작하기',
                onAction: () => context.go('/drive/start'),
              )
            else
              for (final challenge in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: InkWell(
                    onTap: () => context.push('/sponsor/${challenge.id}'),
                    child: SponsorChallengeCard(challenge: challenge),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
