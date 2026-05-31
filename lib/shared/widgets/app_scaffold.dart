import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_typography.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.mobileMargin,
      vertical: AppSpacing.md,
    ),
    this.scrollable = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final EdgeInsets padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: child,
    );

    return Scaffold(
      extendBody: true,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          const Positioned.fill(child: _TechBackground()),
          SafeArea(
            child: scrollable
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: content,
                  )
                : content,
          ),
        ],
      ),
    );
  }
}

class FuelArenaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FuelArenaAppBar({
    super.key,
    this.title = 'FUEL ARENA',
    this.subtitle,
    this.showBack = false,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBack
          ? IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : null,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.neonGreen,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppTypography.dataUnit,
            ),
        ],
      ),
      actions: [
        if (trailing != null) Padding(padding: const EdgeInsets.only(right: 12), child: trailing),
      ],
    );
  }
}

class _TechBackground extends StatelessWidget {
  const _TechBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        gradient: RadialGradient(
          center: const Alignment(-0.8, -0.6),
          radius: 1.4,
          colors: [
            AppColors.neonGreen.withOpacity(0.08),
            AppColors.background,
          ],
        ),
      ),
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    const gap = 36.0;
    for (var x = 0.0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
