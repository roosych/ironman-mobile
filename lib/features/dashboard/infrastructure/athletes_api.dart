import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/errors/api_error_keys.dart';
import '../domain/athlete.dart';
import '../domain/personal_record.dart';
import '../domain/photo.dart';

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
        throw const AthletesApiException(
          localizationKey: ApiErrorKeys.emptyResponse,
        );
      }

      if (data['success'] == true && data['data'] != null) {
        final dataList = data['data'];

        // Проверяем, что data является List
        if (dataList is! List) {
          throw const AthletesApiException(
            localizationKey: ApiErrorKeys.athletesFormat,
          );
        }

        final List<dynamic> athletesJson = dataList;
        return athletesJson.map((json) {
          if (json is! Map<String, dynamic>) {
            throw const AthletesApiException(
              localizationKey: ApiErrorKeys.athleteItemFormat,
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
        throw const AthletesApiException(
          localizationKey: ApiErrorKeys.timeout,
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const AthletesApiException(
          localizationKey: ApiErrorKeys.networkNoConnection,
        );
      }
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'] as String?;
      if (message != null) {
        throw AthletesApiException(
          localizationKey: ApiErrorKeys.generic,
          parameters: {'message': message},
          originalMessage: message,
        );
      }
      throw AthletesApiException(
        localizationKey: ApiErrorKeys.server,
        parameters: {'status': statusCode?.toString() ?? 'Unknown'},
        originalMessage: 'Server error ($statusCode)',
      );
    } catch (e) {
      if (e is AthletesApiException) {
        rethrow;
      }
      throw AthletesApiException(
        localizationKey: ApiErrorKeys.unexpected,
        parameters: {'error': e.toString()},
        originalMessage: e.toString(),
      );
    }
  }

  Future<Athlete> fetchAthleteById(int athleteId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/athletes/$athleteId',
      );

      final data = response.data;
      if (data == null) {
        throw const AthletesApiException(
          localizationKey: ApiErrorKeys.emptyResponse,
        );
      }

      if (data['success'] == true && data['data'] != null) {
        final athleteData = data['data'];
        if (athleteData is! Map<String, dynamic>) {
          throw const AthletesApiException(
            localizationKey: ApiErrorKeys.athleteObjectFormat,
          );
        }
        debugPrint('🔍 athlete detail raw: $athleteData');
        return Athlete.fromJson(athleteData);
      }

      throw const AthletesApiException(
        localizationKey: ApiErrorKeys.athleteNotFound,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const AthletesApiException(
          localizationKey: ApiErrorKeys.timeout,
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const AthletesApiException(
          localizationKey: ApiErrorKeys.networkNoConnection,
        );
      }
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'] as String?;
      if (message != null) {
        throw AthletesApiException(
          localizationKey: ApiErrorKeys.generic,
          parameters: {'message': message},
          originalMessage: message,
        );
      }
      throw AthletesApiException(
        localizationKey: ApiErrorKeys.server,
        parameters: {'status': statusCode?.toString() ?? 'Unknown'},
        originalMessage: 'Server error ($statusCode)',
      );
    } catch (e) {
      if (e is AthletesApiException) {
        rethrow;
      }
      throw AthletesApiException(
        localizationKey: ApiErrorKeys.unexpected,
        parameters: {'error': e.toString()},
        originalMessage: e.toString(),
      );
    }
  }

  Future<({List<Photo> photos, bool hasMore, int currentPage, int lastPage})> fetchAthletePhotos(
    int athleteId, {
    int page = 1,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/athletes/$athleteId/photos',
        queryParameters: {'page': page},
      );

      final data = response.data;
      if (data == null) {
        throw const AthletesApiException(
          localizationKey: ApiErrorKeys.emptyResponse,
        );
      }

      if (data['success'] == false) {
        throw const AthletesApiException(
          localizationKey: ApiErrorKeys.athleteNotFound,
        );
      }

      final List<dynamic> photosJson = data['data'] as List<dynamic>? ?? [];
      final photos = photosJson
          .whereType<Map<String, dynamic>>()
          .map(Photo.fromJson)
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>?;
      final currentPage = pagination?['current_page'] as int? ?? 1;
      final lastPage = pagination?['last_page'] as int? ?? 1;

      return (
        photos: photos,
        hasMore: currentPage < lastPage,
        currentPage: currentPage,
        lastPage: lastPage,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const AthletesApiException(
          localizationKey: ApiErrorKeys.timeout,
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const AthletesApiException(
          localizationKey: ApiErrorKeys.networkNoConnection,
        );
      }
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'] as String?;
      if (message != null) {
        throw AthletesApiException(
          localizationKey: ApiErrorKeys.generic,
          parameters: {'message': message},
          originalMessage: message,
        );
      }
      throw AthletesApiException(
        localizationKey: ApiErrorKeys.server,
        parameters: {'status': statusCode?.toString() ?? 'Unknown'},
        originalMessage: 'Server error ($statusCode)',
      );
    } catch (e) {
      if (e is AthletesApiException) rethrow;
      throw AthletesApiException(
        localizationKey: ApiErrorKeys.unexpected,
        parameters: {'error': e.toString()},
        originalMessage: e.toString(),
      );
    }
  }

  Future<Records> fetchRecords(int athleteId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/athletes/$athleteId/records',
      );

      final data = response.data;
      if (data == null) {
        throw const AthletesApiException(
          localizationKey: ApiErrorKeys.emptyResponse,
        );
      }

      if (data['success'] == true && data['data'] != null) {
        final recordsData = data['data'];
        if (recordsData is! Map<String, dynamic>) {
          throw const AthletesApiException(
            localizationKey: ApiErrorKeys.recordsObjectFormat,
          );
        }
        return Records.fromJson(recordsData);
      }

      throw const AthletesApiException(
        localizationKey: ApiErrorKeys.recordsNotFound,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const AthletesApiException(
          localizationKey: ApiErrorKeys.timeout,
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const AthletesApiException(
          localizationKey: ApiErrorKeys.networkNoConnection,
        );
      }
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'] as String?;
      if (message != null) {
        throw AthletesApiException(
          localizationKey: ApiErrorKeys.generic,
          parameters: {'message': message},
          originalMessage: message,
        );
      }
      throw AthletesApiException(
        localizationKey: ApiErrorKeys.server,
        parameters: {'status': statusCode?.toString() ?? 'Unknown'},
        originalMessage: 'Server error ($statusCode)',
      );
    } catch (e) {
      if (e is AthletesApiException) {
        rethrow;
      }
      throw AthletesApiException(
        localizationKey: ApiErrorKeys.unexpected,
        parameters: {'error': e.toString()},
        originalMessage: e.toString(),
      );
    }
  }

}

