import '../domain/upcoming_race.dart';
import '../domain/upcoming_races_response.dart';

class UpcomingRacesState {
  final List<UpcomingRace> races;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int? loadedForUserProfileId;
  final PaginationMeta? paginationMeta;

  const UpcomingRacesState({
    this.races = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.loadedForUserProfileId,
    this.paginationMeta,
  });

  bool get isEmpty => races.isEmpty && !isLoading && error == null;
  bool get hasError => error != null;
  bool get hasData => races.isNotEmpty;
  bool get hasMorePages => paginationMeta != null &&
                          paginationMeta!.currentPage < paginationMeta!.lastPage;

  UpcomingRacesState copyWith({
    List<UpcomingRace>? races,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    int? loadedForUserProfileId,
    PaginationMeta? paginationMeta,
  }) {
    return UpcomingRacesState(
      races: races ?? this.races,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      loadedForUserProfileId: loadedForUserProfileId ?? this.loadedForUserProfileId,
      paginationMeta: paginationMeta ?? this.paginationMeta,
    );
  }
}

