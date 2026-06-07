import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) {
      return;
    }
    setState(() => _signingOut = true);
    try {
      await ref.read(appSessionServiceProvider).signOut();
      invalidateUserScopedSessionProviders(ref);
      if (!mounted) {
        return;
      }
      setState(() => _signingOut = false);
      context.go('/auth/login');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃을 완료하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '설정', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '앱 설정',
            style:
                AppTypography.displayScore.copyWith(color: AppColors.neonGreen),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_rounded,
                  title: '알림 설정',
                  subtitle: '랭킹, 배틀, 시즌 알림',
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.security_rounded,
                  title: '권한과 데이터',
                  subtitle: '개인정보, 위치정보, 데이터 요청 관리',
                  onTap: () => context.push('/settings/privacy'),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.directions_car_rounded,
                  title: '차량 관리',
                  subtitle: '대표 차량, 연료 리그, 차급 설정',
                  onTap: () => context.push('/settings/vehicles'),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.ads_click_rounded,
                  title: '광고 설정',
                  subtitle: '맞춤형 광고와 보상형 광고 동의 관리',
                  onTap: () => context.push('/settings/ads'),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.shield_rounded,
                  title: '안전 모드',
                  subtitle: '주행 중 광고와 알림 차단 설정',
                  onTap: () => context.push('/settings/safety'),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.support_agent_rounded,
                  title: '고객지원과 신고',
                  subtitle: '문의, 신고, 이의제기',
                  onTap: () => context.push('/support'),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: '로그아웃',
                  subtitle:
                      _signingOut ? '세션을 종료하고 있어요' : '현재 세션을 종료하고 로그인 화면으로 이동',
                  trailing: _signingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _signingOut ? null : _signOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
