import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/vpn/vpn_state.dart';

class ConnectButton extends StatelessWidget {
  final VpnState vpnState;
  final VoidCallback onTap;

  const ConnectButton({
    super.key,
    required this.vpnState,
    required this.onTap,
  });

  Color get _primaryColor {
    switch (vpnState.status) {
      case VpnStatus.connected:
        return AppColors.connected;
      case VpnStatus.connecting:
      case VpnStatus.disconnecting:
        return AppColors.connecting;
      case VpnStatus.error:
        return AppColors.disconnected;
      case VpnStatus.disconnected:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: vpnState.isBusy ? null : onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          if (vpnState.isConnected)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.connected.withOpacity(0.2),
                  width: 1,
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  duration: 1800.ms,
                )
                .fadeOut(begin: 0.5, duration: 1800.ms),

          // Middle ring
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _primaryColor.withOpacity(0.15),
                width: 1.5,
              ),
            ),
          ),

          // Main button
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: vpnState.isConnected
                    ? [const Color(0xFF00BFA5), const Color(0xFF00897B)]
                    : vpnState.isBusy
                        ? [const Color(0xFFFFD600), const Color(0xFFFFA000)]
                        : [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: vpnState.isBusy
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        vpnState.isConnected
                            ? Icons.power_settings_new_rounded
                            : Icons.power_settings_new_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vpnState.isConnected ? 'TAP TO\nDISCONNECT' : 'TAP TO\nCONNECT',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
