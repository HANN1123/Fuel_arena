import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/widgets/widgets.dart';

class AdminVehicleGenerationScreen extends StatelessWidget {
  const AdminVehicleGenerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdminGenerationScaffold(
      title: '차량 세대 관리',
      subtitle: '모델별 세대 목록',
      items: const [
        '제조사별 세대 목록',
        '모델별 세대 코드와 판매 기간',
        '세대별 model_year 매핑',
        '세대별 파워트레인 연결 상태',
      ],
      actions: [
        _AdminGenerationAction(
          label: '세대 CSV 가져오기',
          icon: Icons.upload_file_rounded,
          route: '/admin/vehicle-generations/import',
        ),
        _AdminGenerationAction(
          label: 'Coverage 리포트',
          icon: Icons.analytics_rounded,
          route: '/admin/vehicle-generations/quality',
        ),
        _AdminGenerationAction(
          label: 'BMW 감사',
          icon: Icons.manage_search_rounded,
          route: '/admin/vehicle-generations/bmw',
        ),
      ],
    );
  }
}

class AdminGenerationImportScreen extends StatelessWidget {
  const AdminGenerationImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminGenerationScaffold(
      title: '세대 데이터 가져오기',
      subtitle: 'CSV/JSON import 검수',
      items: [
        'generation_template.csv 기준 업로드',
        'source_status와 confidence_score 확인',
        'source 없는 verified 데이터 차단',
        '변경 로그 기록',
      ],
      command:
          'dart run tool/vehicle_catalog/import_vehicle_generations.dart --generations assets/data/vehicle_catalog_sources/generation_template.csv --powertrains assets/data/vehicle_catalog_sources/powertrain_generation_template.csv',
    );
  }
}

class AdminGenerationQualityReportScreen extends StatelessWidget {
  const AdminGenerationQualityReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminGenerationScaffold(
      title: '세대 품질 리포트',
      subtitle: 'coverage와 P0 결함',
      items: [
        '세대 없는 모델',
        '파워트레인 없는 세대',
        'generation_id 없는 model_year',
        '검증 출처 없는 verified 데이터',
      ],
      command:
          'dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs',
      artifactPath: 'docs/61_vehicle_catalog_coverage_report.md',
    );
  }
}

class AdminBMWCatalogReviewScreen extends StatelessWidget {
  const AdminBMWCatalogReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminGenerationScaffold(
      title: 'BMW 카탈로그 검토',
      subtitle: '모델/세대/파워트레인 감사',
      items: [
        'Series, X, i, M, Z 계열 분류',
        'electric/PHEV/ICE fuelLeague 점검',
        '한국 시장 판매 여부',
        'conflict/pending_review/deprecated 정리',
      ],
      command:
          'dart run tool/vehicle_catalog/generate_catalog_quality_report.dart --fail-on-p0 --write-docs',
      artifactPath: 'docs/62_bmw_catalog_audit_matrix.md',
    );
  }
}

class _AdminGenerationAction {
  const _AdminGenerationAction({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class _AdminGenerationScaffold extends StatelessWidget {
  const _AdminGenerationScaffold({
    required this.title,
    required this.subtitle,
    required this.items,
    this.actions = const [],
    this.command,
    this.artifactPath,
  });

  final String title;
  final String subtitle;
  final List<String> items;
  final List<_AdminGenerationAction> actions;
  final String? command;
  final String? artifactPath;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: FuelArenaAppBar(
        title: title,
        subtitle: subtitle,
        showBack: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: actions
                  .map(
                    (action) => SecondaryButton(
                      label: action.label,
                      icon: action.icon,
                      onPressed: () => context.go(action.route),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (command != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: '운영 명령'),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SelectableText(
                command!,
                style: AppTypography.dataUnit.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
          if (artifactPath != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              borderColor: AppColors.electricBlue.withValues(alpha: 0.24),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_rounded,
                    color: AppColors.electricBlue,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SelectableText(
                      artifactPath!,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fact_check_rounded,
                      color: AppColors.neonGreen,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(item, style: AppTypography.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
