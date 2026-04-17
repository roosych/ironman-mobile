// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'TriRank';

  @override
  String get login_title => 'Sign in to your account';

  @override
  String get login_email => 'Email';

  @override
  String get login_password => 'Password';

  @override
  String get login_button => 'SIGN IN';

  @override
  String get login_email_required => 'Enter email';

  @override
  String get login_email_invalid => 'Invalid email';

  @override
  String get login_password_required => 'Enter password';

  @override
  String get login_forgot_password => 'Forgot password?';

  @override
  String get login_no_account => 'Don\'t have an account?';

  @override
  String get login_create_account => 'Create account';

  @override
  String get login_loading => 'Loading...';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_language => 'Language';

  @override
  String get language_russian => 'Русский';

  @override
  String get language_english => 'English';

  @override
  String get language_azerbaijani => 'Azərbaycan';

  @override
  String get logout_button => 'LOG OUT';

  @override
  String get profile_title => 'Profile';

  @override
  String get profile_information => 'Information';

  @override
  String get profile_photo_gallery => 'Photo Gallery';

  @override
  String get profile_workouts => 'Workouts';

  @override
  String get profile_user_fallback => 'User';

  @override
  String get common_coming_soon => 'coming soon';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_ok => 'OK';

  @override
  String get common_undo => 'Undo';

  @override
  String get common_all => 'All';

  @override
  String get common_loading_error => 'Loading error';

  @override
  String get home_upcoming_races => 'Upcoming Races';

  @override
  String get home_personal_bests => 'Personal Bests';

  @override
  String get home_greeting => 'Hello,';

  @override
  String get home_greeting_welcome => 'Welcome back,';

  @override
  String get home_finishes => 'finishes';

  @override
  String home_finishes_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'finishes',
      one: 'finish',
    );
    return '$_temp0';
  }

  @override
  String get home_add_race => 'Add Race';

  @override
  String get home_add_race_title => 'Add Race';

  @override
  String get race_selection_title => 'Select Race';

  @override
  String get race_selection_search_hint => 'Search races...';

  @override
  String get race_selection_save => 'Save';

  @override
  String get race_selection_no_races => 'No races found';

  @override
  String get race_selection_confirm_title => 'Add Race';

  @override
  String get race_selection_confirm_description =>
      'Add this race to your upcoming races?';

  @override
  String get race_selection_success => 'Race added successfully';

  @override
  String get home_no_upcoming_races => 'No upcoming races';

  @override
  String get common_no_data => 'No data';

  @override
  String get common_today => 'Today';

  @override
  String common_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get results_title => 'Results';

  @override
  String get result_detail_title => 'Result';

  @override
  String get results_my_results => 'My Results';

  @override
  String get results_all_athletes => 'All Athletes';

  @override
  String get results_no_results => 'No results';

  @override
  String get home_no_personal_bests => 'No personal bests yet';

  @override
  String get results_all_coming_soon => 'All athletes results coming soon';

  @override
  String get news_title => 'News';

  @override
  String get news_coming_soon => 'News coming soon';

  @override
  String get news_working_on_section =>
      'We are working on this section. Stay tuned for updates!';

  @override
  String get ratings_title => 'Ratings';

  @override
  String get ratings_coming_soon => 'Ratings coming soon';

  @override
  String get ratings_working_on_section =>
      'We are working on this section. Stay tuned for updates!';

  @override
  String get ratings_by_race_type => 'By Race Type';

  @override
  String get ratings_by_discipline => 'By Discipline';

  @override
  String get ratings_filter_race_type => 'Race Type';

  @override
  String get ratings_filter_discipline => 'Discipline';

  @override
  String get ratings_discipline_total => 'Total';

  @override
  String get ratings_discipline_swim => 'Swim';

  @override
  String get ratings_discipline_bike => 'Bike';

  @override
  String get ratings_discipline_run => 'Run';

  @override
  String get ratings_no_rankings => 'No rankings';

  @override
  String get ratings_position => 'Position';

  @override
  String get ratings_record_date => 'Record Date';

  @override
  String get ratings_record_location => 'Record Location';

  @override
  String get ratings_compare => 'Compare';

  @override
  String get ratings_disciplines_comparison =>
      'Discipline comparison by athlete\'s best records';

  @override
  String get ratings_compare_records => 'Compare personal records';

  @override
  String ratings_faster_by(String name, String time) {
    return '$name is faster by $time';
  }

  @override
  String get unit_sec => 'sec';

  @override
  String get unit_min => 'min';

  @override
  String get unit_hr => 'hr';

  @override
  String get ratings_race_type_full => 'FULL 140.6';

  @override
  String get ratings_race_type_half => 'HALF 70.3';

  @override
  String get ratings_select_two_athletes => 'Select 2 athletes to compare';

  @override
  String get ratings_clear_selection => 'Clear selection';

  @override
  String get ratings_time => 'Time';

  @override
  String get ratings_difference => 'Difference';

  @override
  String get ratings_tap_to_compare_hint => 'Tap on an athlete to compare';

  @override
  String get athletes_title => 'Athletes';

  @override
  String get athletes_coming_soon => 'Athletes screen — coming soon';

  @override
  String get athletes_list_title => 'Athletes';

  @override
  String get athletes_search_hint => 'Search';

  @override
  String get athletes_filter_registered => 'Registered';

  @override
  String get athletes_filter_new => 'New';

  @override
  String get athletes_status_registered => 'Registered';

  @override
  String get athletes_invite_button => 'INVITE';

  @override
  String get athlete_profile_title => 'Athlete Profile';

  @override
  String get athlete_profile_info_tab => 'Info';

  @override
  String get athlete_profile_results_tab => 'Results';

  @override
  String get athlete_profile_best_by_race_type => 'Best by race type';

  @override
  String get athlete_profile_by_disciplines => 'By disciplines';

  @override
  String get athlete_profile_swimming => 'Swimming';

  @override
  String get athlete_profile_cycling => 'Cycling';

  @override
  String get athlete_profile_running => 'Running';

  @override
  String get athlete_profile_personal_bests => 'Records';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_results => 'Results';

  @override
  String get nav_ratings => 'Ratings';

  @override
  String get nav_athletes => 'Athletes';

  @override
  String get nav_login => 'Sign In';

  @override
  String get photo_delete_title => 'Delete photo?';

  @override
  String get photo_delete_avatar_warning =>
      'This photo is your avatar. After deletion, the avatar will be reset.';

  @override
  String get photo_delete_irreversible => 'This action cannot be undone.';

  @override
  String get photo_delete_button => 'Delete';

  @override
  String get photo_deleted => 'Photo deleted';

  @override
  String get photo_uploaded => 'Photo uploaded';

  @override
  String get photo_already_avatar => 'This photo is already set as avatar';

  @override
  String get photo_set_avatar_title => 'Set as avatar?';

  @override
  String get photo_set_avatar_description =>
      'This photo will be used as your avatar in the profile.';

  @override
  String get photo_set_button => 'Set';

  @override
  String get photo_set_as_avatar => 'Set as avatar';

  @override
  String get photo_avatar => 'Avatar';

  @override
  String get photo_delete => 'Delete';

  @override
  String get photo_avatar_updated => 'Avatar successfully updated';

  @override
  String get photo_avatar_set_error => 'Failed to set avatar';

  @override
  String get photo_pending_approval => 'Pending';

  @override
  String get photo_add_button => 'Add';

  @override
  String get result_total_time => 'Total Time';

  @override
  String get result_category => 'Category';

  @override
  String get result_disciplines => 'Disciplines';

  @override
  String get result_swim => 'Swim';

  @override
  String get result_t1 => 'T1';

  @override
  String get result_bike => 'Bike';

  @override
  String get result_t2 => 'T2';

  @override
  String get result_run => 'Run';

  @override
  String get register_sign_in => 'Sign in';

  @override
  String get register_title => 'Create account';

  @override
  String get register_name => 'Full name';

  @override
  String get register_name_required => 'Enter full name';

  @override
  String get register_confirm_password => 'Confirm password';

  @override
  String get register_confirm_password_required => 'Confirm password';

  @override
  String get register_password_min_length =>
      'Password must be at least 6 characters';

  @override
  String get register_passwords_not_match => 'Passwords do not match';

  @override
  String get register_button => 'SIGN UP';

  @override
  String get register_already_have_account => 'Already have an account?';

  @override
  String get register_privacy_policy_agree => 'I agree with the ';

  @override
  String get register_privacy_policy_link => 'Privacy Policy';

  @override
  String get register_privacy_policy_required =>
      'You must agree to the Privacy Policy';

  @override
  String get policies_title => 'Policies';

  @override
  String get settings_policies_and_terms => 'Policies and Terms';

  @override
  String get policy_not_available => 'Policy not available';

  @override
  String get policy_load_error => 'Failed to load policy';

  @override
  String get retry => 'Retry';

  @override
  String get register_thank_you => 'Thank you!';

  @override
  String get register_success_message =>
      'Registration successful.\nPlease verify your account by clicking the link in the email we sent you.\nYou can then sign in to your account.';

  @override
  String get register_confirm_email =>
      'Please check your inbox and confirm your email address to activate your account.';

  @override
  String get register_success_sign_in => 'SIGN IN';

  @override
  String get register_select_country => 'Select country';

  @override
  String get register_search_countries => 'Search countries';

  @override
  String get settings_language_changed => 'Language changed';

  @override
  String get edit_profile_title => 'Athlete Info';

  @override
  String get edit_profile_name => 'Name';

  @override
  String get edit_profile_bio => 'Bio';

  @override
  String get edit_profile_social_links => 'Social Links';

  @override
  String get edit_profile_save_button => 'Save';

  @override
  String get edit_profile_save_success => 'Profile saved successfully';

  @override
  String get edit_profile_save_error => 'Failed to save profile';

  @override
  String get profile_security => 'Security';

  @override
  String get change_password_title => 'Change Password';

  @override
  String get change_password_current => 'Current Password';

  @override
  String get change_password_new => 'New Password';

  @override
  String get change_password_confirm => 'Confirm New Password';

  @override
  String get change_password_current_required => 'Enter current password';

  @override
  String get change_password_new_required => 'Enter new password';

  @override
  String get change_password_confirm_required => 'Confirm new password';

  @override
  String get change_password_min_length =>
      'Password must be at least 8 characters';

  @override
  String get change_password_same_as_current =>
      'New password must differ from current password';

  @override
  String get change_password_mismatch => 'Passwords do not match';

  @override
  String get change_password_button => 'CHANGE PASSWORD';

  @override
  String get change_password_success => 'Password changed successfully';

  @override
  String get change_password_error => 'Failed to change password';

  @override
  String get change_password_current_incorrect =>
      'Current password is incorrect';

  @override
  String get change_password_success_title => 'Success!';

  @override
  String get change_password_error_title => 'Error';

  @override
  String get delete_account_warning =>
      'Deleting your account will permanently remove all your data, including results, statistics, and personal information.';

  @override
  String get delete_account_button => 'DELETE ACCOUNT';

  @override
  String get delete_account_confirm_title => 'Delete Account?';

  @override
  String get delete_account_confirm_description =>
      'This action cannot be undone. All your data will be permanently deleted.';

  @override
  String get delete_account_confirm_button => 'DELETE';

  @override
  String get add_result_title => 'Add Result';

  @override
  String get add_result_info =>
      'Fill in the information about your race result. All fields marked with * are required.';

  @override
  String get add_result_location => 'Location';

  @override
  String get add_result_location_hint => 'e.g. Cozumel, Mexico';

  @override
  String get add_result_location_required => 'Enter location';

  @override
  String get add_result_date => 'Race Date';

  @override
  String get add_result_date_hint => 'Select date';

  @override
  String get add_result_date_required => 'Select race date';

  @override
  String get add_result_race_type => 'Race Type';

  @override
  String get add_result_race_type_required => 'Select race type';

  @override
  String get add_result_total_time => 'Total Time';

  @override
  String get add_result_total_time_required => 'Enter total time';

  @override
  String get add_result_swim => 'Swim';

  @override
  String get add_result_t1 => 'T1 (Transition 1)';

  @override
  String get add_result_bike => 'Bike';

  @override
  String get add_result_t2 => 'T2 (Transition 2)';

  @override
  String get add_result_run => 'Run';

  @override
  String get add_result_time_format => 'Format: HH:MM:SS';

  @override
  String get add_result_save => 'SAVE';

  @override
  String get add_result_saved_stub => 'Result saved (stub)';

  @override
  String get add_result_section_basic_info => 'Basic Information';

  @override
  String get add_result_section_time => 'Time';

  @override
  String get add_result_section_disciplines => 'Disciplines';

  @override
  String get add_result_t1_label => 'T1';

  @override
  String get add_result_t2_label => 'T2';

  @override
  String get add_result_time_hint => 'HH:MM:SS';

  @override
  String get add_result_race_type_ironman => 'Ironman';

  @override
  String get add_result_race_type_ironman_70_3 => 'Ironman 70.3';

  @override
  String get add_result_race_type_5150 => '5150';

  @override
  String get add_result_success_title => 'Result submitted';

  @override
  String get add_result_success_message =>
      'Your result has been submitted for administrator approval. It will appear in the list after verification.';

  @override
  String get add_result_approved => 'Approved';

  @override
  String get add_result_pending_approval => 'Pending approval';

  @override
  String get athlete_profile_ironman_number => 'Ironman Number';

  @override
  String get athlete_profile_bio => 'Bio';

  @override
  String get athlete_profile_social_links => 'Social Links';

  @override
  String get athlete_profile_info_not_available => 'Information not available';

  @override
  String get athlete_profile_social_links_not_specified =>
      'Social links not specified';

  @override
  String get athlete_profile_photos_tab => 'Photos';

  @override
  String get athlete_profile_no_photos => 'No photos yet';

  @override
  String get error_server_error =>
      'Something went wrong, please try again later';

  @override
  String get error_no_internet =>
      'Check your internet connection and try again';

  @override
  String get error_no_network_connection => 'No internet connection available';

  @override
  String get error_ok => 'OK';

  @override
  String error_cooldown(int seconds) {
    return 'Please wait $seconds seconds before trying again';
  }

  @override
  String get error_network_error =>
      'Network connection problem, please check your internet';

  @override
  String get error_unexpected =>
      'An unexpected error occurred, please try again';

  @override
  String get my_races_title => 'My Upcoming Races';

  @override
  String get my_races_no_races => 'You don\'t have any upcoming races yet';

  @override
  String get my_races_delete => 'Delete';

  @override
  String get notifications_title => 'Notifications';

  @override
  String get notifications_mark_all_read_tooltip => 'Mark all as read';

  @override
  String get notifications_mark_all_read_error => 'Failed to mark all as read';

  @override
  String get notifications_delete_error => 'Failed to delete';

  @override
  String get notifications_no_notifications => 'No notifications';

  @override
  String get notifications_fallback_title => 'Notification';

  @override
  String get notification_detail_title => 'Notification';

  @override
  String get notification_detail_understood => 'Got it';

  @override
  String get upcoming_completed => 'COMPLETED';

  @override
  String get upcoming_participated => 'Finished';

  @override
  String get upcoming_did_not_participate => 'No, remove';

  @override
  String get upcoming_finished_confirm_title => 'Did you finish?';

  @override
  String get upcoming_finished_confirm_body =>
      'Would you like to add a result for this race?';

  @override
  String get upcoming_finished_yes => 'Yes';

  @override
  String get upcoming_finished_no => 'No';

  @override
  String get upcoming_delete_confirm_title => 'Remove race?';

  @override
  String get upcoming_delete_confirm_body =>
      'The race will be removed from your list. This action cannot be undone.';

  @override
  String get upcoming_delete_confirm_button => 'Remove';

  @override
  String get upcoming_day_label => 'DAY';

  @override
  String get upcoming_days_label => 'DAYS';

  @override
  String get home_sync_title => 'Sync your past races';

  @override
  String get home_sync_description =>
      'If you already have race results on ironman.az, we can sync them with your profile.';

  @override
  String get home_sync_button => 'REQUEST SYNC';

  @override
  String get home_sync_requested =>
      'Sync request sent. Your results will appear in the profile after processing.';

  @override
  String get home_sync_error => 'Failed to send sync request';

  @override
  String get home_sync_error_timeout => 'Connection timeout. Please try again.';

  @override
  String get home_sync_error_network => 'Connection error. Check your network.';

  @override
  String get home_sync_error_server => 'Server error';

  @override
  String get email_not_verified_title => 'Your email is not verified';

  @override
  String get email_not_verified_message =>
      'Please check your email and click the link to verify your account.';

  @override
  String get email_not_verified_no_email => 'Didn\'t receive the email?';

  @override
  String get email_not_verified_resend => 'RESEND EMAIL';

  @override
  String get email_not_verified_resend_success => 'Email sent again';

  @override
  String get email_not_verified_back_to_login => 'BACK TO LOGIN';

  @override
  String get email_not_verified_back_to_login_description =>
      'You are already logged in. Clicking this button will log you out and return you to the login screen.';

  @override
  String get profile_selection_title => 'Welcome!';

  @override
  String get profile_selection_description =>
      'If your results are not on the site, tap \'Create new profile\' to create an athlete profile.';

  @override
  String get profile_selection_code_text =>
      'If your results are on ironman.az, enter the 6-character code provided by the administrator to link your profile.';

  @override
  String get profile_selection_code_label => 'Profile code';

  @override
  String get profile_selection_code_hint => 'Enter 6-character code';

  @override
  String get profile_selection_code_required => 'Code is required';

  @override
  String get profile_selection_code_length =>
      'Code must be exactly 6 characters';

  @override
  String get profile_selection_code_invalid =>
      'Code contains invalid characters. Use only letters and numbers (excluding 0, O, I, L).';

  @override
  String get profile_selection_link_button => 'Link profile';

  @override
  String get profile_selection_or => 'OR';

  @override
  String get profile_selection_search => 'Search';

  @override
  String profile_selection_results_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get profile_selection_select => 'Select';

  @override
  String get profile_selection_next => 'Next';

  @override
  String get profile_selection_create_new => 'Create new profile';

  @override
  String get profile_selection_loading => 'Loading profiles...';

  @override
  String get profile_selection_no_profiles => 'No available profiles';

  @override
  String get profile_selection_link_success => 'Profile linked successfully';

  @override
  String get profile_selection_create_success => 'Profile created successfully';

  @override
  String get profile_selection_error_network =>
      'Connection error. Check your network.';

  @override
  String get profile_selection_error_server =>
      'Server error. Please try again later.';

  @override
  String get profile_selection_error_already_linked =>
      'This profile is already linked to another user';

  @override
  String get profile_selection_error_code_not_found =>
      'Code not found or invalid';

  @override
  String get profile_selection_error_code_already_used =>
      'This code has already been used';

  @override
  String get profile_selection_error_code_already_linked =>
      'Profile with this code is already linked to another user';

  @override
  String get profile_selection_error_profile_already_exists =>
      'You already have a linked profile';

  @override
  String get profile_selection_logout => 'Log out';

  @override
  String get notification_permission_disabled_title => 'Notifications disabled';

  @override
  String get notification_permission_disabled_message =>
      'You can enable them in settings';

  @override
  String get notification_permission_open_settings => 'Open settings';

  @override
  String get pace_calculator_done => 'Done';

  @override
  String get pace_calculator_tab_full => 'IRONMAN';

  @override
  String get pace_calculator_tab_70_3 => 'IRONMAN 70.3';

  @override
  String get pace_calculator_tab_5150 => '5150';

  @override
  String get pace_calculator_appbar_title => 'Pace Calculator';

  @override
  String get pace_calculator_total_race_time => 'TOTAL RACE TIME';

  @override
  String get pace_calculator_km_unit => 'km';

  @override
  String get pace_calculator_min_per_100m => 'min / 100m';

  @override
  String get pace_calculator_km_per_h => 'km / h';

  @override
  String get pace_calculator_min_per_km => 'min / km';

  @override
  String get pace_calculator_swim_time => 'Swim';

  @override
  String get pace_calculator_t1_time => 'T1';

  @override
  String get pace_calculator_bike_time => 'Bike';

  @override
  String get pace_calculator_t2_time => 'T2';

  @override
  String get pace_calculator_run_time => 'Run';

  @override
  String get home_pace_calculator_title => 'Pace Calculator';

  @override
  String get home_pace_calculator_subtitle => 'Swimming • Cycling • Running';

  @override
  String get home_pace_calculator_button => 'CALCULATE';

  @override
  String get home_card_pace_title => 'Pace Calculator';

  @override
  String get home_card_pace_subtitle => 'SWIMMING • CYCLING • RUNNING';

  @override
  String get home_card_pace_helper => 'Race tools';

  @override
  String get home_card_pace_button => 'CALCULATE';

  @override
  String get home_card_profile_title => 'Athlete Cabinet';

  @override
  String get home_card_profile_subtitle => 'RESULTS • RATINGS • PROFILE';

  @override
  String get home_card_profile_helper => 'Competitive results';

  @override
  String get home_card_profile_button => 'PROFILE';

  @override
  String get events_tab_active => 'Active';

  @override
  String get events_tab_past => 'Past';

  @override
  String get events_no_past_races => 'No past races';

  @override
  String get athlete_rating_title => 'Rating';

  @override
  String get athlete_rating_info =>
      'Rating is calculated based on results data from this application';

  @override
  String get reset_password_title => 'Reset Password';

  @override
  String get reset_password_description =>
      'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get reset_password_send_button => 'SEND';

  @override
  String get reset_password_remember => 'Remember your password?';

  @override
  String get reset_password_sign_in => 'Sign in';

  @override
  String get reset_password_otp => 'OTP Code';

  @override
  String get reset_password_otp_required =>
      'Enter the OTP code from your email';

  @override
  String get reset_password_confirm_button => 'RESET PASSWORD';

  @override
  String get reset_password_resend_button => 'Send again';

  @override
  String get dashboard_notification_card_title => 'Stay updated!';

  @override
  String get dashboard_notification_card_message =>
      'Get notified about your race results, upcoming events and important updates.';

  @override
  String get dashboard_notification_card_enable => 'Yes, enable';

  @override
  String get dashboard_notification_card_later => 'Maybe later';

  @override
  String get transfer_no_request_title => 'Transfer Results';

  @override
  String get transfer_no_request_description =>
      'If your results are on ironman.az website, we can transfer them';

  @override
  String get transfer_attach_results => 'Attach Results';

  @override
  String get transfer_status_pending => 'Request Pending';

  @override
  String get transfer_status_pending_description =>
      'Your transfer request is being reviewed';

  @override
  String get transfer_status_approved => 'Request Approved';

  @override
  String get transfer_status_approved_description =>
      'Your results have been successfully transferred';

  @override
  String get transfer_status_rejected => 'Request Rejected';

  @override
  String get transfer_status_rejected_description =>
      'Your transfer request was rejected';

  @override
  String get transfer_submit_again => 'Submit Again';

  @override
  String transfer_source_athlete(String name) {
    return 'From: $name';
  }

  @override
  String get transfer_select_athlete => 'Select Athlete';

  @override
  String get transfer_search_athletes => 'Search athletes...';

  @override
  String get transfer_start_typing => 'Start typing to search for athletes';

  @override
  String get transfer_no_athletes_found => 'No athletes found';

  @override
  String transfer_results_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String transfer_last_race(String location) {
    return 'Last race: $location';
  }

  @override
  String get transfer_request_created =>
      'Transfer request created successfully';

  @override
  String get transfer_request_error => 'Failed to create transfer request';

  @override
  String get transfer_confirm_title => 'Confirm Transfer';

  @override
  String transfer_confirm_description(String name) {
    return 'Request to transfer results from $name to your profile?';
  }

  @override
  String get transfer_confirm_button => 'Confirm';

  @override
  String get api_error_empty_response => 'Empty response from server';

  @override
  String get api_error_timeout => 'Request timeout exceeded';

  @override
  String get api_error_network_no_connection => 'No internet connection';

  @override
  String api_error_http_status(int status) {
    return 'Loading error (HTTP $status)';
  }

  @override
  String api_error_generic(String message) {
    return 'Loading error: $message';
  }

  @override
  String api_error_unexpected(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get api_error_invalid_data_format =>
      'Expected data list, received different type';

  @override
  String get api_error_invalid_item_format => 'Invalid data item format';

  @override
  String get api_error_races_format =>
      'Expected races list, received different type';

  @override
  String get api_error_race_item_format => 'Invalid race item format';

  @override
  String get api_error_rankings_format =>
      'Expected rankings list, received different type';

  @override
  String get api_error_ranking_item_format => 'Invalid ranking item format';

  @override
  String get api_error_athletes_format =>
      'Expected athletes list, received different type';

  @override
  String get api_error_athlete_item_format => 'Invalid athlete item format';

  @override
  String get api_error_athlete_object_format =>
      'Expected athlete object, received different type';

  @override
  String get api_error_athlete_not_found => 'Failed to get athlete data';

  @override
  String get api_error_records_object_format =>
      'Expected records object, received different type';

  @override
  String get api_error_records_not_found => 'Failed to get records data';

  @override
  String get api_error_upcoming_race_create_failed => 'Failed to create race';

  @override
  String get api_error_upcoming_race_object_format =>
      'Expected race object, received different type';

  @override
  String api_error_server(String status) {
    return 'Server error ($status)';
  }

  @override
  String get api_error_athletes_loading =>
      'An error occurred while loading athletes';

  @override
  String get transfer_api_conflict => 'Conflict when creating request';

  @override
  String get transfer_api_validation => 'Data validation error';

  @override
  String get transfer_api_server_error =>
      'An error occurred while contacting the server';

  @override
  String get transfer_status_timeout => 'Request timeout when updating status';

  @override
  String get transfer_status_load_failed =>
      'Failed to load transfer request status';

  @override
  String get transfer_status_create_failed =>
      'Failed to create transfer request';

  @override
  String get transfer_status_update_failed =>
      'Failed to update transfer status';

  @override
  String get api_error_transfer_create_failed =>
      'Failed to create transfer request';
}
