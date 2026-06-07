import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_typography.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.maxWidth = mobileMaxWidth,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.mobileMargin,
      vertical: AppSpacing.md,
    ),
    this.scrollable = true,
  });

  static const double mobileDesignWidth = AppLayout.mobileDesignWidth;
  static const double mobileMinWidth = AppLayout.mobileMinWidth;
  static const double mobileMaxWidth = AppLayout.mobileMaxWidth;
  static const double adminMinWidth = AppLayout.adminMinWidth;

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final double? maxWidth;
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
      appBar: appBar == null
          ? null
          : _WidthLimitedPreferredSize(
              maxWidth: maxWidth,
              child: appBar!,
            ),
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : _WidthLimitedBottomBar(
              maxWidth: maxWidth,
              child: bottomNavigationBar!,
            ),
      body: Stack(
        children: [
          const Positioned.fill(child: _TechBackground()),
          Positioned.fill(
            child: ResponsiveAppShell(
              maxWidth: maxWidth,
              child: scrollable
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: content,
                    )
                  : content,
            ),
          ),
        ],
      ),
    );
  }
}

class ResponsiveAppShell extends StatelessWidget {
  const ResponsiveAppShell({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  final double? maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (maxWidth == null) {
      return AdminViewportShell(child: child);
    }
    return MobileViewportShell(maxWidth: maxWidth!, child: child);
  }
}

class MobileViewportShell extends StatelessWidget {
  const MobileViewportShell({
    super.key,
    this.maxWidth = AppScaffold.mobileMaxWidth,
    this.minWidth = AppScaffold.mobileMinWidth,
    required this.child,
  });

  final double maxWidth;
  final double minWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = MediaQuery.sizeOf(context);
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : viewportSize.width;
        final viewportHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : viewportSize.height;
        final effectiveMaxWidth = maxWidth < minWidth ? minWidth : maxWidth;
        final width = viewportWidth > effectiveMaxWidth
            ? effectiveMaxWidth
            : viewportWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: viewportHeight,
            child: child,
          ),
        );
      },
    );
  }
}

class AdminViewportShell extends StatelessWidget {
  const AdminViewportShell({
    super.key,
    this.minWidth = AppScaffold.adminMinWidth,
    required this.child,
  });

  final double minWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minWidth) {
          return child;
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: minWidth,
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}

class _WidthLimitedBottomBar extends StatelessWidget {
  const _WidthLimitedBottomBar({
    required this.maxWidth,
    required this.child,
  });

  final double? maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (maxWidth == null) {
      return child;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _effectiveLimitedWidth(context, constraints, maxWidth!);
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(width: width, child: child),
        );
      },
    );
  }
}

class _WidthLimitedPreferredSize extends StatelessWidget
    implements PreferredSizeWidget {
  const _WidthLimitedPreferredSize({
    required this.maxWidth,
    required this.child,
  });

  final double? maxWidth;
  final PreferredSizeWidget child;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    if (maxWidth == null) {
      return child;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _effectiveLimitedWidth(context, constraints, maxWidth!);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: width, child: child),
        );
      },
    );
  }
}

double _effectiveLimitedWidth(
  BuildContext context,
  BoxConstraints constraints,
  double maxWidth,
) {
  final viewportWidth = constraints.maxWidth.isFinite
      ? constraints.maxWidth
      : MediaQuery.sizeOf(context).width;
  return viewportWidth > maxWidth ? maxWidth : viewportWidth;
}

class FuelArenaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FuelArenaAppBar({
    super.key,
    this.title = 'FUEL ARENA',
    this.subtitle,
    this.showBack = false,
    this.fallbackLocation = '/home',
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final String fallbackLocation;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBack
          ? IconButton(
              onPressed: () {
                final router = GoRouter.of(context);
                if (router.canPop()) {
                  router.pop();
                  return;
                }
                router.go(fallbackLocation);
              },
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
        if (trailing != null)
          Padding(padding: const EdgeInsets.only(right: 12), child: trailing),
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
            AppColors.neonGreen.withValues(alpha: 0.08),
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
      ..color = Colors.white.withValues(alpha: 0.025)
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
