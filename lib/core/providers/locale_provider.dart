import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'app_locale';

/// Riverpod provider for the current app locale.
/// Persists the selection to SharedPreferences.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ar', 'AE');

  /// Call this once at app startup to restore the saved locale.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null) {
      state = code == 'en' ? const Locale('en', 'US') : const Locale('ar', 'AE');
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> toggleLocale() async {
    final newLocale = state.languageCode == 'ar'
        ? const Locale('en', 'US')
        : const Locale('ar', 'AE');
    await setLocale(newLocale);
  }

  bool get isArabic => state.languageCode == 'ar';
  bool get isEnglish => state.languageCode == 'en';
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
