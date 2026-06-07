import 'package:flutter/material.dart';

import '../../core/errors/app_error.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_typography.dart';
import 'buttons.dart';
import 'status_widgets.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, color: AppColors.outline, size: 42),
          const SizedBox(height: AppSpacing.md),
          Text(title,
              style: AppTypography.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(message,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted),
              textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.error.withValues(alpha: 0.3),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 42),
          const SizedBox(height: AppSpacing.md),
          Text(message,
              style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: '다시 시도', onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}

class MappedErrorStateView extends StatelessWidget {
  const MappedErrorStateView({
    super.key,
    required this.error,
    this.onRetry,
  });

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    const mapper = ErrorMapper();
    return AppCard(
      borderColor: AppColors.error.withValues(alpha: 0.3),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 42),
          const SizedBox(height: AppSpacing.md),
          Text(mapper.titleFor(error),
              style: AppTypography.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(mapper.messageFor(error),
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted),
              textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: '다시 시도', onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}

class LoadingSkeletonView extends StatelessWidget {
  const LoadingSkeletonView({super.key, this.lines = 4});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        lines,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(height: 72, width: double.infinity),
          ),
        ),
      ),
    );
  }
}
