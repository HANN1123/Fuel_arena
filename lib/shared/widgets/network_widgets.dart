import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_typography.dart';
import 'buttons.dart';
import 'status_widgets.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.isOnline,
  });

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    if (isOnline) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.mobileMargin, vertical: AppSpacing.sm),
      color: AppColors.amber.withValues(alpha: 0.16),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.amber, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '인터넷 연결이 불안정해요',
              style: AppTypography.dataUnit.copyWith(color: AppColors.amber),
            ),
          ),
        ],
      ),
    );
  }
}

class SyncPendingBanner extends StatelessWidget {
  const SyncPendingBanner({
    super.key,
    required this.pendingCount,
  });

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.mobileMargin, AppSpacing.sm, AppSpacing.mobileMargin, 0),
      child: AppCard(
        borderColor: AppColors.electricBlue.withValues(alpha: 0.3),
        child: Row(
          children: [
            const Icon(Icons.sync_rounded, color: AppColors.electricBlue),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '주행 기록은 기기에 안전하게 보관했어요. 연결되면 자동으로 업로드됩니다.',
                style: AppTypography.bodyMedium,
              ),
            ),
            StatusChip(label: '$pendingCount건', color: AppColors.electricBlue),
          ],
        ),
      ),
    );
  }
}

class UploadRetryCard extends StatelessWidget {
  const UploadRetryCard({
    super.key,
    required this.pendingCount,
    required this.onRetry,
    this.loading = false,
  });

  final int pendingCount;
  final VoidCallback onRetry;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.amber.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(
              label: '동기화 대기',
              color: AppColors.amber,
              icon: Icons.cloud_upload_rounded),
          const SizedBox(height: AppSpacing.md),
          Text('업로드 대기 기록 $pendingCount건', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('이전 기록을 안전하게 저장하고 있어요.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: '다시 시도하기',
            icon: Icons.refresh_rounded,
            onPressed: loading ? null : onRetry,
          ),
        ],
      ),
    );
  }
}

class RetryView extends StatelessWidget {
  const RetryView({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.error.withValues(alpha: 0.3),
      child: Column(
        children: [
          const Icon(Icons.refresh_rounded, color: AppColors.error, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text(title,
              style: AppTypography.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(message,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
              label: '다시 시도하기',
              icon: Icons.refresh_rounded,
              onPressed: onRetry),
        ],
      ),
    );
  }
}
