import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF141313);
  static const surfaceDim = Color(0xFF0F0E0E);
  static const surfaceLow = Color(0xFF1C1B1B);
  static const surface = Color(0xFF201F1F);
  static const surfaceHigh = Color(0xFF2B2A2A);
  static const surfaceHighest = Color(0xFF363434);
  static const surfaceVariant = Color(0xFF3C4B35);

  static const onSurface = Color(0xFFE6E1E1);
  static const onSurfaceMuted = Color(0xFFBACCB0);
  static const outline = Color(0xFF85967C);

  static const primary = Color(0xFFEFFFE3);
  static const neonGreen = Color(0xFF79FF5B);
  static const neonGreenDim = Color(0xFF2AE500);
  static const neonGreenContainer = Color(0xFF39FF14);
  static const onPrimary = Color(0xFF053900);

  static const electricBlue = Color(0xFF00DAF8);
  static const electricBlueSoft = Color(0xFFA5EEFF);
  static const onBlue = Color(0xFF001F25);

  static const amber = Color(0xFFFFD88A);
  static const gold = Color(0xFFFFD45A);
  static const danger = Color(0xFFFF6B6B);
  static const error = Color(0xFFFFB4AB);

  static const transparentWhite = Color(0x12FFFFFF);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [electricBlue, neonGreen],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static LinearGradient get surfaceGradient => const LinearGradient(
        colors: [surfaceHigh, surfaceLow],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
