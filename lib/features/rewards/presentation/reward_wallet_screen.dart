import 'package:flutter/material.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/widgets/widgets.dart';

class RewardWalletScreen extends StatelessWidget {
  const RewardWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coupon = Coupon(
      id: 'coupon-001',
      title: '세차 쿠폰 응모권',
      description: '스폰서 챌린지 완료 보상으로 받은 응모권입니다.',
      expiresAt: DateTime.now().add(const Duration(days: 14)),
    );

    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '리워드 지갑', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('보상은 지갑에,\n경쟁은 계속', style: AppTypography.displayScore.copyWith(color: AppColors.gold)),
          const SizedBox(height: AppSpacing.lg),
          CouponCard(coupon: coupon),
          const SizedBox(height: AppSpacing.md),
          const RewardCard(
            title: '배지 조각 7개',
            description: '10개를 모으면 시즌 한정 배지를 제작할 수 있어요.',
          ),
        ],
      ),
    );
  }
}
