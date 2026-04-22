import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/services/revenuecat_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_config_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/iap_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/user_provider.dart';

class VipScreen extends ConsumerStatefulWidget {
  const VipScreen({super.key});

  @override
  ConsumerState<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends ConsumerState<VipScreen> {
  int _selectedPlanIndex = 0;
  bool _isLoading = false;

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.disconnected : AppColors.connected,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _purchase(VipPlanModel plan) async {
    setState(() => _isLoading = true);
    try {
      final planMap = await ref.read(rcPlanMapProvider.future);
      final pkg = planMap[plan.id];

      if (pkg == null) {
        _showSnack('Thanh toán chưa sẵn sàng. Vui lòng thử lại sau.', error: true);
        return;
      }

      final info = await RevenueCatService().purchase(pkg);
      if (info == null) return; // user cancelled

      _showSnack('Mua ${plan.name} thành công! VIP đang được kích hoạt...');
      // VPS receives RC webhook → updates Firestore → 30s polling picks up new status
    } on PlatformException catch (e) {
      _showSnack('Lỗi: ${e.message ?? 'Không thể hoàn tất giao dịch.'}', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userModelProvider).valueOrNull;
    final isVip = user?.isPremium ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 280,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD), Color(0xFFFFFBF0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFAB00).withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                Expanded(
                  child: isVip
                      ? _VipActiveView(user: user!)
                      : _VipPurchaseView(
                          selectedPlanIndex: _selectedPlanIndex,
                          isLoading: _isLoading,
                          onSelectPlan: (i) => setState(() => _selectedPlanIndex = i),
                          onPurchase: _purchase,
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

// ─── VIP Active View ──────────────────────────────────────────────────────────

class _VipActiveView extends ConsumerWidget {
  final UserModel user;
  const _VipActiveView({required this.user});

  List<({IconData icon, String label, Color color})> _features(s) => [
    (icon: Icons.public_rounded,        label: s.feat50Servers,   color: const Color(0xFF6C63FF)),
    (icon: Icons.all_inclusive_rounded, label: s.featUnlimited,   color: const Color(0xFF00BF5F)),
    (icon: Icons.bolt_rounded,          label: s.featHighSpeed,   color: const Color(0xFFFFAB00)),
    (icon: Icons.security_rounded,      label: s.featKillSwitch,  color: const Color(0xFFFF6B35)),
    (icon: Icons.block_rounded,         label: s.featAdBlock,     color: const Color(0xFF00AAFF)),
  ];

  String _formatExpiry(String unlimited) {
    if (user.premiumExpiry == null) return unlimited;
    return DateFormat('dd/MM/yyyy').format(user.premiumExpiry!);
  }

  int _daysLeft() {
    if (user.premiumExpiry == null) return -1;
    return user.premiumExpiry!.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    final days = _daysLeft();
    final expiry = _formatExpiry(s.unlimited);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Hero badge
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFAB00).withValues(alpha: 0.12),
                      ),
                    ),
                    Container(
                      width: 84, height: 84,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFD740), Color(0xFFFF8F00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: Color(0x40FFB300), blurRadius: 24, offset: Offset(0, 8)),
                        ],
                      ),
                      child: const Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 44),
                    ),
                  ],
                )
                    .animate()
                    .scale(begin: const Offset(0.6, 0.6), duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: 12),
                Text(
                  s.vipActiveTitle,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 4),
                Text(
                  s.vipActiveSubtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Expiry card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD740), Color(0xFFFF8F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x30FFB300), blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.vipPlanActive,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s.vipExpiry} $expiry',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (days >= 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            s.langCode == 'vi' ? 'Còn $days ${s.vipDaysLeft}' : '$days ${s.vipDaysLeft} left',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_rounded, color: Colors.white, size: 40),
                ],
              ),
            ),
          ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1, end: 0),

          const SizedBox(height: 20),

          // Features
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                s.yourFeatures,
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.8,
              ),
              itemCount: _features(s).length,
              itemBuilder: (_, i) {
                final f = _features(s)[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: f.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: f.color.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(f.icon, color: f.color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f.label,
                          style: const TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      Icon(Icons.check_circle_rounded, color: f.color, size: 14),
                    ],
                  ),
                );
              },
            ),
          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.08, end: 0),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ─── VIP Purchase View ────────────────────────────────────────────────────────

class _VipPurchaseView extends ConsumerWidget {
  final int selectedPlanIndex;
  final bool isLoading;
  final ValueChanged<int> onSelectPlan;
  final Future<void> Function(VipPlanModel) onPurchase;

  const _VipPurchaseView({
    required this.selectedPlanIndex,
    required this.isLoading,
    required this.onSelectPlan,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(vipPlansProvider);
    final s = ref.watch(l10nProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFAB00).withValues(alpha: 0.12),
                      ),
                    ),
                    Container(
                      width: 84, height: 84,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFD740), Color(0xFFFF8F00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: Color(0x40FFB300), blurRadius: 24, offset: Offset(0, 8)),
                        ],
                      ),
                      child: const Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 44),
                    ),
                  ],
                ).animate().scale(begin: const Offset(0.6, 0.6), duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: 16),
                Text(
                  s.vipScreenTitle,
                  style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 5),
                const Text(
                  'Không giới hạn · Tốc độ cao · Bảo mật nâng cao',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _FeatureGrid(),
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08, end: 0),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  s.choosePlan,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
            ]),
          ),

          const SizedBox(height: 14),

          plansAsync.when(
            loading: () => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: List.generate(2, (i) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms)),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Không tải được gói VIP.', style: TextStyle(color: Color(0xFF9CA3AF))),
            ),
            data: (plans) => Column(
              children: List.generate(plans.length, (i) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _PlanCard(
                  plan: plans[i],
                  isSelected: selectedPlanIndex == i,
                  onTap: () => onSelectPlan(i),
                ),
              ).animate(delay: Duration(milliseconds: 300 + i * 80)).fadeIn().slideY(begin: 0.08, end: 0)),
            ),
          ),

          const SizedBox(height: 6),

          plansAsync.maybeWhen(
            data: (plans) => plans.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: isLoading
                        ? const SizedBox(
                            height: 56,
                            child: Center(child: CircularProgressIndicator(
                              color: Color(0xFFFFAB00), strokeWidth: 2.5)),
                          )
                        : GestureDetector(
                            onTap: () {
                              if (selectedPlanIndex < plans.length) {
                                onPurchase(plans[selectedPlanIndex]);
                              }
                            },
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD740), Color(0xFFFF8F00)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x40FFB300), blurRadius: 16, offset: Offset(0, 6)),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  selectedPlanIndex < plans.length
                                      ? '${s.purchaseButton} ${plans[selectedPlanIndex].name}  →'
                                      : s.choosePlan,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ).animate(delay: 500.ms).fadeIn(),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              children: [
                Text(
                  '${s.autoRenew}\n${s.termsPrivacy}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB0B8C4), fontSize: 11, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature Grid ─────────────────────────────────────────────────────────────

class _FeatureGrid extends ConsumerWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    final features = [
      (icon: Icons.public_rounded,        label: s.feat50Servers,   color: const Color(0xFF6C63FF)),
      (icon: Icons.all_inclusive_rounded, label: s.featUnlimited,   color: const Color(0xFF00BF5F)),
      (icon: Icons.bolt_rounded,          label: s.featHighSpeed,   color: const Color(0xFFFFAB00)),
      (icon: Icons.security_rounded,      label: s.featKillSwitch,  color: const Color(0xFFFF6B35)),
      (icon: Icons.block_rounded,         label: s.featAdBlock,     color: const Color(0xFF00AAFF)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.8,
      ),
      itemCount: features.length,
      itemBuilder: (_, i) {
        final f = features[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: f.color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: f.color.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(f.icon, color: f.color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  f.label,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Plan Card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final VipPlanModel plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFBF0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFAB00) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFFFAB00).withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFFFAB00) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFAB00) : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.name,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFF374151),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (plan.isPopular) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFFD740), Color(0xFFFF8F00)]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PHỔ BIẾN',
                            style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(plan.durationLabel, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                ],
              ),
            ),
            Text(
              plan.priceLabel,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF8F00) : const Color(0xFF1A1A2E),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
