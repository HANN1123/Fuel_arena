import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_spacing.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class RewardAdScreen extends ConsumerStatefulWidget {
  const RewardAdScreen({super.key});

  @override
  ConsumerState<RewardAdScreen> createState() => _RewardAdScreenState();
}

class _RewardAdScreenState extends ConsumerState<RewardAdScreen> {
  var _claimed = false;
  var _loading = false;

  Future<void> _watch() async {
    setState(() => _loading = true);
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
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('광고 보상을 확인하지 못했어요. 잠시 후 다시 시도해주세요.'),
        ),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _claimed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final remoteConfig = ref.watch(appRemoteConfigProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '리워드 광고', showBack: true),
      child: remoteConfig.when(
        loading: () => const LoadingSkeletonView(lines: 4),
        error: (error, stackTrace) => ErrorStateView(
          message: '리워드 광고 운영 설정을 불러오지 못했어요.',
          onRetry: () => ref.invalidate(appRemoteConfigProvider),
        ),
        data: (config) {
          final adsEnabled = config.rewardAdsEnabled;
          final dailyLimit = config.rewardAdDailyLimit;
          return Column(
            children: [
              if (adsEnabled)
                AdRewardCard(
                  label: '광고 보고 시즌 XP 2배 받기 · 하루 $dailyLimit회',
                  loading: _loading,
                  claimed: _claimed,
                  onWatch: _watch,
                )
              else
                const EmptyStateView(
                  title: '광고 보상이 잠시 중단됐어요',
                  message: '기본 보상은 그대로 지급됩니다. 운영 설정이 바뀌면 다시 표시됩니다.',
                ),
              const SizedBox(height: AppSpacing.md),
              const RewardCard(
                title: '광고 정책',
                description: '주행 중, 주행 시작 전, 배틀 진행 중에는 광고를 표시하지 않습니다.',
              ),
            ],
          );
        },
      ),
    );
  }
}
