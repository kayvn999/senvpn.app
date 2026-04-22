import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/locale_provider.dart' show l10nProvider;
import '../../providers/user_provider.dart';
import '../../providers/settings_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _locked = false;
  bool _authenticating = false;
  final _localAuth = LocalAuthentication();

  static const List<_NavItem> _navRoutes = [
    _NavItem(icon: Icons.home_rounded, label: '', route: '/home'),
    _NavItem(icon: Icons.dns_rounded, label: '', route: '/servers'),
    _NavItem(icon: Icons.workspace_premium_rounded, label: 'VIP', route: '/vip'),
    _NavItem(icon: Icons.settings_rounded, label: '', route: '/settings'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final settings = ref.read(settingsProvider);
      if (settings.biometricLock) {
        setState(() => _locked = true);
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    _authenticating = true;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) {
        // Device doesn't support biometric — unlock anyway
        if (mounted) setState(() => _locked = false);
        return;
      }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Xác nhận danh tính để mở SEN VPN',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (mounted) setState(() => _locked = !authenticated);
    } catch (_) {
      if (mounted) setState(() => _locked = false);
    } finally {
      _authenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(fcmTopicSyncProvider);
    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          if (_locked) _BiometricLockScreen(onUnlock: _authenticate),
        ],
      ),
      bottomNavigationBar: _locked
          ? null
          : _BottomNav(
              selectedIndex: _selectedIndex,
              onTap: (index) {
                setState(() => _selectedIndex = index);
                context.go(_navRoutes[index].route);
              },
            ),
    );
  }
}

class _BiometricLockScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  const _BiometricLockScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FF),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fingerprint_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ứng dụng đã bị khóa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Xác thực để tiếp tục',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text('Mở khóa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}

class _BottomNav extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    final items = [
      _BottomNavItem(icon: Icons.home_rounded, label: s.navHome, index: 0),
      _BottomNavItem(icon: Icons.dns_rounded, label: s.navServers, index: 1),
      _BottomNavItem(icon: Icons.workspace_premium_rounded, label: 'VIP', index: 2),
      _BottomNavItem(icon: Icons.settings_rounded, label: s.navSettings, index: 3),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: const Border(
          top: BorderSide(color: AppColors.bgSurface, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items
                .map(
                  (item) => GestureDetector(
                    onTap: () => onTap(item.index),
                    behavior: HitTestBehavior.opaque,
                    child: _NavButton(
                      item: item,
                      isSelected: selectedIndex == item.index,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;
  final int index;
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

class _NavButton extends StatelessWidget {
  final _BottomNavItem item;
  final bool isSelected;

  const _NavButton({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
