import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/locale_provider.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String _selected = 'vi';

  @override
  Widget build(BuildContext context) {
    final languages = [
      (code: 'vi', label: 'Tiếng Việt', flag: '🇻🇳', sub: 'Vietnamese'),
      (code: 'en', label: 'English', flag: '🇺🇸', sub: 'Tiếng Anh'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // Icon
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3D35C8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                      blurRadius: 30, offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.language_rounded, color: Colors.white, size: 46),
              ).animate().scale(
                begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut,
              ),

              const SizedBox(height: 32),

              const Text(
                'Chọn ngôn ngữ\nChoose Language',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              const Text(
                'Bạn có thể thay đổi sau trong Cài đặt\nYou can change this later in Settings',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.6),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 40),

              // Language options
              ...languages.asMap().entries.map((entry) {
                final lang = entry.value;
                final isSelected = _selected == lang.code;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = lang.code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1.5,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                            blurRadius: 12, offset: const Offset(0, 4),
                          ),
                        ] : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8, offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(lang.flag, style: const TextStyle(fontSize: 32)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.label,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                Text(
                                  lang.sub,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: 350 + entry.key * 80)).fadeIn().slideY(begin: 0.1, end: 0),
                );
              }),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(localeProvider.notifier).setLanguage(_selected);
                    if (!context.mounted) return;
                    context.go('/onboarding');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Tiếp tục  /  Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
