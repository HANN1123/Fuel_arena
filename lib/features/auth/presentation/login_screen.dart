import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  var _loading = false;
  String? _error;
  String? _status;

  String _nextRouteAfterLogin(UserProfile user) {
    if (!user.consentCompleted) {
      return '/consent';
    }
    if (!user.vehicleSetupCompleted) {
      return '/setup';
    }
    return '/home';
  }

  Future<void> _trackAuthEvent(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) async {
    try {
      await ref
          .read(analyticsRepositoryProvider)
          .track(eventName, properties: properties);
    } catch (_) {}
  }

  Future<void> _identifyLoginUser(UserProfile user) async {
    try {
      await ref
          .read(analyticsRepositoryProvider)
          .identify(user.id, properties: {'auth_provider': 'google'});
    } catch (_) {}
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
      _status = null;
    });

    try {
      await _trackAuthEvent('google_login_started');
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      await ref.read(appSessionServiceProvider).rememberLogin(user);
      ref.invalidate(restoredSessionProvider);
      await _identifyLoginUser(user);
      await _trackAuthEvent('google_login_succeeded');
      if (!mounted) {
        return;
      }
      context.go(_nextRouteAfterLogin(user));
    } on AuthRedirectInProgressException catch (event) {
      if (!mounted) {
        return;
      }
      await _trackAuthEvent('google_login_redirect_started');
      if (!mounted) {
        return;
      }
      setState(() {
        _status = event.toString();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = const ErrorMapper().messageFor(error);
        _status = null;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final authRepository = ref.watch(authRepositoryProvider);
    final needsGoogleConfig =
        !config.isDev && !authRepository.isGoogleAuthConfigured();

    return AppScaffold(
      scrollable: true,
      child: Center(
        child: AppCard(
          glowColor: AppColors.neonGreen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FUEL ARENA',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.neonGreen,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('연비로 증명해', style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Google 계정으로 시작하고, 나중에 차량을 설정해 리그에 참가하세요.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Google로 시작하기',
                icon: Icons.login_rounded,
                isLoading: _loading,
                onPressed: needsGoogleConfig ? null : _loginWithGoogle,
              ),
              if (needsGoogleConfig || _error != null || _status != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  needsGoogleConfig
                      ? 'Google 로그인 설정이 필요합니다.'
                      : _error ?? _status!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: _error != null || needsGoogleConfig
                        ? AppColors.error
                        : AppColors.neonGreen,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                '로그인 후 필수 동의 화면에서 약관과 개인정보 처리방침 동의를 확정합니다.',
                style: AppTypography.dataUnit
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '가입 전 문서를 먼저 확인할 수 있어요.',
                style: AppTypography.dataUnit
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: const [
                  _LegalLink(
                    label: '약관 보기',
                    icon: Icons.description_rounded,
                    route: '/legal/terms',
                  ),
                  _LegalLink(
                    label: '개인정보 보기',
                    icon: Icons.privacy_tip_rounded,
                    route: '/legal/privacy',
                  ),
                  _LegalLink(
                    label: '위치정보 보기',
                    icon: Icons.location_on_rounded,
                    route: '/legal/location',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '차량 설정은 로그인 후 추가 설정에서 진행합니다.',
                style: AppTypography.dataUnit
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.electricBlue,
      ),
      onPressed: () => GoRouter.of(context).push(route),
      icon: Icon(icon, size: 16),
      label: Text(label, style: AppTypography.dataUnit),
    );
  }
}
