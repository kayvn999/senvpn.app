import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/l10n/app_strings.dart';
import '../core/l10n/vi_strings.dart';
import '../core/l10n/en_strings.dart';

const _kLangKey = 'app_language';

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier([super.initial = 'vi']);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLangKey);
    if (saved != null && (saved == 'vi' || saved == 'en')) {
      state = saved;
    }
  }

  Future<void> setLanguage(String lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, lang);
  }

  static Future<String?> getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLangKey);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

final l10nProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(localeProvider);
  return lang == 'en' ? const EnStrings() : const ViStrings();
});

final materialLocaleProvider = Provider<Locale>((ref) {
  final lang = ref.watch(localeProvider);
  return Locale(lang);
});
