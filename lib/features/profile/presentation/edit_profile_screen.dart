import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:country_flags/country_flags.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/error_handler.dart';
import '../../../shared/utils/alert_helper.dart';
import '../../../shared/data/countries.dart';
import '../../../core/theme/app_button_styles.dart';
import '../../../core/theme/app_colors.dart';
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
  Country? _selectedCountry;

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

    // Initialize selected country from edit profile state
    if (state.countryIso != null) {
      _selectedCountry = Countries.all.where((country) =>
          country.isoCode.toLowerCase() == state.countryIso!.toLowerCase()).firstOrNull;
    }

    // Load fresh profile data from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ВАЖНО: Оборачиваем в try/catch чтобы предотвратить краш
      ref.read(editProfileProvider.notifier).loadProfile().catchError((error) {
        debugPrint('🔴 Ошибка загрузки профиля в initState: $error');
        // Ошибка уже обработана в loadProfile, просто логируем
      });
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

  void _showCountrySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountrySelector(
        onCountrySelected: (country) {
          setState(() {
            _selectedCountry = country;
          });
          // Save country in uppercase format to match API specification
          ref.read(editProfileProvider.notifier).updateCountry(country.isoCode.toUpperCase());
        },
      ),
    );
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

        // Update selected country from fresh API data
        if (next.countryIso != null) {
          if (mounted) {
            setState(() {
              _selectedCountry = Countries.all.where((country) =>
                  country.isoCode.toLowerCase() == next.countryIso!.toLowerCase()).firstOrNull;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _selectedCountry = null;
            });
          }
        }
      }
      // Show success message (already localized from API)
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        if (mounted) {
          AlertHelper.showSuccess(context, next.successMessage!);
          try {
            ref.read(editProfileProvider.notifier).clearSuccessMessage();
          } catch (e) {
            debugPrint('🔴 Ошибка при очистке сообщения успеха: $e');
          }
        }
      }
      // Show error message
      if (next.error != null && previous?.error != next.error) {
        if (mounted) {
          ErrorHandler.showError(context, next.error ?? localizations.edit_profile_save_error);
          try {
            ref.read(editProfileProvider.notifier).clearError();
          } catch (e) {
            debugPrint('🔴 Ошибка при очистке ошибки: $e');
          }
        }
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

              // Country selector
              GestureDetector(
                onTap: state.isLoading ? null : _showCountrySelector,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: localizations.register_select_country,
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedLocation01,
                      color: Colors.white,
                      size: 20,
                    ),
                    suffixIcon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                    border: const OutlineInputBorder(),
                    enabled: !state.isLoading,
                  ),
                  isEmpty: _selectedCountry == null,
                  child: _selectedCountry != null
                      ? SizedBox(
                          height: 24,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: CountryFlag.fromCountryCode(
                                  _selectedCountry!.isoCode,
                                  height: 16,
                                  width: 24,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedCountry!.name,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(height: 24),
                ),
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
                          // ВАЖНО: Оборачиваем в try/catch для предотвращения краша
                          try {
                            ref.read(editProfileProvider.notifier).saveProfile().catchError((error) {
                              debugPrint('🔴 Ошибка при сохранении профиля: $error');
                              // Ошибка уже обработана в saveProfile, просто логируем
                            });
                          } catch (e) {
                            debugPrint('🔴 КРИТИЧЕСКАЯ ошибка при вызове saveProfile: $e');
                          }
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

class _CountrySelector extends StatefulWidget {
  final Function(Country) onCountrySelected;

  const _CountrySelector({
    required this.onCountrySelected,
  });

  @override
  State<_CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<_CountrySelector> {
  final _searchController = TextEditingController();
  List<Country> _filteredCountries = Countries.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = Countries.all;
      } else {
        _filteredCountries = Countries.all
            .where((country) => country.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: AppColors.ironmanGray,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.register_select_country,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: localizations.register_search_countries,
                    prefixIcon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      size: 20,
                      color: AppColors.ironmanTextSecondary,
                    ),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Countries list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemExtent: 72.0, // Fixed height for better performance
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CountryFlag.fromCountryCode(
                      country.isoCode,
                      height: 24,
                      width: 32,
                    ),
                  ),
                  title: Text(country.name),
                  onTap: () {
                    widget.onCountrySelected(country);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
