import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class SponsorChallengeScreen extends ConsumerWidget {
  const SponsorChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '스폰서 챌린지', showBack: true),
      child: FutureBuilder<List<SponsorChallenge>>(
        future: ref.watch(sponsorRepositoryProvider).getChallenges(),
        builder: (context, snapshot) {
          final challenges = snapshot.data ?? const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('선택형 챌린지로\n보상을 노리세요', style: AppTypography.displayScore.copyWith(color: AppColors.electricBlue)),
              const SizedBox(height: AppSpacing.lg),
              if (challenges.isEmpty)
                const EmptyStateView(title: '챌린지 준비 중', message: '새로운 스폰서 챌린지가 곧 열립니다.')
              else
                for (final challenge in challenges)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: SponsorChallengeCard(challenge: challenge),
                  ),
            ],
          );
        },
      ),
    );
  }
}
