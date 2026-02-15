import '../../../core/network/base_api_service.dart';
import '../../../core/network/simple_api_client.dart';
import '../domain/race_result.dart';

/// Простой API сервис для результатов гонок
class SimpleResultsApi extends BaseApiService {
  /// Получение всех результатов
  Future<ApiResponse<ResultsResponse>> getAllResults({
    int page = 1,
    String? search,
    String? raceType,
    String? country,
    String? year,
  }) async {
    await init();

    final queryParams = <String, dynamic>{
      'page': page,
    };

    if (search != null) queryParams['search'] = search;
    if (raceType != null) queryParams['race_type'] = raceType;
    if (country != null) queryParams['country'] = country;
    if (year != null) queryParams['year'] = year;

    return client.get<ResultsResponse>(
      '/race-results',
      queryParameters: queryParams,
      fromJson: (json) => ResultsResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Получение результатов пользователя
  Future<ApiResponse<ResultsResponse>> getUserResults({
    required int userProfileId,
    int page = 1,
    String? raceType,
    String? year,
  }) async {
    await init();

    final queryParams = <String, dynamic>{
      'user_profile_id': userProfileId,
      'page': page,
    };

    if (raceType != null) queryParams['race_type'] = raceType;
    if (year != null) queryParams['year'] = year;

    return client.get<ResultsResponse>(
      '/race-results',
      queryParameters: queryParams,
      fromJson: (json) => ResultsResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Получение деталей результата
  Future<ApiResponse<RaceResult>> getResultDetails(int resultId) async {
    await init();

    return client.get<RaceResult>(
      '/race-results/$resultId',
      fromJson: (json) => RaceResult.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Поиск результатов
  Future<ApiResponse<ResultsResponse>> searchResults({
    required String query,
    int page = 1,
    String? raceType,
    String? country,
    String? year,
  }) async {
    await init();

    final queryParams = <String, dynamic>{
      'search': query,
      'page': page,
    };

    if (raceType != null) queryParams['race_type'] = raceType;
    if (country != null) queryParams['country'] = country;
    if (year != null) queryParams['year'] = year;

    return client.get<ResultsResponse>(
      '/race-results/search',
      queryParameters: queryParams,
      fromJson: (json) => ResultsResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}

/// Ответ API с результатами
class ResultsResponse {
  final List<RaceResult> results;
  final PaginationInfo pagination;

  const ResultsResponse({
    required this.results,
    required this.pagination,
  });

  factory ResultsResponse.fromJson(Map<String, dynamic> json) {
    return ResultsResponse(
      results: (json['data'] as List?)
          ?.map((item) => RaceResult.fromJson(item as Map<String, dynamic>))
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