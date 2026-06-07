import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class SafetyDriveScreen extends ConsumerStatefulWidget {
  const SafetyDriveScreen({super.key});

  @override
  ConsumerState<SafetyDriveScreen> createState() => _SafetyDriveScreenState();
}

class _SafetyDriveScreenState extends ConsumerState<SafetyDriveScreen> {
  Timer? _timer;
  Timer? _finishArmTimer;
  StreamSubscription<Position>? _positionSubscription;
  final _pendingPoints = <DrivePoint>[];
  var _elapsed = Duration.zero;
  var _distance = 0.0;
  var _sessionId = 'local-session';
  var _gpsStatus = 'GPS 신호 확인 중';
  var _flushingPoints = false;
  var _finishArmed = false;
  Position? _lastPosition;
  DateTime? _lastPointFlushAt;

  double get _estimatedEfficiency {
    if (_distance <= 0) {
      return 0;
    }
    final secondsFactor = (_elapsed.inSeconds % 90) / 30;
    return (15.6 + secondsFactor).clamp(12.0, 22.0).toDouble();
  }

  double get _estimatedFuelUsedLiters {
    final efficiency = _estimatedEfficiency;
    if (efficiency <= 0) {
      return 0;
    }
    return _distance / efficiency;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
    _restoreSessionAndStartTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _finishArmTimer?.cancel();
    _positionSubscription?.cancel();
    unawaited(_flushDrivePoints());
    super.dispose();
  }

  Future<void> _restoreSessionAndStartTracking() async {
    final sessionId = await ref
        .read(localStateServiceProvider)
        .getString('active_drive_session_id', fallback: 'local-session');
    if (!mounted) {
      return;
    }
    setState(() => _sessionId = sessionId);
    await _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _gpsStatus = '위치 서비스 꺼짐');
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _gpsStatus = '위치 권한 대기');
        }
        return;
      }

      const settings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      );
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        _handlePosition,
        onError: (Object error) {
          if (mounted) {
            setState(() => _gpsStatus = 'GPS 신호 재시도 중');
          }
        },
      );
      if (mounted) {
        setState(() => _gpsStatus = 'GPS 기록 중');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _gpsStatus = 'GPS 기록 대기');
      }
    }
  }

  void _handlePosition(Position position) {
    if (!mounted || !_isReliablePosition(position)) {
      return;
    }

    var addedDistanceKm = 0.0;
    final previous = _lastPosition;
    if (previous != null && _isReliablePosition(previous)) {
      final meters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
      final speedKmh = _speedKmh(position);
      if (meters >= 2 && meters <= 500 && speedKmh <= 180) {
        addedDistanceKm = meters / 1000;
      }
    }
    _lastPosition = position;
    _pendingPoints.add(
      DrivePoint(
        id: 'drive-point-${DateTime.now().microsecondsSinceEpoch}',
        driveSessionId: _sessionId,
        latitude: position.latitude,
        longitude: position.longitude,
        speedKmh: _speedKmh(position),
        accuracy: position.accuracy,
        recordedAt: position.timestamp,
        isMocked: position.isMocked,
      ),
    );

    if (_pendingPoints.length >= 5 ||
        DateTime.now()
                .difference(_lastPointFlushAt ?? DateTime(1970))
                .inSeconds >=
            15) {
      unawaited(_flushDrivePoints());
    }

    setState(() {
      _distance += addedDistanceKm;
      _gpsStatus = position.isMocked ? '검증 필요 신호' : 'GPS 기록 중';
    });
  }

  bool _isReliablePosition(Position position) {
    return position.latitude.abs() <= 90 &&
        position.longitude.abs() <= 180 &&
        position.accuracy > 0 &&
        position.accuracy <= 100;
  }

  double _speedKmh(Position position) {
    if (position.speed.isNaN ||
        position.speed.isInfinite ||
        position.speed < 0) {
      return 0;
    }
    return (position.speed * 3.6).clamp(0.0, 250.0).toDouble();
  }

  Future<void> _flushDrivePoints() async {
    if (_pendingPoints.isEmpty || _flushingPoints) {
      return;
    }
    _flushingPoints = true;
    final batch = List<DrivePoint>.from(_pendingPoints);
    _pendingPoints.clear();
    try {
      await ref.read(driveRepositoryProvider).recordDrivePoints(batch);
      _lastPointFlushAt = DateTime.now();
    } catch (_) {
      try {
        await ref.read(offlineQueueServiceProvider).enqueueDrivePoints(batch);
        ref.invalidate(offlineQueueItemsProvider);
        if (mounted) {
          setState(() => _gpsStatus = '업로드 대기 저장됨');
        }
      } catch (_) {
        _pendingPoints.insertAll(0, batch);
      }
    } finally {
      _flushingPoints = false;
    }
  }

  Future<bool> _confirmFinishIfNeeded() async {
    final requireConfirm = await ref
        .read(localStateServiceProvider)
        .getBool('safety_confirm_end', fallback: true);
    if (!requireConfirm || !mounted) {
      return true;
    }
    if (_finishArmed) {
      _finishArmTimer?.cancel();
      setState(() => _finishArmed = false);
      return true;
    }
    _finishArmTimer?.cancel();
    setState(() => _finishArmed = true);
    _finishArmTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _finishArmed = false);
      }
    });
    return false;
  }

  Future<void> _finishDrive() async {
    final confirmed = await _confirmFinishIfNeeded();
    if (!confirmed || !mounted) {
      return;
    }
    final localState = ref.read(localStateServiceProvider);
    final sessionId = _sessionId.isNotEmpty
        ? _sessionId
        : await localState.getString(
            'active_drive_session_id',
            fallback: 'local-session',
          );
    await _flushDrivePoints();
    await localState.saveLatestDriveResultSummary(
      sessionId: sessionId,
      duration: _elapsed,
      distanceKm: _distance,
      averageEfficiency: _estimatedEfficiency,
      fuelUsedLiters: _estimatedFuelUsedLiters,
    );
    await localState.clearActiveDriveSession();
    await ref
        .read(analyticsRepositoryProvider)
        .track('drive_finished', properties: {
      'duration_seconds': _elapsed.inSeconds,
      'distance_km': _distance.toStringAsFixed(2),
      'average_efficiency': _estimatedEfficiency.toStringAsFixed(1),
    });
    if (!mounted) return;
    context.go('/drive/result/$sessionId');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          const StatusChip(
              label: '기록 중',
              color: AppColors.neonGreen,
              icon: Icons.radio_button_checked_rounded),
          const Spacer(),
          Text('안전 모드', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _finishArmed
                ? '팝업 없이 한 번 더 누르면 기록을 저장하고 종료합니다.'
                : '주행 중에는 알림과 광고가 표시되지 않아요',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _gpsStatus,
            textAlign: TextAlign.center,
            style: AppTypography.dataUnit.copyWith(color: AppColors.neonGreen),
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
              Expanded(
                  child: StatMetricCard(
                      label: '주행 시간', value: formatDuration(_elapsed))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: StatMetricCard(
                      label: '주행 거리',
                      value: _distance.toStringAsFixed(2),
                      unit: 'km',
                      color: AppColors.electricBlue)),
            ],
          ),
          const Spacer(),
          SecondaryButton(
            label: _finishArmed ? '한 번 더 눌러 종료' : '주행 종료',
            icon:
                _finishArmed ? Icons.check_circle_rounded : Icons.stop_rounded,
            onPressed: _finishDrive,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
