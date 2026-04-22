import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/ads/admob_service.dart';
import '../models/app_config_model.dart';

const _configUrl = 'https://lephap.io.vn/api/config';

Stream<AppConfigModel> _configStream() async* {
  Future<AppConfigModel> fetch() async {
    try {
      final res = await http.get(Uri.parse(_configUrl))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return AppConfigModel.fromMap(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return AppConfigModel.defaults;
  }

  final first = await fetch();
  AdmobService().updateConfig(first);
  yield first;
  await for (final _ in Stream.periodic(const Duration(seconds: 60))) {
    final updated = await fetch();
    AdmobService().updateConfig(updated);
    yield updated;
  }
}

final appConfigProvider = StreamProvider<AppConfigModel>((ref) {
  return _configStream();
});

final freeConfigProvider = Provider<AppConfigModel>((ref) {
  return ref.watch(appConfigProvider).valueOrNull ?? AppConfigModel.defaults;
});

/// VIP plans from VPS
final vipPlansProvider = FutureProvider<List<VipPlanModel>>((ref) async {
  try {
    final res = await http.get(Uri.parse('https://lephap.io.vn/api/plans'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      final plans = list
          .map((e) => VipPlanModel.fromMap(e as Map<String, dynamic>, e['id'] ?? ''))
          .where((p) => p.isActive)
          .toList();
      if (plans.isNotEmpty) return plans;
    }
  } catch (_) {}
  return VipPlanModel.defaults;
});
