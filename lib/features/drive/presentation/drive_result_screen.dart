import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class DriveResultScreen extends ConsumerStatefulWidget {
  const DriveResultScreen({
    super.key,
    this.sessionId = 'local-session',
  });

  final String sessionId;

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
    final localState = ref.read(localStateServiceProvider);
    final routeSessionId = _routeSessionId;
    final resolvedSessionId = await ref
        .read(offlineQueueServiceProvider)
        .resolveDriveSessionId(routeSessionId);
    final summary =
        await localState.getLatestDriveResultSummary(routeSessionId);
    if (summary == null ||
        summary.distanceKm <= 0 ||
        summary.duration <= Duration.zero ||
        summary.averageEfficiency <= 0) {
      throw _MissingDriveResultSummaryException(routeSessionId);
    }

    final distanceKm = summary.distanceKm;
    final duration = summary.duration;
    final averageEfficiency = summary.averageEfficiency;
    final fuelUsedLiters = summary.fuelUsedLiters > 0
        ? summary.fuelUsedLiters
        : distanceKm / averageEfficiency;

    final score = await driveRepository.finishDriveSession(
      sessionId: resolvedSessionId,
      distanceKm: distanceKm,
      duration: duration,
      averageEfficiency: averageEfficiency,
      fuelUsedLiters: fuelUsedLiters,
    );
    final adAvailable = await adsRepository.isRewardAdAvailable();
    final dailyLimit = await adsRepository.getDailyRewardAdLimit();

    return _DriveResultPayload(
      score: score,
      adAvailable: adAvailable,
      dailyAdLimit: dailyLimit,
      distanceKm: distanceKm,
      duration: duration,
      averageEfficiency: averageEfficiency,
      sessionId: resolvedSessionId,
    );
  }

  String get _routeSessionId {
    final trimmed = widget.sessionId.trim();
    return trimmed.isEmpty ? 'local-session' : trimmed;
  }

  Future<void> _watchAd() async {
    setState(() => _rewardLoading = true);
    try {
      final config = ref.read(appConfigProvider);
      var verifiedByAdSdk = false;
      if (config.isProduction && config.hasSupabase) {
        await ref.read(rewardedAdServiceProvider).showRewardedAd(config);
        verifiedByAdSdk = true;
      }
      await ref
          .read(adsRepositoryProvider)
          .watchRewardAd(verifiedByAdSdk: verifiedByAdSdk);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _rewardLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('광고 보상을 확인하지 못했어요. 기본 보상은 유지됩니다.')),
      );
      return;
    }
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
            if (snapshot.error is _MissingDriveResultSummaryException) {
              return EmptyStateView(
                title: '주행 결과 기록이 없어요',
                message:
                    '완료된 주행 요약을 찾지 못했습니다. 저장된 거리, 시간, 연비가 없으면 점수와 랭킹 기록을 만들지 않습니다.',
                actionLabel: '주행 시작하기',
                onAction: () => context.go('/drive/start'),
              );
            }
            return ErrorStateView(
              message: '주행 결과를 계산하지 못했어요.',
              onRetry: () => setState(() {
                _resultFuture = _loadResult();
              }),
            );
          }

          final payload = snapshot.data!;
          final score = payload.score;
          final fuelLeague = ref.watch(primaryVehicleProvider).maybeWhen(
                data: (vehicle) => vehicle?.leagueKey ?? 'gasoline',
                orElse: () => 'gasoline',
              );
          const efficiencyFormatter = FuelEfficiencyFormatter();
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
                averageEfficiency: payload.averageEfficiency,
                classPercentile: score.classPercentile,
                rankingDelta: 3,
                seasonXp: _rewardClaimed ? 360 : 180,
                distanceKm: payload.distanceKm,
                duration: payload.duration,
                fuelLeague: fuelLeague,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                efficiencyFormatter.helperCopyForFuelLeague(fuelLeague),
                style: AppTypography.dataUnit
                    .copyWith(color: AppColors.onSurfaceMuted),
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
                  style: AppTypography.dataUnit
                      .copyWith(color: AppColors.neonGreen),
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
                label: '이 기록 검토 요청',
                icon: Icons.fact_check_rounded,
                onPressed: () =>
                    context.go('/support/review-request/${payload.sessionId}'),
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
                style: AppTypography.dataUnit
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MissingDriveResultSummaryException implements Exception {
  const _MissingDriveResultSummaryException(this.sessionId);

  final String sessionId;
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
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
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
    required this.distanceKm,
    required this.duration,
    required this.averageEfficiency,
    required this.sessionId,
  });

  final DriveScore score;
  final bool adAvailable;
  final int dailyAdLimit;
  final double distanceKm;
  final Duration duration;
  final double averageEfficiency;
  final String sessionId;
}
