import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class RewardWalletScreen extends ConsumerStatefulWidget {
  const RewardWalletScreen({super.key});

  @override
  ConsumerState<RewardWalletScreen> createState() => _RewardWalletScreenState();
}

class _RewardWalletScreenState extends ConsumerState<RewardWalletScreen> {
  final _issuedCouponIds = <String>{};
  String _issuingCouponId = '';

  Future<void> _issueCoupon(Coupon coupon) async {
    if (_issuingCouponId.isNotEmpty || _issuedCouponIds.contains(coupon.id)) {
      return;
    }
    setState(() => _issuingCouponId = coupon.id);
    try {
      await ref.read(analyticsRepositoryProvider).track(
        'coupon_issue_requested',
        properties: {'coupon_id': coupon.id},
      );
      await ref.read(couponRepositoryProvider).issueCoupon(coupon.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _issuedCouponIds.add(coupon.id);
      });
      await ref.read(analyticsRepositoryProvider).track(
        'coupon_issue_succeeded',
        properties: {'coupon_id': coupon.id},
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${coupon.title} 쿠폰이 발급됐어요.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = const ErrorMapper().messageFor(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('쿠폰을 발급하지 못했어요. $message')),
      );
    } finally {
      if (mounted) {
        setState(() => _issuingCouponId = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupons = ref.watch(couponsProvider);
    final remoteConfig = ref.watch(appRemoteConfigProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '리워드 지갑', showBack: true),
      child: remoteConfig.when(
        loading: () => const LoadingSkeletonView(lines: 4),
        error: (error, stackTrace) => ErrorStateView(
          message: '쿠폰 운영 설정을 불러오지 못했어요.',
          onRetry: () => ref.invalidate(appRemoteConfigProvider),
        ),
        data: (config) => coupons.when(
          loading: () => const LoadingSkeletonView(lines: 4),
          error: (error, stackTrace) => ErrorStateView(
            message: '리워드를 불러오지 못했어요.',
            onRetry: () => ref.invalidate(couponsProvider),
          ),
          data: (items) => _RewardWalletContent(
            couponsEnabled: config.couponsEnabled,
            coupons: items,
            issuedCouponIds: _issuedCouponIds,
            issuingCouponId: _issuingCouponId,
            onIssueCoupon: _issueCoupon,
          ),
        ),
      ),
    );
  }
}

class _RewardWalletContent extends StatelessWidget {
  const _RewardWalletContent({
    required this.couponsEnabled,
    required this.coupons,
    required this.issuedCouponIds,
    required this.issuingCouponId,
    required this.onIssueCoupon,
  });

  final bool couponsEnabled;
  final List<Coupon> coupons;
  final Set<String> issuedCouponIds;
  final String issuingCouponId;
  final Future<void> Function(Coupon coupon) onIssueCoupon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '보상은 지갑에,\n경험은 계속',
          style: AppTypography.displayScore.copyWith(color: AppColors.gold),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!couponsEnabled)
          const EmptyStateView(
            title: '쿠폰 발급이 잠시 쉬고 있어요',
            message: '보유한 시즌 XP와 배지 조각은 그대로 유지돼요. 운영 설정이 바뀌면 다시 표시됩니다.',
          )
        else if (coupons.isEmpty)
          EmptyStateView(
            title: '사용 가능한 쿠폰이 없어요',
            message: '시즌 미션과 광고 보상으로 쿠폰 응모권과 배지 조각을 모을 수 있어요.',
            actionLabel: '리워드 광고 보기',
            onAction: () => context.push('/ads/reward'),
          )
        else
          ...coupons.take(4).map(
                (coupon) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ClaimableCouponCard(
                    coupon: coupon,
                    issued: issuedCouponIds.contains(coupon.id),
                    loading: issuingCouponId == coupon.id,
                    onIssue: () => onIssueCoupon(coupon),
                  ),
                ),
              ),
        const SizedBox(height: AppSpacing.md),
        const RewardCard(
          title: '배지 조각 7개',
          description: '10개를 모으면 시즌 한정 배지를 시작할 수 있어요.',
        ),
      ],
    );
  }
}

class _ClaimableCouponCard extends StatelessWidget {
  const _ClaimableCouponCard({
    required this.coupon,
    required this.issued,
    required this.loading,
    required this.onIssue,
  });

  final Coupon coupon;
  final bool issued;
  final bool loading;
  final VoidCallback onIssue;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.gold.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.confirmation_number_rounded,
                color: AppColors.gold,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coupon.title, style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      coupon.description,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: issued
                ? '발급 완료'
                : loading
                    ? '발급 중'
                    : '쿠폰 받기',
            icon: issued ? Icons.check_circle_rounded : Icons.download_rounded,
            onPressed: issued || loading ? null : onIssue,
          ),
        ],
      ),
    );
  }
}
