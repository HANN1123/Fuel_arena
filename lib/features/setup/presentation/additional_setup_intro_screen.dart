import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/widgets/widgets.dart';

class AdditionalSetupIntroScreen extends StatelessWidget {
  const AdditionalSetupIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '추가 설정', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(
            label: '가입 완료',
            color: AppColors.neonGreen,
            icon: Icons.verified_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '이제 리그를 선택할\n차례예요',
            style:
                AppTypography.displayScore.copyWith(color: AppColors.neonGreen),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '차량을 설정하면 연료 리그와 차급에 맞는 경쟁에 자동 배정됩니다.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          const AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.rule_rounded, color: AppColors.electricBlue),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '전기차, 하이브리드, 가솔린, 디젤은 서로 다른 리그에서 경쟁합니다.',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: '차량 설정하기',
            icon: Icons.directions_car_rounded,
            onPressed: () => context.go('/setup/vehicle'),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: '나중에 할게요',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}
