import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/widgets/widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neonGreen.withOpacity(0.18)),
                  ),
                ),
                Container(
                  width: 206,
                  height: 206,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neonGreen.withOpacity(0.16)),
                  ),
                ),
                Text(
                  AppConstants.appName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.neonGreen,
                    fontStyle: FontStyle.italic,
                    shadows: [
                      Shadow(
                        color: AppColors.neonGreen.withOpacity(0.55),
                        blurRadius: 24,
                      ),
                    ],
                  ),
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
