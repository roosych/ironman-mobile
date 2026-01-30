import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../infrastructure/race_results_api.dart';
import 'race_results_state.dart';

final raceResultsProvider =
    StateNotifierProvider<RaceResultsNotifier, RaceResultsState>((ref) {
  return RaceResultsNotifier();
});

/// Отдельный провайдер для результатов конкретного атлета/профиля,
/// чтобы не перетерать результаты залогиненного пользователя.
final athleteRaceResultsProvider = StateNotifierProvider.family<
    RaceResultsNotifier, RaceResultsState, int>((ref, _) {
  return RaceResultsNotifier();
});

class RaceResultsNotifier extends StateNotifier<RaceResultsState> {
  final RaceResultsApi _api;
  static const Duration _requestTimeout = Duration(seconds: 20);
  int? _lastLoadedProfileId; // Отслеживаем, для какого profileId загружены результаты

  RaceResultsNotifier({RaceResultsApi? api})
      : _api = api ?? RaceResultsApi(),
        super(const RaceResultsState());

  Future<void> loadResults(int profileId) async {
    if (state.isLoading) {
      return;
    }

    // Проверяем, что результаты уже загружены для этого profileId
    // Сначала проверяем _lastLoadedProfileId - это самый быстрый и надежный способ
      if (_lastLoadedProfileId == profileId) {
        // Уже загружали для этого profileId - не загружаем повторно
        return;
      }
      
      // Если _lastLoadedProfileId не совпадает, но есть результаты, проверяем userProfileId
      if (state.results.isNotEmpty) {
        final firstResult = state.results.first;
        
        if (firstResult.userProfileId == profileId) {
          // Результаты от нужного пользователя, но _lastLoadedProfileId не установлен
          // Обновляем _lastLoadedProfileId и не загружаем повторно
          _lastLoadedProfileId = profileId;
          return;
        } else if (firstResult.userProfileId != null) {
          // Результаты от другого пользователя - сбрасываем перед загрузкой
          state = const RaceResultsState();
          _lastLoadedProfileId = null;
        }
      }

    // Show loading only if no cached data
    final showLoading = state.results.isEmpty;

    state = state.copyWith(isLoading: showLoading, clearError: true);

    try {
      final response = await _api.fetchResultsByProfileId(profileId).timeout(_requestTimeout);
      _lastLoadedProfileId = profileId; // Сохраняем profileId после успешной загрузки
      state = state.copyWith(
        results: response.results,
        isLoading: false,
        pagination: response.meta,
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: 'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
      );
    } on RaceResultsApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Произошла ошибка',
      );
    }
  }

  Future<void> loadNextPage(int profileId) async {
    // Проверяем, есть ли еще страницы и не идет ли уже загрузка
    if (!state.hasMorePages || state.isLoadingMore || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final nextPage = state.pagination?.nextPage ?? 2;
      final response = await _api.fetchResultsByProfileId(profileId, page: nextPage).timeout(_requestTimeout);
      state = state.copyWith(
        results: response.results,
        isLoadingMore: false,
        pagination: response.meta,
        appendResults: true,
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
      );
    } on RaceResultsApiException catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Произошла ошибка',
      );
    }
  }

  Future<void> refreshResults(int profileId) async {
    state = state.copyWith(clearError: true);

    try {
      final response = await _api.fetchResultsByProfileId(profileId).timeout(_requestTimeout);
      _lastLoadedProfileId = profileId; // Обновляем profileId после обновления
      state = state.copyWith(
        results: response.results,
        pagination: response.meta,
      );
    } on TimeoutException {
      state = state.copyWith(
        error: 'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
      );
    } on RaceResultsApiException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: 'Произошла ошибка');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Сбросить все результаты (используется при смене пользователя)
  void reset() {
    state = const RaceResultsState();
    _lastLoadedProfileId = null;
  }
}

// Provider for all race results (all athletes)
final allRaceResultsProvider =
    StateNotifierProvider<AllRaceResultsNotifier, RaceResultsState>((ref) {
  return AllRaceResultsNotifier();
});

class AllRaceResultsNotifier extends StateNotifier<RaceResultsState> {
  final RaceResultsApi _api;
  static const Duration _requestTimeout = Duration(seconds: 20);

  AllRaceResultsNotifier({RaceResultsApi? api})
      : _api = api ?? RaceResultsApi(),
        super(const RaceResultsState());

  Future<void> loadAllResults() async {
    if (state.isLoading) return;

    // Show loading only if no cached data
    final showLoading = state.results.isEmpty;

    state = state.copyWith(isLoading: showLoading, clearError: true);

    try {
      final response = await _api.fetchAllResults().timeout(_requestTimeout);
      state = state.copyWith(
        results: response.results,
        isLoading: false,
        pagination: response.meta,
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: 'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
      );
    } on RaceResultsApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Произошла ошибка',
      );
    }
  }

  Future<void> loadNextPage() async {
    // Проверяем, есть ли еще страницы и не идет ли уже загрузка
    if (!state.hasMorePages || state.isLoadingMore || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final nextPage = state.pagination?.nextPage ?? 2;
      final response = await _api.fetchAllResults(page: nextPage).timeout(_requestTimeout);
      state = state.copyWith(
        results: response.results,
        isLoadingMore: false,
        pagination: response.meta,
        appendResults: true,
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
      );
    } on RaceResultsApiException catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Произошла ошибка',
      );
    }
  }

  Future<void> refreshAllResults() async {
    state = state.copyWith(clearError: true);

    try {
      final response = await _api.fetchAllResults().timeout(_requestTimeout);
      state = state.copyWith(
        results: response.results,
        pagination: response.meta,
      );
    } on TimeoutException {
      state = state.copyWith(
        error: 'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
      );
    } on RaceResultsApiException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: 'Произошла ошибка');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Сбросить все результаты (используется при смене пользователя)
  void reset() {
    state = const RaceResultsState();
  }
}
