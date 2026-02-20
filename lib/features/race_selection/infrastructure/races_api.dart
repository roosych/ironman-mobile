import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/errors/api_error_keys.dart';
import '../models/race_model.dart';

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
        throw const RacesApiException(
          localizationKey: ApiErrorKeys.emptyResponse,
        );
      }

      // Проверяем успешность запроса
      if (data['success'] == true && data['data'] != null) {
        final dataList = data['data'];

        // Проверяем, что data является List
        if (dataList is! List) {
          throw const RacesApiException(
            localizationKey: ApiErrorKeys.racesFormat,
          );
        }

        final List<dynamic> racesJson = dataList;
        return racesJson.map((json) {
          if (json is! Map<String, dynamic>) {
            throw const RacesApiException(
              localizationKey: ApiErrorKeys.raceItemFormat,
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
        throw const RacesApiException(
          localizationKey: ApiErrorKeys.timeout,
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const RacesApiException(
          localizationKey: ApiErrorKeys.networkNoConnection,
        );
      }

      // Более детальная информация об ошибке
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;

        // Пытаемся извлечь сообщение об ошибке из ответа
        if (errorData is Map && errorData['message'] != null) {
          throw RacesApiException(
            localizationKey: ApiErrorKeys.generic,
            parameters: {'message': errorData['message'] as String},
            originalMessage: errorData['message'] as String,
          );
        }

        throw RacesApiException(
          localizationKey: ApiErrorKeys.httpStatus,
          parameters: {'status': statusCode ?? 0},
          originalMessage: 'HTTP $statusCode',
        );
      }

      throw RacesApiException(
        localizationKey: ApiErrorKeys.generic,
        parameters: {'message': e.message ?? 'Unknown error'},
        originalMessage: e.message ?? 'Unknown error',
      );
    } catch (e) {
      // Обработка любых других исключений
      if (e is RacesApiException) {
        rethrow;
      }
      throw RacesApiException(
        localizationKey: ApiErrorKeys.unexpected,
        parameters: {'error': e.toString()},
        originalMessage: e.toString(),
      );
    }
  }
}