import 'package:flutter/foundation.dart';

@immutable
class Policy {
  final int id;
  final String type;
  final String typeName;
  final String language;
  final String title;
  final String content;
  final bool isActive;
  final DateTime effectiveDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Policy({
    required this.id,
    required this.type,
    required this.typeName,
    required this.language,
    required this.title,
    required this.content,
    required this.isActive,
    required this.effectiveDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['id'] as int,
      type: json['type'] as String,
      typeName: json['type_name'] as String,
      language: json['language'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      isActive: json['is_active'] as bool,
      effectiveDate: DateTime.parse(json['effective_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'type_name': typeName,
      'language': language,
      'title': title,
      'content': content,
      'is_active': isActive,
      'effective_date': effectiveDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Policy(id: $id, type: $type, language: $language, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Policy &&
        other.id == id &&
        other.type == type &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hash(id, type, language);
}

@immutable
class PolicyType {
  final String value;
  final String name;

  const PolicyType({
    required this.value,
    required this.name,
  });

  factory PolicyType.fromJson(Map<String, dynamic> json) {
    return PolicyType(
      value: json['value'] as String,
      name: json['name'] as String,
    );
  }

  // Common policy types based on API specification
  static const privacy = PolicyType(value: 'privacy', name: 'Privacy Policy');
  static const terms = PolicyType(value: 'terms', name: 'Terms of Service');
  static const dataProcessing = PolicyType(value: 'data_processing', name: 'Data Processing');
  static const cookies = PolicyType(value: 'cookies', name: 'Cookie Policy');

  static const allTypes = [privacy, terms/*, dataProcessing, cookies*/];

  @override
  String toString() => 'PolicyType(value: $value, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PolicyType && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

@immutable
class PolicyLanguage {
  final String code;
  final String name;

  const PolicyLanguage({
    required this.code,
    required this.name,
  });

  factory PolicyLanguage.fromJson(Map<String, dynamic> json) {
    return PolicyLanguage(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  // Supported languages based on API specification
  static const english = PolicyLanguage(code: 'en', name: 'English');
  static const russian = PolicyLanguage(code: 'ru', name: 'Русский');
  static const azerbaijani = PolicyLanguage(code: 'az', name: 'Azərbaycan');

  static const allLanguages = [english, russian, azerbaijani];

  @override
  String toString() => 'PolicyLanguage(code: $code, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PolicyLanguage && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}