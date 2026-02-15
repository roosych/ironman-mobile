import '../../../core/network/base_api_service.dart';
import '../../../core/network/simple_api_client.dart';
import '../domain/athlete.dart';
import '../domain/ranking.dart';

/// Простой API сервис для рейтингов
class SimpleRankingsApi extends BaseApiService {
  /// Получение рейтингов
  Future<ApiResponse<RankingsResult>> getRankings({
    String? country,
    String? raceType,
    String? gender,
    String? ageGroup,
    int? year,
    int page = 1,
  }) async {
    await init();

    final queryParams = <String, dynamic>{
      'page': page,
    };

    if (country != null) queryParams['country'] = country;
    if (raceType != null) queryParams['race_type'] = raceType;
    if (gender != null) queryParams['gender'] = gender;
    if (ageGroup != null) queryParams['age_group'] = ageGroup;
    if (year != null) queryParams['year'] = year;

    return client.get<RankingsResult>(
      '/rankings',
      queryParameters: queryParams,
      fromJson: (json) => RankingsResult.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Поиск атлетов
  Future<ApiResponse<AthletesResult>> searchAthletes({
    required String query,
    int page = 1,
  }) async {
    await init();

    return client.get<AthletesResult>(
      '/athletes/search',
      queryParameters: {
        'q': query,
        'page': page,
      },
      fromJson: (json) => AthletesResult.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Получение деталей атлета
  Future<ApiResponse<Athlete>> getAthleteDetails(int athleteId) async {
    await init();

    return client.get<Athlete>(
      '/athletes/$athleteId',
      fromJson: (json) => Athlete.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Получение всех атлетов
  Future<ApiResponse<AthletesResult>> getAllAthletes({
    int page = 1,
    String? search,
    String? country,
    String? gender,
  }) async {
    await init();

    final queryParams = <String, dynamic>{
      'page': page,
    };

    if (search != null) queryParams['search'] = search;
    if (country != null) queryParams['country'] = country;
    if (gender != null) queryParams['gender'] = gender;

    return client.get<AthletesResult>(
      '/athletes',
      queryParameters: queryParams,
      fromJson: (json) => AthletesResult.fromJson(json as Map<String, dynamic>),
    );
  }
}

/// Результат запроса рейтингов
class RankingsResult {
  final List<Ranking> rankings;
  final PaginationInfo pagination;

  const RankingsResult({
    required this.rankings,
    required this.pagination,
  });

  factory RankingsResult.fromJson(Map<String, dynamic> json) {
    return RankingsResult(
      rankings: (json['data'] as List)
          .map((item) => Ranking.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Результат запроса атлетов
class AthletesResult {
  final List<Athlete> athletes;
  final PaginationInfo pagination;

  const AthletesResult({
    required this.athletes,
    required this.pagination,
  });

  factory AthletesResult.fromJson(Map<String, dynamic> json) {
    return AthletesResult(
      athletes: (json['data'] as List)
          .map((item) => Athlete.fromJson(item as Map<String, dynamic>))
          .toList(),
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