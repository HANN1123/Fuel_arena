import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final primaryVehicle = ref.watch(primaryVehicleProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.mobileMargin, AppSpacing.md, AppSpacing.mobileMargin, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('배틀',
              style: AppTypography.displayScore
                  .copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.xs),
          Text('같은 연료 리그와 차급 운전자끼리 점수와 명예로 겨룹니다',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: AppSpacing.lg),
          primaryVehicle.when(
            loading: () => const LoadingSkeletonView(lines: 1),
            error: (error, stackTrace) =>
                const ErrorStateView(message: '대표 차량을 확인하지 못했어요.'),
            data: (vehicle) {
              if (vehicle == null) {
                return EmptyStateView(
                  title: '차량 설정이 필요해요',
                  message: '배틀은 내 연료 리그와 차급을 기준으로 매칭됩니다. 먼저 대표 차량을 설정해주세요.',
                  actionLabel: '차량 설정하기',
                  onAction: () => context.go('/setup/vehicle'),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusChip(
                            label: vehicle.leagueDisplayName,
                            color: AppColors.neonGreen),
                        const SizedBox(height: AppSpacing.sm),
                        Text('대표 차량 ${vehicle.displayName}',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                            '공개 매칭은 같은 연료 리그와 차급을 우선 적용하고, 다른 리그는 친선전으로 표시합니다.',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.onSurfaceMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                      label: '새 배틀 만들기',
                      icon: Icons.add_rounded,
                      onPressed: () => context.push('/battle/create')),
                  const SizedBox(height: AppSpacing.xl),
                  battles.when(
                    loading: () => const LoadingSkeletonView(lines: 4),
                    error: (error, stackTrace) =>
                        const ErrorStateView(message: '배틀 목록을 불러오지 못했어요.'),
                    data: (items) {
                      if (items.isEmpty) {
                        return const EmptyStateView(
                          title: '진행 중인 배틀이 없어요',
                          message: '내 리그에 맞는 공개 배틀이 열리면 여기에 표시됩니다.',
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: '진행 중 배틀'),
                          BattleCard(
                              battle: items.first,
                              onTap: () => context
                                  .push('/battle/detail/${items.first.id}')),
                          const SizedBox(height: AppSpacing.lg),
                          const SectionHeader(title: '추천 공개 배틀'),
                          ...items.skip(1).map(
                                (battle) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.md),
                                  child: BattleCard(
                                      battle: battle,
                                      onTap: () => context
                                          .push('/battle/detail/${battle.id}')),
                                ),
                              ),
                          const SectionHeader(title: '배틀 템플릿'),
                          const AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatusChip(
                                    label: '비현금성', color: AppColors.amber),
                                SizedBox(height: AppSpacing.md),
                                Text('커피런 · 점심길 · 벌칙 미션',
                                    style: AppTypography.titleMedium),
                                SizedBox(height: AppSpacing.xs),
                                Text(
                                  '금전 거래 없이 시즌 XP, 배지 조각, 쿠폰 응모권 같은 앱 내 보상으로만 표현합니다.',
                                  style: AppTypography.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
