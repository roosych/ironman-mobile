import 'simple_api_client.dart';

/// Базовый класс для всех API сервисов
abstract class BaseApiService {
  final SimpleApiClient _client = SimpleApiClient();

  /// Получение клиента
  SimpleApiClient get client => _client;

  /// Инициализация (вызывается автоматически)
  Future<void> init() async {
    await _client.init();
  }
}