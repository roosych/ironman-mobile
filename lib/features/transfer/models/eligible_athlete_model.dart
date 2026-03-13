/// Модель атлета-донора для переноса результатов
class EligibleAthleteModel {
  /// ID атлета
  final int id;

  /// Имя атлета
  final String name;

  /// URL аватара атлета
  final String? avatar;

  /// Общее количество гонок атлета
  final int totalRaces;

  /// Локация последней гонки
  final String? lastRaceLocation;

  /// Дата последней гонки
  final DateTime? lastRaceDate;

  const EligibleAthleteModel({
    required this.id,
    required this.name,
    this.avatar,
    required this.totalRaces,
    this.lastRaceLocation,
    this.lastRaceDate,
  });

  static int _parseId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Создает модель из JSON данных
  factory EligibleAthleteModel.fromJson(Map<String, dynamic> json) {
    return EligibleAthleteModel(
      id: _parseId(json['id']),
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      totalRaces: json['total_races'] as int? ?? 0,
      lastRaceLocation: json['last_race_location'] as String?,
      lastRaceDate: json['last_race_date'] != null
          ? DateTime.parse(json['last_race_date'] as String)
          : null,
    );
  }

  /// Преобразует модель в JSON данные
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'total_races': totalRaces,
      'last_race_location': lastRaceLocation,
      'last_race_date': lastRaceDate?.toIso8601String(),
    };
  }

  /// Создает копию модели с измененными полями
  EligibleAthleteModel copyWith({
    int? id,
    String? name,
    String? avatar,
    int? totalRaces,
    String? lastRaceLocation,
    DateTime? lastRaceDate,
    bool clearAvatar = false,
    bool clearLastRaceLocation = false,
    bool clearLastRaceDate = false,
  }) {
    return EligibleAthleteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: clearAvatar ? null : (avatar ?? this.avatar),
      totalRaces: totalRaces ?? this.totalRaces,
      lastRaceLocation: clearLastRaceLocation ? null : (lastRaceLocation ?? this.lastRaceLocation),
      lastRaceDate: clearLastRaceDate ? null : (lastRaceDate ?? this.lastRaceDate),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EligibleAthleteModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EligibleAthleteModel{id: $id, name: $name, totalRaces: $totalRaces}';
  }
}