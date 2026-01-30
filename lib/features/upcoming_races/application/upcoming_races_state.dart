import '../domain/upcoming_race.dart';

class UpcomingRacesState {
  final List<UpcomingRace> races;
  final bool isLoading;
  final String? error;
  final int? loadedForUserProfileId;

  const UpcomingRacesState({
    this.races = const [],
    this.isLoading = false,
    this.error,
    this.loadedForUserProfileId,
  });

  bool get isEmpty => races.isEmpty && !isLoading && error == null;
  bool get hasError => error != null;
  bool get hasData => races.isNotEmpty;

  UpcomingRacesState copyWith({
    List<UpcomingRace>? races,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? loadedForUserProfileId,
  }) {
    return UpcomingRacesState(
      races: races ?? this.races,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      loadedForUserProfileId: loadedForUserProfileId ?? this.loadedForUserProfileId,
    );
  }
}

