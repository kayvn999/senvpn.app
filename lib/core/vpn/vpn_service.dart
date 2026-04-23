import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/server_model.dart';
import 'vpn_state.dart';

class VpnService {
  static final VpnService _instance = VpnService._internal();
  factory VpnService() => _instance;
  VpnService._internal();

  final StreamController<VpnState> _stateController =
      StreamController<VpnState>.broadcast();
  VpnState _currentState = const VpnState();
  Timer? _connectionTimer;
  Timer? _statsTimer;
  Timer? _killSwitchTimer;
  Timer? _connectTimeoutTimer;

  bool _killSwitchEnabled = false;
  bool _dnsLeakProtectionEnabled = false;
  bool _userInitiatedDisconnect = false;
  ServerModel? _lastServer;

  Stream<VpnState> get stateStream => _stateController.stream;
  VpnState get currentState => _currentState;

  void setKillSwitch(bool enabled) => _killSwitchEnabled = enabled;
  void setDnsLeakProtection(bool enabled) => _dnsLeakProtectionEnabled = enabled;

  Future<void> initialize() async {
    // VPN native plugin disabled — using simulation mode for Simulator/testing
    // Real VPN via openvpn_flutter will be re-enabled for production builds
    debugPrint('VpnService: simulation mode');
  }

  double _prevByteIn = 0;
  double _prevByteOut = 0;
  DateTime _prevStatsTime = DateTime.now();

  void _scheduleKillSwitchReconnect() {
    _killSwitchTimer?.cancel();
    _killSwitchTimer = Timer(const Duration(seconds: 2), () {
      if (!_currentState.isConnected && !_currentState.isConnecting && _lastServer != null) {
        connect(_lastServer!);
      }
    });
  }

  String _fixLegacyConfig(String config) {
    return config
        .replaceAll(RegExp(r'cipher AES-128-CBC.*', multiLine: true), 'cipher AES-256-GCM\ndata-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC')
        .replaceAll(RegExp(r'auth SHA1.*', multiLine: true), 'auth SHA256')
        .replaceAll(RegExp(r'ns-cert-type server.*\n?', multiLine: true), 'remote-cert-tls server\n')
        .replaceAll(RegExp(r'comp-lzo.*\n?', multiLine: true), '')
        .replaceAll(RegExp(r'ncp-ciphers.*\n?', multiLine: true), '');
  }

  String _applyDnsProtection(String config) {
    const dnsBlock = '\n'
        'dhcp-option DNS 8.8.8.8\n'
        'dhcp-option DNS 8.8.4.4\n'
        'block-outside-dns\n';
    final cleaned = config
        .replaceAll(RegExp(r'dhcp-option DNS[^\n]*\n?'), '')
        .replaceAll(RegExp(r'block-outside-dns[^\n]*\n?'), '');
    return cleaned + dnsBlock;
  }

  Future<void> connect(ServerModel server) async {
    if (_currentState.isBusy) return;

    _userInitiatedDisconnect = false;
    _lastServer = server;
    _killSwitchTimer?.cancel();

    _updateState(_currentState.copyWith(
      status: VpnStatus.connecting,
      selectedServer: server,
    ));

    try {
      await _simulateConnection(server);
    } catch (e) {
      _updateState(_currentState.copyWith(
        status: VpnStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _simulateConnection(ServerModel server) async {
    await Future.delayed(const Duration(seconds: 3));
    _updateState(_currentState.copyWith(
      status: VpnStatus.connected,
      selectedServer: server,
      vpnIp: '10.8.0.${(100 + server.id.hashCode % 100).abs()}',
    ));
    _prevByteIn = 0;
    _prevByteOut = 0;
    _prevStatsTime = DateTime.now();
    _startConnectionTimer();
    _startStatsPoll();
  }

  Future<void> disconnect() async {
    _userInitiatedDisconnect = true;
    _killSwitchTimer?.cancel();
    _updateState(_currentState.copyWith(status: VpnStatus.disconnecting));
    _stopTimers();
    await Future.delayed(const Duration(milliseconds: 800));
    _updateState(const VpnState());
  }

  void _startConnectionTimer() {
    _connectionTimer?.cancel();
    int seconds = _currentState.connectedSeconds;
    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds++;
      _updateState(_currentState.copyWith(connectedSeconds: seconds));
    });
  }

  void _startStatsPoll() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!_currentState.isConnected) return;
      _prevByteIn += 50000;
      _prevByteOut += 10000;
      final now = DateTime.now();
      final elapsed = now.difference(_prevStatsTime).inMilliseconds / 1000.0;
      _prevStatsTime = now;
      _updateState(_currentState.copyWith(
        downloadSpeedKbps: elapsed > 0 ? 50000 / elapsed / 1024 : 0,
        uploadSpeedKbps: elapsed > 0 ? 10000 / elapsed / 1024 : 0,
        downloadedMB: _prevByteIn / (1024 * 1024),
        uploadedMB: _prevByteOut / (1024 * 1024),
      ));
    });
  }

  void _stopTimers() {
    _connectionTimer?.cancel();
    _statsTimer?.cancel();
    _connectTimeoutTimer?.cancel();
  }

  void _updateState(VpnState state) {
    _currentState = state;
    _stateController.add(state);
  }

  Future<bool> requestPermission() async => true;

  void dispose() {
    _stopTimers();
    _killSwitchTimer?.cancel();
    _stateController.close();
  }
}
