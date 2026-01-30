class Approver {
  final int id;
  final String name;

  const Approver({
    required this.id,
    required this.name,
  });

  factory Approver.fromJson(Map<String, dynamic> json) {
    return Approver(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class RaceResult {
  final int id;
  final String date;
  final String location;
  final String raceType;
  final String? raceTypeLabel;
  final String swimTime;
  final String t1Time;
  final String bikeTime;
  final String t2Time;
  final String runTime;
  final String totalTime;
  final String? ageGroup;
  final int? overallPosition;
  final int? ageGroupPosition;
  final int? userProfileId;
  final String? athleteName;
  final bool isApproved;
  final DateTime? approvedAt;
  final Approver? approvedBy;

  const RaceResult({
    required this.id,
    required this.date,
    required this.location,
    required this.raceType,
    this.raceTypeLabel,
    required this.swimTime,
    required this.t1Time,
    required this.bikeTime,
    required this.t2Time,
    required this.runTime,
    required this.totalTime,
    this.ageGroup,
    this.overallPosition,
    this.ageGroupPosition,
    this.userProfileId,
    this.athleteName,
    this.isApproved = true,
    this.approvedAt,
    this.approvedBy,
  });

  static String? _extractAthleteName(Map<String, dynamic> json) {
    // Сначала проверяем самое вероятное поле 'name' (текущий формат API)
    if (json['name'] != null) {
      final name = json['name'];
      if (name is String && name.isNotEmpty) return name;
    }
    
    // Альтернативные варианты полей
    if (json['athlete_name'] != null) {
      final name = json['athlete_name'];
      if (name is String && name.isNotEmpty) return name;
    }
    if (json['athleteName'] != null) {
      final name = json['athleteName'];
      if (name is String && name.isNotEmpty) return name;
    }
    if (json['user_name'] != null) {
      final name = json['user_name'];
      if (name is String && name.isNotEmpty) return name;
    }
    if (json['userName'] != null) {
      final name = json['userName'];
      if (name is String && name.isNotEmpty) return name;
    }
    
    // Из вложенного объекта user
    if (json['user'] is Map<String, dynamic>) {
      final user = json['user'] as Map<String, dynamic>;
      if (user['name'] != null) {
        final name = user['name'];
        if (name is String && name.isNotEmpty) return name;
      }
    }
    
    // Из вложенного объекта profile
    if (json['profile'] is Map<String, dynamic>) {
      final profile = json['profile'] as Map<String, dynamic>;
      if (profile['name'] != null) {
        final name = profile['name'];
        if (name is String && name.isNotEmpty) return name;
      }
    }
    
    // Из вложенного объекта user_profile
    if (json['user_profile'] is Map<String, dynamic>) {
      final userProfile = json['user_profile'] as Map<String, dynamic>;
      if (userProfile['name'] != null) {
        final name = userProfile['name'];
        if (name is String && name.isNotEmpty) return name;
      }
    }
    
    return null;
  }

  factory RaceResult.fromJson(Map<String, dynamic> json) {
    // Безопасное преобразование с значениями по умолчанию
    int? safeInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    String safeString(dynamic value, [String defaultValue = '-']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    // Parse approved_at
    DateTime? approvedAt;
    if (json['approved_at'] != null) {
      try {
        approvedAt = DateTime.parse(json['approved_at'] as String);
      } catch (_) {
        approvedAt = null;
      }
    }

    // Parse approved_by
    Approver? approvedBy;
    if (json['approved_by'] != null && json['approved_by'] is Map<String, dynamic>) {
      try {
        approvedBy = Approver.fromJson(json['approved_by'] as Map<String, dynamic>);
      } catch (_) {
        approvedBy = null;
      }
    }

    return RaceResult(
      id: safeInt(json['id']) ?? 0,
      date: safeString(json['race_date'] ?? json['date'], ''),
      location: safeString(json['location'], ''),
      raceType: safeString(json['race_type'], ''),
      raceTypeLabel: json['race_type_label'] as String?,
      swimTime: safeString(json['swim_time'] ?? json['swimTime'], '00:00:00'),
      t1Time: safeString(json['t1_time'] ?? json['t1Time'], '00:00:00'),
      bikeTime: safeString(json['bike_time'] ?? json['bikeTime'], '00:00:00'),
      t2Time: safeString(json['t2_time'] ?? json['t2Time'], '00:00:00'),
      runTime: safeString(json['run_time'] ?? json['runTime'], '00:00:00'),
      totalTime: safeString(json['total_time'] ?? json['totalTime'], '00:00:00'),
      ageGroup: json['age_group'] as String? ?? json['ageGroup'] as String?,
      overallPosition: safeInt(json['overall_position'] ?? json['overallPosition']),
      ageGroupPosition: safeInt(json['age_group_position'] ?? json['ageGroupPosition']),
      userProfileId: safeInt(json['user_profile_id'] ?? json['userProfileId']),
      athleteName: _extractAthleteName(json),
      isApproved: json['is_approved'] as bool? ?? true,
      approvedAt: approvedAt,
      approvedBy: approvedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'raceDate': date,
      'location': location,
      'raceType': raceType,
      'raceTypeLabel': raceTypeLabel,
      'swimTime': swimTime,
      't1Time': t1Time,
      'bikeTime': bikeTime,
      't2Time': t2Time,
      'runTime': runTime,
      'totalTime': totalTime,
      'ageGroup': ageGroup,
      'overallPosition': overallPosition,
      'ageGroupPosition': ageGroupPosition,
      'userProfileId': userProfileId,
      'athleteName': athleteName,
    };
  }
}
