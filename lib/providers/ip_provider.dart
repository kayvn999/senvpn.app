import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'vpn_provider.dart';
import '../core/vpn/vpn_state.dart';

class IpInfo {
  final String ip;
  final String country;
  final String countryCode;
  final String city;

  const IpInfo({
    required this.ip,
    required this.country,
    required this.countryCode,
    required this.city,
  });
}

Future<IpInfo?> _fetchIp() async {
  final sources = [_tryIpwho, _tryIpapiCo, _tryIpinfo];
  for (final src in sources) {
    try {
      final result = await src();
      if (result != null && result.ip.isNotEmpty) return result;
    } catch (_) {}
  }
  return null;
}

Future<IpInfo?> _tryIpapiCo() async {
  final res = await http
      .get(Uri.parse('https://ipapi.co/json/'))
      .timeout(const Duration(seconds: 6));
  if (res.statusCode != 200) return null;
  final d = jsonDecode(res.body) as Map<String, dynamic>;
  if (d['error'] == true) return null;
  return IpInfo(
    ip: d['ip'] as String? ?? '',
    country: d['country_name'] as String? ?? '',
    countryCode: d['country_code'] as String? ?? '',
    city: d['city'] as String? ?? '',
  );
}

Future<IpInfo?> _tryIpwho() async {
  final res = await http
      .get(Uri.parse('https://ipwho.is/'))
      .timeout(const Duration(seconds: 6));
  if (res.statusCode != 200) return null;
  final d = jsonDecode(res.body) as Map<String, dynamic>;
  if (d['success'] == false) return null;
  return IpInfo(
    ip: d['ip'] as String? ?? '',
    country: d['country'] as String? ?? '',
    countryCode: d['country_code'] as String? ?? '',
    city: d['city'] as String? ?? '',
  );
}

Future<IpInfo?> _tryIpinfo() async {
  final res = await http
      .get(Uri.parse('https://ipinfo.io/json'))
      .timeout(const Duration(seconds: 6));
  if (res.statusCode != 200) return null;
  final d = jsonDecode(res.body) as Map<String, dynamic>;
  final cc = d['country'] as String? ?? '';
  return IpInfo(
    ip: d['ip'] as String? ?? '',
    country: cc,
    countryCode: cc,
    city: d['city'] as String? ?? '',
  );
}

/// IP thật của thiết bị — KHÔNG thay đổi theo VPN, luôn hiện IP gốc.
/// Dùng cho card "IP & Vị trí" ở dưới.
final realIpProvider = FutureProvider<IpInfo?>((ref) async {
  return _fetchIp();
});

/// IP sau khi VPN kết nối — refetch khi VPN connect/disconnect.
/// Dùng cho row "IP — Ẩn danh" ở trên (chỉ hiện khi connected).
final publicIpProvider = FutureProvider.autoDispose<IpInfo?>((ref) async {
  ref.listen<VpnState>(vpnNotifierProvider, (prev, next) {
    final wasBusy = prev?.isBusy ?? false;
    final nowStable = !next.isBusy;
    if (wasBusy && nowStable) {
      // Đợi tunnel ổn định rồi fetch lại
      Future.delayed(const Duration(seconds: 6), () => ref.invalidateSelf());
    }
  });
  // Nếu đang connected thì đợi tunnel ổn định trước khi fetch lần đầu
  final vpnState = ref.read(vpnNotifierProvider);
  if (vpnState.isConnected) {
    await Future.delayed(const Duration(seconds: 6));
  }
  return _fetchIp();
});
