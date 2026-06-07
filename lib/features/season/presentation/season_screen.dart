import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class SeasonScreen extends ConsumerStatefulWidget {
  const SeasonScreen({super.key});

  @override
  ConsumerState<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends ConsumerState<SeasonScreen> {
  String? _claimingMissionId;

  @override
  Widget build(BuildContext context) {
    final season = ref.watch(seasonProvider);
    final missions = ref.watch(seasonMissionsProvider);
    final primaryVehicle = ref.watch(primaryVehicleProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.mobileMargin, AppSpacing.md, AppSpacing.mobileMargin, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('시즌',
              style: AppTypography.displayScore
                  .copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.xs),
          Text('대표 차량 리그를 기준으로 승급과 보상을 계산합니다',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: AppSpacing.lg),
          primaryVehicle.when(
            loading: () => const LoadingSkeletonView(lines: 2),
            error: (error, stackTrace) =>
                const ErrorStateView(message: '대표 차량을 확인하지 못했어요.'),
            data: (vehicle) {
              if (vehicle == null) {
                return EmptyStateView(
                  title: '시즌 리그가 아직 없어요',
                  message: '차량을 설정하면 연료 리그와 차급에 맞는 시즌 리그가 자동으로 열립니다.',
                  actionLabel: '차량 설정하기',
                  onAction: () => context.go('/setup/vehicle'),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusChip(
                            label: vehicle.leagueDisplayName,
                            color: AppColors.neonGreen),
                        const SizedBox(height: AppSpacing.sm),
                        Text('${vehicle.displayName} 기준 시즌',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text('미션과 보상은 유지하되 랭킹 비교는 같은 연료 리그와 차급을 우선합니다.',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.onSurfaceMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  season.when(
                    loading: () => const LoadingSkeletonView(lines: 2),
                    error: (error, stackTrace) =>
                        const ErrorStateView(message: '시즌 정보를 불러오지 못했어요.'),
                    data: (value) => SeasonProgressCard(season: value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: '일일 미션과 주간 챌린지'),
                  missions.when(
                    loading: () => const LoadingSkeletonView(lines: 2),
                    error: (error, stackTrace) =>
                        const ErrorStateView(message: '미션을 불러오지 못했어요.'),
                    data: (items) => Column(
                      children: items
                          .map(
                            (mission) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: MissionCard(
                                mission: mission,
                                isClaiming: _claimingMissionId == mission.id,
                                onClaimReward: () => _claimReward(mission.id),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SectionHeader(title: '시즌패스 보상 트랙'),
                  const RewardCard(
                      title: '무료 보상',
                      description: '배지 조각, 시즌 XP, 쿠폰 응모권을 획득하세요.'),
                  const SizedBox(height: AppSpacing.md),
                  const LockedPremiumCard(
                    title: '프리미엄 보상 잠금',
                    description: '프리미엄 배지와 시즌패스 추가 보상이 기다리고 있어요.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _claimReward(
    String missionId,
  ) async {
    setState(() => _claimingMissionId = missionId);
    try {
      final result = await ref
          .read(seasonRepositoryProvider)
          .claimMissionReward(missionId);
      ref.invalidate(seasonMissionsProvider);
      ref.invalidate(seasonProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(homeSnapshotProvider);
      if (!mounted) return;
      final label = result.rewardClaimed ? '시즌 보상을 받았어요.' : '미션 상태를 갱신했어요.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(label)));
    } catch (error) {
      if (!mounted) return;
      final message = const ErrorMapper().messageFor(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('보상을 받을 수 없어요. $message')),
      );
    } finally {
      if (mounted && _claimingMissionId == missionId) {
        setState(() => _claimingMissionId = null);
      }
    }
  }
}
