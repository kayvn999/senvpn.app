import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static const _key = 'sen_device_id';
  static final DeviceService instance = DeviceService._();
  DeviceService._();

  String? _cached;

  Future<String> getDeviceId() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null) {
      id = _generateUuid();
      await prefs.setString(_key, id);
    }
    _cached = id;
    return id;
  }

  String _generateUuid() {
    final r = Random.secure();
    final b = List.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
