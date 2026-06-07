import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../shared/providers/repository_providers.dart';
import '../shared/widgets/widgets.dart';

class AuthRequiredRoute extends ConsumerWidget {
  const AuthRequiredRoute({
    super.key,
    this.requireConsent = true,
    required this.child,
  });

  final bool requireConsent;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(restoredSessionProvider);
    return session.when(
      loading: () => const AppScaffold(
        scrollable: false,
        child: Center(child: LoadingSkeletonView(lines: 4)),
      ),
      error: (error, stackTrace) => AppScaffold(
        scrollable: false,
        child: Center(
          child: ErrorStateView(
            message: '세션 상태를 확인하지 못했어요.',
            onRetry: () => ref.invalidate(restoredSessionProvider),
          ),
        ),
      ),
      data: (value) {
        if (value.user == null) {
          return const _LoginRequiredView();
        }
        if (requireConsent && !value.consentCompleted) {
          return const _ConsentRequiredView();
        }
        return child;
      },
    );
  }
}

class AdminRequiredRoute extends ConsumerWidget {
  const AdminRequiredRoute({
    super.key,
    this.requireConsent = true,
    required this.child,
  });

  final bool requireConsent;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(restoredSessionProvider);
    return session.when(
      loading: () => const AppScaffold(
        scrollable: false,
        child: Center(child: LoadingSkeletonView(lines: 4)),
      ),
      error: (error, stackTrace) => AppScaffold(
        scrollable: false,
        child: Center(
          child: ErrorStateView(
            message: '관리자 권한을 확인하지 못했어요.',
            onRetry: () => ref.invalidate(restoredSessionProvider),
          ),
        ),
      ),
      data: (value) {
        final user = value.user;
        if (user == null) {
          return const _LoginRequiredView();
        }
        if (requireConsent && !value.consentCompleted) {
          return const _ConsentRequiredView();
        }
        if (user.isAdmin) {
          return child;
        }
        return const _AdminRequiredView();
      },
    );
  }
}

class _ConsentRequiredView extends StatelessWidget {
  const _ConsentRequiredView();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      child: Center(
        child: AppCard(
          borderColor: AppColors.neonGreen.withValues(alpha: 0.28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusChip(
                label: '필수 동의 필요',
                icon: Icons.verified_user_rounded,
                color: AppColors.neonGreen,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '연비 경쟁을 시작하기 전에 필수 동의가 필요해요',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '약관, 개인정보, 위치 기반 주행 검증 동의를 완료한 뒤 홈, 주행, 배틀, 랭킹 화면을 이용할 수 있어요.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: '동의 화면으로 이동',
                icon: Icons.fact_check_rounded,
                onPressed: () => context.go('/consent'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: '로그인 화면으로 돌아가기',
                icon: Icons.login_rounded,
                onPressed: () => context.go('/auth/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminRequiredView extends StatelessWidget {
  const _AdminRequiredView();

  @override
  Widget build(BuildContext context) {
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
                label: '관리자 권한 필요',
                icon: Icons.admin_panel_settings_rounded,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '운영 대시보드는 관리자만 이용할 수 있어요',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '차량 카탈로그, 신고, 개인정보 요청, 정산 데이터는 관리자 계정에서만 열립니다.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: '홈으로 이동',
                icon: Icons.home_rounded,
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: '고객지원으로 문의',
                icon: Icons.support_agent_rounded,
                onPressed: () => context.go('/support'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginRequiredView extends StatelessWidget {
  const _LoginRequiredView();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      child: Center(
        child: AppCard(
          borderColor: AppColors.neonGreen.withValues(alpha: 0.28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusChip(
                label: '로그인 필요',
                icon: Icons.lock_rounded,
                color: AppColors.neonGreen,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Google 로그인 후 이용할 수 있어요',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '랭킹, 배틀, 주행 기록, 보상은 계정과 차량 리그 기준으로 연결됩니다.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: '로그인 화면으로 이동',
                icon: Icons.login_rounded,
                onPressed: () => context.go('/auth/login'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: '처음 화면으로 돌아가기',
                icon: Icons.home_rounded,
                onPressed: () => context.go('/splash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
