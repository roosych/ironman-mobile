import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_az.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('az'),
    Locale('en'),
    Locale('ru'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'IRONSTATS'**
  String get app_title;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get login_title;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get login_email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get login_password;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get login_button;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get login_email_required;

  /// Email format validation error
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get login_email_invalid;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get login_password_required;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get login_forgot_password;

  /// Text before registration link
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get login_no_account;

  /// Registration link text
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get login_create_account;

  /// Loading message during authentication
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get login_loading;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// Russian language name
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get language_russian;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_english;

  /// Azerbaijani language name
  ///
  /// In en, this message translates to:
  /// **'Azərbaycan'**
  String get language_azerbaijani;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'LOG OUT'**
  String get logout_button;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_title;

  /// Information menu item
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get profile_information;

  /// Photo Gallery menu item
  ///
  /// In en, this message translates to:
  /// **'Photo Gallery'**
  String get profile_photo_gallery;

  /// Workouts menu item
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get profile_workouts;

  /// Fallback text for user name
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profile_user_fallback;

  /// Coming soon text
  ///
  /// In en, this message translates to:
  /// **'coming soon'**
  String get common_coming_soon;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// Undo button text
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get common_undo;

  /// All button/text
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get common_all;

  /// Loading error message
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get common_loading_error;

  /// Upcoming races section title
  ///
  /// In en, this message translates to:
  /// **'Upcoming Races'**
  String get home_upcoming_races;

  /// Personal bests section title
  ///
  /// In en, this message translates to:
  /// **'Personal Bests'**
  String get home_personal_bests;

  /// Greeting text before user name
  ///
  /// In en, this message translates to:
  /// **'Hello,'**
  String get home_greeting;

  /// Welcome back greeting text
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get home_greeting_welcome;

  /// Finishes label
  ///
  /// In en, this message translates to:
  /// **'finishes'**
  String get home_finishes;

  /// Add race button text
  ///
  /// In en, this message translates to:
  /// **'Add Race'**
  String get home_add_race;

  /// Add upcoming race bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Add Race'**
  String get home_add_race_title;

  /// Race selection bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Select Race'**
  String get race_selection_title;

  /// Race selection search field hint
  ///
  /// In en, this message translates to:
  /// **'Search races...'**
  String get race_selection_search_hint;

  /// Race selection save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get race_selection_save;

  /// Race selection empty state message
  ///
  /// In en, this message translates to:
  /// **'No races found'**
  String get race_selection_no_races;

  /// Race selection confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Race'**
  String get race_selection_confirm_title;

  /// Race selection confirmation dialog description
  ///
  /// In en, this message translates to:
  /// **'Add this race to your upcoming races?'**
  String get race_selection_confirm_description;

  /// Race selection success message
  ///
  /// In en, this message translates to:
  /// **'Race added successfully'**
  String get race_selection_success;

  /// No upcoming races message
  ///
  /// In en, this message translates to:
  /// **'No upcoming races'**
  String get home_no_upcoming_races;

  /// No data message
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get common_no_data;

  /// Today label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get common_today;

  /// Days count label
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Today} =1{1 day} other{{count} days}}'**
  String common_days(int count);

  /// Results screen title
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results_title;

  /// Result detail screen title
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result_detail_title;

  /// My Results tab
  ///
  /// In en, this message translates to:
  /// **'My Results'**
  String get results_my_results;

  /// All Athletes tab
  ///
  /// In en, this message translates to:
  /// **'All Athletes'**
  String get results_all_athletes;

  /// No results message
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get results_no_results;

  /// All athletes results coming soon message
  ///
  /// In en, this message translates to:
  /// **'All athletes results coming soon'**
  String get results_all_coming_soon;

  /// News screen title
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news_title;

  /// News coming soon message
  ///
  /// In en, this message translates to:
  /// **'News coming soon'**
  String get news_coming_soon;

  /// News section work in progress message
  ///
  /// In en, this message translates to:
  /// **'We are working on this section. Stay tuned for updates!'**
  String get news_working_on_section;

  /// Ratings screen title
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get ratings_title;

  /// Ratings coming soon message
  ///
  /// In en, this message translates to:
  /// **'Ratings coming soon'**
  String get ratings_coming_soon;

  /// Ratings section work in progress message
  ///
  /// In en, this message translates to:
  /// **'We are working on this section. Stay tuned for updates!'**
  String get ratings_working_on_section;

  /// By race type tab label
  ///
  /// In en, this message translates to:
  /// **'By Race Type'**
  String get ratings_by_race_type;

  /// By discipline tab label
  ///
  /// In en, this message translates to:
  /// **'By Discipline'**
  String get ratings_by_discipline;

  /// Race type filter label
  ///
  /// In en, this message translates to:
  /// **'Race Type'**
  String get ratings_filter_race_type;

  /// Discipline filter label
  ///
  /// In en, this message translates to:
  /// **'Discipline'**
  String get ratings_filter_discipline;

  /// Total discipline label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get ratings_discipline_total;

  /// Swim discipline label
  ///
  /// In en, this message translates to:
  /// **'Swim'**
  String get ratings_discipline_swim;

  /// Bike discipline label
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get ratings_discipline_bike;

  /// Run discipline label
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get ratings_discipline_run;

  /// No rankings message
  ///
  /// In en, this message translates to:
  /// **'No rankings'**
  String get ratings_no_rankings;

  /// Position label
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get ratings_position;

  /// Record date label
  ///
  /// In en, this message translates to:
  /// **'Record Date'**
  String get ratings_record_date;

  /// Record location label
  ///
  /// In en, this message translates to:
  /// **'Record Location'**
  String get ratings_record_location;

  /// Compare label
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get ratings_compare;

  /// No description provided for @ratings_disciplines_comparison.
  ///
  /// In en, this message translates to:
  /// **'Discipline comparison by athlete\'s best records'**
  String get ratings_disciplines_comparison;

  /// No description provided for @ratings_compare_records.
  ///
  /// In en, this message translates to:
  /// **'Compare personal records'**
  String get ratings_compare_records;

  /// No description provided for @ratings_race_type_full.
  ///
  /// In en, this message translates to:
  /// **'FULL 140.6'**
  String get ratings_race_type_full;

  /// No description provided for @ratings_race_type_half.
  ///
  /// In en, this message translates to:
  /// **'HALF 70.3'**
  String get ratings_race_type_half;

  /// Select two athletes message
  ///
  /// In en, this message translates to:
  /// **'Select 2 athletes to compare'**
  String get ratings_select_two_athletes;

  /// Clear selection button text
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get ratings_clear_selection;

  /// Time label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get ratings_time;

  /// Difference label
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get ratings_difference;

  /// Hint text for comparing athletes
  ///
  /// In en, this message translates to:
  /// **'Tap on an athlete to compare'**
  String get ratings_tap_to_compare_hint;

  /// Athletes screen title
  ///
  /// In en, this message translates to:
  /// **'Athletes'**
  String get athletes_title;

  /// Athletes screen coming soon message
  ///
  /// In en, this message translates to:
  /// **'Athletes screen — coming soon'**
  String get athletes_coming_soon;

  /// Athletes list screen title
  ///
  /// In en, this message translates to:
  /// **'Athletes'**
  String get athletes_list_title;

  /// Athletes search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get athletes_search_hint;

  /// Registered athletes filter
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get athletes_filter_registered;

  /// New athletes filter
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get athletes_filter_new;

  /// Registered status label
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get athletes_status_registered;

  /// Invite athlete button text
  ///
  /// In en, this message translates to:
  /// **'INVITE'**
  String get athletes_invite_button;

  /// Athlete profile screen title
  ///
  /// In en, this message translates to:
  /// **'Athlete Profile'**
  String get athlete_profile_title;

  /// Info tab label
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get athlete_profile_info_tab;

  /// Results tab label
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get athlete_profile_results_tab;

  /// Best by race type section title
  ///
  /// In en, this message translates to:
  /// **'Best by race type'**
  String get athlete_profile_best_by_race_type;

  /// By disciplines section title
  ///
  /// In en, this message translates to:
  /// **'By disciplines'**
  String get athlete_profile_by_disciplines;

  /// Swimming discipline label
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get athlete_profile_swimming;

  /// Cycling discipline label
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get athlete_profile_cycling;

  /// Running discipline label
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get athlete_profile_running;

  /// Personal bests tab label
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get athlete_profile_personal_bests;

  /// Bottom navigation Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// Bottom navigation Results
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get nav_results;

  /// Bottom navigation Ratings
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get nav_ratings;

  /// Bottom navigation Athletes
  ///
  /// In en, this message translates to:
  /// **'Athletes'**
  String get nav_athletes;

  /// Delete photo dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete photo?'**
  String get photo_delete_title;

  /// Delete avatar photo warning
  ///
  /// In en, this message translates to:
  /// **'This photo is your avatar. After deletion, the avatar will be reset.'**
  String get photo_delete_avatar_warning;

  /// Delete photo irreversible warning
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get photo_delete_irreversible;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get photo_delete_button;

  /// Photo deleted success message
  ///
  /// In en, this message translates to:
  /// **'Photo deleted'**
  String get photo_deleted;

  /// Photo uploaded success message
  ///
  /// In en, this message translates to:
  /// **'Photo uploaded'**
  String get photo_uploaded;

  /// Photo already avatar message
  ///
  /// In en, this message translates to:
  /// **'This photo is already set as avatar'**
  String get photo_already_avatar;

  /// Set as avatar dialog title
  ///
  /// In en, this message translates to:
  /// **'Set as avatar?'**
  String get photo_set_avatar_title;

  /// Set as avatar dialog description
  ///
  /// In en, this message translates to:
  /// **'This photo will be used as your avatar in the profile.'**
  String get photo_set_avatar_description;

  /// Set button text
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get photo_set_button;

  /// Set as avatar button text
  ///
  /// In en, this message translates to:
  /// **'Set as avatar'**
  String get photo_set_as_avatar;

  /// Avatar label
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get photo_avatar;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get photo_delete;

  /// Avatar updated success message
  ///
  /// In en, this message translates to:
  /// **'Avatar successfully updated'**
  String get photo_avatar_updated;

  /// Add photo button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get photo_add_button;

  /// Total time label
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get result_total_time;

  /// Category label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get result_category;

  /// Disciplines section title
  ///
  /// In en, this message translates to:
  /// **'Disciplines'**
  String get result_disciplines;

  /// Swim discipline label
  ///
  /// In en, this message translates to:
  /// **'Swim'**
  String get result_swim;

  /// Transition 1 label
  ///
  /// In en, this message translates to:
  /// **'T1'**
  String get result_t1;

  /// Bike discipline label
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get result_bike;

  /// Transition 2 label
  ///
  /// In en, this message translates to:
  /// **'T2'**
  String get result_t2;

  /// Run discipline label
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get result_run;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get register_sign_in;

  /// Registration screen title
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get register_title;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get register_name;

  /// Name validation error
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get register_name_required;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get register_confirm_password;

  /// Confirm password validation error
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get register_confirm_password_required;

  /// Password minimum length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get register_password_min_length;

  /// Password mismatch validation error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get register_passwords_not_match;

  /// Registration button text
  ///
  /// In en, this message translates to:
  /// **'SIGN UP'**
  String get register_button;

  /// Text before login link
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get register_already_have_account;

  /// Privacy policy agreement text (first part)
  ///
  /// In en, this message translates to:
  /// **'I agree with the '**
  String get register_privacy_policy_agree;

  /// Privacy policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get register_privacy_policy_link;

  /// Privacy policy validation error
  ///
  /// In en, this message translates to:
  /// **'You must agree to the Privacy Policy'**
  String get register_privacy_policy_required;

  /// Policy screen title
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get policies_title;

  /// Policy not available message
  ///
  /// In en, this message translates to:
  /// **'Policy not available'**
  String get policy_not_available;

  /// Policy load error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load policy'**
  String get policy_load_error;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Registration success title
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get register_thank_you;

  /// Registration success message
  ///
  /// In en, this message translates to:
  /// **'Registration successful.\nPlease verify your account by clicking the link in the email we sent you.\nYou can then sign in to your account.'**
  String get register_success_message;

  /// Sign in button on success screen
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get register_success_sign_in;

  /// Country selector label
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get register_select_country;

  /// Country search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search countries'**
  String get register_search_countries;

  /// Language changed notification message
  ///
  /// In en, this message translates to:
  /// **'Language changed'**
  String get settings_language_changed;

  /// Edit profile screen title
  ///
  /// In en, this message translates to:
  /// **'Athlete Info'**
  String get edit_profile_title;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get edit_profile_name;

  /// Bio field label
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get edit_profile_bio;

  /// Social links section title
  ///
  /// In en, this message translates to:
  /// **'Social Links'**
  String get edit_profile_social_links;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get edit_profile_save_button;

  /// Profile save success message
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully'**
  String get edit_profile_save_success;

  /// Profile save error message
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile'**
  String get edit_profile_save_error;

  /// Security menu item
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get profile_security;

  /// Change password screen title
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password_title;

  /// Current password field label
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get change_password_current;

  /// New password field label
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get change_password_new;

  /// Confirm new password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get change_password_confirm;

  /// Current password validation error
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get change_password_current_required;

  /// New password validation error
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get change_password_new_required;

  /// Confirm password validation error
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get change_password_confirm_required;

  /// Password minimum length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get change_password_min_length;

  /// New password same as current validation error
  ///
  /// In en, this message translates to:
  /// **'New password must differ from current password'**
  String get change_password_same_as_current;

  /// Password mismatch validation error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get change_password_mismatch;

  /// Change password button text
  ///
  /// In en, this message translates to:
  /// **'CHANGE PASSWORD'**
  String get change_password_button;

  /// Password change success message
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get change_password_success;

  /// Password change error message
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get change_password_error;

  /// Current password incorrect error message
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get change_password_current_incorrect;

  /// Success dialog title
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get change_password_success_title;

  /// Error dialog title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get change_password_error_title;

  /// Warning message for account deletion
  ///
  /// In en, this message translates to:
  /// **'Deleting your account will permanently remove all your data, including results, statistics, and personal information.'**
  String get delete_account_warning;

  /// Delete account button text
  ///
  /// In en, this message translates to:
  /// **'DELETE ACCOUNT'**
  String get delete_account_button;

  /// Delete account confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get delete_account_confirm_title;

  /// Delete account confirmation dialog description
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data will be permanently deleted.'**
  String get delete_account_confirm_description;

  /// Delete account confirmation button text
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get delete_account_confirm_button;

  /// Add result screen title
  ///
  /// In en, this message translates to:
  /// **'Add Result'**
  String get add_result_title;

  /// Add result screen info text
  ///
  /// In en, this message translates to:
  /// **'Fill in the information about your race result. All fields marked with * are required.'**
  String get add_result_info;

  /// Location field label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get add_result_location;

  /// Location field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Cozumel, Mexico'**
  String get add_result_location_hint;

  /// Location validation error
  ///
  /// In en, this message translates to:
  /// **'Enter location'**
  String get add_result_location_required;

  /// Date field label
  ///
  /// In en, this message translates to:
  /// **'Race Date'**
  String get add_result_date;

  /// Date field hint
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get add_result_date_hint;

  /// Date validation error
  ///
  /// In en, this message translates to:
  /// **'Select race date'**
  String get add_result_date_required;

  /// Race type field label
  ///
  /// In en, this message translates to:
  /// **'Race Type'**
  String get add_result_race_type;

  /// Race type validation error
  ///
  /// In en, this message translates to:
  /// **'Select race type'**
  String get add_result_race_type_required;

  /// Total time field label
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get add_result_total_time;

  /// Total time validation error
  ///
  /// In en, this message translates to:
  /// **'Enter total time'**
  String get add_result_total_time_required;

  /// Swim time field label
  ///
  /// In en, this message translates to:
  /// **'Swim'**
  String get add_result_swim;

  /// T1 time field label
  ///
  /// In en, this message translates to:
  /// **'T1 (Transition 1)'**
  String get add_result_t1;

  /// Bike time field label
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get add_result_bike;

  /// T2 time field label
  ///
  /// In en, this message translates to:
  /// **'T2 (Transition 2)'**
  String get add_result_t2;

  /// Run time field label
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get add_result_run;

  /// Time format validation error
  ///
  /// In en, this message translates to:
  /// **'Format: HH:MM:SS'**
  String get add_result_time_format;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get add_result_save;

  /// Save success message stub
  ///
  /// In en, this message translates to:
  /// **'Result saved (stub)'**
  String get add_result_saved_stub;

  /// Basic information section title
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get add_result_section_basic_info;

  /// Time section title
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get add_result_section_time;

  /// Disciplines section title
  ///
  /// In en, this message translates to:
  /// **'Disciplines'**
  String get add_result_section_disciplines;

  /// T1 field label
  ///
  /// In en, this message translates to:
  /// **'T1'**
  String get add_result_t1_label;

  /// T2 field label
  ///
  /// In en, this message translates to:
  /// **'T2'**
  String get add_result_t2_label;

  /// Time format hint
  ///
  /// In en, this message translates to:
  /// **'HH:MM:SS'**
  String get add_result_time_hint;

  /// Ironman race type label
  ///
  /// In en, this message translates to:
  /// **'Ironman'**
  String get add_result_race_type_ironman;

  /// Ironman 70.3 race type label
  ///
  /// In en, this message translates to:
  /// **'Ironman 70.3'**
  String get add_result_race_type_ironman_70_3;

  /// 5150 race type label
  ///
  /// In en, this message translates to:
  /// **'5150'**
  String get add_result_race_type_5150;

  /// Success message title when result is submitted
  ///
  /// In en, this message translates to:
  /// **'Result submitted'**
  String get add_result_success_title;

  /// Success message when result is submitted for approval
  ///
  /// In en, this message translates to:
  /// **'Your result has been submitted for administrator approval. It will appear in the list after verification.'**
  String get add_result_success_message;

  /// Status label for approved result
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get add_result_approved;

  /// Status label for pending approval result
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get add_result_pending_approval;

  /// Ironman number label
  ///
  /// In en, this message translates to:
  /// **'Ironman Number'**
  String get athlete_profile_ironman_number;

  /// Bio section title
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get athlete_profile_bio;

  /// Social links section title
  ///
  /// In en, this message translates to:
  /// **'Social Links'**
  String get athlete_profile_social_links;

  /// Information not available message
  ///
  /// In en, this message translates to:
  /// **'Information not available'**
  String get athlete_profile_info_not_available;

  /// Social links not specified message
  ///
  /// In en, this message translates to:
  /// **'Social links not specified'**
  String get athlete_profile_social_links_not_specified;

  /// Server error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please try again later'**
  String get error_server_error;

  /// No internet connection error message
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again'**
  String get error_no_internet;

  /// Network connection error message
  ///
  /// In en, this message translates to:
  /// **'No internet connection available'**
  String get error_no_network_connection;

  /// OK button text for error alerts
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get error_ok;

  /// Network cooldown error message with seconds parameter
  ///
  /// In en, this message translates to:
  /// **'Please wait {seconds} seconds before trying again'**
  String error_cooldown(int seconds);

  /// General network error message
  ///
  /// In en, this message translates to:
  /// **'Network connection problem, please check your internet'**
  String get error_network_error;

  /// Unexpected error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred, please try again'**
  String get error_unexpected;

  /// My races screen title
  ///
  /// In en, this message translates to:
  /// **'Upcoming Races'**
  String get my_races_title;

  /// No races message for my races screen
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any upcoming races yet'**
  String get my_races_no_races;

  /// Delete button text for race swipe action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get my_races_delete;

  /// Notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications_title;

  /// Tooltip for mark all as read button
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notifications_mark_all_read_tooltip;

  /// Error message when marking all as read fails
  ///
  /// In en, this message translates to:
  /// **'Failed to mark all as read'**
  String get notifications_mark_all_read_error;

  /// Error message when deleting notification fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get notifications_delete_error;

  /// Empty notifications list message
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notifications_no_notifications;

  /// Fallback title for notification without title
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notifications_fallback_title;

  /// Notification detail screen title
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification_detail_title;

  /// Button text to close notification detail screen
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get notification_detail_understood;

  /// No description provided for @upcoming_completed.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get upcoming_completed;

  /// No description provided for @upcoming_day_label.
  ///
  /// In en, this message translates to:
  /// **'DAY'**
  String get upcoming_day_label;

  /// No description provided for @upcoming_days_label.
  ///
  /// In en, this message translates to:
  /// **'DAYS'**
  String get upcoming_days_label;

  /// No description provided for @home_sync_title.
  ///
  /// In en, this message translates to:
  /// **'Sync your past races'**
  String get home_sync_title;

  /// No description provided for @home_sync_description.
  ///
  /// In en, this message translates to:
  /// **'If you already have race results on ironman.az, we can sync them with your profile.'**
  String get home_sync_description;

  /// No description provided for @home_sync_button.
  ///
  /// In en, this message translates to:
  /// **'REQUEST SYNC'**
  String get home_sync_button;

  /// No description provided for @home_sync_requested.
  ///
  /// In en, this message translates to:
  /// **'Sync request sent. Your results will appear in the profile after processing.'**
  String get home_sync_requested;

  /// No description provided for @home_sync_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to send sync request'**
  String get home_sync_error;

  /// No description provided for @home_sync_error_timeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout. Please try again.'**
  String get home_sync_error_timeout;

  /// No description provided for @home_sync_error_network.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Check your network.'**
  String get home_sync_error_network;

  /// No description provided for @home_sync_error_server.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get home_sync_error_server;

  /// Email not verified screen title
  ///
  /// In en, this message translates to:
  /// **'Your email is not verified'**
  String get email_not_verified_title;

  /// Email verification message
  ///
  /// In en, this message translates to:
  /// **'Please check your email and click the link to verify your account.'**
  String get email_not_verified_message;

  /// Text before resend email button
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email?'**
  String get email_not_verified_no_email;

  /// Resend email button text
  ///
  /// In en, this message translates to:
  /// **'RESEND EMAIL'**
  String get email_not_verified_resend;

  /// Success message when email is resent
  ///
  /// In en, this message translates to:
  /// **'Email sent again'**
  String get email_not_verified_resend_success;

  /// Back to login button text
  ///
  /// In en, this message translates to:
  /// **'BACK TO LOGIN'**
  String get email_not_verified_back_to_login;

  /// Explanation of what happens when clicking back to login button
  ///
  /// In en, this message translates to:
  /// **'You are already logged in. Clicking this button will log you out and return you to the login screen.'**
  String get email_not_verified_back_to_login_description;

  /// Profile selection screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get profile_selection_title;

  /// Profile selection screen description
  ///
  /// In en, this message translates to:
  /// **'If your results are not on the site, tap \'Create new profile\' to create an athlete profile.'**
  String get profile_selection_description;

  /// Text about entering profile code
  ///
  /// In en, this message translates to:
  /// **'If your results are on ironman.az, enter the 6-character code provided by the administrator to link your profile.'**
  String get profile_selection_code_text;

  /// Profile code input field label
  ///
  /// In en, this message translates to:
  /// **'Profile code'**
  String get profile_selection_code_label;

  /// Profile code input field hint
  ///
  /// In en, this message translates to:
  /// **'Enter 6-character code'**
  String get profile_selection_code_hint;

  /// Code required validation message
  ///
  /// In en, this message translates to:
  /// **'Code is required'**
  String get profile_selection_code_required;

  /// Code length validation message
  ///
  /// In en, this message translates to:
  /// **'Code must be exactly 6 characters'**
  String get profile_selection_code_length;

  /// Code format validation message
  ///
  /// In en, this message translates to:
  /// **'Code contains invalid characters. Use only letters and numbers (excluding 0, O, I, L).'**
  String get profile_selection_code_invalid;

  /// Link profile button text
  ///
  /// In en, this message translates to:
  /// **'Link profile'**
  String get profile_selection_link_button;

  /// OR separator text
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get profile_selection_or;

  /// Search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get profile_selection_search;

  /// Results count label
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} =1{1 result} other{{count} results}}'**
  String profile_selection_results_count(int count);

  /// Select profile button text
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get profile_selection_select;

  /// Next button text to proceed with profile linking
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get profile_selection_next;

  /// Create new profile button text
  ///
  /// In en, this message translates to:
  /// **'Create new profile'**
  String get profile_selection_create_new;

  /// Loading profiles message
  ///
  /// In en, this message translates to:
  /// **'Loading profiles...'**
  String get profile_selection_loading;

  /// No profiles available message
  ///
  /// In en, this message translates to:
  /// **'No available profiles'**
  String get profile_selection_no_profiles;

  /// Profile linked success message
  ///
  /// In en, this message translates to:
  /// **'Profile linked successfully'**
  String get profile_selection_link_success;

  /// Profile created success message
  ///
  /// In en, this message translates to:
  /// **'Profile created successfully'**
  String get profile_selection_create_success;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Connection error. Check your network.'**
  String get profile_selection_error_network;

  /// Server error message
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get profile_selection_error_server;

  /// Profile already linked error message
  ///
  /// In en, this message translates to:
  /// **'This profile is already linked to another user'**
  String get profile_selection_error_already_linked;

  /// Code not found error message
  ///
  /// In en, this message translates to:
  /// **'Code not found or invalid'**
  String get profile_selection_error_code_not_found;

  /// Code already used error message
  ///
  /// In en, this message translates to:
  /// **'This code has already been used'**
  String get profile_selection_error_code_already_used;

  /// Code already linked error message
  ///
  /// In en, this message translates to:
  /// **'Profile with this code is already linked to another user'**
  String get profile_selection_error_code_already_linked;

  /// Profile already exists error message
  ///
  /// In en, this message translates to:
  /// **'You already have a linked profile'**
  String get profile_selection_error_profile_already_exists;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profile_selection_logout;

  /// Title for notification permission disabled banner
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notification_permission_disabled_title;

  /// Message for notification permission disabled banner
  ///
  /// In en, this message translates to:
  /// **'You can enable them in settings'**
  String get notification_permission_disabled_message;

  /// Button text to open app settings
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get notification_permission_open_settings;

  /// No description provided for @pace_calculator_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get pace_calculator_done;

  /// No description provided for @pace_calculator_tab_full.
  ///
  /// In en, this message translates to:
  /// **'IRONMAN'**
  String get pace_calculator_tab_full;

  /// No description provided for @pace_calculator_tab_70_3.
  ///
  /// In en, this message translates to:
  /// **'IRONMAN 70.3'**
  String get pace_calculator_tab_70_3;

  /// No description provided for @pace_calculator_tab_5150.
  ///
  /// In en, this message translates to:
  /// **'5150'**
  String get pace_calculator_tab_5150;

  /// No description provided for @pace_calculator_appbar_title.
  ///
  /// In en, this message translates to:
  /// **'Pace Calculator'**
  String get pace_calculator_appbar_title;

  /// No description provided for @pace_calculator_total_race_time.
  ///
  /// In en, this message translates to:
  /// **'TOTAL RACE TIME'**
  String get pace_calculator_total_race_time;

  /// No description provided for @pace_calculator_km_unit.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get pace_calculator_km_unit;

  /// No description provided for @pace_calculator_min_per_100m.
  ///
  /// In en, this message translates to:
  /// **'min / 100m'**
  String get pace_calculator_min_per_100m;

  /// No description provided for @pace_calculator_km_per_h.
  ///
  /// In en, this message translates to:
  /// **'km / h'**
  String get pace_calculator_km_per_h;

  /// No description provided for @pace_calculator_min_per_km.
  ///
  /// In en, this message translates to:
  /// **'min / km'**
  String get pace_calculator_min_per_km;

  /// No description provided for @pace_calculator_swim_time.
  ///
  /// In en, this message translates to:
  /// **'Swim'**
  String get pace_calculator_swim_time;

  /// No description provided for @pace_calculator_t1_time.
  ///
  /// In en, this message translates to:
  /// **'T1'**
  String get pace_calculator_t1_time;

  /// No description provided for @pace_calculator_bike_time.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get pace_calculator_bike_time;

  /// No description provided for @pace_calculator_t2_time.
  ///
  /// In en, this message translates to:
  /// **'T2'**
  String get pace_calculator_t2_time;

  /// No description provided for @pace_calculator_run_time.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get pace_calculator_run_time;

  /// No description provided for @home_pace_calculator_title.
  ///
  /// In en, this message translates to:
  /// **'Pace Calculator'**
  String get home_pace_calculator_title;

  /// No description provided for @home_pace_calculator_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Swimming • Cycling • Running'**
  String get home_pace_calculator_subtitle;

  /// No description provided for @home_pace_calculator_button.
  ///
  /// In en, this message translates to:
  /// **'CALCULATE'**
  String get home_pace_calculator_button;

  /// No description provided for @home_card_pace_title.
  ///
  /// In en, this message translates to:
  /// **'Pace Calculator'**
  String get home_card_pace_title;

  /// No description provided for @home_card_pace_subtitle.
  ///
  /// In en, this message translates to:
  /// **'SWIMMING • CYCLING • RUNNING'**
  String get home_card_pace_subtitle;

  /// No description provided for @home_card_pace_helper.
  ///
  /// In en, this message translates to:
  /// **'Race tools'**
  String get home_card_pace_helper;

  /// No description provided for @home_card_pace_button.
  ///
  /// In en, this message translates to:
  /// **'CALCULATE'**
  String get home_card_pace_button;

  /// No description provided for @home_card_profile_title.
  ///
  /// In en, this message translates to:
  /// **'Athlete Cabinet'**
  String get home_card_profile_title;

  /// No description provided for @home_card_profile_subtitle.
  ///
  /// In en, this message translates to:
  /// **'RESULTS • RATINGS • PROFILE'**
  String get home_card_profile_subtitle;

  /// No description provided for @home_card_profile_helper.
  ///
  /// In en, this message translates to:
  /// **'Competitive results'**
  String get home_card_profile_helper;

  /// No description provided for @home_card_profile_button.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get home_card_profile_button;

  /// No description provided for @events_tab_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get events_tab_active;

  /// No description provided for @events_tab_past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get events_tab_past;

  /// No description provided for @events_no_past_races.
  ///
  /// In en, this message translates to:
  /// **'No past races'**
  String get events_no_past_races;

  /// No description provided for @athlete_rating_title.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get athlete_rating_title;

  /// No description provided for @athlete_rating_info.
  ///
  /// In en, this message translates to:
  /// **'Rating is calculated based on results data from this application'**
  String get athlete_rating_info;

  /// No description provided for @reset_password_title.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get reset_password_title;

  /// No description provided for @reset_password_description.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password.'**
  String get reset_password_description;

  /// No description provided for @reset_password_send_button.
  ///
  /// In en, this message translates to:
  /// **'SEND EMAIL'**
  String get reset_password_send_button;

  /// No description provided for @reset_password_remember.
  ///
  /// In en, this message translates to:
  /// **'Remember your password?'**
  String get reset_password_remember;

  /// No description provided for @reset_password_sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get reset_password_sign_in;

  /// Notification permission card title
  ///
  /// In en, this message translates to:
  /// **'Stay updated!'**
  String get dashboard_notification_card_title;

  /// Notification permission card message
  ///
  /// In en, this message translates to:
  /// **'Get notified about your race results, upcoming events and important updates.'**
  String get dashboard_notification_card_message;

  /// Enable notifications button
  ///
  /// In en, this message translates to:
  /// **'Yes, enable'**
  String get dashboard_notification_card_enable;

  /// Maybe later button
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get dashboard_notification_card_later;

  /// Title when user has no transfer request
  ///
  /// In en, this message translates to:
  /// **'Transfer Results'**
  String get transfer_no_request_title;

  /// Description when user has no transfer request
  ///
  /// In en, this message translates to:
  /// **'If your results are on ironman.az website, we can transfer them'**
  String get transfer_no_request_description;

  /// Button text to start transfer process
  ///
  /// In en, this message translates to:
  /// **'Attach Results'**
  String get transfer_attach_results;

  /// Status text for pending transfer request
  ///
  /// In en, this message translates to:
  /// **'Request Pending'**
  String get transfer_status_pending;

  /// Description for pending transfer status
  ///
  /// In en, this message translates to:
  /// **'Your transfer request is being reviewed'**
  String get transfer_status_pending_description;

  /// Status text for approved transfer request
  ///
  /// In en, this message translates to:
  /// **'Request Approved'**
  String get transfer_status_approved;

  /// Description for approved transfer status
  ///
  /// In en, this message translates to:
  /// **'Your results have been successfully transferred'**
  String get transfer_status_approved_description;

  /// Status text for rejected transfer request
  ///
  /// In en, this message translates to:
  /// **'Request Rejected'**
  String get transfer_status_rejected;

  /// Description for rejected transfer status
  ///
  /// In en, this message translates to:
  /// **'Your transfer request was rejected'**
  String get transfer_status_rejected_description;

  /// Button text to submit new transfer request after rejection
  ///
  /// In en, this message translates to:
  /// **'Submit Again'**
  String get transfer_submit_again;

  /// Shows source athlete name
  ///
  /// In en, this message translates to:
  /// **'From: {name}'**
  String transfer_source_athlete(String name);

  /// BottomSheet title for athlete selection
  ///
  /// In en, this message translates to:
  /// **'Select Athlete'**
  String get transfer_select_athlete;

  /// Search field placeholder in athlete selection
  ///
  /// In en, this message translates to:
  /// **'Search athletes...'**
  String get transfer_search_athletes;

  /// Empty state message in athlete search
  ///
  /// In en, this message translates to:
  /// **'Start typing to search for athletes'**
  String get transfer_start_typing;

  /// Empty results message in athlete search
  ///
  /// In en, this message translates to:
  /// **'No athletes found'**
  String get transfer_no_athletes_found;

  /// Results count for athlete
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} =1{1 result} other{{count} results}}'**
  String transfer_results_count(int count);

  /// Shows athlete's last race location
  ///
  /// In en, this message translates to:
  /// **'Last race: {location}'**
  String transfer_last_race(String location);

  /// Success message after creating transfer request
  ///
  /// In en, this message translates to:
  /// **'Transfer request created successfully'**
  String get transfer_request_created;

  /// Error message when transfer request creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create transfer request'**
  String get transfer_request_error;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Transfer'**
  String get transfer_confirm_title;

  /// Confirmation dialog description
  ///
  /// In en, this message translates to:
  /// **'Request to transfer results from {name} to your profile?'**
  String transfer_confirm_description(String name);

  /// Confirm button in confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get transfer_confirm_button;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['az', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'az':
      return AppLocalizationsAz();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
