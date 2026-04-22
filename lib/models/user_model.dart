import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionStatus { free, vip, expired }

class UserModel {
  final String uid;
  final String shortId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final SubscriptionStatus subscriptionStatus;
  final DateTime? premiumExpiry;
  final int dailyDataLimitMB;
  final int usedDataTodayMB;
  final String? selectedServerId;
  final DateTime createdAt;
  final bool isEmailVerified;

  const UserModel({
    required this.uid,
    this.shortId = '',
    required this.email,
    this.displayName,
    this.photoUrl,
    this.subscriptionStatus = SubscriptionStatus.free,
    this.premiumExpiry,
    this.dailyDataLimitMB = 500,
    this.usedDataTodayMB = 0,
    this.selectedServerId,
    required this.createdAt,
    this.isEmailVerified = false,
  });

  bool get isPremium => subscriptionStatus == SubscriptionStatus.vip;

  bool get hasDataLeft => usedDataTodayMB < dailyDataLimitMB || isPremium;

  int get remainingDataMB => isPremium ? -1 : (dailyDataLimitMB - usedDataTodayMB).clamp(0, dailyDataLimitMB);

  double get dataUsagePercent => isPremium ? 0 : (usedDataTodayMB / dailyDataLimitMB).clamp(0.0, 1.0);

  String get subscriptionLabel {
    switch (subscriptionStatus) {
      case SubscriptionStatus.vip:
        return 'VIP';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.free:
        return 'Free';
    }
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      subscriptionStatus: _parseStatus(data['subscriptionStatus']),
      premiumExpiry: data['premiumExpiry'] != null
          ? (data['premiumExpiry'] as Timestamp).toDate()
          : null,
      dailyDataLimitMB: data['dailyDataLimitMB'] ?? 500,
      usedDataTodayMB: data['usedDataTodayMB'] ?? 0,
      selectedServerId: data['selectedServerId'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isEmailVerified: data['isEmailVerified'] ?? false,
    );
  }

  factory UserModel.fromApiMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      shortId: data['shortId'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'],
      subscriptionStatus: _parseStatus(data['subscriptionStatus']),
      premiumExpiry: data['premiumExpiry'] != null
          ? DateTime.tryParse(data['premiumExpiry'] as String)
          : null,
      dailyDataLimitMB: data['dailyDataLimitMB'] ?? 500,
      usedDataTodayMB: data['usedDataTodayMB'] ?? 0,
      createdAt: DateTime.now(),
    );
  }

  static SubscriptionStatus _parseStatus(String? value) {
    switch (value) {
      case 'vip':
        return SubscriptionStatus.vip;
      case 'expired':
        return SubscriptionStatus.expired;
      default:
        return SubscriptionStatus.free;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'subscriptionStatus': subscriptionStatus.name,
      'premiumExpiry': premiumExpiry != null ? Timestamp.fromDate(premiumExpiry!) : null,
      'dailyDataLimitMB': dailyDataLimitMB,
      'usedDataTodayMB': usedDataTodayMB,
      'selectedServerId': selectedServerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isEmailVerified': isEmailVerified,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    SubscriptionStatus? subscriptionStatus,
    DateTime? premiumExpiry,
    int? dailyDataLimitMB,
    int? usedDataTodayMB,
    String? selectedServerId,
    bool? isEmailVerified,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      dailyDataLimitMB: dailyDataLimitMB ?? this.dailyDataLimitMB,
      usedDataTodayMB: usedDataTodayMB ?? this.usedDataTodayMB,
      selectedServerId: selectedServerId ?? this.selectedServerId,
      createdAt: createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
