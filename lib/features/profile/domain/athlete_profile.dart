/// Social links for athlete profile
class SocialLinks {
  final String? strava;
  final String? instagram;
  final String? facebook;

  const SocialLinks({
    this.strava,
    this.instagram,
    this.facebook,
  });

  factory SocialLinks.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SocialLinks();
    }
    return SocialLinks(
      strava: json['strava'] as String?,
      instagram: json['instagram'] as String?,
      facebook: json['facebook'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'strava': strava,
      'instagram': instagram,
      'facebook': facebook,
    };
  }

  SocialLinks copyWith({
    String? strava,
    String? instagram,
    String? facebook,
    bool clearStrava = false,
    bool clearInstagram = false,
    bool clearFacebook = false,
  }) {
    return SocialLinks(
      strava: clearStrava ? null : (strava ?? this.strava),
      instagram: clearInstagram ? null : (instagram ?? this.instagram),
      facebook: clearFacebook ? null : (facebook ?? this.facebook),
    );
  }
}

/// Athlete profile data (bio and social links)
class AthleteProfile {
  final String? bio;
  final SocialLinks socialLinks;

  const AthleteProfile({
    this.bio,
    this.socialLinks = const SocialLinks(),
  });

  factory AthleteProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AthleteProfile();
    }
    return AthleteProfile(
      bio: json['bio'] as String?,
      socialLinks: SocialLinks.fromJson(
        json['social_links'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'social_links': socialLinks.toJson(),
    };
  }

  AthleteProfile copyWith({
    String? bio,
    SocialLinks? socialLinks,
    bool clearBio = false,
  }) {
    return AthleteProfile(
      bio: clearBio ? null : (bio ?? this.bio),
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }
}
