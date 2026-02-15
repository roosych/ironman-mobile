import 'dart:ui';
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
import 'package:ironman_mobile/core/network/simple_api_client.dart';

/// Global navigator key for navigation without BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handling to catch crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('=== FLUTTER ERROR CAUGHT ===');
    debugPrint('Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    debugPrint('Library: ${details.library}');
    debugPrint('Context: ${details.context}');
    debugPrint('========================');

    // Don't show red screens in debug mode for expected network errors
    final isNetworkError = details.exception.toString().toLowerCase().contains('timeout') ||
        details.exception.toString().toLowerCase().contains('connection') ||
        details.exception.toString().toLowerCase().contains('dioexception');

    if (!isNetworkError) {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('=== PLATFORM ERROR CAUGHT ===');
    debugPrint('Error: $error');
    debugPrint('Stack trace: $stack');
    debugPrint('========================');
    return true;
  };

  // Initialize AppConfig FIRST - before any other services
  AppConfig.initialize();

  // Initialize SimpleApiClient
  try {
    await SimpleApiClient().init();
    debugPrint('✅ SimpleApiClient initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing SimpleApiClient: $e');
  }

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
  static const Color ironmanRed = Color.fromARGB(255, 35, 129, 201);
  static const Color ironmanBlack = Color(0xFF0D0D0D);
  static const Color ironmanDarkGray = Color(0xFF1A1A1A);
  static const Color ironmanGray = Color(0xFF2A2A2A);
  static const Color ironmanLightGray = Color(0xFF3A3A3A);
  static const Color ironmanWhite = Color(0xFFFFFFFF);
  static const Color ironmanTextSecondary = Color(0xFFB0B0B0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

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
      home: const AuthRouter(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/email-not-verified': (context) => const EmailNotVerifiedScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/pace-calculator': (context) => const PaceCalculatorScreen(),
        '/profile': (context) =>
            const DashboardScreen(), // Redirect to dashboard for authenticated users
        '/results': (context) => const ResultsScreen(),
        '/ratings': (context) => const RatingsScreen(),
        '/athletes': (context) => const AthletesScreen(),
      },
    );
  }
}

class AuthRouter extends ConsumerStatefulWidget {
  const AuthRouter({super.key});

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

    // Precache background image to prevent flickering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/bg.png'), context);
    });

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

    debugPrint('=== AuthRouter.build() called ===');
    debugPrint('isAuthenticated: ${authState.isAuthenticated}');
    debugPrint('isInitial: ${authState.isInitial}');
    debugPrint('isLoading: ${authState.isLoading}');
    debugPrint('user: ${authState.user?.email ?? 'null'}');

    // Загружаем upcoming события при восстановлении сессии или после логина
    // и очищаем результаты при смене пользователя
    // ВАЖНО: Навигация происходит в LoginScreen после успешного логина
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Очищаем результаты при смене пользователя (логин/логаут)
      final previousUserId = previous?.user?.id;
      final nextUserId = next.user?.id;

      // Если пользователь изменился или произошел логаут
      // ВАЖНО: Проверяем смену пользователя даже если оба аутентифицированы
      final userChanged =
          (previousUserId != null &&
              nextUserId != null &&
              previousUserId != nextUserId) ||
          (previous?.isAuthenticated == true && !next.isAuthenticated) ||
          (previous?.isAuthenticated != true &&
              next.isAuthenticated &&
              previousUserId != nextUserId);

      if (userChanged) {
        // Очищаем результаты предыдущего пользователя
        ref.read(raceResultsProvider.notifier).reset();
        ref.read(allRaceResultsProvider.notifier).reset();
        // Очищаем уведомления предыдущего пользователя
        ref.read(notificationsProvider.notifier).reset();
      }

      // Загружаем upcoming события для всех верифицированных пользователей
      if ((previous?.isAuthenticated != true) &&
          next.isAuthenticated &&
          next.user?.verified == true) {
        ref
            .read(globalUpcomingRacesProvider.notifier)
            .loadUpcomingRaces(onlyFuture: true);
      }
    });

    if (authState.isInitial) {
      debugPrint('=== AuthRouter: Showing initial loader ===');
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // НЕ показываем лоадер в роутере при isLoading - лоадер должен показываться
    // на конкретных экранах (логин, регистрация), чтобы пользователь видел форму
    // и мог видеть ошибки. Роутер только определяет, какой экран показать.
    // ВАЖНО: Если пользователь аутентифицирован, показываем правильный экран,
    // даже если isLoading == true (это может быть фоновое обновление)

    if (authState.isAuthenticated) {
      debugPrint('=== AuthRouter: User is authenticated ===');
      // ВАЖНО: Не навигируем, пока данные загружаются
      if (authState.isLoading) {
        debugPrint(
          '=== AuthRouter: Showing loading for authenticated user ===',
        );
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (authState.user != null && !authState.user!.verified) {
        debugPrint('=== AuthRouter: Showing EmailNotVerifiedScreen ===');
        return const EmailNotVerifiedScreen();
      }
      debugPrint('=== AuthRouter: Showing DashboardScreen ===');
      return const DashboardScreen();
    }

    debugPrint('=== AuthRouter: Showing HomeScreen ===');
    return const HomeScreen();
  }
}
