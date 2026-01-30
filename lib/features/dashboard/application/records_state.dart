import '../domain/personal_record.dart';

class RecordsState {
  final Records? records;
  final bool isLoading;
  final String? error;

  const RecordsState({
    this.records,
    this.isLoading = false,
    this.error,
  });

  RecordsState copyWith({
    Records? records,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RecordsState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasError => error != null && error!.isNotEmpty;
  bool get isEmpty => records == null;
}

