import 'package:flutter/material.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/widgets/widgets.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '고급 통계', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('숫자로 보는\n나의 주행 스타일', style: AppTypography.displayScore.copyWith(color: AppColors.electricBlue)),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            children: [
              Expanded(child: StatMetricCard(label: '평균 연비', value: '17.8', unit: 'km/l')),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: StatMetricCard(label: '안정 점수', value: '88', unit: '점', color: AppColors.electricBlue)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const LockedPremiumCard(
            title: '라이벌 분석 잠금',
            description: '프리미엄에서 라이벌 대비 강점과 약점을 확인할 수 있습니다.',
          ),
        ],
      ),
    );
  }
}
