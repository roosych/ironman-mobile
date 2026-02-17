import 'package:flutter/foundation.dart';
import 'policy.dart';

@immutable
class PolicyResponse {
  final bool success;
  final Policy? data;
  final String? message;
  final String? error;

  const PolicyResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory PolicyResponse.fromJson(Map<String, dynamic> json) {
    return PolicyResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? Policy.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }

  bool get hasData => success && data != null;
  bool get hasError => !success || error != null;
  String get errorMessage => error ?? message ?? 'Политика недоступна';

  @override
  String toString() {
    return 'PolicyResponse(success: $success, data: $data, error: $error)';
  }
}

@immutable
class PolicyTypesResponse {
  final bool success;
  final List<PolicyType> data;
  final String? message;
  final String? error;

  const PolicyTypesResponse({
    required this.success,
    required this.data,
    this.message,
    this.error,
  });

  factory PolicyTypesResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] as List<dynamic>? ?? [];
    return PolicyTypesResponse(
      success: json['success'] as bool? ?? false,
      data: dataList.map((item) => PolicyType.fromJson(item as Map<String, dynamic>)).toList(),
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }
}

@immutable
class PolicyLanguagesResponse {
  final bool success;
  final List<PolicyLanguage> data;
  final String? message;
  final String? error;

  const PolicyLanguagesResponse({
    required this.success,
    required this.data,
    this.message,
    this.error,
  });

  factory PolicyLanguagesResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] as List<dynamic>? ?? [];
    return PolicyLanguagesResponse(
      success: json['success'] as bool? ?? false,
      data: dataList.map((item) => PolicyLanguage.fromJson(item as Map<String, dynamic>)).toList(),
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }
}