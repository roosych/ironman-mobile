import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../infrastructure/races_api.dart';
import '../models/race_model.dart';
import 'race_selection_state.dart';

/// Notifier для управления состоянием выбора гонки
class RaceSelectionNotifier extends StateNotifier<RaceSelectionState> {
  final RacesApi _api;
  static const Duration _requestTimeout = Duration(seconds: 20);

  RaceSelectionNotifier({RacesApi? api})
      : _api = api ?? RacesApi(),
        super(const RaceSelectionState());


  /// Загрузить все доступные гонки (один раз при открытии BottomSheet)
  ///
  /// Идемпотентный метод - возвращается сразу если гонки уже загружены
  Future<void> loadAllRaces() async {
    // Проверяем, не загружены ли уже гонки
    if (state.allRacesLoaded) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final races = await _api.fetchAvailableRaces().timeout(_requestTimeout);

      if (mounted) {
        state = state.copyWith(
          allRaces: races,
          races: races, // Изначально показываем все гонки
          isLoading: false,
          allRacesLoaded: true,
        );
      }
    } on TimeoutException {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Превышено время ожидания. Проверьте подключение к интернету.',
        );
      }
      rethrow;
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Не удалось загрузить список гонок';
        if (e.toString().contains('NETWORK_NO_CONNECTION')) {
          errorMessage = 'Отсутствует подключение к интернету';
        } else if (e is RacesApiException) {
          errorMessage = e.message;
        }

        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
      }
      rethrow;
    }
  }

  /// Поиск и фильтрация гонок локально (без запросов к серверу)
  ///
  /// Если данные еще не загружены, сначала загружает их, затем применяет фильтр
  void searchRaces(String query) {
    final trimmedQuery = query.trim();

    // Если данные еще не загружены, загружаем их асинхронно
    if (!state.allRacesLoaded) {
      loadAllRaces().then((_) {
        if (mounted) {
          _filterRacesLocally(trimmedQuery);
        }
      });
      return;
    }

    _filterRacesLocally(trimmedQuery);
  }

  /// Выбрать гонку
  void selectRace(RaceModel race) {
    // Переключение выбора: если гонка уже выбрана, снимаем выбор
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
    state = const RaceSelectionState();
  }

  /// Повторить поиск при ошибке
  Future<void> retrySearch() async {
    if (!state.allRacesLoaded) {
      // Если начальная загрузка не удалась, повторяем ее
      await loadAllRaces();
      return;
    }

    // Если загрузка была успешной, повторно применяем фильтр
    _filterRacesLocally(state.searchQuery);
  }

  /// Локальная фильтрация списка гонок
  ///
  /// Фильтрует по location, typeLabel и дате. Без запросов к серверу.
  void _filterRacesLocally(String query) {
    if (!state.allRacesLoaded) {
      return;
    }

    final filteredRaces = query.isEmpty
        ? state.allRaces
        : state.allRaces.where((race) {
            final queryLower = query.toLowerCase();
            final location = race.location.toLowerCase();
            final typeLabel = race.typeLabel.toLowerCase();
            final formattedDate = race.formattedDate.toLowerCase();

            return location.contains(queryLower) ||
                typeLabel.contains(queryLower) ||
                formattedDate.contains(queryLower);
          }).toList();

    state = state.copyWith(
      searchQuery: query,
      races: filteredRaces,
      clearError: true,
    );
  }
}