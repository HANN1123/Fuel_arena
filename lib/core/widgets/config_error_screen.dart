import 'package:flutter/material.dart';

import '../../app/bootstrap.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_typography.dart';
import '../../shared/widgets/widgets.dart';

class ConfigErrorScreen extends StatelessWidget {
  const ConfigErrorScreen({
    super.key,
    required this.bootstrap,
    this.recoveryHint,
  });

  final BootstrapResult bootstrap;
  final String? recoveryHint;

  @override
  Widget build(BuildContext context) {
    final config = bootstrap.config;
    final exception = bootstrap.configurationException;
    final showDebugPanel = !config.isProduction && exception != null;

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
                exception?.userMessage ??
                    (config.isProduction
                        ? '서버 설정에 문제가 있어요. 잠시 후 다시 시도해주세요.'
                        : bootstrap.configurationError ?? '환경 설정을 확인해 주세요.'),
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                recoveryHint ?? _configurationRecoveryHint(bootstrap),
                style:
                    AppTypography.dataUnit.copyWith(color: AppColors.neonGreen),
              ),
              if (showDebugPanel) ...[
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Text('개발자 확인 항목', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  exception.developerMessage,
                  style: AppTypography.dataUnit
                      .copyWith(color: AppColors.onSurfaceMuted),
                ),
                if (exception.missingKeys.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    exception.missingKeys.join(', '),
                    style:
                        AppTypography.dataUnit.copyWith(color: AppColors.amber),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _configurationRecoveryHint(BootstrapResult bootstrap) {
  if (bootstrap.config.isDev) {
    return '로컬 확인 환경은 Supabase 연결 없이도 기본 흐름을 볼 수 있습니다.';
  }
  return '운영/스테이징 빌드는 .env.production 또는 --dart-define 값과 Supabase/Google 콘솔 설정을 확인해야 합니다.';
}
