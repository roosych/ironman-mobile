import '../domain/athlete_profile.dart';

/// State for edit profile screen
class EditProfileState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final String name;
  final String? countryIso;
  final int? ironmanNumber;
  final AthleteProfile athleteProfile;

  const EditProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.name = '',
    this.countryIso,
    this.ironmanNumber,
    this.athleteProfile = const AthleteProfile(),
  });

  EditProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    String? name,
    String? countryIso,
    int? ironmanNumber,
    AthleteProfile? athleteProfile,
    bool clearError = false,
    bool clearSuccessMessage = false,
    bool clearCountryIso = false,
    bool clearIronmanNumber = false,
  }) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      name: name ?? this.name,
      countryIso: clearCountryIso ? null : (countryIso ?? this.countryIso),
      ironmanNumber: clearIronmanNumber ? null : (ironmanNumber ?? this.ironmanNumber),
      athleteProfile: athleteProfile ?? this.athleteProfile,
    );
  }
}
