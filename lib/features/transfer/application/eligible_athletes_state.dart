import '../models/eligible_athlete_model.dart';

/// Состояние поиска доступных атлетов для переноса
class EligibleAthletesState {
  /// Полный список всех доступных атлетов (загруженных с сервера)
  final List<EligibleAthleteModel> allAthletes;

  /// Список найденных атлетов (фильтрованный или полный)
  final List<EligibleAthleteModel> athletes;

  /// Выполняется ли загрузка
  final bool isLoading;

  /// Сообщение об ошибке
  final String? error;

  /// Текущий поисковый запрос
  final String searchQuery;

  /// Загружены ли все атлеты с сервера
  final bool allAthletesLoaded;

  /// Выбранный атлет
  final EligibleAthleteModel? selectedAthlete;

  const EligibleAthletesState({
    this.allAthletes = const [],
    this.athletes = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.allAthletesLoaded = false,
    this.selectedAthlete,
  });

  /// Есть ли найденные атлеты
  bool get hasAthletes => athletes.isNotEmpty;

  /// Есть ли ошибка
  bool get hasError => error != null;

  /// Выполнялся ли поиск
  bool get hasSearched => searchQuery.isNotEmpty || allAthletesLoaded;

  /// Можно ли показать сообщение "Не найдено"
  bool get canShowEmptyMessage => hasSearched && !isLoading && !hasAthletes && !hasError;

  /// Есть ли выбранный атлет
  bool get isAthleteSelected => selectedAthlete != null;

  /// Создает копию состояния с измененными полями
  EligibleAthletesState copyWith({
    List<EligibleAthleteModel>? allAthletes,
    List<EligibleAthleteModel>? athletes,
    bool? isLoading,
    String? error,
    String? searchQuery,
    bool? allAthletesLoaded,
    EligibleAthleteModel? selectedAthlete,
    bool clearError = false,
    bool clearSelectedAthlete = false,
  }) {
    return EligibleAthletesState(
      allAthletes: allAthletes ?? this.allAthletes,
      athletes: athletes ?? this.athletes,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      allAthletesLoaded: allAthletesLoaded ?? this.allAthletesLoaded,
      selectedAthlete: clearSelectedAthlete ? null : (selectedAthlete ?? this.selectedAthlete),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EligibleAthletesState &&
          runtimeType == other.runtimeType &&
          allAthletes == other.allAthletes &&
          athletes == other.athletes &&
          isLoading == other.isLoading &&
          error == other.error &&
          searchQuery == other.searchQuery &&
          allAthletesLoaded == other.allAthletesLoaded &&
          selectedAthlete == other.selectedAthlete;

  @override
  int get hashCode =>
      allAthletes.hashCode ^
      athletes.hashCode ^
      isLoading.hashCode ^
      error.hashCode ^
      searchQuery.hashCode ^
      allAthletesLoaded.hashCode ^
      selectedAthlete.hashCode;

  @override
  String toString() {
    return 'EligibleAthletesState{allAthletes: ${allAthletes.length}, athletes: ${athletes.length}, '
           'isLoading: $isLoading, error: $error, searchQuery: $searchQuery, allAthletesLoaded: $allAthletesLoaded, '
           'selectedAthlete: $selectedAthlete}';
  }
}