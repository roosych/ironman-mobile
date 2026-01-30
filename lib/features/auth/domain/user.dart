class User {
  final int id;
  final String name;
  final String email;
  final bool verified;
  final dynamic profile;
  final String? avatarUrl;
  final String? locale;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.verified,
    this.profile,
    this.avatarUrl,
    this.locale,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];

    // Extract avatarUrl from multiple possible sources
    String? avatarUrl = json['avatarUrl'] as String?; // From stored user data

    if (avatarUrl == null && profile is Map<String, dynamic>) {
      // Try different possible paths in API response
      avatarUrl = profile['avatar_url'] as String?;
      avatarUrl ??= profile['avatarUrl'] as String?;

      // Check if avatar is an object with url
      final avatar = profile['avatar'];
      if (avatarUrl == null && avatar is Map<String, dynamic>) {
        avatarUrl = avatar['url'] as String?;
      }

      // Check avatar_photo object
      final avatarPhoto = profile['avatar_photo'];
      if (avatarUrl == null && avatarPhoto is Map<String, dynamic>) {
        avatarUrl = avatarPhoto['url'] as String?;
      }

      // Check photos array for avatar
      final photos = profile['photos'];
      if (avatarUrl == null && photos is List) {
        for (final photo in photos) {
          if (photo is Map<String, dynamic> && photo['is_avatar'] == true) {
            avatarUrl = photo['url'] as String?;
            break;
          }
        }
      }
    }

    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      verified: json['verified'] as bool? ?? false,
      profile: profile,
      avatarUrl: avatarUrl,
      locale: json['locale'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'verified': verified,
      'profile': profile,
      'avatarUrl': avatarUrl,
      'locale': locale,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    bool? verified,
    dynamic profile,
    String? avatarUrl,
    String? locale,
    bool clearAvatarUrl = false,
    bool clearLocale = false,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      verified: verified ?? this.verified,
      profile: profile ?? this.profile,
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }
}
