import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../infrastructure/races_api.dart';
import '../models/race_model.dart';
import '../../../core/errors/api_exception.dart';
import 'race_selection_state.dart';

/// Notifier для управления состоянием выбора гонки
class RaceSelectionNotifier extends StateNotifier<RaceSelectionState> {
  final RacesApi _api;
  static const Duration _requestTimeout = Duration(seconds: 20);
  static const Duration _debounceDuration = Duration(milliseconds: 400);

  Timer? _debounceTimer;

  RaceSelectionNotifier({RacesApi? api})
      : _api = api ?? RacesApi(),
        super(const RaceSelectionState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Загрузить гонки при открытии BottomSheet
  Future<void> loadAllRaces() async {
    if (state.allRacesLoaded) return;

    state = state.copyWith(isLoading: true, clearError: true);
    await _fetchRaces();
  }

  /// Поиск гонок через API с дебаунсом
  void searchRaces(String query) {
    final trimmedQuery = query.trim();
    state = state.copyWith(searchQuery: trimmedQuery, isLoading: true, clearError: true);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (mounted) {
        _fetchRaces(search: trimmedQuery.isEmpty ? null : trimmedQuery);
      }
    });
  }

  /// Выбрать гонку
  void selectRace(RaceModel race) {
    final newSelection = state.selectedRace?.id == race.id ? null : race;
    state = state.copyWith(selectedRace: newSelection, clearError: true);
  }

  /// Очистить выбор
  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Сбросить состояние к начальному
  void reset() {
    _debounceTimer?.cancel();
    state = const RaceSelectionState();
  }

  /// Повторить запрос при ошибке
  Future<void> retrySearch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _fetchRaces(
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
    );
  }

  /// Выполнить запрос к API
  Future<void> _fetchRaces({String? search}) async {
    try {
      final races = await _api
          .fetchAvailableRaces(search: search, perPage: 100)
          .timeout(_requestTimeout);

      if (mounted) {
        state = state.copyWith(
          races: races,
          isLoading: false,
          allRacesLoaded: true,
        );
      }
    } on TimeoutException {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: 'api_error_timeout');
      }
    } catch (e) {
      if (mounted) {
        final errorKey = e is RacesApiException ? e.localizationKey : 'error_unexpected';
        state = state.copyWith(isLoading: false, error: errorKey);
      }
    }
  }
}