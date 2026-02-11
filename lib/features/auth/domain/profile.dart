import 'package:flutter/foundation.dart';
import 'stats.dart';
import '../../results/domain/race_result.dart';

/// Social links for user profile
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

/// User profile data
class Profile {
  final int? id;
  final String? role;
  final int? ironmanNumber;
  final int? ironmanRacesCount;
  final String? countryIso;
  final String? bio;
  final SocialLinks socialLinks;
  final bool? codeUsed;
  final Map<String, dynamic>? photos;
  final List<RaceResult>? raceResults;
  final Stats? stats;
  final Map<String, dynamic>? personalBests;

  const Profile({
    this.id,
    this.role,
    this.ironmanNumber,
    this.ironmanRacesCount,
    this.countryIso,
    this.bio,
    this.socialLinks = const SocialLinks(),
    this.codeUsed,
    this.photos,
    this.raceResults,
    this.stats,
    this.personalBests,
  });

  factory Profile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const Profile();
    }

    // Parse race results safely
    List<RaceResult>? raceResults;
    if (json['race_results'] is List) {
      try {
        raceResults = (json['race_results'] as List)
            .map((result) => RaceResult.fromJson(result as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error parsing race results: $e');
        raceResults = <RaceResult>[];
      }
    }

    // Parse photos safely
    Map<String, dynamic>? photos;
    if (json['photos'] is Map) {
      photos = Map<String, dynamic>.from(json['photos'] as Map);
    } else if (json['photos'] is List) {
      // Handle case when photos is a List (from API) - convert to empty map for consistency
      photos = <String, dynamic>{};
    }

    // Parse personal_bests safely
    Map<String, dynamic>? personalBests;
    try {
      debugPrint('=== Profile.fromJson: personal_bests DEBUG ===');
      debugPrint('Raw JSON keys: ${json.keys}');
      debugPrint('Has personal_bests key: ${json.containsKey('personal_bests')}');
      debugPrint('personal_bests raw: ${json['personal_bests']}');
      debugPrint('personal_bests type: ${json['personal_bests'].runtimeType}');

      if (json['personal_bests'] is Map) {
        personalBests = Map<String, dynamic>.from(json['personal_bests'] as Map);
        debugPrint('personal_bests parsed successfully: ${personalBests.keys}');
      } else {
        debugPrint('personal_bests is not a Map or is null');
      }
      debugPrint('==============================================');
    } catch (e) {
      debugPrint('Profile debug logging error (safe to ignore): $e');
      // Continue with normal parsing even if debug fails
      if (json['personal_bests'] is Map) {
        personalBests = Map<String, dynamic>.from(json['personal_bests'] as Map);
      }
    }

    return Profile(
      id: json['id'] as int?,
      role: json['role'] as String?,
      ironmanNumber: json['ironman_number'] as int?,
      ironmanRacesCount: json['ironman_races_count'] as int?,
      countryIso: json['country_iso'] as String?,
      bio: json['bio'] as String?,
      socialLinks: SocialLinks.fromJson(
        json['social_links'] as Map<String, dynamic>?,
      ),
      codeUsed: json['code_used'] as bool?,
      photos: photos,
      raceResults: raceResults,
      stats: Stats.fromJson(
        json['stats'] as Map<String, dynamic>?,
      ),
      personalBests: personalBests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'ironman_number': ironmanNumber,
      'ironman_races_count': ironmanRacesCount,
      'country_iso': countryIso,
      'bio': bio,
      'social_links': socialLinks.toJson(),
      'code_used': codeUsed,
      'photos': photos,
      'race_results': raceResults?.map((result) => result.toJson()).toList(),
      'stats': stats?.toJson(),
      'personal_bests': personalBests,
    };
  }

  Profile copyWith({
    int? id,
    String? role,
    int? ironmanNumber,
    int? ironmanRacesCount,
    String? countryIso,
    String? bio,
    SocialLinks? socialLinks,
    bool? codeUsed,
    Map<String, dynamic>? photos,
    List<RaceResult>? raceResults,
    Stats? stats,
    Map<String, dynamic>? personalBests,
    bool clearId = false,
    bool clearRole = false,
    bool clearIronmanNumber = false,
    bool clearIronmanRacesCount = false,
    bool clearCountryIso = false,
    bool clearBio = false,
    bool clearCodeUsed = false,
    bool clearPhotos = false,
    bool clearRaceResults = false,
    bool clearStats = false,
    bool clearPersonalBests = false,
  }) {
    return Profile(
      id: clearId ? null : (id ?? this.id),
      role: clearRole ? null : (role ?? this.role),
      ironmanNumber: clearIronmanNumber ? null : (ironmanNumber ?? this.ironmanNumber),
      ironmanRacesCount: clearIronmanRacesCount ? null : (ironmanRacesCount ?? this.ironmanRacesCount),
      countryIso: clearCountryIso ? null : (countryIso ?? this.countryIso),
      bio: clearBio ? null : (bio ?? this.bio),
      socialLinks: socialLinks ?? this.socialLinks,
      codeUsed: clearCodeUsed ? null : (codeUsed ?? this.codeUsed),
      photos: clearPhotos ? null : (photos ?? this.photos),
      raceResults: clearRaceResults ? null : (raceResults ?? this.raceResults),
      stats: clearStats ? null : (stats ?? this.stats),
      personalBests: clearPersonalBests ? null : (personalBests ?? this.personalBests),
    );
  }
}