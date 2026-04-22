import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/vpn/vpn_service.dart';
import '../core/vpn/vpn_state.dart';
import '../models/server_model.dart';
import 'user_provider.dart';
import 'settings_provider.dart';
import 'server_provider.dart';

const _kPrefLogId = 'vpn_log_id';

const _vpsBase = 'https://lephap.io.vn/api';

Future<void> _reportDataUsage(String uid, double totalMB) async {
  if (totalMB <= 0) return;
  try {
    await http.patch(
      Uri.parse('$_vpsBase/user/$uid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'addDataMB': totalMB.round()}),
    ).timeout(const Duration(seconds: 10));
  } catch (_) {}
}

final vpnServiceProvider = Provider<VpnService>((ref) {
  final service = VpnService();
  ref.onDispose(service.dispose);
  return service;
});

final vpnStateProvider = StreamProvider<VpnState>((ref) {
  final service = ref.watch(vpnServiceProvider);
  return service.stateStream;
});

final vpnNotifierProvider =
    StateNotifierProvider<VpnNotifier, VpnState>((ref) {
  return VpnNotifier(
    ref.watch(vpnServiceProvider),
    ref.watch(firestoreServiceProvider),
    ref,
  );
});

class VpnNotifier extends StateNotifier<VpnState> {
  final VpnService _vpnService;
  final Ref _ref;

  String? _connectionLogId;
  bool _autoRetrying = false;
  int _retryIndex = 0;
  String? _retryCountryCode; // only retry within same country

  VpnNotifier(this._vpnService, _, this._ref)
      : super(const VpnState()) {
    _vpnService.stateStream.listen((vpnState) {
      final prev = state;
      state = vpnState;
      _handleStateChange(prev, vpnState);
    });
    _syncSettingsToService();
    _scheduleAutoConnect();
    _closeOrphanLog();
  }

  // Push kill switch + DNS settings to VpnService whenever settings change
  void _syncSettingsToService() {
    final settings = _ref.read(settingsProvider);
    _vpnService.setKillSwitch(settings.killSwitch);
    _vpnService.setDnsLeakProtection(settings.dnsLeakProtection);
  }

  // Auto-connect on startup if setting is enabled
  void _scheduleAutoConnect() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final settings = _ref.read(settingsProvider);
      if (!settings.autoConnect) return;
      if (state.isConnected || state.isConnecting) return;
      final server = _ref.read(selectedServerProvider);
      if (server != null) connect(server);
    });
  }

  void _handleStateChange(VpnState prev, VpnState next) {
    if (!prev.isConnected && next.isConnected && next.selectedServer != null) {
      _autoRetrying = false;
      _retryIndex = 0;
      final user = _ref.read(userModelProvider).valueOrNull;
      final displayName = user?.displayName?.isNotEmpty == true
          ? user!.displayName!
          : user?.shortId.isNotEmpty == true
              ? '#${user!.shortId}'
              : user?.uid ?? 'anonymous';
      _logConnectionStart(
        uid: user?.uid ?? 'anonymous',
        email: (user != null && user.email.isNotEmpty) ? user.email : displayName,
        serverName: next.selectedServer!.name,
        serverCountry: next.selectedServer!.country,
      ).then((id) => _connectionLogId = id);
    }
    if (prev.isConnected && !next.isConnected && _connectionLogId != null) {
      final totalMB = prev.downloadedMB + prev.uploadedMB;
      _logConnectionEnd(_connectionLogId!, totalMB);
      _connectionLogId = null;
      // Update daily data usage via VPS API
      final uid = _ref.read(userModelProvider).valueOrNull?.uid;
      if (uid != null && uid.isNotEmpty) {
        _reportDataUsage(uid, totalMB);
      }
    }
    // Auto-retry next free server on error/timeout
    if (_autoRetrying && (next.status == VpnStatus.error || next.status == VpnStatus.disconnected)) {
      _retryNextFreeServer();
    }
  }

  void _retryNextFreeServer() {
    final sameCountryServers = (_ref.read(serversProvider).valueOrNull ?? [])
        .where((s) => s.isFree && s.countryCode == _retryCountryCode)
        .toList();
    if (_retryIndex >= sameCountryServers.length) {
      _autoRetrying = false;
      _retryIndex = 0;
      _retryCountryCode = null;
      return;
    }
    final next = sameCountryServers[_retryIndex++];
    _ref.read(selectedServerProvider.notifier).state = next;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) connect(next);
    });
  }

  Future<void> connect(ServerModel server) async {
    // Sync settings to service right before connecting
    _syncSettingsToService();
    final hasPermission = await _vpnService.requestPermission();
    if (!hasPermission) return;
    await _vpnService.connect(server);
  }

  Future<void> disconnect() async {
    await _vpnService.disconnect();
  }

  Future<void> toggleConnection(ServerModel? server) async {
    if (state.isConnected || state.isConnecting) {
      _autoRetrying = false;
      _retryIndex = 0;
      _retryCountryCode = null;
      await disconnect();
    } else {
      if (server != null) {
        if (server.isFree) {
          // Auto-retry within same country only
          _autoRetrying = true;
          _retryCountryCode = server.countryCode;
          final sameCountry = (_ref.read(serversProvider).valueOrNull ?? [])
              .where((s) => s.isFree && s.countryCode == server.countryCode)
              .toList();
          final startIdx = sameCountry.indexWhere((s) => s.id == server.id);
          _retryIndex = startIdx >= 0 ? startIdx + 1 : 0;
        }
        await connect(server);
      }
    }
  }

  // Called from settings screen when kill switch or DNS settings change
  void updateSettings() => _syncSettingsToService();

  // On app start: close any orphan log left from a previous crash/kill
  Future<void> _closeOrphanLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orphanId = prefs.getString(_kPrefLogId);
      if (orphanId != null) {
        await _logConnectionEnd(orphanId, 0);
        await prefs.remove(_kPrefLogId);
      }
    } catch (_) {}
  }

  Future<String?> _logConnectionStart({
    required String uid,
    required String email,
    required String serverName,
    required String serverCountry,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_vpsBase/connections'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'email': email,
          'serverName': serverName,
          'serverCountry': serverCountry,
          'action': 'start',
        }),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final id = data['id'] as String?;
        if (id != null) {
          // Persist so we can close it even if app is killed
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kPrefLogId, id);
        }
        return id;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _logConnectionEnd(String logId, double dataMB) async {
    try {
      await http.post(
        Uri.parse('$_vpsBase/connections'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': 'system',
          'action': 'end',
          'logId': logId,
          'dataMB': dataMB,
        }),
      ).timeout(const Duration(seconds: 10));
      // Clear persisted log id after successful close
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPrefLogId);
    } catch (_) {}
  }
}
