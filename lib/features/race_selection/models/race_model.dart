/// Модель данных для гонки из API /api/v1/races
class RaceModel {
  final int id;
  final String date;           // "2026-06-14"
  final String location;       // "Hamburg"
  final String type;          // "ironman"
  final String typeLabel;     // "Ironman"
  final String countryIso;    // "DE"

  const RaceModel({
    required this.id,
    required this.date,
    required this.location,
    required this.type,
    required this.typeLabel,
    required this.countryIso,
  });

  /// Создание модели из JSON ответа API
  factory RaceModel.fromJson(Map<String, dynamic> json) {
    // Безопасные парсеры для обработки разных типов данных
    int safeInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    return RaceModel(
      id: safeInt(json['id']),
      date: safeString(json['date']),
      location: safeString(json['location']),
      type: safeString(json['type']),
      typeLabel: safeString(json['type_label']),
      countryIso: safeString(json['country_iso']),
    );
  }

  /// Конвертация в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'location': location,
      'type': type,
      'type_label': typeLabel,
      'country_iso': countryIso,
    };
  }

  /// Копирование с изменениями
  RaceModel copyWith({
    int? id,
    String? date,
    String? location,
    String? type,
    String? typeLabel,
    String? countryIso,
  }) {
    return RaceModel(
      id: id ?? this.id,
      date: date ?? this.date,
      location: location ?? this.location,
      type: type ?? this.type,
      typeLabel: typeLabel ?? this.typeLabel,
      countryIso: countryIso ?? this.countryIso,
    );
  }


  /// Сравнение объектов
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RaceModel &&
        other.id == id &&
        other.date == date &&
        other.location == location &&
        other.type == type &&
        other.typeLabel == typeLabel &&
        other.countryIso == countryIso;
  }

  /// Хеш-код для сравнения
  @override
  int get hashCode {
    return Object.hash(id, date, location, type, typeLabel, countryIso);
  }

  /// Строковое представление для отладки
  @override
  String toString() {
    return 'RaceModel(id: $id, date: $date, location: $location, type: $type, typeLabel: $typeLabel, countryIso: $countryIso)';
  }

  /// Отформатированная дата для UI (DD.MM.YYYY)
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
    } catch (e) {
      return date; // Возвращаем оригинальную дату если не удалось распарсить
    }
  }

  /// Полное название для отображения в UI
  String get displayName {
    return '${typeLabel.toUpperCase()}, $location, $formattedDate';
  }
}