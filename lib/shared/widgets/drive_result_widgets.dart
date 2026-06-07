import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/formatters.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_typography.dart';
import '../models/fuel_arena_models.dart';
import 'buttons.dart';
import 'status_widgets.dart';

class DriveResultHeader extends StatelessWidget {
  const DriveResultHeader({
    super.key,
    required this.score,
    required this.tier,
    required this.promotionLeft,
    required this.status,
  });

  final DriveScore score;
  final String tier;
  final int promotionLeft;
  final String status;

  @override
  Widget build(BuildContext context) {
    final verified = status == 'verified';
    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.neonGreen.withValues(alpha: 0.34),
      glowColor: AppColors.neonGreen,
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.65, -0.85),
                    radius: 1.1,
                    colors: [
                      AppColors.neonGreen.withValues(alpha: 0.16),
                      AppColors.surfaceLow.withValues(alpha: 0.96),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -44,
              top: -44,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.neonGreen.withValues(alpha: 0.14),
                      width: 18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('주행 완료', style: AppTypography.titleLarge),
                      ),
                      Flexible(
                        flex: 0,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: StatusChip(
                            label: verified ? '검증 완료' : '검증 중',
                            icon: verified
                                ? Icons.verified_rounded
                                : Icons.sync_rounded,
                            color: verified
                                ? AppColors.neonGreen
                                : AppColors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('이번 주행 총점', style: AppTypography.labelCaps),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.decimalPattern().format(score.totalScore),
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.neonGreen,
                          fontSize: 64,
                          height: 0.95,
                          shadows: [
                            Shadow(
                              color:
                                  AppColors.neonGreen.withValues(alpha: 0.55),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('PTS',
                            style: AppTypography.dataUnit
                                .copyWith(color: AppColors.neonGreen)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      TierBadge(tier: tier),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '승급까지 ${promotionLeft.clamp(0, 99999)}점',
                          textAlign: TextAlign.right,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.amber),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DriveResultKpiGrid extends StatelessWidget {
  const DriveResultKpiGrid({
    super.key,
    required this.averageEfficiency,
    required this.classPercentile,
    required this.rankingDelta,
    required this.seasonXp,
    required this.distanceKm,
    required this.duration,
    this.fuelLeague = 'gasoline',
  });

  final double averageEfficiency;
  final int classPercentile;
  final int rankingDelta;
  final int seasonXp;
  final double distanceKm;
  final Duration duration;
  final String fuelLeague;

  @override
  Widget build(BuildContext context) {
    const formatter = FuelEfficiencyFormatter();
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactList =
            constraints.maxWidth.isFinite && constraints.maxWidth < 430;
        return GridView.count(
          crossAxisCount: useCompactList ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: useCompactList ? 3.1 : 1.55,
          children: [
            DriveResultKpiTile(
              label: formatter.metricLabelForFuelLeague(fuelLeague),
              value: averageEfficiency.toStringAsFixed(1),
              unit: formatter.unitForFuelLeague(fuelLeague),
              icon: fuelLeague == FuelEfficiencyFormatter.electricLeague
                  ? Icons.electric_car_rounded
                  : Icons.local_gas_station_rounded,
              color: AppColors.neonGreen,
            ),
            DriveResultKpiTile(
              label: '동급 대비',
              value: '상위 $classPercentile',
              unit: '%',
              icon: Icons.speed_rounded,
              color: AppColors.electricBlue,
            ),
            DriveResultKpiTile(
              label: '랭킹 변화',
              value: '+$rankingDelta',
              unit: '위',
              icon: Icons.trending_up_rounded,
              color: AppColors.neonGreen,
            ),
            DriveResultKpiTile(
              label: '시즌 XP',
              value: '+$seasonXp',
              icon: Icons.bolt_rounded,
              color: AppColors.gold,
            ),
            DriveResultKpiTile(
              label: '주행 거리',
              value: distanceKm.toStringAsFixed(1),
              unit: 'km',
              icon: Icons.route_rounded,
              color: AppColors.electricBlueSoft,
            ),
            DriveResultKpiTile(
              label: '주행 시간',
              value: _formatDuration(duration),
              icon: Icons.timer_rounded,
              color: AppColors.amber,
            ),
          ],
        );
      },
    );
  }
}

class DriveResultKpiTile extends StatelessWidget {
  const DriveResultKpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: color.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(label, style: AppTypography.dataUnit)),
            ],
          ),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: RichText(
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
          ),
        ],
      ),
    );
  }
}

class DriveScoreAnalysisCard extends StatelessWidget {
  const DriveScoreAnalysisCard({
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
          const Text('점수 분석', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '좋았던 습관과 다음 주행에서 줄일 손실을 분리해서 보여줍니다.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ScoreLine(
            label: '연비 효율 점수',
            value: score.efficiencyScore,
            maxValue: 100,
            color: AppColors.neonGreen,
          ),
          _ScoreLine(
            label: '안정 주행 점수',
            value: score.stabilityScore,
            maxValue: 100,
            color: AppColors.electricBlue,
          ),
          _ScoreDelta(label: '급가속 패널티', value: score.accelerationPenalty),
          _ScoreDelta(label: '급감속 패널티', value: score.brakingPenalty),
          _ScoreDelta(label: '공회전 패널티', value: score.idlePenalty),
          _ScoreDelta(
              label: '거리 보정', value: score.distanceBonus, positive: true),
          _ScoreDelta(
              label: '일관성 보너스', value: score.consistencyBonus, positive: true),
        ],
      ),
    );
  }
}

class RankingResultCard extends StatelessWidget {
  const RankingResultCard({
    super.key,
    required this.overtakenCount,
    required this.pointsToTopTen,
    required this.rivalName,
    required this.rivalGap,
  });

  final int overtakenCount;
  final int pointsToTopTen;
  final String rivalName;
  final int rivalGap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.neonGreen.withValues(alpha: 0.26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(
              label: '랭킹 변화',
              color: AppColors.neonGreen,
              icon: Icons.leaderboard_rounded),
          const SizedBox(height: AppSpacing.md),
          Text('오늘 $overtakenCount명을 추월했어요', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _InsightRow(
            icon: Icons.flag_rounded,
            label: '상위 10%까지',
            value: '$pointsToTopTen점 남음',
            color: AppColors.amber,
          ),
          _InsightRow(
            icon: Icons.local_fire_department_rounded,
            label: rivalName,
            value: '$rivalGap점 차이',
            color: AppColors.electricBlue,
          ),
        ],
      ),
    );
  }
}

class DriveRewardAdCard extends StatelessWidget {
  const DriveRewardAdCard({
    super.key,
    required this.adAvailable,
    required this.dailyLimit,
    required this.usedToday,
    required this.rewardClaimed,
    required this.loading,
    required this.onWatchAd,
    required this.onClaimBaseReward,
  });

  final bool adAvailable;
  final int dailyLimit;
  final int usedToday;
  final bool rewardClaimed;
  final bool loading;
  final VoidCallback onWatchAd;
  final VoidCallback onClaimBaseReward;

  @override
  Widget build(BuildContext context) {
    final remaining = (dailyLimit - usedToday).clamp(0, dailyLimit);
    final unavailable = !adAvailable || remaining == 0;
    final statusLabel = rewardClaimed
        ? '보상 완료'
        : unavailable
            ? '광고 없음'
            : '광고 보상';
    final statusColor = rewardClaimed
        ? AppColors.neonGreen
        : unavailable
            ? AppColors.outline
            : AppColors.electricBlue;

    return AppCard(
      borderColor: statusColor.withValues(alpha: 0.28),
      glowColor: unavailable ? null : AppColors.electricBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: statusLabel,
            color: statusColor,
            icon: rewardClaimed
                ? Icons.check_circle_rounded
                : Icons.play_circle_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            rewardClaimed
                ? '시즌 XP 2배가 적용됐어요'
                : unavailable
                    ? '지금은 받을 수 있는 광고가 없어요'
                    : '광고 보고 시즌 XP 2배 받기',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            unavailable
                ? '기본 보상은 그대로 지급됩니다. 보상 조건이 맞으면 이 영역에서 다시 받을 수 있어요.'
                : '광고는 선택입니다. 보지 않아도 이번 주행의 기본 보상은 유지됩니다.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: StatusChip(
                  label: '오늘 $usedToday / $dailyLimit회 사용',
                  color: AppColors.outline,
                  icon: Icons.today_rounded,
                ),
              ),
              Text(
                '남은 보상 $remaining회',
                style: AppTypography.dataUnit
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!unavailable && !rewardClaimed)
            PrimaryButton(
              label: '광고 보고 시즌 XP 2배 받기',
              icon: Icons.play_arrow_rounded,
              isLoading: loading,
              onPressed: onWatchAd,
            ),
          if (unavailable || rewardClaimed)
            SecondaryButton(
              label: rewardClaimed ? '보상 적용 완료' : '광고 보상 가능',
              icon: rewardClaimed
                  ? Icons.check_rounded
                  : Icons.hourglass_empty_rounded,
              onPressed: null,
            ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: '기본 보상만 받기',
            icon: Icons.card_giftcard_rounded,
            onPressed: onClaimBaseReward,
          ),
        ],
      ),
    );
  }
}

class ResultStateBanner extends StatelessWidget {
  const ResultStateBanner({
    super.key,
    required this.state,
  });

  final String state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      'calculating' => AppColors.electricBlue,
      'verifying' => AppColors.amber,
      'verified' => AppColors.neonGreen,
      'rewardClaimed' => AppColors.gold,
      'adUnavailable' => AppColors.outline,
      _ => AppColors.electricBlue,
    };
    final label = switch (state) {
      'calculating' => '점수 계산 중',
      'verifying' => '데이터 검증 중',
      'verified' => '검증 완료',
      'rewardClaimed' => '보상 지급 완료',
      'adUnavailable' => '광고 보상 대기',
      _ => '결과 계산 중',
    };

    return AppCard(
      borderColor: color.withValues(alpha: 0.28),
      child: Row(
        children: [
          Icon(Icons.sensors_rounded, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text(label,
                  style: AppTypography.bodyMedium.copyWith(color: color))),
        ],
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = maxValue == 0 ? 0.0 : value / maxValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTypography.bodyMedium)),
              Text('+$value',
                  style: AppTypography.bodyMedium
                      .copyWith(color: color, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0).toDouble(),
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: AppColors.surfaceHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ],
      ),
    );
  }
}

class _ScoreDelta extends StatelessWidget {
  const _ScoreDelta({
    required this.label,
    required this.value,
    this.positive = false,
  });

  final String label;
  final int value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.neonGreen : AppColors.danger;
    final prefix = value > 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
              positive ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
              color: color,
              size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Text(
            '$prefix$value',
            style: AppTypography.bodyMedium
                .copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Text(value,
              style: AppTypography.bodyMedium
                  .copyWith(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (duration.inHours > 0) {
    return '${duration.inHours}:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}
