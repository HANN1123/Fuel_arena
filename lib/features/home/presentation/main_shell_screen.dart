import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/repository_providers.dart';
import '../../../shared/services/app_services.dart';
import '../../../shared/widgets/widgets.dart';
import '../../battle/presentation/battle_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../ranking/presentation/ranking_screen.dart';
import '../../season/presentation/season_screen.dart';
import 'home_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late var _index = widget.initialIndex;
  var _syncing = false;

  static const _screens = [
    HomeScreen(),
    BattleScreen(),
    RankingScreen(),
    SeasonScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_retryPendingUpload());
    });
  }

  Future<void> _retryPendingUpload() async {
    if (_syncing) {
      return;
    }
    _syncing = true;
    try {
      final uploaded = await ref.read(syncServiceProvider).uploadPending();
      if (uploaded > 0 && mounted) {
        ref.invalidate(offlineQueueItemsProvider);
      }
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<NetworkSnapshot>>(networkStatusProvider,
        (previous, next) {
      next.whenData((snapshot) {
        if (snapshot.isOnline) {
          unawaited(_retryPendingUpload());
        }
      });
    });
    final network = ref.watch(networkStatusProvider);
    final pendingQueue = ref.watch(offlineQueueItemsProvider);
    return AppScaffold(
      scrollable: false,
      padding: EdgeInsets.zero,
      bottomNavigationBar: MainBottomNavigation(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: KeyedSubtree(
              key: ValueKey(_index),
              child: _screens[_index],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                network.maybeWhen(
                  data: (value) => OfflineBanner(isOnline: value.isOnline),
                  orElse: () => const SizedBox.shrink(),
                ),
                pendingQueue.maybeWhen(
                  data: (items) =>
                      SyncPendingBanner(pendingCount: items.length),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
