import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/policy.dart';
import '../infrastructure/policies_api.dart';
import 'policies_state.dart';
import '../../settings/application/locale_notifier.dart';

final policiesProvider = StateNotifierProvider<PoliciesNotifier, PoliciesState>((ref) {
  return PoliciesNotifier(ref: ref);
});

class PoliciesNotifier extends StateNotifier<PoliciesState> {
  final PoliciesApi _api;
  final Ref? _ref;

  PoliciesNotifier({PoliciesApi? api, Ref? ref})
      : _api = api ?? PoliciesApi(),
        _ref = ref,
        super(const PoliciesState());

  /// Initialize with default selections based on current app locale
  Future<void> initialize() async {
    debugPrint('🔧 PoliciesNotifier: Initializing...');

    // Get current app locale
    final currentLocale = _ref?.read(localeProvider.notifier).getLocaleForApi() ?? 'en';
    debugPrint('🌍 PoliciesNotifier: Current locale: $currentLocale');

    // Set default selections
    final defaultLanguage = _getLanguageByCode(currentLocale) ?? PolicyLanguage.english;
    final defaultType = PolicyType.privacy; // Default to privacy policy

    state = state.copyWith(
      selectedType: defaultType,
      selectedLanguage: defaultLanguage,
      availableTypes: PolicyType.allTypes,
      availableLanguages: PolicyLanguage.allLanguages,
    );

    // Load the default policy
    await loadCurrentPolicy();
  }

  /// Load policy types from API
  Future<void> loadPolicyTypes() async {
    if (state.isLoadingTypes) return;

    debugPrint('🔍 PoliciesNotifier: Loading policy types...');

    state = state.copyWith(
      isLoadingTypes: true,
      clearError: true,
    );

    try {
      final types = await _api.getPolicyTypes();
      debugPrint('✅ PoliciesNotifier: Loaded ${types.length} policy types');

      state = state.copyWith(
        availableTypes: types,
        isLoadingTypes: false,
      );
    } catch (e) {
      debugPrint('❌ PoliciesNotifier: Error loading policy types: $e');

      // Keep default types on error
      state = state.copyWith(
        availableTypes: PolicyType.allTypes,
        isLoadingTypes: false,
        error: 'Не удалось загрузить типы политик',
      );
    }
  }

  /// Load policy languages from API
  Future<void> loadPolicyLanguages() async {
    if (state.isLoadingLanguages) return;

    debugPrint('🔍 PoliciesNotifier: Loading policy languages...');

    state = state.copyWith(
      isLoadingLanguages: true,
      clearError: true,
    );

    try {
      final languages = await _api.getPolicyLanguages();
      debugPrint('✅ PoliciesNotifier: Loaded ${languages.length} policy languages');

      state = state.copyWith(
        availableLanguages: languages,
        isLoadingLanguages: false,
      );
    } catch (e) {
      debugPrint('❌ PoliciesNotifier: Error loading policy languages: $e');

      // Keep default languages on error
      state = state.copyWith(
        availableLanguages: PolicyLanguage.allLanguages,
        isLoadingLanguages: false,
        error: 'Не удалось загрузить доступные языки',
      );
    }
  }

  /// Select policy type
  void selectType(PolicyType type) {
    debugPrint('📋 PoliciesNotifier: Selecting type: ${type.value}');

    state = state.copyWith(
      selectedType: type,
      clearError: true,
    );

    // Load the policy for the new selection
    loadCurrentPolicy();
  }

  /// Select policy language
  void selectLanguage(PolicyLanguage language) {
    debugPrint('🌍 PoliciesNotifier: Selecting language: ${language.code}');

    state = state.copyWith(
      selectedLanguage: language,
      clearError: true,
    );

    // Load the policy for the new selection
    loadCurrentPolicy();
  }

  /// Load policy for current selection
  Future<void> loadCurrentPolicy() async {
    final selectedType = state.selectedType;
    final selectedLanguage = state.selectedLanguage;

    if (selectedType == null || selectedLanguage == null) {
      debugPrint('⚠️ PoliciesNotifier: Cannot load policy - no type or language selected');
      return;
    }

    await loadPolicy(selectedType.value, selectedLanguage.code);
  }

  /// Load specific policy by type and language
  Future<void> loadPolicy(String type, String languageCode) async {
    // Check if already cached
    if (state.hasPolicy(type, languageCode)) {
      debugPrint('📦 PoliciesNotifier: Policy already cached for $type/$languageCode');
      return;
    }

    // Prevent loading the same policy multiple times
    if (state.isLoading) {
      debugPrint('⏳ PoliciesNotifier: Already loading a policy...');
      return;
    }

    debugPrint('🔄 PoliciesNotifier: Loading policy $type/$languageCode...');

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final policy = await _api.getPolicy(
        type: type,
        locale: languageCode,
      );

      debugPrint('✅ PoliciesNotifier: Policy loaded successfully: ${policy.title}');

      // Update the policies cache
      final updatedPolicies = Map<String, Map<String, Policy>>.from(state.policies);
      if (!updatedPolicies.containsKey(type)) {
        updatedPolicies[type] = <String, Policy>{};
      }
      updatedPolicies[type]![languageCode] = policy;

      state = state.copyWith(
        policies: updatedPolicies,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('❌ PoliciesNotifier: Error loading policy: $e');

      // Try fallback to English if the requested language is not available
      if (languageCode != 'en') {
        debugPrint('🔄 PoliciesNotifier: Trying fallback to English...');

        try {
          final fallbackPolicy = await _api.getPolicy(
            type: type,
            locale: 'en',
          );

          debugPrint('✅ PoliciesNotifier: Fallback policy loaded successfully: ${fallbackPolicy.title}');

          // Update the policies cache with fallback policy
          final updatedPolicies = Map<String, Map<String, Policy>>.from(state.policies);
          if (!updatedPolicies.containsKey(type)) {
            updatedPolicies[type] = <String, Policy>{};
          }
          // Store fallback policy under the requested language code
          updatedPolicies[type]![languageCode] = fallbackPolicy;

          state = state.copyWith(
            policies: updatedPolicies,
            isLoading: false,
          );

          return; // Success with fallback
        } catch (fallbackError) {
          debugPrint('❌ PoliciesNotifier: Fallback to English also failed: $fallbackError');
        }
      }

      // Both original and fallback failed
      String errorMessage = 'Не удалось загрузить политику';
      if (e is PoliciesApiException) {
        errorMessage = e.message;
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  /// Load privacy policy for current language
  Future<void> loadPrivacyPolicy() async {
    final language = state.selectedLanguage ?? PolicyLanguage.english;

    // Select privacy policy type
    state = state.copyWith(selectedType: PolicyType.privacy);

    await loadPolicy(PolicyType.privacy.value, language.code);
  }

  /// Refresh current policy (force reload)
  Future<void> refreshCurrentPolicy() async {
    final selectedType = state.selectedType;
    final selectedLanguage = state.selectedLanguage;

    if (selectedType == null || selectedLanguage == null) return;

    // Clear cached policy to force reload
    final updatedPolicies = Map<String, Map<String, Policy>>.from(state.policies);
    updatedPolicies[selectedType.value]?.remove(selectedLanguage.code);

    state = state.copyWith(policies: updatedPolicies);

    // Load fresh policy
    await loadPolicy(selectedType.value, selectedLanguage.code);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reset state
  void reset() {
    state = const PoliciesState();
  }

  /// Get policy language by code
  PolicyLanguage? _getLanguageByCode(String code) {
    try {
      return PolicyLanguage.allLanguages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Get localized type name
  String getLocalizedTypeName(PolicyType type, String locale) {
    // This could be expanded to support localized type names
    // For now, return the default name
    switch (type.value) {
      case 'privacy':
        switch (locale) {
          case 'ru':
            return 'Политика конфиденциальности';
          case 'az':
            return 'Məxfilik Siyasəti';
          default:
            return 'Privacy Policy';
        }
      case 'terms':
        switch (locale) {
          case 'ru':
            return 'Условия использования';
          case 'az':
            return 'İstifadə Şərtləri';
          default:
            return 'Terms of Service';
        }
      case 'data_processing':
        switch (locale) {
          case 'ru':
            return 'Обработка данных';
          case 'az':
            return 'Məlumatların emalı';
          default:
            return 'Data Processing';
        }
      case 'cookies':
        switch (locale) {
          case 'ru':
            return 'Политика файлов cookie';
          case 'az':
            return 'Cookie siyasəti';
          default:
            return 'Cookie Policy';
        }
      default:
        return type.name;
    }
  }
}