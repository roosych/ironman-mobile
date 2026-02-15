import '../../../core/network/base_api_service.dart';
import '../../../core/network/simple_api_client.dart';
import '../domain/upcoming_race.dart';

/// Простой API сервис для предстоящих гонок
class SimpleUpcomingRacesApi extends BaseApiService {
  /// Получение предстоящих гонок
  Future<ApiResponse<UpcomingRacesResponse>> getUpcomingRaces({
    bool onlyFuture = true,
    int? userProfileId,
    int page = 1,
    String? search,
    String? country,
    String? raceType,
  }) async {
    await init();

    final queryParams = <String, dynamic>{
      'only_future': onlyFuture,
      'page': page,
    };

    if (userProfileId != null) queryParams['user_profile_id'] = userProfileId;
    if (search != null) queryParams['search'] = search;
    if (country != null) queryParams['country'] = country;
    if (raceType != null) queryParams['race_type'] = raceType;

    return client.get<UpcomingRacesResponse>(
      '/upcoming-races',
      queryParameters: queryParams,
      fromJson: (json) => UpcomingRacesResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Получение деталей гонки
  Future<ApiResponse<UpcomingRace>> getRaceDetails(int raceId) async {
    await init();

    return client.get<UpcomingRace>(
      '/upcoming-races/$raceId',
      fromJson: (json) => UpcomingRace.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Добавление гонки пользователя
  Future<ApiResponse<UpcomingRace>> addUserRace({
    required int raceId,
    required int userProfileId,
  }) async {
    await init();

    return client.post<UpcomingRace>(
      '/user-races',
      data: {
        'race_id': raceId,
        'user_profile_id': userProfileId,
      },
      fromJson: (json) => UpcomingRace.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Удаление гонки пользователя
  Future<ApiResponse<void>> removeUserRace({
    required int raceId,
    required int userProfileId,
  }) async {
    await init();

    return client.delete<void>(
      '/user-races',
      data: {
        'race_id': raceId,
        'user_profile_id': userProfileId,
      },
    );
  }

  /// Поиск гонок
  Future<ApiResponse<UpcomingRacesResponse>> searchRaces({
    required String query,
    int page = 1,
    String? country,
    String? raceType,
    bool onlyFuture = true,
  }) async {
    await init();

    final queryParams = <String, dynamic>{
      'search': query,
      'page': page,
      'only_future': onlyFuture,
    };

    if (country != null) queryParams['country'] = country;
    if (raceType != null) queryParams['race_type'] = raceType;

    return client.get<UpcomingRacesResponse>(
      '/upcoming-races/search',
      queryParameters: queryParams,
      fromJson: (json) => UpcomingRacesResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}

/// Ответ API с предстоящими гонками
class UpcomingRacesResponse {
  final List<UpcomingRace> races;
  final PaginationInfo pagination;

  const UpcomingRacesResponse({
    required this.races,
    required this.pagination,
  });

  factory UpcomingRacesResponse.fromJson(Map<String, dynamic> json) {
    return UpcomingRacesResponse(
      races: (json['data'] as List?)
          ?.map((item) => UpcomingRace.fromJson(item as Map<String, dynamic>))
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