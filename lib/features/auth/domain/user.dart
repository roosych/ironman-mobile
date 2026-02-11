import 'package:flutter/foundation.dart';
import 'profile.dart';

class User {
  final int id;
  final String name;
  final String email;
  final bool verified;
  final Profile? profile;
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
    final profileData = json['profile'];
    Profile? profile;

    // DEBUG: Log profile data parsing
    try {
      debugPrint('=== User.fromJson: Profile Data Debug ===');
      debugPrint('Profile data type: ${profileData.runtimeType}');
      if (profileData is Map<String, dynamic>) {
        debugPrint('Profile data keys: ${profileData.keys}');
        debugPrint('Profile id: ${profileData['id']}');
        debugPrint('Profile role: ${profileData['role']}');
      }
    } catch (e) {
      debugPrint('User debug logging error (safe to ignore): $e');
    }

    // Parse profile if present and valid
    if (profileData is Map<String, dynamic>) {
      try {
        profile = Profile.fromJson(profileData);
        debugPrint('Profile parsed successfully: id=${profile.id}, role=${profile.role}');
      } catch (e) {
        // If profile parsing fails, set to null to maintain backwards compatibility
        debugPrint('Profile parsing FAILED: $e');
        profile = null;
      }
    } else {
      debugPrint('Profile data is not Map<String, dynamic> or is null');
    }

    debugPrint('Final profile: $profile');
    debugPrint('===========================================');

    // Extract avatarUrl from multiple possible sources
    String? avatarUrl = json['avatarUrl'] as String?; // From stored user data

    if (avatarUrl == null && profileData is Map<String, dynamic>) {
      // Try different possible paths in API response
      avatarUrl = profileData['avatar_url'] as String?;
      avatarUrl ??= profileData['avatarUrl'] as String?;

      // Check if avatar is an object with url
      final avatar = profileData['avatar'];
      if (avatarUrl == null && avatar is Map<String, dynamic>) {
        avatarUrl = avatar['url'] as String?;
      }

      // Check avatar_photo object
      final avatarPhoto = profileData['avatar_photo'];
      if (avatarUrl == null && avatarPhoto is Map<String, dynamic>) {
        avatarUrl = avatarPhoto['url'] as String?;
      }

      // Check photos array for avatar
      final photos = profileData['photos'];
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
      'profile': profile?.toJson(),
      'avatarUrl': avatarUrl,
      'locale': locale,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    bool? verified,
    Profile? profile,
    String? avatarUrl,
    String? locale,
    bool clearProfile = false,
    bool clearAvatarUrl = false,
    bool clearLocale = false,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      verified: verified ?? this.verified,
      profile: clearProfile ? null : (profile ?? this.profile),
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }
}
