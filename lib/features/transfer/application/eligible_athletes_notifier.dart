import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../infrastructure/transfer_api.dart';
import '../infrastructure/transfer_api_exception.dart';
import '../models/eligible_athlete_model.dart';
import 'eligible_athletes_state.dart';

/// Notifier для поиска доступных атлетов с локальной фильтрацией
class EligibleAthletesNotifier extends StateNotifier<EligibleAthletesState> {
  final TransferApi _api;
  Timer? _debounceTimer;

  static const Duration _requestTimeout = Duration(seconds: 20);

  EligibleAthletesNotifier({TransferApi? api})
      : _api = api ?? TransferApi(),
        super(const EligibleAthletesState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Загрузка всех доступных атлетов при открытии bottomSheet
  Future<void> loadAllAthletes() async {
    // Если уже загружены, ничего не делаем
    if (state.allAthletesLoaded) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final athletes = await _api.getEligibleAthletes()
          .timeout(_requestTimeout);

      state = state.copyWith(
        allAthletes: athletes,
        athletes: athletes, // Показываем всех атлетов
        isLoading: false,
        allAthletesLoaded: true,
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: 'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
      );
    } on TransferApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Произошла ошибка при загрузке атлетов',
      );
    }
  }

  /// Поиск атлетов с локальной фильтрацией
  void searchAthletes(String query) {
    final trimmedQuery = query.trim();

    // Если все атлеты еще не загружены, загружаем их сначала
    if (!state.allAthletesLoaded) {
      loadAllAthletes().then((_) {
        _filterAthletesLocally(trimmedQuery);
      });
      return;
    }

    // Выполняем локальную фильтрацию
    _filterAthletesLocally(trimmedQuery);
  }

  /// Локальная фильтрация атлетов
  void _filterAthletesLocally(String query) {
    final filteredAthletes = query.isEmpty
        ? state.allAthletes
        : state.allAthletes.where((athlete) {
            final name = athlete.name.toLowerCase();
            final searchQuery = query.toLowerCase();
            return name.contains(searchQuery);
          }).toList();

    state = state.copyWith(
      searchQuery: query,
      athletes: filteredAthletes,
      clearError: true,
    );
  }


  /// Повторная загрузка (используется при ошибке загрузки всех атлетов)
  Future<void> retrySearch() async {
    // Если атлеты еще не загружены, пытаемся загрузить их снова
    if (!state.allAthletesLoaded) {
      await loadAllAthletes();
      return;
    }

    // Если атлеты загружены, просто применяем текущий фильтр
    _filterAthletesLocally(state.searchQuery);
  }

  /// Очищает ошибку
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Выбирает атлета
  void selectAthlete(EligibleAthleteModel athlete) {
    state = state.copyWith(
      selectedAthlete: athlete,
    );
  }

  /// Очищает выбор атлета
  void clearSelection() {
    state = state.copyWith(clearSelectedAthlete: true);
  }

  /// Сбрасывает состояние к начальному
  void reset() {
    _debounceTimer?.cancel();
    state = const EligibleAthletesState();
  }


  /// Устанавливает фиксированный список атлетов (для тестирования)
  void setAthletes(List<EligibleAthleteModel> athletes) {
    state = state.copyWith(
      athletes: athletes,
      isLoading: false,
      clearError: true,
    );
  }
}