import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/widgets/widgets.dart';

class SafetyDriveScreen extends StatefulWidget {
  const SafetyDriveScreen({super.key});

  @override
  State<SafetyDriveScreen> createState() => _SafetyDriveScreenState();
}

class _SafetyDriveScreenState extends State<SafetyDriveScreen> {
  Timer? _timer;
  var _elapsed = Duration.zero;
  var _distance = 0.0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
        _distance += 0.012;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          const StatusChip(label: 'Recording', color: AppColors.neonGreen, icon: Icons.radio_button_checked_rounded),
          const Spacer(),
          Text('안전 모드', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '주행 중에는 알림과 광고가 표시되지 않아요',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          ScoreGauge(
            score: _elapsed.inSeconds,
            label: formatDuration(_elapsed),
            progress: (_elapsed.inSeconds % 60) / 60,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: StatMetricCard(label: '주행 시간', value: formatDuration(_elapsed))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: StatMetricCard(label: '주행 거리', value: _distance.toStringAsFixed(2), unit: 'km', color: AppColors.electricBlue)),
            ],
          ),
          const Spacer(),
          SecondaryButton(
            label: '주행 종료',
            icon: Icons.stop_rounded,
            onPressed: () => context.go('/drive/result'),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
