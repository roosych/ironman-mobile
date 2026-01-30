import '../domain/athlete.dart';

class AthleteDetailState {
  final Athlete? athlete;
  final bool isLoading;
  final String? error;

  const AthleteDetailState({
    this.athlete,
    this.isLoading = false,
    this.error,
  });

  AthleteDetailState copyWith({
    Athlete? athlete,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AthleteDetailState(
      athlete: athlete ?? this.athlete,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasError => error != null;
}

