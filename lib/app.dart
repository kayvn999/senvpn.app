import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/servers/servers_screen.dart';
import 'features/vip/vip_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/language/language_screen.dart';
import 'features/main/main_shell.dart';
import 'providers/app_config_provider.dart';
import 'providers/locale_provider.dart';
import 'widgets/maintenance_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/servers',
          builder: (context, state) => const ServersScreen(),
        ),
        GoRoute(
          path: '/vip',
          builder: (context, state) => const VipScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

class SecureVpnApp extends ConsumerWidget {
  const SecureVpnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(materialLocaleProvider);
    return MaterialApp.router(
      title: 'SecureVPN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      routerConfig: _router,
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, _) {
            final config = ref.watch(freeConfigProvider);
            if (config.maintenanceMode) {
              return MaintenanceScreen(message: config.maintenanceMessage);
            }
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
