class Ranking {
  final int position;
  final int athleteId;
  final String name;
  final String? avatar;
  final String time;
  final int seconds;
  final String raceDate;
  final String location;
  final int ironmanCount;
  final int? swimSeconds;
  final int? bikeSeconds;
  final int? runSeconds;

  const Ranking({
    required this.position,
    required this.athleteId,
    required this.name,
    this.avatar,
    required this.time,
    required this.seconds,
    required this.raceDate,
    required this.location,
    this.ironmanCount = 0,
    this.swimSeconds,
    this.bikeSeconds,
    this.runSeconds,
  });

  factory Ranking.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    // Извлекаем количество гонок типа ironman
    int ironmanCount = 0;
    try {
      // Проверяем наличие race_counts
      final raceCountsValue = json['race_counts'];
      if (raceCountsValue != null && raceCountsValue is Map) {
        try {
          final ironmanValue = raceCountsValue['ironman'];
          if (ironmanValue != null) {
            ironmanCount = safeInt(ironmanValue);
          }
        } catch (_) {
          // Игнорируем ошибки при парсинге race_counts
        }
      }

      // Альтернативный вариант, если данные приходят напрямую
      if (ironmanCount == 0) {
        final ironmanCountValue = json['ironman_count'];
        if (ironmanCountValue != null) {
          ironmanCount = safeInt(ironmanCountValue);
        }
      }
    } catch (e) {
      // В случае любой ошибки используем значение по умолчанию 0
      ironmanCount = 0;
    }

    return Ranking(
      position: safeInt(json['position']),
      athleteId: safeInt(json['athlete_id']),
      name: safeString(json['name'], ''),
      avatar: json['avatar'] as String?,
      time: safeString(json['time'], '00:00:00'),
      seconds: safeInt(json['seconds']),
      raceDate: safeString(json['race_date'], ''),
      location: safeString(json['location'], ''),
      ironmanCount: ironmanCount,
      swimSeconds: json['swim_seconds'] != null ? safeInt(json['swim_seconds']) : null,
      bikeSeconds: json['bike_seconds'] != null ? safeInt(json['bike_seconds']) : null,
      runSeconds: json['run_seconds'] != null ? safeInt(json['run_seconds']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'athlete_id': athleteId,
      'name': name,
      'avatar': avatar,
      'time': time,
      'seconds': seconds,
      'race_date': raceDate,
      'location': location,
      'ironman_count': ironmanCount,
      'swim_seconds': swimSeconds,
      'bike_seconds': bikeSeconds,
      'run_seconds': runSeconds,
    };
  }
}

class RankingsMeta {
  final String raceType;
  final String discipline;
  final int total;

  const RankingsMeta({
    required this.raceType,
    required this.discipline,
    required this.total,
  });

  factory RankingsMeta.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return RankingsMeta(
      raceType: safeString(json['race_type'], ''),
      discipline: safeString(json['discipline'], ''),
      total: safeInt(json['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'race_type': raceType, 'discipline': discipline, 'total': total};
  }
}
