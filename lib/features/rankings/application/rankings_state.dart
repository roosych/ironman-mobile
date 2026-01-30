import '../domain/ranking.dart';

class RankingsState {
  final List<Ranking> rankings;
  final bool isLoading;
  final String? error;
  final RankingsMeta? meta;
  final String selectedRaceType;
  final String selectedDiscipline;
  final Set<int> selectedAthleteIds;

  const RankingsState({
    this.rankings = const [],
    this.isLoading = false,
    this.error,
    this.meta,
    this.selectedRaceType = 'ironman',
    this.selectedDiscipline = 'total',
    this.selectedAthleteIds = const {},
  });

  bool get isEmpty => rankings.isEmpty && !isLoading && error == null;
  bool get hasError => error != null;
  bool get hasData => rankings.isNotEmpty;
  bool get canCompare => selectedAthleteIds.length == 2;
  List<Ranking> get selectedAthletes => rankings
      .where((r) => selectedAthleteIds.contains(r.athleteId))
      .toList();

  RankingsState copyWith({
    List<Ranking>? rankings,
    bool? isLoading,
    String? error,
    RankingsMeta? meta,
    String? selectedRaceType,
    String? selectedDiscipline,
    Set<int>? selectedAthleteIds,
    bool clearError = false,
    bool clearSelection = false,
  }) {
    return RankingsState(
      rankings: rankings ?? this.rankings,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      meta: meta ?? this.meta,
      selectedRaceType: selectedRaceType ?? this.selectedRaceType,
      selectedDiscipline: selectedDiscipline ?? this.selectedDiscipline,
      selectedAthleteIds: clearSelection
          ? const {}
          : (selectedAthleteIds ?? this.selectedAthleteIds),
    );
  }
}

