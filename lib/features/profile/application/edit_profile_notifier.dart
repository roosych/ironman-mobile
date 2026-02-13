import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_notifier.dart';
import '../domain/athlete_profile.dart';
import '../infrastructure/profile_api.dart';
import 'edit_profile_state.dart';

final editProfileProvider =
    StateNotifierProvider<EditProfileNotifier, EditProfileState>((ref) {
  return EditProfileNotifier(ref);
});

/// Handles edit profile operations
class EditProfileNotifier extends StateNotifier<EditProfileState> {
  final Ref _ref;
  final ProfileApi _api;

  EditProfileNotifier(this._ref, {ProfileApi? api})
      : _api = api ?? ProfileApi(),
        super(const EditProfileState()) {
    _loadInitialDataFromLocal();
  }

  /// Load initial data from local auth state (fast, no network)
  void _loadInitialDataFromLocal() {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    AthleteProfile athleteProfile = const AthleteProfile();
    if (user.profile != null) {
      athleteProfile = AthleteProfile.fromJson(user.profile!.toJson());
    }

    state = state.copyWith(
      name: user.name,
      countryIso: user.profile?.countryIso,
      ironmanNumber: user.profile?.ironmanNumber,
      athleteProfile: athleteProfile,
    );
  }

  /// Load profile data from API
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _api.getProfile();

      AthleteProfile athleteProfile = const AthleteProfile();
      if (user.profile != null) {
        athleteProfile = AthleteProfile.fromJson(user.profile!.toJson());
      }

      state = state.copyWith(
        isLoading: false,
        name: user.name,
        countryIso: user.profile?.countryIso,
        ironmanNumber: user.profile?.ironmanNumber,
        athleteProfile: athleteProfile,
      );

      // Update auth state with fresh data
      _ref.read(authProvider.notifier).setUser(user);
    } on ProfileApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile',
      );
    }
  }

  /// Update name field
  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  /// Update bio field
  void updateBio(String bio) {
    state = state.copyWith(
      athleteProfile: state.athleteProfile.copyWith(bio: bio),
    );
  }

  /// Update strava link
  void updateStrava(String strava) {
    state = state.copyWith(
      athleteProfile: state.athleteProfile.copyWith(
        socialLinks: state.athleteProfile.socialLinks.copyWith(strava: strava),
      ),
    );
  }

  /// Update instagram link
  void updateInstagram(String instagram) {
    state = state.copyWith(
      athleteProfile: state.athleteProfile.copyWith(
        socialLinks:
            state.athleteProfile.socialLinks.copyWith(instagram: instagram),
      ),
    );
  }

  /// Update facebook link
  void updateFacebook(String facebook) {
    state = state.copyWith(
      athleteProfile: state.athleteProfile.copyWith(
        socialLinks:
            state.athleteProfile.socialLinks.copyWith(facebook: facebook),
      ),
    );
  }

  /// Update country
  void updateCountry(String countryIso) {
    state = state.copyWith(
      countryIso: countryIso,
    );
  }

  /// Update ironman number
  void updateIronmanNumber(int? ironmanNumber) {
    state = state.copyWith(
      ironmanNumber: ironmanNumber,
    );
  }

  /// Save profile changes
  Future<void> saveProfile() async {
    debugPrint('🚀 EditProfileNotifier.saveProfile: НАЧИНАЕМ');
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      debugPrint('📤 Отправляем запрос через безопасный ApiClient...');

      // Теперь все ошибки обрабатываются в ApiClient.safeRequest
      final updateResult = await _api.updateProfile(
        name: state.name,
        countryIso: state.countryIso?.toUpperCase(),
        ironmanNumber: state.ironmanNumber,
        bio: state.athleteProfile.bio,
        socialLinks: state.athleteProfile.socialLinks,
      );

      debugPrint('✅ Ответ получен успешно!');

      // Load fresh profile data from API
      final user = await _api.getProfile();

      AthleteProfile athleteProfile = const AthleteProfile();
      if (user.profile != null) {
        athleteProfile = AthleteProfile.fromJson(user.profile!.toJson());
      }

      final successMessage = updateResult['message'] as String? ?? 'Profile saved successfully';

      state = state.copyWith(
        isSaving: false,
        name: user.name,
        countryIso: user.profile?.countryIso,
        ironmanNumber: user.profile?.ironmanNumber,
        athleteProfile: athleteProfile,
        successMessage: successMessage,
      );

      // Update auth state with fresh data from server
      await _ref.read(authProvider.notifier).updateUser(user);
      debugPrint('🎉 ПРОФИЛЬ УСПЕШНО СОХРАНЕН!');

    } catch (e) {
      debugPrint('🔥 ПОЙМАЛИ ОШИБКУ: ${e.runtimeType} - $e');

      // Все ошибки уже обработаны в ApiClient и GlobalErrorInterceptor
      // Просто извлекаем понятное сообщение
      String errorMessage = 'Произошла ошибка при сохранении профиля';

      if (e is ProfileApiException) {
        errorMessage = e.message;
      } else if (e is DioException && e.message != null) {
        errorMessage = e.message!;
      }

      state = state.copyWith(
        isSaving: false,
        error: errorMessage,
      );

      debugPrint('📱 Показываем ошибку пользователю: $errorMessage');
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(clearSuccessMessage: true);
  }
}
