import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final badges = ref.watch(badgesProvider);
    final achievements = ref.watch(achievementsProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.mobileMargin, AppSpacing.md, AppSpacing.mobileMargin, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('프로필', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
            const SizedBox(height: AppSpacing.lg),
            profile.when(
              loading: () => const LoadingSkeletonView(lines: 1),
              error: (error, stackTrace) => const ErrorStateView(message: '프로필을 불러오지 못했어요.'),
              data: (value) => ProfileHeader(profile: value),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: '대표 차량'),
            const AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.directions_car_rounded, color: AppColors.neonGreen),
                title: Text('출퇴근 머신'),
                subtitle: Text('대표 차량 · 프로필 꾸미기 준비 중'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: '대표 배지'),
            badges.when(
              loading: () => const LoadingSkeletonView(lines: 1),
              error: (error, stackTrace) => const ErrorStateView(message: '배지를 불러오지 못했어요.'),
              data: (items) => BadgeGrid(badges: items),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: '업적'),
            achievements.when(
              loading: () => const LoadingSkeletonView(lines: 2),
              error: (error, stackTrace) => const ErrorStateView(message: '업적을 불러오지 못했어요.'),
              data: (items) => Column(
                children: items
                    .map(
                      (achievement) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AchievementTile(achievement: achievement),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
