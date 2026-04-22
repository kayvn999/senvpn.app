class AppConfigModel {
  final int freeDataLimitMB;
  final int freeServersPerCountry;
  final int freeMaxConnections;
  final List<String> allowedCountries;
  final List<String> blockedCountries;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final bool vpngateEnabled;
  final int vpngateMaxServers;
  final bool oneconnectEnabled;
  final String oneconnectApiKey;
  final bool? oneconnectFreeEnabled;
  final bool? oneconnectProEnabled;
  final String storeUrl;
  final String shareText;
  final String privacyPolicyUrl;
  final String termsUrl;
  final bool adsEnabled;
  final int adIntervalSeconds;
  final String bannerAdUnitAndroid;
  final String bannerAdUnitIos;
  final String interstitialAdUnitAndroid;
  final String interstitialAdUnitIos;
  final String rewardedAdUnitAndroid;
  final String rewardedAdUnitIos;

  const AppConfigModel({
    this.freeDataLimitMB = 500,
    this.freeServersPerCountry = 3,
    this.freeMaxConnections = 1,
    this.allowedCountries = const [],
    this.blockedCountries = const [],
    this.maintenanceMode = false,
    this.maintenanceMessage = 'Hệ thống đang bảo trì, vui lòng thử lại sau.',
    this.vpngateEnabled = true,
    this.vpngateMaxServers = 300,
    this.oneconnectEnabled = false,
    this.oneconnectApiKey = '',
    this.oneconnectFreeEnabled,
    this.oneconnectProEnabled,
    this.storeUrl = '',
    this.shareText = 'Tải SEN VPN miễn phí tại: ',
    this.privacyPolicyUrl = '',
    this.termsUrl = '',
    this.adsEnabled = false,
    this.adIntervalSeconds = 180,
    this.bannerAdUnitAndroid = '',
    this.bannerAdUnitIos = '',
    this.interstitialAdUnitAndroid = '',
    this.interstitialAdUnitIos = '',
    this.rewardedAdUnitAndroid = '',
    this.rewardedAdUnitIos = '',
  });

  factory AppConfigModel.fromMap(Map<String, dynamic> map) {
    return AppConfigModel(
      freeDataLimitMB: (map['freeDataLimitMB'] ?? 500) as int,
      freeServersPerCountry: (map['freeServersPerCountry'] ?? 3) as int,
      freeMaxConnections: (map['freeMaxConnections'] ?? 1) as int,
      allowedCountries: List<String>.from(map['allowedCountries'] ?? []),
      blockedCountries: List<String>.from(map['blockedCountries'] ?? []),
      maintenanceMode: (map['maintenanceMode'] ?? false) as bool,
      maintenanceMessage: (map['maintenanceMessage'] ?? '') as String,
      vpngateEnabled: (map['vpngateEnabled'] ?? true) as bool,
      vpngateMaxServers: (map['vpngateMaxServers'] ?? 300) as int,
      oneconnectEnabled: (map['oneconnectEnabled'] ?? false) as bool,
      oneconnectApiKey: (map['oneconnectApiKey'] ?? '') as String,
      oneconnectFreeEnabled: map['oneconnectFreeEnabled'] as bool?,
      oneconnectProEnabled: map['oneconnectProEnabled'] as bool?,
      storeUrl: (map['storeUrl'] ?? '') as String,
      shareText: (map['shareText'] ?? 'Tải SEN VPN miễn phí tại: ') as String,
      privacyPolicyUrl: (map['privacyPolicyUrl'] ?? '') as String,
      termsUrl: (map['termsUrl'] ?? '') as String,
      adsEnabled: (map['adsEnabled'] ?? false) as bool,
      adIntervalSeconds: (map['adIntervalSeconds'] ?? 180) as int,
      bannerAdUnitAndroid: (map['bannerAdUnitAndroid'] ?? '') as String,
      bannerAdUnitIos: (map['bannerAdUnitIos'] ?? '') as String,
      interstitialAdUnitAndroid: (map['interstitialAdUnitAndroid'] ?? '') as String,
      interstitialAdUnitIos: (map['interstitialAdUnitIos'] ?? '') as String,
      rewardedAdUnitAndroid: (map['rewardedAdUnitAndroid'] ?? '') as String,
      rewardedAdUnitIos: (map['rewardedAdUnitIos'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'freeDataLimitMB': freeDataLimitMB,
        'freeServersPerCountry': freeServersPerCountry,
        'freeMaxConnections': freeMaxConnections,
        'allowedCountries': allowedCountries,
        'blockedCountries': blockedCountries,
        'maintenanceMode': maintenanceMode,
        'maintenanceMessage': maintenanceMessage,
        'vpngateEnabled': vpngateEnabled,
        'vpngateMaxServers': vpngateMaxServers,
        'storeUrl': storeUrl,
        'shareText': shareText,
        'privacyPolicyUrl': privacyPolicyUrl,
        'termsUrl': termsUrl,
      };

  static AppConfigModel get defaults => const AppConfigModel();
}

class VipPlanModel {
  final String id;
  final String name;
  final int priceVnd;
  final String currency;
  final int durationDays;
  final List<String> features;
  final bool isPopular;
  final bool isActive;

  const VipPlanModel({
    required this.id,
    required this.name,
    required this.priceVnd,
    this.currency = 'VND',
    required this.durationDays,
    required this.features,
    this.isPopular = false,
    this.isActive = true,
  });

  factory VipPlanModel.fromMap(Map<String, dynamic> map, String id) {
    return VipPlanModel(
      id: id,
      name: map['name'] ?? '',
      priceVnd: (map['priceVnd'] as num? ?? 0).toInt(),
      currency: map['currency'] ?? 'VND',
      durationDays: (map['durationDays'] as num? ?? 30).toInt(),
      features: List<String>.from(map['features'] ?? []),
      isPopular: (map['isPopular'] ?? false) as bool,
      isActive: (map['isActive'] ?? true) as bool,
    );
  }

  String get priceLabel {
    // Format: 79.000 VNĐ  (dùng dấu chấm phân cách nghìn theo chuẩn VN)
    final formatted = priceVnd.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted $currency';
  }

  String get durationLabel {
    if (durationDays == 7) return '1 tuần';
    if (durationDays == 30) return '1 tháng';
    if (durationDays == 90) return '3 tháng';
    if (durationDays == 365) return '1 năm';
    return '$durationDays ngày';
  }

  static List<VipPlanModel> get defaults => [
        const VipPlanModel(
          id: 'weekly',
          name: 'Gói tuần',
          priceVnd: 29000,
          durationDays: 7,
          features: ['Tất cả server VIP', 'Không giới hạn data', 'Tốc độ cao'],
        ),
        const VipPlanModel(
          id: 'monthly',
          name: 'Gói tháng',
          priceVnd: 79000,
          durationDays: 30,
          features: ['Tất cả server VIP', 'Không giới hạn data', 'Tốc độ cao', 'Kill Switch', 'DNS bảo mật'],
          isPopular: true,
        ),
        const VipPlanModel(
          id: 'yearly',
          name: 'Gói năm',
          priceVnd: 599000,
          durationDays: 365,
          features: ['Tất cả server VIP', 'Không giới hạn data', 'Tốc độ cao', 'Kill Switch', 'DNS bảo mật', 'Ưu tiên hỗ trợ'],
        ),
      ];
}
