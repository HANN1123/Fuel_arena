import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class RankingDetailScreen extends ConsumerWidget {
  const RankingDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankings = ref.watch(rankingEntriesProvider('내 리그'));
    final primaryVehicle = ref.watch(primaryVehicleProvider);

    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '랭킹 상세', showBack: true),
      child: primaryVehicle.when(
        loading: () => const LoadingSkeletonView(lines: 2),
        error: (error, stackTrace) => ErrorStateView(
          message: '대표 차량을 확인하지 못했어요.',
          onRetry: () => ref.invalidate(primaryVehicleProvider),
        ),
        data: (vehicle) {
          if (vehicle == null) {
            return EmptyStateView(
              title: '차량 설정이 필요해요',
              message: '내 리그 상세 랭킹은 대표 차량의 연료 리그와 차급을 기준으로 계산됩니다.',
              actionLabel: '차량 설정하기',
              onAction: () => context.go('/setup/vehicle'),
            );
          }
          return rankings.when(
            loading: () => const LoadingSkeletonView(lines: 5),
            error: (error, stackTrace) => ErrorStateView(
              message: '랭킹 상세를 불러오지 못했어요.',
              onRetry: () => ref.invalidate(rankingEntriesProvider('내 리그')),
            ),
            data: (items) {
              if (items.isEmpty) {
                return EmptyStateView(
                  title: '아직 리그 랭킹이 없어요',
                  message:
                      '검증된 주행 기록이 쌓이면 ${vehicle.leagueDisplayName} 상세 랭킹이 표시됩니다.',
                  actionLabel: '주행 시작하기',
                  onAction: () => context.go('/drive/start'),
                );
              }
              return _RankingDetailContent(
                vehicle: vehicle,
                rankings: items,
              );
            },
          );
        },
      ),
    );
  }
}

class _RankingDetailContent extends StatelessWidget {
  const _RankingDetailContent({
    required this.vehicle,
    required this.rankings,
  });

  final Vehicle vehicle;
  final List<RankingEntry> rankings;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern();
    final current = _currentEntry(rankings);
    final topEntries = rankings.take(3).toList();
    final nearby = _nearbyEntries(rankings, current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '내 리그의\n상세 순위',
          style: AppTypography.displayScore.copyWith(
            color: AppColors.neonGreen,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${vehicle.leagueDisplayName} 기준으로 공개 랭킹 정보를 비교합니다.',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.onSurfaceMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          borderColor: AppColors.neonGreen.withValues(alpha: 0.28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusChip(
                label: vehicle.leagueDisplayName,
                color: AppColors.neonGreen,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                current == null
                    ? '내 순위는 검증 주행 후 표시됩니다.'
                    : '#${current.rank} · ${formatter.format(current.score)}점',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '공개 항목: 닉네임, 티어, 점수, 차급, 연료 리그',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: '상위 랭커'),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in topEntries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _RankingDetailCard(entry: entry),
          ),
        const SectionHeader(title: '내 주변 순위'),
        const SizedBox(height: AppSpacing.sm),
        if (nearby.isEmpty)
          const EmptyStateView(
            title: '주변 순위가 아직 없어요',
            message: '내 리그 랭킹 표본이 늘어나면 바로 위아래 순위가 표시됩니다.',
          )
        else
          for (final entry in nearby)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _RankingDetailCard(entry: entry),
            ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('공개 제한', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '정확한 위치와 상세 주행 경로는 랭킹 상세에 표시하지 않습니다.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: '배틀 만들기',
          icon: Icons.sports_mma_rounded,
          onPressed: () => context.go('/battle/create'),
        ),
      ],
    );
  }
}

class _RankingDetailCard extends StatelessWidget {
  const _RankingDetailCard({required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern();
    final topThree = entry.rank <= 3;
    return AppCard(
      borderColor: entry.isCurrentUser
          ? AppColors.neonGreen.withValues(alpha: 0.35)
          : topThree
              ? AppColors.gold.withValues(alpha: 0.24)
              : null,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              '#${entry.rank}',
              style: AppTypography.titleMedium.copyWith(
                color: topThree ? AppColors.gold : AppColors.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.nickname,
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    if (entry.isCurrentUser) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const StatusChip(label: '나', color: AppColors.neonGreen),
                    ],
                  ],
                ),
                Text(
                  '${entry.tier} · ${entry.vehicleClass} · ${FuelLeague.nameForKey(entry.leagueKey)}',
                  style: AppTypography.dataUnit,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(entry.score),
                style: AppTypography.titleMedium
                    .copyWith(color: AppColors.neonGreen),
              ),
              RankingChangeChip(
                rank: entry.rank,
                previousRank: entry.previousRank,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

RankingEntry? _currentEntry(List<RankingEntry> rankings) {
  for (final entry in rankings) {
    if (entry.isCurrentUser) {
      return entry;
    }
  }
  return null;
}

List<RankingEntry> _nearbyEntries(
  List<RankingEntry> rankings,
  RankingEntry? current,
) {
  if (current == null) {
    return rankings.skip(3).take(3).toList();
  }
  final nearby = rankings
      .where((entry) => (entry.rank - current.rank).abs() <= 2)
      .toList()
    ..sort((a, b) => a.rank.compareTo(b.rank));
  return nearby;
}
