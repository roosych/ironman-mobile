import '../domain/athlete_profile.dart';

/// State for edit profile screen
class EditProfileState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final String name;
  final AthleteProfile athleteProfile;

  const EditProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.name = '',
    this.athleteProfile = const AthleteProfile(),
  });

  EditProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    String? name,
    AthleteProfile? athleteProfile,
    bool clearError = false,
    bool clearSuccessMessage = false,
  }) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      name: name ?? this.name,
      athleteProfile: athleteProfile ?? this.athleteProfile,
    );
  }
}
