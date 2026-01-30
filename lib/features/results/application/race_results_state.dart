import '../domain/race_result.dart';
import '../domain/paginated_response.dart';

class RaceResultsState {
  final List<RaceResult> results;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final PaginationMeta? pagination;

  const RaceResultsState({
    this.results = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.pagination,
  });

  bool get isEmpty => results.isEmpty && !isLoading && !isLoadingMore && error == null;
  bool get hasError => error != null;
  bool get hasData => results.isNotEmpty;
  bool get hasMorePages => pagination?.hasMorePages ?? false;

  RaceResultsState copyWith({
    List<RaceResult>? results,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    PaginationMeta? pagination,
    bool clearError = false,
    bool appendResults = false,
  }) {
    return RaceResultsState(
      results: appendResults && results != null
          ? [...this.results, ...results]
          : (results ?? this.results),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      pagination: pagination ?? this.pagination,
    );
  }
}
