class ChangePasswordState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const ChangePasswordState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ChangePasswordState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccessMessage = false,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

