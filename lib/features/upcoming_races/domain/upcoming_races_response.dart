import 'upcoming_race.dart';

/// Модель для метаданных пагинации (meta)
class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return PaginationMeta(
      currentPage: safeInt(json['current_page'], 1),
      lastPage: safeInt(json['last_page'], 1),
      perPage: safeInt(json['per_page'], 10),
      total: safeInt(json['total'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
    };
  }
}

/// Модель для ответа API с пагинацией
class UpcomingRacesResponse {
  final bool success;
  final List<UpcomingRace> data;
  final PaginationMeta meta;

  const UpcomingRacesResponse({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory UpcomingRacesResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'];
    if (dataList is! List) {
      throw Exception('Expected data to be a List, got ${dataList.runtimeType}');
    }

    final races = dataList.map((json) {
      if (json is! Map<String, dynamic>) {
        throw Exception('Expected race item to be a Map, got ${json.runtimeType}');
      }
      return UpcomingRace.fromJson(json);
    }).toList();

    return UpcomingRacesResponse(
      success: json['success'] == true,
      data: races,
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((race) => race.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }
}