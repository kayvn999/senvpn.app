import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/services/vpngate_service.dart';
import '../models/server_model.dart';
import '../providers/app_config_provider.dart';
import 'user_provider.dart';

const _serversApiUrl = 'https://lephap.io.vn/api/servers';

final selectedServerProvider = StateProvider<ServerModel?>((ref) => null);

/// Fetches VPS servers (local + VPNGate cached by VPS).
final _vpsServersProvider = FutureProvider<List<ServerModel>>((ref) async {
  try {
    final response = await http
        .get(Uri.parse(_serversApiUrl))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) return [];
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((s) => ServerModel.fromMap(s as Map<String, dynamic>, s['id'] as String? ?? ''))
        .toList();
  } catch (_) {
    return [];
  }
});

/// Fetches VPNGate directly from device — each device gets its own fresh list.
/// This bypasses VPS rate-limiting and returns many more servers.
final _directVpnGateProvider = FutureProvider<List<ServerModel>>((ref) async {
  final config = ref.watch(freeConfigProvider);
  if (!config.vpngateEnabled) return [];
  return VpnGateService.fetchServers(
    maxTotal: config.vpngateMaxServers > 0 ? config.vpngateMaxServers : 500,
    maxPerCountry: config.freeServersPerCountry > 0 ? config.freeServersPerCountry : 10,
    blockedCountries: config.blockedCountries,
    allowedCountries: config.allowedCountries,
  );
});


String _flag(String cc) {
  try {
    return String.fromCharCodes(cc.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 65));
  } catch (_) { return '🌍'; }
}

/// Merged list: VPS servers + direct VPNGate, deduped by host IP.
final serversProvider = FutureProvider<List<ServerModel>>((ref) async {
  final vpsServers = await ref.watch(_vpsServersProvider.future);
  final directServers = await ref.watch(_directVpnGateProvider.future);

  final hostsSeen = <String>{};
  final merged = <ServerModel>[];

  for (final s in vpsServers) {
    if (hostsSeen.add(s.host)) merged.add(s);
  }
  for (final s in directServers) {
    if (hostsSeen.add(s.host)) merged.add(s);
  }

  merged.sort((a, b) => a.ping.compareTo(b.ping));
  return merged;
});

final freeServersProvider = Provider<List<ServerModel>>((ref) {
  return (ref.watch(serversProvider).valueOrNull ?? []).where((s) => s.isFree).toList();
});

final vipServersProvider = Provider<List<ServerModel>>((ref) {
  return (ref.watch(serversProvider).valueOrNull ?? []).where((s) => s.isVip).toList();
});

final serverSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredServersProvider = Provider<List<ServerModel>>((ref) {
  final servers = ref.watch(serversProvider).valueOrNull ?? [];
  final query = ref.watch(serverSearchQueryProvider).toLowerCase();
  final isPremium = ref.watch(isPremiumProvider);

  List<ServerModel> filtered =
      isPremium ? servers : servers.where((s) => s.isFree).toList();

  if (query.isNotEmpty) {
    filtered = filtered
        .where((s) =>
            s.name.toLowerCase().contains(query) ||
            s.country.toLowerCase().contains(query))
        .toList();
  }
  return filtered;
});

final bestServerProvider = FutureProvider<ServerModel?>((ref) async {
  final servers = await ref.watch(serversProvider.future);
  final isPremium = ref.watch(isPremiumProvider);
  final candidates = isPremium ? servers : servers.where((s) => s.isFree).toList();
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => a.ping.compareTo(b.ping));
  return candidates.first;
});
