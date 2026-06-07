import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;
  Object? _restoreError;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), _restoreAndRoute);
  }

  Future<void> _restoreAndRoute() async {
    if (!mounted) {
      return;
    }
    setState(() => _restoreError = null);
    try {
      final session = await ref.read(appSessionServiceProvider).restore();
      if (!mounted) {
        return;
      }
      if (session.user == null) {
        context.go(session.onboardingCompleted ? '/auth/login' : '/onboarding');
        return;
      }
      if (!session.consentCompleted) {
        context.go('/consent');
        return;
      }
      if (session.hasActiveDrive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('진행 중이던 주행을 복구했어요')),
        );
        context.go('/drive/safety');
        return;
      }
      context.go('/home');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _restoreError = error);
    }
  }

  void _retryRestore() {
    _timer?.cancel();
    unawaited(_restoreAndRoute());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_restoreError != null) {
      return AppScaffold(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.xl),
            const _SplashBrandMark(
              outerSize: 176,
              middleSize: 128,
              imageSize: 96,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppConstants.appName.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.neonGreen,
                fontStyle: FontStyle.italic,
                shadows: [
                  Shadow(
                    color: AppColors.neonGreen.withValues(alpha: 0.55),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ErrorStateView(
              message: '앱 시작 상태를 확인하지 못했어요.',
              onRetry: _retryRestore,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(AppConstants.slogan, style: AppTypography.labelCaps),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      );
    }

    return AppScaffold(
      scrollable: false,
      child: Column(
        children: [
          const Spacer(),
          const _SplashBrandMark(
            outerSize: 280,
            middleSize: 206,
            imageSize: 152,
          ),
          Text(
            AppConstants.appName.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.neonGreen,
              fontStyle: FontStyle.italic,
              shadows: [
                Shadow(
                  color: AppColors.neonGreen.withValues(alpha: 0.55),
                  blurRadius: 24,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PulseDot(),
              SizedBox(width: AppSpacing.sm),
              _PulseDot(),
              SizedBox(width: AppSpacing.sm),
              _PulseDot(),
            ],
          ),
          const Spacer(),
          Text(AppConstants.slogan, style: AppTypography.labelCaps),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SplashBrandMark extends StatelessWidget {
  const _SplashBrandMark({
    required this.outerSize,
    required this.middleSize,
    required this.imageSize,
  });

  final double outerSize;
  final double middleSize;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.neonGreen.withValues(alpha: 0.18),
              ),
            ),
          ),
          Container(
            width: middleSize,
            height: middleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.neonGreen.withValues(alpha: 0.16),
              ),
            ),
          ),
          Image.asset(
            'assets/brand/fuel_arena_mark.png',
            width: imageSize,
            height: imageSize,
            semanticLabel: 'Fuel Arena',
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.neonGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppColors.neonGreen, blurRadius: 12),
        ],
      ),
    );
  }
}
