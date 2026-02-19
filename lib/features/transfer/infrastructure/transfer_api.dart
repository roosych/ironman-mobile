import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/transfer_request_model.dart';
import '../models/eligible_athlete_model.dart';
import 'transfer_api_exception.dart';

/// API сервис для операций переноса результатов
class TransferApi {
  final ApiClient _client;

  TransferApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Получить текущий статус заявки на перенос
  ///
  /// Returns:
  /// - TransferRequestModel если есть активная заявка
  /// - null если нет активной заявки
  ///
  /// Throws:
  /// - TransferApiException при ошибках API
  Future<TransferRequestModel?> getCurrentTransferStatus() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/transfer/current',
      );

      final data = response.data;
      if (data == null) {
        return null;
      }

      // Если success == true и есть data, значит есть активная заявка
      if (data['success'] == true && data['data'] != null) {
        final requestData = data['data'] as Map<String, dynamic>;
        return TransferRequestModel.fromJson(requestData);
      }

      // Если success == true но data == null, значит нет заявки
      return null;
    } on DioException catch (e) {
      // 404 означает, что нет активной заявки
      if (e.response?.statusCode == 404) {
        return null;
      }

      // 401 означает, что нет доступа к функции переноса или токен недействителен
      // Обрабатываем как "нет заявки" - покажется кнопка "Attach Results"
      if (e.response?.statusCode == 401) {
        return null;
      }

      throw TransferApiException.fromDioException(e);
    } catch (e) {
      if (e is TransferApiException) {
        rethrow;
      }
      throw TransferApiException('Произошла ошибка: ${e.toString()}');
    }
  }

  /// Получить список доступных атлетов для переноса результатов
  ///
  /// Parameters:
  /// - search: Поисковый запрос (опционально)
  ///
  /// Returns:
  /// - Список атлетов-доноров
  ///
  /// Throws:
  /// - TransferApiException при ошибках API
  Future<List<EligibleAthleteModel>> getEligibleAthletes({String search = ''}) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _client.get<Map<String, dynamic>>(
        '/transfer/eligible-athletes',
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      final data = response.data;
      if (data == null) {
        throw const TransferApiException('Пустой ответ от сервера');
      }

      if (data['success'] == true && data['data'] != null) {
        final dataList = data['data'];

        // Проверяем, что data является List
        if (dataList is! List) {
          throw const TransferApiException(
            'Ожидался список атлетов, получен другой тип данных',
          );
        }

        final List<dynamic> athletesJson = dataList;
        return athletesJson.map((json) {
          if (json is! Map<String, dynamic>) {
            throw const TransferApiException(
              'Неверный формат элемента атлета',
            );
          }
          return EligibleAthleteModel.fromJson(json);
        }).toList();
      }

      // Если success != true, возвращаем пустой список
      return [];
    } on DioException catch (e) {
      throw TransferApiException.fromDioException(e);
    } catch (e) {
      if (e is TransferApiException) {
        rethrow;
      }
      throw TransferApiException('Произошла ошибка при поиске атлетов: ${e.toString()}');
    }
  }

  /// Создать заявку на перенос результатов
  ///
  /// Parameters:
  /// - sourceAthleteId: ID атлета-источника результатов
  ///
  /// Returns:
  /// - Созданная заявка
  ///
  /// Throws:
  /// - TransferApiException при ошибках API (включая дублирование заявок)
  Future<TransferRequestModel> createTransferRequest(int sourceAthleteId) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/transfer/request',
        data: {
          'source_athlete_id': sourceAthleteId,
        },
      );

      final data = response.data;
      if (data == null) {
        throw const TransferApiException('Пустой ответ от сервера');
      }

      if (data['success'] == true && data['data'] != null) {
        final requestData = data['data'] as Map<String, dynamic>;
        return TransferRequestModel.fromJson(requestData);
      }

      // Если success != true, это ошибка
      final message = data['message'] as String? ?? 'Не удалось создать заявку';
      throw TransferApiException(message);
    } on DioException catch (e) {
      // Специфичная обработка конфликтов (409 - уже есть активная заявка)
      if (e.response?.statusCode == 409) {
        final data = e.response?.data;

        // Пытаемся извлечь данные существующей заявки из ответа сервера
        if (data != null && data['data'] != null) {
          debugPrint('🔍 409 ответ содержит данные существующей заявки, возвращаем её');
          try {
            final requestData = data['data'] as Map<String, dynamic>;
            return TransferRequestModel.fromJson(requestData);
          } catch (e) {
            debugPrint('❌ Ошибка парсинга данных заявки из 409 ответа: $e');
          }
        }

        final message = data?['message']?.toString() ?? 'У вас уже есть активная заявка на перенос';
        throw TransferApiException(message);
      }

      throw TransferApiException.fromDioException(e);
    } catch (e) {
      if (e is TransferApiException) {
        rethrow;
      }
      throw TransferApiException('Произошла ошибка при создании заявки: ${e.toString()}');
    }
  }
}