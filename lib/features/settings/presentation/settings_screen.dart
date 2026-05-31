import 'package:flutter/material.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/widgets/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '설정', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('시스템 설정', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.lg),
          const AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.notifications_rounded),
                  title: Text('알림 설정'),
                  subtitle: Text('랭킹, 배틀, 시즌 알림'),
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.security_rounded),
                  title: Text('권한과 데이터'),
                  subtitle: Text('위치 권한 및 데이터 활용 동의 관리'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
