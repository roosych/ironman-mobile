import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  static const String _localeKey = 'app_locale';
  static const List<String> _supportedLanguages = ['ru', 'en', 'az'];
  static const List<String> _backendSupportedLanguages = ['ru', 'en'];

  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }
  
  /// Get locale code for backend API (only ru or en)
  String getLocaleForApi() {
    final localeCode = state.languageCode;
    return _backendSupportedLanguages.contains(localeCode) ? localeCode : 'en';
  }
  
  /// Sync locale with user's locale from API
  /// This should be called when user logs in or when user data is refreshed
  Future<void> syncWithUserLocale(String? userLocale) async {
    if (userLocale == null) return;
    
    // Поддерживаем только ru и en для синхронизации с бэкендом
    if (!_backendSupportedLanguages.contains(userLocale)) {
      return;
    }
    
    // Если locale отличается от текущего, обновляем
    if (state.languageCode != userLocale) {
      await setLocale(Locale(userLocale));
    }
  }

  /// Load saved locale from SharedPreferences or use system locale
  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocaleCode = prefs.getString(_localeKey);

      if (savedLocaleCode != null && _supportedLanguages.contains(savedLocaleCode)) {
        state = Locale(savedLocaleCode);
        return;
      }

      // Use system locale if available, otherwise default to English
      final systemLocales = PlatformDispatcher.instance.locales;
      if (systemLocales.isNotEmpty) {
        final systemLanguageCode = systemLocales.first.languageCode;
        if (_supportedLanguages.contains(systemLanguageCode)) {
          state = Locale(systemLanguageCode);
          return;
        }
      }

      // Fallback to English
      state = const Locale('en');
    } catch (e) {
      // Fallback to English on error
      state = const Locale('en');
    }
  }

  /// Set locale and save to SharedPreferences
  Future<void> setLocale(Locale locale) async {
    if (!_supportedLanguages.contains(locale.languageCode)) {
      return; // Ignore unsupported locales
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
      state = locale;
    } catch (e) {
      // Handle error silently
    }
  }
}

