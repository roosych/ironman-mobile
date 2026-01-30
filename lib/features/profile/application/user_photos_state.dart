import '../domain/user_photo.dart';

class UserPhotosState {
  final List<UserPhoto> photos;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  const UserPhotosState({
    this.photos = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  bool get isEmpty => photos.isEmpty && !isLoading && error == null;
  bool get hasError => error != null;
  bool get hasData => photos.isNotEmpty;
  bool get isFullLoading => isLoading && photos.isEmpty;
  bool get isSilentRefresh => isRefreshing && photos.isNotEmpty;

  UserPhotosState copyWith({
    List<UserPhoto>? photos,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
  }) {
    return UserPhotosState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
