import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/errors/api_error_keys.dart';
import '../models/transfer_request_model.dart';
import '../models/eligible_athlete_model.dart';

/// API сервис для операций переноса результатов
class TransferApi {
  final ApiClient _client;

  TransferApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Helper метод для создания TransferApiException из DioException
  TransferApiException _handleDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // Обработка специфичных ошибок переноса
    if (statusCode == 409 && data != null && data['message'] != null) {
      return TransferApiException(
        localizationKey: ApiErrorKeys.transferConflict,
        originalMessage: data['message']?.toString(),
      );
    }

    if (statusCode == 422 && data != null) {
      // Ошибки валидации
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map<String, dynamic>;
        final fieldErrors = <String, List<String>>{};

        errors.forEach((field, messages) {
          if (messages is List) {
            fieldErrors[field] = messages.map((m) => m.toString()).toList();
          }
        });

        final message = data['message']?.toString() ?? 'Validation error';
        return TransferApiException(
          localizationKey: ApiErrorKeys.transferValidation,
          originalMessage: message,
          fieldErrors: fieldErrors,
        );
      }
    }

    // Обработка типов DioException
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const TransferApiException(
          localizationKey: ApiErrorKeys.timeout,
        );

      case DioExceptionType.connectionError:
        return const TransferApiException(
          localizationKey: ApiErrorKeys.networkNoConnection,
        );

      case DioExceptionType.badResponse:
        final message = data?['message']?.toString();
        if (message != null) {
          return TransferApiException(
            localizationKey: ApiErrorKeys.generic,
            parameters: {'message': message},
            originalMessage: message,
          );
        }
        return TransferApiException(
          localizationKey: ApiErrorKeys.server,
          parameters: {'status': statusCode?.toString() ?? 'Unknown'},
          originalMessage: 'Server error ($statusCode)',
        );

      default:
        return const TransferApiException(
          localizationKey: ApiErrorKeys.transferServerError,
        );
    }
  }

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

      throw _handleDioException(e);
    } catch (e) {
      if (e is TransferApiException) {
        rethrow;
      }
      throw TransferApiException(
        localizationKey: ApiErrorKeys.unexpected,
        parameters: {'error': e.toString()},
        originalMessage: 'An error occurred: ${e.toString()}',
      );
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
        throw const TransferApiException(
          localizationKey: ApiErrorKeys.emptyResponse,
        );
      }

      if (data['success'] == true && data['data'] != null) {
        final dataList = data['data'];

        // Проверяем, что data является List
        if (dataList is! List) {
          throw const TransferApiException(
            localizationKey: ApiErrorKeys.athletesFormat,
          );
        }

        final List<dynamic> athletesJson = dataList;
        return athletesJson.map((json) {
          if (json is! Map<String, dynamic>) {
            throw const TransferApiException(
              localizationKey: ApiErrorKeys.athleteItemFormat,
            );
          }
          return EligibleAthleteModel.fromJson(json);
        }).toList();
      }

      // Если success != true, возвращаем пустой список
      return [];
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is TransferApiException) {
        rethrow;
      }
      throw TransferApiException(
        localizationKey: ApiErrorKeys.athletesLoading,
        originalMessage: e.toString(),
      );
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
        throw const TransferApiException(
          localizationKey: ApiErrorKeys.emptyResponse,
        );
      }

      if (data['success'] == true && data['data'] != null) {
        final requestData = data['data'] as Map<String, dynamic>;
        return TransferRequestModel.fromJson(requestData);
      }

      // Если success != true, это ошибка
      final message = data['message'] as String? ?? 'Failed to create request';
      throw TransferApiException(
        localizationKey: ApiErrorKeys.generic,
        parameters: {'message': message},
        originalMessage: message,
      );
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
        throw TransferApiException(
          localizationKey: ApiErrorKeys.transferConflict,
          originalMessage: message,
        );
      }

      throw _handleDioException(e);
    } catch (e) {
      if (e is TransferApiException) {
        rethrow;
      }
      throw TransferApiException(
        localizationKey: ApiErrorKeys.transferCreateFailed,
        originalMessage: 'Failed to create transfer request: ${e.toString()}',
      );
    }
  }
}