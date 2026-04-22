import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;

  // Default values
  static const Map<String, dynamic> _defaults = {
    'ad_interval_seconds': 180,
    'free_server_count': 5,
    'free_daily_data_mb': 500,
    'free_speed_limit_mbps': 5,
    'show_announcement': false,
    'announcement_text': '',
    'announcement_url': '',
    'min_app_version': '1.0.0',
    'force_update': false,
    'vpngate_enabled': true,
    'interstitial_enabled': true,
    'rewarded_enabled': true,
    'weekly_price_vnd': 29000,
    'monthly_price_vnd': 79000,
    'yearly_price_vnd': 599000,
  };

  Future<void> initialize() async {
    _remoteConfig = FirebaseRemoteConfig.instance;

    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval:
          kDebugMode ? Duration.zero : const Duration(hours: 12),
    ));

    await _remoteConfig.setDefaults(
      _defaults.map((k, v) => MapEntry(k, v)),
    );

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('Remote config fetch failed: $e');
    }
  }

  int get adIntervalSeconds => _remoteConfig.getInt('ad_interval_seconds');
  int get freeServerCount => _remoteConfig.getInt('free_server_count');
  int get freeDailyDataMB => _remoteConfig.getInt('free_daily_data_mb');
  int get freeSpeedLimitMbps => _remoteConfig.getInt('free_speed_limit_mbps');
  bool get showAnnouncement => _remoteConfig.getBool('show_announcement');
  String get announcementText => _remoteConfig.getString('announcement_text');
  String get announcementUrl => _remoteConfig.getString('announcement_url');
  bool get forceUpdate => _remoteConfig.getBool('force_update');
  bool get vpngateEnabled => _remoteConfig.getBool('vpngate_enabled');
  bool get interstitialEnabled => _remoteConfig.getBool('interstitial_enabled');
  bool get rewardedEnabled => _remoteConfig.getBool('rewarded_enabled');
  int get weeklyPriceVnd => _remoteConfig.getInt('weekly_price_vnd');
  int get monthlyPriceVnd => _remoteConfig.getInt('monthly_price_vnd');
  int get yearlyPriceVnd => _remoteConfig.getInt('yearly_price_vnd');
}
