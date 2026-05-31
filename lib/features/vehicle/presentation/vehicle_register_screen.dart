import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class VehicleRegisterScreen extends ConsumerStatefulWidget {
  const VehicleRegisterScreen({super.key});

  @override
  ConsumerState<VehicleRegisterScreen> createState() => _VehicleRegisterScreenState();
}

class _VehicleRegisterScreenState extends ConsumerState<VehicleRegisterScreen> {
  final _nicknameController = TextEditingController(text: '출퇴근 머신');
  String _manufacturer = 'Hyundai';
  String _model = 'Avante Hybrid';
  int _year = 2024;
  String _fuelType = 'Hybrid';
  String _vehicleClass = '준중형';
  var _loading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    setState(() => _loading = true);
    await ref.read(vehicleRepositoryProvider).saveVehicle(
          manufacturer: _manufacturer,
          modelName: _model,
          modelYear: _year,
          fuelType: _fuelType,
          vehicleClass: _vehicleClass,
          nickname: _nicknameController.text.trim().isEmpty ? '내 전투 유닛' : _nicknameController.text.trim(),
        );
    ref.invalidate(homeSnapshotProvider);
    if (!mounted) {
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: 'FUEL ARENA', subtitle: 'Vehicle Setup', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('내 전투 유닛을\n세팅하세요', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '같은 클래스 운전자들과 공정하게 겨루기 위해 차량 정보를 등록합니다.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: '제조사'),
          _ChoiceWrap(
            values: const ['Hyundai', 'Porsche', 'BMW', 'Kia'],
            selected: _manufacturer,
            onSelected: (value) => setState(() => _manufacturer = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '모델'),
          _ChoiceWrap(
            values: const ['Avante Hybrid', '911 GT3 RS', 'Taycan Turbo S', 'K5'],
            selected: _model,
            onSelected: (value) => setState(() => _model = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '연식'),
          _ChoiceWrap<int>(
            values: const [2024, 2023, 2022, 2021],
            selected: _year,
            labelBuilder: (value) => '$value',
            onSelected: (value) => setState(() => _year = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '연료 타입'),
          _ChoiceWrap(
            values: const ['Gasoline', 'Diesel', 'Hybrid', 'Electric', 'LPG'],
            selected: _fuelType,
            onSelected: (value) => setState(() => _fuelType = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '차급'),
          _ChoiceWrap(
            values: const ['경형', '소형', '준중형', '중형', '대형', 'SUV'],
            selected: _vehicleClass,
            onSelected: (value) => setState(() => _vehicleClass = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '차량 별명'),
          TextField(
            controller: _nicknameController,
            maxLength: 10,
            decoration: const InputDecoration(
              hintText: '예: 연비 괴물, 출퇴근 머신',
              prefixIcon: Icon(Icons.directions_car_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: '차량 등록 완료',
            icon: Icons.check_circle_rounded,
            isLoading: _loading,
            onPressed: _complete,
          ),
        ],
      ),
    );
  }
}

class _ChoiceWrap<T> extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.selected,
    required this.onSelected,
    this.labelBuilder,
  });

  final List<T> values;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T value)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: values.map((value) {
        final active = value == selected;
        final label = labelBuilder?.call(value) ?? value.toString();
        return ChoiceChip(
          selected: active,
          label: Text(label),
          onSelected: (_) => onSelected(value),
          selectedColor: AppColors.neonGreen.withOpacity(0.18),
          backgroundColor: AppColors.surfaceLow,
          side: BorderSide(color: active ? AppColors.neonGreen : Colors.white.withOpacity(0.1)),
          labelStyle: AppTypography.bodyMedium.copyWith(
            color: active ? AppColors.neonGreen : AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        );
      }).toList(),
    );
  }
}
