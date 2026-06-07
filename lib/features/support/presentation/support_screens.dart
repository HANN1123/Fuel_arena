import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/input_validators.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

  static const _categories = [
    '로그인 문제',
    '차량 선택 문제',
    '주행 기록 문제',
    '점수/랭킹 문제',
    '광고 보상 문제',
    '결제/프리미엄 문제',
    '쿠폰 문제',
    '신고/부정 기록',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(supportTicketsProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '고객지원', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '도움이 필요하신가요?',
            style:
                AppTypography.displayScore.copyWith(color: AppColors.neonGreen),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '문의와 신고를 남기면 운영자가 확인하고 답변합니다.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: '문의 접수',
            icon: Icons.support_agent_rounded,
            onPressed: () => context.go('/support/contact'),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: '자주 묻는 질문',
            icon: Icons.quiz_rounded,
            onPressed: () => context.go('/support/faq'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '문의 유형'),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _categories
                .map(
                  (item) =>
                      StatusChip(label: item, color: AppColors.electricBlue),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '내 문의'),
          tickets.when(
            loading: () => const LoadingSkeletonView(lines: 2),
            error: (error, stackTrace) => ErrorStateView(
              message: '문의 내역을 불러오지 못했어요.',
              onRetry: () => ref.invalidate(supportTicketsProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return EmptyStateView(
                  title: '접수된 문의가 없어요',
                  message: '문제가 생기면 문의를 남겨 주세요. 답변은 이곳에서 확인할 수 있습니다.',
                  actionLabel: '문의 접수',
                  onAction: () => context.go('/support/contact'),
                );
              }
              return Column(
                children: items
                    .map(
                      (ticket) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppCard(
                          child: Material(
                            type: MaterialType.transparency,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.confirmation_number_rounded,
                                color: AppColors.neonGreen,
                              ),
                              title: Text(ticket.title),
                              subtitle: Text(
                                '${ticket.category} · ${_supportStatusLabel(ticket.status)}',
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => context.go(
                                '/support/ticket/${Uri.encodeComponent(ticket.id)}',
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  static const _items = [
    _FaqItem(
      title: '공식 랭킹은 어떻게 반영되나요?',
      body: '검증이 완료된 주행 점수만 같은 연료 리그와 차급 안에서 반영합니다. 보류된 기록은 검토 후 반영됩니다.',
      category: '점수/랭킹 문제',
      actionLabel: '검토 요청하기',
      actionRoute: '/support/review-request',
    ),
    _FaqItem(
      title: '광고를 보지 않으면 보상을 못 받나요?',
      body: '아니요. 기본 보상은 유지되고, 광고는 사용자가 선택할 때만 추가 보상을 위해 실행됩니다.',
      category: '광고 보상 문제',
      actionLabel: '광고 보상 문의',
    ),
    _FaqItem(
      title: '직접 입력한 차량은 언제 공식 리그에 반영되나요?',
      body: '운영자 검토 후 승인되면 대표 차량 리그와 차급이 갱신되고 공식 랭킹/배틀 조건에 반영됩니다.',
      category: '차량 선택 문제',
      actionLabel: '차량 문의',
    ),
    _FaqItem(
      title: '쿠폰을 발급했는데 보이지 않아요',
      body: '리워드 지갑에서 발급 상태를 확인해 주세요. 같은 쿠폰 중복 발급은 서버에서 보호합니다.',
      category: '쿠폰 문제',
      actionLabel: '쿠폰 문제로 문의',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '자주 묻는 질문', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자주 묻는 질문',
            style:
                AppTypography.displayScore.copyWith(color: AppColors.neonGreen),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '답변으로 해결되지 않으면 관련 문의 유형으로 바로 접수할 수 있어요.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(
                      label: item.category,
                      color: AppColors.electricBlue,
                      icon: Icons.help_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(item.title, style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.body,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.onSurfaceMuted),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SecondaryButton(
                      label: item.actionLabel,
                      icon: Icons.support_agent_rounded,
                      onPressed: () => context.go(item.route),
                    ),
                  ],
                ),
              ),
            ),
          PrimaryButton(
            label: '새 문의 접수',
            icon: Icons.edit_rounded,
            onPressed: () => context.go('/support/contact'),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({
    required this.title,
    required this.body,
    required this.category,
    required this.actionLabel,
    this.actionRoute,
  });

  final String title;
  final String body;
  final String category;
  final String actionLabel;
  final String? actionRoute;

  String get route =>
      actionRoute ??
      '/support/contact?category=${Uri.encodeComponent(category)}';
}

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({
    super.key,
    this.initialCategory = '주행 기록 문제',
    this.reportTargetType,
    this.reportTargetId = '',
  });

  final String initialCategory;
  final String? reportTargetType;
  final String reportTargetId;

  @override
  ConsumerState<ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  late var _category = _categories.contains(widget.initialCategory)
      ? widget.initialCategory
      : '주행 기록 문제';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _saving = false;

  bool get _isReport =>
      _category == '신고/부정 기록' || widget.reportTargetType != null;

  static const _categories = [
    '로그인 문제',
    '차량 선택 문제',
    '주행 기록 문제',
    '점수/랭킹 문제',
    '광고 보상 문제',
    '결제/프리미엄 문제',
    '쿠폰 문제',
    '신고/부정 기록',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final error = InputValidators.supportTitle(title) ??
        InputValidators.supportBody(description);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    setState(() => _saving = true);
    final ticket =
        await ref.read(supportRepositoryProvider).createSupportTicket(
              category: _category,
              title: title,
              description: description,
            );
    if (_isReport) {
      await ref.read(reportRepositoryProvider).createReport(
            ReportRequest(
              targetType: widget.reportTargetType ?? 'general',
              targetId: widget.reportTargetId,
              reason: '$title\n$description',
            ),
          );
    }
    await ref.read(analyticsRepositoryProvider).track(
      _isReport ? 'report_submitted' : 'support_ticket_submitted',
      properties: {
        'category': _category,
        if (widget.reportTargetType != null)
          'targetType': widget.reportTargetType,
      },
    );
    ref.invalidate(supportTicketsProvider);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    context.go('/support/ticket/${Uri.encodeComponent(ticket.id)}');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '문의 접수', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '문제를 자세히 알려주세요',
            style:
                AppTypography.displayScore.copyWith(color: AppColors.neonGreen),
          ),
          if (_isReport) ...[
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              borderColor: AppColors.amber.withValues(alpha: 0.32),
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded, color: AppColors.amber),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _reportTargetCopy(
                        widget.reportTargetType,
                        widget.reportTargetId,
                      ),
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.onSurfaceMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: _categories
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
            decoration: const InputDecoration(labelText: '문의 유형'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _titleController,
            maxLength: 40,
            decoration: const InputDecoration(labelText: '제목'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _descriptionController,
            minLines: 5,
            maxLines: 8,
            maxLength: 800,
            decoration: const InputDecoration(labelText: '내용'),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: '접수하기',
            icon: Icons.send_rounded,
            isLoading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  const SupportTicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  final _messageController = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final error = InputValidators.supportBody(message);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    setState(() => _sending = true);
    await ref
        .read(supportRepositoryProvider)
        .addMessage(widget.ticketId, message);
    ref.invalidate(supportTicketMessagesProvider(widget.ticketId));
    ref.invalidate(supportTicketDetailProvider(widget.ticketId));
    ref.invalidate(supportTicketsProvider);
    if (!mounted) {
      return;
    }
    _messageController.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final ticket = ref.watch(supportTicketDetailProvider(widget.ticketId));
    final messages = ref.watch(supportTicketMessagesProvider(widget.ticketId));
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '문의 상세', showBack: true),
      child: ticket.when(
        loading: () => const LoadingSkeletonView(lines: 4),
        error: (error, stackTrace) => ErrorStateView(
          message: '문의 상세를 불러오지 못했어요.',
          onRetry: () => ref.invalidate(
            supportTicketDetailProvider(widget.ticketId),
          ),
        ),
        data: (item) {
          if (item == null) {
            return EmptyStateView(
              title: '문의가 보이지 않아요',
              message: '이미 삭제되었거나 접근 권한이 없는 문의입니다.',
              actionLabel: '고객지원으로 이동',
              onAction: () => context.go('/support'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                borderColor: AppColors.neonGreen.withValues(alpha: 0.28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        StatusChip(
                          label: _supportStatusLabel(item.status),
                          color: _supportStatusColor(item.status),
                        ),
                        StatusChip(
                          label: item.category,
                          color: AppColors.electricBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(item.title, style: AppTypography.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      item.description,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.onSurfaceMuted),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '접수 ${_formatSupportDate(item.createdAt)}',
                      style: AppTypography.dataUnit
                          .copyWith(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: '답변과 추가 메시지'),
              messages.when(
                loading: () => const LoadingSkeletonView(lines: 2),
                error: (error, stackTrace) => ErrorStateView(
                  message: '메시지를 불러오지 못했어요.',
                  onRetry: () => ref.invalidate(
                    supportTicketMessagesProvider(widget.ticketId),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStateView(
                      title: '아직 답변이 없어요',
                      message: '운영자가 확인하면 이곳에 답변이 표시됩니다.',
                    );
                  }
                  return Column(
                    children: items
                        .map(
                          (message) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: _SupportMessageCard(message: message),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _messageController,
                minLines: 3,
                maxLines: 6,
                maxLength: 600,
                decoration: const InputDecoration(
                  labelText: '추가 메시지',
                  hintText: '운영자가 확인할 수 있도록 상황을 더 남겨 주세요.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: '메시지 보내기',
                icon: Icons.reply_rounded,
                isLoading: _sending,
                onPressed: _sendMessage,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SupportMessageCard extends StatelessWidget {
  const _SupportMessageCard({required this.message});

  final SupportTicketMessage message;

  @override
  Widget build(BuildContext context) {
    final isAdmin = message.isAdminReply;
    return AppCard(
      borderColor: isAdmin
          ? AppColors.neonGreen.withValues(alpha: 0.28)
          : Colors.white.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAdmin
                    ? Icons.support_agent_rounded
                    : Icons.person_outline_rounded,
                color: isAdmin ? AppColors.neonGreen : AppColors.electricBlue,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isAdmin ? '운영자 답변' : '내 추가 메시지',
                  style: AppTypography.titleMedium,
                ),
              ),
              Text(
                _formatSupportDate(message.createdAt),
                style: AppTypography.dataUnit
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message.message,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

class ReportProblemScreen extends StatelessWidget {
  const ReportProblemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContactSupportScreen(initialCategory: '신고/부정 기록');
  }
}

class ReportUserScreen extends StatelessWidget {
  const ReportUserScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return ContactSupportScreen(
      initialCategory: '신고/부정 기록',
      reportTargetType: 'user',
      reportTargetId: userId,
    );
  }
}

class ReportDriveRecordScreen extends StatelessWidget {
  const ReportDriveRecordScreen({super.key, required this.driveId});

  final String driveId;

  @override
  Widget build(BuildContext context) {
    return ContactSupportScreen(
      initialCategory: '신고/부정 기록',
      reportTargetType: 'drive_session',
      reportTargetId: driveId,
    );
  }
}

class ReviewRequestScreen extends ConsumerStatefulWidget {
  const ReviewRequestScreen({
    super.key,
    this.driveId = '',
  });

  final String driveId;

  @override
  ConsumerState<ReviewRequestScreen> createState() =>
      _ReviewRequestScreenState();
}

class _ReviewRequestScreenState extends ConsumerState<ReviewRequestScreen> {
  late final TextEditingController _driveIdController;
  final _descriptionController = TextEditingController();
  var _reason = '점수 반영 보류';
  var _saving = false;

  static const _reasons = [
    '점수 반영 보류',
    'GPS 품질 재검토',
    '랭킹 미반영',
    '배틀 정산 이의',
  ];

  @override
  void initState() {
    super.initState();
    _driveIdController = TextEditingController(text: widget.driveId);
  }

  @override
  void dispose() {
    _driveIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final driveId = _driveIdController.text.trim();
    final description = _descriptionController.text.trim();
    final error = InputValidators.supportBody(description);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() => _saving = true);
    final title = driveId.isEmpty ? '주행 기록 검토 요청' : '주행 기록 $driveId 검토 요청';
    final body = [
      '요청 사유: $_reason',
      if (driveId.isNotEmpty) '대상 기록: $driveId',
      '상세 내용: $description',
      '공정한 경쟁을 위해 기록 상태와 검증 기준 재확인을 요청합니다.',
    ].join('\n');
    final ticket =
        await ref.read(supportRepositoryProvider).createSupportTicket(
              category: '점수/랭킹 문제',
              title: title,
              description: body,
            );
    await ref.read(reportRepositoryProvider).createReport(
          ReportRequest(
            targetType: 'drive_review_request',
            targetId: driveId,
            reason: body,
          ),
        );
    await ref.read(analyticsRepositoryProvider).track(
      'review_request_submitted',
      properties: {
        'reason': _reason,
        'hasDriveId': driveId.isNotEmpty,
      },
    );
    ref.invalidate(supportTicketsProvider);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    context.go('/support/ticket/${Uri.encodeComponent(ticket.id)}');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '검토 요청', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기록을 다시\n확인해드릴게요',
            style: AppTypography.displayScore.copyWith(color: AppColors.amber),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '점수 보류, 랭킹 미반영, 배틀 정산이 이상하면 운영팀에 재검토를 요청할 수 있습니다.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            borderColor: AppColors.electricBlue.withValues(alpha: 0.28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusChip(
                  label: '공정성 검토',
                  color: AppColors.electricBlue,
                  icon: Icons.fact_check_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '정확한 위치 좌표는 공개 화면에 표시하지 않고, 운영 검토는 권한이 제한된 기록으로만 진행합니다.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.onSurfaceMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '요청 사유'),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _reasons.map((reason) {
              final selected = reason == _reason;
              return ChoiceChip(
                selected: selected,
                label: Text(reason),
                selectedColor: AppColors.amber.withValues(alpha: 0.18),
                backgroundColor: AppColors.surfaceLow,
                side: BorderSide(
                  color: selected
                      ? AppColors.amber
                      : Colors.white.withValues(alpha: 0.1),
                ),
                onSelected: (_) => setState(() => _reason = reason),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _driveIdController,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: '주행 기록 ID',
              hintText: '모르면 비워둘 수 있어요',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _descriptionController,
            minLines: 5,
            maxLines: 8,
            maxLength: 800,
            decoration: const InputDecoration(
              labelText: '검토 내용',
              hintText: '언제 어떤 기록에서 어떤 점이 이상했는지 알려주세요.',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: '검토 요청 제출',
            icon: Icons.fact_check_rounded,
            isLoading: _saving,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '요청은 문의 상세에서 답변을 확인할 수 있고, 운영자 Reports 큐에도 함께 기록됩니다.',
            style: AppTypography.dataUnit
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

String _reportTargetCopy(String? targetType, String targetId) {
  if (targetType == 'user') {
    return '사용자 신고로 접수합니다. 대상 ID: $targetId';
  }
  if (targetType == 'drive_session') {
    return '주행 기록 신고로 접수합니다. 대상 ID: $targetId';
  }
  return '부정 기록 또는 공정성 이슈 신고로 접수합니다.';
}

String _supportStatusLabel(String status) {
  return switch (status.toLowerCase()) {
    'open' => '접수',
    'review' || 'in_review' => '검토 중',
    'resolved' || 'closed' => '처리 완료',
    _ => status,
  };
}

Color _supportStatusColor(String status) {
  return switch (status.toLowerCase()) {
    'open' => AppColors.amber,
    'review' || 'in_review' => AppColors.electricBlue,
    'resolved' || 'closed' => AppColors.neonGreen,
    _ => AppColors.outline,
  };
}

String _formatSupportDate(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}.${two(local.month)}.${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
