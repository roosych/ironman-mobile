import 'package:flutter/foundation.dart';

/// User statistics summary
class StatsSummary {
  final int? totalRaces;
  final int? totalDistances;

  const StatsSummary({
    this.totalRaces,
    this.totalDistances,
  });

  factory StatsSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const StatsSummary();
    }
    return StatsSummary(
      totalRaces: json['total_races'] as int?,
      totalDistances: json['total_distances'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_races': totalRaces,
      'total_distances': totalDistances,
    };
  }
}

/// User statistics from profile
class Stats {
  final StatsSummary? summary;
  final String? fastestSwim;
  final String? fastestBike;
  final String? fastestRun;
  final String? bestTotalTime;
  final Map<String, dynamic>? personalBests;

  const Stats({
    this.summary,
    this.fastestSwim,
    this.fastestBike,
    this.fastestRun,
    this.bestTotalTime,
    this.personalBests,
  });

  factory Stats.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const Stats();
    }

    // Parse personal_bests safely
    Map<String, dynamic>? personalBests;
    try {
      debugPrint('=== Stats.fromJson: personal_bests DEBUG ===');
      debugPrint('Raw stats JSON keys: ${json.keys}');
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
      debugPrint('Stats debug logging error (safe to ignore): $e');
      // Continue with normal parsing even if debug fails
      if (json['personal_bests'] is Map) {
        personalBests = Map<String, dynamic>.from(json['personal_bests'] as Map);
      }
    }

    return Stats(
      summary: StatsSummary.fromJson(json['summary'] as Map<String, dynamic>?),
      fastestSwim: json['fastest_swim'] as String?,
      fastestBike: json['fastest_bike'] as String?,
      fastestRun: json['fastest_run'] as String?,
      bestTotalTime: json['best_total_time'] as String?,
      personalBests: personalBests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary?.toJson(),
      'fastest_swim': fastestSwim,
      'fastest_bike': fastestBike,
      'fastest_run': fastestRun,
      'best_total_time': bestTotalTime,
      'personal_bests': personalBests,
    };
  }

  Stats copyWith({
    StatsSummary? summary,
    String? fastestSwim,
    String? fastestBike,
    String? fastestRun,
    String? bestTotalTime,
    Map<String, dynamic>? personalBests,
    bool clearSummary = false,
    bool clearFastestSwim = false,
    bool clearFastestBike = false,
    bool clearFastestRun = false,
    bool clearBestTotalTime = false,
    bool clearPersonalBests = false,
  }) {
    return Stats(
      summary: clearSummary ? null : (summary ?? this.summary),
      fastestSwim: clearFastestSwim ? null : (fastestSwim ?? this.fastestSwim),
      fastestBike: clearFastestBike ? null : (fastestBike ?? this.fastestBike),
      fastestRun: clearFastestRun ? null : (fastestRun ?? this.fastestRun),
      bestTotalTime: clearBestTotalTime ? null : (bestTotalTime ?? this.bestTotalTime),
      personalBests: clearPersonalBests ? null : (personalBests ?? this.personalBests),
    );
  }
}