class ProfileSelectionState {
  final bool isProcessing;
  final String? error;

  const ProfileSelectionState({
    this.isProcessing = false,
    this.error,
  });

  bool get hasError => error != null;

  ProfileSelectionState copyWith({
    bool? isProcessing,
    String? error,
    bool clearError = false,
  }) {
    return ProfileSelectionState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

