import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_typography.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderColor,
    this.glowColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceLow.withValues(alpha: 0.92),
        borderRadius: AppRadius.card,
        border: Border.all(
            color: borderColor ?? Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.18),
              blurRadius: 22,
              spreadRadius: -6,
            ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.labelCaps
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!,
                style: AppTypography.dataUnit
                    .copyWith(color: AppColors.electricBlue)),
          ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.electricBlue,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.chip,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label, style: AppTypography.dataUnit.copyWith(color: color)),
        ],
      ),
    );
  }
}

class TierBadge extends StatelessWidget {
  const TierBadge({
    super.key,
    required this.tier,
  });

  final String tier;

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: tier.toUpperCase(),
      icon: Icons.military_tech_rounded,
      color: AppColors.gold,
    );
  }
}

class ScoreGauge extends StatelessWidget {
  const ScoreGauge({
    super.key,
    required this.score,
    required this.label,
    this.progress = 0.78,
  });

  final int score;
  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172,
      height: 172,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              strokeWidth: 10,
              backgroundColor: AppColors.surfaceHighest,
              valueColor: const AlwaysStoppedAnimation(AppColors.neonGreen),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                NumberFormat.decimalPattern().format(score),
                style: AppTypography.displayScore
                    .copyWith(color: AppColors.neonGreen),
              ),
              Text(label, style: AppTypography.dataUnit),
            ],
          ),
        ],
      ),
    );
  }
}

class RankingChangeChip extends StatelessWidget {
  const RankingChangeChip({
    super.key,
    required this.rank,
    required this.previousRank,
  });

  final int rank;
  final int previousRank;

  @override
  Widget build(BuildContext context) {
    final diff = previousRank - rank;
    final isUp = diff > 0;
    final isSame = diff == 0;
    final color = isSame
        ? AppColors.outline
        : isUp
            ? AppColors.neonGreen
            : AppColors.danger;
    final label = isSame ? '-' : '${isUp ? '+' : ''}$diff';
    return StatusChip(
      label: label,
      icon: isSame
          ? Icons.remove_rounded
          : isUp
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
      color: color,
    );
  }
}

class VerificationStatusBanner extends StatelessWidget {
  const VerificationStatusBanner({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
    final verified = normalized == 'verified';
    final rejected = normalized == 'rejected' || normalized == 'blocked';
    final color = verified
        ? AppColors.neonGreen
        : rejected
            ? AppColors.danger
            : AppColors.amber;
    final icon = verified
        ? Icons.verified_rounded
        : rejected
            ? Icons.report_problem_rounded
            : Icons.pending_rounded;
    final message = verified
        ? '검증 완료되어 랭킹에 반영됩니다'
        : rejected
            ? '검증 기준을 통과하지 못해 랭킹에는 반영되지 않습니다'
            : '검증 대기 중인 기록입니다';
    return AppCard(
      borderColor: color.withValues(alpha: 0.28),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
