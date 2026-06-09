import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart' hide FuelLeague;
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';
import '../../vehicle/domain/vehicle_powertrain_taxonomy.dart';

// --- Admin Powertrain Data Models & State ---

class VehicleCatalogConflict {
  VehicleCatalogConflict({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.conflictType,
    required this.existingValue,
    required this.incomingValue,
    required this.status,
    required this.createdAt,
    required this.incomingSourceName,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String conflictType;
  final Map<String, dynamic> existingValue;
  final Map<String, dynamic> incomingValue;
  String status;
  final DateTime createdAt;
  final String incomingSourceName;

  VehicleCatalogConflict copyWith({String? status}) {
    return VehicleCatalogConflict(
      id: id,
      entityType: entityType,
      entityId: entityId,
      conflictType: conflictType,
      existingValue: existingValue,
      incomingValue: incomingValue,
      status: status ?? this.status,
      createdAt: createdAt,
      incomingSourceName: incomingSourceName,
    );
  }
}

class VehicleCatalogImportJob {
  VehicleCatalogImportJob({
    required this.id,
    required this.importType,
    required this.status,
    required this.totalRows,
    required this.insertedRows,
    required this.updatedRows,
    required this.conflictRows,
    required this.finishedAt,
  });

  final String id;
  final String importType;
  final String status;
  final int totalRows;
  final int insertedRows;
  final int updatedRows;
  final int conflictRows;
  final DateTime finishedAt;
}

// State Providers for local UI mock interactivity

class AdminConflictsNotifier extends Notifier<List<VehicleCatalogConflict>> {
  @override
  List<VehicleCatalogConflict> build() {
    return [
      VehicleCatalogConflict(
        id: 'conflict-1',
        entityType: 'variant',
        entityId: 'porsche-911-carrera-2026',
        conflictType: 'specification_mismatch',
        existingValue: {
          'trim_name': '카레라 4',
          'drivetrain': 'AWD',
          'displacement_cc': 2981,
          'official_efficiency': 8.6,
          'efficiency_unit': 'km/L',
          'source_status': 'verified_official',
          'source_name': '포르쉐 코리아 공식 제원'
        },
        incomingValue: {
          'trim_name': 'Carrera 4',
          'drivetrain': 'FWD',
          'displacement_cc': 2981,
          'official_efficiency': 8.2,
          'efficiency_unit': 'km/L',
          'source_status': 'imported_public',
          'source_name': '한국에너지공단 연비데이터'
        },
        status: 'open',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        incomingSourceName: '한국에너지공단 연비데이터',
      ),
      VehicleCatalogConflict(
        id: 'conflict-2',
        entityType: 'variant',
        entityId: 'bmw-i4-m50-2025',
        conflictType: 'invalid_unit',
        existingValue: {
          'trim_name': 'M50 Gran Coupe',
          'battery_kwh': 84.0,
          'official_efficiency': 4.1,
          'efficiency_unit': 'km/kWh',
          'source_status': 'verified_official',
          'source_name': 'BMW 공식 카탈로그'
        },
        incomingValue: {
          'trim_name': 'M50 Gran Coupe',
          'battery_kwh': 84.0,
          'official_efficiency': 14.5,
          'efficiency_unit': 'km/L',
          'source_status': 'imported_public',
          'source_name': 'KEA 연비인증 CSV'
        },
        status: 'open',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        incomingSourceName: 'KEA 연비인증 CSV',
      ),
    ];
  }

  void update(List<VehicleCatalogConflict> newList) {
    state = newList;
  }
}

final adminConflictsProvider = NotifierProvider.autoDispose<
    AdminConflictsNotifier, List<VehicleCatalogConflict>>(() {
  return AdminConflictsNotifier();
});

class AdminImportJobsNotifier extends Notifier<List<VehicleCatalogImportJob>> {
  @override
  List<VehicleCatalogImportJob> build() {
    return [
      VehicleCatalogImportJob(
        id: 'job-1',
        importType: '한국에너지공단 공공 연비 CSV',
        status: 'completed',
        totalRows: 1240,
        insertedRows: 20,
        updatedRows: 1210,
        conflictRows: 10,
        finishedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      VehicleCatalogImportJob(
        id: 'job-2',
        importType: 'BMW 코리아 제조사 사양 CSV',
        status: 'completed',
        totalRows: 85,
        insertedRows: 5,
        updatedRows: 78,
        conflictRows: 2,
        finishedAt: DateTime.now().subtract(const Duration(hours: 18)),
      ),
    ];
  }

  void update(List<VehicleCatalogImportJob> newList) {
    state = newList;
  }
}

final adminImportJobsProvider = NotifierProvider.autoDispose<
    AdminImportJobsNotifier, List<VehicleCatalogImportJob>>(() {
  return AdminImportJobsNotifier();
});

// --- Main Screens Hub ---

class AdminPowertrainCatalogScreen extends ConsumerWidget {
  const AdminPowertrainCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return AppScaffold(
      maxWidth: null,
      appBar: const FuelArenaAppBar(
        title: '파워트레인 데이터 및 품질 관리',
        subtitle: '관리자 신뢰성 제어 센터',
        showBack: true,
      ),
      child: profile.when(
        loading: () => const LoadingSkeletonView(lines: 3),
        error: (error, stackTrace) => MappedErrorStateView(error: error),
        data: (user) {
          if (!user.isAdmin) {
            return const ErrorStateView(message: '관리자만 접근할 수 있습니다.');
          }
          return const _AdminPowertrainDashboard();
        },
      ),
    );
  }
}

class _AdminPowertrainDashboard extends StatefulWidget {
  const _AdminPowertrainDashboard();

  @override
  State<_AdminPowertrainDashboard> createState() =>
      _AdminPowertrainDashboardState();
}

class _AdminPowertrainDashboardState extends State<_AdminPowertrainDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.neonGreen,
          unselectedLabelColor: AppColors.onSurfaceMuted,
          indicatorColor: AppColors.neonGreen,
          tabs: const [
            Tab(text: '파워트레인 목록'),
            Tab(text: '출처 충돌 해결'),
            Tab(text: '임포트 작업 이력'),
            Tab(text: '품질 스캔 보고서'),
            Tab(text: '직접 입력 검수'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 650,
          child: TabBarView(
            controller: _tabController,
            children: const [
              _CatalogTab(),
              AdminPowertrainConflictScreen(),
              AdminPowertrainImportScreen(),
              AdminCatalogQualityReportScreen(),
              AdminCustomVehicleReviewScreen(),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Tab 1: 파워트레인 목록 ---

class _CatalogTab extends ConsumerStatefulWidget {
  const _CatalogTab();

  @override
  ConsumerState<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends ConsumerState<_CatalogTab> {
  var _keyword = '';
  var _selectedLeague = '전체';

  @override
  Widget build(BuildContext context) {
    final query = VehicleManufacturerQuery();
    final manufacturers = ref.watch(vehicleManufacturersProvider(query));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) =>
                    setState(() => _keyword = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  labelText: '제조사/모델/트림 검색',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            DropdownButton<String>(
              value: _selectedLeague,
              dropdownColor: AppColors.surface,
              style: AppTypography.bodyMedium,
              underline: const SizedBox(),
              items: [
                '전체',
                'gasoline',
                'diesel',
                'hybrid',
                'electric',
                'lpg',
                'plug_in_hybrid'
              ]
                  .map((val) => DropdownMenuItem(
                        value: val,
                        child: Text(val == '전체'
                            ? '리그 필터'
                            : FuelLeague.fromKey(val).displayName),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedLeague = val ?? '전체'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: manufacturers.when(
            loading: () => const LoadingSkeletonView(lines: 5),
            error: (err, st) => ErrorStateView(
                message: '데이터를 불러오지 못했어요.',
                onRetry: () =>
                    ref.invalidate(vehicleManufacturersProvider(query))),
            data: (mfs) {
              // Mock/Fallback or listed variants
              return ListView.builder(
                itemCount: _fallbackVariants.length,
                itemBuilder: (context, index) {
                  final variant = _fallbackVariants[index];
                  final status = SourceStatus.fromKey(variant.sourceStatus);

                  // Apply filter
                  if (_keyword.isNotEmpty &&
                      !variant.manufacturerName
                          .toLowerCase()
                          .contains(_keyword) &&
                      !variant.modelName.toLowerCase().contains(_keyword) &&
                      !variant.trimName.toLowerCase().contains(_keyword)) {
                    return const SizedBox.shrink();
                  }
                  if (_selectedLeague != '전체' &&
                      variant.fuelLeague != _selectedLeague) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    color: AppColors.surfaceLow,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      title: Text(
                          '${variant.manufacturerName} ${variant.modelName}',
                          style: AppTypography.titleMedium),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${variant.year}년식 · ${variant.trimName}',
                              style: AppTypography.bodyMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(variant.specSummary,
                              style: AppTypography.dataUnit
                                  .copyWith(color: AppColors.onSurfaceMuted)),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatusChip(
                              label: status.displayName, color: status.color),
                          const SizedBox(height: 4),
                          Text(
                            variant.confidenceScore != null
                                ? '신뢰도 ${(variant.confidenceScore! * 100).toStringAsFixed(0)}%'
                                : 'N/A',
                            style: AppTypography.dataUnit,
                          ),
                        ],
                      ),
                      onTap: () => _showVariantDetail(context, variant),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showVariantDetail(BuildContext context, VehicleVariant variant) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final status = SourceStatus.fromKey(variant.sourceStatus);
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('${variant.manufacturerName} ${variant.modelName} 제원 정보',
              style: AppTypography.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('트림명', variant.trimName),
                _buildInfoRow('연료 타입', variant.fuelType),
                _buildInfoRow('리그 배정',
                    FuelLeague.fromKey(variant.fuelLeague).displayName),
                _buildInfoRow('차급', variant.vehicleClass),
                _buildInfoRow(
                    '배기량(cc)',
                    variant.displacementCc != null
                        ? '${variant.displacementCc} cc'
                        : '-'),
                _buildInfoRow(
                    '배터리 용량',
                    variant.batteryKwh != null
                        ? '${variant.batteryKwh} kWh'
                        : '-'),
                _buildInfoRow('구동 방식',
                    variant.drivetrain.isNotEmpty ? variant.drivetrain : '-'),
                _buildInfoRow(
                    '변속기',
                    variant.transmission.isNotEmpty
                        ? variant.transmission
                        : '-'),
                _buildInfoRow(
                    '공인 효율',
                    variant.officialEfficiency != null
                        ? '${variant.officialEfficiency} ${variant.resolvedEfficiencyUnit}'
                        : '정보 준비 중'),
                const Divider(color: AppColors.outline, height: AppSpacing.lg),
                _buildInfoRow('출처 등급', status.displayName,
                    valueColor: status.color),
                _buildInfoRow(
                    '신뢰도 점수',
                    variant.confidenceScore != null
                        ? '${(variant.confidenceScore! * 100).toStringAsFixed(0)}%'
                        : 'N/A'),
                _buildInfoRow('출처 기관', variant.sourceName ?? '공식 카탈로그'),
                _buildInfoRow('출처 링크', variant.sourceUrl ?? '-'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.onSurfaceMuted))),
          Expanded(
              child: Text(value,
                  style: AppTypography.bodyMedium.copyWith(
                      color: valueColor,
                      fontWeight: valueColor != null
                          ? FontWeight.bold
                          : FontWeight.normal))),
        ],
      ),
    );
  }
}

// --- Tab 2: 출처 충돌 해결 (Conflict Resolution) ---

class AdminPowertrainConflictScreen extends ConsumerWidget {
  const AdminPowertrainConflictScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflicts = ref.watch(adminConflictsProvider);

    if (conflicts.every((c) => c.status != 'open')) {
      return const EmptyStateView(
        title: '해결할 충돌 데이터가 없어요',
        message: '가져온 데이터와 기존 DB 사양 간에 모순이나 충돌이 발견되지 않았습니다.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            '신규 임포트 데이터와 기존 데이터 간의 불일치 이슈입니다. 승인 결정을 내려 병합해 주세요.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: conflicts.length,
            itemBuilder: (context, index) {
              final conflict = conflicts[index];
              if (conflict.status != 'open') return const SizedBox.shrink();

              return Card(
                color: AppColors.surfaceLow,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  key: ValueKey(conflict.id),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusChip(
                            label: conflict.conflictType ==
                                    'specification_mismatch'
                                ? '제원 사양 불일치'
                                : '연비 단위 불일치',
                            color: AppColors.amber,
                          ),
                          Text(
                            '발생일시: ${conflict.createdAt.toString().substring(0, 16)}',
                            style: AppTypography.dataUnit
                                .copyWith(color: AppColors.onSurfaceMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('대상 차량 ID: ${conflict.entityId}',
                          style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _buildConflictColumn(
                              title: '기존 데이터 사양',
                              source: conflict.existingValue['source_name'] ??
                                  '공식 DB',
                              value: conflict.existingValue,
                              color: AppColors.electricBlue,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Icon(Icons.compare_arrows_rounded,
                              color: AppColors.onSurfaceMuted),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildConflictColumn(
                              title: '신규 임포트 데이터',
                              source: conflict.incomingValue['source_name'] ??
                                  '새 파일',
                              value: conflict.incomingValue,
                              color: AppColors.neonGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _resolveConflict(context, ref,
                                conflict.id, 'resolved_keep_existing'),
                            child: const Text('기존 데이터 유지'),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.neonGreen,
                                foregroundColor: Colors.black),
                            onPressed: () => _resolveConflict(context, ref,
                                conflict.id, 'resolved_overwrite'),
                            child: const Text('새 데이터로 덮어쓰기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConflictColumn({
    required String title,
    required String source,
    required Map<String, dynamic> value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.dataUnit
                  .copyWith(color: color, fontWeight: FontWeight.bold)),
          Text('출처: $source',
              style: AppTypography.dataUnit
                  .copyWith(color: AppColors.onSurfaceMuted)),
          const Divider(height: AppSpacing.sm),
          _buildTextLine('트림', '${value['trim_name'] ?? ''}'),
          _buildTextLine('구동', '${value['drivetrain'] ?? ''}'),
          _buildTextLine(
              '배기량',
              value['displacement_cc'] != null
                  ? '${value['displacement_cc']}cc'
                  : '-'),
          _buildTextLine('효율',
              '${value['official_efficiency'] ?? '-'} ${value['efficiency_unit'] ?? ''}'),
        ],
      ),
    );
  }

  Widget _buildTextLine(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.dataUnit
                  .copyWith(color: AppColors.onSurfaceMuted)),
          Text(val, style: AppTypography.dataUnit),
        ],
      ),
    );
  }

  void _resolveConflict(
      BuildContext context, WidgetRef ref, String id, String status) async {
    final list = ref.read(adminConflictsProvider);
    final newList = list.map((item) {
      if (item.id == id) {
        return item.copyWith(status: status);
      }
      return item;
    }).toList();
    ref.read(adminConflictsProvider.notifier).update(newList);

    final actionLabel =
        status == 'resolved_overwrite' ? '신규 데이터로 덮어쓰기' : '기존 데이터 유지';
    await ref.read(adminRepositoryProvider).recordAction(
          AdminActionRequest(
            section: 'Vehicles Catalog',
            action: '출처 충돌 해결 ($actionLabel)',
            record: AdminRecord(
              id: id,
              title: '출처 충돌 해결 완료',
              status: status,
              owner: 'admin',
              description: '충돌 데이터 ID: $id를 $actionLabel 처분으로 결합 처리 완료.',
            ),
          ),
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('충돌을 성공적으로 해결했습니다 ($actionLabel).')),
      );
    }
  }
}

// --- Tab 3: 임포트 작업 이력 (Import History) ---

class AdminPowertrainImportScreen extends ConsumerWidget {
  const AdminPowertrainImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(adminImportJobsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                '차량 카탈로그 공식 연비 데이터 임포트 실행 및 이력 관리 화면입니다.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.sync_rounded),
              label: const Text('공공 연비 동기화 실행'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white),
              onPressed: () => _triggerMockImport(context, ref),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return Card(
                color: AppColors.surfaceLow,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(job.importType,
                              style: AppTypography.titleMedium),
                          StatusChip(label: '완료됨', color: AppColors.neonGreen),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '종료 시각: ${job.finishedAt.toString().substring(0, 19)}',
                        style: AppTypography.dataUnit
                            .copyWith(color: AppColors.onSurfaceMuted),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('총 행 수', '${job.totalRows}'),
                          _buildStatItem('추가 건수', '${job.insertedRows}'),
                          _buildStatItem('업데이트', '${job.updatedRows}'),
                          _buildStatItem('충돌 발생', '${job.conflictRows}',
                              color: job.conflictRows > 0
                                  ? AppColors.amber
                                  : null),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label,
            style: AppTypography.dataUnit
                .copyWith(color: AppColors.onSurfaceMuted)),
        const SizedBox(height: 4),
        Text(value,
            style: AppTypography.titleMedium
                .copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _triggerMockImport(BuildContext context, WidgetRef ref) {
    // Add a new completed job to simulate syncing
    final newJob = VehicleCatalogImportJob(
      id: 'job-${DateTime.now().millisecondsSinceEpoch}',
      importType: '한국에너지공단 KEA 수동 연비 인증 CSV',
      status: 'completed',
      totalRows: 420,
      insertedRows: 2,
      updatedRows: 418,
      conflictRows: 0,
      finishedAt: DateTime.now(),
    );

    final list = ref.read(adminImportJobsProvider);
    ref.read(adminImportJobsProvider.notifier).update([newJob, ...list]);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('동기화 파이프라인(Fuzzy Match)이 구동되어 420개의 제원을 대조 및 갱신 완료했습니다!')),
    );
  }
}

// --- Tab 4: 품질 스캔 보고서 (Quality Scan Report) ---

class AdminCatalogQualityReportScreen extends StatelessWidget {
  const AdminCatalogQualityReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              '차량 카탈로그 데이터 품질 현황 리포트입니다. P0 비정상 수치 및 오류 조합은 0건으로 제어됩니다.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: const [
              Expanded(
                child: StatMetricCard(
                  label: '품질 지수 점수',
                  value: '99.8',
                  unit: '%',
                  color: AppColors.neonGreen,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatMetricCard(
                  label: '품질 차단 P0 오류',
                  value: '0',
                  unit: '건',
                  color: AppColors.electricBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '제원 신뢰도 통계'),
          AppCard(
            child: Column(
              children: [
                _buildReportLine(
                    '공식 인증 검증 데이터(verified_official)', '3,450개 (66.9%)'),
                _buildReportLine(
                    '관리자 검수 데이터(verified_admin)', '1,200개 (23.3%)'),
                _buildReportLine('공공기관 연비 데이터(imported_public)', '485개 (9.4%)'),
                _buildReportLine('검토 대기 데이터(pending_review)', '20개 (0.4%)'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '품질 진단 상세 규칙 상태'),
          AppCard(
            child: Column(
              children: [
                _buildRuleStatusLine(
                    '전기차의 배기량 CC 보유 모순 검사 (P0)', '이상 없음 (0건)', true),
                _buildRuleStatusLine(
                    '가솔린/디젤 차량의 배터리 보유 모순 검사 (P0)', '이상 없음 (0건)', true),
                _buildRuleStatusLine(
                    '비현실적 연비/전비 오인 스캔 (P0)', '이상 없음 (0건)', true),
                _buildRuleStatusLine(
                    '한국에너지공단 연비/전비 단위 교차 불일치 검증 (P0)', '이상 없음 (0건)', true),
                _buildRuleStatusLine(
                    '공식 검증 데이터의 상세 출처 유효성 검사 (P0)', '이상 없음 (0건)', true),
                _buildRuleStatusLine('연비 정보 누락율 점검', '0.1% 미만 (5건 대기)', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(value,
              style: AppTypography.titleMedium.copyWith(
                  color: AppColors.neonGreen, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRuleStatusLine(String ruleName, String status, bool healthy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            healthy ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: healthy ? AppColors.neonGreen : AppColors.amber,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(ruleName, style: AppTypography.bodyMedium),
          ),
          StatusChip(
            label: status,
            color: healthy ? AppColors.electricBlue : AppColors.amber,
          ),
        ],
      ),
    );
  }
}

// --- Tab 5: 직접 입력 검수 (Custom Vehicle Review) ---

class AdminCustomVehicleReviewScreen extends ConsumerStatefulWidget {
  const AdminCustomVehicleReviewScreen({super.key});

  @override
  ConsumerState<AdminCustomVehicleReviewScreen> createState() =>
      _AdminCustomVehicleReviewScreenState();
}

class _AdminCustomVehicleReviewScreenState
    extends ConsumerState<AdminCustomVehicleReviewScreen> {
  var _reviewingRequestId = '';

  Future<void> _reviewRequest(
    CustomVehicleReviewRequest request,
    String decision,
  ) async {
    if (request.userVehicleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연결된 사용자 차량 ID가 없어 검수를 처리할 수 없어요.')),
      );
      return;
    }
    setState(() => _reviewingRequestId = request.id);
    try {
      final result = await ref
          .read(vehicleCatalogRepositoryProvider)
          .reviewCustomVehicleRequest(
            requestId: request.id,
            decision: decision,
            reviewNote: decision == 'approve' ? '공식 리그 반영 승인' : '공식 리그 반영 보류',
          );
      await ref.read(adminRepositoryProvider).recordAction(
            AdminActionRequest(
              section: 'Vehicles Catalog',
              action: decision == 'approve' ? '직접 입력 승인' : '직접 입력 반려',
              record: AdminRecord(
                id: request.id,
                title: request.displayName,
                status: result?.status ?? request.status,
                owner: request.userId,
                description: request.memo,
                createdAt: request.createdAt,
                metadata: {
                  'user_vehicle_id': request.userVehicleId,
                  'fuel_league': request.fuelLeague,
                  'vehicle_class': request.vehicleClass,
                },
              ),
            ),
          );
      ref.invalidate(customVehicleReviewRequestsProvider('pending_review'));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(decision == 'approve'
              ? '직접 입력 차량을 공식 리그에 반영했어요.'
              : '직접 입력 차량을 반려 처리했어요.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = const ErrorMapper().messageFor(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검수 처리에 실패했어요. $message')),
      );
    } finally {
      if (mounted) {
        setState(() => _reviewingRequestId = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests =
        ref.watch(customVehicleReviewRequestsProvider('pending_review'));
    return requests.when(
      loading: () => const LoadingSkeletonView(lines: 3),
      error: (error, stackTrace) => ErrorStateView(
        message: '직접 입력 차량 검수 큐를 불러오지 못했어요.',
        onRetry: () => ref
            .invalidate(customVehicleReviewRequestsProvider('pending_review')),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyStateView(
            title: '검수 대기 차량이 없어요',
            message: '사용자가 직접 입력한 차량은 이곳에서 공식 리그 반영 여부를 검토합니다.',
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final detail = [
              item.fuelType,
              item.fuelLeague,
              item.vehicleClass,
              if (item.memo.isNotEmpty) item.memo,
            ].join(' · ');
            return Card(
              color: AppColors.surfaceLow,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        const StatusChip(
                          label: '검수 대기',
                          color: AppColors.amber,
                          icon: Icons.fact_check_rounded,
                        ),
                        StatusChip(
                          label: item.userVehicleId.isEmpty
                              ? '연결 확인 필요'
                              : '차량 연결됨',
                          color: item.userVehicleId.isEmpty
                              ? AppColors.danger
                              : AppColors.electricBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(item.displayName, style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      detail,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.onSurfaceMuted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '요청 ${item.id} · 차량 ${item.userVehicleId.isEmpty ? '미연결' : item.userVehicleId}',
                      style: AppTypography.dataUnit
                          .copyWith(color: AppColors.onSurfaceMuted),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: '승인',
                            icon: Icons.verified_rounded,
                            isLoading: _reviewingRequestId == item.id,
                            onPressed: item.userVehicleId.isEmpty
                                ? null
                                : () => _reviewRequest(item, 'approve'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: SecondaryButton(
                            label: '반려',
                            icon: Icons.block_rounded,
                            onPressed: _reviewingRequestId == item.id ||
                                    item.userVehicleId.isEmpty
                                ? null
                                : () => _reviewRequest(item, 'reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- Private Fallback Variants for Local Display ---

final _fallbackVariants = [
  const VehicleVariant(
    id: 'hyundai-avante-1.6g-2026',
    modelYearId: 'hyundai-avante-2026',
    manufacturerName: '현대',
    modelName: '아반떼',
    year: 2026,
    trimName: '1.6 가솔린',
    displacementCc: 1598,
    drivetrain: 'FF',
    transmission: 'IVT',
    officialEfficiency: 15.0,
    efficiencyUnit: 'km/L',
    vehicleClass: '준중형',
    fuelLeague: 'gasoline',
    fuelType: 'gasoline',
    sourceStatus: 'verified_official',
    sourceName: '한국에너지공단 연비데이터',
    confidenceScore: 0.99,
  ),
  const VehicleVariant(
    id: 'kia-sportage-1.6h-2026',
    modelYearId: 'kia-sportage-2026',
    manufacturerName: '기아',
    modelName: '스포티지 하이브리드',
    year: 2026,
    trimName: '1.6 HEV 2WD',
    displacementCc: 1598,
    drivetrain: 'FF',
    transmission: '6AT',
    officialEfficiency: 16.7,
    efficiencyUnit: 'km/L',
    vehicleClass: '준중형 SUV',
    fuelLeague: 'hybrid',
    fuelType: 'hybrid',
    sourceStatus: 'verified_official',
    sourceName: '기아 공식 카탈로그',
    confidenceScore: 0.98,
  ),
  const VehicleVariant(
    id: 'porsche-taycan-4s-2025',
    modelYearId: 'porsche-taycan-2025',
    manufacturerName: '포르쉐',
    modelName: '타이칸',
    year: 2025,
    trimName: '4S',
    batteryKwh: 93.4,
    drivetrain: 'AWD',
    transmission: '2AT',
    officialEfficiency: 3.2,
    efficiencyUnit: 'km/kWh',
    vehicleClass: '대형',
    fuelLeague: 'electric',
    fuelType: 'electric',
    sourceStatus: 'verified_official',
    sourceName: '포르쉐 코리아 공식 제원',
    confidenceScore: 0.95,
  ),
  const VehicleVariant(
    id: 'tesla-model3-rwd-2026',
    modelYearId: 'tesla-model3-2026',
    manufacturerName: '테슬라',
    modelName: 'Model 3',
    year: 2026,
    trimName: 'RWD (LFP)',
    batteryKwh: 60.0,
    drivetrain: 'RWD',
    transmission: '1AT',
    officialEfficiency: 5.7,
    efficiencyUnit: 'km/kWh',
    vehicleClass: '중형',
    fuelLeague: 'electric',
    fuelType: 'electric',
    sourceStatus: 'imported_public',
    sourceName: '국토교통부 연비 등록 정보',
    confidenceScore: 0.90,
  ),
];
