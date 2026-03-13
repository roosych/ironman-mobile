class UpcomingRace {
  final int id;
  final String raceType;
  final String raceTypeLabel;
  final String location;
  final String raceDate;
  final String? countryIso;
  final bool isActive;
  final CreatedBy? createdBy;

  const UpcomingRace({
    required this.id,
    required this.raceType,
    required this.raceTypeLabel,
    required this.location,
    required this.raceDate,
    this.countryIso,
    required this.isActive,
    this.createdBy,
  });

  factory UpcomingRace.fromJson(Map<String, dynamic> json) {
    int? safeInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    bool safeBool(dynamic value, [bool defaultValue = false]) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return defaultValue;
    }

    // Новый формат API: вложенные объекты race и athlete
    final raceObj = json['race'] as Map<String, dynamic>?;
    if (raceObj != null) {
      return UpcomingRace(
        id: safeInt(json['id']) ?? 0,
        raceType: safeString(raceObj['type'], ''),
        raceTypeLabel: safeString(raceObj['type_label'], ''),
        location: safeString(raceObj['location'], ''),
        raceDate: safeString(raceObj['date'], ''),
        countryIso: raceObj['country_iso'] as String?,
        isActive: true,
        createdBy: json['athlete'] != null
            ? CreatedBy.fromJson(json['athlete'] as Map<String, dynamic>)
            : null,
      );
    }

    // Старый плоский формат (обратная совместимость)
    return UpcomingRace(
      id: safeInt(json['id']) ?? 0,
      raceType: safeString(json['race_type'], ''),
      raceTypeLabel: safeString(json['race_type_label'], ''),
      location: safeString(json['location'], ''),
      raceDate: safeString(json['race_date'], ''),
      countryIso: json['country_iso'] as String?,
      isActive: safeBool(json['is_active'], true),
      createdBy: json['created_by'] != null
          ? CreatedBy.fromJson(json['created_by'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'race_type': raceType,
      'race_type_label': raceTypeLabel,
      'location': location,
      'race_date': raceDate,
      'country_iso': countryIso,
      'is_active': isActive,
      'created_by': createdBy?.toJson(),
    };
  }
}

class CreatedBy {
  final int id;
  final String name;
  final String? avatar;

  const CreatedBy({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    int? safeInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    return CreatedBy(
      id: safeInt(json['id']) ?? 0,
      name: safeString(json['name'], ''),
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
    };
  }
}

