/// Модель фотографии
class Photo {
  final int id;
  final String url;
  final String filename;
  final bool isAvatar;
  final DateTime? createdAt;

  const Photo({
    required this.id,
    required this.url,
    required this.filename,
    this.isAvatar = false,
    this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as int,
      url: json['url'] as String,
      filename: json['filename'] as String? ?? '',
      isAvatar: json['is_avatar'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'is_avatar': isAvatar,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

