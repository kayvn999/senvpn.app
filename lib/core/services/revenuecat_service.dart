import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../constants/app_constants.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize(String userId) async {
    if (_initialized) return;
    final apiKey = Platform.isAndroid
        ? AppConstants.revenueCatApiKeyAndroid
        : AppConstants.revenueCatApiKeyIos;
    if (apiKey.isEmpty || apiKey.startsWith('YOUR_') || apiKey.startsWith('test_') || apiKey.startsWith('appl_REPLACE')) return;
    final config = PurchasesConfiguration(apiKey)..appUserID = userId;
    await Purchases.configure(config);
    _initialized = true;
  }

  Future<List<Package>> getOfferings() async {
    if (!_initialized) return [];
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Returns CustomerInfo on success, null if user cancelled, throws on real error.
  Future<CustomerInfo?> purchase(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return null;
      rethrow;
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!_initialized) return null;
    try {
      return await Purchases.restorePurchases();
    } catch (_) {
      return null;
    }
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_initialized) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }

  /// Maps VipPlanModel.id ('weekly', 'monthly', 'yearly') → RC Package.
  Map<String, Package> mapPlanIdToPackage(List<Package> packages) {
    final result = <String, Package>{};
    for (final pkg in packages) {
      switch (pkg.packageType) {
        case PackageType.weekly:
          result['weekly'] = pkg;
        case PackageType.monthly:
          result['monthly'] = pkg;
        case PackageType.annual:
          result['yearly'] = pkg;
        default:
          final id = pkg.identifier.toLowerCase();
          final pid = pkg.storeProduct.identifier.toLowerCase();
          if (id.contains('weekly') || pid.contains('weekly')) {
            result['weekly'] = pkg;
          } else if (id.contains('monthly') || pid.contains('monthly')) {
            result['monthly'] = pkg;
          } else if (id.contains('year') || pid.contains('year')) {
            result['yearly'] = pkg;
          }
      }
    }
    return result;
  }
}
