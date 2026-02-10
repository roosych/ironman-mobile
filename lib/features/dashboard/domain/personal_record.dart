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

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      swim: json['swim'] != null
          ? DisciplineRecord.fromJson(json['swim'] as Map<String, dynamic>)
          : null,
      t1: json['t1'] != null
          ? DisciplineRecord.fromJson(json['t1'] as Map<String, dynamic>)
          : null,
      bike: json['bike'] != null
          ? DisciplineRecord.fromJson(json['bike'] as Map<String, dynamic>)
          : null,
      t2: json['t2'] != null
          ? DisciplineRecord.fromJson(json['t2'] as Map<String, dynamic>)
          : null,
      run: json['run'] != null
          ? DisciplineRecord.fromJson(json['run'] as Map<String, dynamic>)
          : null,
      total: json['total'] != null
          ? DisciplineRecord.fromJson(json['total'] as Map<String, dynamic>)
          : null,
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

  factory Records.fromJson(Map<String, dynamic> json) {
    return Records(
      ironman: json['ironman'] != null
          ? PersonalRecord.fromJson(json['ironman'] as Map<String, dynamic>)
          : null,
      ironman703: json['ironman_70_3'] != null
          ? PersonalRecord.fromJson(
              json['ironman_70_3'] as Map<String, dynamic>,
            )
          : null,
      race5150: json['5150'] != null
          ? PersonalRecord.fromJson(json['5150'] as Map<String, dynamic>)
          : null,
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

