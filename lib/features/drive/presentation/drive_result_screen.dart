import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class DriveResultScreen extends ConsumerStatefulWidget {
  const DriveResultScreen({super.key});

  @override
  ConsumerState<DriveResultScreen> createState() => _DriveResultScreenState();
}

class _DriveResultScreenState extends ConsumerState<DriveResultScreen> {
  late Future<_DriveResultPayload> _resultFuture;
  var _rewardLoading = false;
  var _rewardClaimed = false;
  var _baseRewardClaimed = false;

  @override
  void initState() {
    super.initState();
    _resultFuture = _loadResult();
  }

  Future<_DriveResultPayload> _loadResult() async {
    final driveRepository = ref.read(driveRepositoryProvider);
    final adsRepository = ref.read(adsRepositoryProvider);

    final score = await driveRepository.finishDriveSession();
    final adAvailable = await adsRepository.isRewardAdAvailable();
    final dailyLimit = await adsRepository.getDailyRewardAdLimit();

    return _DriveResultPayload(
      score: score,
      adAvailable: adAvailable,
      dailyAdLimit: dailyLimit,
    );
  }

  Future<void> _watchAd() async {
    setState(() => _rewardLoading = true);
    await ref.read(adsRepositoryProvider).watchRewardAd();
    if (!mounted) {
      return;
    }
    setState(() {
      _rewardLoading = false;
      _rewardClaimed = true;
    });
  }

  void _claimBaseReward() {
    setState(() => _baseRewardClaimed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('기본 보상이 지급됐어요. 광고 보상은 선택 사항입니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '주행 결과', showBack: true),
      child: FutureBuilder<_DriveResultPayload>(
        future: _resultFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _CalculatingResultView();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorStateView(
              message: '주행 결과를 계산하지 못했어요.',
              onRetry: () => setState(() {
                _resultFuture = _loadResult();
              }),
            );
          }

          final payload = snapshot.data!;
          final score = payload.score;
          final adState = _rewardClaimed
              ? 'rewardClaimed'
              : payload.adAvailable
                  ? 'adAvailable'
                  : 'adUnavailable';
          final resultState = _rewardClaimed
              ? 'rewardClaimed'
              : score.verificationStatus == 'verified'
                  ? 'verified'
                  : 'verifying';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DriveResultHeader(
                score: score,
                tier: 'Gold III',
                promotionLeft: 120,
                status: score.verificationStatus,
              ),
              const SizedBox(height: AppSpacing.md),
              ResultStateBanner(state: resultState),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: '핵심 지표'),
              DriveResultKpiGrid(
                averageEfficiency: 18.4,
                classPercentile: score.classPercentile,
                rankingDelta: 3,
                seasonXp: _rewardClaimed ? 360 : 180,
                distanceKm: 24.8,
                duration: const Duration(minutes: 38, seconds: 12),
              ),
              const SizedBox(height: AppSpacing.lg),
              DriveScoreAnalysisCard(score: score),
              const SizedBox(height: AppSpacing.lg),
              const RankingResultCard(
                overtakenCount: 3,
                pointsToTopTen: 120,
                rivalName: 'NightCruise',
                rivalGap: 48,
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: '보상 선택',
                actionLabel: switch (adState) {
                  'adAvailable' => '광고 가능',
                  'rewardClaimed' => '보상 완료',
                  _ => '광고 대기',
                },
              ),
              DriveRewardAdCard(
                adAvailable: payload.adAvailable,
                dailyLimit: payload.dailyAdLimit,
                usedToday: _rewardClaimed ? 1 : 0,
                rewardClaimed: _rewardClaimed,
                loading: _rewardLoading,
                onWatchAd: _watchAd,
                onClaimBaseReward: _claimBaseReward,
              ),
              if (_baseRewardClaimed) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '기본 보상은 확보됐습니다. 추가 보상은 원할 때만 선택하세요.',
                  style: AppTypography.dataUnit.copyWith(color: AppColors.neonGreen),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: '랭킹 확인',
                icon: Icons.leaderboard_rounded,
                onPressed: () => context.go('/home?tab=ranking'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: '라이벌에게 도전',
                icon: Icons.sports_mma_rounded,
                onPressed: () => context.go('/home?tab=battle'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: '홈으로 돌아가기',
                icon: Icons.home_rounded,
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '검증 완료 후 랭킹에 반영됩니다. 정확한 위치 경로는 공개되지 않습니다.',
                style: AppTypography.dataUnit.copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CalculatingResultView extends StatelessWidget {
  const _CalculatingResultView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResultStateBanner(state: 'calculating'),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          glowColor: AppColors.electricBlue,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              const SizedBox.square(
                dimension: 76,
                child: CircularProgressIndicator(
                  strokeWidth: 7,
                  valueColor: AlwaysStoppedAnimation(AppColors.electricBlue),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('주행 데이터를 계산하고 있어요', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '연비, 안정 주행, 동급 보정, 랭킹 반영 가능 여부를 분리해서 확인합니다.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const LoadingSkeletonView(lines: 4),
      ],
    );
  }
}

class _DriveResultPayload {
  const _DriveResultPayload({
    required this.score,
    required this.adAvailable,
    required this.dailyAdLimit,
  });

  final DriveScore score;
  final bool adAvailable;
  final int dailyAdLimit;
}
