import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battles = ref.watch(battlesProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.mobileMargin, AppSpacing.md, AppSpacing.mobileMargin, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('배틀', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
            const SizedBox(height: AppSpacing.xs),
            Text('현금성 베팅 없이 점수와 명예로 겨룹니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: '새 배틀 만들기', icon: Icons.add_rounded, onPressed: () {}),
            const SizedBox(height: AppSpacing.xl),
            battles.when(
              loading: () => const LoadingSkeletonView(lines: 4),
              error: (error, stackTrace) => const ErrorStateView(message: '배틀 목록을 불러오지 못했어요.'),
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: '진행 중 배틀'),
                  BattleCard(battle: items.first),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: '추천 공개 배틀'),
                  ...items.skip(1).map(
                        (battle) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: BattleCard(battle: battle),
                        ),
                      ),
                  const SectionHeader(title: '배틀 템플릿'),
                  const AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusChip(label: '비현금성', color: AppColors.amber),
                        SizedBox(height: AppSpacing.md),
                        Text('커피런 · 점심길 · 벌칙 미션', style: AppTypography.titleMedium),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          '금전 거래 없이 시즌 XP, 배지 조각, 쿠폰 응모권 같은 앱 내 보상으로만 표현합니다.',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
