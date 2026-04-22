import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/firebase/firestore_service.dart';
import '../../providers/locale_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Check force update before navigating
    final shouldBlock = await _checkForceUpdate();
    if (shouldBlock || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;
    if (!mounted) return;
    if (isFirstLaunch) {
      final savedLang = await LocaleNotifier.getSavedLanguage();
      if (!mounted) return;
      context.go(savedLang == null ? '/language' : '/onboarding');
    } else {
      context.go('/home');
    }
  }

  /// Returns true if a force-update dialog was shown and navigation should halt.
  Future<bool> _checkForceUpdate() async {
    try {
      final versionData = await FirestoreService().getAppVersion();
      if (versionData == null) return false;
      final forceUpdate = versionData['forceUpdate'] as bool? ?? false;
      if (!forceUpdate) return false;

      final info = await PackageInfo.fromPlatform();
      final minVersion = versionData['minVersion'] as String? ?? '1.0.0';
      if (!_isVersionLower(info.version, minVersion)) return false;

      if (!mounted) return true;
      _showForceUpdateDialog(
        versionData['downloadUrl'] as String? ?? '',
        versionData['releaseNotes'] as String? ?? '',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isVersionLower(String current, String minimum) {
    final c = current.split('.').map(int.tryParse).toList();
    final m = minimum.split('.').map(int.tryParse).toList();
    for (int i = 0; i < 3; i++) {
      final cv = i < c.length ? (c[i] ?? 0) : 0;
      final mv = i < m.length ? (m[i] ?? 0) : 0;
      if (cv < mv) return true;
      if (cv > mv) return false;
    }
    return false;
  }

  void _showForceUpdateDialog(String downloadUrl, String releaseNotes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cần cập nhật ứng dụng',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Text(
            releaseNotes.isNotEmpty
                ? releaseNotes
                : 'Phiên bản mới đã sẵn sàng. Vui lòng cập nhật để tiếp tục sử dụng.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (downloadUrl.isNotEmpty) {
                  final uri = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                }
              },
              child: const Text('Cập nhật ngay',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            )
                .animate()
                .scale(
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(1.0, 1.0),
                  duration: 700.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // Tagline
            const Text(
              'Fast. Secure. Private.',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

            const SizedBox(height: 80),

            // Loading indicator
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ).animate().fadeIn(delay: 900.ms),
          ],
        ),
      ),
    );
  }
}
