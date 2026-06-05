import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '알림', showBack: true),
      child: notifications.when(
        loading: () => const LoadingSkeletonView(lines: 4),
        error: (error, stackTrace) => const ErrorStateView(message: '알림을 불러오지 못했어요.'),
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('경쟁 소식', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
            const SizedBox(height: AppSpacing.lg),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  borderColor: item.isRead ? null : AppColors.neonGreen.withOpacity(0.3),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(item.isRead ? Icons.notifications_rounded : Icons.notifications_active_rounded, color: AppColors.neonGreen),
                    title: Text(item.title),
                    subtitle: Text(item.body),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
