class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String period;
  final int durationDays;
  final bool isPopular;
  final List<String> features;
  final double? originalPrice;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'VND',
    required this.period,
    required this.durationDays,
    this.isPopular = false,
    required this.features,
    this.originalPrice,
  });

  String get formattedPrice {
    if (currency == 'VND') {
      return '${(price / 1000).toStringAsFixed(0)}K đ';
    }
    return '\$${price.toStringAsFixed(2)}';
  }

  String get formattedOriginalPrice {
    if (originalPrice == null) return '';
    if (currency == 'VND') {
      return '${(originalPrice! / 1000).toStringAsFixed(0)}K đ';
    }
    return '\$${originalPrice!.toStringAsFixed(2)}';
  }

  int get discountPercent {
    if (originalPrice == null || originalPrice == 0) return 0;
    return ((1 - price / originalPrice!) * 100).round();
  }

  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'securevpn_weekly',
      name: '1 Tuần',
      description: 'Trải nghiệm VIP',
      price: 29000,
      period: '/ tuần',
      durationDays: 7,
      features: [
        'Tất cả server premium',
        'Không giới hạn băng thông',
        'Không quảng cáo',
        'WireGuard protocol',
        'Hỗ trợ 24/7',
      ],
    ),
    SubscriptionPlan(
      id: 'securevpn_monthly',
      name: '1 Tháng',
      description: 'Phổ biến nhất',
      price: 79000,
      originalPrice: 116000,
      period: '/ tháng',
      durationDays: 30,
      isPopular: true,
      features: [
        'Tất cả server premium',
        'Không giới hạn băng thông',
        'Không quảng cáo',
        'WireGuard protocol',
        'Kill Switch',
        'DNS Leak Protection',
        'Hỗ trợ 24/7',
      ],
    ),
    SubscriptionPlan(
      id: 'securevpn_yearly',
      name: '1 Năm',
      description: 'Tiết kiệm nhất 🔥',
      price: 599000,
      originalPrice: 948000,
      period: '/ năm',
      durationDays: 365,
      features: [
        'Tất cả server premium',
        'Không giới hạn băng thông',
        'Không quảng cáo',
        'WireGuard protocol',
        'Kill Switch',
        'DNS Leak Protection',
        'Multi-device (5 thiết bị)',
        'Hỗ trợ ưu tiên 24/7',
        'Sử dụng trên tất cả thiết bị',
      ],
    ),
  ];
}
