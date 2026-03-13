import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/errors/api_error_keys.dart';
import '../domain/upcoming_race.dart';
import '../domain/upcoming_races_response.dart';

class UpcomingRacesApi {
  final ApiClient _client;

  UpcomingRacesApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Получить список предстоящих гонок
  ///
  /// [userProfileId] - фильтр по ID профиля пользователя
  /// [raceType] - фильтр по типу гонки (например, 'ironman')
  /// [onlyFuture] - если true, показывать только будущие гонки (по умолчанию true)
  ///                если false, показывать все гонки (будущие и прошедшие)
  Future<List<UpcomingRace>> fetchUpcomingRaces({
    int? userProfileId,
    String? raceType,
    bool onlyFuture = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userProfileId != null) {
        queryParams['user_profile_id'] = userProfileId;
      }
      if (raceType != null && raceType.isNotEmpty) {
        queryParams['race_type'] = raceType;
      }
      // Добавляем параметр only_future (по умолчанию true для обратной совместимости)
      queryParams['only_future'] = onlyFuture;

      final response = await _client.get<Map<String, dynamic>>(
        '/races/upcoming',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final data = response.data;
      if (data == null) {
        throw const UpcomingRacesApiException(
          localizationKey: ApiErrorKeys.emptyResponse,
        );
      }

      // Обновленный формат ответа с success и meta
      if (data['success'] == true && data['data'] != null) {
        try {
          final racesResponse = UpcomingRacesResponse.fromJson(data);
          return racesResponse.data;
        } catch (e) {
          throw UpcomingRacesApiException(
            localizationKey: ApiErrorKeys.invalidDataFormat,
            parameters: {'error': e.toString()},
            originalMessage: 'Invalid response format: ${e.toString()}',
          );
        }
      }

      // Если success != true, но нет ошибки, возвращаем пустой список
      return [];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const UpcomingRacesApiException(
          localizationKey: ApiErrorKeys.timeout,
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const UpcomingRacesApiException(
          localizationKey: ApiErrorKeys.networkNoConnection,
        );
      }

      // Более детальная информация об ошибке
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw UpcomingRacesApiException(
            localizationKey: ApiErrorKeys.generic,
            parameters: {'message': errorData['message'] as String},
            originalMessage: errorData['message'] as String,
          );
        }
        throw UpcomingRacesApiException(
          localizationKey: ApiErrorKeys.httpStatus,
          parameters: {'status': statusCode ?? 0},
          originalMessage: 'HTTP $statusCode',
        );
      }

      throw UpcomingRacesApiException(
        localizationKey: ApiErrorKeys.generic,
        parameters: {'message': e.message ?? 'Unknown error'},
        originalMessage: e.message ?? 'Unknown error',
      );
    } catch (e) {
      if (e is UpcomingRacesApiException) {
        rethrow;
      }
      throw UpcomingRacesApiException(
        localizationKey: ApiErrorKeys.unexpected,
        parameters: {'error': e.toString()},
        originalMessage: e.toString(),
      );
    }
  }

  /// Получить пагинированный ответ со всеми данными (links, meta)
  ///
  /// [userProfileId] - фильтр по ID профиля пользователя
  /// [raceType] - фильтр по типу гонки (например, 'ironman_70_3')
  /// [onlyFuture] - если true, показывать только будущие гонки (по умолчанию true)
  /// [page] - номер страницы для пагинации
  Future<UpcomingRacesResponse> fetchUpcomingRacesWithPagination({
    int? userProfileId,
    String? raceType,
    bool onlyFuture = true,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userProfileId != null) {
        queryParams['user_profile_id'] = userProfileId;
      }
      if (raceType != null && raceType.isNotEmpty) {
        queryParams['race_type'] = raceType;
      }
      queryParams['only_future'] = onlyFuture;
      queryParams['page'] = page;

      final response = await _client.get<Map<String, dynamic>>(
        '/races/upcoming',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data == null) {
        throw const UpcomingRacesApiException(
          localizationKey: ApiErrorKeys.emptyResponse,
        );
      }

      return UpcomingRacesResponse.fromJson(data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const UpcomingRacesApiException(
          localizationKey: ApiErrorKeys.timeout,
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const UpcomingRacesApiException(
          localizationKey: ApiErrorKeys.networkNoConnection,
        );
      }

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw UpcomingRacesApiException(
            localizationKey: ApiErrorKeys.generic,
            parameters: {'message': errorData['message'] as String},
            originalMessage: errorData['message'] as String,
          );
        }
        throw UpcomingRacesApiException(
          localizationKey: ApiErrorKeys.httpStatus,
          parameters: {'status': statusCode ?? 0},
          originalMessage: 'HTTP $statusCode',
        );
      }

      throw UpcomingRacesApiException(
        localizationKey: ApiErrorKeys.generic,
        parameters: {'message': e.message ?? 'Unknown error'},
        originalMessage: e.message ?? 'Unknown error',
      );
    } catch (e) {
      if (e is UpcomingRacesApiException) {
        rethrow;
      }
      throw UpcomingRacesApiException(
        localizationKey: ApiErrorKeys.unexpected,
        parameters: {'error': e.toString()},
        originalMessage: e.toString(),
      );
    }
  }

  /// Создать новую предстоящую гонку
  ///
  /// [raceId] - ID гонки из таблицы races
  Future<UpcomingRace> createUpcomingRace({
    required int raceId,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/races/upcoming',
        data: {
          'race_id': raceId,
        },
      );

      final data = response.data;
      if (data == null) {
        throw const UpcomingRacesApiException(
          localizationKey: ApiErrorKeys.emptyResponse,
        );
      }

      if (data['success'] == true && data['data'] != null) {
        final dataJson = data['data'];
        if (dataJson is! Map<String, dynamic>) {
          throw const UpcomingRacesApiException(
            localizationKey: ApiErrorKeys.upcomingRaceObjectFormat,
          );
        }
        final raceJson = dataJson['race'] as Map<String, dynamic>?;
        if (raceJson == null) {
          throw const UpcomingRacesApiException(
            localizationKey: ApiErrorKeys.upcomingRaceObjectFormat,
          );
        }
        return UpcomingRace(
          id: dataJson['id'] as int? ?? 0,
          raceType: raceJson['type'] as String? ?? '',
          raceTypeLabel: raceJson['type_label'] as String? ?? '',
          location: raceJson['location'] as String? ?? '',
          raceDate: raceJson['date'] as String? ?? '',
          countryIso: raceJson['country_iso'] as String?,
          isActive: true,
        );
      }

      // Если success != true, пытаемся извлечь сообщение об ошибке
      if (data['message'] != null) {
        throw UpcomingRacesApiException(
          localizationKey: ApiErrorKeys.generic,
          parameters: {'message': data['message'] as String},
          originalMessage: data['message'] as String,
        );
      }
      if (data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw UpcomingRacesApiException(
              localizationKey: ApiErrorKeys.generic,
              parameters: {'message': firstError.first as String},
              originalMessage: firstError.first as String,
            );
          }
        }
      }

      throw const UpcomingRacesApiException(
        localizationKey: ApiErrorKeys.upcomingRaceCreateFailed,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const UpcomingRacesApiException(
          localizationKey: ApiErrorKeys.timeout,
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const UpcomingRacesApiException(
          localizationKey: ApiErrorKeys.networkNoConnection,
        );
      }

      // Более детальная информация об ошибке
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw UpcomingRacesApiException(
            localizationKey: ApiErrorKeys.generic,
            parameters: {'message': errorData['message'] as String},
            originalMessage: errorData['message'] as String,
          );
        }
        if (errorData is Map && errorData['errors'] != null) {
          final errors = errorData['errors'] as Map<String, dynamic>?;
          if (errors != null && errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              throw UpcomingRacesApiException(
                localizationKey: ApiErrorKeys.generic,
                parameters: {'message': firstError.first as String},
                originalMessage: firstError.first as String,
              );
            }
          }
        }
        throw UpcomingRacesApiException(
          localizationKey: ApiErrorKeys.httpStatus,
          parameters: {'status': statusCode ?? 0},
          originalMessage: 'HTTP $statusCode',
        );
      }

      throw UpcomingRacesApiException(
        localizationKey: ApiErrorKeys.generic,
        parameters: {'message': e.message ?? 'Unknown error'},
        originalMessage: e.message ?? 'Unknown error',
      );
    } catch (e) {
      if (e is UpcomingRacesApiException) {
        rethrow;
      }
      throw UpcomingRacesApiException(
        localizationKey: ApiErrorKeys.unexpected,
        parameters: {'error': e.toString()},
        originalMessage: e.toString(),
      );
    }
  }
}

