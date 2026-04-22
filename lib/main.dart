import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'core/ads/admob_service.dart';
import 'core/firebase/remote_config_service.dart';
import 'core/services/device_service.dart';
import 'core/services/revenuecat_service.dart';
import 'core/vpn/vpn_service.dart';
import 'providers/locale_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0E1A),
  ));

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Remote Config
  await RemoteConfigService().initialize();

  // AdMob
  await AdmobService().initialize();

  // FCM permissions (required on iOS and Android 13+)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // RevenueCat
  final deviceId = await DeviceService.instance.getDeviceId();
  await RevenueCatService().initialize(deviceId);

  // VPN Service
  await VpnService().initialize();

  // Load saved language before first frame
  final savedLang = await LocaleNotifier.getSavedLanguage() ?? 'vi';

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((_) => LocaleNotifier(savedLang)),
      ],
      child: const SecureVpnApp(),
    ),
  );
}
