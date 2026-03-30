import '../models/race_model.dart';

/// Состояние для выбора гонки
class RaceSelectionState {
  final List<RaceModel> races;        // Список гонок с сервера
  final RaceModel? selectedRace;      // Выбранная гонка
  final String searchQuery;           // Текущий поисковый запрос
  final bool allRacesLoaded;         // Флаг успешной первой загрузки
  final bool isLoading;
  final String? error;

  const RaceSelectionState({
    this.races = const [],
    this.selectedRace,
    this.searchQuery = '',
    this.allRacesLoaded = false,
    this.isLoading = false,
    this.error,
  });

  /// Computed getters
  bool get hasRaces => races.isNotEmpty;
  bool get hasError => error != null;
  bool get hasSearched => searchQuery.isNotEmpty || allRacesLoaded;
  bool get canShowEmptyMessage => hasSearched && !isLoading && !hasRaces && !hasError;
  bool get isRaceSelected => selectedRace != null;

  /// Создание копии состояния с измененными полями
  RaceSelectionState copyWith({
    List<RaceModel>? races,
    RaceModel? selectedRace,
    String? searchQuery,
    bool? allRacesLoaded,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSelection = false,
  }) {
    return RaceSelectionState(
      races: races ?? this.races,
      selectedRace: clearSelection ? null : (selectedRace ?? this.selectedRace),
      searchQuery: searchQuery ?? this.searchQuery,
      allRacesLoaded: allRacesLoaded ?? this.allRacesLoaded,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RaceSelectionState &&
        other.races == races &&
        other.selectedRace == selectedRace &&
        other.searchQuery == searchQuery &&
        other.allRacesLoaded == allRacesLoaded &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      races,
      selectedRace,
      searchQuery,
      allRacesLoaded,
      isLoading,
      error,
    );
  }

  @override
  String toString() {
    return 'RaceSelectionState(races: ${races.length}, selectedRace: $selectedRace, searchQuery: $searchQuery, allRacesLoaded: $allRacesLoaded, isLoading: $isLoading, error: $error)';
  }
}