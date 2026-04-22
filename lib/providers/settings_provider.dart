import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class AppSettings {
  final bool autoConnect;
  final bool killSwitch;
  final bool dnsLeakProtection;
  final bool biometricLock;
  final bool notificationsEnabled;
  final String protocol;

  const AppSettings({
    this.autoConnect = false,
    this.killSwitch = true,
    this.dnsLeakProtection = true,
    this.biometricLock = false,
    this.notificationsEnabled = true,
    this.protocol = 'Auto',
  });

  AppSettings copyWith({
    bool? autoConnect,
    bool? killSwitch,
    bool? dnsLeakProtection,
    bool? biometricLock,
    bool? notificationsEnabled,
    String? protocol,
  }) {
    return AppSettings(
      autoConnect: autoConnect ?? this.autoConnect,
      killSwitch: killSwitch ?? this.killSwitch,
      dnsLeakProtection: dnsLeakProtection ?? this.dnsLeakProtection,
      biometricLock: biometricLock ?? this.biometricLock,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      protocol: protocol ?? this.protocol,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      autoConnect: prefs.getBool(AppConstants.keyAutoConnect) ?? false,
      killSwitch: prefs.getBool(AppConstants.keyKillSwitch) ?? true,
      dnsLeakProtection: prefs.getBool(AppConstants.keyDnsLeak) ?? true,
      biometricLock: prefs.getBool(AppConstants.keyBiometric) ?? false,
      notificationsEnabled: prefs.getBool(AppConstants.keyNotifications) ?? true,
      protocol: prefs.getString(AppConstants.keyProtocol) ?? 'Auto',
    );
  }

  Future<void> setAutoConnect(bool value) async {
    state = state.copyWith(autoConnect: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAutoConnect, value);
  }

  Future<void> setKillSwitch(bool value) async {
    state = state.copyWith(killSwitch: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyKillSwitch, value);
  }

  Future<void> setDnsLeakProtection(bool value) async {
    state = state.copyWith(dnsLeakProtection: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyDnsLeak, value);
  }

  Future<void> setBiometricLock(bool value) async {
    state = state.copyWith(biometricLock: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyBiometric, value);
  }

  Future<void> setNotifications(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyNotifications, value);
    final msg = FirebaseMessaging.instance;
    if (value) {
      await msg.subscribeToTopic('all_users');
    } else {
      await msg.unsubscribeFromTopic('all_users');
      await msg.unsubscribeFromTopic('vip_users');
      await msg.unsubscribeFromTopic('free_users');
    }
  }

  Future<void> setProtocol(String protocol) async {
    state = state.copyWith(protocol: protocol);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyProtocol, protocol);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
