import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Получить список уведомлений
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      debugPrint('=== DEBUG: NotificationService.getNotifications ===');
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response data type: ${response.data.runtimeType}');
      debugPrint('Response data keys: ${response.data?.keys.toList()}');

      if (response.statusCode == 200) {
        final responseData = response.data ?? {};
        debugPrint('Returning response data: $responseData');
        
        // Проверяем, может ли быть другая структура ответа
        if (responseData.isEmpty || (!responseData.containsKey('data') && !responseData.containsKey('success'))) {
          debugPrint('⚠️ WARNING: Response data structure may be unexpected');
          debugPrint('Response data: $responseData');
        }
        
        return responseData;
      } else {
        debugPrint('⚠️ ERROR: Non-200 status code: ${response.statusCode}');
        debugPrint('Response data: ${response.data}');
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('=== DEBUG: NotificationService.getNotifications DioException ===');
      debugPrint('Error type: ${e.type}');
      debugPrint('Error message: ${e.message}');
      if (e.response != null) {
        debugPrint('Response status: ${e.response!.statusCode}');
        debugPrint('Response data: ${e.response!.data}');
      }
      debugPrint('NotificationService: Error getting notifications: $e');
      rethrow;
    } catch (e) {
      debugPrint('NotificationService: Error getting notifications: $e');
      rethrow;
    }
  }

  /// Пометить уведомление как прочитанное
  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/notifications/$notificationId/read',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('NotificationService: Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Пометить все как прочитанные
  Future<void> markAllAsRead() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/notifications/read-all',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all as read: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('NotificationService: Error marking all as read: $e');
      rethrow;
    }
  }

  /// Удалить уведомление
  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/notifications/$notificationId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('NotificationService: Error deleting notification: $e');
      rethrow;
    }
  }
}

