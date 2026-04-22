import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/device_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';
  final _keyController = TextEditingController();
  bool _activating = false;
  String? _activateMsg;
  bool _activateSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = 'v${info.version}');
  }

  Future<void> _activateKey() async {
    final key = _keyController.text.trim().toUpperCase();
    if (key.isEmpty) return;
    setState(() { _activating = true; _activateMsg = null; });
    try {
      final deviceId = await DeviceService.instance.getDeviceId();
      final res = await http.post(
        Uri.parse('https://lephap.io.vn/api/activate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': key, 'deviceId': deviceId}),
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final s = ref.read(l10nProvider);
      if (res.statusCode == 200) {
        _keyController.clear();
        setState(() { _activateSuccess = true; _activateMsg = s.activationSuccess; });
        ref.invalidate(userModelProvider);
      } else {
        setState(() { _activateSuccess = false; _activateMsg = body['error'] as String? ?? s.activateButton; });
      }
    } catch (_) {
      setState(() { _activateSuccess = false; _activateMsg = ref.read(l10nProvider).activationConnecting; });
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userModelProvider).valueOrNull;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final config = ref.watch(freeConfigProvider);
    final lang = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);
    final s = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: SafeArea(
          child: Column(
            children: [
              // ─── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Text(
                      s.settingsTitle,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // ─── Profile Card ─────────────────────────────────────
                    _ProfileCard(user: user)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.05, end: 0),

                    const SizedBox(height: 24),

                    // ─── VPN Settings ─────────────────────────────────────
                    _SectionHeader(title: s.sectionVpn),
                    _SettingToggle(
                      icon: Icons.power_settings_new_rounded,
                      iconColor: AppColors.primary,
                      title: s.autoConnect,
                      subtitle: s.autoConnectSub,
                      value: settings.autoConnect,
                      onChanged: settingsNotifier.setAutoConnect,
                    ),
                    _SettingToggle(
                      icon: Icons.security_rounded,
                      iconColor: AppColors.disconnected,
                      title: s.killSwitch,
                      subtitle: s.killSwitchSub,
                      value: settings.killSwitch,
                      onChanged: settingsNotifier.setKillSwitch,
                      isPremium: true,
                      isPremiumUser: user?.isPremium ?? false,
                    ),
                    _SettingToggle(
                      icon: Icons.dns_rounded,
                      iconColor: AppColors.accent,
                      title: s.dnsLeak,
                      subtitle: s.dnsLeakSub,
                      value: settings.dnsLeakProtection,
                      onChanged: settingsNotifier.setDnsLeakProtection,
                      isPremium: true,
                      isPremiumUser: user?.isPremium ?? false,
                    ),

                    const SizedBox(height: 24),

                    // ─── Security ─────────────────────────────────────────
                    _SectionHeader(title: s.sectionSecurity),
                    _SettingToggle(
                      icon: Icons.fingerprint_rounded,
                      iconColor: AppColors.vipGold,
                      title: s.biometric,
                      subtitle: s.biometricSub,
                      value: settings.biometricLock,
                      onChanged: settingsNotifier.setBiometricLock,
                    ),
                    _SettingToggle(
                      icon: Icons.notifications_rounded,
                      iconColor: AppColors.primary,
                      title: s.notifications,
                      subtitle: s.notificationsSub,
                      value: settings.notificationsEnabled,
                      onChanged: settingsNotifier.setNotifications,
                    ),

                    const SizedBox(height: 24),

                    // ─── Activation Key ───────────────────────────────────
                    _SectionHeader(title: s.sectionActivation),
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.activationTitle,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _keyController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: s.activationHint,
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFD1D5DB),
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 1,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.primary),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  onSubmitted: (_) => _activateKey(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _activating ? null : _activateKey,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 18),
                                    elevation: 0,
                                  ),
                                  child: _activating
                                      ? const SizedBox(
                                          width: 18, height: 18,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Text(s.activateButton, style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                          if (_activateMsg != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _activateSuccess
                                    ? const Color(0xFFF0FDF4)
                                    : const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _activateSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                                    size: 16,
                                    color: _activateSuccess ? AppColors.connected : AppColors.disconnected,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _activateMsg!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _activateSuccess ? AppColors.connected : AppColors.disconnected,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Language ─────────────────────────────────────────
                    _SectionHeader(title: s.sectionLanguage),
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          _LangOption(
                            flag: '🇻🇳',
                            label: 'Tiếng Việt',
                            selected: lang == 'vi',
                            onTap: () => localeNotifier.setLanguage('vi'),
                          ),
                          Container(width: 1, height: 48, color: const Color(0xFFE5E7EB)),
                          _LangOption(
                            flag: '🇺🇸',
                            label: 'English',
                            selected: lang == 'en',
                            onTap: () => localeNotifier.setLanguage('en'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── About ────────────────────────────────────────────
                    _SectionHeader(title: s.sectionAbout),
                    _SettingTile(
                      icon: Icons.star_rounded,
                      iconColor: AppColors.vipGold,
                      title: s.rateApp,
                      onTap: config.storeUrl.isNotEmpty
                          ? () => launchUrl(Uri.parse(config.storeUrl), mode: LaunchMode.externalApplication)
                          : null,
                    ),
                    _SettingTile(
                      icon: Icons.share_rounded,
                      iconColor: AppColors.accent,
                      title: s.shareApp,
                      onTap: config.storeUrl.isNotEmpty
                          ? () => Share.share('${config.shareText}${config.storeUrl}')
                          : null,
                    ),
                    _SettingTile(
                      icon: Icons.privacy_tip_rounded,
                      iconColor: AppColors.primary,
                      title: s.privacyPolicy,
                      onTap: config.privacyPolicyUrl.isNotEmpty
                          ? () => launchUrl(Uri.parse(config.privacyPolicyUrl), mode: LaunchMode.externalApplication)
                          : null,
                    ),
                    _SettingTile(
                      icon: Icons.description_rounded,
                      iconColor: AppColors.textSecondary,
                      title: s.termsOfService,
                      onTap: config.termsUrl.isNotEmpty
                          ? () => launchUrl(Uri.parse(config.termsUrl), mode: LaunchMode.externalApplication)
                          : null,
                    ),
                    _SettingTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.textMuted,
                      title: s.appVersion,
                      trailing: Text(
                        _appVersion,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const SizedBox(height: 32),
                  ].animate(interval: 30.ms).fadeIn(),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  const _ProfileCard({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Row(
        children: [
          // Avatar
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFEEF2FF),
            backgroundImage: AssetImage('assets/images/user.png'),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Khách',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email?.isNotEmpty == true
                      ? user!.email
                      : user?.shortId.isNotEmpty == true
                          ? 'ID: #${user!.shortId}'
                          : 'Khách ẩn danh',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Plan badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: user?.isPremium == true
                  ? AppColors.vipGradient
                  : null,
              color: user?.isPremium == true ? null : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user?.subscriptionLabel ?? 'Free',
              style: TextStyle(
                color: user?.isPremium == true
                    ? Colors.black
                    : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF374151),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isPremium;
  final bool isPremiumUser;

  const _SettingToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isPremium = false,
    this.isPremiumUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = isPremium && !isPremiumUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isPremium) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          gradient: AppColors.vipGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VIP',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isLocked)
            GestureDetector(
              onTap: () => context.push('/vip'),
              child: const Icon(Icons.lock_rounded,
                  color: AppColors.vipGold, size: 20),
            )
          else
            Switch(
              value: value,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF2FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? const Color(0xFF4338CA) : const Color(0xFF6B7280),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF6C63FF)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.bgSurface),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted, size: 20)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
