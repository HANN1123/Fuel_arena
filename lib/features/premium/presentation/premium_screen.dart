import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  var _purchased = false;

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(premiumRepositoryProvider).getPlans();
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: 'Premium', showBack: true),
      child: FutureBuilder<List<SubscriptionPlan>>(
        future: plans,
        builder: (context, snapshot) {
          final plan = snapshot.data?.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('더 깊게 분석하고\n더 멋지게 경쟁하세요', style: AppTypography.displayScore.copyWith(color: AppColors.gold)),
              const SizedBox(height: AppSpacing.sm),
              Text('프리미엄은 광고 제거보다 더 강한 경쟁 도구입니다.', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                borderColor: AppColors.gold.withOpacity(0.35),
                glowColor: AppColors.gold,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusChip(label: '추천', color: AppColors.gold, icon: Icons.workspace_premium_rounded),
                    const SizedBox(height: AppSpacing.md),
                    Text(plan?.name ?? 'Fuel Arena Premium', style: AppTypography.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(plan?.priceLabel ?? '월 4,900원', style: AppTypography.titleMedium.copyWith(color: AppColors.neonGreen)),
                    const SizedBox(height: AppSpacing.md),
                    for (final benefit in plan?.benefits ?? const ['광고 제거', '고급 통계', '라이벌 분석', '시즌패스 추가 보상'])
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(benefit, style: AppTypography.bodyMedium)),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: _purchased ? '프리미엄 활성화됨' : '프리미엄 시작하기',
                      icon: _purchased ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      onPressed: _purchased
                          ? () => context.go('/home?tab=profile')
                          : () async {
                              final ok = await ref.read(subscriptionRepositoryProvider).startSubscription(plan?.id ?? 'premium-monthly');
                              if (!mounted) {
                                return;
                              }
                              setState(() => _purchased = ok);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('개발 모드 mock purchase가 완료됐어요.')),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
