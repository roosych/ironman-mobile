/// Модель данных личного рекорда по дисциплине
class DisciplineRecord {
  final String time;
  final int seconds;
  final String raceDate;
  final String location;

  const DisciplineRecord({
    required this.time,
    required this.seconds,
    required this.raceDate,
    required this.location,
  });

  factory DisciplineRecord.fromJson(Map<String, dynamic> json) {
    return DisciplineRecord(
      time: json['time'] as String,
      seconds: json['seconds'] as int,
      raceDate: json['race_date'] as String,
      location: json['location'] as String,
    );
  }

  /// Преобразует в формат, ожидаемый виджетом _PersonalBestsCard
  Map<String, dynamic> toPersonalBestsFormat() {
    return {
      'time': time,
      'race': {
        'race_date': raceDate,
        'location': location,
      },
    };
  }
}

/// Модель данных личных рекордов по типу гонки
class PersonalRecord {
  final DisciplineRecord? swim;
  final DisciplineRecord? t1;
  final DisciplineRecord? bike;
  final DisciplineRecord? t2;
  final DisciplineRecord? run;
  final DisciplineRecord? total;

  const PersonalRecord({
    this.swim,
    this.t1,
    this.bike,
    this.t2,
    this.run,
    this.total,
  });

  static DisciplineRecord? _parseField(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return DisciplineRecord.fromJson(value);
    if (value is Map) return DisciplineRecord.fromJson(Map<String, dynamic>.from(value));
    return null;
  }

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      swim: _parseField(json['swim']),
      t1: _parseField(json['t1']),
      bike: _parseField(json['bike']),
      t2: _parseField(json['t2']),
      run: _parseField(json['run']),
      total: _parseField(json['total']),
    );
  }

  /// Преобразует в формат, ожидаемый виджетом _PersonalBestsCard
  Map<String, dynamic> toPersonalBestsFormat() {
    return {
      'swim': swim?.toPersonalBestsFormat(),
      't1': t1?.toPersonalBestsFormat(),
      'bike': bike?.toPersonalBestsFormat(),
      't2': t2?.toPersonalBestsFormat(),
      'run': run?.toPersonalBestsFormat(),
      'total': total?.toPersonalBestsFormat(),
    };
  }
}

/// Модель данных всех личных рекордов атлета
class Records {
  final PersonalRecord? ironman;
  final PersonalRecord? ironman703;
  final PersonalRecord? race5150;

  const Records({
    this.ironman,
    this.ironman703,
    this.race5150,
  });

  static PersonalRecord? _parseRecord(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return PersonalRecord.fromJson(value);
    if (value is Map) return PersonalRecord.fromJson(Map<String, dynamic>.from(value));
    return null;
  }

  factory Records.fromJson(Map<String, dynamic> json) {
    return Records(
      ironman: _parseRecord(json['ironman']),
      ironman703: _parseRecord(json['ironman_70_3']),
      race5150: _parseRecord(json['olympic_5150'] ?? json['5150']),
    );
  }

  /// Преобразует в формат, ожидаемый виджетом _PersonalBestsCard
  Map<String, dynamic> toPersonalBestsFormat() {
    return {
      'ironman': ironman?.toPersonalBestsFormat(),
      'ironman_70_3': ironman703?.toPersonalBestsFormat(),
      '5150': race5150?.toPersonalBestsFormat(),
    };
  }
}

