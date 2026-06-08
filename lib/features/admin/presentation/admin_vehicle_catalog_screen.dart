import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class AdminVehicleCatalogScreen extends ConsumerStatefulWidget {
  const AdminVehicleCatalogScreen({super.key});

  @override
  ConsumerState<AdminVehicleCatalogScreen> createState() =>
      _AdminVehicleCatalogScreenState();
}

class _AdminVehicleCatalogScreenState
    extends ConsumerState<AdminVehicleCatalogScreen> {
  var _keyword = '';
  var _selectedPolicy = '검수 대기';

  static const _policies = [
    '검수 대기',
    '공식 리그 반영',
    '직접 입력 제한',
    '연비 단위 점검',
  ];

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final manufacturerQuery = VehicleManufacturerQuery(keyword: _keyword);
    final manufacturers =
        ref.watch(vehicleManufacturersProvider(manufacturerQuery));

    return AppScaffold(
      maxWidth: null,
      appBar: const FuelArenaAppBar(
          title: '차량 카탈로그 운영', subtitle: '운영 카탈로그', showBack: true),
      child: profile.when(
        loading: () => const LoadingSkeletonView(lines: 3),
        error: (error, stackTrace) => MappedErrorStateView(error: error),
        data: (user) {
          if (!user.isAdmin) {
            return const ErrorStateView(message: '관리자만 차량 카탈로그를 관리할 수 있어요.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('차량 DB와 리그를\n함께 관리해요',
                  style: AppTypography.displayScore
                      .copyWith(color: AppColors.neonGreen)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '직접 입력 차량은 검수 대기로 묶고, 검증된 카탈로그만 공식 랭킹과 배틀 리그에 반영합니다.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              _CatalogMetricRow(manufacturers: manufacturers),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: '운영 정책'),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: _policies.map((policy) {
                  final selected = policy == _selectedPolicy;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(policy),
                    selectedColor: AppColors.neonGreen.withValues(alpha: 0.18),
                    backgroundColor: AppColors.surfaceLow,
                    side: BorderSide(
                        color: selected
                            ? AppColors.neonGreen
                            : Colors.white.withValues(alpha: 0.1)),
                    onSelected: (_) => setState(() => _selectedPolicy = policy),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              _PolicyDetail(policy: _selectedPolicy),
              const SizedBox(height: AppSpacing.lg),
              const _CatalogToolingPanel(),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                onChanged: (value) => setState(() => _keyword = value.trim()),
                decoration: const InputDecoration(
                  labelText: '제조사 검색',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: '제조사 카탈로그'),
              manufacturers.when(
                loading: () => const LoadingSkeletonView(lines: 4),
                error: (error, stackTrace) => MappedErrorStateView(
                  error: error,
                  onRetry: () => ref.invalidate(
                    vehicleManufacturersProvider(manufacturerQuery),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStateView(
                        title: '검색 결과가 없어요', message: '다른 제조사 이름으로 검색해 주세요.');
                  }
                  return Column(
                    children: items
                        .map(
                          (item) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _ManufacturerAdminTile(manufacturer: item),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: '검수 큐'),
              const _ReviewQueueCard(),
            ],
          );
        },
      ),
    );
  }
}

class _CatalogToolingPanel extends StatelessWidget {
  const _CatalogToolingPanel();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 860;
        final cards = [
          _ToolCard(
            title: 'CSV 가져오기',
            body:
                'assets/data/vehicle_catalog_kr_sample.csv 형식으로 운영 데이터를 준비하고 가져오기 도구로 SQL을 생성합니다.',
            icon: Icons.upload_file_rounded,
            actionLabel: '가져오기 명령 보기',
            onTap: () => _showCommand(
              context,
              title: '차량 카탈로그 import',
              command:
                  'dart run tool/import_vehicle_catalog.dart --in assets/data/vehicle_catalog_kr_seed.json --out supabase/seed_vehicle_catalog.sql',
            ),
          ),
          _ToolCard(
            title: 'JSON 내보내기',
            body:
                '앱 내 기본 카탈로그 자산은 assets/data/vehicle_catalog_kr_seed.json을 사용합니다.',
            icon: Icons.data_object_rounded,
            actionLabel: 'asset 위치 보기',
            onTap: () => _showCommand(
              context,
              title: 'JSON export 위치',
              command: 'assets/data/vehicle_catalog_kr_seed.json',
            ),
          ),
          _ToolCard(
            title: '무결성 검사',
            body: '제조사, 모델, 연식, 파워트레인, 연료 리그, 효율 단위 연결을 배포 전 검증합니다.',
            icon: Icons.verified_rounded,
            actionLabel: '검증 명령 보기',
            onTap: () => _showCommand(
              context,
              title: '카탈로그 무결성 검사',
              command: 'dart run tool/validate_vehicle_catalog.dart',
            ),
          ),
        ];
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cards
                .map((card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        child: card,
                      ),
                    ))
                .toList(),
          );
        }
        return Column(
          children: cards
              .map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: card,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String body;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.neonGreen, size: 28),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(body,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: actionLabel,
            icon: Icons.terminal_rounded,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

void _showCommand(BuildContext context,
    {required String title, required String command}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SelectableText(command),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
}

class _CatalogMetricRow extends StatelessWidget {
  const _CatalogMetricRow({required this.manufacturers});

  final AsyncValue<List<VehicleManufacturer>> manufacturers;

  @override
  Widget build(BuildContext context) {
    final count = manufacturers.asData?.value.length ?? 0;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        SizedBox(
            width: 170,
            child: StatMetricCard(label: '제조사', value: '$count', unit: '개')),
        const SizedBox(
            width: 170,
            child: StatMetricCard(
                label: '검수 대기',
                value: '12',
                unit: '건',
                color: AppColors.amber)),
        const SizedBox(
            width: 170,
            child: StatMetricCard(label: '공식 리그', value: '6', unit: '종')),
      ],
    );
  }
}

class _PolicyDetail extends StatelessWidget {
  const _PolicyDetail({required this.policy});

  final String policy;

  @override
  Widget build(BuildContext context) {
    final body = switch (policy) {
      '공식 리그 반영' => '검증 완료 차량만 시즌 점수, 랭킹, 공식 배틀에 반영합니다.',
      '직접 입력 제한' => '사용자 직접 입력 차량은 검수 대기 상태로 저장하고 운영자 검수 전까지 친선전만 허용합니다.',
      '연비 단위 점검' => '전기차는 km/kWh, 내연기관과 하이브리드는 km/L 기준으로 표시합니다.',
      _ => '카탈로그에 없는 차량, 이상 연비, 중복 모델명은 검수 큐에서 확인합니다.',
    };
    return AppCard(
      borderColor: AppColors.electricBlue.withValues(alpha: 0.24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rule_rounded, color: AppColors.electricBlue),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(policy, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(body,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.onSurfaceMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManufacturerAdminTile extends StatelessWidget {
  const _ManufacturerAdminTile({required this.manufacturer});

  final VehicleManufacturer manufacturer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.factory_rounded,
              color: AppColors.neonGreen, size: 34),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(manufacturer.nameKo, style: AppTypography.titleMedium),
                Text(
                  [manufacturer.nameEn, manufacturer.country]
                      .where((item) => item.isNotEmpty)
                      .join(' · '),
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.onSurfaceMuted),
                ),
              ],
            ),
          ),
          StatusChip(
            label: manufacturer.isPopular ? '인기' : '일반',
            color: manufacturer.isPopular
                ? AppColors.neonGreen
                : AppColors.outline,
          ),
        ],
      ),
    );
  }
}

class _ReviewQueueCard extends ConsumerStatefulWidget {
  const _ReviewQueueCard();

  @override
  ConsumerState<_ReviewQueueCard> createState() => _ReviewQueueCardState();
}

class _ReviewQueueCardState extends ConsumerState<_ReviewQueueCard> {
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
        return Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _CustomVehicleReviewTile(
                    request: item,
                    isLoading: _reviewingRequestId == item.id,
                    onApprove: () => _reviewRequest(item, 'approve'),
                    onReject: () => _reviewRequest(item, 'reject'),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CustomVehicleReviewTile extends StatelessWidget {
  const _CustomVehicleReviewTile({
    required this.request,
    required this.isLoading,
    required this.onApprove,
    required this.onReject,
  });

  final CustomVehicleReviewRequest request;
  final bool isLoading;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final detail = [
      request.fuelType,
      request.fuelLeague,
      request.vehicleClass,
      if (request.memo.isNotEmpty) request.memo,
    ].join(' · ');
    return AppCard(
      borderColor: AppColors.amber.withValues(alpha: 0.28),
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
                label: request.userVehicleId.isEmpty ? '연결 확인 필요' : '차량 연결됨',
                color: request.userVehicleId.isEmpty
                    ? AppColors.danger
                    : AppColors.electricBlue,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(request.displayName, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            '요청 ${request.id} · 차량 ${request.userVehicleId.isEmpty ? '미연결' : request.userVehicleId}',
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
                  isLoading: isLoading,
                  onPressed: request.userVehicleId.isEmpty ? null : onApprove,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SecondaryButton(
                  label: '반려',
                  icon: Icons.block_rounded,
                  onPressed: isLoading || request.userVehicleId.isEmpty
                      ? null
                      : onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
