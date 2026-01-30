import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../domain/ranking.dart';

class RankingsApiException implements Exception {
  final String message;
  RankingsApiException(this.message);

  @override
  String toString() => message;
}

class RankingsApi {
  final ApiClient _client;

  RankingsApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Get rankings
  /// GET /rankings?race_type=ironman&discipline=total
  Future<RankingsResponse> getRankings({
    required String raceType,
    required String discipline,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/rankings',
        queryParameters: {
          'race_type': raceType,
          'discipline': discipline,
        },
      );

      final data = response.data;
      if (data == null) {
        throw RankingsApiException('Пустой ответ от сервера');
      }

      if (data['success'] == true && data['data'] != null) {
        final dataList = data['data'];

        // Проверяем, что data является List
        if (dataList is! List) {
          throw RankingsApiException(
            'Ожидался список рейтингов, получен другой тип данных',
          );
        }

        final List<dynamic> rankingsJson = dataList;
        final rankings = rankingsJson.map((json) {
          if (json is! Map<String, dynamic>) {
            throw RankingsApiException(
              'Неверный формат элемента рейтинга',
            );
          }
          return Ranking.fromJson(json);
        }).toList();

        // Извлекаем мета-информацию
        RankingsMeta meta;
        if (data['meta'] != null && data['meta'] is Map) {
          meta = RankingsMeta.fromJson(data['meta'] as Map<String, dynamic>);
        } else {
          // Если мета нет, создаем дефолтную
          meta = RankingsMeta(
            raceType: raceType,
            discipline: discipline,
            total: rankings.length,
          );
        }

        return RankingsResponse(rankings: rankings, meta: meta);
      }

      // Если success != true, но нет ошибки, возвращаем пустой ответ
      return RankingsResponse(
        rankings: [],
        meta: RankingsMeta(
          raceType: raceType,
          discipline: discipline,
          total: 0,
        ),
      );
    } on DioException catch (e) {
      debugPrint('RankingsApi.getRankings DioException: $e');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw RankingsApiException('Превышено время ожидания');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw RankingsApiException('NETWORK_NO_CONNECTION');
      }

      // Более детальная информация об ошибке
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw RankingsApiException(errorData['message'] as String);
        }
        throw RankingsApiException(
          'Ошибка загрузки данных (HTTP $statusCode)',
        );
      }

      throw RankingsApiException(
        'Ошибка загрузки данных: ${e.message ?? 'Неизвестная ошибка'}',
      );
    } catch (e) {
      if (e is RankingsApiException) {
        rethrow;
      }
      throw RankingsApiException('Произошла ошибка: ${e.toString()}');
    }
  }
}

class RankingsResponse {
  final List<Ranking> rankings;
  final RankingsMeta meta;

  const RankingsResponse({
    required this.rankings,
    required this.meta,
  });
}

