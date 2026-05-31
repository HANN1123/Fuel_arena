import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_typography.dart';
import '../models/fuel_arena_models.dart';
import 'status_widgets.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      glowColor: AppColors.neonGreen,
      child: Column(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.surfaceHighest,
            child: Icon(Icons.person_rounded, color: AppColors.neonGreen, size: 38),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(profile.nickname, style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          TierBadge(tier: profile.tier),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ProfileMetric(label: '총점', value: NumberFormat.decimalPattern().format(profile.totalScore)),
              _ProfileMetric(label: '최고 연승', value: '${profile.bestStreak}연승'),
              _ProfileMetric(label: '시즌', value: NumberFormat.decimalPattern().format(profile.seasonScore)),
            ],
          ),
        ],
      ),
    );
  }
}

class BadgeGrid extends StatelessWidget {
  const BadgeGrid({
    super.key,
    required this.badges,
  });

  final List<Badge> badges;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final badge = badges[index];
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.military_tech_rounded, color: AppColors.gold),
              const SizedBox(height: AppSpacing.xs),
              Text(badge.name, style: AppTypography.dataUnit, textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }
}

class AchievementTile extends StatelessWidget {
  const AchievementTile({
    super.key,
    required this.achievement,
  });

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final value = achievement.target == 0 ? 0.0 : achievement.progress / achievement.target;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(achievement.title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(achievement.description, style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: value.clamp(0.0, 1.0).toDouble(),
            minHeight: 6,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: AppColors.surfaceHighest,
            valueColor: const AlwaysStoppedAnimation(AppColors.neonGreen),
          ),
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.titleMedium.copyWith(color: AppColors.neonGreen)),
        Text(label, style: AppTypography.dataUnit),
      ],
    );
  }
}
