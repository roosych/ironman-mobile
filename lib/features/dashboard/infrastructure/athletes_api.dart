import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/athlete.dart';
import '../domain/personal_record.dart';

class AthletesApiException implements Exception {
  final String message;

  AthletesApiException(this.message);

  @override
  String toString() => message;
}

class AthletesApi {
  final ApiClient _client;

  AthletesApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Athlete>> fetchAthletes() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/athletes',
      );

      final data = response.data;
      if (data == null) {
        throw AthletesApiException('Пустой ответ от сервера');
      }

      if (data['success'] == true && data['data'] != null) {
        final dataList = data['data'];

        // Проверяем, что data является List
        if (dataList is! List) {
          throw AthletesApiException(
            'Ожидался список атлетов, получен другой тип данных',
          );
        }

        final List<dynamic> athletesJson = dataList;
        return athletesJson.map((json) {
          if (json is! Map<String, dynamic>) {
            throw AthletesApiException(
              'Неверный формат элемента атлета',
            );
          }
          return Athlete.fromJson(json);
        }).toList();
      }

      // Если success != true, но нет ошибки, возвращаем пустой список
      return [];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw AthletesApiException('Превышено время ожидания');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw AthletesApiException('NETWORK_NO_CONNECTION');
      }
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'] as String?;
      throw AthletesApiException(
        message ?? 'Ошибка сервера ($statusCode)',
      );
    } catch (e) {
      if (e is AthletesApiException) {
        rethrow;
      }
      throw AthletesApiException('Произошла ошибка: ${e.toString()}');
    }
  }

  Future<Athlete> fetchAthleteById(int athleteId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/athletes/$athleteId',
      );

      final data = response.data;
      if (data == null) {
        throw AthletesApiException('Пустой ответ от сервера');
      }

      if (data['success'] == true && data['data'] != null) {
        final athleteData = data['data'];
        if (athleteData is! Map<String, dynamic>) {
          throw AthletesApiException(
            'Ожидался объект атлета, получен другой тип данных',
          );
        }
        return Athlete.fromJson(athleteData);
      }

      throw AthletesApiException('Не удалось получить данные атлета');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw AthletesApiException('Превышено время ожидания');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw AthletesApiException('NETWORK_NO_CONNECTION');
      }
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'] as String?;
      throw AthletesApiException(
        message ?? 'Ошибка сервера ($statusCode)',
      );
    } catch (e) {
      if (e is AthletesApiException) {
        rethrow;
      }
      throw AthletesApiException('Произошла ошибка: ${e.toString()}');
    }
  }

  Future<Records> fetchRecords(int athleteId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/athletes/$athleteId/records',
      );

      final data = response.data;
      if (data == null) {
        throw AthletesApiException('Пустой ответ от сервера');
      }

      if (data['success'] == true && data['data'] != null) {
        final recordsData = data['data'];
        if (recordsData is! Map<String, dynamic>) {
          throw AthletesApiException(
            'Ожидался объект records, получен другой тип данных',
          );
        }
        return Records.fromJson(recordsData);
      }

      throw AthletesApiException('Не удалось получить данные records');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw AthletesApiException('Превышено время ожидания');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw AthletesApiException('NETWORK_NO_CONNECTION');
      }
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'] as String?;
      throw AthletesApiException(
        message ?? 'Ошибка сервера ($statusCode)',
      );
    } catch (e) {
      if (e is AthletesApiException) {
        rethrow;
      }
      throw AthletesApiException('Произошла ошибка: ${e.toString()}');
    }
  }
}

