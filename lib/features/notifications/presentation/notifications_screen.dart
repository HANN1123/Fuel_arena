import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final session = ref.watch(restoredSessionProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '알림', showBack: true),
      child: session.when(
        loading: () => const LoadingSkeletonView(lines: 4),
        error: (error, stackTrace) => ErrorStateView(
          message: '주행 상태를 확인하지 못했어요.',
          onRetry: () => ref.invalidate(restoredSessionProvider),
        ),
        data: (session) {
          if (session.hasActiveDrive) {
            return _ActiveDriveNotificationHold(
              sessionId: session.activeDriveSessionId,
            );
          }
          return notifications.when(
            loading: () => const LoadingSkeletonView(lines: 4),
            error: (error, stackTrace) =>
                const ErrorStateView(message: '알림을 불러오지 못했어요.'),
            data: (items) => _NotificationList(items: items),
          );
        },
      ),
    );
  }
}

class _ActiveDriveNotificationHold extends StatelessWidget {
  const _ActiveDriveNotificationHold({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '주행 안전 모드',
          style:
              AppTypography.displayScore.copyWith(color: AppColors.neonGreen),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          borderColor: AppColors.neonGreen.withValues(alpha: 0.28),
          child: Column(
            children: [
              const Icon(
                Icons.do_not_disturb_on_total_silence_rounded,
                color: AppColors.neonGreen,
                size: 42,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '주행 중에는 알림을 표시하지 않아요',
                style: AppTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '배틀 초대, 보상, 광고성 안내는 주행 완료 후 한 번에 확인할 수 있어요.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              StatusChip(
                label: '보류 중인 주행 $sessionId',
                icon: Icons.shield_rounded,
                color: AppColors.electricBlue,
              ),
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(
                label: '주행 화면으로 돌아가기',
                icon: Icons.navigation_rounded,
                onPressed: () => context.go('/drive/safety'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.items});

  final List<NotificationItem> items;

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) async {
    await ref.read(notificationRepositoryProvider).markRead(item.id);
    await ref.read(analyticsRepositoryProvider).track(
      'notification_opened',
      properties: {
        'notification_id': item.id,
        'notification_type': item.notificationType,
        'target_route': item.targetRoute,
        'held_during_drive': item.heldDuringDrive,
      },
    );
    ref.invalidate(notificationsProvider);
    if (item.targetRoute.isNotEmpty && context.mounted) {
      context.go(item.targetRoute);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '경쟁 소식',
          style:
              AppTypography.displayScore.copyWith(color: AppColors.neonGreen),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '주행 중 보류된 알림은 주행 완료 후 한 번에 확인할 수 있어요.',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.onSurfaceMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (items.isEmpty)
          const EmptyStateView(
            title: '새 알림이 없어요',
            message: '배틀 초대, 시즌 보상, 주행 검증 결과가 생기면 여기에 표시됩니다.',
          )
        else ...[
          SecondaryButton(
            label: '전체 읽음 처리',
            icon: Icons.done_all_rounded,
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              borderColor: item.isRead
                  ? null
                  : AppColors.neonGreen.withValues(alpha: 0.3),
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item.isRead
                        ? Icons.notifications_rounded
                        : Icons.notifications_active_rounded,
                    color: AppColors.neonGreen,
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    item.heldDuringDrive ? '${item.body}\n주행 중 보류됨' : item.body,
                  ),
                  trailing: item.targetRoute.isEmpty
                      ? null
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openNotification(context, ref, item),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
