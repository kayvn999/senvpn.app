import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../models/app_config_model.dart';

class AdmobService {
  static final AdmobService _instance = AdmobService._internal();
  factory AdmobService() => _instance;
  AdmobService._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  DateTime? _lastInterstitialShown;
  AppConfigModel? _config;

  void updateConfig(AppConfigModel config) {
    final prevEnabled = _config?.adsEnabled ?? false;
    _config = config;
    if (config.adsEnabled && !prevEnabled) {
      _preloadInterstitial();
      _preloadRewarded();
    }
  }

  bool get adsEnabled => _config?.adsEnabled ?? false;

  String get _bannerUnitId {
    final id = Platform.isAndroid
        ? (_config?.bannerAdUnitAndroid ?? '')
        : (_config?.bannerAdUnitIos ?? '');
    return id.isNotEmpty ? id : _testBannerId;
  }

  String get _interstitialUnitId {
    final id = Platform.isAndroid
        ? (_config?.interstitialAdUnitAndroid ?? '')
        : (_config?.interstitialAdUnitIos ?? '');
    return id.isNotEmpty ? id : _testInterstitialId;
  }

  String get _rewardedUnitId {
    final id = Platform.isAndroid
        ? (_config?.rewardedAdUnitAndroid ?? '')
        : (_config?.rewardedAdUnitIos ?? '');
    return id.isNotEmpty ? id : _testRewardedId;
  }

  static String get _testBannerId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  static String get _testInterstitialId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  static String get _testRewardedId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed: $error');
        },
      ),
    );
  }

  void _preloadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed: $error');
          Future.delayed(const Duration(minutes: 2), _preloadInterstitial);
        },
      ),
    );
  }

  void _preloadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded failed: $error');
          Future.delayed(const Duration(minutes: 2), _preloadRewarded);
        },
      ),
    );
  }

  bool canShowInterstitial() {
    if (!adsEnabled || _interstitialAd == null) return false;
    final interval = _config?.adIntervalSeconds ?? 180;
    if (_lastInterstitialShown == null) return true;
    return DateTime.now().difference(_lastInterstitialShown!).inSeconds >= interval;
  }

  void showInterstitial({VoidCallback? onDismissed}) {
    if (_interstitialAd == null) { onDismissed?.call(); return; }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _lastInterstitialShown = DateTime.now();
        _preloadInterstitial();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        onDismissed?.call();
      },
    );
    _interstitialAd!.show();
  }

  void showRewarded({
    required void Function(int rewardAmount) onRewarded,
    VoidCallback? onDismissed,
  }) {
    if (_rewardedAd == null) { onDismissed?.call(); return; }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _preloadRewarded();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onDismissed?.call();
      },
    );
    _rewardedAd!.show(onUserEarnedReward: (_, reward) {
      onRewarded(reward.amount.toInt());
    });
  }
}
