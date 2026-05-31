import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 28,
      offset: Offset(0, 14),
    ),
  ];

  static const neonGreen = [
    BoxShadow(
      color: Color(0x5579FF5B),
      blurRadius: 24,
      spreadRadius: -6,
    ),
  ];

  static const electricBlue = [
    BoxShadow(
      color: Color(0x5500DAF8),
      blurRadius: 24,
      spreadRadius: -6,
    ),
  ];

  static BoxShadow glow(Color color) => BoxShadow(
        color: color.withOpacity(0.28),
        blurRadius: 22,
        spreadRadius: -5,
      );

  static const subtleBorder = BorderSide(color: AppColors.transparentWhite);
}
