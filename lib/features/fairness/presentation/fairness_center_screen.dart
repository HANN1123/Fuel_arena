import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class FairnessCenterScreen extends ConsumerWidget {
  const FairnessCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '공정성 센터', showBack: true),
      child: FutureBuilder<List<String>>(
        future: ref.watch(fairnessRepositoryProvider).getGuidelines(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingSkeletonView(lines: 5);
          }
          if (snapshot.hasError) {
            return ErrorStateView(
              message: '공정성 기준을 불러오지 못했어요.',
              onRetry: () => ref.invalidate(fairnessRepositoryProvider),
            );
          }
          final items = snapshot.data ?? const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('점수는 공정하게,\n위치는 안전하게',
                  style: AppTypography.displayScore
                      .copyWith(color: AppColors.electricBlue)),
              const SizedBox(height: AppSpacing.sm),
              Text('가솔린, 디젤, 하이브리드, 전기차, LPG, 플러그인 하이브리드 리그를 분리해 랭킹을 계산합니다.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.onSurfaceMuted)),
              const SizedBox(height: AppSpacing.xl),
              const AppCard(
                borderColor: AppColors.neonGreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(
                        label: '리그 분리',
                        color: AppColors.neonGreen,
                        icon: Icons.leaderboard_rounded),
                    SizedBox(height: AppSpacing.md),
                    Text('연료 타입 먼저, 차급은 그다음', style: AppTypography.titleMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text('같은 연료 리그와 차급끼리 우선 비교하고, 다른 리그와의 배틀은 친선전으로 기록합니다.',
                        style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: EmptyStateView(
                    title: '공정성 기준을 확인할 수 없어요',
                    message: '운영 정책이 공개되면 이곳에서 리그와 검증 기준을 확인할 수 있습니다.',
                  ),
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified_user_rounded,
                              color: AppColors.neonGreen),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                              child:
                                  Text(item, style: AppTypography.bodyMedium)),
                        ],
                      ),
                    ),
                  ),
                ),
              const AppCard(
                borderColor: AppColors.amber,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(
                        label: '검토 요청 가능',
                        color: AppColors.amber,
                        icon: Icons.fact_check_rounded),
                    SizedBox(height: AppSpacing.md),
                    Text('점수 반영 보류 기록이 있다면 검토를 요청할 수 있어요',
                        style: AppTypography.titleMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                        '공격적인 표현 없이 기록 상태와 검증 기준을 설명하고, 사용자가 이의를 제출할 수 있는 흐름을 제공합니다.',
                        style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: '검토 요청하기',
                icon: Icons.fact_check_rounded,
                onPressed: () => context.go('/support/review-request'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                borderColor: AppColors.electricBlue.withValues(alpha: 0.28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusChip(
                        label: '위치 비공개',
                        color: AppColors.electricBlue,
                        icon: Icons.location_off_rounded),
                    const SizedBox(height: AppSpacing.md),
                    Text('공개 랭킹에는 정확한 좌표를 표시하지 않아요',
                        style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                        '검증에는 주행 신호를 사용하지만, 공개 화면에는 닉네임, 리그, 차급, 점수 중심으로만 보여줍니다.',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.onSurfaceMuted)),
                    const SizedBox(height: AppSpacing.md),
                    SecondaryButton(
                        label: '부정 기록 신고',
                        icon: Icons.flag_rounded,
                        onPressed: () => context.go('/support/report')),
                    const SizedBox(height: AppSpacing.sm),
                    SecondaryButton(
                        label: '개인정보 설정',
                        icon: Icons.privacy_tip_rounded,
                        onPressed: () => context.go('/settings/privacy')),
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
