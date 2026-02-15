import '../../../core/network/base_api_service.dart';
import '../../../core/network/simple_api_client.dart';
import '../../rankings/domain/athlete.dart';

/// Простой API сервис для атлетов
class SimpleAthletesApi extends BaseApiService {
  /// Получение всех атлетов
  Future<ApiResponse<AthletesResponse>> getAthletes({
    int page = 1,
    String? search,
    String? country,
    String? gender,
    String? raceType,
  }) async {
    await init();

    final queryParams = <String, dynamic>{
      'page': page,
    };

    if (search != null) queryParams['search'] = search;
    if (country != null) queryParams['country'] = country;
    if (gender != null) queryParams['gender'] = gender;
    if (raceType != null) queryParams['race_type'] = raceType;

    return client.get<AthletesResponse>(
      '/athletes',
      queryParameters: queryParams,
      fromJson: (json) => AthletesResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Получение деталей атлета
  Future<ApiResponse<AthleteDetails>> getAthleteDetails(int athleteId) async {
    await init();

    return client.get<AthleteDetails>(
      '/athletes/$athleteId',
      fromJson: (json) => AthleteDetails.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Поиск атлетов
  Future<ApiResponse<AthletesResponse>> searchAthletes({
    required String query,
    int page = 1,
    String? country,
    String? gender,
    String? raceType,
  }) async {
    await init();

    final queryParams = <String, dynamic>{
      'search': query,
      'page': page,
    };

    if (country != null) queryParams['country'] = country;
    if (gender != null) queryParams['gender'] = gender;
    if (raceType != null) queryParams['race_type'] = raceType;

    return client.get<AthletesResponse>(
      '/athletes/search',
      queryParameters: queryParams,
      fromJson: (json) => AthletesResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Получение статистики атлета
  Future<ApiResponse<AthleteStats>> getAthleteStats(int athleteId) async {
    await init();

    return client.get<AthleteStats>(
      '/athletes/$athleteId/stats',
      fromJson: (json) => AthleteStats.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Получение результатов атлета
  Future<ApiResponse<AthleteResultsResponse>> getAthleteResults({
    required int athleteId,
    int page = 1,
    String? raceType,
    String? year,
  }) async {
    await init();

    final queryParams = <String, dynamic>{
      'page': page,
    };

    if (raceType != null) queryParams['race_type'] = raceType;
    if (year != null) queryParams['year'] = year;

    return client.get<AthleteResultsResponse>(
      '/athletes/$athleteId/results',
      queryParameters: queryParams,
      fromJson: (json) => AthleteResultsResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}

/// Ответ API со списком атлетов
class AthletesResponse {
  final List<Athlete> athletes;
  final PaginationInfo pagination;

  const AthletesResponse({
    required this.athletes,
    required this.pagination,
  });

  factory AthletesResponse.fromJson(Map<String, dynamic> json) {
    return AthletesResponse(
      athletes: (json['data'] as List?)
          ?.map((item) => Athlete.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Детали атлета
class AthleteDetails {
  final Athlete athlete;
  final AthleteStats? stats;
  final List<AthleteResult>? recentResults;

  const AthleteDetails({
    required this.athlete,
    this.stats,
    this.recentResults,
  });

  factory AthleteDetails.fromJson(Map<String, dynamic> json) {
    return AthleteDetails(
      athlete: Athlete.fromJson(json['athlete'] as Map<String, dynamic>),
      stats: json['stats'] != null
          ? AthleteStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      recentResults: (json['recent_results'] as List?)
          ?.map((item) => AthleteResult.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Статистика атлета
class AthleteStats {
  final int totalRaces;
  final int totalWins;
  final int totalPodiums;
  final String? bestTime;
  final String? averageTime;

  const AthleteStats({
    required this.totalRaces,
    required this.totalWins,
    required this.totalPodiums,
    this.bestTime,
    this.averageTime,
  });

  factory AthleteStats.fromJson(Map<String, dynamic> json) {
    return AthleteStats(
      totalRaces: json['total_races'] as int? ?? 0,
      totalWins: json['total_wins'] as int? ?? 0,
      totalPodiums: json['total_podiums'] as int? ?? 0,
      bestTime: json['best_time'] as String?,
      averageTime: json['average_time'] as String?,
    );
  }
}

/// Результат атлета
class AthleteResult {
  final int id;
  final String raceName;
  final DateTime raceDate;
  final String raceType;
  final String? location;
  final int? position;
  final String? finishTime;
  final String? swimTime;
  final String? bikeTime;
  final String? runTime;

  const AthleteResult({
    required this.id,
    required this.raceName,
    required this.raceDate,
    required this.raceType,
    this.location,
    this.position,
    this.finishTime,
    this.swimTime,
    this.bikeTime,
    this.runTime,
  });

  factory AthleteResult.fromJson(Map<String, dynamic> json) {
    return AthleteResult(
      id: json['id'] as int,
      raceName: json['race_name'] as String,
      raceDate: DateTime.parse(json['race_date'] as String),
      raceType: json['race_type'] as String,
      location: json['location'] as String?,
      position: json['position'] as int?,
      finishTime: json['finish_time'] as String?,
      swimTime: json['swim_time'] as String?,
      bikeTime: json['bike_time'] as String?,
      runTime: json['run_time'] as String?,
    );
  }
}

/// Ответ API с результатами атлета
class AthleteResultsResponse {
  final List<AthleteResult> results;
  final PaginationInfo pagination;

  const AthleteResultsResponse({
    required this.results,
    required this.pagination,
  });

  factory AthleteResultsResponse.fromJson(Map<String, dynamic> json) {
    return AthleteResultsResponse(
      results: (json['data'] as List?)
          ?.map((item) => AthleteResult.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Информация о пагинации
class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPrevPage;

  const PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      totalItems: json['total_items'] as int? ?? 0,
      hasNextPage: json['has_next_page'] as bool? ?? false,
      hasPrevPage: json['has_prev_page'] as bool? ?? false,
    );
  }
}