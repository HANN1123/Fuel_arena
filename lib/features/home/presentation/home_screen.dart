import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(homeSnapshotProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final minContentHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0;
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(homeSnapshotProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.mobileMargin,
              AppSpacing.md,
              AppSpacing.mobileMargin,
              112,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minContentHeight),
              child: snapshot.when(
                loading: () => const LoadingSkeletonView(lines: 6),
                error: (error, stackTrace) => ErrorStateView(
                  message: '홈 데이터를 불러오지 못했어요.',
                  onRetry: () => ref.invalidate(homeSnapshotProvider),
                ),
                data: (data) {
                  final promotionLeft = data.season.promotionTargetScore -
                      data.profile.seasonScore;
                  final vehicle = data.vehicle;
                  if (vehicle == null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${data.profile.nickname}님',
                                      style: AppTypography.titleLarge),
                                  Text('아직 참가 중인 리그가 없어요',
                                      style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.onSurfaceMuted)),
                                ],
                              ),
                            ),
                            TierBadge(tier: data.profile.tier),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppCard(
                          glowColor: AppColors.neonGreen,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const StatusChip(
                                  label: '차량 미설정',
                                  color: AppColors.amber,
                                  icon: Icons.directions_car_rounded),
                              const SizedBox(height: AppSpacing.md),
                              Text('아직 참가 중인 리그가 없어요',
                                  style: AppTypography.titleLarge
                                      .copyWith(color: AppColors.neonGreen)),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '차량을 설정하면 내 연료 리그와 차급에 맞는 경쟁에 배정됩니다.',
                                style: AppTypography.bodyMedium
                                    .copyWith(color: AppColors.onSurfaceMuted),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              PrimaryButton(
                                label: '차량 설정하기',
                                icon: Icons.directions_car_rounded,
                                onPressed: () => context.go('/setup/vehicle'),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SecondaryButton(
                                label: '공정성 기준 보기',
                                icon: Icons.rule_rounded,
                                onPressed: () => context.push('/fairness'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const EmptyStateView(
                          title: '차량 설정이 필요해요',
                          message:
                              '주행 기록, 랭킹, 배틀, 시즌 리그 참여는 대표 차량 설정 후 이용할 수 있어요.',
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${data.profile.nickname}님',
                                    style: AppTypography.titleLarge),
                                Text(vehicle.nickname,
                                    style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.onSurfaceMuted)),
                              ],
                            ),
                          ),
                          TierBadge(tier: data.profile.tier),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        glowColor: AppColors.neonGreen,
                        child: Column(
                          children: [
                            ScoreGauge(
                              score: data.profile.seasonScore,
                              label: '현재 시즌 점수',
                              progress: data.profile.seasonScore /
                                  data.season.promotionTargetScore,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: StatMetricCard(
                                    label: '클래스 내 순위',
                                    value: NumberFormat.decimalPattern()
                                        .format(data.classRank),
                                    unit: '위',
                                    color: AppColors.electricBlue,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: StatMetricCard(
                                    label: '전체 순위',
                                    value: NumberFormat.decimalPattern()
                                        .format(data.totalRank),
                                    unit: '위',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            StatusChip(
                              label: '승급까지 ${promotionLeft.clamp(0, 99999)}점',
                              icon: Icons.arrow_upward_rounded,
                              color: AppColors.amber,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppCard(
                        borderColor:
                            AppColors.neonGreen.withValues(alpha: 0.28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusChip(
                                label: '내 리그: ${vehicle.leagueDisplayName}',
                                color: AppColors.neonGreen),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                                '대표 차량: ${vehicle.displayName} ${vehicle.fuelType}',
                                style: AppTypography.titleMedium),
                            const SizedBox(height: AppSpacing.xs),
                            Text('차급: ${vehicle.vehicleClass}',
                                style: AppTypography.bodyMedium
                                    .copyWith(color: AppColors.onSurfaceMuted)),
                            const SizedBox(height: AppSpacing.xs),
                            Text('같은 연료 리그와 차급의 운전자들과 경쟁합니다.',
                                style: AppTypography.bodyMedium
                                    .copyWith(color: AppColors.onSurfaceMuted)),
                            const SizedBox(height: AppSpacing.md),
                            SecondaryButton(
                              label: '대표 차량 변경',
                              icon: Icons.swap_horiz_rounded,
                              onPressed: () => context.go('/settings/vehicles'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        label: '주행 시작하기',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => context.push('/drive/start'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const SectionHeader(title: '진행 중인 경쟁'),
                      BattleCard(battle: data.activeBattle),
                      const SizedBox(height: AppSpacing.md),
                      MissionCard(mission: data.todayMission),
                      const SizedBox(height: AppSpacing.md),
                      SeasonProgressCard(season: data.season),
                      const SizedBox(height: AppSpacing.md),
                      RivalAlertCard(rival: data.rival),
                      const SizedBox(height: AppSpacing.xl),
                      const SectionHeader(title: '최근 주행 결과'),
                      DriveResultCard(score: data.latestDriveScore),
                      const SizedBox(height: AppSpacing.md),
                      SponsorChallengeCard(challenge: data.sponsorChallenge),
                      const SizedBox(height: AppSpacing.md),
                      LockedPremiumCard(
                        title: '프리미엄으로 광고 없이 보상을 받아보세요',
                        description: '고급 통계, 라이벌 분석, 동급 차량 상세 비교가 열립니다.',
                        onTap: () => context.push('/premium'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '오늘 ${NumberFormat.decimalPattern().format(data.overtakenToday)}명을 추월했어요',
                        style: AppTypography.dataUnit
                            .copyWith(color: AppColors.neonGreen),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
