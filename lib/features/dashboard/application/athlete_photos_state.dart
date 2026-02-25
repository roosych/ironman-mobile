import '../domain/photo.dart';

class AthletePhotosState {
  final List<Photo> photos;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int lastPage;

  const AthletePhotosState({
    this.photos = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 0,
    this.lastPage = 1,
  });

  bool get hasMore => currentPage < lastPage;
  bool get hasError => error != null;

  AthletePhotosState copyWith({
    List<Photo>? photos,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    int? currentPage,
    int? lastPage,
  }) {
    return AthletePhotosState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
    );
  }
}
