import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/race_model.dart';

/// API исключения для работы с гонками
class RacesApiException implements Exception {
  final String message;

  RacesApiException(this.message);

  @override
  String toString() => message;
}

/// API слой для получения доступных гонок
class RacesApi {
  final ApiClient _client;

  RacesApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Получить список доступных гонок из API /races
  ///
  /// Загружает все активные гонки, доступные для выбора пользователем.
  /// Требует авторизации через Bearer token.
  Future<List<RaceModel>> fetchAvailableRaces() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/races',
      );

      final data = response.data;
      if (data == null) {
        throw RacesApiException('Пустой ответ от сервера');
      }

      // Проверяем успешность запроса
      if (data['success'] == true && data['data'] != null) {
        final dataList = data['data'];

        // Проверяем, что data является List
        if (dataList is! List) {
          throw RacesApiException(
            'Ожидался список гонок, получен другой тип данных',
          );
        }

        final List<dynamic> racesJson = dataList;
        return racesJson.map((json) {
          if (json is! Map<String, dynamic>) {
            throw RacesApiException(
              'Неверный формат элемента гонки',
            );
          }
          return RaceModel.fromJson(json);
        }).toList();
      }

      // Если success != true, но нет ошибки, возвращаем пустой список
      return [];
    } on DioException catch (e) {
      // Обработка сетевых ошибок
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw RacesApiException('Превышено время ожидания');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw RacesApiException('NETWORK_NO_CONNECTION');
      }

      // Более детальная информация об ошибке
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;

        // Пытаемся извлечь сообщение об ошибке из ответа
        if (errorData is Map && errorData['message'] != null) {
          throw RacesApiException(errorData['message'] as String);
        }

        throw RacesApiException(
          'Ошибка загрузки данных (HTTP $statusCode)',
        );
      }

      throw RacesApiException(
        'Ошибка загрузки данных: ${e.message ?? 'Неизвестная ошибка'}',
      );
    } catch (e) {
      // Обработка любых других исключений
      if (e is RacesApiException) {
        rethrow;
      }
      throw RacesApiException('Произошла ошибка: ${e.toString()}');
    }
  }
}