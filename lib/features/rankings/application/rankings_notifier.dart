import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../infrastructure/rankings_api.dart';
import 'rankings_state.dart';

final rankingsProvider =
    StateNotifierProvider<RankingsNotifier, RankingsState>((ref) {
  return RankingsNotifier();
});

class RankingsNotifier extends StateNotifier<RankingsState> {
  final RankingsApi _api;
  static const Duration _requestTimeout = Duration(seconds: 20);

  RankingsNotifier({RankingsApi? api})
      : _api = api ?? RankingsApi(),
        super(const RankingsState());


  Future<void> loadRankings({
    String? raceType,
    String? discipline,
    bool forceLoading = false,
  }) async {
    if (state.isLoading && !forceLoading) return;

    final effectiveRaceType = raceType ?? state.selectedRaceType;
    final effectiveDiscipline = discipline ?? state.selectedDiscipline;

    // Show loading if no cached data, filters changed, or forced
    final showLoading = forceLoading ||
        state.rankings.isEmpty ||
        effectiveRaceType != state.selectedRaceType ||
        effectiveDiscipline != state.selectedDiscipline;

    state = state.copyWith(
      isLoading: showLoading,
      clearError: true,
      selectedRaceType: effectiveRaceType,
      selectedDiscipline: effectiveDiscipline,
    );

    try {
      final response = await _api
          .getRankings(
            raceType: effectiveRaceType,
            discipline: effectiveDiscipline,
          )
          .timeout(_requestTimeout);


      state = state.copyWith(
        rankings: response.rankings,
        isLoading: false,
        meta: response.meta,
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: 'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
      );
    } on RankingsApiException catch (e) {
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

  Future<void> refreshRankings() async {
    state = state.copyWith(clearError: true);

    try {
      final response = await _api
          .getRankings(
            raceType: state.selectedRaceType,
            discipline: state.selectedDiscipline,
          )
          .timeout(_requestTimeout);


      state = state.copyWith(
        rankings: response.rankings,
        meta: response.meta,
      );
    } on TimeoutException {
      state = state.copyWith(
        error: 'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
      );
    } on RankingsApiException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: 'Произошла ошибка');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Очищает данные рейтингов для показа анимации загрузки
  void clearRankings() {
    state = state.copyWith(
      rankings: [],
      isLoading: true,
      clearError: true,
      clearSelection: true,
    );
  }

  /// Выбирает или снимает выбор атлета для сравнения
  void toggleAthleteSelection(int athleteId) {
    final currentSelection = Set<int>.from(state.selectedAthleteIds);
    
    if (currentSelection.contains(athleteId)) {
      // Снимаем выбор
      currentSelection.remove(athleteId);
    } else {
      // Добавляем выбор, но максимум 2
      if (currentSelection.length < 2) {
        currentSelection.add(athleteId);
      } else {
        // Если уже выбрано 2, заменяем первый на новый
        currentSelection.remove(currentSelection.first);
        currentSelection.add(athleteId);
      }
    }
    
    state = state.copyWith(selectedAthleteIds: currentSelection);
  }

  /// Очищает выбор атлетов
  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }
}

