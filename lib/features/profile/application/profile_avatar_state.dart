/// State for avatar upload operations only.
/// avatarUrl is NOT stored here - it's in AuthState.user.avatarUrl (Single Source of Truth)
class ProfileAvatarState {
  final bool isLoading;
  final String? error;

  const ProfileAvatarState({
    this.isLoading = false,
    this.error,
  });

  ProfileAvatarState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ProfileAvatarState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
