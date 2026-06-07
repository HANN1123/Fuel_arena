import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

final _driveHistoryProvider = FutureProvider<_DriveHistoryPayload>((ref) async {
  final repository = ref.watch(driveRepositoryProvider);
  final sessionsFuture = repository.listDriveSessions(limit: 20);
  final scoresFuture = repository.listDriveScores(limit: 20);
  final sessions = await sessionsFuture;
  final scores = await scoresFuture;
  return _DriveHistoryPayload(sessions: sessions, scores: scores);
});

final _driveAnalysisProvider =
    FutureProvider.family<_DriveAnalysisPayload, String>(
        (ref, sessionId) async {
  final history = await ref.watch(_driveHistoryProvider.future);
  final session = _firstWhereOrNull(
    history.sessions,
    (item) => item.id == sessionId,
  );
  final score = history.scoreFor(sessionId);
  return _DriveAnalysisPayload(session: session, score: score);
});

class DriveHistoryScreen extends ConsumerWidget {
  const DriveHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_driveHistoryProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '주행 기록', showBack: true),
      child: history.when(
        loading: () => const LoadingSkeletonView(lines: 5),
        error: (error, stackTrace) => ErrorStateView(
          message: '주행 기록을 불러오지 못했어요.',
          onRetry: () => ref.invalidate(_driveHistoryProvider),
        ),
        data: (payload) {
          if (payload.sessions.isEmpty) {
            return EmptyStateView(
              title: '아직 주행 기록이 없어요',
              message: '첫 주행을 완료하면 검증 상태와 점수 분석이 이곳에 쌓입니다.',
              actionLabel: '주행 시작하기',
              onAction: () => context.go('/drive/start'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '최근 주행을\n다시 확인하세요',
                style: AppTypography.displayScore
                    .copyWith(color: AppColors.neonGreen),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '공개 랭킹에는 좌표와 상세 경로를 표시하지 않고, 이 화면에서도 점수 계산에 필요한 요약만 보여줍니다.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final session in payload.sessions)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _DriveHistoryCard(
                    session: session,
                    score: payload.scoreFor(session.id),
                    onTap: () => context.push('/drive/analysis/${session.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class DriveAnalysisScreen extends ConsumerWidget {
  const DriveAnalysisScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(_driveAnalysisProvider(sessionId));
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '주행 분석', showBack: true),
      child: analysis.when(
        loading: () => const LoadingSkeletonView(lines: 5),
        error: (error, stackTrace) => ErrorStateView(
          message: '주행 분석을 불러오지 못했어요.',
          onRetry: () => ref.invalidate(_driveAnalysisProvider(sessionId)),
        ),
        data: (payload) {
          final session = payload.session;
          if (session == null) {
            return EmptyStateView(
              title: '주행 기록을 찾을 수 없어요',
              message: '기록이 삭제되었거나 아직 동기화되지 않았습니다. 최근 주행 목록에서 다시 선택해 주세요.',
              actionLabel: '주행 기록 보기',
              onAction: () => context.go('/drive/history'),
            );
          }
          return _DriveAnalysisContent(
            session: session,
            score: payload.score,
          );
        },
      ),
    );
  }
}

class _DriveAnalysisContent extends StatelessWidget {
  const _DriveAnalysisContent({
    required this.session,
    required this.score,
  });

  final DriveSession session;
  final DriveScore? score;

  @override
  Widget build(BuildContext context) {
    final verificationStatus = score?.verificationStatus ?? session.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '점수로 보는\n이번 주행',
          style: AppTypography.displayScore.copyWith(
            color: AppColors.electricBlue,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          borderColor: _statusColor(verificationStatus).withValues(alpha: 0.32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDateTime(session.startedAt),
                      style: AppTypography.titleMedium,
                    ),
                  ),
                  StatusChip(
                    label: _statusLabel(verificationStatus),
                    color: _statusColor(verificationStatus),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '기록 ID ${_shortId(session.id)}',
                style: AppTypography.dataUnit
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _MetricBox(
              label: '총점',
              value: score == null ? '-' : '${score!.totalScore}',
              unit: score == null ? null : 'PTS',
              color: AppColors.neonGreen,
            ),
            _MetricBox(
              label: '주행 거리',
              value: session.distanceKm.toStringAsFixed(1),
              unit: 'km',
              color: AppColors.electricBlue,
            ),
            _MetricBox(
              label: '평균 효율',
              value: session.averageFuelEfficiency.toStringAsFixed(1),
              unit: 'km/L',
              color: AppColors.gold,
            ),
            _MetricBox(
              label: '주행 시간',
              value: _formatDuration(session.duration),
              color: AppColors.amber,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (score == null)
          const EmptyStateView(
            title: '점수 검증을 기다리고 있어요',
            message: '서버 검증이 끝나면 총점, 패널티, 보너스가 자동으로 표시됩니다.',
          )
        else
          DriveScoreAnalysisCard(score: score!),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('공개 제한', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '정확한 위치 좌표와 원본 주행 포인트는 공개 화면에 표시하지 않습니다.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: '랭킹 확인',
          icon: Icons.leaderboard_rounded,
          onPressed: () => context.go('/home?tab=ranking'),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: '이 기록 검토 요청',
          icon: Icons.support_agent_rounded,
          onPressed: () =>
              context.push('/support/review-request/${session.id}'),
        ),
      ],
    );
  }
}

class _DriveHistoryCard extends StatelessWidget {
  const _DriveHistoryCard({
    required this.session,
    required this.score,
    required this.onTap,
  });

  final DriveSession session;
  final DriveScore? score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = score?.verificationStatus ?? session.status;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AppCard(
        borderColor: _statusColor(status).withValues(alpha: 0.24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDateTime(session.startedAt),
                    style: AppTypography.titleMedium,
                  ),
                ),
                StatusChip(
                    label: _statusLabel(status), color: _statusColor(status)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${session.distanceKm.toStringAsFixed(1)}km · ${_formatDuration(session.duration)} · ${session.averageFuelEfficiency.toStringAsFixed(1)}km/L',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    score == null ? '점수 검증 대기' : '${score!.totalScore} PTS',
                    style: AppTypography.titleLarge.copyWith(
                      color: score == null
                          ? AppColors.onSurfaceMuted
                          : AppColors.neonGreen,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.outline),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
    required this.color,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 188,
      child: StatMetricCard(
        label: label,
        value: value,
        unit: unit,
        color: color,
      ),
    );
  }
}

class _DriveHistoryPayload {
  const _DriveHistoryPayload({
    required this.sessions,
    required this.scores,
  });

  final List<DriveSession> sessions;
  final List<DriveScore> scores;

  DriveScore? scoreFor(String sessionId) {
    return _firstWhereOrNull(
        scores, (score) => score.driveSessionId == sessionId);
  }
}

class _DriveAnalysisPayload {
  const _DriveAnalysisPayload({
    required this.session,
    required this.score,
  });

  final DriveSession? session;
  final DriveScore? score;
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) {
      return item;
    }
  }
  return null;
}

String _formatDateTime(DateTime value) {
  return DateFormat('M월 d일 HH:mm').format(value);
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).abs();
  if (minutes <= 0) {
    return '$seconds초';
  }
  return '$minutes분 ${seconds.toString().padLeft(2, '0')}초';
}

String _shortId(String id) {
  if (id.length <= 10) {
    return id;
  }
  return id.substring(id.length - 10);
}

String _statusLabel(String status) {
  return switch (status) {
    'verified' => '검증 완료',
    'pending_review' => '검증 대기',
    'recording' => '기록 중',
    'rejected' => '반영 제외',
    _ => '검증 확인',
  };
}

Color _statusColor(String status) {
  return switch (status) {
    'verified' => AppColors.neonGreen,
    'pending_review' => AppColors.amber,
    'recording' => AppColors.electricBlue,
    'rejected' => AppColors.danger,
    _ => AppColors.outline,
  };
}
