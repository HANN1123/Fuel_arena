import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          final items = snapshot.data ?? const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('점수는 공정하게,\n위치는 안전하게', style: AppTypography.displayScore.copyWith(color: AppColors.electricBlue)),
              const SizedBox(height: AppSpacing.sm),
              Text('차종, 연료 타입, 동급 대비 퍼센타일을 반영해 랭킹을 계산합니다.', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
              const SizedBox(height: AppSpacing.xl),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppColors.neonGreen),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(item, style: AppTypography.bodyMedium)),
                      ],
                    ),
                  ),
                ),
              ),
              const LockedPremiumCard(
                title: '비정상 기록 이의 제기',
                description: '검증 센터와 이의 제기 워크플로우는 다음 단계에서 연결됩니다.',
              ),
            ],
          );
        },
      ),
    );
  }
}
