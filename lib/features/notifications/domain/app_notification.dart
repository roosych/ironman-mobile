class AppNotification {
  final int id;
  final String title;
  final String body;
  final DateTime? createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? translations;
  final String? type;
  final Map<String, dynamic>? data;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.createdAt,
    this.readAt,
    this.translations,
    this.type,
    this.data,
    this.isRead = false,
  });

  /// Получить локализованный заголовок
  String getLocalizedTitle(String localeCode) {
    if (translations == null) return title;
    
    final localeTranslations = translations![localeCode];
    if (localeTranslations is Map<String, dynamic>) {
      return (localeTranslations['title'] ?? title).toString();
    }
    
    // Fallback на английский, если запрошенной локали нет
    if (localeCode != 'en') {
      final enTranslations = translations!['en'];
      if (enTranslations is Map<String, dynamic>) {
        return (enTranslations['title'] ?? title).toString();
      }
    }
    
    return title;
  }

  /// Получить локализованный текст
  String getLocalizedBody(String localeCode) {
    if (translations == null) return body;
    
    final localeTranslations = translations![localeCode];
    if (localeTranslations is Map<String, dynamic>) {
      return (localeTranslations['body'] ?? body).toString();
    }
    
    // Fallback на английский, если запрошенной локали нет
    if (localeCode != 'en') {
      final enTranslations = translations!['en'];
      if (enTranslations is Map<String, dynamic>) {
        return (enTranslations['body'] ?? body).toString();
      }
    }
    
    return body;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt() ?? 0;
    
    // Парсим translations если есть
    final translations = json['translations'] as Map<String, dynamic>?;
    
    // Базовые title и body (fallback)
    final title = (json['title'] ?? json['subject'] ?? '').toString();
    final body = (json['body'] ?? json['message'] ?? '').toString();
    
    // Парсим type и data
    final type = json['type']?.toString();
    final data = json['data'] as Map<String, dynamic>?;
    
    // Парсим is_read (приоритет над read_at)
    final isRead = json['is_read'] == true;
    
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return AppNotification(
      id: id,
      title: title,
      body: body,
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      readAt: parseDate(json['read_at'] ?? json['readAt']),
      translations: translations,
      type: type,
      data: data,
      isRead: isRead,
    );
  }

  AppNotification copyWith({
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? translations,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    bool clearReadAt = false,
  }) {
    return AppNotification(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
      translations: translations ?? this.translations,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }
}


