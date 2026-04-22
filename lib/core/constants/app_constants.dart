class AppConstants {
  // App Info
  static const String appName = 'SEN VPN';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.senvpn.app';

  // AdMob IDs (test IDs - replace with real ones)
  static const String admobAppIdAndroid = 'ca-app-pub-3940256099942544~3347511713';
  static const String admobAppIdIos = 'ca-app-pub-3940256099942544~1458002511';
  static const String bannerAdUnitAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String bannerAdUnitIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String interstitialAdUnitAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String interstitialAdUnitIos = 'ca-app-pub-3940256099942544/4411468910';
  static const String rewardedAdUnitAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String rewardedAdUnitIos = 'ca-app-pub-3940256099942544/1712485313';

  // RevenueCat
  static const String revenueCatApiKeyAndroid = 'goog_lbZEzFZvrJogSqVmsoRcvtnRWgD';
  static const String revenueCatApiKeyIos = 'appl_REPLACE_WITH_IOS_KEY';

  // Subscription Product IDs
  static const String weeklyProductId = 'securevpn_weekly';
  static const String monthlyProductId = 'securevpn_monthly';
  static const String yearlyProductId = 'securevpn_yearly';

  // Free tier limits
  static const int freeDailyDataLimitMB = 500;
  static const int freeSpeedLimitMbps = 5;
  static const int freeServerCount = 5;
  static const int adIntervalSeconds = 180;

  // Connection
  static const int connectionTimeoutSeconds = 30;
  static const int reconnectAttempts = 3;

  // VPNGate API
  static const String vpngateApiUrl = 'http://www.vpngate.net/api/iphone/';

  // Firestore Collections
  static const String colServers = 'servers';
  static const String colUsers = 'users';
  static const String colAppConfig = 'app_config';

  // SharedPreferences Keys
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keySelectedServer = 'selected_server';
  static const String keyAutoConnect = 'auto_connect';
  static const String keyKillSwitch = 'kill_switch';
  static const String keyDnsLeak = 'dns_leak_protection';
  static const String keyBiometric = 'biometric_lock';
  static const String keyProtocol = 'vpn_protocol';
  static const String keyTheme = 'app_theme';
  static const String keyNotifications = 'notifications_enabled';
}

class VpnProtocol {
  static const String openVpn = 'OpenVPN';
  static const String wireGuard = 'WireGuard';
  static const String shadowsocks = 'Shadowsocks';
  static const String auto = 'Auto';
}
