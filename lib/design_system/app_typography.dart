import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const fontFamily = 'Sora';

  static const displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    height: 56 / 48,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    color: AppColors.onSurface,
  );

  static const displayScore = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.02,
    color: AppColors.onSurface,
  );

  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static const titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static const labelCaps = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.08,
    color: AppColors.onSurfaceMuted,
  );

  static const dataUnit = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurfaceMuted,
  );
}
