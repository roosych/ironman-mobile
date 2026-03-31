import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/race_result.dart';
import '../domain/paginated_response.dart';

class RaceResultsApiException implements Exception {
  final String message;

  RaceResultsApiException(this.message);

  @override
  String toString() => message;
}

class RaceResultsApi {
  final ApiClient _client;

  RaceResultsApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<RaceResult>> fetchResults(int userId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/users/$userId/race-results',
      );

      final data = response.data;
      if (data == null) {
        throw RaceResultsApiException('Empty server response');
      }

      if (data['success'] == true && data['data'] != null) {
        final dataList = data['data'];

        // Проверяем, что data является List
        if (dataList is! List) {
          throw RaceResultsApiException(
            'Ожидался список результатов, получен другой тип данных',
          );
        }

        final List<dynamic> resultsJson = dataList;
        return resultsJson.map((json) {
          if (json is! Map<String, dynamic>) {
            throw RaceResultsApiException(
              'Неверный формат элемента результата',
            );
          }
          return RaceResult.fromJson(json);
        }).toList();
      }

      // Если success != true, но нет ошибки, возвращаем пустой список
      return [];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw RaceResultsApiException('Request timeout');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw RaceResultsApiException('NETWORK_NO_CONNECTION');
      }

      // Более детальная информация об ошибке
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw RaceResultsApiException(errorData['message'] as String);
        }
        throw RaceResultsApiException(
          'Failed to load data (HTTP $statusCode)',
        );
      }

      throw RaceResultsApiException(
        'Failed to load data: ${e.message ?? 'Unknown error'}',
      );
    } catch (e) {
      if (e is RaceResultsApiException) {
        rethrow;
      }
      throw RaceResultsApiException('An error occurred: ${e.toString()}');
    }
  }

  Future<PaginatedResponse> fetchResultsByProfileId(int profileId, {int? page, bool onlyApproved = true}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) {
        queryParams['page'] = page;
      }
      if (onlyApproved) {
        queryParams['is_approved'] = 1;
      }
      final response = await _client.get<Map<String, dynamic>>(
        '/race-results/by-profile/$profileId',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final data = response.data;
      if (data == null) {
        throw RaceResultsApiException('Empty server response');
      }

      if (data['success'] == true && data['data'] != null) {
        final dataList = data['data'];

        // Проверяем, что data является List
        if (dataList is! List) {
          throw RaceResultsApiException(
            'Ожидался список результатов, получен другой тип данных',
          );
        }

        final List<dynamic> resultsJson = dataList;
        final results = resultsJson
            .map((json) {
          if (json is! Map<String, dynamic>) {
            throw RaceResultsApiException(
              'Неверный формат элемента результата',
            );
          }
          return RaceResult.fromJson(json);
            })
            .where((result) => onlyApproved ? result.isApproved : true)
            .toList();

        // Извлекаем мета-информацию о пагинации
        PaginationMeta meta;
        if (data['meta'] != null && data['meta'] is Map) {
          meta = PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>);
        } else {
          // Если мета нет, создаем дефолтную (все результаты на одной странице)
          meta = PaginationMeta(
            currentPage: page ?? 1,
            lastPage: 1,
            perPage: results.length,
            total: results.length,
          );
        }

        return PaginatedResponse(results: results, meta: meta);
      }

      // Если success != true, но нет ошибки, возвращаем пустой ответ
      return PaginatedResponse(
        results: [],
        meta: PaginationMeta(
          currentPage: page ?? 1,
          lastPage: 1,
          perPage: 15,
          total: 0,
        ),
      );
    } on DioException catch (e) {
      // Если профиль не найден (404), возвращаем пустой список - это нормальная ситуация
      if (e.response?.statusCode == 404) {
        return PaginatedResponse(
          results: [],
          meta: PaginationMeta(
            currentPage: page ?? 1,
            lastPage: 1,
            perPage: 15,
            total: 0,
          ),
        );
      }
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw RaceResultsApiException('Request timeout');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw RaceResultsApiException('NETWORK_NO_CONNECTION');
      }

      // Более детальная информация об ошибке
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw RaceResultsApiException(errorData['message'] as String);
        }
        throw RaceResultsApiException(
          'Failed to load data (HTTP $statusCode)',
        );
      }

      throw RaceResultsApiException(
        'Failed to load data: ${e.message ?? 'Unknown error'}',
      );
    } catch (e) {
      if (e is RaceResultsApiException) {
        rethrow;
      }
      throw RaceResultsApiException('An error occurred: ${e.toString()}');
    }
  }

  Future<PaginatedResponse> fetchAllResults({int? page, bool onlyApproved = true, String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) {
        queryParams['page'] = page;
      }
      if (onlyApproved) {
        queryParams['is_approved'] = 1;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await _client.get<Map<String, dynamic>>(
        '/race-results',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final data = response.data;
      if (data == null) {
        throw RaceResultsApiException('Empty server response');
      }

      if (data['success'] == true && data['data'] != null) {
        final dataList = data['data'];

        // Проверяем, что data является List
        if (dataList is! List) {
          throw RaceResultsApiException(
            'Ожидался список результатов, получен другой тип данных',
          );
        }

        final List<dynamic> resultsJson = dataList;
        final results = resultsJson
            .map((json) {
          if (json is! Map<String, dynamic>) {
            throw RaceResultsApiException(
              'Неверный формат элемента результата',
            );
          }
          return RaceResult.fromJson(json);
            })
            .where((result) => onlyApproved ? result.isApproved : true)
            .toList();

        // Извлекаем мета-информацию о пагинации
        PaginationMeta meta;
        if (data['meta'] != null && data['meta'] is Map) {
          meta = PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>);
        } else {
          // Если мета нет, создаем дефолтную (все результаты на одной странице)
          meta = PaginationMeta(
            currentPage: page ?? 1,
            lastPage: 1,
            perPage: results.length,
            total: results.length,
          );
        }

        return PaginatedResponse(results: results, meta: meta);
      }

      // Если success != true, но нет ошибки, возвращаем пустой ответ
      return PaginatedResponse(
        results: [],
        meta: PaginationMeta(
          currentPage: page ?? 1,
          lastPage: 1,
          perPage: 15,
          total: 0,
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw RaceResultsApiException('Request timeout');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw RaceResultsApiException('NETWORK_NO_CONNECTION');
      }

      // Более детальная информация об ошибке
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw RaceResultsApiException(errorData['message'] as String);
        }
        throw RaceResultsApiException(
          'Failed to load data (HTTP $statusCode)',
        );
      }

      throw RaceResultsApiException(
        'Failed to load data: ${e.message ?? 'Unknown error'}',
      );
    } catch (e) {
      if (e is RaceResultsApiException) {
        rethrow;
      }
      throw RaceResultsApiException('An error occurred: ${e.toString()}');
    }
  }

  /// Создать новый результат гонки
  /// 
  /// [raceDate] - дата гонки в формате 'YYYY-MM-DD'
  /// [location] - локация гонки
  /// [raceType] - тип гонки (например, 'ironman', 'ironman_70_3', '5150')
  /// [swimTime] - время плавания в секундах (int)
  /// [t1Time] - время первого перехода в секундах (int)
  /// [bikeTime] - время велосипеда в секундах (int)
  /// [t2Time] - время второго перехода в секундах (int)
  /// [runTime] - время бега в секундах (int)
  /// [totalTime] - общее время в секундах (int)
  /// [ageGroup] - возрастная группа (опционально)
  /// [overallPosition] - общая позиция (опционально)
  /// [ageGroupPosition] - позиция в возрастной группе (опционально)
  Future<RaceResult> createRaceResult({
    required String raceDate,
    required String location,
    required String raceType,
    required int swimTime,
    required int t1Time,
    required int bikeTime,
    required int t2Time,
    required int runTime,
    required int totalTime,
    String? ageGroup,
    int? overallPosition,
    int? ageGroupPosition,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/race-results',
        data: {
          'race_date': raceDate,
          'location': location,
          'race_type': raceType,
          'swim_time': swimTime,
          't1_time': t1Time,
          'bike_time': bikeTime,
          't2_time': t2Time,
          'run_time': runTime,
          'total_time': totalTime,
          if (ageGroup != null) 'age_group': ageGroup,
          if (overallPosition != null) 'overall_position': overallPosition,
          if (ageGroupPosition != null) 'age_group_position': ageGroupPosition,
        },
      );

      final data = response.data;
      if (data == null) {
        throw RaceResultsApiException('Empty server response');
      }

      if (data['success'] == true && data['data'] != null) {
        final resultJson = data['data'];
        if (resultJson is! Map<String, dynamic>) {
          throw RaceResultsApiException(
            'Ожидался объект результата, получен другой тип данных',
          );
        }
        return RaceResult.fromJson(resultJson);
      }

      // Если success != true, пытаемся извлечь сообщение об ошибке
      final errorMessage = data['message'] as String? ?? 
          'Failed to create result';
      throw RaceResultsApiException(errorMessage);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw RaceResultsApiException('Request timeout');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw RaceResultsApiException('NETWORK_NO_CONNECTION');
      }

      // Более детальная информация об ошибке
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw RaceResultsApiException(errorData['message'] as String);
        }
        throw RaceResultsApiException(
          'Failed to create result (HTTP $statusCode)',
        );
      }

      throw RaceResultsApiException(
        'Failed to create result: ${e.message ?? 'Unknown error'}',
      );
    } catch (e) {
      if (e is RaceResultsApiException) {
        rethrow;
      }
      throw RaceResultsApiException('An error occurred: ${e.toString()}');
    }
  }
}
