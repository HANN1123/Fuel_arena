import 'package:flutter/material.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/widgets/widgets.dart';

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sections,
    required this.selectedSection,
    required this.onSectionChanged,
    required this.child,
  });

  final String title;
  final String subtitle;
  final List<String> sections;
  final String selectedSection;
  final ValueChanged<String> onSectionChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      maxWidth: null,
      appBar: FuelArenaAppBar(title: title, subtitle: subtitle, showBack: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 860;
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminTopBar(
                  title: adminSectionLabel(selectedSection),
                  subtitle: '운영 항목을 선택하고 상태를 확인합니다.',
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedSection,
                  items: sections
                      .map((section) => DropdownMenuItem(
                          value: section,
                          child: Text(adminSectionLabel(section))))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onSectionChanged(value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                child,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 280,
                child: AdminSidebar(
                  sections: sections,
                  selected: selectedSection,
                  onChanged: onSectionChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.sections,
    required this.selected,
    required this.onChanged,
  });

  final List<String> sections;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(
            label: '관리자',
            color: AppColors.neonGreen,
            icon: Icons.admin_panel_settings_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  dense: true,
                  selected: section == selected,
                  selectedColor: AppColors.neonGreen,
                  leading: Icon(_iconForSection(section), size: 18),
                  title: Text(
                    adminSectionLabel(section),
                    overflow: TextOverflow.ellipsis,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () => onChanged(section),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminTopBar extends StatelessWidget {
  const AdminTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTypography.titleLarge
                      .copyWith(color: AppColors.neonGreen)),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.onSurfaceMuted)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.healthy,
  });

  final String label;
  final String value;
  final String? unit;
  final bool healthy;

  @override
  Widget build(BuildContext context) {
    return StatMetricCard(
      label: label,
      value: value,
      unit: unit,
      color: healthy ? AppColors.neonGreen : AppColors.amber,
    );
  }
}

class AdminFilterBar extends StatelessWidget {
  const AdminFilterBar({
    super.key,
    required this.searchHint,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  final String searchHint;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                labelText: searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          ...filters.map((filter) {
            final selected = filter == selectedFilter;
            return ChoiceChip(
              selected: selected,
              label: Text(adminFilterLabel(filter)),
              onSelected: (_) => onFilterChanged(filter),
              selectedColor: AppColors.neonGreen.withValues(alpha: 0.18),
              backgroundColor: AppColors.surfaceLow,
              side: BorderSide(
                color: selected
                    ? AppColors.neonGreen
                    : Colors.white.withValues(alpha: 0.1),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyMessage = '표시할 운영 데이터가 없어요.',
    this.onRowTap,
  });

  final List<String> columns;
  final List<List<Widget>> rows;
  final String emptyMessage;
  final ValueChanged<int>? onRowTap;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return EmptyStateView(title: '데이터 없음', message: emptyMessage);
    }
    return AppCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle:
              AppTypography.dataUnit.copyWith(color: AppColors.onSurfaceMuted),
          dataTextStyle: AppTypography.bodyMedium,
          columns:
              columns.map((column) => DataColumn(label: Text(column))).toList(),
          rows: rows
              .asMap()
              .entries
              .map(
                (cells) => DataRow(
                  onSelectChanged:
                      onRowTap == null ? null : (_) => onRowTap!(cells.key),
                  cells: cells.value.map((cell) => DataCell(cell)).toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
    final color = switch (normalized) {
      'active' ||
      'verified' ||
      'resolved' ||
      'completed' ||
      'healthy' =>
        AppColors.neonGreen,
      'pending' ||
      'pendingreview' ||
      'open' ||
      'review' ||
      'inreview' =>
        AppColors.amber,
      'blocked' || 'rejected' || 'failed' || 'risk' => AppColors.danger,
      _ => AppColors.electricBlue,
    };
    return StatusChip(
        label: _adminStatusLabel(normalized, status), color: color);
  }
}

String _adminStatusLabel(String normalized, String fallback) {
  return switch (normalized) {
    'active' => '활성',
    'verified' => '검증 완료',
    'resolved' || 'completed' => '처리 완료',
    'healthy' => '정상',
    'pending' || 'pendingreview' => '검수 대기',
    'review' || 'inreview' => '검토 중',
    'open' => '접수',
    'blocked' => '차단',
    'rejected' => '반려',
    'failed' => '실패',
    'risk' => '위험',
    _ => fallback,
  };
}

class AdminChartCard extends StatelessWidget {
  const AdminChartCard({
    super.key,
    required this.title,
    required this.values,
  });

  final String title;
  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.values.fold<double>(1, (max, value) {
      return value > max ? value : max;
    });
    return AppCard(
      borderColor: AppColors.electricBlue.withValues(alpha: 0.24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...values.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(adminChartLabel(entry.key),
                        style: AppTypography.dataUnit),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: (entry.value / maxValue).clamp(0, 1),
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceHighest,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.neonGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(entry.value.toStringAsFixed(0),
                      style: AppTypography.dataUnit),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminActionMenu extends StatelessWidget {
  const AdminActionMenu({
    super.key,
    required this.actions,
    this.onSelected,
  });

  final List<String> actions;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '운영 액션',
      icon: const Icon(Icons.more_horiz_rounded),
      itemBuilder: (context) => actions
          .map((action) => PopupMenuItem(value: action, child: Text(action)))
          .toList(),
      onSelected: (value) {
        if (onSelected != null) {
          onSelected!(value);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$value 작업을 운영 로그에서 확인했어요.')),
        );
      },
    );
  }
}

class AdminPaginationBar extends StatelessWidget {
  const AdminPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '페이지 ${page + 1} / $totalPages · ${totalCount > 0 ? '$totalCount건' : '결과 없음'}',
            style: AppTypography.dataUnit
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
        ),
        IconButton(
          tooltip: '이전 페이지',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          tooltip: '다음 페이지',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class AdminRecordDetailDrawer extends StatelessWidget {
  const AdminRecordDetailDrawer({
    super.key,
    required this.section,
    required this.record,
  });

  final String section;
  final AdminRecord record;

  static Future<void> show(
    BuildContext context, {
    required String section,
    required AdminRecord record,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AdminRecordDetailDrawer(
        section: section,
        record: record,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.centerRight,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, minWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(adminSectionLabel(section),
                        style: AppTypography.titleMedium),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(record.title,
                  style: AppTypography.titleLarge
                      .copyWith(color: AppColors.neonGreen)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AdminStatusBadge(status: record.status),
                  StatusChip(
                      label: record.owner, color: AppColors.electricBlue),
                ],
              ),
              if (record.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(record.description, style: AppTypography.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.md),
              SelectableText('ID: ${record.id}',
                  style: AppTypography.dataUnit
                      .copyWith(color: AppColors.onSurfaceMuted)),
              const SizedBox(height: AppSpacing.md),
              ...record.metadata.entries.take(8).map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 130,
                            child:
                                Text(entry.key, style: AppTypography.dataUnit),
                          ),
                          Expanded(
                            child: SelectableText(entry.value,
                                style: AppTypography.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminConfirmDialog extends StatelessWidget {
  const AdminConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AdminConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

IconData _iconForSection(String section) {
  if (section.contains('Vehicle')) return Icons.directions_car_rounded;
  if (section.contains('User')) return Icons.people_alt_rounded;
  if (section.contains('Drive')) return Icons.route_rounded;
  if (section.contains('Ranking')) return Icons.leaderboard_rounded;
  if (section.contains('Battle')) return Icons.sports_mma_rounded;
  if (section.contains('Season') || section.contains('Mission')) {
    return Icons.emoji_events_rounded;
  }
  if (section.contains('Ad')) return Icons.campaign_rounded;
  if (section.contains('Coupon') || section.contains('Premium')) {
    return Icons.card_giftcard_rounded;
  }
  if (section.contains('Fraud') || section.contains('Report')) {
    return Icons.verified_user_rounded;
  }
  if (section.contains('Privacy')) return Icons.privacy_tip_rounded;
  if (section.contains('Consent')) return Icons.privacy_tip_rounded;
  if (section.contains('Settings')) return Icons.tune_rounded;
  return Icons.monitor_heart_rounded;
}

String adminSectionLabel(String section) {
  return switch (section) {
    'System Overview' => '시스템 개요',
    'Users' => '사용자',
    'Vehicles Catalog' => '차량 카탈로그',
    'User Vehicles' => '사용자 차량',
    'Drive Sessions' => '주행 세션',
    'Drive Scores' => '주행 점수',
    'Rankings' => '랭킹',
    'Battles' => '배틀',
    'Seasons' => '시즌',
    'Missions' => '미션',
    'Ads' => '광고',
    'Sponsors' => '스폰서',
    'Coupons' => '쿠폰',
    'Premium' => '프리미엄',
    'Fraud Reviews' => '부정 기록 검토',
    'Reports' => '신고/이의제기',
    'Support Tickets' => '고객 문의',
    'Privacy Requests' => '개인정보 요청',
    'Consent Logs' => '동의 로그',
    'App Settings' => '앱 설정',
    'Admin Actions' => '운영 액션 로그',
    _ => section,
  };
}

String adminFilterLabel(String filter) {
  final normalized = filter.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
  return switch (normalized) {
    'active' => '활성',
    'pending' || 'pendingreview' => '검수 대기',
    'review' || 'inreview' => '검토 중',
    'blocked' => '차단',
    'open' => '접수',
    'completed' => '완료',
    'resolved' => '처리 완료',
    'rejected' => '반려',
    _ => filter,
  };
}

String adminChartLabel(String key) {
  return switch (key) {
    'verified' => '검증 완료',
    'pending' => '검수 대기',
    'rejected' => '반려',
    'open' => '접수',
    'review' => '검토 중',
    'completed' => '완료',
    'resolved' => '처리 완료',
    'view' => '조회',
    'claim' => '지급',
    'purchase' => '구매',
    'active' => '활성',
    'blocked' => '차단',
    _ => key,
  };
}
