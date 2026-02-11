/// Модель фотографии
class Photo {
  final int id;
  final String url;
  final String filename;
  final DateTime? createdAt;

  const Photo({
    required this.id,
    required this.url,
    required this.filename,
    this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as int,
      url: json['url'] as String,
      filename: json['filename'] as String? ?? '',
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
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

