import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../core/services/revenuecat_service.dart';

final rcOfferingsProvider = FutureProvider<List<Package>>((ref) async {
  return RevenueCatService().getOfferings();
});

final rcPlanMapProvider = FutureProvider<Map<String, Package>>((ref) async {
  final packages = await ref.watch(rcOfferingsProvider.future);
  return RevenueCatService().mapPlanIdToPackage(packages);
});
