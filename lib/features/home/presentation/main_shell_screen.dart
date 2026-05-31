import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../battle/presentation/battle_screen.dart';
import '../../ranking/presentation/ranking_screen.dart';
import '../../season/presentation/season_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'home_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late var _index = widget.initialIndex;

  static const _screens = [
    HomeScreen(),
    BattleScreen(),
    RankingScreen(),
    SeasonScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      padding: EdgeInsets.zero,
      bottomNavigationBar: MainBottomNavigation(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
      child: IndexedStack(
        index: _index,
        children: _screens,
      ),
    );
  }
}
