import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:oneconnect_flutter/openvpn_flutter.dart' as oc;
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

/// Fetches servers from OneConnect SDK
final _oneConnectProvider = FutureProvider<List<ServerModel>>((ref) async {
  final config = ref.watch(freeConfigProvider);
  if (!config.oneconnectEnabled) return [];
  final apiKey = config.oneconnectApiKey;
  if (apiKey.isEmpty) return [];

  try {
    final openVpn = oc.OpenVPN();
    openVpn.apiKey = apiKey;
    final servers = <ServerModel>[];

    ServerModel toModel(oc.VpnServer s, bool isFree) {
      final name = s.serverName.isNotEmpty ? s.serverName : 'Unknown';
      return ServerModel(
        id: 'oc_${isFree ? 'free' : 'pro'}_${s.id}',
        name: name,
        host: s.server,
        port: 1194,
        protocol: 'OpenVPN',
        country: name,
        countryCode: '',
        flag: '🌍',
        ping: 99,
        load: 0,
        isFree: isFree,
        isVip: !isFree,
        isActive: true,
        speedMbps: 100,
        ovpnConfig: oc.OpenVPN.decrypt(s.ovpnConfiguration),
        vpnUsername: oc.OpenVPN.decrypt(s.vpnUserName),
        vpnPassword: oc.OpenVPN.decrypt(s.vpnPassword),
      );
    }

    if (config.oneconnectFreeEnabled ?? true) {
      final freeList = await openVpn.fetchOneConnect(oc.OneConnect.free);
      debugPrint('[OC] free servers: ${freeList.length}');
      for (final s in freeList) {
        debugPrint('[OC] free: ${s.serverName} | host=${s.server} | ovpn=${s.ovpnConfiguration.length} chars | user=${s.vpnUserName}');
        if (s.ovpnConfiguration.isEmpty) continue;
        servers.add(toModel(s, true));
      }
    }

    if (config.oneconnectProEnabled ?? true) {
      final proList = await openVpn.fetchOneConnect(oc.OneConnect.pro);
      debugPrint('[OC] pro servers: ${proList.length}');
      for (final s in proList) {
        debugPrint('[OC] pro: ${s.serverName} | host=${s.server} | ovpn=${s.ovpnConfiguration.length} chars');
        if (s.ovpnConfiguration.isEmpty) continue;
        servers.add(toModel(s, false));
      }
    }
    debugPrint('[OC] total servers added: ${servers.length}');
    return servers;
  } catch (e, st) {
    debugPrint('[OC] ERROR: $e\n$st');
    return [];
  }
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
  final ocServers = await ref.watch(_oneConnectProvider.future);

  final hostsSeen = <String>{};
  final merged = <ServerModel>[];

  for (final s in vpsServers) {
    if (hostsSeen.add(s.host)) merged.add(s);
  }
  for (final s in directServers) {
    if (hostsSeen.add(s.host)) merged.add(s);
  }
  for (final s in ocServers) {
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
