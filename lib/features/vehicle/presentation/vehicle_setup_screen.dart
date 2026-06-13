import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_layout.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';
import '../domain/vehicle_powertrain_taxonomy.dart' hide FuelLeague;

Future<void> _refreshVehicleSetupState(
  WidgetRef ref, {
  String? primaryVehicleId,
}) async {
  final localState = ref.read(localStateServiceProvider);
  await localState.markVehicleSetupCompleted();
  if (primaryVehicleId != null && primaryVehicleId.isNotEmpty) {
    await localState.saveRecentPrimaryVehicle(primaryVehicleId);
  }
  ref
    ..invalidate(restoredSessionProvider)
    ..invalidate(primaryVehicleProvider)
    ..invalidate(vehiclesProvider)
    ..invalidate(homeSnapshotProvider)
    ..invalidate(profileProvider);
}

class VehicleSetupScreen extends ConsumerStatefulWidget {
  const VehicleSetupScreen({super.key});

  @override
  ConsumerState<VehicleSetupScreen> createState() => _VehicleSetupScreenState();
}

class _VehicleSetupScreenState extends ConsumerState<VehicleSetupScreen> {
  var _selection = const VehicleSelectionState();
  var _query = '';
  var _manufacturerCountry = '';
  var _saving = false;
  String? _saveError;
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  String get _stepLabel {
    return switch (_selection.currentStep) {
      VehicleSelectionStep.manufacturer => '1/6 제조사 선택',
      VehicleSelectionStep.fuelType => '2/6 연료 선택',
      VehicleSelectionStep.category => '3/6 범주 선택',
      VehicleSelectionStep.model => '4/6 모델 선택',
      VehicleSelectionStep.generation => '5/6 세대 선택',
      VehicleSelectionStep.powertrain => '6/6 파워트레인 선택',
      VehicleSelectionStep.confirm => '선택 확인',
    };
  }

  void _goTo(VehicleSelectionStep step) {
    setState(() {
      _query = '';
      _selection = _selection.copyWith(currentStep: step);
    });
  }

  Future<void> _saveSelection() async {
    final variant = _selection.selectedVariant;
    if (variant == null) {
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final nickname = _nicknameController.text.trim();
      final userVehicle = await ref
          .read(userVehicleRepositoryProvider)
          .addUserVehicleFromVariant(
            variant.id,
            nickname.isEmpty
                ? '${variant.modelName} ${variant.trimName}'
                : nickname,
            _selection.isPrimary,
          );
      await ref
          .read(userVehicleRepositoryProvider)
          .assignLeagueForVehicle(userVehicle.id);
      await _refreshVehicleSetupState(ref, primaryVehicleId: userVehicle.id);
      try {
        await ref
            .read(analyticsRepositoryProvider)
            .track('vehicle_setup_completed', properties: {
          'fuel_league': variant.fuelLeague,
          'vehicle_class': variant.vehicleClass,
          'variant_id': variant.id,
        });
      } catch (_) {}
      if (!mounted) {
        return;
      }
      context.go('/vehicle/complete');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _saveError = '차량 설정을 저장하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar:
          FuelArenaAppBar(title: '차량 설정', subtitle: _stepLabel, showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VehicleSetupProgressIndicator(step: _selection.currentStep),
          const SizedBox(height: AppSpacing.md),
          VehicleSetupBreadcrumb(selection: _selection, onTap: _goTo),
          const SizedBox(height: AppSpacing.lg),
          if (_showsSearchField) ...[
            VehicleSearchField(
              hintText: switch (_selection.currentStep) {
                VehicleSelectionStep.manufacturer => '제조사 검색',
                VehicleSelectionStep.fuelType => '',
                VehicleSelectionStep.category => '',
                VehicleSelectionStep.model => '모델 검색',
                VehicleSelectionStep.generation => '세대/코드 검색',
                VehicleSelectionStep.powertrain => '파워트레인 검색',
                VehicleSelectionStep.confirm => '',
              },
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _buildCurrentStep(),
          if (_selection.breadcrumb.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            VehicleSelectionSummaryCard(selection: _selection),
          ],
        ],
      ),
    );
  }

  bool get _showsSearchField {
    return switch (_selection.currentStep) {
      VehicleSelectionStep.manufacturer ||
      VehicleSelectionStep.model ||
      VehicleSelectionStep.generation ||
      VehicleSelectionStep.powertrain =>
        true,
      VehicleSelectionStep.fuelType ||
      VehicleSelectionStep.category ||
      VehicleSelectionStep.confirm =>
        false,
    };
  }

  Widget _buildCurrentStep() {
    return switch (_selection.currentStep) {
      VehicleSelectionStep.manufacturer => _ManufacturerStep(
          keyword: _query,
          country: _manufacturerCountry,
          onCountryChanged: (country) {
            setState(() => _manufacturerCountry = country);
          },
          onSelected: (manufacturer) {
            ref
                .read(analyticsRepositoryProvider)
                .track('vehicle_manufacturer_selected', properties: {
              'manufacturer_id': manufacturer.id,
              'country_filter':
                  _manufacturerCountry.isEmpty ? 'all' : _manufacturerCountry,
            });
            setState(() {
              _query = '';
              _selection = _selection.copyWith(
                selectedManufacturer: manufacturer,
                clearFuelType: true,
                clearCategory: true,
                clearModel: true,
                clearGeneration: true,
                clearYear: true,
                clearVariant: true,
                currentStep: VehicleSelectionStep.fuelType,
              );
            });
          },
        ),
      VehicleSelectionStep.fuelType => _FuelTypeStep(
          manufacturer: _selection.selectedManufacturer!,
          onSelected: (fuelType) {
            ref.read(analyticsRepositoryProvider).track(
              'vehicle_fuel_type_selected',
              properties: {'fuel_type': fuelType},
            );
            setState(() {
              _query = '';
              _selection = _selection.copyWith(
                selectedFuelType: fuelType,
                clearCategory: true,
                clearModel: true,
                clearGeneration: true,
                clearYear: true,
                clearVariant: true,
                currentStep: VehicleSelectionStep.category,
              );
            });
          },
        ),
      VehicleSelectionStep.category => _CategoryStep(
          manufacturer: _selection.selectedManufacturer!,
          fuelType: _selection.selectedFuelType,
          selectedCategory: _selection.selectedCategory,
          onSelected: (category) {
            ref.read(analyticsRepositoryProvider).track(
              'vehicle_category_selected',
              properties: {
                'fuel_type': _selection.selectedFuelType,
                'category': category.key,
              },
            );
            setState(() {
              _query = '';
              _selection = _selection.copyWith(
                selectedCategory: category,
                clearModel: true,
                clearGeneration: true,
                clearYear: true,
                clearVariant: true,
                currentStep: VehicleSelectionStep.model,
              );
            });
          },
        ),
      VehicleSelectionStep.model => _ModelStep(
          manufacturer: _selection.selectedManufacturer!,
          fuelType: _selection.selectedFuelType,
          category: _selection.selectedCategory,
          keyword: _query,
          onSelected: (summary) {
            ref
                .read(analyticsRepositoryProvider)
                .track('vehicle_model_selected', properties: {
              'model_id': summary.model.id,
              'fuel_type': _selection.selectedFuelType,
              'category': _selection.selectedCategory.key,
            });
            setState(() {
              _query = '';
              _selection = _selection.copyWith(
                selectedModel: summary.model,
                clearGeneration: true,
                clearYear: true,
                clearVariant: true,
                currentStep: VehicleSelectionStep.generation,
              );
            });
          },
        ),
      VehicleSelectionStep.generation => _GenerationStep(
          model: _selection.selectedModel!,
          manufacturer: _selection.selectedManufacturer!,
          fuelType: _selection.selectedFuelType,
          category: _selection.selectedCategory,
          keyword: _query,
          onSelected: (summary) {
            ref.read(analyticsRepositoryProvider).track(
              'vehicle_generation_selected',
              properties: {
                'model_id': _selection.selectedModel!.id,
                'generation_id': summary.generation.id,
                'generation_code': summary.generation.generationCode,
              },
            );
            setState(() {
              _query = '';
              _selection = _selection.copyWith(
                selectedGeneration: summary.generation,
                clearYear: true,
                clearVariant: true,
                currentStep: VehicleSelectionStep.powertrain,
              );
            });
          },
        ),
      VehicleSelectionStep.powertrain => _VariantStep(
          generation: _selection.selectedGeneration!,
          fuelType: _selection.selectedFuelType,
          category: _selection.selectedCategory,
          keyword: _query,
          onSelected: (choice) {
            final variant = choice.representative;
            ref
                .read(analyticsRepositoryProvider)
                .track('vehicle_variant_selected', properties: {
              'variant_id': variant.id,
              'generation_id': _selection.selectedGeneration!.id,
              'fuel_league': variant.fuelLeague,
              'valid_period': choice.periodLabel,
            });
            setState(() {
              _query = '';
              _nicknameController.text =
                  '${variant.modelName} ${variant.trimName}';
              _selection = _selection.copyWith(
                selectedVariant: variant,
                nickname: _nicknameController.text,
                currentStep: VehicleSelectionStep.confirm,
              );
            });
          },
        ),
      VehicleSelectionStep.confirm => _ConfirmStep(
          selection: _selection,
          nicknameController: _nicknameController,
          saving: _saving,
          errorMessage: _saveError,
          onPrimaryChanged: (value) => setState(
              () => _selection = _selection.copyWith(isPrimary: value)),
          onReset: () => _goTo(VehicleSelectionStep.manufacturer),
          onSave: _saveSelection,
        ),
    };
  }
}

class _ManufacturerStep extends ConsumerWidget {
  const _ManufacturerStep({
    required this.keyword,
    required this.country,
    required this.onCountryChanged,
    required this.onSelected,
  });

  final String keyword;
  final String country;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<VehicleManufacturer> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = VehicleManufacturerQuery(keyword: keyword, country: country);
    final manufacturers = ref.watch(vehicleManufacturersProvider(query));
    return manufacturers.when(
      loading: () => const LoadingSkeletonView(lines: 4),
      error: (error, stackTrace) => MappedErrorStateView(
        error: error,
        onRetry: () => ref.invalidate(vehicleManufacturersProvider(query)),
      ),
      data: (items) {
        final popular = items.where((item) => item.isPopular).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VehicleManufacturerCountryFilter(
              selectedCountry: country,
              onChanged: onCountryChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            if (popular.isNotEmpty && keyword.isEmpty) ...[
              const SectionHeader(title: '인기 제조사'),
              _ManufacturerGrid(items: popular, onSelected: onSelected),
              const SizedBox(height: AppSpacing.lg),
            ],
            const SectionHeader(title: '전체 제조사'),
            _ManufacturerGrid(items: items, onSelected: onSelected),
          ],
        );
      },
    );
  }
}

class VehicleManufacturerCountryFilter extends StatelessWidget {
  const VehicleManufacturerCountryFilter({
    super.key,
    required this.selectedCountry,
    required this.onChanged,
  });

  final String selectedCountry;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      _ManufacturerCountryOption(label: '전체', value: ''),
      _ManufacturerCountryOption(label: '국산', value: 'KR'),
      _ManufacturerCountryOption(label: '수입', value: 'IMPORT'),
    ];

    return Row(
      children: options.map((option) {
        final selected = selectedCountry == option.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option == options.last ? 0 : AppSpacing.xs,
            ),
            child: FilterChip(
              selected: selected,
              showCheckmark: false,
              label: Center(child: Text(option.label)),
              onSelected: (_) => onChanged(option.value),
              selectedColor: AppColors.neonGreen.withValues(alpha: 0.18),
              backgroundColor: AppColors.surfaceLow,
              side: BorderSide(
                color: selected
                    ? AppColors.neonGreen
                    : Colors.white.withValues(alpha: 0.1),
              ),
              labelStyle: AppTypography.dataUnit.copyWith(
                color: selected ? AppColors.neonGreen : AppColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ManufacturerCountryOption {
  const _ManufacturerCountryOption({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _ManufacturerGrid extends StatelessWidget {
  const _ManufacturerGrid({
    required this.items,
    required this.onSelected,
  });

  final List<VehicleManufacturer> items;
  final ValueChanged<VehicleManufacturer> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: AppCardSize.manufacturerHeight,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return CompactManufacturerCard(
          manufacturer: item,
          onTap: () => onSelected(item),
        );
      },
    );
  }
}

class _FuelTypeStep extends ConsumerWidget {
  const _FuelTypeStep({
    required this.manufacturer,
    required this.onSelected,
  });

  final VehicleManufacturer manufacturer;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuels =
        ref.watch(vehicleFuelTypesByManufacturerProvider(manufacturer.id));
    return fuels.when(
      loading: () => const LoadingSkeletonView(lines: 3),
      error: (error, stackTrace) => MappedErrorStateView(
        error: error,
        onRetry: () => ref.invalidate(
            vehicleFuelTypesByManufacturerProvider(manufacturer.id)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return CustomVehicleRequestCard(
              manufacturerName: manufacturer.nameKo);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: '${manufacturer.nameKo} 연료 타입'),
            const SizedBox(height: AppSpacing.sm),
            ...items.map(
              (fuelType) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: VehicleFuelTypeCard(
                  fuelType: fuelType,
                  onTap: () => onSelected(fuelType),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryStep extends ConsumerWidget {
  const _CategoryStep({
    required this.manufacturer,
    required this.fuelType,
    required this.selectedCategory,
    required this.onSelected,
  });

  final VehicleManufacturer manufacturer;
  final String fuelType;
  final VehicleCategoryFilter selectedCategory;
  final ValueChanged<VehicleCategoryFilter> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = VehicleFuelCategoryQuery(
      manufacturerId: manufacturer.id,
      fuelType: fuelType,
    );
    final categories = ref.watch(vehicleCategoriesByFuelProvider(query));
    return categories.when(
      loading: () => const LoadingSkeletonView(lines: 3),
      error: (error, stackTrace) => MappedErrorStateView(
        error: error,
        onRetry: () => ref.invalidate(vehicleCategoriesByFuelProvider(query)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return CustomVehicleRequestCard(
              manufacturerName: manufacturer.nameKo);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title:
                  '${FuelLeague.nameForKey(fuelType).replaceAll(' 리그', '')} 범주',
            ),
            const SizedBox(height: AppSpacing.sm),
            VehicleCategoryFilterChips(
              categories: items,
              selectedCategory: selectedCategory,
              onChanged: onSelected,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '브랜드 안의 모델을 EV, 승용, SUV, RV, 상용처럼 큰 범주로 좁힙니다.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: '모델 보기',
              icon: Icons.directions_car_rounded,
              onPressed: () => onSelected(selectedCategory),
            ),
          ],
        );
      },
    );
  }
}

class _ModelStep extends ConsumerWidget {
  const _ModelStep({
    required this.manufacturer,
    required this.fuelType,
    required this.category,
    required this.keyword,
    required this.onSelected,
  });

  final VehicleManufacturer manufacturer;
  final String fuelType;
  final VehicleCategoryFilter category;
  final String keyword;
  final ValueChanged<VehicleModelFilterSummary> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = VehicleModelFilterQuery(
      manufacturerId: manufacturer.id,
      fuelType: fuelType,
      category: category,
      keyword: keyword,
    );
    final models = ref.watch(vehicleModelFilterProvider(query));
    return models.when(
      loading: () => const LoadingSkeletonView(lines: 4),
      error: (error, stackTrace) => MappedErrorStateView(
        error: error,
        onRetry: () => ref.invalidate(vehicleModelFilterProvider(query)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return CustomVehicleRequestCard(
              manufacturerName: manufacturer.nameKo);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title:
                  '${manufacturer.nameKo} ${FuelLeague.nameForKey(fuelType).replaceAll(' 리그', '')} 모델',
            ),
            const SizedBox(height: AppSpacing.sm),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: VehicleModelSummaryCard(
                  summary: item,
                  onTap: () => onSelected(item),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class VehicleCategoryFilterChips extends StatelessWidget {
  const VehicleCategoryFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  final List<VehicleCategoryFilter> categories;
  final VehicleCategoryFilter selectedCategory;
  final ValueChanged<VehicleCategoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: categories.map((category) {
        final selected = selectedCategory == category;
        return FilterChip(
          selected: selected,
          showCheckmark: false,
          label: Text(category.label),
          onSelected: (_) => onChanged(category),
          selectedColor: AppColors.neonGreen.withValues(alpha: 0.18),
          backgroundColor: AppColors.surfaceLow,
          side: BorderSide(
            color: selected
                ? AppColors.neonGreen
                : Colors.white.withValues(alpha: 0.1),
          ),
          labelStyle: AppTypography.dataUnit.copyWith(
            color: selected ? AppColors.neonGreen : AppColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        );
      }).toList(),
    );
  }
}

class _GenerationStep extends ConsumerWidget {
  const _GenerationStep({
    required this.model,
    required this.manufacturer,
    required this.fuelType,
    required this.category,
    required this.keyword,
    required this.onSelected,
  });

  final VehicleModel model;
  final VehicleManufacturer manufacturer;
  final String fuelType;
  final VehicleCategoryFilter category;
  final String keyword;
  final ValueChanged<VehicleGenerationSummary> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = VehicleGenerationFilterQuery(
      modelId: model.id,
      manufacturerId: manufacturer.id,
      fuelType: fuelType,
      category: category,
      keyword: keyword,
    );
    final generations = ref.watch(vehicleGenerationsByFilterProvider(query));
    return generations.when(
      loading: () => const LoadingSkeletonView(lines: 4),
      error: (error, stackTrace) => MappedErrorStateView(
        error: error,
        onRetry: () =>
            ref.invalidate(vehicleGenerationsByFilterProvider(query)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return CustomVehicleRequestCard(
            manufacturerName: model.nameKo,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: '세대 선택'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '같은 모델이라도 세대에 따라 파워트레인과 리그 기준이 달라질 수 있어요.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: VehicleGenerationCard(
                  summary: item,
                  onTap: () => onSelected(item),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VariantStep extends ConsumerWidget {
  const _VariantStep({
    required this.generation,
    required this.fuelType,
    required this.category,
    required this.keyword,
    required this.onSelected,
  });

  final VehicleGeneration generation;
  final String fuelType;
  final VehicleCategoryFilter category;
  final String keyword;
  final ValueChanged<VehiclePowertrainChoice> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = VehiclePowertrainFilterQuery(
      generationId: generation.id,
      fuelType: fuelType,
      category: category,
      keyword: keyword,
    );
    final choices = ref.watch(vehiclePowertrainsByGenerationProvider(query));
    return choices.when(
      loading: () => const LoadingSkeletonView(lines: 4),
      error: (error, stackTrace) => MappedErrorStateView(
        error: error,
        onRetry: () =>
            ref.invalidate(vehiclePowertrainsByGenerationProvider(query)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const CustomVehicleRequestCard();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title:
                  '${FuelLeague.nameForKey(fuelType).replaceAll(' 리그', '')} 파워트레인',
            ),
            const SizedBox(height: AppSpacing.sm),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: VehicleVariantCard(
                  variant: item.representative,
                  periodLabel: item.periodLabel,
                  onTap: () => onSelected(item),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    required this.selection,
    required this.nicknameController,
    required this.saving,
    this.errorMessage,
    required this.onPrimaryChanged,
    required this.onReset,
    required this.onSave,
  });

  final VehicleSelectionState selection;
  final TextEditingController nicknameController;
  final bool saving;
  final String? errorMessage;
  final ValueChanged<bool> onPrimaryChanged;
  final VoidCallback onReset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final variant = selection.selectedVariant!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VehicleSelectionSummaryCard(selection: selection, expanded: true),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: nicknameController,
          maxLength: 12,
          decoration: const InputDecoration(
            labelText: '대표 차량 별명',
            hintText: '예: 출퇴근 머신',
            prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
          ),
        ),
        SwitchListTile(
          value: selection.isPrimary,
          onChanged: onPrimaryChanged,
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.neonGreen,
          title: const Text('대표 차량으로 설정'),
          subtitle: Text('${variant.leagueDisplayName}에 자동 배정됩니다.'),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (errorMessage != null) ...[
          ErrorStateView(message: errorMessage!, onRetry: onSave),
          const SizedBox(height: AppSpacing.md),
        ],
        PrimaryButton(
          label: '이 차량으로 시작하기',
          icon: Icons.check_circle_rounded,
          isLoading: saving,
          onPressed: onSave,
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: '다시 선택하기',
          icon: Icons.replay_rounded,
          onPressed: onReset,
        ),
      ],
    );
  }
}

class CustomVehicleRequestScreen extends ConsumerStatefulWidget {
  const CustomVehicleRequestScreen({
    super.key,
    this.initialManufacturer = '',
  });

  final String initialManufacturer;

  @override
  ConsumerState<CustomVehicleRequestScreen> createState() =>
      _CustomVehicleRequestScreenState();
}

class _CustomVehicleRequestScreenState
    extends ConsumerState<CustomVehicleRequestScreen> {
  late final TextEditingController _manufacturerController;
  final _modelController = TextEditingController();
  final _generationNameController = TextEditingController();
  final _generationCodeController = TextEditingController();
  final _yearController = TextEditingController(text: '2026');
  final _trimController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _memoController = TextEditingController();
  var _fuelType = '가솔린';
  var _vehicleClass = '준중형';
  var _saving = false;
  String? _saveError;

  static const _fuelTypes = [
    '가솔린',
    '디젤',
    '하이브리드',
    '전기차',
    'LPG',
    '플러그인 하이브리드',
    '수소전기차',
  ];

  static const _vehicleClasses = [
    '경형',
    '소형',
    '준중형',
    '중형',
    '대형',
    '소형 SUV',
    'SUV',
    '대형 SUV',
    'MPV',
    '픽업',
    '상용',
    '스포츠',
  ];

  @override
  void initState() {
    super.initState();
    _manufacturerController =
        TextEditingController(text: widget.initialManufacturer);
  }

  @override
  void dispose() {
    _manufacturerController.dispose();
    _modelController.dispose();
    _generationNameController.dispose();
    _generationCodeController.dispose();
    _yearController.dispose();
    _trimController.dispose();
    _nicknameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final manufacturer = _manufacturerController.text.trim();
    final model = _modelController.text.trim();
    final generationName = _generationNameController.text.trim();
    final generationCode = _generationCodeController.text.trim();
    final year = int.tryParse(_yearController.text.trim());
    final trim = _trimController.text.trim();
    if (manufacturer.isEmpty || model.isEmpty || trim.isEmpty || year == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제조사, 모델, 연식, 파워트레인을 모두 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final request = await ref
          .read(vehicleCatalogRepositoryProvider)
          .createCustomVehicleRequest(
            manufacturer: manufacturer,
            modelName: model,
            generationName: generationName,
            generationCode: generationCode,
            year: year,
            trimName: trim,
            fuelType: _fuelType,
            vehicleClass: _vehicleClass,
            nickname: _nicknameController.text.trim(),
            memo: _memoController.text.trim(),
          );
      await _refreshVehicleSetupState(ref);
      try {
        await ref
            .read(analyticsRepositoryProvider)
            .track('custom_vehicle_request_submitted', properties: {
          'fuel_league': request.fuelLeague,
          'vehicle_class': request.vehicleClass,
        });
      } catch (_) {}
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('차량 검토 요청을 접수했어요. 승인되면 알림으로 알려드릴게요.')),
      );
      context.go('/home');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _saveError = '차량 검토 요청을 접수하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fuelLeague = FuelLeague.keyForFuelType(_fuelType);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '차량 직접 입력', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('내 차량이 없어요',
              style: AppTypography.displayScore
                  .copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '입력한 차량은 검토 후 공식 리그에 반영됩니다. 검토 전에는 친선전과 개인 기록만 사용할 수 있어요.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(
                    labelText: '제조사',
                    prefixIcon: Icon(Icons.factory_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: '모델',
                    prefixIcon: Icon(Icons.directions_car_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _generationNameController,
                  decoration: const InputDecoration(
                    labelText: '세대명',
                    hintText: '예: 7세대',
                    prefixIcon: Icon(Icons.layers_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _generationCodeController,
                  decoration: const InputDecoration(
                    labelText: '세대 코드',
                    hintText: '예: CN7, G30',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '연식',
                    prefixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _trimController,
                  decoration: const InputDecoration(
                    labelText: '파워트레인',
                    prefixIcon: Icon(Icons.tune_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _fuelType,
                  decoration: const InputDecoration(labelText: '연료 타입'),
                  items: _fuelTypes
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _fuelType = value ?? _fuelType),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _vehicleClass,
                  decoration: const InputDecoration(labelText: '차급'),
                  items: _vehicleClasses
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _vehicleClass = value ?? _vehicleClass),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _nicknameController,
                  maxLength: 12,
                  decoration: const InputDecoration(
                    labelText: '차량 별명',
                    hintText: '예: 출퇴근 머신',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _memoController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '운영팀 메모',
                    hintText: '동일 파워트레인을 찾기 위한 정보를 적어주세요.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            borderColor: AppColors.amber.withValues(alpha: 0.28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FuelLeagueBadge(fuelLeague: fuelLeague),
                const SizedBox(height: AppSpacing.sm),
                Text(FuelLeague.leagueLabel(fuelLeague, _vehicleClass),
                    style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '공식 효율 정보는 운영팀 검수 후 반영됩니다. 검토 전 기록은 공개 랭킹에 반영되지 않습니다.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.onSurfaceMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_saveError != null) ...[
            ErrorStateView(message: _saveError!, onRetry: _submit),
            const SizedBox(height: AppSpacing.md),
          ],
          PrimaryButton(
            label: '검토 요청 제출',
            icon: Icons.fact_check_rounded,
            isLoading: _saving,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: '카탈로그 다시 검색',
            icon: Icons.search_rounded,
            onPressed: () => context.go('/setup/vehicle'),
          ),
        ],
      ),
    );
  }
}

class VehicleSetupCompleteScreen extends ConsumerWidget {
  const VehicleSetupCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(primaryVehicleProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '차량 설정 완료', showBack: true),
      child: vehicle.when(
        loading: () => const LoadingSkeletonView(lines: 3),
        error: (error, stackTrace) =>
            const ErrorStateView(message: '차량 설정 결과를 불러오지 못했어요.'),
        data: (value) {
          final primary = value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('차량 설정 완료',
                  style: AppTypography.displayScore
                      .copyWith(color: AppColors.neonGreen)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                primary == null
                    ? '홈에서 다시 차량을 설정할 수 있어요.'
                    : '이제 ${primary.leagueName}에서 같은 클래스 운전자들과 경쟁할 수 있어요.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (primary != null) ...[
                VehicleCard(vehicle: primary),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  borderColor: AppColors.neonGreen.withValues(alpha: 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FuelLeagueBadge(fuelLeague: primary.leagueKey),
                      const SizedBox(height: AppSpacing.md),
                      Text(primary.leagueDisplayName,
                          style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text('같은 연료 리그와 차급의 운전자들과 경쟁합니다.',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.onSurfaceMuted)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                  label: '홈으로 이동',
                  icon: Icons.home_rounded,
                  onPressed: () => context.go('/home')),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                  label: '첫 주행 시작하기',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => context.go('/drive/start')),
            ],
          );
        },
      ),
    );
  }
}

class VehicleAddScreen extends StatelessWidget {
  const VehicleAddScreen({super.key});

  @override
  Widget build(BuildContext context) => const VehicleSetupScreen();
}

class VehicleEditScreen extends StatelessWidget {
  const VehicleEditScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    return const VehicleSetupScreen();
  }
}

class VehicleSetupBreadcrumb extends StatelessWidget {
  const VehicleSetupBreadcrumb({
    super.key,
    required this.selection,
    required this.onTap,
  });

  final VehicleSelectionState selection;
  final ValueChanged<VehicleSelectionStep> onTap;

  @override
  Widget build(BuildContext context) {
    final crumbs = <({String label, VehicleSelectionStep step})>[
      if (selection.selectedManufacturer != null)
        (
          label: selection.selectedManufacturer!.nameKo,
          step: VehicleSelectionStep.manufacturer
        ),
      if (selection.selectedFuelType.isNotEmpty)
        (label: selection.fuelTypeLabel, step: VehicleSelectionStep.fuelType),
      if (!selection.selectedCategory.isAll)
        (
          label: selection.selectedCategory.label,
          step: VehicleSelectionStep.category
        ),
      if (selection.selectedModel != null)
        (
          label: selection.selectedModel!.nameKo,
          step: VehicleSelectionStep.model
        ),
      if (selection.selectedGeneration != null)
        (
          label: selection.selectedGeneration!.displayName,
          step: VehicleSelectionStep.generation
        ),
      if (selection.selectedVariant != null)
        (
          label: selection.selectedVariant!.trimName,
          step: VehicleSelectionStep.powertrain
        ),
    ];
    if (crumbs.isEmpty) {
      return Text('차량을 선택하면 리그가 자동으로 계산됩니다.',
          style:
              AppTypography.dataUnit.copyWith(color: AppColors.onSurfaceMuted));
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: crumbs.map((crumb) {
        return ActionChip(
          label: Text(crumb.label),
          onPressed: () => onTap(crumb.step),
          avatar: const Icon(Icons.chevron_right_rounded, size: 16),
          backgroundColor: AppColors.surfaceLow,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        );
      }).toList(),
    );
  }
}

class CompactManufacturerCard extends StatelessWidget {
  const CompactManufacturerCard({
    super.key,
    required this.manufacturer,
    required this.onTap,
  });

  final VehicleManufacturer manufacturer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ManufacturerLogoBadge(manufacturer: manufacturer),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    manufacturer.nameKo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              _manufacturerMetaLabel(manufacturer),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.dataUnit,
            ),
            const SizedBox(height: 4),
            VehicleCatalogStatsChip(
              label: _manufacturerYearLabel(manufacturer),
            ),
          ],
        ),
      ),
    );
  }
}

class ManufacturerLogoBadge extends StatelessWidget {
  const ManufacturerLogoBadge({
    super.key,
    required this.manufacturer,
  });

  final VehicleManufacturer manufacturer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppIconSize.xl,
      height: AppIconSize.xl,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.neonGreen.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          manufacturer.nameKo.isEmpty
              ? '?'
              : manufacturer.nameKo.substring(0, 1),
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.neonGreen,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}

class VehicleCatalogStatsChip extends StatelessWidget {
  const VehicleCatalogStatsChip({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.dataUnit.copyWith(
          color: AppColors.onSurfaceMuted,
          fontSize: 11,
        ),
      ),
    );
  }
}

String _manufacturerMetaLabel(VehicleManufacturer manufacturer) {
  final origin = manufacturer.country == 'KR' ? '국산' : '수입';
  if (manufacturer.modelCount <= 0) {
    return '$origin · 모델 목록 확인';
  }
  return '$origin · ${manufacturer.modelCount}개 모델';
}

String _manufacturerYearLabel(VehicleManufacturer manufacturer) {
  if (manufacturer.minYear > 0 &&
      manufacturer.maxYear >= manufacturer.minYear) {
    return '${manufacturer.minYear}-${manufacturer.maxYear} 지원';
  }
  return '지원 연식 확인';
}

class VehicleManufacturerCard extends StatelessWidget {
  const VehicleManufacturerCard({
    super.key,
    required this.manufacturer,
    required this.onTap,
  });

  final VehicleManufacturer manufacturer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CompactManufacturerCard(
      manufacturer: manufacturer,
      onTap: onTap,
    );
  }
}

class VehicleFuelTypeCard extends StatelessWidget {
  const VehicleFuelTypeCard({
    super.key,
    required this.fuelType,
    required this.onTap,
  });

  final String fuelType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _fuelTypeAccentColor(fuelType);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderColor: color.withValues(alpha: 0.24),
        child: Row(
          children: [
            Container(
              width: AppIconSize.lg,
              height: AppIconSize.lg,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.28)),
              ),
              child: Icon(_fuelTypeIcon(fuelType), color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FuelLeague.nameForKey(fuelType).replaceAll(' 리그', ''),
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _fuelTypeCaption(fuelType),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.onSurfaceMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

class VehicleModelCard extends StatelessWidget {
  const VehicleModelCard({
    super.key,
    required this.model,
    required this.onTap,
  });

  final VehicleModel model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AppCard(
        child: Row(
          children: [
            const Icon(Icons.directions_car_filled_rounded,
                color: AppColors.neonGreen, size: 38),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(model.nameKo, style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(model.bodyType, style: AppTypography.dataUnit),
                  const SizedBox(height: AppSpacing.xs),
                  Text(model.availableFuelTypes.join(' · '),
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.onSurfaceMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

class VehicleModelSummaryCard extends StatelessWidget {
  const VehicleModelSummaryCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  final VehicleModelFilterSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final model = summary.model;
    final samplePowertrains = summary.samplePowertrainLabels.join(' · ');
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: AppIconSize.lg,
              height: AppIconSize.lg,
              child: Icon(
                Icons.directions_car_filled_rounded,
                color: AppColors.neonGreen,
                size: AppIconSize.lg,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(model.nameKo, style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      StatusChip(
                        label: summary.yearRangeLabel,
                        color: AppColors.electricBlue,
                      ),
                      StatusChip(
                        label: '${summary.matchingPowertrainCount}개 파워트레인',
                        color: AppColors.neonGreen,
                      ),
                    ],
                  ),
                  if (samplePowertrains.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      samplePowertrains,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      ...summary.supportedVehicleClasses.take(2).map(
                            (item) => VehicleClassBadge(vehicleClass: item),
                          ),
                      ...summary.supportedBodyTypes.take(1).map(
                            (item) => StatusChip(
                              label: item,
                              color: AppColors.outline,
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

class VehicleGenerationCard extends StatelessWidget {
  const VehicleGenerationCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  final VehicleGenerationSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = SourceStatus.fromKey(summary.sourceStatusSummary);
    final generation = summary.generation;
    final fuels = summary.supportedFuelTypes
        .map((item) => FuelLeague.nameForKey(item).replaceAll(' 리그', ''))
        .join(' · ');
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderColor: generation.isCurrent
            ? AppColors.neonGreen.withValues(alpha: 0.24)
            : AppColors.electricBlue.withValues(alpha: 0.16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    generation.displayName,
                    style: AppTypography.titleMedium,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.outline),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              generation.periodLabel,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (generation.isCurrent)
                  const StatusChip(
                    label: '현재 판매 중',
                    color: AppColors.neonGreen,
                  ),
                if (generation.isUpcoming)
                  const StatusChip(
                    label: '출시 예정',
                    color: AppColors.amber,
                  ),
                if (fuels.isNotEmpty)
                  StatusChip(label: fuels, color: AppColors.electricBlue),
                ...summary.supportedVehicleClasses.take(2).map(
                      (item) => VehicleClassBadge(vehicleClass: item),
                    ),
                StatusChip(
                  label: '${summary.matchingPowertrainCount}개 파워트레인',
                  color: AppColors.neonGreen,
                ),
                StatusChip(label: status.displayName, color: status.color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _fuelTypeIcon(String fuelType) {
  return switch (fuelType) {
    'electric' => Icons.electric_bolt_rounded,
    'hydrogen' => Icons.water_drop_rounded,
    'hybrid' || 'plug_in_hybrid' => Icons.energy_savings_leaf_rounded,
    'diesel' => Icons.local_gas_station_rounded,
    'lpg' => Icons.propane_tank_rounded,
    _ => Icons.local_gas_station_rounded,
  };
}

Color _fuelTypeAccentColor(String fuelType) {
  return switch (fuelType) {
    'electric' => AppColors.electricBlue,
    'hydrogen' => AppColors.electricBlueSoft,
    'hybrid' => AppColors.neonGreen,
    'plug_in_hybrid' => AppColors.electricBlueSoft,
    'lpg' => AppColors.amber,
    'diesel' => AppColors.outline,
    _ => AppColors.neonGreen,
  };
}

String _fuelTypeCaption(String fuelType) {
  return switch (fuelType) {
    'electric' => '전기 파워트레인만 다음 단계에 표시됩니다.',
    'hydrogen' => '수소전기 파워트레인만 다음 단계에 표시됩니다.',
    'hybrid' => '하이브리드 파워트레인만 다음 단계에 표시됩니다.',
    'plug_in_hybrid' => '플러그인 하이브리드만 다음 단계에 표시됩니다.',
    'diesel' => '디젤 파워트레인만 다음 단계에 표시됩니다.',
    'lpg' => 'LPG 파워트레인만 다음 단계에 표시됩니다.',
    _ => '가솔린 파워트레인만 다음 단계에 표시됩니다.',
  };
}

void _showSourceDetailBottomSheet(
    BuildContext context, VehicleVariant variant) {
  final status = SourceStatus.fromKey(variant.sourceStatus);
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '데이터 출처 정보',
                    style: AppTypography.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(
                  color: AppColors.surfaceHighest, height: AppSpacing.lg),
              Text(
                '${variant.manufacturerName} ${variant.modelName} ${variant.year}년식 ${variant.trimName}',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSourceDetailRow('검증 등급', status.displayName,
                  textColor: status.color),
              _buildSourceDetailRow(
                  '신뢰도 점수',
                  variant.confidenceScore != null
                      ? '${(variant.confidenceScore! * 100).toStringAsFixed(0)}%'
                      : '정보 없음'),
              _buildSourceDetailRow(
                  '출처 기관',
                  variant.sourceName != null && variant.sourceName!.isNotEmpty
                      ? variant.sourceName!
                      : '공식 제원 정보'),
              if (variant.sourceUrl != null && variant.sourceUrl!.isNotEmpty)
                _buildSourceDetailRow('출처 링크', variant.sourceUrl!,
                    isLink: true),
              const SizedBox(height: AppSpacing.lg),
              if (status == SourceStatus.conflict)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '주의: 본 차량 정보는 출처 간의 충돌(연비/단위 등)이 발견되어 검토가 필요합니다.',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildSourceDetailRow(String label, String value,
    {Color? textColor, bool isLink = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
        ),
        Expanded(
          child: isLink
              ? Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.electricBlue,
                    decoration: TextDecoration.underline,
                  ),
                )
              : Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textColor ?? AppColors.onSurface,
                    fontWeight:
                        textColor != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
        ),
      ],
    ),
  );
}

class VehicleVariantCard extends StatelessWidget {
  const VehicleVariantCard({
    super.key,
    required this.variant,
    required this.onTap,
    this.periodLabel = '',
  });

  final VehicleVariant variant;
  final VoidCallback onTap;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final status = SourceStatus.fromKey(variant.sourceStatus);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AppCard(
        borderColor: AppColors.neonGreen.withValues(alpha: 0.18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(variant.trimName,
                            style: AppTypography.titleMedium),
                      ),
                      if (status == SourceStatus.conflict) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
                FuelLeagueBadge(fuelLeague: variant.fuelLeague),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(variant.specSummary,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted)),
            if (periodLabel.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                periodLabel,
                style: AppTypography.dataUnit
                    .copyWith(color: AppColors.electricBlue),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      VehicleClassBadge(vehicleClass: variant.vehicleClass),
                      StatusChip(
                          label: variant.leagueDisplayName,
                          color: AppColors.neonGreen),
                      StatusChip(
                          label: status.displayName, color: status.color),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () =>
                      _showSourceDetailBottomSheet(context, variant),
                  child: const Text('출처 보기',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.electricBlue)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FuelLeagueBadge extends StatelessWidget {
  const FuelLeagueBadge({
    super.key,
    required this.fuelLeague,
  });

  final String fuelLeague;

  @override
  Widget build(BuildContext context) {
    final color = switch (fuelLeague) {
      'electric' => AppColors.electricBlue,
      'hydrogen' => AppColors.electricBlueSoft,
      'hybrid' => AppColors.neonGreen,
      'diesel' => AppColors.outline,
      'lpg' => AppColors.amber,
      'plug_in_hybrid' => AppColors.electricBlueSoft,
      _ => AppColors.neonGreen,
    };
    return StatusChip(label: FuelLeague.nameForKey(fuelLeague), color: color);
  }
}

class VehicleClassBadge extends StatelessWidget {
  const VehicleClassBadge({
    super.key,
    required this.vehicleClass,
  });

  final String vehicleClass;

  @override
  Widget build(BuildContext context) {
    return StatusChip(label: vehicleClass, color: AppColors.electricBlue);
  }
}

class VehicleSearchField extends StatelessWidget {
  const VehicleSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
      ),
    );
  }
}

class VehicleSelectionSummaryCard extends StatelessWidget {
  const VehicleSelectionSummaryCard({
    super.key,
    required this.selection,
    this.expanded = false,
  });

  final VehicleSelectionState selection;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final variant = selection.selectedVariant;
    return AppCard(
      borderColor: AppColors.electricBlue.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('선택 요약', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(selection.breadcrumb,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted)),
          if (variant != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      FuelLeagueBadge(fuelLeague: variant.fuelLeague),
                      VehicleClassBadge(vehicleClass: variant.vehicleClass),
                      StatusChip(
                        label: SourceStatus.fromKey(variant.sourceStatus)
                            .displayName,
                        color: SourceStatus.fromKey(variant.sourceStatus).color,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () =>
                      _showSourceDetailBottomSheet(context, variant),
                  child: const Text('출처 보기',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.electricBlue)),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: AppSpacing.md),
              Text('배정 리그: ${variant.leagueDisplayName}',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.neonGreen)),
              const SizedBox(height: AppSpacing.xs),
              Text('같은 연료 리그와 차급의 운전자들과 경쟁합니다.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.onSurfaceMuted)),
            ],
          ],
        ],
      ),
    );
  }
}

class VehicleSetupProgressIndicator extends StatelessWidget {
  const VehicleSetupProgressIndicator({
    super.key,
    required this.step,
  });

  final VehicleSelectionStep step;

  @override
  Widget build(BuildContext context) {
    final index = switch (step) {
      VehicleSelectionStep.manufacturer => 1,
      VehicleSelectionStep.fuelType => 2,
      VehicleSelectionStep.category => 3,
      VehicleSelectionStep.model => 4,
      VehicleSelectionStep.generation => 5,
      VehicleSelectionStep.powertrain => 6,
      VehicleSelectionStep.confirm => 6,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$index / 6',
            style: AppTypography.dataUnit.copyWith(color: AppColors.neonGreen)),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: index / 6,
          minHeight: 6,
          borderRadius: BorderRadius.circular(99),
          backgroundColor: AppColors.surfaceHighest,
          valueColor: const AlwaysStoppedAnimation(AppColors.neonGreen),
        ),
      ],
    );
  }
}

class VehicleSetupEmptyState extends StatelessWidget {
  const VehicleSetupEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      title: '차량 설정이 필요해요',
      message: '리그와 점수 계산을 위해 먼저 차량을 선택해주세요.',
      actionLabel: '차량 설정하기',
      onAction: () => context.go('/setup/vehicle'),
    );
  }
}

class CustomVehicleRequestCard extends StatelessWidget {
  const CustomVehicleRequestCard({
    super.key,
    this.manufacturerName,
  });

  final String? manufacturerName;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.amber.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(
              label: '직접 입력', color: AppColors.amber, icon: Icons.edit_rounded),
          const SizedBox(height: AppSpacing.md),
          Text('검색 결과가 없어요', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${manufacturerName ?? '선택한 제조사'} 차량을 직접 입력하면 검수 대기 상태로 저장되고, 공식 리그 반영은 검증 후 진행됩니다.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: '직접 입력하기',
            icon: Icons.edit_note_rounded,
            onPressed: () {
              final encoded =
                  Uri.encodeComponent(manufacturerName?.trim() ?? '');
              context.go('/setup/vehicle/custom?manufacturer=$encoded');
            },
          ),
        ],
      ),
    );
  }
}
