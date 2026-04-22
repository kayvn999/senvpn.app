import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/vpn/vpn_state.dart';

class ConnectionStats extends StatelessWidget {
  final VpnState vpnState;

  const ConnectionStats({super.key, required this.vpnState});

  @override
  Widget build(BuildContext context) {
    if (!vpnState.isConnected) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.bgSurface),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Connection time
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.accent, size: 16),
                const SizedBox(width: 6),
                Text(
                  vpnState.connectedTimeLabel,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: AppColors.bgSurface, height: 1),
            const SizedBox(height: 16),

            // Speed stats
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.download_rounded,
                    label: 'Download',
                    value: vpnState.downloadSpeedLabel,
                    color: AppColors.connected,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.bgSurface,
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.upload_rounded,
                    label: 'Upload',
                    value: vpnState.uploadSpeedLabel,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: AppColors.bgSurface, height: 1),
            const SizedBox(height: 16),

            // IP & Location
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.language_rounded,
                    label: 'VPN IP',
                    value: vpnState.vpnIp ?? '—',
                    color: AppColors.vipGold,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.bgSurface,
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.location_on_rounded,
                    label: 'Máy chủ',
                    value: vpnState.selectedServer?.countryCode ?? '—',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
