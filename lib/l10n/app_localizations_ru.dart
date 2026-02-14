// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get app_title => 'IRONSTATS';

  @override
  String get login_title => 'Войдите в свой аккаунт';

  @override
  String get login_email => 'Email';

  @override
  String get login_password => 'Пароль';

  @override
  String get login_button => 'ВОЙТИ';

  @override
  String get login_email_required => 'Введите email';

  @override
  String get login_email_invalid => 'Некорректный email';

  @override
  String get login_password_required => 'Введите пароль';

  @override
  String get login_forgot_password => 'Забыли пароль?';

  @override
  String get login_no_account => 'Нет аккаунта?';

  @override
  String get login_create_account => 'Создать аккаунт';

  @override
  String get login_loading => 'Загрузка...';

  @override
  String get settings_title => 'Настройки';

  @override
  String get settings_language => 'Язык';

  @override
  String get language_russian => 'Русский';

  @override
  String get language_english => 'English';

  @override
  String get language_azerbaijani => 'Azərbaycan';

  @override
  String get logout_button => 'ВЫХОД';

  @override
  String get profile_title => 'Профиль';

  @override
  String get profile_information => 'Информация';

  @override
  String get profile_photo_gallery => 'Фотогалерея';

  @override
  String get profile_workouts => 'Тренировки';

  @override
  String get profile_user_fallback => 'Пользователь';

  @override
  String get common_coming_soon => 'скоро';

  @override
  String get common_retry => 'Повторить';

  @override
  String get common_cancel => 'Отмена';

  @override
  String get common_undo => 'Отменить';

  @override
  String get common_all => 'Все';

  @override
  String get common_loading_error => 'Ошибка загрузки';

  @override
  String get home_upcoming_races => 'Предстоящие гонки';

  @override
  String get home_personal_bests => 'Личные рекорды';

  @override
  String get home_greeting => 'Привет,';

  @override
  String get home_finishes => 'финишов';

  @override
  String get home_add_race => 'Добавить гонку';

  @override
  String get home_add_race_title => 'Добавить гонку';

  @override
  String get home_no_upcoming_races => 'Нет предстоящих гонок';

  @override
  String get common_no_data => 'Нет данных';

  @override
  String get common_today => 'Сегодня';

  @override
  String common_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней',
      few: '$count дня',
      one: '1 день',
      zero: 'Сегодня',
    );
    return '$_temp0';
  }

  @override
  String get results_title => 'Результаты';

  @override
  String get result_detail_title => 'Результат';

  @override
  String get results_my_results => 'Мои результаты';

  @override
  String get results_all_athletes => 'Все атлеты';

  @override
  String get results_no_results => 'Нет результатов';

  @override
  String get results_all_coming_soon => 'Результаты всех атлетов скоро';

  @override
  String get news_title => 'Новости';

  @override
  String get news_coming_soon => 'Новости скоро';

  @override
  String get news_working_on_section =>
      'Мы работаем над этим разделом. Следите за обновлениями!';

  @override
  String get ratings_title => 'Рейтинги';

  @override
  String get ratings_coming_soon => 'Рейтинги скоро';

  @override
  String get ratings_working_on_section =>
      'Мы работаем над этим разделом. Следите за обновлениями!';

  @override
  String get ratings_by_race_type => 'По типу гонок';

  @override
  String get ratings_by_discipline => 'По дисциплинам';

  @override
  String get ratings_filter_race_type => 'Тип гонки';

  @override
  String get ratings_filter_discipline => 'Дисциплина';

  @override
  String get ratings_discipline_total => 'Общее время';

  @override
  String get ratings_discipline_swim => 'Плавание';

  @override
  String get ratings_discipline_bike => 'Велосипед';

  @override
  String get ratings_discipline_run => 'Бег';

  @override
  String get ratings_no_rankings => 'Нет рейтингов';

  @override
  String get ratings_position => 'Место';

  @override
  String get ratings_record_date => 'Дата рекорда';

  @override
  String get ratings_record_location => 'Место рекорда';

  @override
  String get ratings_compare => 'Сравнение';

  @override
  String get ratings_disciplines_comparison =>
      'Сравнение дисциплин по лучшим рекордам атлета';

  @override
  String get ratings_compare_records => 'Сравнить личные рекорды';

  @override
  String get ratings_race_type_full => 'FULL 140.6';

  @override
  String get ratings_race_type_half => 'HALF 70.3';

  @override
  String get ratings_select_two_athletes => 'Выберите 2 атлета для сравнения';

  @override
  String get ratings_clear_selection => 'Очистить выбор';

  @override
  String get ratings_time => 'Время';

  @override
  String get ratings_difference => 'Разница';

  @override
  String get ratings_tap_to_compare_hint => 'Нажмите на атлета, чтобы сравнить';

  @override
  String get athletes_title => 'Атлеты';

  @override
  String get athletes_coming_soon => 'Экран атлетов — скоро';

  @override
  String get athletes_list_title => 'Атлеты';

  @override
  String get athletes_search_hint => 'Поиск';

  @override
  String get athletes_filter_registered => 'Зарегистрированные';

  @override
  String get athletes_filter_new => 'Новые';

  @override
  String get athletes_status_registered => 'Зарегистрирован';

  @override
  String get athletes_invite_button => 'ИНВАЙТ';

  @override
  String get athlete_profile_title => 'Профиль атлета';

  @override
  String get athlete_profile_info_tab => 'Инфо';

  @override
  String get athlete_profile_results_tab => 'Результаты';

  @override
  String get athlete_profile_best_by_race_type => 'Лучшие по типу гонки';

  @override
  String get athlete_profile_by_disciplines => 'По дисциплинам';

  @override
  String get athlete_profile_swimming => 'Плавание';

  @override
  String get athlete_profile_cycling => 'Велосипед';

  @override
  String get athlete_profile_running => 'Бег';

  @override
  String get athlete_profile_personal_bests => 'Рекорды';

  @override
  String get nav_home => 'Главная';

  @override
  String get nav_results => 'Результаты';

  @override
  String get nav_ratings => 'Рейтинги';

  @override
  String get nav_athletes => 'Атлеты';

  @override
  String get photo_delete_title => 'Удалить фото?';

  @override
  String get photo_delete_avatar_warning =>
      'Это фото является вашим аватаром. После удаления аватар будет сброшен.';

  @override
  String get photo_delete_irreversible => 'Это действие нельзя отменить.';

  @override
  String get photo_delete_button => 'Удалить';

  @override
  String get photo_deleted => 'Фото удалено';

  @override
  String get photo_uploaded => 'Фото загружено';

  @override
  String get photo_already_avatar => 'Это фото уже установлено как аватар';

  @override
  String get photo_set_avatar_title => 'Установить как аватар?';

  @override
  String get photo_set_avatar_description =>
      'Это фото будет использовано как ваш аватар в профиле.';

  @override
  String get photo_set_button => 'Установить';

  @override
  String get photo_set_as_avatar => 'Установить как аватар';

  @override
  String get photo_avatar => 'Аватар';

  @override
  String get photo_delete => 'Удалить';

  @override
  String get photo_avatar_updated => 'Аватар успешно обновлён';

  @override
  String get photo_add_button => 'Добавить';

  @override
  String get result_total_time => 'Общее время';

  @override
  String get result_category => 'Категория';

  @override
  String get result_disciplines => 'Дисциплины';

  @override
  String get result_swim => 'Плавание';

  @override
  String get result_t1 => 'T1';

  @override
  String get result_bike => 'Велосипед';

  @override
  String get result_t2 => 'T2';

  @override
  String get result_run => 'Бег';

  @override
  String get register_sign_in => 'Войти';

  @override
  String get register_title => 'Создать аккаунт';

  @override
  String get register_name => 'Имя Фамилия';

  @override
  String get register_name_required => 'Введите имя и фамилию';

  @override
  String get register_confirm_password => 'Подтвердите пароль';

  @override
  String get register_confirm_password_required => 'Подтвердите пароль';

  @override
  String get register_password_min_length =>
      'Пароль должен содержать не менее 6 символов';

  @override
  String get register_passwords_not_match => 'Пароли не совпадают';

  @override
  String get register_button => 'ЗАРЕГИСТРИРОВАТЬСЯ';

  @override
  String get register_already_have_account => 'Уже есть аккаунт?';

  @override
  String get register_thank_you => 'Спасибо!';

  @override
  String get register_success_message =>
      'Регистрация успешна.\nПожалуйста, подтвердите свой аккаунт, перейдя по ссылке в письме, которое мы отправили вам на почту.\nПосле этого вы сможете войти в свой аккаунт.';

  @override
  String get register_success_sign_in => 'ВОЙТИ';

  @override
  String get register_select_country => 'Выберите страну';

  @override
  String get register_search_countries => 'Поиск стран';

  @override
  String get settings_language_changed => 'Язык изменён';

  @override
  String get edit_profile_title => 'Информация об атлете';

  @override
  String get edit_profile_name => 'Имя';

  @override
  String get edit_profile_bio => 'О себе';

  @override
  String get edit_profile_social_links => 'Социальные сети';

  @override
  String get edit_profile_save_button => 'СОХРАНИТЬ ИЗМЕНЕНИЯ';

  @override
  String get edit_profile_save_success => 'Профиль сохранён';

  @override
  String get edit_profile_save_error => 'Не удалось сохранить профиль';

  @override
  String get profile_security => 'Безопасность';

  @override
  String get change_password_title => 'Сменить пароль';

  @override
  String get change_password_current => 'Текущий пароль';

  @override
  String get change_password_new => 'Новый пароль';

  @override
  String get change_password_confirm => 'Подтвердите новый пароль';

  @override
  String get change_password_current_required => 'Введите текущий пароль';

  @override
  String get change_password_new_required => 'Введите новый пароль';

  @override
  String get change_password_confirm_required => 'Подтвердите новый пароль';

  @override
  String get change_password_min_length =>
      'Пароль должен содержать не менее 8 символов';

  @override
  String get change_password_same_as_current =>
      'Новый пароль должен отличаться от текущего';

  @override
  String get change_password_mismatch => 'Пароли не совпадают';

  @override
  String get change_password_button => 'СМЕНИТЬ ПАРОЛЬ';

  @override
  String get change_password_success => 'Пароль успешно изменён';

  @override
  String get change_password_error => 'Не удалось изменить пароль';

  @override
  String get change_password_current_incorrect => 'Текущий пароль неверен';

  @override
  String get change_password_success_title => 'Успешно!';

  @override
  String get change_password_error_title => 'Ошибка';

  @override
  String get delete_account_warning =>
      'Удаление аккаунта приведет к безвозвратной потере всех данных, включая результаты, статистику и личную информацию.';

  @override
  String get delete_account_button => 'УДАЛИТЬ АККАУНТ';

  @override
  String get delete_account_confirm_title => 'Удалить аккаунт?';

  @override
  String get delete_account_confirm_description =>
      'Это действие нельзя отменить. Все ваши данные будут удалены навсегда.';

  @override
  String get delete_account_confirm_button => 'УДАЛИТЬ';

  @override
  String get add_result_title => 'Добавить результат';

  @override
  String get add_result_info =>
      'Заполните информацию о результате вашей гонки. Все поля, отмеченные *, обязательны для заполнения.';

  @override
  String get add_result_location => 'Локация';

  @override
  String get add_result_location_hint => 'Например: Cozumel, Mexico';

  @override
  String get add_result_location_required => 'Введите локацию';

  @override
  String get add_result_date => 'Дата гонки';

  @override
  String get add_result_date_hint => 'Выберите дату';

  @override
  String get add_result_race_type => 'Тип гонки';

  @override
  String get add_result_race_type_required => 'Выберите тип гонки';

  @override
  String get add_result_total_time => 'Общее время';

  @override
  String get add_result_total_time_required => 'Введите общее время';

  @override
  String get add_result_swim => 'Swim';

  @override
  String get add_result_t1 => 'T1 (Переход 1)';

  @override
  String get add_result_bike => 'Bike';

  @override
  String get add_result_t2 => 'T2 (Переход 2)';

  @override
  String get add_result_run => 'Run';

  @override
  String get add_result_time_format => 'Формат: HH:MM:SS';

  @override
  String get add_result_save => 'СОХРАНИТЬ';

  @override
  String get add_result_saved_stub => 'Результат сохранен (заглушка)';

  @override
  String get add_result_section_basic_info => 'Основная информация';

  @override
  String get add_result_section_time => 'Время';

  @override
  String get add_result_section_disciplines => 'Дисциплины';

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
  String get add_result_success_title => 'Результат отправлен';

  @override
  String get add_result_success_message =>
      'Ваш результат отправлен на подтверждение администратором. Он появится в списке после проверки.';

  @override
  String get add_result_approved => 'Подтверждено';

  @override
  String get add_result_pending_approval => 'Ожидает подтверждения';

  @override
  String get athlete_profile_ironman_number => 'Номер Ironman';

  @override
  String get athlete_profile_bio => 'О себе';

  @override
  String get athlete_profile_social_links => 'Социальные сети';

  @override
  String get athlete_profile_info_not_available => 'Информация отсутствует';

  @override
  String get athlete_profile_social_links_not_specified =>
      'Социальные сети не указаны';

  @override
  String get error_server_error => 'Что-то пошло не так, попробуйте позже';

  @override
  String get error_no_internet =>
      'Проверьте подключение к интернету и попробуйте снова';

  @override
  String get error_no_network_connection =>
      'Отсутствует подключение к интернету';

  @override
  String get error_ok => 'OK';

  @override
  String error_cooldown(int seconds) {
    return 'Подождите $seconds секунд перед повторной попыткой';
  }

  @override
  String get error_network_error =>
      'Проблемы с сетевым подключением, проверьте интернет';

  @override
  String get error_unexpected =>
      'Произошла неожиданная ошибка, попробуйте снова';

  @override
  String get my_races_title => 'Предстоящие гонки';

  @override
  String get my_races_no_races => 'У вас пока нет предстоящих гонок';

  @override
  String get my_races_delete => 'Удалить';

  @override
  String get notifications_title => 'Уведомления';

  @override
  String get notifications_mark_all_read_tooltip => 'Отметить все прочитанными';

  @override
  String get notifications_mark_all_read_error =>
      'Не удалось пометить все как прочитанные';

  @override
  String get notifications_delete_error => 'Не удалось удалить';

  @override
  String get notifications_no_notifications => 'Нет уведомлений';

  @override
  String get notifications_fallback_title => 'Уведомление';

  @override
  String get notification_detail_title => 'Уведомление';

  @override
  String get notification_detail_understood => 'Понятно';

  @override
  String get upcoming_completed => 'ЗАВЕРШЕНО';

  @override
  String get upcoming_day_label => 'ДЕНЬ';

  @override
  String get upcoming_days_label => 'ДНЕЙ';

  @override
  String get home_sync_title => 'Синхронизация прошлых гонок';

  @override
  String get home_sync_description =>
      'Если у вас уже были гонки, и они есть на сайте ironman.az, мы можем синхронизировать их с вашим профилем.';

  @override
  String get home_sync_button => 'ЗАПРОСИТЬ';

  @override
  String get home_sync_requested =>
      'Запрос на синхронизацию отправлен. После обработки ваши результаты появятся в профиле.';

  @override
  String get home_sync_error => 'Не удалось отправить запрос на синхронизацию';

  @override
  String get home_sync_error_timeout =>
      'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.';

  @override
  String get home_sync_error_network =>
      'Ошибка подключения. Проверьте интернет.';

  @override
  String get home_sync_error_server => 'Ошибка сервера';

  @override
  String get email_not_verified_title => 'Ваш email не подтверждён';

  @override
  String get email_not_verified_message =>
      'Пожалуйста, проверьте почту и перейдите по ссылке для подтверждения аккаунта.';

  @override
  String get email_not_verified_no_email => 'Не получили письмо?';

  @override
  String get email_not_verified_resend => 'ОТПРАВИТЬ ПОВТОРНО';

  @override
  String get email_not_verified_resend_success => 'Письмо отправлено повторно';

  @override
  String get email_not_verified_back_to_login => 'ВОЙТИ';

  @override
  String get email_not_verified_back_to_login_description =>
      'Вы уже вошли в систему. Нажатие этой кнопки выйдет из аккаунта и вернёт вас на экран входа.';

  @override
  String get profile_selection_title => 'Добро пожаловать!';

  @override
  String get profile_selection_description =>
      'Если ваших результатов нет на сайте, нажмите \'Создать новый профиль\' для создания профиля атлета.';

  @override
  String get profile_selection_code_text =>
      'Если ваши результаты есть на сайте ironman.az, введите 6-значный код, предоставленный администратором, чтобы привязать ваш профиль.';

  @override
  String get profile_selection_code_label => 'Код профиля';

  @override
  String get profile_selection_code_hint => 'Введите 6-значный код';

  @override
  String get profile_selection_code_required => 'Код обязателен';

  @override
  String get profile_selection_code_length =>
      'Код должен содержать ровно 6 символов';

  @override
  String get profile_selection_code_invalid =>
      'Код содержит недопустимые символы. Используйте только буквы и цифры (исключая 0, O, I, L).';

  @override
  String get profile_selection_link_button => 'Привязать профиль';

  @override
  String get profile_selection_or => 'ИЛИ';

  @override
  String get profile_selection_search => 'Поиск';

  @override
  String profile_selection_results_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count результатов',
      one: '1 результат',
      zero: 'Нет результатов',
    );
    return '$_temp0';
  }

  @override
  String get profile_selection_select => 'Выбрать';

  @override
  String get profile_selection_next => 'Далее';

  @override
  String get profile_selection_create_new => 'Создать новый профиль';

  @override
  String get profile_selection_loading => 'Загрузка профилей...';

  @override
  String get profile_selection_no_profiles => 'Нет доступных профилей';

  @override
  String get profile_selection_link_success => 'Профиль успешно привязан';

  @override
  String get profile_selection_create_success => 'Профиль успешно создан';

  @override
  String get profile_selection_error_network =>
      'Ошибка подключения. Проверьте интернет.';

  @override
  String get profile_selection_error_server =>
      'Ошибка сервера. Попробуйте позже.';

  @override
  String get profile_selection_error_already_linked =>
      'Этот профиль уже привязан к другому пользователю';

  @override
  String get profile_selection_error_code_not_found =>
      'Код не найден или неверен';

  @override
  String get profile_selection_error_code_already_used =>
      'Этот код уже был использован';

  @override
  String get profile_selection_error_code_already_linked =>
      'Профиль с этим кодом уже привязан к другому пользователю';

  @override
  String get profile_selection_error_profile_already_exists =>
      'У вас уже есть привязанный профиль';

  @override
  String get profile_selection_logout => 'Выйти';

  @override
  String get notification_permission_disabled_title => 'Уведомления отключены';

  @override
  String get notification_permission_disabled_message =>
      'Вы можете включить их в настройках';

  @override
  String get notification_permission_open_settings => 'Открыть настройки';

  @override
  String get pace_calculator_done => 'Готово';

  @override
  String get pace_calculator_tab_full => 'IRONMAN';

  @override
  String get pace_calculator_tab_70_3 => 'IRONMAN 70.3';

  @override
  String get pace_calculator_tab_5150 => '5150';

  @override
  String get pace_calculator_appbar_title => 'Калькулятор';

  @override
  String get pace_calculator_total_race_time => 'ОБЩЕЕ ВРЕМЯ ГОНКИ';

  @override
  String get pace_calculator_km_unit => 'км';

  @override
  String get pace_calculator_min_per_100m => 'мин / 100 м';

  @override
  String get pace_calculator_km_per_h => 'км / ч';

  @override
  String get pace_calculator_min_per_km => 'мин / км';

  @override
  String get pace_calculator_swim_time => 'Плавание';

  @override
  String get pace_calculator_t1_time => 'T1';

  @override
  String get pace_calculator_bike_time => 'Вело';

  @override
  String get pace_calculator_t2_time => 'T2';

  @override
  String get pace_calculator_run_time => 'Бег';

  @override
  String get home_pace_calculator_title => 'Калькулятор темпа';

  @override
  String get home_pace_calculator_subtitle => 'Плавание • Вело • Бег';

  @override
  String get home_pace_calculator_button => 'РАССЧИТАТЬ';

  @override
  String get home_card_pace_title => 'Калькулятор темпа';

  @override
  String get home_card_pace_subtitle => 'ПЛАВАНИЕ • ВЕЛО • БЕГ';

  @override
  String get home_card_pace_helper => 'Инструменты для гонки';

  @override
  String get home_card_pace_button => 'РАССЧИТАТЬ';

  @override
  String get home_card_profile_title => 'Кабинет атлета';

  @override
  String get home_card_profile_subtitle => 'РЕЗУЛЬТАТЫ • РЕЙТИНГИ • ПРОФИЛЬ';

  @override
  String get home_card_profile_helper => 'Соревновательные результаты';

  @override
  String get home_card_profile_button => 'ПРОФИЛЬ';

  @override
  String get events_tab_active => 'Активные';

  @override
  String get events_tab_past => 'Прошедшие';

  @override
  String get events_no_past_races => 'Нет прошедших гонок';

  @override
  String get athlete_rating_title => 'Рейтинг';

  @override
  String get athlete_rating_info =>
      'Рейтинг рассчитывается по данным результатов данного приложения';

  @override
  String get reset_password_title => 'Сброс пароля';

  @override
  String get reset_password_description =>
      'Введите email, и мы отправим ссылку для сброса пароля.';

  @override
  String get reset_password_send_button => 'ОТПРАВИТЬ ПИСЬМО';

  @override
  String get reset_password_remember => 'Вспомнили пароль?';

  @override
  String get reset_password_sign_in => 'Войти';

  @override
  String get dashboard_notification_card_title => 'Оставайтесь в курсе!';

  @override
  String get dashboard_notification_card_message =>
      'Получайте уведомления о ваших результатах гонок, предстоящих событиях и важных обновлениях.';

  @override
  String get dashboard_notification_card_enable => 'Да, включить';

  @override
  String get dashboard_notification_card_later => 'Может позже';
}
