/// Модель данных атлета
class Athlete {
  final int id;
  final String name;
  final String? avatar;
  final String? countryIso;
  final RaceCounts raceCounts;
  final int? ironmanNumber;
  final String? bio;
  final SocialLinks? socialLinks;
  final Ranking? ranking;

  const Athlete({
    required this.id,
    required this.name,
    this.avatar,
    this.countryIso,
    required this.raceCounts,
    this.ironmanNumber,
    this.bio,
    this.socialLinks,
    this.ranking,
  });

  factory Athlete.fromJson(Map<String, dynamic> json) {
    return Athlete(
      id: json['id'] as int,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      countryIso: json['country_iso'] as String?,
      raceCounts: RaceCounts.fromJson(
        json['race_counts'] as Map<String, dynamic>,
      ),
      ironmanNumber: json['ironman_number'] as int?,
      bio: json['bio'] as String?,
      socialLinks: json['social_links'] != null
          ? SocialLinks.fromJson(json['social_links'] as Map<String, dynamic>)
          : null,
      ranking: json['ranking'] != null
          ? Ranking.fromJson(json['ranking'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Количество гонок по типам
class RaceCounts {
  final int ironman;
  final int ironman703;
  final int race5150;

  const RaceCounts({
    required this.ironman,
    required this.ironman703,
    required this.race5150,
  });

  factory RaceCounts.fromJson(Map<String, dynamic> json) {
    return RaceCounts(
      ironman: json['ironman'] as int? ?? 0,
      ironman703: json['ironman_70_3'] as int? ?? 0,
      race5150: json['5150'] as int? ?? 0,
    );
  }
}

/// Социальные ссылки
class SocialLinks {
  final String? strava;
  final String? facebook;
  final String? instagram;

  const SocialLinks({
    this.strava,
    this.facebook,
    this.instagram,
  });

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      strava: json['strava'] as String?,
      facebook: json['facebook'] as String?,
      instagram: json['instagram'] as String?,
    );
  }
}

/// Рейтинг атлета
class Ranking {
  final RankingItem? ironman;
  final RankingItem? ironman703;

  const Ranking({
    this.ironman,
    this.ironman703,
  });

  factory Ranking.fromJson(Map<String, dynamic> json) {
    return Ranking(
      ironman: json['ironman'] != null
          ? RankingItem.fromJson(json['ironman'] as Map<String, dynamic>)
          : null,
      ironman703: json['ironman_70_3'] != null
          ? RankingItem.fromJson(json['ironman_70_3'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Элемент рейтинга
class RankingItem {
  final int position;
  final int total;

  const RankingItem({
    required this.position,
    required this.total,
  });

  factory RankingItem.fromJson(Map<String, dynamic> json) {
    return RankingItem(
      position: json['position'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }
}

