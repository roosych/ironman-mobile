import '../domain/athlete.dart';

class AthletesState {
  final List<Athlete> athletes;
  final bool isLoading;
  final String? error;

  const AthletesState({
    this.athletes = const [],
    this.isLoading = false,
    this.error,
  });

  AthletesState copyWith({
    List<Athlete>? athletes,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AthletesState(
      athletes: athletes ?? this.athletes,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isEmpty => athletes.isEmpty;
  bool get hasError => error != null;
}

