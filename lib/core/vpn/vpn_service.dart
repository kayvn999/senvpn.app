import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart' as ovpn;
import '../../models/server_model.dart';
import 'vpn_state.dart';

class VpnService {
  static final VpnService _instance = VpnService._internal();
  factory VpnService() => _instance;
  VpnService._internal();

  ovpn.OpenVPN? _openVpn;
  final StreamController<VpnState> _stateController =
      StreamController<VpnState>.broadcast();
  VpnState _currentState = const VpnState();
  Timer? _connectionTimer;
  Timer? _statsTimer;
  Timer? _killSwitchTimer;
  Timer? _connectTimeoutTimer;

  // Settings that affect connection behavior
  bool _killSwitchEnabled = false;
  bool _dnsLeakProtectionEnabled = false;
  bool _userInitiatedDisconnect = false;
  ServerModel? _lastServer;

  Stream<VpnState> get stateStream => _stateController.stream;
  VpnState get currentState => _currentState;

  void setKillSwitch(bool enabled) => _killSwitchEnabled = enabled;
  void setDnsLeakProtection(bool enabled) => _dnsLeakProtectionEnabled = enabled;

  Future<void> initialize() async {
    if (Platform.isAndroid || Platform.isIOS) {
      _openVpn = ovpn.OpenVPN(
        onVpnStatusChanged: _onStatusChanged,
        onVpnStageChanged: _onStageChanged,
      );
      await _openVpn!.initialize(
        groupIdentifier: 'group.com.senvpn.app',
        providerBundleIdentifier: 'com.senvpn.app.VPNExtension',
        localizedDescription: 'SenVPN',
      );
    }
  }

  double _prevByteIn = 0;
  double _prevByteOut = 0;
  DateTime _prevStatsTime = DateTime.now();

  void _onStatusChanged(ovpn.VpnStatus? status) {
    if (status == null || !_currentState.isConnected) return;

    final now = DateTime.now();
    final elapsed = now.difference(_prevStatsTime).inMilliseconds / 1000.0;
    if (elapsed <= 0) return;

    final byteIn = double.tryParse(status.byteIn ?? '0') ?? 0;
    final byteOut = double.tryParse(status.byteOut ?? '0') ?? 0;

    final dlKbps = elapsed > 0 ? ((byteIn - _prevByteIn) / elapsed / 1024).clamp(0, 100000) : 0.0;
    final ulKbps = elapsed > 0 ? ((byteOut - _prevByteOut) / elapsed / 1024).clamp(0, 100000) : 0.0;

    _prevByteIn = byteIn;
    _prevByteOut = byteOut;
    _prevStatsTime = now;

    _updateState(_currentState.copyWith(
      downloadSpeedKbps: dlKbps.toDouble(),
      uploadSpeedKbps: ulKbps.toDouble(),
      downloadedMB: byteIn / (1024 * 1024),
      uploadedMB: byteOut / (1024 * 1024),
    ));
  }

  void _onStageChanged(ovpn.VPNStage stage, String rawStage) {
    debugPrint('VPN Stage: $stage');
    VpnStatus newStatus;

    switch (stage) {
      case ovpn.VPNStage.connected:
        newStatus = VpnStatus.connected;
        _connectTimeoutTimer?.cancel();
        _prevByteIn = 0;
        _prevByteOut = 0;
        _prevStatsTime = DateTime.now();
        _startConnectionTimer();
        _startStatsPoll();
        break;
      case ovpn.VPNStage.connecting:
      case ovpn.VPNStage.authenticating:
      case ovpn.VPNStage.authentication:
      case ovpn.VPNStage.prepare:
      case ovpn.VPNStage.wait_connection:
      case ovpn.VPNStage.get_config:
      case ovpn.VPNStage.assign_ip:
      case ovpn.VPNStage.tcp_connect:
      case ovpn.VPNStage.udp_connect:
        newStatus = VpnStatus.connecting;
        break;
      case ovpn.VPNStage.disconnected:
      case ovpn.VPNStage.exiting:
        newStatus = VpnStatus.disconnected;
        _connectTimeoutTimer?.cancel();
        _stopTimers();
        // Kill switch: reconnect immediately if disconnect was not user-initiated
        if (_killSwitchEnabled && !_userInitiatedDisconnect && _lastServer != null) {
          _scheduleKillSwitchReconnect();
        }
        break;
      case ovpn.VPNStage.disconnecting:
        newStatus = VpnStatus.disconnecting;
        break;
      case ovpn.VPNStage.error:
      case ovpn.VPNStage.denied:
        newStatus = VpnStatus.error;
        _stopTimers();
        // Kill switch: also reconnect on error
        if (_killSwitchEnabled && !_userInitiatedDisconnect && _lastServer != null) {
          _scheduleKillSwitchReconnect();
        }
        break;
      default:
        return;
    }

    _updateState(_currentState.copyWith(status: newStatus));
  }

  void _scheduleKillSwitchReconnect() {
    _killSwitchTimer?.cancel();
    _killSwitchTimer = Timer(const Duration(seconds: 2), () {
      if (!_currentState.isConnected && !_currentState.isConnecting && _lastServer != null) {
        connect(_lastServer!);
      }
    });
  }

  // Fix legacy VPNGate configs for OpenVPN 2.5+ compatibility
  String _fixLegacyConfig(String config) {
    return config
        // Replace deprecated ciphers
        .replaceAll(RegExp(r'cipher AES-128-CBC.*', multiLine: true), 'cipher AES-256-GCM\ndata-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC')
        .replaceAll(RegExp(r'auth SHA1.*', multiLine: true), 'auth SHA256')
        // Remove deprecated options
        .replaceAll(RegExp(r'ns-cert-type server.*\n?', multiLine: true), 'remote-cert-tls server\n')
        .replaceAll(RegExp(r'comp-lzo.*\n?', multiLine: true), '')
        .replaceAll(RegExp(r'ncp-ciphers.*\n?', multiLine: true), '');
  }

  // Inject DNS settings into OpenVPN config for DNS leak protection
  String _applyDnsProtection(String config) {
    const dnsBlock = '\n'
        'dhcp-option DNS 8.8.8.8\n'
        'dhcp-option DNS 8.8.4.4\n'
        'block-outside-dns\n';
    // Remove existing dhcp-option DNS lines first to avoid duplicates
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
      if ((Platform.isAndroid || Platform.isIOS) &&
          server.ovpnConfig != null &&
          server.ovpnConfig!.isNotEmpty) {
        final fixed = _fixLegacyConfig(server.ovpnConfig!);
        final config = _dnsLeakProtectionEnabled
            ? _applyDnsProtection(fixed)
            : fixed;
        _openVpn!.connect(
          config,
          server.name,
          certIsRequired: false,
          bypassPackages: [],
          username: server.vpnUsername,
          password: server.vpnPassword,
        );
        _connectTimeoutTimer?.cancel();
        _connectTimeoutTimer = Timer(const Duration(seconds: 30), () {
          if (_currentState.isConnecting) {
            _openVpn!.disconnect();
            _updateState(_currentState.copyWith(
              status: VpnStatus.error,
              errorMessage: 'Connection timeout',
            ));
          }
        });
      } else {
        await _simulateConnection(server);
      }
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
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        _openVpn!.disconnect();
      }
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (_) {}
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
      if (!_currentState.isConnected || _openVpn == null) return;
      try {
        final status = await _openVpn!.status();
        _onStatusChanged(status);
      } catch (_) {}
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

  Future<bool> requestPermission() async {
    if (Platform.isAndroid && _openVpn != null) {
      return await _openVpn!.requestPermissionAndroid();
    }
    return true;
  }

  void dispose() {
    _stopTimers();
    _killSwitchTimer?.cancel();
    _stateController.close();
  }
}
