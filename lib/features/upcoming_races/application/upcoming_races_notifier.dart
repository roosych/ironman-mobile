import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../infrastructure/upcoming_races_api.dart';
import 'upcoming_races_state.dart';

// Провайдер для главного экрана и экрана "Все гонки" (общие гонки, только будущие)
final globalUpcomingRacesProvider =
    StateNotifierProvider<UpcomingRacesNotifier, UpcomingRacesState>((ref) {
      return UpcomingRacesNotifier();
    });

// Провайдер для экрана атлета (гонки конкретного атлета, только будущие)
final athleteUpcomingRacesProvider =
    StateNotifierProvider.family<
      UpcomingRacesNotifier,
      UpcomingRacesState,
      int
    >((ref, int athleteId) {
      return UpcomingRacesNotifier();
    });

// Провайдер для экрана "Мои гонки" (все гонки текущего пользователя, включая прошедшие)
final myRacesProvider =
    StateNotifierProvider<UpcomingRacesNotifier, UpcomingRacesState>((ref) {
      return UpcomingRacesNotifier();
    });

// Оставляем старый провайдер для обратной совместимости (будет удален после обновления всех мест)
@Deprecated(
  'Используйте globalUpcomingRacesProvider, athleteUpcomingRacesProvider или myRacesProvider',
)
final upcomingRacesProvider = globalUpcomingRacesProvider;

class UpcomingRacesNotifier extends StateNotifier<UpcomingRacesState> {
  final UpcomingRacesApi _api;
  static const Duration _requestTimeout = Duration(seconds: 20);

  UpcomingRacesNotifier({UpcomingRacesApi? api})
    : _api = api ?? UpcomingRacesApi(),
      super(const UpcomingRacesState());

  /// Сброс списка гонок (используется, если профиль пользователя не найден)
  void setEmpty() {
    state = state.copyWith(
      races: const [],
      isLoading: false,
      error: null,
    );
  }

  /// Загрузить все предстоящие гонки
  ///
  /// [onlyFuture] - если true, загружать только будущие гонки (по умолчанию true)
  ///                если false, загружать все гонки (будущие и прошедшие)
  Future<void> loadUpcomingRaces({
    int? userProfileId,
    String? raceType,
    bool onlyFuture = true,
  }) async {
    // Если уже идет загрузка, не запускаем повторно
    if (state.isLoading) {
      return;
    }

    // Если данные уже загружены и не пустые, не загружаем повторно
    if (state.races.isNotEmpty && !state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final races = await _api
          .fetchUpcomingRaces(
            userProfileId: userProfileId,
            raceType: raceType,
            onlyFuture: onlyFuture,
          )
          .timeout(_requestTimeout);
      state = state.copyWith(races: races, isLoading: false);
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error:
            'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
      );
    } on UpcomingRacesApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Произошла ошибка');
    }
  }

  /// Обновить список предстоящих гонок
  ///
  /// [onlyFuture] - если true, загружать только будущие гонки (по умолчанию true)
  ///                если false, загружать все гонки (будущие и прошедшие)
  Future<void> refreshUpcomingRaces({
    int? userProfileId,
    String? raceType,
    bool onlyFuture = true,
  }) async {
    state = state.copyWith(clearError: true);

    try {
      final races = await _api
          .fetchUpcomingRaces(
            userProfileId: userProfileId,
            raceType: raceType,
            onlyFuture: onlyFuture,
          )
          .timeout(_requestTimeout);
      state = state.copyWith(races: races);
    } on TimeoutException {
      state = state.copyWith(
        error:
            'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
      );
    } on UpcomingRacesApiException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: 'Произошла ошибка');
    }
  }

  /// Создать новую предстоящую гонку
  Future<void> createUpcomingRace({
    required String raceType,
    required String location,
    required String raceDate,
  }) async {
    state = state.copyWith(clearError: true);

    try {
      final newRace = await _api
          .createUpcomingRace(
            raceType: raceType,
            location: location,
            raceDate: raceDate,
          )
          .timeout(_requestTimeout);

      // Добавляем новую гонку в список
      state = state.copyWith(races: [newRace, ...state.races]);
    } on TimeoutException {
      state = state.copyWith(
        error:
            'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
      );
      rethrow;
    } on UpcomingRacesApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: 'Произошла ошибка');
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Очистить список гонок
  void clearRaces() {
    state = state.copyWith(races: const [], isLoading: false, clearError: true);
  }
}
