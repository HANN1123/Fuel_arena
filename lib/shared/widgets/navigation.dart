import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_typography.dart';

class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDim.withValues(alpha: 0.96),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppLayout.bottomNavHeight,
          child: Row(
            children: [
              _BottomNavItem(
                icon: Icons.dashboard_rounded,
                label: '홈',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _BottomNavItem(
                icon: Icons.sports_mma_rounded,
                label: '배틀',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _BottomNavItem(
                icon: Icons.leaderboard_rounded,
                label: '랭킹',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _BottomNavItem(
                icon: Icons.emoji_events_rounded,
                label: '시즌',
                selected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _BottomNavItem(
                icon: Icons.person_rounded,
                label: '프로필',
                selected: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.neonGreen : AppColors.onSurface;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.neonGreen.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, color: color, size: AppIconSize.sm),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: AppTypography.dataUnit.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
