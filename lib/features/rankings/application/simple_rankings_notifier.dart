import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/athlete.dart';
import '../domain/ranking.dart';
import '../infrastructure/simple_rankings_api.dart';

final simpleRankingsProvider = StateNotifierProvider<SimpleRankingsNotifier, RankingsState>((ref) {
  return SimpleRankingsNotifier();
});

/// Простой и надежный RankingsNotifier
class SimpleRankingsNotifier extends StateNotifier<RankingsState> {
  final SimpleRankingsApi _api = SimpleRankingsApi();

  SimpleRankingsNotifier() : super(const RankingsState());

  /// Загрузка рейтингов
  Future<void> loadRankings({
    String? country,
    String? raceType,
    String? gender,
    String? ageGroup,
    int? year,
    bool isRefresh = false,
  }) async {
    // Защита от повторных вызовов
    if (state.isLoading && !isRefresh) return;

    // Устанавливаем состояние загрузки
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final response = await _api.getRankings(
        country: country,
        raceType: raceType,
        gender: gender,
        ageGroup: ageGroup,
        year: year,
        page: 1,
      );

      if (response.isSuccess && response.data != null) {
        state = state.copyWith(
          rankings: response.data!.rankings,
          pagination: response.data!.pagination,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Не удалось загрузить рейтинги',
        );
      }
    } catch (e) {
      debugPrint('Rankings loading error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Произошла ошибка при загрузке рейтингов',
      );
    }
  }

  /// Загрузка следующей страницы
  Future<void> loadNextPage({
    String? country,
    String? raceType,
    String? gender,
    String? ageGroup,
    int? year,
  }) async {
    // Проверяем, есть ли следующая страница
    if (!state.pagination.hasNextPage || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _api.getRankings(
        country: country,
        raceType: raceType,
        gender: gender,
        ageGroup: ageGroup,
        year: year,
        page: state.pagination.currentPage + 1,
      );

      if (response.isSuccess && response.data != null) {
        // Добавляем новые данные к существующим
        final allRankings = [...state.rankings, ...response.data!.rankings];

        state = state.copyWith(
          rankings: allRankings,
          pagination: response.data!.pagination,
          isLoadingMore: false,
          error: null,
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } catch (e) {
      debugPrint('Next page loading error: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Поиск атлетов
  Future<void> searchAthletes(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        searchResults: [],
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true);

    try {
      final response = await _api.searchAthletes(query: query);

      if (response.isSuccess && response.data != null) {
        state = state.copyWith(
          searchResults: response.data!.athletes,
          isSearching: false,
        );
      } else {
        state = state.copyWith(
          searchResults: [],
          isSearching: false,
        );
      }
    } catch (e) {
      debugPrint('Athletes search error: $e');
      state = state.copyWith(
        searchResults: [],
        isSearching: false,
      );
    }
  }

  /// Получение деталей атлета
  Future<Athlete?> getAthleteDetails(int athleteId) async {
    try {
      final response = await _api.getAthleteDetails(athleteId);

      if (response.isSuccess && response.data != null) {
        return response.data!;
      }
    } catch (e) {
      debugPrint('Athlete details error: $e');
    }

    return null;
  }

  /// Очистка поиска
  void clearSearch() {
    state = state.copyWith(
      searchResults: [],
      isSearching: false,
    );
  }

  /// Сброс состояния
  void reset() {
    state = const RankingsState();
  }
}

/// Состояние рейтингов
class RankingsState {
  final List<Ranking> rankings;
  final List<Athlete> searchResults;
  final PaginationInfo pagination;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSearching;
  final String? error;

  const RankingsState({
    this.rankings = const [],
    this.searchResults = const [],
    this.pagination = const PaginationInfo(
      currentPage: 1,
      totalPages: 1,
      totalItems: 0,
      hasNextPage: false,
      hasPrevPage: false,
    ),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSearching = false,
    this.error,
  });

  RankingsState copyWith({
    List<Ranking>? rankings,
    List<Athlete>? searchResults,
    PaginationInfo? pagination,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSearching,
    String? error,
  }) {
    return RankingsState(
      rankings: rankings ?? this.rankings,
      searchResults: searchResults ?? this.searchResults,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }

  bool get hasError => error != null;
  bool get hasData => rankings.isNotEmpty;
  bool get isEmpty => rankings.isEmpty && !isLoading;
}