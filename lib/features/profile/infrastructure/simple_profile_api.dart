import '../../../core/network/base_api_service.dart';
import '../../../core/network/simple_api_client.dart';
import '../domain/user_profile.dart';
import '../../auth/domain/user.dart';

/// Простой API сервис для профиля
class SimpleProfileApi extends BaseApiService {
  /// Получение профиля пользователя
  Future<ApiResponse<User>> getProfile() async {
    await init();

    return client.get<User>(
      '/profile',
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Обновление профиля
  Future<ApiResponse<User>> updateProfile({
    required String name,
    required String email,
    String? birthday,
    String? country,
    String? city,
    String? phone,
    String? instagram,
    String? strava,
    String? website,
  }) async {
    await init();

    final data = <String, dynamic>{
      'name': name,
      'email': email,
    };

    if (birthday != null) data['birthday'] = birthday;
    if (country != null) data['country'] = country;
    if (city != null) data['city'] = city;
    if (phone != null) data['phone'] = phone;
    if (instagram != null) data['instagram'] = instagram;
    if (strava != null) data['strava'] = strava;
    if (website != null) data['website'] = website;

    return client.put<User>(
      '/profile',
      data: data,
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Создание профиля
  Future<ApiResponse<User>> createProfile({
    required String name,
    required String email,
    String? birthday,
    String? country,
    String? city,
    String? phone,
    String? instagram,
    String? strava,
    String? website,
  }) async {
    await init();

    final data = <String, dynamic>{
      'name': name,
      'email': email,
    };

    if (birthday != null) data['birthday'] = birthday;
    if (country != null) data['country'] = country;
    if (city != null) data['city'] = city;
    if (phone != null) data['phone'] = phone;
    if (instagram != null) data['instagram'] = instagram;
    if (strava != null) data['strava'] = strava;
    if (website != null) data['website'] = website;

    return client.post<User>(
      '/profile',
      data: data,
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Получение URL аватара
  Future<ApiResponse<AvatarResult>> getCurrentAvatarUrl() async {
    await init();

    return client.get<AvatarResult>(
      '/user/photos',
      fromJson: (json) => AvatarResult.fromJson(json as Map<String, dynamic>),
      showErrorDialog: false, // Не показываем ошибку для аватара
    );
  }

  /// Загрузка аватара
  Future<ApiResponse<AvatarResult>> uploadAvatar({
    required String filePath,
  }) async {
    await init();

    // TODO: Реализовать загрузку файла через multipart/form-data
    // Пока заглушка
    throw UnimplementedError('Avatar upload not implemented yet');
  }

  /// Удаление аватара
  Future<ApiResponse<void>> deleteAvatar() async {
    await init();

    return client.delete<void>('/user/photos');
  }
}

/// Результат операций с аватаром
class AvatarResult {
  final String? avatarUrl;

  const AvatarResult({this.avatarUrl});

  factory AvatarResult.fromJson(Map<String, dynamic> json) {
    return AvatarResult(
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}