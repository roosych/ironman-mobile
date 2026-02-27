// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppLocalizationsAz extends AppLocalizations {
  AppLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get app_title => 'IRONSTATS';

  @override
  String get login_title => 'Hesabınıza daxil olun';

  @override
  String get login_email => 'Email';

  @override
  String get login_password => 'Şifrə';

  @override
  String get login_button => 'DAXİL OL';

  @override
  String get login_email_required => 'Email daxil edin';

  @override
  String get login_email_invalid => 'Yanlış email';

  @override
  String get login_password_required => 'Şifrə daxil edin';

  @override
  String get login_forgot_password => 'Şifrəni unutmusunuz?';

  @override
  String get login_no_account => 'Hesabınız yoxdur?';

  @override
  String get login_create_account => 'Hesab yaradın';

  @override
  String get login_loading => 'Yüklənir...';

  @override
  String get settings_title => 'Parametrlər';

  @override
  String get settings_language => 'Dil seçimi';

  @override
  String get language_russian => 'Русский';

  @override
  String get language_english => 'English';

  @override
  String get language_azerbaijani => 'Azərbaycan';

  @override
  String get logout_button => 'ÇIXIŞ';

  @override
  String get profile_title => 'Profil';

  @override
  String get profile_information => 'Məlumat';

  @override
  String get profile_photo_gallery => 'Foto qalereya';

  @override
  String get profile_workouts => 'Məşqlər';

  @override
  String get profile_user_fallback => 'İstifadəçi';

  @override
  String get common_coming_soon => 'tezliklə';

  @override
  String get common_retry => 'Yenidən cəhd et';

  @override
  String get common_cancel => 'Ləğv et';

  @override
  String get common_confirm => 'Təsdiq et';

  @override
  String get common_undo => 'Geri al';

  @override
  String get common_all => 'Hamısı';

  @override
  String get common_loading_error => 'Yükləmə xətası';

  @override
  String get home_upcoming_races => 'Gələcək yarışlar';

  @override
  String get home_personal_bests => 'Şəxsi rekordlar';

  @override
  String get home_greeting => 'Salam,';

  @override
  String get home_greeting_welcome => 'Yenidən xoş gəldin,';

  @override
  String get home_finishes => 'finiş';

  @override
  String get home_add_race => 'Əlavə et';

  @override
  String get home_add_race_title => 'Əlavə et';

  @override
  String get race_selection_title => 'Yarış seçin';

  @override
  String get race_selection_search_hint => 'Yarışları axtarın...';

  @override
  String get race_selection_save => 'Saxla';

  @override
  String get race_selection_no_races => 'Yarış tapılmadı';

  @override
  String get race_selection_confirm_title => 'Yarış əlavə et';

  @override
  String get race_selection_confirm_description =>
      'Bu yarışı gələcək yarışlar siyahısına əlavə edək?';

  @override
  String get race_selection_success => 'Yarış uğurla əlavə edildi';

  @override
  String get home_no_upcoming_races => 'Gələcək yarış yoxdur';

  @override
  String get common_no_data => 'Məlumat yoxdur';

  @override
  String get common_today => 'Bu gün';

  @override
  String common_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
      one: '1 gün',
      zero: 'Bu gün',
    );
    return '$_temp0';
  }

  @override
  String get results_title => 'Nəticələr';

  @override
  String get result_detail_title => 'Nəticə';

  @override
  String get results_my_results => 'Mənim nəticələrim';

  @override
  String get results_all_athletes => 'Bütün idmançılar';

  @override
  String get results_no_results => 'Nəticə yoxdur';

  @override
  String get results_all_coming_soon =>
      'Bütün idmançıların nəticələri tezliklə';

  @override
  String get news_title => 'Xəbərlər';

  @override
  String get news_coming_soon => 'Xəbərlər tezliklə';

  @override
  String get news_working_on_section =>
      'Biz bu bölmə üzərində işləyirik. Yenilikləri izləyin!';

  @override
  String get ratings_title => 'Reytinq';

  @override
  String get ratings_coming_soon => 'Reytinq tezliklə';

  @override
  String get ratings_working_on_section =>
      'Biz bu bölmə üzərində işləyirik. Yenilikləri izləyin!';

  @override
  String get ratings_by_race_type => 'Yarış növünə görə';

  @override
  String get ratings_by_discipline => 'Mərhələyə görə';

  @override
  String get ratings_filter_race_type => 'Yarış növü';

  @override
  String get ratings_filter_discipline => 'Mərhələ';

  @override
  String get ratings_discipline_total => 'Ümumi';

  @override
  String get ratings_discipline_swim => 'Üzmə';

  @override
  String get ratings_discipline_bike => 'Velosiped';

  @override
  String get ratings_discipline_run => 'Qaçış';

  @override
  String get ratings_no_rankings => 'Reytinq yoxdur';

  @override
  String get ratings_position => 'Yer';

  @override
  String get ratings_record_date => 'Rekord tarixi';

  @override
  String get ratings_record_location => 'Rekord yeri';

  @override
  String get ratings_compare => 'Müqayisə';

  @override
  String get ratings_disciplines_comparison =>
      'Atletin ən yaxşı rekordlarına görə növlərin müqayisəsi';

  @override
  String get ratings_compare_records => 'Şəxsi rekordları müqayisə et';

  @override
  String get ratings_race_type_full => 'FULL 140.6';

  @override
  String get ratings_race_type_half => 'HALF 70.3';

  @override
  String get ratings_select_two_athletes => 'Müqayisə üçün 2 idmançı seçin';

  @override
  String get ratings_clear_selection => 'Seçimi təmizlə';

  @override
  String get ratings_time => 'Vaxt';

  @override
  String get ratings_difference => 'Fərq';

  @override
  String get ratings_tap_to_compare_hint =>
      'Müqayisə etmək üçün idmançıya toxunun';

  @override
  String get athletes_title => 'Atletlər';

  @override
  String get athletes_coming_soon => 'Atletlər ekranı — tezliklə';

  @override
  String get athletes_list_title => 'Atletlər';

  @override
  String get athletes_search_hint => 'Axtarış';

  @override
  String get athletes_filter_registered => 'Qeydiyyatdan keçmiş';

  @override
  String get athletes_filter_new => 'Yeni';

  @override
  String get athletes_status_registered => 'Qeydiyyatdan keçmiş';

  @override
  String get athletes_invite_button => 'DAVƏT ET';

  @override
  String get athlete_profile_title => 'Atletin profili';

  @override
  String get athlete_profile_info_tab => 'Məlumat';

  @override
  String get athlete_profile_results_tab => 'Nəticələr';

  @override
  String get athlete_profile_best_by_race_type => 'Yarış növünə görə ən yaxşı';

  @override
  String get athlete_profile_by_disciplines => 'Mərhələlərə görə';

  @override
  String get athlete_profile_swimming => 'Üzmə';

  @override
  String get athlete_profile_cycling => 'Velosiped';

  @override
  String get athlete_profile_running => 'Qaçış';

  @override
  String get athlete_profile_personal_bests => 'Rekordlar';

  @override
  String get nav_home => 'Əsas';

  @override
  String get nav_results => 'Nəticələr';

  @override
  String get nav_ratings => 'Reytinq';

  @override
  String get nav_athletes => 'Atletlər';

  @override
  String get nav_login => 'Daxil ol';

  @override
  String get photo_delete_title => 'Foto silinəcək, əminsiniz?';

  @override
  String get photo_delete_avatar_warning =>
      'Bu foto sizin avatarınızdır. Silindikdən sonra avatar sıfırlanacaq.';

  @override
  String get photo_delete_irreversible => 'Bu hərəkəti geri qaytarmaq olmaz.';

  @override
  String get photo_delete_button => 'Sil';

  @override
  String get photo_deleted => 'Foto silindi';

  @override
  String get photo_uploaded => 'Foto yükləndi';

  @override
  String get photo_already_avatar => 'Bu foto artıq avatar kimi təyin edilib';

  @override
  String get photo_set_avatar_title => 'Avatar kimi təyin olunsun?';

  @override
  String get photo_set_avatar_description =>
      'Bu foto profildə sizin avatarınız kimi istifadə ediləcək.';

  @override
  String get photo_set_button => 'Təyin et';

  @override
  String get photo_set_as_avatar => 'Avatar kimi təyin et';

  @override
  String get photo_avatar => 'Avatar';

  @override
  String get photo_delete => 'Sil';

  @override
  String get photo_avatar_updated => 'Avatar uğurla yeniləndi';

  @override
  String get photo_add_button => 'Əlavə et';

  @override
  String get result_total_time => 'Ümumi vaxt';

  @override
  String get result_category => 'Kateqoriya';

  @override
  String get result_disciplines => 'Mərhələlər';

  @override
  String get result_swim => 'Üzmə';

  @override
  String get result_t1 => 'T1';

  @override
  String get result_bike => 'Velosiped';

  @override
  String get result_t2 => 'T2';

  @override
  String get result_run => 'Qaçış';

  @override
  String get register_sign_in => 'Daxil ol';

  @override
  String get register_title => 'Hesab yarat';

  @override
  String get register_name => 'Ad Soyad';

  @override
  String get register_name_required => 'Ad və soyadınızı daxil edin';

  @override
  String get register_confirm_password => 'Şifrəni təsdiqləyin';

  @override
  String get register_confirm_password_required => 'Şifrəni təsdiqləyin';

  @override
  String get register_password_min_length => 'Şifrə ən azı 6 simvol olmalıdır';

  @override
  String get register_passwords_not_match => 'Şifrələr uyğun gəlmir';

  @override
  String get register_button => 'QEYDİYYAT';

  @override
  String get register_already_have_account => 'Hesabınız var?';

  @override
  String get register_privacy_policy_agree => 'Məxfilik siyasəti ilə razıyam ';

  @override
  String get register_privacy_policy_link => 'Məxfilik Siyasəti';

  @override
  String get register_privacy_policy_required =>
      'Məxfilik Siyasəti ilə razılaşmaq lazımdır';

  @override
  String get policies_title => 'Siyasətlər';

  @override
  String get settings_policies_and_terms => 'Məxfilik siyasəti və şərtlər';

  @override
  String get policy_not_available => 'Siyasət mövcud deyil';

  @override
  String get policy_load_error => 'Siyasəti yükləmək mümkün olmadı';

  @override
  String get retry => 'Təkrar cəhd edin';

  @override
  String get register_thank_you => 'Təşəkkürlər!';

  @override
  String get register_success_message =>
      'Qeydiyyat uğurla tamamlandı.\nZəhmət olmasa, sizə göndərdiyimiz e-poçtdakı linkə klikləməklə hesabınızı təsdiqləyin.\nBundan sonra hesabınıza daxil ola bilərsiniz.';

  @override
  String get register_success_sign_in => 'DAXİL OL';

  @override
  String get register_select_country => 'Ölkəni seçin';

  @override
  String get register_search_countries => 'Axtar';

  @override
  String get settings_language_changed => 'Dil dəyişdirildi';

  @override
  String get edit_profile_title => 'Şəxsi məlumatlar';

  @override
  String get edit_profile_name => 'Ad';

  @override
  String get edit_profile_bio => 'Haqqımda';

  @override
  String get edit_profile_social_links => 'Sosial şəbəkələr';

  @override
  String get edit_profile_save_button => 'Yadda saxla';

  @override
  String get edit_profile_save_success => 'Profil saxlanıldı';

  @override
  String get edit_profile_save_error => 'Profili saxlamaq mümkün olmadı';

  @override
  String get profile_security => 'Təhlükəsizlik';

  @override
  String get change_password_title => 'Şifrəni dəyişdir';

  @override
  String get change_password_current => 'Cari şifrə';

  @override
  String get change_password_new => 'Yeni şifrə';

  @override
  String get change_password_confirm => 'Yeni şifrəni təsdiqləyin';

  @override
  String get change_password_current_required => 'Cari şifrəni daxil edin';

  @override
  String get change_password_new_required => 'Yeni şifrəni daxil edin';

  @override
  String get change_password_confirm_required => 'Yeni şifrəni təsdiqləyin';

  @override
  String get change_password_min_length => 'Şifrə ən azı 8 simvol olmalıdır';

  @override
  String get change_password_same_as_current =>
      'Yeni şifrə cari şifrədən fərqli olmalıdır';

  @override
  String get change_password_mismatch => 'Şifrələr uyğun gəlmir';

  @override
  String get change_password_button => 'ŞİFRƏNİ DƏYİŞDİR';

  @override
  String get change_password_success => 'Şifrə uğurla dəyişdirildi';

  @override
  String get change_password_error => 'Şifrəni dəyişdirmək mümkün olmadı';

  @override
  String get change_password_current_incorrect => 'Cari şifrə yanlışdır';

  @override
  String get change_password_success_title => 'Uğurlu!';

  @override
  String get change_password_error_title => 'Xəta';

  @override
  String get delete_account_warning =>
      'Hesabınızı silmək bütün məlumatlarınızı, o cümlədən nəticələri, statistikaları və şəxsi məlumatları həmişəlik ləğv edəcək.';

  @override
  String get delete_account_button => 'HESABI SİL';

  @override
  String get delete_account_confirm_title => 'Hesabı silinsin?';

  @override
  String get delete_account_confirm_description =>
      'Bu əməliyyatı geri qaytarmaq olmaz. Bütün məlumatlarınız həmişəlik silinəcək.';

  @override
  String get delete_account_confirm_button => 'SİL';

  @override
  String get add_result_title => 'Nəticə əlavə et';

  @override
  String get add_result_info =>
      'Yarış nəticəniz haqqında məlumat doldurun. * ilə işarələnmiş bütün sahələr məcburidir.';

  @override
  String get add_result_location => 'Yer';

  @override
  String get add_result_location_hint => 'Məsələn: Cozumel, Mexico';

  @override
  String get add_result_location_required => 'Yer daxil edin';

  @override
  String get add_result_date => 'Yarış tarixi';

  @override
  String get add_result_date_hint => 'Tarix seçin';

  @override
  String get add_result_date_required => 'Yarış tarixini seçin';

  @override
  String get add_result_race_type => 'Yarış növü';

  @override
  String get add_result_race_type_required => 'Yarış növünü seçin';

  @override
  String get add_result_total_time => 'Ümumi vaxt';

  @override
  String get add_result_total_time_required => 'Ümumi vaxtı daxil edin';

  @override
  String get add_result_swim => 'Üzmə';

  @override
  String get add_result_t1 => 'T1';

  @override
  String get add_result_bike => 'Velosiped';

  @override
  String get add_result_t2 => 'T2';

  @override
  String get add_result_run => 'Qaçış';

  @override
  String get add_result_time_format => 'Format: SS:DD:SS';

  @override
  String get add_result_save => 'YADDA SAXLA';

  @override
  String get add_result_saved_stub => 'Nəticə qeyd olundu';

  @override
  String get add_result_section_basic_info => 'Əsas məlumat';

  @override
  String get add_result_section_time => 'Vaxt';

  @override
  String get add_result_section_disciplines => 'Mərhələlər';

  @override
  String get add_result_t1_label => 'T1';

  @override
  String get add_result_t2_label => 'T2';

  @override
  String get add_result_time_hint => 'SS:DD:SS';

  @override
  String get add_result_race_type_ironman => 'Ironman';

  @override
  String get add_result_race_type_ironman_70_3 => 'Ironman 70.3';

  @override
  String get add_result_race_type_5150 => '5150';

  @override
  String get add_result_success_title => 'Nəticə göndərildi';

  @override
  String get add_result_success_message =>
      'Nəticəniz administrator tərəfindən təsdiqlənmək üçün göndərildi. Yoxlamadan sonra siyahıda görünəcək.';

  @override
  String get add_result_approved => 'Təsdiqlənib';

  @override
  String get add_result_pending_approval => 'Təsdiq gözləyir';

  @override
  String get athlete_profile_ironman_number => 'Ironman Nömrəsi';

  @override
  String get athlete_profile_bio => 'Haqqımda';

  @override
  String get athlete_profile_social_links => 'Sosial şəbəkələr';

  @override
  String get athlete_profile_info_not_available => 'Məlumat mövcud deyil';

  @override
  String get athlete_profile_social_links_not_specified =>
      'Sosial şəbəkələr göstərilməyib';

  @override
  String get athlete_profile_photos_tab => 'Şəkillər';

  @override
  String get athlete_profile_no_photos => 'Hələ şəkil yoxdur';

  @override
  String get error_server_error =>
      'Server xətası, zəhmət olmasa az sonra yenidən cəhd edin';

  @override
  String get error_no_internet =>
      'İnternet bağlantınızı yoxlayın və yenidən cəhd edin';

  @override
  String get error_no_network_connection => 'İnternet bağlantısı mövcud deyil';

  @override
  String get error_ok => 'OK';

  @override
  String error_cooldown(int seconds) {
    return 'Zəhmət olmasa yenidən cəhd etmədən əvvəl $seconds saniyə gözləyin';
  }

  @override
  String get error_network_error =>
      'Şəbəkə bağlantısı problemi, zəhmət olmasa internetinizi yoxlayın';

  @override
  String get error_unexpected =>
      'Gözlənilməz xəta baş verdi, zəhmət olmasa yenidən cəhd edin';

  @override
  String get my_races_title => 'Gələcək yarışlar';

  @override
  String get my_races_no_races => 'Hələ gələcək yarışınız yoxdur';

  @override
  String get my_races_delete => 'Sil';

  @override
  String get notifications_title => 'Bildirişlər';

  @override
  String get notifications_mark_all_read_tooltip =>
      'Hamısını oxunmuş kimi işarələ';

  @override
  String get notifications_mark_all_read_error =>
      'Hamısını oxunmuş kimi işarələmək mümkün olmadı';

  @override
  String get notifications_delete_error => 'Silinmədi';

  @override
  String get notifications_no_notifications => 'Bildiriş yoxdur';

  @override
  String get notifications_fallback_title => 'Bildiriş';

  @override
  String get notification_detail_title => 'Bildiriş';

  @override
  String get notification_detail_understood => 'Başa düşdüm';

  @override
  String get upcoming_completed => 'TAMAMLANIB';

  @override
  String get upcoming_day_label => 'GÜN';

  @override
  String get upcoming_days_label => 'GÜN';

  @override
  String get home_sync_title => 'Keçmiş yarışların sinxronizasiyası';

  @override
  String get home_sync_description =>
      'Əgər ironman.az saytında nəticələriniz varsa, biz onları profilinizlə sinxronizasiya edə bilərik.';

  @override
  String get home_sync_button => 'SORĞU GÖNDƏR';

  @override
  String get home_sync_requested =>
      'Sinxronizasiya sorğusu göndərildi. Emal olunduqdan sonra nəticələr profilinizdə görünəcək.';

  @override
  String get home_sync_error => 'Sinxronizasiya sorğusu göndərilmədi';

  @override
  String get home_sync_error_timeout =>
      'Gözləmə vaxtı keçdi. İnterneti yoxlayın və yenidən cəhd edin.';

  @override
  String get home_sync_error_network => 'Bağlantı xətası. İnterneti yoxlayın.';

  @override
  String get home_sync_error_server => 'Server xətası';

  @override
  String get email_not_verified_title => 'Emailiniz təsdiqlənməyib';

  @override
  String get email_not_verified_message =>
      'Zəhmət olmasa poçtunuzu yoxlayın və hesabınızı təsdiqləmək üçün keçidə klikləyin.';

  @override
  String get email_not_verified_no_email => 'Məktub almadınız?';

  @override
  String get email_not_verified_resend => 'MƏKTUBU YENİDƏN GÖNDƏR';

  @override
  String get email_not_verified_resend_success => 'Məktub yenidən göndərildi';

  @override
  String get email_not_verified_back_to_login => 'GİRİŞƏ QAYIT';

  @override
  String get email_not_verified_back_to_login_description =>
      'Siz artıq sistemə daxil olmusunuz. Bu düyməyə basmaq sizi sistemdən çıxaracaq və giriş ekranına qaytaracaq.';

  @override
  String get profile_selection_title => 'Xoş gəlmisiniz!';

  @override
  String get profile_selection_description =>
      'Əgər nəticələriniz saytda yoxdursa, idmançı profili yaratmaq üçün \'Yeni profil yarat\' düyməsinə basın.';

  @override
  String get profile_selection_code_text =>
      'Əgər nəticələriniz ironman.az saytında varsa, administrator tərəfindən verilən 6 simvollu kodu daxil edin ki, profilinizi bağlayasınız.';

  @override
  String get profile_selection_code_label => 'Profil kodu';

  @override
  String get profile_selection_code_hint => '6 simvollu kodu daxil edin';

  @override
  String get profile_selection_code_required => 'Kod tələb olunur';

  @override
  String get profile_selection_code_length =>
      'Kod tam olaraq 6 simvoldan ibarət olmalıdır';

  @override
  String get profile_selection_code_invalid =>
      'Kodda icazə verilməyən simvollar var. Yalnız hərflər və rəqəmlərdən istifadə edin (0, O, I, L istisna olmaqla).';

  @override
  String get profile_selection_link_button => 'Profili bağla';

  @override
  String get profile_selection_or => 'VƏ YA';

  @override
  String get profile_selection_search => 'Axtar';

  @override
  String profile_selection_results_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nəticə',
      one: '1 nəticə',
      zero: 'Nəticə yoxdur',
    );
    return '$_temp0';
  }

  @override
  String get profile_selection_select => 'Seç';

  @override
  String get profile_selection_next => 'Növbəti';

  @override
  String get profile_selection_create_new => 'Yeni profil yarat';

  @override
  String get profile_selection_loading => 'Profillər yüklənir...';

  @override
  String get profile_selection_no_profiles => 'Mövcud profil yoxdur';

  @override
  String get profile_selection_link_success => 'Profil uğurla bağlandı';

  @override
  String get profile_selection_create_success => 'Profil uğurla yaradıldı';

  @override
  String get profile_selection_error_network =>
      'Bağlantı xətası. İnterneti yoxlayın.';

  @override
  String get profile_selection_error_server =>
      'Server xətası. Daha sonra cəhd edin.';

  @override
  String get profile_selection_error_already_linked =>
      'Bu profil artıq başqa istifadəçiyə bağlıdır';

  @override
  String get profile_selection_error_code_not_found =>
      'Kod tapılmadı və ya yanlışdır';

  @override
  String get profile_selection_error_code_already_used =>
      'Bu kod artıq istifadə olunub';

  @override
  String get profile_selection_error_code_already_linked =>
      'Bu kodla profil artıq başqa istifadəçiyə bağlıdır';

  @override
  String get profile_selection_error_profile_already_exists =>
      'Sizdə artıq bağlı profil var';

  @override
  String get profile_selection_logout => 'Çıxış';

  @override
  String get notification_permission_disabled_title => 'Bildirişlər söndürülüb';

  @override
  String get notification_permission_disabled_message =>
      'Onları parametrlərdə aktivləşdirə bilərsiniz';

  @override
  String get notification_permission_open_settings => 'Parametrləri aç';

  @override
  String get pace_calculator_done => 'Hazır';

  @override
  String get pace_calculator_tab_full => 'IRONMAN';

  @override
  String get pace_calculator_tab_70_3 => 'IRONMAN 70.3';

  @override
  String get pace_calculator_tab_5150 => '5150';

  @override
  String get pace_calculator_appbar_title => 'Temp kalkulatoru';

  @override
  String get pace_calculator_total_race_time => 'ÜMUMİ YARIŞ VAXTI';

  @override
  String get pace_calculator_km_unit => 'km';

  @override
  String get pace_calculator_min_per_100m => 'dəq / 100m';

  @override
  String get pace_calculator_km_per_h => 'km / saat';

  @override
  String get pace_calculator_min_per_km => 'dəq / km';

  @override
  String get pace_calculator_swim_time => 'Üzmə';

  @override
  String get pace_calculator_t1_time => 'T1';

  @override
  String get pace_calculator_bike_time => 'Velosiped';

  @override
  String get pace_calculator_t2_time => 'T2';

  @override
  String get pace_calculator_run_time => 'Qaçış';

  @override
  String get home_pace_calculator_title => 'Temp kalkulatoru';

  @override
  String get home_pace_calculator_subtitle => 'Üzmə • Velosiped • Qaçış';

  @override
  String get home_pace_calculator_button => 'HESABLA';

  @override
  String get home_card_pace_title => 'Temp kalkulatoru';

  @override
  String get home_card_pace_subtitle => 'ÜZMƏ • VELOSİPED • QAÇIŞ';

  @override
  String get home_card_pace_helper => 'Yarış alətləri';

  @override
  String get home_card_pace_button => 'HESABLA';

  @override
  String get home_card_profile_title => 'Atlet Kabineti';

  @override
  String get home_card_profile_subtitle => 'NƏTİCƏLƏR • REYTİNQ • PROFİL';

  @override
  String get home_card_profile_helper => 'Yarış nəticələri';

  @override
  String get home_card_profile_button => 'PROFİL';

  @override
  String get events_tab_active => 'Aktiv';

  @override
  String get events_tab_past => 'Keçmiş';

  @override
  String get events_no_past_races => 'Keçmiş yarışlar yoxdur';

  @override
  String get athlete_rating_title => 'Reytinq';

  @override
  String get athlete_rating_info =>
      'Reytinq bu tətbiqin nəticələr məlumatlarına əsasən hesablanır';

  @override
  String get reset_password_title => 'Parolun sıfırlanması';

  @override
  String get reset_password_description =>
      'E-mailinizi daxil edin və biz sizə parolun sıfırlanması üçün keçid göndərəcəyik.';

  @override
  String get reset_password_send_button => 'GÖNDƏR';

  @override
  String get reset_password_remember => 'Parolunuzu bilirsiniz?';

  @override
  String get reset_password_sign_in => 'Daxil ol';

  @override
  String get dashboard_notification_card_title => 'Xəbərdar qalın!';

  @override
  String get dashboard_notification_card_message =>
      'Yarış nəticələriniz, gələcək hadisələr və vacib yeniləmələr haqqında bildirişlər alın.';

  @override
  String get dashboard_notification_card_enable => 'Aktiv et';

  @override
  String get dashboard_notification_card_later => 'İndi yox';

  @override
  String get transfer_no_request_title => 'Başqalarının nəticələrini bağla';

  @override
  String get transfer_no_request_description =>
      'Əgər nəticələriniz ironman.az saytında varsa, onları köçürə bilərik';

  @override
  String get transfer_attach_results => 'Sorğu göndər';

  @override
  String get transfer_status_pending => 'Gözləyir';

  @override
  String get transfer_status_pending_description =>
      'Köçürmə sorğunuz nəzərdən keçirilir';

  @override
  String get transfer_status_approved => 'Təsdiqlənib';

  @override
  String get transfer_status_approved_description =>
      'Nəticələriniz uğurla köçürüldü';

  @override
  String get transfer_status_rejected => 'Rədd edilib';

  @override
  String get transfer_status_rejected_description =>
      'Köçürmə sorğunuz imtina edildi';

  @override
  String get transfer_submit_again => 'Yenidən göndər';

  @override
  String transfer_source_athlete(String name) {
    return 'Atlet: $name';
  }

  @override
  String get transfer_select_athlete => 'Atleti seçin';

  @override
  String get transfer_search_athletes => 'Atletləri axtar';

  @override
  String get transfer_start_typing => 'Axtarış üçün yazmağa başlayın';

  @override
  String get transfer_no_athletes_found => 'Heç bir atlet tapılmadı';

  @override
  String transfer_results_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nəticə',
      one: '1 nəticə',
      zero: 'nəticə yoxdur',
    );
    return '$_temp0';
  }

  @override
  String transfer_last_race(String location) {
    return 'Son yarış: $location';
  }

  @override
  String get transfer_request_created =>
      'Sorğu yaradıldı. İnzibatçı tərəfindən nəzərdən keçiriləcək';

  @override
  String get transfer_request_error => 'Sorğu göndərilmədi. Yenidən cəhd edin';

  @override
  String get transfer_confirm_title => 'Nəticələr bağlansın?';

  @override
  String transfer_confirm_description(String name) {
    return '$name atletinin bütün nəticələrini öz profilinizə əlavə etmək üçün sorğu göndərilsin?';
  }

  @override
  String get transfer_confirm_button => 'Təsdiqlə';

  @override
  String get api_error_empty_response => 'Serverdən boş cavab';

  @override
  String get api_error_timeout => 'Gözləmə müddəti keçdi';

  @override
  String get api_error_network_no_connection => 'İnternet bağlantısı yoxdur';

  @override
  String api_error_http_status(int status) {
    return 'Məlumat yüklənməsi xətası (HTTP $status)';
  }

  @override
  String api_error_generic(String message) {
    return 'Məlumat yüklənməsi xətası: $message';
  }

  @override
  String api_error_unexpected(String error) {
    return 'Xəta baş verdi: $error';
  }

  @override
  String get api_error_invalid_data_format =>
      'Məlumat siyahısı gözlənilirdi, başqa tip alındı';

  @override
  String get api_error_invalid_item_format =>
      'Məlumat elementinin formatı düzgün deyil';

  @override
  String get api_error_races_format =>
      'Yarış siyahısı gözlənilirdi, başqa tip alındı';

  @override
  String get api_error_race_item_format =>
      'Yarış elementinin formatı düzgün deyil';

  @override
  String get api_error_rankings_format =>
      'Reytinq siyahısı gözlənilirdi, başqa tip alındı';

  @override
  String get api_error_ranking_item_format =>
      'Reytinq elementinin formatı düzgün deyil';

  @override
  String get api_error_athletes_format =>
      'Atletlər siyahısı gözlənilirdi, başqa tip alındı';

  @override
  String get api_error_athlete_item_format =>
      'Atlet elementinin formatı düzgün deyil';

  @override
  String get api_error_athlete_object_format =>
      'Atlet obyekti gözlənilirdi, başqa tip alındı';

  @override
  String get api_error_athlete_not_found =>
      'Atlet məlumatları əldə edilə bilmədi';

  @override
  String get api_error_records_object_format =>
      'Rekorlar obyekti gözlənilirdi, başqa tip alındı';

  @override
  String get api_error_records_not_found =>
      'Rekor məlumatları əldə edilə bilmədi';

  @override
  String get api_error_upcoming_race_create_failed => 'Yarış yaradıla bilmədi';

  @override
  String get api_error_upcoming_race_object_format =>
      'Yarış obyekti gözlənilirdi, başqa tip alındı';

  @override
  String api_error_server(String status) {
    return 'Server xətası ($status)';
  }

  @override
  String get api_error_athletes_loading =>
      'Atletlərin yüklənməsində xəta baş verdi';

  @override
  String get transfer_api_conflict => 'Sorğu yaradarkən münaqişə';

  @override
  String get transfer_api_validation => 'Məlumat yoxlanması xətası';

  @override
  String get transfer_api_server_error =>
      'Serverlə əlaqə qurarkən xəta baş verdi';

  @override
  String get transfer_status_timeout =>
      'Status yeniləyərkən gözləmə müddəti keçdi';

  @override
  String get transfer_status_load_failed =>
      'Transfer sorğusunun statusu yüklənə bilmədi';

  @override
  String get transfer_status_create_failed =>
      'Transfer sorğusu yaradıla bilmədi';

  @override
  String get transfer_status_update_failed =>
      'Transfer statusu yenilənə bilmədi';

  @override
  String get api_error_transfer_create_failed =>
      'Transfer sorğusu yaradıla bilmədi';
}
