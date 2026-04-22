import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/locale_provider.dart';

class _OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsFirstLaunch, false);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);

    final pages = [
      _OnboardingPage(
        title: s.ob1Title,
        subtitle: s.ob1Sub,
        icon: Icons.shield_rounded,
        gradient: const [Color(0xFF6C63FF), Color(0xFF3D35C8)],
      ),
      _OnboardingPage(
        title: s.ob2Title,
        subtitle: s.ob2Sub,
        icon: Icons.bolt_rounded,
        gradient: const [Color(0xFF00BCD4), Color(0xFF0097A7)],
      ),
      _OnboardingPage(
        title: s.ob3Title,
        subtitle: s.ob3Sub,
        icon: Icons.public_rounded,
        gradient: const [Color(0xFF4CAF50), Color(0xFF388E3C)],
      ),
      _OnboardingPage(
        title: s.ob4Title,
        subtitle: s.ob4Sub,
        icon: Icons.rocket_launch_rounded,
        gradient: const [Color(0xFFFF6B35), Color(0xFFE64A19)],
      ),
    ];

    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenHeight < 700;
    final iconSize = isSmall ? 110.0 : 140.0;
    final iconInnerSize = isSmall ? 55.0 : 70.0;
    final spacerLarge = isSmall ? 28.0 : 48.0;
    final spacerMedium = isSmall ? 14.0 : 20.0;
    final bottomPadding = isSmall ? 20.0 : 32.0;
    final dotButtonGap = isSmall ? 20.0 : 32.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _complete,
                    child: Text(
                      s.skip,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon
                          Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: page.gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: page.gradient.first.withValues(alpha: 0.4),
                                  blurRadius: 50,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(page.icon, size: iconInnerSize, color: Colors.white),
                          )
                              .animate(key: ValueKey('icon_$index'))
                              .scale(
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1, 1),
                                duration: 500.ms,
                                curve: Curves.elasticOut,
                              ),

                          SizedBox(height: spacerLarge),

                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF1A1A2E),
                              fontSize: isSmall ? 28 : 32,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          )
                              .animate(key: ValueKey('title_$index'))
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.2, end: 0),

                          SizedBox(height: spacerMedium),

                          Text(
                            page.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF6B7280),
                              fontSize: isSmall ? 14 : 16,
                              fontWeight: FontWeight.w400,
                              height: 1.6,
                            ),
                          )
                              .animate(key: ValueKey('sub_$index'))
                              .fadeIn(delay: 150.ms, duration: 400.ms),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Dots and button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: bottomPadding),
                child: Column(
                  children: [
                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? AppColors.primary
                                : AppColors.textMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: dotButtonGap),

                    // Next / Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < pages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _complete();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _currentPage < pages.length - 1 ? s.next : s.getStarted,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
