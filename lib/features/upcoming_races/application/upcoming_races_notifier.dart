import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Провайдер для Dashboard (только первая страница, 15 записей)
final dashboardUpcomingRacesProvider =
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

  /// Загрузить только первую страницу предстоящих гонок (для Dashboard)
  ///
  /// [onlyFuture] - если true, загружать только будущие гонки (по умолчанию true)
  ///                если false, загружать все гонки (будущие и прошедшие)
  Future<void> loadUpcomingRacesFirstPage({
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
      final racesResponse = await _api
          .fetchUpcomingRacesWithPagination(
            userProfileId: userProfileId,
            raceType: raceType,
            onlyFuture: onlyFuture,
            page: 1, // Только первая страница
          );
      state = state.copyWith(
        races: racesResponse.data,
        isLoading: false,
        paginationMeta: racesResponse.meta,
      );
    } on UpcomingRacesApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Произошла ошибка');
    }
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
      final racesResponse = await _api
          .fetchUpcomingRacesWithPagination(
            userProfileId: userProfileId,
            raceType: raceType,
            onlyFuture: onlyFuture,
            page: 1,
          )
;
      state = state.copyWith(
        races: racesResponse.data,
        isLoading: false,
        paginationMeta: racesResponse.meta,
      );
    } on UpcomingRacesApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Произошла ошибка');
    }
  }

  /// Загрузить следующую страницу предстоящих гонок
  Future<void> loadNextPage({
    int? userProfileId,
    String? raceType,
    bool onlyFuture = true,
  }) async {
    final meta = state.paginationMeta;
    if (meta == null || state.isLoadingMore || !state.hasMorePages) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final racesResponse = await _api
          .fetchUpcomingRacesWithPagination(
            userProfileId: userProfileId,
            raceType: raceType,
            onlyFuture: onlyFuture,
            page: meta.currentPage + 1,
          )
;

      // Добавляем новые гонки к существующим
      final updatedRaces = [...state.races, ...racesResponse.data];
      state = state.copyWith(
        races: updatedRaces,
        isLoadingMore: false,
        paginationMeta: racesResponse.meta,
      );
    } on UpcomingRacesApiException catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: 'Произошла ошибка');
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
      final racesResponse = await _api
          .fetchUpcomingRacesWithPagination(
            userProfileId: userProfileId,
            raceType: raceType,
            onlyFuture: onlyFuture,
            page: 1,
          )
;
      state = state.copyWith(
        races: racesResponse.data,
        paginationMeta: racesResponse.meta,
      );
    } on UpcomingRacesApiException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: 'Произошла ошибка');
    }
  }

  /// Создать новую предстоящую гонку по ID (новый API формат)
  Future<void> createUpcomingRaceFromId({
    required int raceId,
  }) async {
    state = state.copyWith(clearError: true);

    try {
      final newRace = await _api
          .createUpcomingRace(
            raceId: raceId,
          )
;

      // Добавляем новую гонку в список
      state = state.copyWith(races: [newRace, ...state.races]);
    } on UpcomingRacesApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: 'Произошла ошибка');
    }
  }

  /// DEPRECATED: Старый метод больше не поддерживается
  /// Используйте createUpcomingRaceFromId() вместо этого
  @Deprecated('Use createUpcomingRaceFromId() instead')
  Future<void> createUpcomingRace({
    required String raceType,
    required String location,
    required String raceDate,
  }) async {
    throw UnimplementedError(
      'Этот метод больше не поддерживается. '
      'Используйте createUpcomingRaceFromId() с race_id.',
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Очистить список гонок
  void clearRaces() {
    state = state.copyWith(
      races: const [],
      isLoading: false,
      isLoadingMore: false,
      clearError: true,
      paginationMeta: null,
    );
  }
}
