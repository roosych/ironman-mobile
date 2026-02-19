import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/upcoming_race.dart';

class UpcomingRacesApiException implements Exception {
  final String message;

  UpcomingRacesApiException(this.message);

  @override
  String toString() => message;
}

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
        '/upcoming-races',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final data = response.data;
      if (data == null) {
        throw UpcomingRacesApiException('Пустой ответ от сервера');
      }

      if (data['success'] == true && data['data'] != null) {
        final dataList = data['data'];

        // Проверяем, что data является List
        if (dataList is! List) {
          throw UpcomingRacesApiException(
            'Ожидался список гонок, получен другой тип данных',
          );
        }

        final List<dynamic> racesJson = dataList;
        return racesJson.map((json) {
          if (json is! Map<String, dynamic>) {
            throw UpcomingRacesApiException(
              'Неверный формат элемента гонки',
            );
          }
          return UpcomingRace.fromJson(json);
        }).toList();
      }

      // Если success != true, но нет ошибки, возвращаем пустой список
      return [];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw UpcomingRacesApiException('Превышено время ожидания');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw UpcomingRacesApiException('NETWORK_NO_CONNECTION');
      }

      // Более детальная информация об ошибке
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw UpcomingRacesApiException(errorData['message'] as String);
        }
        throw UpcomingRacesApiException(
          'Ошибка загрузки данных (HTTP $statusCode)',
        );
      }

      throw UpcomingRacesApiException(
        'Ошибка загрузки данных: ${e.message ?? 'Неизвестная ошибка'}',
      );
    } catch (e) {
      if (e is UpcomingRacesApiException) {
        rethrow;
      }
      throw UpcomingRacesApiException('Произошла ошибка: ${e.toString()}');
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
        '/upcoming-races',
        data: {
          'race_id': raceId,
        },
      );

      final data = response.data;
      if (data == null) {
        throw UpcomingRacesApiException('Пустой ответ от сервера');
      }

      if (data['success'] == true && data['data'] != null) {
        final raceJson = data['data'];
        if (raceJson is! Map<String, dynamic>) {
          throw UpcomingRacesApiException(
            'Ожидался объект гонки, получен другой тип данных',
          );
        }
        return UpcomingRace.fromJson(raceJson);
      }

      // Если success != true, пытаемся извлечь сообщение об ошибке
      if (data['message'] != null) {
        throw UpcomingRacesApiException(data['message'] as String);
      }
      if (data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw UpcomingRacesApiException(firstError.first as String);
          }
        }
      }

      throw UpcomingRacesApiException('Не удалось создать гонку');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw UpcomingRacesApiException('Превышено время ожидания');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw UpcomingRacesApiException('NETWORK_NO_CONNECTION');
      }

      // Более детальная информация об ошибке
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw UpcomingRacesApiException(errorData['message'] as String);
        }
        if (errorData is Map && errorData['errors'] != null) {
          final errors = errorData['errors'] as Map<String, dynamic>?;
          if (errors != null && errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              throw UpcomingRacesApiException(firstError.first as String);
            }
          }
        }
        throw UpcomingRacesApiException(
          'Ошибка создания гонки (HTTP $statusCode)',
        );
      }

      throw UpcomingRacesApiException(
        'Ошибка создания гонки: ${e.message ?? 'Неизвестная ошибка'}',
      );
    } catch (e) {
      if (e is UpcomingRacesApiException) {
        rethrow;
      }
      throw UpcomingRacesApiException('Произошла ошибка: ${e.toString()}');
    }
  }
}

