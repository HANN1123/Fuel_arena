import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_config.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class AuthDiagnosticsScreen extends ConsumerStatefulWidget {
  const AuthDiagnosticsScreen({super.key});

  @override
  ConsumerState<AuthDiagnosticsScreen> createState() =>
      _AuthDiagnosticsScreenState();
}

class _AuthDiagnosticsScreenState extends ConsumerState<AuthDiagnosticsScreen> {
  bool _loading = false;
  String? _message;
  bool _isError = false;

  String _maskClientId(String value) {
    if (value.isEmpty) return '설정되지 않음';
    const suffix = '.apps.googleusercontent.com';
    if (value.endsWith(suffix) && value.length > suffix.length) {
      final prefix = value.substring(0, value.length - suffix.length);
      if (prefix.length <= 6) {
        return '***...***$suffix';
      }
      return '${prefix.substring(0, 6)}...${prefix.substring(prefix.length - 2)}$suffix';
    }
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return '***';
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 2) {
      return '*@$domain';
    }
    return '${username.substring(0, 2)}***@$domain';
  }

  String _maskUserId(String id) {
    if (id.isEmpty) return '없음';
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }

  Future<void> _runGoogleLogin() async {
    setState(() {
      _loading = true;
      _message = null;
      _isError = false;
    });
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      await ref.read(appSessionServiceProvider).rememberLogin(user);
      invalidateUserScopedSessionProviders(ref);
      setState(() {
        _message = '로그인 성공: ${user.nickname}님 환영합니다.';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = '로그인 실패: $e';
        _isError = true;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshSession() async {
    setState(() {
      _loading = true;
      _message = null;
      _isError = false;
    });
    try {
      invalidateUserScopedSessionProviders(ref);
      // Wait for session recovery
      await ref.read(restoredSessionProvider.future);
      setState(() {
        _message = '세션이 새로고침되었습니다.';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = '세션 새로고침 실패: $e';
        _isError = true;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _loading = true;
      _message = null;
      _isError = false;
    });
    try {
      await ref.read(appSessionServiceProvider).signOut();
      invalidateUserScopedSessionProviders(ref);
      setState(() {
        _message = '로그아웃 성공';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = '로그아웃 실패: $e';
        _isError = true;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _copyDiagnostics(AppConfig config, String userStatus) {
    final diagnostics = '''
--- Fuel Arena Auth Diagnostics ---
APP_ENV: ${config.environment.name}
RepositoryMode: ${config.repositoryMode}
Supabase Configured: ${config.hasSupabase}
Google Web Client ID: ${_maskClientId(config.googleWebClientId)}
Google Android Client ID: ${_maskClientId(config.googleAndroidClientId)}
Google iOS Client ID: ${_maskClientId(config.googleIosClientId)}
Redirect Scheme: ${config.authRedirectScheme}
Redirect Host: ${config.authRedirectHost}
User Status: $userStatus
-----------------------------------
''';
    Clipboard.setData(ClipboardData(text: diagnostics));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('진단 결과가 클립보드에 복사되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);

    // Strict check: Block in production
    if (config.isProduction) {
      return const AppScaffold(
        scrollable: false,
        child: Center(
          child: Text('접근 권한이 없습니다.'),
        ),
      );
    }

    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.asData?.value;
    final userStatus = user != null
        ? '로그인됨 (ID: ${_maskUserId(user.id)}, 이메일: ${_maskEmail(user.email)}, 닉네임: ${user.nickname})'
        : '로그아웃됨';

    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '인증 진단', showBack: true),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '인증 개발자 진단',
            style:
                AppTypography.displayScore.copyWith(color: AppColors.neonGreen),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '이 화면은 dev/staging 모드에서만 접근 가능합니다. 민감한 정보(secrets, tokens)는 안전하게 마스킹됩니다.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_message != null) ...[
            AppCard(
              borderColor: _isError ? AppColors.error : AppColors.neonGreen,
              child: Text(
                _message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: _isError ? AppColors.error : AppColors.neonGreen,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('환경 (APP_ENV)', config.environment.name),
                const Divider(),
                _infoRow('저장소 모드 (RepositoryMode)', config.repositoryMode),
                const Divider(),
                _infoRow(
                    'Supabase 설정 여부', config.hasSupabase ? '설정됨' : '설정 안 됨'),
                const Divider(),
                _infoRow('Google Web Client ID',
                    _maskClientId(config.googleWebClientId)),
                const Divider(),
                _infoRow('Google Android Client ID',
                    _maskClientId(config.googleAndroidClientId)),
                const Divider(),
                _infoRow('Google iOS Client ID',
                    _maskClientId(config.googleIosClientId)),
                const Divider(),
                _infoRow('리다이렉트 URL',
                    '${config.authRedirectScheme}://${config.authRedirectHost}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('현재 사용자 정보', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('로그인 상태', user != null ? '로그인됨' : '로그아웃됨'),
                if (user != null) ...[
                  const Divider(),
                  _infoRow('사용자 ID (UID)', _maskUserId(user.id)),
                  const Divider(),
                  _infoRow('이메일', _maskEmail(user.email)),
                  const Divider(),
                  _infoRow('닉네임', user.nickname),
                  const Divider(),
                  _infoRow('가입 동의 완료 여부', user.consentCompleted ? '완료' : '미완료'),
                  const Divider(),
                  _infoRow(
                      '차량 설정 완료 여부', user.vehicleSetupCompleted ? '완료' : '미완료'),
                  const Divider(),
                  _infoRow(
                      '마지막 로그인', user.lastLoginAt?.toIso8601String() ?? '없음'),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            PrimaryButton(
              label: 'Google 로그인 테스트',
              icon: Icons.login_rounded,
              onPressed: _runGoogleLogin,
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: '세션 새로고침',
              icon: Icons.refresh_rounded,
              onPressed: _refreshSession,
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: '로그아웃 테스트',
              icon: Icons.logout_rounded,
              onPressed: _signOut,
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: '진단 결과 복사',
              icon: Icons.copy_rounded,
              onPressed: () => _copyDiagnostics(config, userStatus),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.dataUnit
                  .copyWith(color: AppColors.onSurfaceMuted),
            ),
          ),
        ],
      ),
    );
  }
}
