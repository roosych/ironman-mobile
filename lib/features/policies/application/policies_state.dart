import 'package:flutter/foundation.dart';
import '../domain/policy.dart';

@immutable
class PoliciesState {
  final Map<String, Map<String, Policy>> policies; // type -> locale -> policy
  final List<PolicyType> availableTypes;
  final List<PolicyLanguage> availableLanguages;
  final bool isLoading;
  final bool isLoadingTypes;
  final bool isLoadingLanguages;
  final String? error;
  final PolicyType? selectedType;
  final PolicyLanguage? selectedLanguage;

  const PoliciesState({
    this.policies = const {},
    this.availableTypes = const [],
    this.availableLanguages = const [],
    this.isLoading = false,
    this.isLoadingTypes = false,
    this.isLoadingLanguages = false,
    this.error,
    this.selectedType,
    this.selectedLanguage,
  });

  /// Get policy for the current selection
  Policy? get currentPolicy {
    if (selectedType == null || selectedLanguage == null) return null;
    return policies[selectedType!.value]?[selectedLanguage!.code];
  }

  /// Check if current policy is loading
  bool get isCurrentPolicyLoading {
    if (selectedType == null || selectedLanguage == null) return false;
    return isLoading && currentPolicy == null;
  }

  /// Check if we have the current policy cached
  bool get hasCurrentPolicy {
    return currentPolicy != null;
  }

  /// Get policy by type and language
  Policy? getPolicy(String type, String language) {
    return policies[type]?[language];
  }

  /// Check if we have a specific policy cached
  bool hasPolicy(String type, String language) {
    return policies[type]?[language] != null;
  }

  PoliciesState copyWith({
    Map<String, Map<String, Policy>>? policies,
    List<PolicyType>? availableTypes,
    List<PolicyLanguage>? availableLanguages,
    bool? isLoading,
    bool? isLoadingTypes,
    bool? isLoadingLanguages,
    String? error,
    bool clearError = false,
    PolicyType? selectedType,
    PolicyLanguage? selectedLanguage,
  }) {
    return PoliciesState(
      policies: policies ?? this.policies,
      availableTypes: availableTypes ?? this.availableTypes,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingTypes: isLoadingTypes ?? this.isLoadingTypes,
      isLoadingLanguages: isLoadingLanguages ?? this.isLoadingLanguages,
      error: clearError ? null : (error ?? this.error),
      selectedType: selectedType ?? this.selectedType,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
    );
  }

  @override
  String toString() {
    return 'PoliciesState('
        'policies: ${policies.keys}, '
        'availableTypes: ${availableTypes.length}, '
        'availableLanguages: ${availableLanguages.length}, '
        'isLoading: $isLoading, '
        'error: $error, '
        'selectedType: ${selectedType?.value}, '
        'selectedLanguage: ${selectedLanguage?.code}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PoliciesState &&
        mapEquals(other.policies, policies) &&
        listEquals(other.availableTypes, availableTypes) &&
        listEquals(other.availableLanguages, availableLanguages) &&
        other.isLoading == isLoading &&
        other.isLoadingTypes == isLoadingTypes &&
        other.isLoadingLanguages == isLoadingLanguages &&
        other.error == error &&
        other.selectedType == selectedType &&
        other.selectedLanguage == selectedLanguage;
  }

  @override
  int get hashCode {
    return Object.hash(
      policies,
      availableTypes,
      availableLanguages,
      isLoading,
      isLoadingTypes,
      isLoadingLanguages,
      error,
      selectedType,
      selectedLanguage,
    );
  }
}