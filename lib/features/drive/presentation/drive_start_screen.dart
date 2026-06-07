import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/repositories/fuel_arena_repositories.dart'
    show DriveRepository;
import '../../../shared/widgets/widgets.dart';

class DriveStartScreen extends ConsumerStatefulWidget {
  const DriveStartScreen({super.key});

  @override
  ConsumerState<DriveStartScreen> createState() => _DriveStartScreenState();
}

class _DriveStartScreenState extends ConsumerState<DriveStartScreen> {
  Future<_DriveReadiness>? _readinessFuture;
  String? _readinessVehicleId;
  var _startingDrive = false;

  Future<_DriveReadiness> _loadReadiness({
    required DriveRepository repository,
    required Vehicle primaryVehicle,
  }) async {
    final mission = await repository.getTodayMission();
    final permissionStatus = await Permission.locationWhenInUse.status;
    return _DriveReadiness(
      vehicle: primaryVehicle,
      mission: mission,
      permissionStatus: permissionStatus,
    );
  }

  Future<_DriveReadiness> _readinessFor({
    required DriveRepository repository,
    required Vehicle primaryVehicle,
  }) {
    if (_readinessFuture == null || _readinessVehicleId != primaryVehicle.id) {
      _readinessVehicleId = primaryVehicle.id;
      _readinessFuture = _loadReadiness(
        repository: repository,
        primaryVehicle: primaryVehicle,
      );
    }
    return _readinessFuture!;
  }

  void _retryReadiness() {
    ref.invalidate(primaryVehicleProvider);
    setState(() {
      _readinessFuture = null;
      _readinessVehicleId = null;
    });
  }

  Future<void> _startDrive({
    required BuildContext context,
    required DriveRepository repository,
    required Vehicle vehicle,
  }) async {
    if (_startingDrive) {
      return;
    }
    setState(() => _startingDrive = true);
    try {
      final network = await ref.read(networkStatusServiceProvider).current();
      DriveSession session;
      if (network.isOnline) {
        session = await repository.startDriveSession();
      } else {
        final startedAt = DateTime.now();
        session = DriveSession(
          id: 'local-drive-${startedAt.microsecondsSinceEpoch}',
          vehicleId: vehicle.id,
          startedAt: startedAt,
          duration: Duration.zero,
          distanceKm: 0,
          averageFuelEfficiency: 0,
          sourceType: 'local',
          status: 'recording',
        );
        await ref
            .read(offlineQueueServiceProvider)
            .enqueueDriveSession(session);
        ref.invalidate(offlineQueueItemsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('주행 기록은 기기에 안전하게 보관했어요')),
          );
        }
      }
      await ref
          .read(localStateServiceProvider)
          .saveActiveDriveSession(session.id);
      await ref.read(analyticsRepositoryProvider).track(
        'drive_started',
        properties: {
          'vehicle_id': session.vehicleId,
          'storage_mode': network.isOnline ? 'server' : 'local_queue',
        },
      );
      if (context.mounted) {
        context.go('/drive/safety');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주행을 시작하지 못했어요. 연결 상태를 확인해주세요')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _startingDrive = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(driveRepositoryProvider);
    final primaryVehicle = ref.watch(primaryVehicleProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '주행 준비', showBack: true),
      child: primaryVehicle.when(
        loading: () => const LoadingSkeletonView(lines: 3),
        error: (error, stackTrace) => MappedErrorStateView(
          error: error,
          onRetry: _retryReadiness,
        ),
        data: (primary) {
          if (primary == null) {
            return EmptyStateView(
              title: '차량 설정이 필요해요',
              message: '리그와 점수 계산을 위해 먼저 차량을 선택해주세요.',
              actionLabel: '차량 설정하기',
              onAction: () => context.go('/setup/vehicle'),
            );
          }
          return FutureBuilder<_DriveReadiness>(
            future: _readinessFor(
              repository: repository,
              primaryVehicle: primary,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return MappedErrorStateView(
                  error: snapshot.error!,
                  onRetry: _retryReadiness,
                );
              }
              if (!snapshot.hasData) {
                return const LoadingSkeletonView(lines: 4);
              }
              final readiness = snapshot.data!;
              final vehicle = readiness.vehicle;
              final mission = readiness.mission;
              final permissionStatus = readiness.permissionStatus;
              if (permissionStatus.isDenied ||
                  permissionStatus.isPermanentlyDenied ||
                  permissionStatus.isRestricted) {
                return EmptyStateView(
                  title: '위치 권한이 필요해요',
                  message: '권한이 없어도 앱을 둘러볼 수 있지만, 주행 기록은 사용할 수 없어요.',
                  actionLabel: '권한 설정하기',
                  onAction: () => context.go('/permissions/location'),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('오늘의 주행을\n기록할까요?',
                      style: AppTypography.displayScore
                          .copyWith(color: AppColors.neonGreen)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('주행 중에는 광고와 팝업을 완전히 차단합니다.',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.onSurfaceMuted)),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: '대표 차량'),
                  VehicleCard(vehicle: vehicle),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: '오늘 적용되는 미션'),
                  MissionCard(mission: mission),
                  const SizedBox(height: AppSpacing.lg),
                  const SafetyModePanel(),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: _startingDrive ? '주행 시작 확인' : '안전 모드로 주행 시작',
                    icon: Icons.shield_rounded,
                    onPressed: () => _startDrive(
                      context: context,
                      repository: repository,
                      vehicle: vehicle,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DriveReadiness {
  const _DriveReadiness({
    required this.vehicle,
    required this.mission,
    required this.permissionStatus,
  });

  final Vehicle vehicle;
  final SeasonMission mission;
  final PermissionStatus permissionStatus;
}
