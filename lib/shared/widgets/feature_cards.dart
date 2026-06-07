import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_typography.dart';
import '../models/fuel_arena_models.dart';
import 'buttons.dart';
import 'status_widgets.dart';

class BattleCard extends StatelessWidget {
  const BattleCard({
    super.key,
    required this.battle,
    this.onTap,
  });

  final Battle battle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fuelLeague = battle.requiredFuelLeague;
    final vehicleClass = battle.requiredVehicleClass;
    return AppCard(
      glowColor: AppColors.neonGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(battle.title, style: AppTypography.titleMedium),
              ),
              StatusChip(label: battle.status, color: AppColors.neonGreen),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${battle.battleType} · ${battle.ruleType}',
              style: AppTypography.dataUnit),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              StatusChip(
                label: fuelLeague == null || fuelLeague.isEmpty
                    ? '리그 공개'
                    : FuelLeague.nameForKey(fuelLeague),
                color: AppColors.neonGreen,
              ),
              if (vehicleClass != null && vehicleClass.isNotEmpty)
                StatusChip(label: vehicleClass, color: AppColors.electricBlue),
              if (battle.isFriendlyCrossLeague)
                const StatusChip(label: '친선전', color: AppColors.amber),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                  child: _ScoreColumn(label: '내 점수', score: battle.myScore)),
              Text('VS',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.outline)),
              Expanded(
                  child: _ScoreColumn(
                      label: battle.opponentNickname,
                      score: battle.opponentScore)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  battle.rewardSummary,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.electricBlueSoft),
                ),
              ),
              if (onTap != null)
                TextButton(
                  onPressed: onTap,
                  child: const Text('도전'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.mission,
    this.onClaimReward,
    this.isClaiming = false,
  });

  final SeasonMission mission;
  final VoidCallback? onClaimReward;
  final bool isClaiming;

  @override
  Widget build(BuildContext context) {
    final value = mission.target == 0 ? 0.0 : mission.progress / mission.target;
    final isComplete = mission.progress >= mission.target;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(mission.title, style: AppTypography.titleMedium)),
              StatusChip(
                label: mission.rewardClaimed
                    ? '보상 완료'
                    : isComplete
                        ? '완료'
                        : mission.isWeekly
                            ? '주간'
                            : '오늘',
                color: mission.rewardClaimed
                    ? AppColors.neonGreen
                    : isComplete
                        ? AppColors.gold
                        : mission.isWeekly
                            ? AppColors.amber
                            : AppColors.electricBlue,
                icon: mission.rewardClaimed
                    ? Icons.check_rounded
                    : isComplete
                        ? Icons.emoji_events_rounded
                        : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(mission.description,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: value.clamp(0.0, 1.0).toDouble(),
            minHeight: 6,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: AppColors.surfaceHighest,
            valueColor: const AlwaysStoppedAnimation(AppColors.neonGreen),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${mission.progress} / ${mission.target}',
                  style: AppTypography.dataUnit),
              Text('+${mission.rewardXp} XP',
                  style: AppTypography.dataUnit
                      .copyWith(color: AppColors.neonGreen)),
            ],
          ),
          if (isComplete &&
              !mission.rewardClaimed &&
              onClaimReward != null) ...[
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: '보상 받기',
              icon: Icons.card_giftcard_rounded,
              onPressed: onClaimReward,
              isLoading: isClaiming,
            ),
          ],
        ],
      ),
    );
  }
}

class SeasonProgressCard extends StatelessWidget {
  const SeasonProgressCard({
    super.key,
    required this.season,
  });

  final Season season;

  @override
  Widget build(BuildContext context) {
    final remain = season.promotionTargetScore - season.seasonScore;
    return AppCard(
      borderColor: AppColors.neonGreen.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(season.name, style: AppTypography.titleMedium)),
              StatusChip(label: season.currentLeague, color: AppColors.gold),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('승급까지 ${remain.clamp(0, 99999)}점',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: season.rewardProgress.clamp(0.0, 1.0).toDouble(),
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: AppColors.surfaceHighest,
            valueColor: const AlwaysStoppedAnimation(AppColors.neonGreen),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${DateFormat('M월 d일').format(season.endsAt)} 시즌 종료',
            style: AppTypography.dataUnit.copyWith(color: AppColors.amber),
          ),
        ],
      ),
    );
  }
}

class RivalAlertCard extends StatelessWidget {
  const RivalAlertCard({
    super.key,
    required this.rival,
  });

  final Rival rival;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.amber.withValues(alpha: 0.28),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: AppColors.amber),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rival.message, style: AppTypography.titleMedium),
                Text('${rival.nickname} · ${rival.scoreGap}점 차이',
                    style: AppTypography.dataUnit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DriveResultCard extends StatelessWidget {
  const DriveResultCard({
    super.key,
    required this.score,
  });

  final DriveScore score;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      glowColor: AppColors.neonGreen,
      child: Column(
        children: [
          Text('이번 주행 점수', style: AppTypography.labelCaps),
          Text(
            NumberFormat.decimalPattern().format(score.totalScore),
            style:
                AppTypography.displayLarge.copyWith(color: AppColors.neonGreen),
          ),
          Text('동급 대비 상위 ${score.classPercentile}%',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.electricBlueSoft)),
        ],
      ),
    );
  }
}

class ScoreBreakdownCard extends StatelessWidget {
  const ScoreBreakdownCard({
    super.key,
    required this.score,
  });

  final DriveScore score;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('점수 분석', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _BreakdownRow(
              label: '효율 점수',
              value: '+${score.efficiencyScore}',
              color: AppColors.neonGreen),
          _BreakdownRow(
              label: '안정 주행',
              value: '+${score.stabilityScore}',
              color: AppColors.electricBlue),
          _BreakdownRow(
              label: '거리 보너스',
              value: '+${score.distanceBonus}',
              color: AppColors.neonGreen),
          _BreakdownRow(
              label: '일관성 보너스',
              value: '+${score.consistencyBonus}',
              color: AppColors.neonGreen),
          _BreakdownRow(
              label: '급가속 패널티',
              value: '${score.accelerationPenalty}',
              color: AppColors.danger),
          _BreakdownRow(
              label: '급제동 패널티',
              value: '${score.brakingPenalty}',
              color: AppColors.danger),
          _BreakdownRow(
              label: '공회전 패널티',
              value: '${score.idlePenalty}',
              color: AppColors.danger),
        ],
      ),
    );
  }
}

class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.title,
    required this.description,
    this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.gold.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(
              label: '보상',
              color: AppColors.gold,
              icon: Icons.card_giftcard_rounded),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(description,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted)),
          if (onTap != null) ...[
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: '기본 보상만 받기', onPressed: onTap),
          ],
        ],
      ),
    );
  }
}

class AdRewardCard extends StatelessWidget {
  const AdRewardCard({
    super.key,
    required this.label,
    required this.onWatch,
    this.claimed = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback onWatch;
  final bool claimed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.electricBlue.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: claimed ? '보상 완료' : '광고 보상',
            color: claimed ? AppColors.neonGreen : AppColors.electricBlue,
            icon: claimed
                ? Icons.check_circle_rounded
                : Icons.play_circle_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            claimed ? '시즌 XP 2배가 적용됐어요' : label,
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '광고를 보지 않아도 기본 보상은 유지됩니다.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: claimed ? '보상 적용 완료' : '광고 보고 보상 받기',
            icon: claimed ? Icons.check_rounded : Icons.play_arrow_rounded,
            isLoading: loading,
            onPressed: claimed ? null : onWatch,
          ),
        ],
      ),
    );
  }
}

class NativeAdCard extends StatelessWidget {
  const NativeAdCard({
    super.key,
    required this.advertisement,
  });

  final Advertisement advertisement;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const StatusChip(label: 'AD', color: AppColors.outline),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child:
                  Text(advertisement.label, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}

class SponsorChallengeCard extends StatelessWidget {
  const SponsorChallengeCard({
    super.key,
    required this.challenge,
  });

  final SponsorChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.electricBlue.withValues(alpha: 0.24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
              label: challenge.sponsorName, color: AppColors.electricBlue),
          const SizedBox(height: AppSpacing.md),
          Text(challenge.title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(challenge.description,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: AppSpacing.md),
          Text(challenge.rewardSummary,
              style: AppTypography.dataUnit.copyWith(color: AppColors.gold)),
        ],
      ),
    );
  }
}

class CouponCard extends StatelessWidget {
  const CouponCard({
    super.key,
    required this.coupon,
  });

  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.gold.withValues(alpha: 0.3),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.confirmation_number_rounded,
            color: AppColors.gold),
        title: Text(coupon.title, style: AppTypography.titleMedium),
        subtitle: Text(coupon.description),
      ),
    );
  }
}

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
  });

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppColors.surfaceGradient,
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: AppColors.neonGreen, size: 36),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle.nickname, style: AppTypography.titleMedium),
                Text(
                  '${vehicle.manufacturer} ${vehicle.modelName}',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.onSurfaceMuted),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusChip(
                        label: '${vehicle.vehicleClass} · ${vehicle.fuelType}',
                        color: AppColors.electricBlue),
                    StatusChip(
                        label: vehicle.leagueDisplayName,
                        color: AppColors.neonGreen),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyModePanel extends StatelessWidget {
  const SafetyModePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.neonGreen.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(
              label: '안전 모드',
              color: AppColors.neonGreen,
              icon: Icons.shield_rounded),
          const SizedBox(height: AppSpacing.md),
          Text('주행 중에는 알림과 광고가 표시되지 않아요', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '광고 없음 · 팝업 없음 · 도전장 없음. 기록과 안전에만 집중합니다.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

class LockedPremiumCard extends StatelessWidget {
  const LockedPremiumCard({
    super.key,
    required this.title,
    required this.description,
    this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.gold.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(
              label: '프리미엄', color: AppColors.gold, icon: Icons.lock_rounded),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(description,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted)),
          if (onTap != null) ...[
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
                label: '프리미엄 시작하기',
                icon: Icons.arrow_forward_rounded,
                onPressed: onTap),
          ],
        ],
      ),
    );
  }
}

class StatMetricCard extends StatelessWidget {
  const StatMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.color = AppColors.neonGreen,
  });

  final String label;
  final String value;
  final String? unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.dataUnit),
          const SizedBox(height: AppSpacing.xs),
          RichText(
            text: TextSpan(
              text: value,
              style: AppTypography.titleLarge.copyWith(color: color),
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: AppTypography.dataUnit
                        .copyWith(color: AppColors.onSurfaceMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  const _ScoreColumn({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTypography.dataUnit, textAlign: TextAlign.center),
        Text(
          score == 0 ? '-' : NumberFormat.decimalPattern().format(score),
          style: AppTypography.titleLarge.copyWith(color: AppColors.neonGreen),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Text(value,
              style: AppTypography.bodyMedium
                  .copyWith(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
