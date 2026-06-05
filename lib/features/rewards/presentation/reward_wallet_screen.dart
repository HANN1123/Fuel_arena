import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class RewardWalletScreen extends ConsumerWidget {
  const RewardWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupons = ref.watch(couponsProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '리워드 지갑', showBack: true),
      child: coupons.when(
        loading: () => const LoadingSkeletonView(lines: 4),
        error: (error, stackTrace) => const ErrorStateView(message: '리워드를 불러오지 못했어요.'),
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('보상은 지갑에,\n경쟁은 계속', style: AppTypography.displayScore.copyWith(color: AppColors.gold)),
            const SizedBox(height: AppSpacing.lg),
            ...items.take(4).map((coupon) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: CouponCard(coupon: coupon))),
            const RewardCard(
              title: '배지 조각 7개',
              description: '10개를 모으면 시즌 한정 배지를 제작할 수 있어요.',
            ),
          ],
        ),
      ),
    );
  }
}
