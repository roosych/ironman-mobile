class UserPhoto {
  final int id;
  final String url;
  final String filename;
  final bool isAvatar;
  final bool isApproved;
  final DateTime? createdAt;

  const UserPhoto({
    required this.id,
    required this.url,
    required this.filename,
    required this.isAvatar,
    required this.isApproved,
    this.createdAt,
  });

  factory UserPhoto.fromJson(Map<String, dynamic> json) {
    return UserPhoto(
      id: json['id'] as int,
      url: json['url'] as String,
      filename: json['filename'] as String? ?? '',
      isAvatar: json['is_avatar'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? true,
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
      'is_approved': isApproved,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserPhoto copyWith({
    int? id,
    String? url,
    String? filename,
    bool? isAvatar,
    bool? isApproved,
    DateTime? createdAt,
  }) {
    return UserPhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      filename: filename ?? this.filename,
      isAvatar: isAvatar ?? this.isAvatar,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
