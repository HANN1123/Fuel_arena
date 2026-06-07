import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
  var _purchasePending = false;
  var _storeAvailable = false;
  var _storeMessage = '';
  ProductDetails? _storeProduct;
  String _loadedProductId = '';
  String _selectedPlanId = '';
  String _selectedProductId = '';
  String _activePlanId = '';
  var _restorePending = false;
  final _planIdByProductId = <String, String>{};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool get _supportsStorePurchase {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  @override
  void initState() {
    super.initState();
    if (_supportsStorePurchase) {
      _purchaseSubscription =
          InAppPurchase.instance.purchaseStream.listen(_handlePurchaseUpdates);
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStoreProduct(String productId) async {
    if (!_supportsStorePurchase ||
        productId.isEmpty ||
        productId == _loadedProductId) {
      return;
    }
    _loadedProductId = productId;
    final available = await InAppPurchase.instance.isAvailable();
    if (!mounted) {
      return;
    }
    if (!available) {
      setState(() {
        _storeAvailable = false;
        _storeMessage = '스토어 결제를 사용할 수 없어요.';
      });
      return;
    }

    final response =
        await InAppPurchase.instance.queryProductDetails({productId});
    if (!mounted) {
      return;
    }
    if (response.productDetails.isEmpty) {
      setState(() {
        _storeAvailable = false;
        _storeMessage = '스토어 상품을 찾지 못했어요.';
      });
      return;
    }
    setState(() {
      _storeAvailable = true;
      _storeProduct = response.productDetails.first;
      _storeMessage = '';
    });
  }

  Future<void> _startPurchase(SubscriptionPlan? plan) async {
    if (plan == null) {
      return;
    }
    _selectedPlanId = plan.id;
    _selectedProductId = plan.productId;
    _planIdByProductId[plan.productId] = plan.id;

    if (_supportsStorePurchase) {
      final productId = plan.productId;
      await _loadStoreProduct(productId);
      final product = _storeProduct;
      if (product == null || !_storeAvailable || product.id != productId) {
        _showSnack(
          _storeMessage.isEmpty ? '스토어 상품을 불러오지 못했어요.' : _storeMessage,
        );
        return;
      }
      setState(() => _purchasePending = true);
      final sent = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!sent && mounted) {
        setState(() => _purchasePending = false);
        _showSnack('결제 요청을 시작하지 못했어요.');
      }
      return;
    }

    final config = ref.read(appConfigProvider);
    if (!config.canUseMockRepositories) {
      _showSnack('실제 스토어 결제는 Android 또는 iOS에서 진행할 수 있어요.');
      return;
    }
    final ok = await ref
        .read(subscriptionRepositoryProvider)
        .startSubscription(plan.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _purchased = ok;
      _activePlanId = ok ? plan.id : '';
    });
    _showSnack('개발 모드 결제 확인이 완료됐어요.');
  }

  Future<void> _restorePurchases() async {
    if (!_supportsStorePurchase) {
      _showSnack('구매 복원은 Android 또는 iOS에서 진행할 수 있어요.');
      return;
    }
    setState(() => _restorePending = true);
    try {
      await InAppPurchase.instance.restorePurchases();
      if (!mounted) {
        return;
      }
      _showSnack('구매 복원을 요청했어요. 스토어 내역을 확인합니다.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('구매 복원을 시작하지 못했어요.');
    } finally {
      if (mounted) {
        setState(() => _restorePending = false);
      }
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) {
          setState(() => _purchasePending = true);
        }
        continue;
      }
      if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          setState(() => _purchasePending = false);
          _showSnack(purchase.error?.message ?? '결제 오류가 발생했어요.');
        }
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _verifyPurchase(purchase);
      }
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    try {
      final provider = _providerFor(purchase.verificationData.source);
      final result = await ref
          .read(subscriptionRepositoryProvider)
          .verifyPurchase(
            PurchaseVerificationRequest(
              provider: provider,
              productId: purchase.productID,
              purchaseToken: purchase.verificationData.serverVerificationData,
              transactionId: purchase.purchaseID ??
                  purchase.transactionDate ??
                  '${purchase.productID}-${DateTime.now().millisecondsSinceEpoch}',
              planId: _planIdForProductId(purchase.productID),
            ),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _purchasePending = false;
        _purchased = result.premiumActive;
        _activePlanId = result.premiumActive
            ? result.planId.isNotEmpty
                ? result.planId
                : _planIdForProductId(purchase.productID)
            : '';
      });
      _showSnack(
        result.premiumActive ? '프리미엄이 활성화됐어요.' : '구매 검증이 보류됐어요.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _purchasePending = false);
      _showSnack('구매 영수증을 검증하지 못했어요.');
    }
  }

  String _planIdForProductId(String productId) {
    if (_selectedProductId == productId && _selectedPlanId.isNotEmpty) {
      return _selectedPlanId;
    }
    return _planIdByProductId[productId] ?? '';
  }

  void _rememberPlanProducts(List<SubscriptionPlan> plans) {
    for (final plan in plans) {
      if (plan.productId.isNotEmpty) {
        _planIdByProductId[plan.productId] = plan.id;
      }
    }
  }

  String _providerFor(String source) {
    final normalized = source.toLowerCase();
    if (normalized.contains('google') || normalized.contains('play')) {
      return 'google_play';
    }
    if (normalized.contains('app_store') ||
        normalized.contains('storekit') ||
        normalized.contains('ios')) {
      return 'app_store';
    }
    return source;
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(premiumRepositoryProvider).getPlans();
    final remotePriceLabel = ref.watch(appRemoteConfigProvider).maybeWhen(
          data: (config) => config.premiumPriceLabel,
          orElse: () => '월 4,900원',
        );
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '프리미엄', showBack: true),
      child: FutureBuilder<List<SubscriptionPlan>>(
        future: plans,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingSkeletonView(lines: 4);
          }
          if (snapshot.hasError) {
            return ErrorStateView(
              message: '프리미엄 요금제를 불러오지 못했어요.',
              onRetry: () => setState(() {}),
            );
          }
          final items = snapshot.data ?? const <SubscriptionPlan>[];
          if (items.isEmpty) {
            return EmptyStateView(
              title: '요금제를 확인할 수 없어요',
              message:
                  '결제 상품 정보를 불러오지 못했습니다. 계정이나 스토어 설정 문제라면 고객지원에서 바로 확인해드릴게요.',
              actionLabel: '고객지원 문의',
              onAction: () => context.push('/support/contact'),
            );
          }

          _rememberPlanProducts(items);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '더 깊게 분석하고\n더 멋지게 경쟁하세요',
                style:
                    AppTypography.displayScore.copyWith(color: AppColors.gold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '프리미엄은 광고 제거보다 더 강한 경쟁 도구입니다.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              for (final plan in items) ...[
                _PremiumPlanCard(
                  plan: plan,
                  fallbackPriceLabel: remotePriceLabel,
                  isActive: _purchased && _activePlanId == plan.id,
                  isBusy: _purchasePending || _restorePending,
                  onStart: () => _startPurchase(plan),
                  onProfile: () => context.go('/home?tab=profile'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_supportsStorePurchase)
                SecondaryButton(
                  label: _restorePending ? '구매 복원 확인 중' : '구매 복원',
                  icon: Icons.restore_rounded,
                  onPressed: _purchasePending || _restorePending
                      ? null
                      : _restorePurchases,
                ),
              if (_storeMessage.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _storeMessage,
                  style:
                      AppTypography.dataUnit.copyWith(color: AppColors.amber),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PremiumPlanCard extends StatelessWidget {
  const _PremiumPlanCard({
    required this.plan,
    required this.fallbackPriceLabel,
    required this.isActive,
    required this.isBusy,
    required this.onStart,
    required this.onProfile,
  });

  final SubscriptionPlan plan;
  final String fallbackPriceLabel;
  final bool isActive;
  final bool isBusy;
  final VoidCallback onStart;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final planName = plan.name.isEmpty ? 'Fuel Arena 프리미엄' : plan.name;
    final priceLabel =
        plan.priceLabel.isEmpty ? fallbackPriceLabel : plan.priceLabel;
    final benefits = plan.benefits.isEmpty
        ? const ['광고 제거', '고급 통계', '라이벌 분석', '시즌패스 추가 보상']
        : plan.benefits;
    return AppCard(
      borderColor: plan.isRecommended
          ? AppColors.gold.withValues(alpha: 0.35)
          : AppColors.neonGreen.withValues(alpha: 0.18),
      glowColor: plan.isRecommended ? AppColors.gold : AppColors.neonGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.isRecommended) ...[
            const StatusChip(
              label: '추천',
              color: AppColors.gold,
              icon: Icons.workspace_premium_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(planName, style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            priceLabel,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.neonGreen,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final benefit in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.neonGreen,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(benefit, style: AppTypography.bodyMedium),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: isActive
                ? '이 요금제가 활성화됨'
                : isBusy
                    ? '결제 확인 중'
                    : _startLabel,
            icon: isActive
                ? Icons.check_circle_rounded
                : isBusy
                    ? Icons.hourglass_top_rounded
                    : Icons.arrow_forward_rounded,
            onPressed: isActive
                ? onProfile
                : isBusy
                    ? null
                    : onStart,
          ),
        ],
      ),
    );
  }

  String get _startLabel {
    return switch (plan.planType) {
      'season_pass' => '시즌패스 시작하기',
      'bundle' => '번들 시작하기',
      _ => '프리미엄 시작하기',
    };
  }
}
