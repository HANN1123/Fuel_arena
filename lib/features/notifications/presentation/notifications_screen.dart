import 'package:flutter/material.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/widgets/widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '알림', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('경쟁 소식', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.lg),
          const EmptyStateView(
            title: '아직 새 알림이 없어요',
            message: '랭킹 추월, 배틀 결과, 시즌 미션 알림이 여기에 표시됩니다.',
          ),
        ],
      ),
    );
  }
}
