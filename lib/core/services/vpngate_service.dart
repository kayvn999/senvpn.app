import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/server_model.dart';

/// VPNGate volunteer VPN network — University of Tsukuba, Japan.
/// Public API returns thousands of free OpenVPN servers with real .ovpn configs.
/// Docs: https://www.vpngate.net/en/about_us.aspx
class VpnGateService {
  static const _apiUrl = 'https://www.vpngate.net/api/iphone/';

  // CSV column indices
  static const _iHostname = 0;
  static const _iIp = 1;
  static const _iScore = 2;
  static const _iPing = 3;
  static const _iSpeed = 4;       // bytes/sec
  static const _iCountryLong = 5;
  static const _iCountryShort = 6;
  static const _iSessions = 7;
  static const _iOvpn = 14;       // base64-encoded .ovpn config

  /// Fetch and parse servers. Returns sorted by ping ascending.
  static Future<List<ServerModel>> fetchServers({
    int maxTotal = 200,
    int maxPerCountry = 5,
    List<String> blockedCountries = const [],
    List<String> allowedCountries = const [], // empty = all allowed
  }) async {
    try {
      final resp = await http
          .get(Uri.parse(_apiUrl), headers: {'User-Agent': 'SecureVPN/1.0'})
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return [];
      return _parse(
        resp.body,
        maxTotal: maxTotal,
        maxPerCountry: maxPerCountry,
        blockedCountries: blockedCountries.map((c) => c.toUpperCase()).toSet(),
        allowedCountries: allowedCountries.map((c) => c.toUpperCase()).toSet(),
      );
    } catch (_) {
      return [];
    }
  }

  static List<ServerModel> _parse(
    String csv, {
    required int maxTotal,
    required int maxPerCountry,
    Set<String> blockedCountries = const {},
    Set<String> allowedCountries = const {},
  }) {
    final lines = const LineSplitter().convert(csv);
    final servers = <ServerModel>[];
    final countryCount = <String, int>{};

    for (final line in lines) {
      if (line.startsWith('*') || line.startsWith('#') || line.trim().isEmpty) {
        continue;
      }
      final cols = line.split(',');
      if (cols.length <= _iOvpn) continue;

      try {
        final countryShort = cols[_iCountryShort].toUpperCase().trim();
        if (countryShort.length != 2) continue;

        // Apply admin country filters
        if (blockedCountries.contains(countryShort)) continue;
        if (allowedCountries.isNotEmpty && !allowedCountries.contains(countryShort)) continue;

        final count = countryCount[countryShort] ?? 0;
        if (count >= maxPerCountry) continue;

        final ip = cols[_iIp].trim();
        final ping = int.tryParse(cols[_iPing].trim()) ?? 999;
        final speedBps = int.tryParse(cols[_iSpeed].trim()) ?? 0;
        final countryLong = _cleanName(cols[_iCountryLong]);
        final sessions = int.tryParse(cols[_iSessions].trim()) ?? 0;
        final ovpnBase64 = cols[_iOvpn].trim();

        String ovpnConfig;
        try {
          ovpnConfig = utf8.decode(base64.decode(ovpnBase64));
        } catch (_) {
          continue;
        }
        if (ovpnConfig.isEmpty || !ovpnConfig.contains('client')) continue;

        final speedMbps = speedBps / 1000000.0;
        final load = (sessions / 20).clamp(0, 100).toInt();

        // Add numbering when multiple servers from same country
        final displayName = count == 0 ? countryLong : '$countryLong #${count + 1}';

        servers.add(ServerModel(
          id: 'vg_${ip}_$countryShort',
          name: displayName,
          host: ip,
          port: 1194,
          protocol: 'OpenVPN',
          country: countryLong,
          countryCode: countryShort,
          flag: _flag(countryShort),
          ping: ping.clamp(0, 999),
          load: load,
          isFree: true,
          isVip: false,
          ovpnConfig: ovpnConfig,
          isActive: true,
          speedMbps: speedMbps,
          userCount: sessions,
        ));

        countryCount[countryShort] = count + 1;
        if (servers.length >= maxTotal) break;
      } catch (_) {
        continue;
      }
    }

    servers.sort((a, b) => a.ping.compareTo(b.ping));
    return servers;
  }

  static String _cleanName(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return 'Unknown';
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  static String _flag(String code) {
    try {
      final a = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
      final b = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
      return String.fromCharCode(a) + String.fromCharCode(b);
    } catch (_) {
      return '🌍';
    }
  }
}
