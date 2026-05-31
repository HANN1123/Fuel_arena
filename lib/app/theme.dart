import 'package:flutter/material.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_typography.dart';

abstract final class FuelArenaTheme {
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.neonGreen,
      brightness: Brightness.dark,
      primary: AppColors.neonGreen,
      secondary: AppColors.electricBlue,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme.copyWith(
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        primary: AppColors.neonGreen,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.electricBlue,
        onSecondary: AppColors.onBlue,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTypography.fontFamily,
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        headlineLarge: AppTypography.displayScore,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        labelLarge: AppTypography.labelCaps,
        labelMedium: AppTypography.dataUnit,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.onSurface,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: const BorderSide(color: AppColors.transparentWhite),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: UnderlineInputBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.md),
          ),
          borderSide: const BorderSide(color: AppColors.electricBlue),
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.md),
          ),
          borderSide: const BorderSide(color: AppColors.electricBlue),
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.md),
          ),
          borderSide: const BorderSide(color: AppColors.neonGreen),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.outline,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDim,
        selectedItemColor: AppColors.neonGreen,
        unselectedItemColor: AppColors.onSurfaceMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
