import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../shared/widgets/widgets.dart';
import 'bootstrap.dart';
import 'router.dart';
import 'theme.dart';

class FuelArenaApp extends StatelessWidget {
  const FuelArenaApp({
    super.key,
    required this.bootstrap,
  });

  final BootstrapResult bootstrap;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fuel Arena',
      debugShowCheckedModeBanner: false,
      theme: FuelArenaTheme.dark,
      routerConfig: bootstrap.canStartApp
          ? appRouter
          : configurationErrorRouter(bootstrap),
    );
  }
}

Widget configurationErrorScreen(BootstrapResult bootstrap) {
  return AppScaffold(
    scrollable: false,
    child: Center(
      child: AppCard(
        borderColor: AppColors.error.withValues(alpha: 0.35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StatusChip(
              label: '설정 오류',
              color: AppColors.error,
              icon: Icons.error_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('앱을 시작할 수 없어요', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              bootstrap.configurationError ?? '환경 설정을 확인해 주세요.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _configurationRecoveryHint(bootstrap),
              style:
                  AppTypography.dataUnit.copyWith(color: AppColors.neonGreen),
            ),
          ],
        ),
      ),
    ),
  );
}

String _configurationRecoveryHint(BootstrapResult bootstrap) {
  if (bootstrap.config.isDev) {
    return '개발 모드는 Supabase 없이 로컬 저장소로 실행할 수 있습니다.';
  }
  return '운영/스테이징 빌드는 .env.production 또는 --dart-define 값과 Supabase/Google 콘솔 설정을 확인해야 합니다.';
}

GoRouter configurationErrorRouter(BootstrapResult bootstrap) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => configurationErrorScreen(bootstrap),
      ),
    ],
  );
}
