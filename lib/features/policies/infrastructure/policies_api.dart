import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../domain/policy.dart';
import '../domain/policy_response.dart';

class PoliciesApi {
  final ApiClient _client;

  PoliciesApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Get available policy types
  /// GET /policies/types
  Future<List<PolicyType>> getPolicyTypes() async {
    try {
      debugPrint('🔍 PoliciesApi: Getting policy types...');

      final response = await _client.get('/policies/types');

      debugPrint('✅ PoliciesApi: Policy types response: ${response.data}');

      if (response.data != null) {
        final result = PolicyTypesResponse.fromJson(response.data as Map<String, dynamic>);
        if (result.success) {
          return result.data;
        } else {
          debugPrint('❌ PoliciesApi: Policy types API returned success=false');
          // Fallback to default types if API fails
          return PolicyType.allTypes;
        }
      } else {
        debugPrint('❌ PoliciesApi: Policy types response data is null');
        // Fallback to default types
        return PolicyType.allTypes;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ PoliciesApi: Error getting policy types: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return default types as fallback
      return PolicyType.allTypes;
    }
  }

  /// Get available policy languages
  /// GET /policies/languages
  Future<List<PolicyLanguage>> getPolicyLanguages() async {
    try {
      debugPrint('🔍 PoliciesApi: Getting policy languages...');

      final response = await _client.get('/policies/languages');

      debugPrint('✅ PoliciesApi: Policy languages response: ${response.data}');

      if (response.data != null) {
        final result = PolicyLanguagesResponse.fromJson(response.data as Map<String, dynamic>);
        if (result.success) {
          return result.data;
        } else {
          debugPrint('❌ PoliciesApi: Policy languages API returned success=false');
          // Fallback to default languages if API fails
          return PolicyLanguage.allLanguages;
        }
      } else {
        debugPrint('❌ PoliciesApi: Policy languages response data is null');
        // Fallback to default languages
        return PolicyLanguage.allLanguages;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ PoliciesApi: Error getting policy languages: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return default languages as fallback
      return PolicyLanguage.allLanguages;
    }
  }

  /// Get policy by type
  /// GET /policies/{type}
  /// Headers: Accept-Language: {locale} or query param ?locale={locale}
  Future<Policy> getPolicy({
    required String type,
    String? locale,
  }) async {
    try {
      debugPrint('🔍 PoliciesApi: Getting policy - type: $type, locale: $locale');

      // Build query parameters
      Map<String, dynamic>? queryParameters;
      if (locale != null && locale.isNotEmpty) {
        queryParameters = {'locale': locale};
      }

      final response = await _client.get(
        '/policies/$type',
        queryParameters: queryParameters,
      );

      debugPrint('✅ PoliciesApi: Policy response: ${response.data}');

      if (response.data != null) {
        final result = PolicyResponse.fromJson(response.data as Map<String, dynamic>);
        if (result.hasData) {
          return result.data!;
        } else {
          debugPrint('❌ PoliciesApi: Policy API returned no data or success=false');
          throw PoliciesApiException(result.errorMessage);
        }
      } else {
        debugPrint('❌ PoliciesApi: Policy response data is null');
        throw PoliciesApiException('Policy not available');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ PoliciesApi: Error getting policy: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is PoliciesApiException) {
        rethrow;
      } else {
        throw PoliciesApiException('Failed to load policy');
      }
    }
  }

  /// Get privacy policy (convenience method)
  Future<Policy> getPrivacyPolicy({String? locale}) async {
    return getPolicy(type: 'privacy', locale: locale);
  }

  /// Get terms of service (convenience method)
  Future<Policy> getTermsOfService({String? locale}) async {
    return getPolicy(type: 'terms', locale: locale);
  }

  /// Get data processing policy (convenience method)
  Future<Policy> getDataProcessingPolicy({String? locale}) async {
    return getPolicy(type: 'data_processing', locale: locale);
  }

  /// Get cookies policy (convenience method)
  Future<Policy> getCookiesPolicy({String? locale}) async {
    return getPolicy(type: 'cookies', locale: locale);
  }
}

class PoliciesApiException implements Exception {
  final String message;

  const PoliciesApiException(this.message);

  @override
  String toString() => 'PoliciesApiException: $message';
}