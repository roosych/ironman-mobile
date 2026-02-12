import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/error_handler.dart';
import '../../../shared/utils/alert_helper.dart';
import '../../../core/theme/app_button_styles.dart';
import '../application/edit_profile_notifier.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _stravaController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(editProfileProvider);
    _nameController = TextEditingController(text: state.name);
    _bioController = TextEditingController(text: state.athleteProfile.bio ?? '');
    _stravaController =
        TextEditingController(text: state.athleteProfile.socialLinks.strava ?? '');
    _instagramController =
        TextEditingController(text: state.athleteProfile.socialLinks.instagram ?? '');
    _facebookController =
        TextEditingController(text: state.athleteProfile.socialLinks.facebook ?? '');

    // Load fresh profile data from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editProfileProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _stravaController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileProvider);
    final localizations = AppLocalizations.of(context)!;

    // Listen for state changes
    ref.listen(editProfileProvider, (previous, next) {
      // Update text controllers when data is loaded from API
      if (previous?.isLoading == true && next.isLoading == false && next.error == null) {
        _nameController.text = next.name;
        _bioController.text = next.athleteProfile.bio ?? '';
        _stravaController.text = next.athleteProfile.socialLinks.strava ?? '';
        _instagramController.text = next.athleteProfile.socialLinks.instagram ?? '';
        _facebookController.text = next.athleteProfile.socialLinks.facebook ?? '';
      }
      // Show success message (already localized from API)
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        AlertHelper.showSuccess(context, next.successMessage!);
        ref.read(editProfileProvider.notifier).clearSuccessMessage();
      }
      // Show error message
      if (next.error != null && previous?.error != next.error) {
        ErrorHandler.showError(context, next.error ?? localizations.edit_profile_save_error);
        ref.read(editProfileProvider.notifier).clearError();
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          localizations.edit_profile_title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: localizations.edit_profile_name,
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
                    color: Colors.white,
                    size: 20,
                  ),
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  ref.read(editProfileProvider.notifier).updateName(value);
                },
              ),
              const SizedBox(height: 16),

              // Bio field (multiline)
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: localizations.edit_profile_bio,
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedEdit01,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                onChanged: (value) {
                  ref.read(editProfileProvider.notifier).updateBio(value);
                },
              ),
              const SizedBox(height: 24),

              // Social links section
              Text(
                localizations.edit_profile_social_links,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Strava field
              TextFormField(
                controller: _stravaController,
                decoration: InputDecoration(
                  labelText: 'Strava',
                  hintText: 'Strava ID',
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedBicycle,
                    color: Colors.white,
                    size: 20,
                  ),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  ref.read(editProfileProvider.notifier).updateStrava(value);
                },
              ),
              const SizedBox(height: 16),

              // Instagram field
              TextFormField(
                controller: _instagramController,
                decoration: InputDecoration(
                  labelText: 'Instagram',
                  hintText: '@username',
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedInstagram,
                    color: Colors.white,
                    size: 20,
                  ),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  ref.read(editProfileProvider.notifier).updateInstagram(value);
                },
              ),
              const SizedBox(height: 16),

              // Facebook field
              TextFormField(
                controller: _facebookController,
                decoration: InputDecoration(
                  labelText: 'Facebook',
                  hintText: 'username',
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFacebook01,
                    color: Colors.white,
                    size: 20,
                  ),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  ref.read(editProfileProvider.notifier).updateFacebook(value);
                },
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: state.isSaving
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: AppButtonStyles.primaryGradientDecoration(
                          borderRadius: 12,
                        ),
                        child: const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : AppButtonStyles.primaryGradientButton(
                        text: localizations.edit_profile_save_button,
                        onPressed: () {
                          ref.read(editProfileProvider.notifier).saveProfile();
                        },
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
