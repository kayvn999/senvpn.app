import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/vpn/vpn_state.dart';
import '../../providers/locale_provider.dart';
import '../../providers/vpn_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/ip_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpnState = ref.watch(vpnNotifierProvider);
    final user = ref.watch(userModelProvider).valueOrNull;
    final selectedServer = ref.watch(selectedServerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: Stack(
        children: [
          const _BackgroundDecor(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(user: user, vpnState: vpnState),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // ── Connect zone ──────────────────────────────
                        _ConnectZone(
                          vpnState: vpnState,
                          server: selectedServer,
                          onTap: () => ref
                              .read(vpnNotifierProvider.notifier)
                              .toggleConnection(selectedServer),
                        ).animate().fadeIn(duration: 500.ms),

                        const SizedBox(height: 28),

                        // ── Live stats (connected only) ──────────────
                        if (vpnState.isConnected)
                          _LiveStats(vpnState: vpnState)
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.1),

                        // ── Feature strip (disconnected) ─────────────
                        if (!vpnState.isConnected)
                          _FeatureStrip()
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 500.ms),

                        const SizedBox(height: 20),

                        // ── Server card ──────────────────────────────
                        _LuxuryServerCard(
                          server: selectedServer,
                          isConnected: vpnState.isConnected,
                        )
                            .animate()
                            .fadeIn(delay: 150.ms)
                            .slideY(begin: 0.06),

                        // ── IP & location card ───────────────────────
                        const SizedBox(height: 14),
                        _IpLocationCard(vpnState: vpnState, server: selectedServer)
                            .animate()
                            .fadeIn(delay: 300.ms)
                            .slideY(begin: 0.06),

                        // ── Upgrade banner (free users) ──────────────
                        if (user != null && !user.isPremium) ...[
                          const SizedBox(height: 14),
                          _UpgradeBanner()
                              .animate()
                              .fadeIn(delay: 350.ms),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Subtle background decor
// ─────────────────────────────────────────────────────────────────────────────
class _BackgroundDecor extends StatefulWidget {
  const _BackgroundDecor();

  @override
  State<_BackgroundDecor> createState() => _BackgroundDecorState();
}

class _BackgroundDecorState extends State<_BackgroundDecor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: size,
        painter: _DecorPainter(_ctrl.value),
      ),
    );
  }
}

class _DecorPainter extends CustomPainter {
  final double t;
  _DecorPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, size,
        Offset(size.width * 0.9 + 20 * math.sin(t * math.pi * 2),
            size.height * 0.08),
        size.width * 0.5, const Color(0xFF6366F1), 0.06);
    _draw(canvas, size,
        Offset(-size.width * 0.05,
            size.height * 0.72 + 15 * math.cos(t * math.pi * 2)),
        size.width * 0.4, const Color(0xFF6366F1), 0.04);
  }

  void _draw(Canvas canvas, Size size, Offset c, double r, Color color,
      double alpha) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          color.withValues(alpha: alpha),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_DecorPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends ConsumerWidget {
  final dynamic user;
  final VpnState vpnState;
  const _TopBar({this.user, required this.vpnState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          // Logo
          Image.asset(
            'assets/images/logo.png',
            height: 72,
            fit: BoxFit.contain,
          ),

          const Spacer(),

          // VIP / Upgrade
          if (user?.isPremium == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      color: Colors.white, size: 13),
                  SizedBox(width: 4),
                  Text('VIP',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => context.push('/vip'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_outline_rounded,
                        color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 5),
                    Text(
                        ref.watch(l10nProvider).langCode == 'en'
                            ? 'Upgrade VIP'
                            : 'Nâng VIP',
                        style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),

          const SizedBox(width: 10),

          // Avatar
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 19,
                backgroundColor: Color(0xFFEEF2FF),
                backgroundImage: AssetImage('assets/images/user.png'),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connect Zone — status + big button
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectZone extends ConsumerStatefulWidget {
  final VpnState vpnState;
  final dynamic server;
  final VoidCallback onTap;

  const _ConnectZone({
    required this.vpnState,
    required this.onTap,
    this.server,
  });

  @override
  ConsumerState<_ConnectZone> createState() => _ConnectZoneState();
}

class _ConnectZoneState extends ConsumerState<_ConnectZone>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _accent {
    switch (widget.vpnState.status) {
      case VpnStatus.connected:     return const Color(0xFF10B981);
      case VpnStatus.connecting:
      case VpnStatus.disconnecting: return const Color(0xFFF59E0B);
      case VpnStatus.error:         return const Color(0xFFEF4444);
      default:                      return const Color(0xFF6366F1);
    }
  }

  List<Color> get _btnGradient {
    switch (widget.vpnState.status) {
      case VpnStatus.connected:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case VpnStatus.connecting:
      case VpnStatus.disconnecting:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case VpnStatus.error:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      default:
        return [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
    }
  }

  String _statusText(s) {
    switch (widget.vpnState.status) {
      case VpnStatus.connected:     return s.statusConnected;
      case VpnStatus.connecting:    return s.statusConnecting;
      case VpnStatus.disconnecting: return '${s.disconnecting}...';
      case VpnStatus.error:         return s.error;
      default:                      return s.statusDisconnected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);
    return Column(
      children: [
        // Status pill
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.vpnState.isBusy)
                SizedBox(
                  width: 9,
                  height: 9,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: _accent),
                )
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accent,
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.6),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                _statusText(s),
                style: TextStyle(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.vpnState.isConnected &&
                  widget.server != null) ...[
                const SizedBox(width: 6),
                Text(widget.server.flag,
                    style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Big button
        GestureDetector(
          onTap: widget.vpnState.isBusy ? null : widget.onTap,
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated pulse rings (connected only)
                if (widget.vpnState.isConnected) ...[
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => _GlowRing(
                      size: 178 + _pulse.value * 38,
                      color: _accent,
                      alpha: (1 - _pulse.value) * 0.18,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) {
                      final t2 = (_pulse.value + 0.5) % 1.0;
                      return _GlowRing(
                        size: 178 + t2 * 38,
                        color: _accent,
                        alpha: (1 - t2) * 0.10,
                      );
                    },
                  ),
                ],

                // Outer shadow halo
                Container(
                  width: 195,
                  height: 195,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.18),
                        blurRadius: 50,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),

                // Inner ring
                Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accent.withValues(alpha: 0.06),
                    border: Border.all(
                      color: _accent.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                ),

                // Core button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _btnGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.5),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: widget.vpnState.isBusy
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.power_settings_new_rounded,
                              color: Colors.white,
                              size: 46,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.vpnState.isConnected
                                  ? s.disconnectButton.toUpperCase()
                                  : s.connectButton.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowRing extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;
  const _GlowRing({required this.size, required this.color, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: alpha),
          width: 2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Stats (connected)
// ─────────────────────────────────────────────────────────────────────────────
class _LiveStats extends ConsumerWidget {
  final VpnState vpnState;
  const _LiveStats({required this.vpnState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpnIpAsync = ref.watch(publicIpProvider);
    final vpnIp = vpnIpAsync.when(
      data: (info) => info?.ip ?? '—',
      loading: () => '...',
      error: (_, __) => '—',
    );

    return Column(
      children: [
        Row(
          children: [
            _MiniStatCard(
              icon: Icons.download_rounded,
              value: vpnState.downloadSpeedLabel,
              label: '↓ Download',
              accent: const Color(0xFF10B981),
            ),
            const SizedBox(width: 10),
            _MiniStatCard(
              icon: Icons.timer_outlined,
              value: vpnState.connectedTimeLabel,
              label: '⏱ Thời gian',
              accent: const Color(0xFF6366F1),
            ),
            const SizedBox(width: 10),
            _MiniStatCard(
              icon: Icons.upload_rounded,
              value: vpnState.uploadSpeedLabel,
              label: '↑ Upload',
              accent: const Color(0xFF0EA5E9),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // VPN IP bar — hiện IP VPN đang kết nối
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.language_rounded, color: Color(0xFF6366F1), size: 16),
              const SizedBox(width: 8),
              const Text('IP', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vpnIp,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Ẩn danh',
                    style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 15),
            ),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 9.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature Strip (disconnected)
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FeatItem(icon: Icons.lock_rounded,     label: 'AES-256',    color: Color(0xFF6366F1)),
          _Dot(),
          _FeatItem(icon: Icons.dns_rounded,       label: 'No Logs',   color: Color(0xFF10B981)),
          _Dot(),
          _FeatItem(icon: Icons.bolt_rounded,      label: 'High Speed', color: Color(0xFF0EA5E9)),
          _Dot(),
          _FeatItem(icon: Icons.security_rounded,  label: 'Kill Switch', color: Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}

class _FeatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeatItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: const Color(0xFFE5E7EB));
}

// ─────────────────────────────────────────────────────────────────────────────
// Luxury Server Card
// ─────────────────────────────────────────────────────────────────────────────
class _LuxuryServerCard extends ConsumerWidget {
  final dynamic server;
  final bool isConnected;
  const _LuxuryServerCard({this.server, required this.isConnected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    return GestureDetector(
      onTap: () => context.push('/servers'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flag bubble
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      server?.flag ?? '🌍',
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                  if (isConnected)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          server?.name ?? s.noServerSelected,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (server?.isVip == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('VIP',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (server != null)
                    Row(
                      children: [
                        _PingDot(ping: server.ping),
                        const SizedBox(width: 4),
                        Text(
                          '${server.ping} ms',
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (server.load / 100).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: server.load < 50
                                    ? const Color(0xFF10B981)
                                    : server.load < 80
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${server.load}%',
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 11),
                        ),
                      ],
                    )
                  else
                    Text(
                      s.selectServerHint,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                ],
              ),
            ),

            // Arrow
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF6366F1), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _PingDot extends StatelessWidget {
  final int ping;
  const _PingDot({required this.ping});

  Color get _color {
    if (ping < 50) return const Color(0xFF10B981);
    if (ping < 150) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) =>
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _color));
}

// ─────────────────────────────────────────────────────────────────────────────
// IP & Location Card
// ─────────────────────────────────────────────────────────────────────────────
class _IpLocationCard extends ConsumerWidget {
  final VpnState vpnState;
  final dynamic server;
  const _IpLocationCard({required this.vpnState, this.server});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    final bool connected = vpnState.isConnected;
    final ipAsync = ref.watch(realIpProvider);

    final String displayIp = ipAsync.when(
      data: (info) => info?.ip ?? '—',
      loading: () => '...',
      error: (_, __) => '—',
    );
    final String displayCountry = ipAsync.when(
      data: (info) => info != null ? '${info.city.isNotEmpty ? '${info.city}, ' : ''}${info.country}' : '',
      loading: () => '',
      error: (_, __) => '',
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (connected
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444))
                  .withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              connected ? Icons.location_on_rounded : Icons.location_off_rounded,
              color: connected
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.langCode == 'vi' ? 'IP & Vị trí' : 'IP & Location',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayIp,
                  style: TextStyle(
                    color: connected
                        ? const Color(0xFF111827)
                        : const Color(0xFFEF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (displayCountry.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    displayCountry,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Always show real IP flag + country
          ipAsync.when(
            data: (info) {
              final cc = info?.countryCode ?? '';
              final flag = cc.length == 2
                  ? String.fromCharCodes(cc.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 65))
                  : '🌍';
              final country = info?.country ?? '';
              return Row(children: [
                Text(flag, style: const TextStyle(fontSize: 22)),
                if (country.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(country,
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ]);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (!connected) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.langCode == 'vi' ? 'Rủi ro' : 'At Risk',
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Upgrade Banner
// ─────────────────────────────────────────────────────────────────────────────
class _UpgradeBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    return GestureDetector(
      onTap: () => context.push('/vip'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.upgradeVipBanner,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.viewButton,
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
