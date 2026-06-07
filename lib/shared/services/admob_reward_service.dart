import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../app/app_config.dart';

class RewardedAdService {
  const RewardedAdService();

  static Future<InitializationStatus>? _initialization;

  bool get supportsRewardedAds {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  String adUnitIdFor(AppConfig config) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => config.rewardedAndroidUnitId,
      TargetPlatform.iOS => config.rewardedIosUnitId,
      _ => '',
    };
  }

  Future<void> showRewardedAd(
    AppConfig config, {
    Duration loadTimeout = const Duration(seconds: 20),
    Duration watchTimeout = const Duration(minutes: 2),
  }) async {
    if (!supportsRewardedAds) {
      throw StateError('리워드 광고는 Android/iOS 앱에서만 지원합니다.');
    }

    final adUnitId = adUnitIdFor(config);
    if (adUnitId.isEmpty) {
      throw StateError('리워드 광고 단위 ID가 설정되지 않았습니다.');
    }

    await _initializeMobileAds();
    final ad = await _loadRewardedAd(adUnitId, timeout: loadTimeout);
    await _showAndWaitForReward(ad, timeout: watchTimeout);
  }

  Future<void> _initializeMobileAds() async {
    _initialization ??= MobileAds.instance.initialize();
    await _initialization;
  }

  Future<RewardedAd> _loadRewardedAd(
    String adUnitId, {
    required Duration timeout,
  }) {
    final completer = Completer<RewardedAd>();
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: completer.complete,
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) {
            completer.completeError(
              StateError('리워드 광고를 불러오지 못했습니다: ${error.message}'),
            );
          }
        },
      ),
    );
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        throw StateError('리워드 광고 로드 시간이 초과되었습니다.');
      },
    );
  }

  Future<void> _showAndWaitForReward(
    RewardedAd ad, {
    required Duration timeout,
  }) async {
    final completer = Completer<bool>();
    var earnedReward = false;

    void complete(bool value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        complete(earnedReward);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('리워드 광고를 표시하지 못했습니다: ${error.message}'),
          );
        }
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          earnedReward = true;
        },
      );
    } catch (_) {
      ad.dispose();
      rethrow;
    }

    final completed = await completer.future.timeout(
      timeout,
      onTimeout: () {
        ad.dispose();
        return earnedReward;
      },
    );
    if (!completed) {
      throw StateError('리워드 광고를 끝까지 시청해야 보상이 지급됩니다.');
    }
  }
}
