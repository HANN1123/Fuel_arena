import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  static const _tabs = ['전체', '차종', '지역', '연료', '친구', '크루'];
  var _selected = '전체';

  @override
  Widget build(BuildContext context) {
    final rankings = ref.watch(rankingEntriesProvider(_selected));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.mobileMargin, AppSpacing.md, AppSpacing.mobileMargin, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('랭킹', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
            const SizedBox(height: AppSpacing.xs),
            Text('같은 클래스 운전자들과 공정하게 겨룹니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
            const SizedBox(height: AppSpacing.lg),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.map((tab) {
                  final active = tab == _selected;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      selected: active,
                      label: Text(tab),
                      onSelected: (_) => setState(() => _selected = tab),
                      selectedColor: AppColors.neonGreen.withOpacity(0.18),
                      backgroundColor: AppColors.surfaceLow,
                      labelStyle: TextStyle(color: active ? AppColors.neonGreen : AppColors.onSurface),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: rankings.when(
                loading: () => const LoadingSkeletonView(lines: 5),
                error: (error, stackTrace) => const ErrorStateView(message: '랭킹을 불러오지 못했어요.'),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStateView(
                      title: '아직 랭킹이 없어요',
                      message: '검증된 주행 기록이 생기면 랭킹이 표시됩니다.',
                    );
                  }
                  final currentUser = items.firstWhere((entry) => entry.isCurrentUser);
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) => _RankingTile(entry: items[index]),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _RankingTile(entry: currentUser, pinned: true),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({
    required this.entry,
    this.pinned = false,
  });

  final RankingEntry entry;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final topThree = entry.rank <= 3;
    return AppCard(
      borderColor: entry.isCurrentUser
          ? AppColors.neonGreen.withOpacity(0.35)
          : topThree
              ? AppColors.gold.withOpacity(0.3)
              : null,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              '#${entry.rank}',
              style: AppTypography.titleMedium.copyWith(color: topThree ? AppColors.gold : AppColors.onSurface),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(entry.nickname, style: AppTypography.titleMedium)),
                    if (entry.isCurrentUser) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const StatusChip(label: '나', color: AppColors.neonGreen),
                    ],
                  ],
                ),
                Text('${entry.tier} · ${entry.vehicleClass} · ${entry.fuelType}', style: AppTypography.dataUnit),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(NumberFormat.decimalPattern().format(entry.score), style: AppTypography.titleMedium.copyWith(color: AppColors.neonGreen)),
              RankingChangeChip(rank: entry.rank, previousRank: entry.previousRank),
            ],
          ),
          if (!entry.isCurrentUser && !pinned) ...[
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.sports_mma_rounded, color: AppColors.electricBlue),
          ],
        ],
      ),
    );
  }
}
