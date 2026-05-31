import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';

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
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: AppColors.surfaceDim.withOpacity(0.96),
      indicatorColor: AppColors.neonGreen.withOpacity(0.16),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: '홈'),
        NavigationDestination(icon: Icon(Icons.sports_mma_rounded), label: '배틀'),
        NavigationDestination(icon: Icon(Icons.leaderboard_rounded), label: '랭킹'),
        NavigationDestination(icon: Icon(Icons.emoji_events_rounded), label: '시즌'),
        NavigationDestination(icon: Icon(Icons.person_rounded), label: '프로필'),
      ],
    );
  }
}
