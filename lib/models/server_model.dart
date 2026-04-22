import 'package:cloud_firestore/cloud_firestore.dart';

// Handles Firestore data that may be stored as strings ("true", "42") or proper types.
bool _toBool(dynamic v, {bool def = false}) {
  if (v == null) return def;
  if (v is bool) return v;
  if (v is String) return v == 'true' || v == '1';
  if (v is int) return v != 0;
  return def;
}

int _toInt(dynamic v, {int def = 0}) {
  if (v == null) return def;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? def;
  return def;
}

double _toDouble(dynamic v, {double def = 0}) {
  if (v == null) return def;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? def;
  return def;
}

class ServerModel {
  final String id;
  final String name;
  final String host;
  final int port;
  final String protocol;
  final String country;
  final String countryCode;
  final String flag;
  final int ping;
  final int load;
  final bool isFree;
  final bool isVip;
  final String? ovpnConfig;
  final String? vpnUsername;
  final String? vpnPassword;
  final bool isActive;
  final double latitude;
  final double longitude;
  final int userCount;
  final double speedMbps;

  const ServerModel({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.protocol,
    required this.country,
    required this.countryCode,
    required this.flag,
    required this.ping,
    required this.load,
    required this.isFree,
    required this.isVip,
    this.ovpnConfig,
    this.vpnUsername,
    this.vpnPassword,
    required this.isActive,
    this.latitude = 0,
    this.longitude = 0,
    this.userCount = 0,
    this.speedMbps = 100,
  });

  factory ServerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isVip = _toBool(data['isVip'] ?? data['isPremium']);
    return ServerModel(
      id: doc.id,
      name: data['name'] ?? '',
      host: data['host'] ?? '',
      port: _toInt(data['port'], def: 1194),
      protocol: data['protocol'] ?? 'OpenVPN',
      country: data['country'] ?? '',
      countryCode: data['countryCode'] ?? '',
      flag: data['flag'] ?? '🌍',
      ping: _toInt(data['ping'], def: 99),
      load: _toInt(data['load'], def: 0),
      isFree: data['isFree'] != null ? _toBool(data['isFree']) : !isVip,
      isVip: isVip,
      ovpnConfig: data['ovpnConfig'] as String?,
      vpnUsername: data['vpnUsername'] as String?,
      vpnPassword: data['vpnPassword'] as String?,
      isActive: _toBool(data['isActive'], def: true),
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      userCount: _toInt(data['userCount']),
      speedMbps: _toDouble(data['speedMbps'], def: 100),
    );
  }

  factory ServerModel.fromMap(Map<String, dynamic> data, String id) {
    final isVip = _toBool(data['isVip'] ?? data['isPremium']);
    return ServerModel(
      id: id,
      name: data['name'] ?? '',
      host: data['host'] ?? '',
      port: _toInt(data['port'], def: 1194),
      protocol: data['protocol'] ?? 'OpenVPN',
      country: data['country'] ?? '',
      countryCode: data['countryCode'] ?? '',
      flag: data['flag'] ?? '🌍',
      ping: _toInt(data['ping'], def: 99),
      load: _toInt(data['load'], def: 0),
      isFree: data['isFree'] != null ? _toBool(data['isFree']) : !isVip,
      isVip: isVip,
      ovpnConfig: data['ovpnConfig'] as String?,
      vpnUsername: data['vpnUsername'] as String?,
      vpnPassword: data['vpnPassword'] as String?,
      isActive: _toBool(data['isActive'], def: true),
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      userCount: _toInt(data['userCount']),
      speedMbps: _toDouble(data['speedMbps'], def: 100),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'host': host,
      'port': port,
      'protocol': protocol,
      'country': country,
      'countryCode': countryCode,
      'flag': flag,
      'ping': ping,
      'load': load,
      'isFree': isFree,
      'isVip': isVip,
      'ovpnConfig': ovpnConfig,
      'vpnUsername': vpnUsername,
      'vpnPassword': vpnPassword,
      'isActive': isActive,
      'latitude': latitude,
      'longitude': longitude,
      'userCount': userCount,
      'speedMbps': speedMbps,
    };
  }

  ServerModel copyWith({bool? isActive, bool? isFree, bool? isVip}) {
    return ServerModel(
      id: id, name: name, host: host, port: port, protocol: protocol,
      country: country, countryCode: countryCode, flag: flag,
      ping: ping, load: load, ovpnConfig: ovpnConfig,
      vpnUsername: vpnUsername, vpnPassword: vpnPassword,
      latitude: latitude, longitude: longitude,
      userCount: userCount, speedMbps: speedMbps,
      isFree: isFree ?? this.isFree,
      isVip: isVip ?? this.isVip,
      isActive: isActive ?? this.isActive,
    );
  }

  String get pingLabel {
    if (ping < 50) return 'Nhanh';
    if (ping < 100) return 'Tốt';
    if (ping < 200) return 'Trung bình';
    return 'Chậm';
  }

  String get loadLabel {
    if (load < 30) return 'Thấp';
    if (load < 70) return 'Trung bình';
    return 'Cao';
  }
}
