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

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  static const _tabs = [
    '전체',
    '내 리그',
    '가솔린',
    '디젤',
    '하이브리드',
    '전기차',
    'LPG',
    '차급',
    '지역',
    '친구',
    '크루'
  ];
  var _selected = '내 리그';
  var _restored = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final restored = await ref
          .read(localStateServiceProvider)
          .getString('recent_ranking_filter', fallback: '내 리그');
      if (mounted && _tabs.contains(restored)) {
        setState(() {
          _selected = restored;
          _restored = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rankings = ref.watch(rankingEntriesProvider(_selected));
    final primaryVehicle = ref.watch(primaryVehicleProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.mobileMargin, AppSpacing.md, AppSpacing.mobileMargin, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('랭킹',
              style: AppTypography.displayScore
                  .copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.xs),
          Text('내 리그와 연료 리그별 순위를 분리해 비교합니다',
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
                  message: '리그와 점수 계산을 위해 먼저 차량을 선택해주세요.',
                  actionLabel: '차량 설정하기',
                  onAction: () => context.go('/setup/vehicle'),
                );
              }
              return AppCard(
                child: Text(
                  '내 차량은 ${vehicle.leagueDisplayName}에 배정됐어요.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.neonGreen),
                ),
              );
            },
          ),
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
                    onSelected: (_) async {
                      setState(() => _selected = tab);
                      await ref
                          .read(localStateServiceProvider)
                          .saveRecentRankingFilter(tab);
                      await ref
                          .read(analyticsRepositoryProvider)
                          .track('ranking_viewed', properties: {'scope': tab});
                    },
                    selectedColor: AppColors.neonGreen.withValues(alpha: 0.18),
                    backgroundColor: AppColors.surfaceLow,
                    labelStyle: TextStyle(
                        color:
                            active ? AppColors.neonGreen : AppColors.onSurface),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_restored && _selected != '내 리그') ...[
            Text('최근 선택한 $_selected 필터를 복구했어요.',
                style: AppTypography.dataUnit
                    .copyWith(color: AppColors.neonGreen)),
            const SizedBox(height: AppSpacing.sm),
          ],
          Expanded(
            child: primaryVehicle.maybeWhen(
              data: (vehicle) => vehicle == null
                  ? const SizedBox.shrink()
                  : rankings.when(
                      loading: () => const LoadingSkeletonView(lines: 5),
                      error: (error, stackTrace) =>
                          const ErrorStateView(message: '랭킹을 불러오지 못했어요.'),
                      data: (items) {
                        if (items.isEmpty) {
                          return const EmptyStateView(
                            title: '아직 랭킹이 없어요',
                            message: '검증된 주행 기록이 생기면 랭킹이 표시됩니다.',
                          );
                        }
                        final currentUsers = items
                            .where((entry) => entry.isCurrentUser)
                            .toList();
                        return Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) =>
                                    _RankingTile(entry: items[index]),
                              ),
                            ),
                            if (currentUsers.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              _RankingTile(
                                  entry: currentUsers.first, pinned: true),
                            ],
                          ],
                        );
                      },
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
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
    final canOpenProfile = entry.userId.isNotEmpty;
    return GestureDetector(
      onTap:
          canOpenProfile ? () => context.go('/profile/${entry.userId}') : null,
      child: AppCard(
        borderColor: entry.isCurrentUser
            ? AppColors.neonGreen.withValues(alpha: 0.35)
            : topThree
                ? AppColors.gold.withValues(alpha: 0.3)
                : null,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                '#${entry.rank}',
                style: AppTypography.titleMedium.copyWith(
                    color: topThree ? AppColors.gold : AppColors.onSurface),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                          child: Text(entry.nickname,
                              style: AppTypography.titleMedium)),
                      if (entry.isCurrentUser) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const StatusChip(
                            label: '나', color: AppColors.neonGreen),
                      ],
                    ],
                  ),
                  Text(
                      '${entry.tier} · ${entry.vehicleClass} · ${FuelLeague.nameForKey(entry.leagueKey)}',
                      style: AppTypography.dataUnit),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(NumberFormat.decimalPattern().format(entry.score),
                    style: AppTypography.titleMedium
                        .copyWith(color: AppColors.neonGreen)),
                RankingChangeChip(
                    rank: entry.rank, previousRank: entry.previousRank),
              ],
            ),
            if (canOpenProfile && !pinned) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.person_search_rounded,
                  color: AppColors.electricBlue),
            ],
          ],
        ),
      ),
    );
  }
}
