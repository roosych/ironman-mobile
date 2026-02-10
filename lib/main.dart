import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/core/services/fcm_service.dart';
import 'package:ironman_mobile/core/session/session_manager.dart';
import 'package:ironman_mobile/features/auth/application/auth_notifier.dart';
import 'package:ironman_mobile/features/auth/application/auth_state.dart';
import 'package:ironman_mobile/features/auth/presentation/login_screen.dart';
import 'package:ironman_mobile/features/auth/presentation/register_screen.dart';
import 'package:ironman_mobile/features/auth/presentation/email_not_verified_screen.dart';
import 'package:ironman_mobile/features/auth/presentation/reset_password_screen.dart';
import 'package:ironman_mobile/features/profile/presentation/profile_selection_screen.dart';
import 'package:ironman_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:ironman_mobile/features/home/presentation/home_screen.dart';
import 'package:ironman_mobile/features/home/presentation/pace_calculator_screen.dart';
import 'package:ironman_mobile/features/dashboard/presentation/results_screen.dart';
import 'package:ironman_mobile/features/dashboard/presentation/ratings_screen.dart';
import 'package:ironman_mobile/features/dashboard/presentation/athletes_screen.dart';
import 'package:ironman_mobile/features/settings/application/locale_notifier.dart';
import 'package:ironman_mobile/features/settings/presentation/settings_screen.dart';
import 'package:ironman_mobile/features/upcoming_races/application/upcoming_races_notifier.dart';
import 'package:ironman_mobile/features/results/application/race_results_notifier.dart';
import 'package:ironman_mobile/features/notifications/application/notifications_notifier.dart';
import 'package:ironman_mobile/core/config/app_config.dart';

/// Global navigator key for navigation without BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AppConfig FIRST - before any other services
  AppConfig.initialize();

  // Initialize Hive
  try {
    await Hive.initFlutter();
    debugPrint('✅ Hive initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing Hive: $e');
  }

  // ВАЖНО: Регистрация background handler ДО инициализации Firebase
  // Это должно быть сделано до runApp() и до Firebase.initializeApp()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');

    // ВАЖНО: Не инициализируем FCM здесь, так как это требует валидную сессию
    // FCM будет инициализирован автоматически после восстановления сессии
    // в auth_repository.dart через hasSession() -> FcmService().initialize()
    // Это гарантирует, что токен регистрируется только для авторизованных пользователей
  } catch (e) {
    debugPrint('❌ Error initializing Firebase: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0D0D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // Цветовая палитра
  static const Color ironmanRed = Color(0xFFE31837);
  static const Color ironmanBlack = Color(0xFF0D0D0D);
  static const Color ironmanDarkGray = Color(0xFF1A1A1A);
  static const Color ironmanGray = Color(0xFF2A2A2A);
  static const Color ironmanLightGray = Color(0xFF3A3A3A);
  static const Color ironmanWhite = Color(0xFFFFFFFF);
  static const Color ironmanTextSecondary = Color(0xFFB0B0B0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    // ВАЖНО: Отслеживаем изменения authState для принудительной перерисовки AuthRouter
    final authState = ref.watch(authProvider);
    // Создаем динамический ключ на основе состояния для принудительной перерисовки
    final routerKey = AuthRouter.getKey(authState);
    debugPrint(
      '=== MyApp: Building with authState - isAuthenticated: ${authState.isAuthenticated}, user: ${authState.user?.id} ===',
    );
    debugPrint('=== MyApp: Router key: ${routerKey.value} ===');

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'IRONSTATS',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ru'), Locale('az')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: ironmanRed,
          onPrimary: ironmanWhite,
          secondary: ironmanRed,
          onSecondary: ironmanWhite,
          surface: ironmanDarkGray,
          onSurface: ironmanWhite,
          error: ironmanRed,
          outline: ironmanLightGray,
          outlineVariant: ironmanGray,
          surfaceContainerHighest: ironmanGray,
        ),
        scaffoldBackgroundColor: ironmanBlack,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: ironmanBlack,
          foregroundColor: ironmanWhite,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: ironmanDarkGray,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ironmanGray, width: 1),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: ironmanRed,
            foregroundColor: ironmanWhite,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: ironmanRed),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ironmanWhite,
            side: const BorderSide(color: ironmanLightGray),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: ironmanDarkGray,
          indicatorColor: ironmanRed.withValues(alpha: 0.2),
          surfaceTintColor: ironmanBlack,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: ironmanRed,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              );
            }
            return const TextStyle(color: ironmanTextSecondary, fontSize: 12);
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ironmanGray,
          prefixIconColor: ironmanTextSecondary,
          suffixIconColor: ironmanTextSecondary,
          labelStyle: const TextStyle(color: ironmanTextSecondary),
          hintStyle: const TextStyle(color: ironmanTextSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ironmanLightGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ironmanLightGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ironmanRed, width: 2),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: ironmanWhite),
          headlineMedium: TextStyle(color: ironmanWhite),
          headlineSmall: TextStyle(color: ironmanWhite),
          titleLarge: TextStyle(color: ironmanWhite),
          titleMedium: TextStyle(color: ironmanWhite),
          titleSmall: TextStyle(color: ironmanWhite),
          bodyLarge: TextStyle(color: ironmanWhite),
          bodyMedium: TextStyle(color: ironmanWhite),
          bodySmall: TextStyle(color: ironmanTextSecondary),
          labelLarge: TextStyle(color: ironmanWhite),
          labelMedium: TextStyle(color: ironmanWhite),
          labelSmall: TextStyle(color: ironmanTextSecondary),
        ),
        iconTheme: const IconThemeData(color: ironmanWhite),
        dividerTheme: const DividerThemeData(color: ironmanGray),
      ),
      // ВАЖНО: Используем AuthRouter напрямую с динамическим ключом
      // Ключ меняется при изменении состояния, что заставляет Flutter пересоздать виджет
      home: AuthRouter(key: routerKey),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/email-not-verified': (context) => const EmailNotVerifiedScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/profile-selection': (context) => const ProfileSelectionScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/pace-calculator': (context) => const PaceCalculatorScreen(),
        '/profile': (context) => const DashboardScreen(), // Redirect to dashboard for authenticated users
        '/results': (context) => const ResultsScreen(),
        '/ratings': (context) => const RatingsScreen(),
        '/athletes': (context) => const AthletesScreen(),
      },
    );
  }
}

class AuthRouter extends ConsumerStatefulWidget {
  const AuthRouter({super.key});

  // ВАЖНО: Используем ValueKey для принудительной перерисовки при изменении состояния
  // Это гарантирует, что роутер пересоздастся при изменении authState
  static ValueKey<String> getKey(AuthState state) {
    final userKey = state.user?.id ?? 'null';
    final authKey = state.isAuthenticated ? 'auth' : 'unauth';
    final profileKey = state.user?.profile is Map<String, dynamic>
        ? (state.user!.profile as Map<String, dynamic>)['id']?.toString() ??
              'no_profile'
        : 'no_profile';
    return ValueKey('auth_router_${userKey}_${authKey}_$profileKey');
  }

  @override
  ConsumerState<AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends ConsumerState<AuthRouter> {
  @override
  void initState() {
    super.initState();

    // Initialize SessionManager with navigator key and forceLogout callback
    SessionManager().init(
      navigatorKey: navigatorKey,
      onForceLogout: () {
        ref.read(authProvider.notifier).forceLogout();
      },
    );

    // Restore session after initialization
    Future.microtask(() {
      ref.read(authProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ВАЖНО: Используем ref.watch для отслеживания изменений состояния
    // Это гарантирует, что роутер перерисуется при изменении authState
    final authState = ref.watch(authProvider);

    // Отладочный вывод для диагностики
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    debugPrint('=== AuthRouter build ($timestamp) ===');
    debugPrint('isAuthenticated: ${authState.isAuthenticated}');
    debugPrint('isLoading: ${authState.isLoading}');
    debugPrint('user: ${authState.user?.id}');
    debugPrint('status: ${authState.status}');
    debugPrint('user.profile: ${authState.user?.profile}');
    debugPrint('authState.hashCode: ${authState.hashCode}');

    // Загружаем upcoming события при восстановлении сессии или после логина
    // и очищаем результаты при смене пользователя
    // ВАЖНО: Навигация происходит в LoginScreen после успешного логина
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Очищаем результаты при смене пользователя (логин/логаут)
      final previousUserId = previous?.user?.id;
      final nextUserId = next.user?.id;
      final previousProfileId = previous?.user?.profile is Map<String, dynamic>
          ? (previous!.user!.profile as Map<String, dynamic>)['id'] as int?
          : null;
      final nextProfileId = next.user?.profile is Map<String, dynamic>
          ? (next.user!.profile as Map<String, dynamic>)['id'] as int?
          : null;

      // Если пользователь изменился (разные ID или profile ID) или произошел логаут
      // ВАЖНО: Проверяем смену пользователя даже если оба аутентифицированы
      final userChanged =
          (previousUserId != null &&
              nextUserId != null &&
              previousUserId != nextUserId) ||
          (previousProfileId != null &&
              nextProfileId != null &&
              previousProfileId != nextProfileId) ||
          (previous?.isAuthenticated == true && !next.isAuthenticated) ||
          (previous?.isAuthenticated != true &&
              next.isAuthenticated &&
              previousUserId != nextUserId);

      if (userChanged) {
        debugPrint('=== Clearing data due to user change ===');
        debugPrint(
          'Previous user ID: $previousUserId, Next user ID: $nextUserId',
        );
        debugPrint(
          'Previous profile ID: $previousProfileId, Next profile ID: $nextProfileId',
        );
        // Очищаем результаты предыдущего пользователя
        ref.read(raceResultsProvider.notifier).reset();
        ref.read(allRaceResultsProvider.notifier).reset();
        // Очищаем уведомления предыдущего пользователя
        ref.read(notificationsProvider.notifier).reset();
      }

      // Загружаем upcoming события только для верифицированных пользователей с валидным профилем
      if ((previous?.isAuthenticated != true) &&
          next.isAuthenticated &&
          next.user?.verified == true) {
        // Проверяем наличие валидного профиля перед загрузкой данных
        bool hasValidProfile = false;
        if (next.user?.profile is Map<String, dynamic>) {
          final profile = next.user!.profile as Map<String, dynamic>;
          final profileId = profile['id'];
          hasValidProfile = profileId != null && profileId is int;
        }

        // Загружаем данные только если профиль валиден
        if (hasValidProfile) {
          ref
              .read(globalUpcomingRacesProvider.notifier)
              .loadUpcomingRaces(onlyFuture: true);
        }
      }
    });

    if (authState.isInitial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // НЕ показываем лоадер в роутере при isLoading - лоадер должен показываться
    // на конкретных экранах (логин, регистрация), чтобы пользователь видел форму
    // и мог видеть ошибки. Роутер только определяет, какой экран показать.
    // ВАЖНО: Если пользователь аутентифицирован, показываем правильный экран,
    // даже если isLoading == true (это может быть фоновое обновление)

    if (authState.isAuthenticated) {
      debugPrint('=== AuthRouter: User is authenticated ===');
      debugPrint('isLoading: ${authState.isLoading}');
      debugPrint('User: ${authState.user?.id}');
      debugPrint('User verified: ${authState.user?.verified}');
      if (authState.user != null && !authState.user!.verified) {
        return const EmailNotVerifiedScreen();
      }
      // Проверяем наличие профиля - если нет, показываем экран выбора профиля
      // Профиль считается валидным только если в нем есть поле 'id'
      final user = authState.user;
      bool hasProfile = false;
      if (user?.profile is Map<String, dynamic>) {
        final profile = user!.profile as Map<String, dynamic>;
        // Профиль валиден только если в нем есть 'id' (это означает, что профиль реально привязан)
        final profileId = profile['id'];
        hasProfile = profileId != null && profileId is int;
      }

      // Отладочный вывод для диагностики
      debugPrint('=== AuthRouter Profile Check ===');
      debugPrint('User ID: ${user?.id}');
      debugPrint('Profile: ${user?.profile}');
      debugPrint('Profile type: ${user?.profile.runtimeType}');
      debugPrint('Has Profile: $hasProfile');
      if (user?.profile is Map<String, dynamic>) {
        final profile = user!.profile as Map<String, dynamic>;
        debugPrint('Profile keys: ${profile.keys}');
        debugPrint('Profile id: ${profile['id']}');
      }
      debugPrint('================================');

      if (user != null && !hasProfile) {
        debugPrint('=== AuthRouter: Showing ProfileSelectionScreen ===');
        return const ProfileSelectionScreen();
      }
      debugPrint('=== AuthRouter: Showing DashboardScreen ===');
      return const DashboardScreen();
    }

    debugPrint(
      '=== AuthRouter: User NOT authenticated, showing HomeScreen ===',
    );
    debugPrint('isAuthenticated: ${authState.isAuthenticated}');
    debugPrint('isLoading: ${authState.isLoading}');
    return const HomeScreen();
  }
}
