class AvailableProfile {
  final int id;
  final String adminFullName;
  final int? ironmanNumber;
  final int raceResultsCount;
  final String role;

  const AvailableProfile({
    required this.id,
    required this.adminFullName,
    this.ironmanNumber,
    required this.raceResultsCount,
    required this.role,
  });

  factory AvailableProfile.fromJson(Map<String, dynamic> json) {
    return AvailableProfile(
      id: json['id'] as int,
      adminFullName: json['admin_full_name'] as String,
      ironmanNumber: json['ironman_number'] as int?,
      raceResultsCount: json['race_results_count'] as int? ?? 0,
      role: json['role'] as String? ?? 'athlete',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_full_name': adminFullName,
      'ironman_number': ironmanNumber,
      'race_results_count': raceResultsCount,
      'role': role,
    };
  }
}

