import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_spacing.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class RewardAdMockScreen extends ConsumerStatefulWidget {
  const RewardAdMockScreen({super.key});

  @override
  ConsumerState<RewardAdMockScreen> createState() => _RewardAdMockScreenState();
}

class _RewardAdMockScreenState extends ConsumerState<RewardAdMockScreen> {
  var _claimed = false;
  var _loading = false;

  Future<void> _watch() async {
    setState(() => _loading = true);
    await ref.read(adsRepositoryProvider).watchRewardAd();
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
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '리워드 광고', showBack: true),
      child: Column(
        children: [
          AdRewardCard(
            label: '광고 보고 시즌 XP 2배 받기',
            loading: _loading,
            claimed: _claimed,
            onWatch: _watch,
          ),
          const SizedBox(height: AppSpacing.md),
          const RewardCard(
            title: '광고 정책',
            description: '주행 중, 주행 시작 전, 배틀 진행 중에는 광고를 표시하지 않습니다.',
          ),
        ],
      ),
    );
  }
}
