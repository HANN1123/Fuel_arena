import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.notifications_rounded),
                  title: Text('알림 설정'),
                  subtitle: Text('랭킹, 배틀, 시즌 알림'),
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.security_rounded),
                  title: Text('권한과 데이터'),
                  subtitle: Text('위치 권한 및 데이터 활용 동의 관리'),
                  onTap: () => context.push('/settings/privacy'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.directions_car_rounded),
                  title: const Text('차량 관리'),
                  subtitle: const Text('대표 차량 변경, 차량 추가, 삭제 요청'),
                  onTap: () => context.push('/settings/vehicles'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.ads_click_rounded),
                  title: const Text('광고 설정'),
                  subtitle: const Text('맞춤형 광고와 보상형 광고 동의 관리'),
                  onTap: () => context.push('/settings/ads'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.shield_rounded),
                  title: const Text('안전 모드'),
                  subtitle: const Text('주행 중 광고와 알림 차단 설정'),
                  onTap: () => context.push('/settings/safety'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('로그아웃'),
                  subtitle: const Text('mock 세션을 종료하고 로그인 화면으로 이동'),
                  onTap: () => context.go('/auth/login'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
