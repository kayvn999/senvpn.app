import '../../models/server_model.dart';

enum VpnStatus { disconnected, connecting, connected, disconnecting, error }

class VpnState {
  final VpnStatus status;
  final ServerModel? selectedServer;
  final String? errorMessage;
  final int connectedSeconds;
  final double downloadSpeedKbps;
  final double uploadSpeedKbps;
  final double downloadedMB;
  final double uploadedMB;
  final String? currentIp;
  final String? vpnIp;

  const VpnState({
    this.status = VpnStatus.disconnected,
    this.selectedServer,
    this.errorMessage,
    this.connectedSeconds = 0,
    this.downloadSpeedKbps = 0,
    this.uploadSpeedKbps = 0,
    this.downloadedMB = 0,
    this.uploadedMB = 0,
    this.currentIp,
    this.vpnIp,
  });

  bool get isConnected => status == VpnStatus.connected;
  bool get isConnecting => status == VpnStatus.connecting;
  bool get isDisconnected => status == VpnStatus.disconnected;
  bool get isBusy => status == VpnStatus.connecting || status == VpnStatus.disconnecting;

  String get statusLabel {
    switch (status) {
      case VpnStatus.connected:
        return 'Đã kết nối';
      case VpnStatus.connecting:
        return 'Đang kết nối...';
      case VpnStatus.disconnected:
        return 'Chưa kết nối';
      case VpnStatus.disconnecting:
        return 'Đang ngắt kết nối...';
      case VpnStatus.error:
        return 'Lỗi kết nối';
    }
  }

  String get connectedTimeLabel {
    final hours = connectedSeconds ~/ 3600;
    final minutes = (connectedSeconds % 3600) ~/ 60;
    final seconds = connectedSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get downloadSpeedLabel {
    if (downloadSpeedKbps < 1000) {
      return '${downloadSpeedKbps.toStringAsFixed(1)} KB/s';
    }
    return '${(downloadSpeedKbps / 1024).toStringAsFixed(1)} MB/s';
  }

  String get uploadSpeedLabel {
    if (uploadSpeedKbps < 1000) {
      return '${uploadSpeedKbps.toStringAsFixed(1)} KB/s';
    }
    return '${(uploadSpeedKbps / 1024).toStringAsFixed(1)} MB/s';
  }

  VpnState copyWith({
    VpnStatus? status,
    ServerModel? selectedServer,
    String? errorMessage,
    int? connectedSeconds,
    double? downloadSpeedKbps,
    double? uploadSpeedKbps,
    double? downloadedMB,
    double? uploadedMB,
    String? currentIp,
    String? vpnIp,
  }) {
    return VpnState(
      status: status ?? this.status,
      selectedServer: selectedServer ?? this.selectedServer,
      errorMessage: errorMessage ?? this.errorMessage,
      connectedSeconds: connectedSeconds ?? this.connectedSeconds,
      downloadSpeedKbps: downloadSpeedKbps ?? this.downloadSpeedKbps,
      uploadSpeedKbps: uploadSpeedKbps ?? this.uploadSpeedKbps,
      downloadedMB: downloadedMB ?? this.downloadedMB,
      uploadedMB: uploadedMB ?? this.uploadedMB,
      currentIp: currentIp ?? this.currentIp,
      vpnIp: vpnIp ?? this.vpnIp,
    );
  }
}
