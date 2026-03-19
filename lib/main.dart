import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:ironman_mobile/features/settings/application/theme_notifier.dart';
import 'package:ironman_mobile/features/settings/presentation/settings_screen.dart';
import 'package:ironman_mobile/features/upcoming_races/application/upcoming_races_notifier.dart';
import 'package:ironman_mobile/features/results/application/race_results_notifier.dart';
import 'package:ironman_mobile/features/notifications/application/notifications_notifier.dart';
import 'package:ironman_mobile/core/config/app_config.dart';
import 'package:ironman_mobile/firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('=== FLUTTER ERROR CAUGHT ===');
    debugPrint('Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('=== PLATFORM ERROR CAUGHT ===');
    debugPrint('Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  AppConfig.initialize();

  try {
    await Hive.initFlutter();
  } catch (e) {
    debugPrint('Hive error: $e');
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase error: $e');
  }

  // ✅ FIXED SYSTEM UI (light)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // Light theme colors
  static const Color _red = Color(0xFFE53935);

  static ThemeData _lightTheme() => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: _red,
          onPrimary: Colors.white,
          secondary: _red,
          onSecondary: Colors.white,
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF111111),
          error: _red,
          outline: Color(0xFFCCCCCC),
          outlineVariant: Color(0xFFE0E0E0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111111),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _red),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF111111),
            side: const BorderSide(color: Color(0xFFCCCCCC)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: _red.withValues(alpha: 0.1),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: _red, fontWeight: FontWeight.w600, fontSize: 12);
            }
            return const TextStyle(color: Color(0xFF777777), fontSize: 12);
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          labelStyle: const TextStyle(color: Color(0xFF777777)),
          hintStyle: const TextStyle(color: Color(0xFF777777)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _red, width: 2),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF111111)),
          bodyMedium: TextStyle(color: Color(0xFF111111)),
          bodySmall: TextStyle(color: Color(0xFF777777)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111111)),
        dividerTheme: const DividerThemeData(color: Color(0xFFE0E0E0)),
      );

  static ThemeData _darkTheme() => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: _red,
          onPrimary: Colors.white,
          secondary: _red,
          onSecondary: Colors.white,
          surface: const Color(0xFF1A1A1A),
          onSurface: Colors.white,
          error: _red,
          outline: const Color(0xFF3A3A3A),
          outlineVariant: const Color(0xFF2A2A2A),
          surfaceContainerHighest: const Color(0xFF2A2A2A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0D0D),
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A1A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _red),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF3A3A3A)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1A1A1A),
          indicatorColor: _red.withValues(alpha: 0.2),
          surfaceTintColor: const Color(0xFF0D0D0D),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: _red, fontWeight: FontWeight.w600, fontSize: 12);
            }
            return const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12);
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          prefixIconColor: const Color(0xFFB0B0B0),
          suffixIconColor: const Color(0xFFB0B0B0),
          labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
          hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _red, width: 2),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Color(0xFFB0B0B0)),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        dividerTheme: const DividerThemeData(color: Color(0xFF2A2A2A)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) => MaterialApp(
        navigatorKey: navigatorKey,
        title: 'TriRank',
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ru'), Locale('az')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        themeMode: themeMode,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),

        home: const AuthRouter(),

        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/email-not-verified': (context) =>
              const EmailNotVerifiedScreen(),
          '/reset-password': (context) =>
              const ResetPasswordScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/pace-calculator': (context) =>
              const PaceCalculatorScreen(),
          '/profile': (context) => const DashboardScreen(),
          '/results': (context) => const ResultsScreen(),
          '/ratings': (context) => const RatingsScreen(),
          '/athletes': (context) => const AthletesScreen(),
        },
      ),
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

    SessionManager().init(
      navigatorKey: navigatorKey,
      onForceLogout: () {
        ref.read(authProvider.notifier).forceLogout();
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/bg.png'), context);
    });

    Future.microtask(() {
      ref.read(authProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    debugPrint('=== AuthRouter.build() called ===');
    debugPrint('isAuthenticated: ${authState.isAuthenticated}');
    debugPrint('isInitial: ${authState.isInitial}');
    debugPrint('isLoading: ${authState.isLoading}');
    debugPrint('user: ${authState.user?.email ?? 'null'}');

    ref.listen<AuthState>(authProvider, (previous, next) {
      final previousUserId = previous?.user?.id;
      final nextUserId = next.user?.id;

      final userChanged =
          (previousUserId != null &&
              nextUserId != null &&
              previousUserId != nextUserId) ||
          (previous?.isAuthenticated == true && !next.isAuthenticated) ||
          (previous?.isAuthenticated != true &&
              next.isAuthenticated &&
              previousUserId != nextUserId);

      if (userChanged) {
        ref.read(raceResultsProvider.notifier).reset();
        ref.read(allRaceResultsProvider.notifier).reset();
        ref.read(notificationsProvider.notifier).reset();
      }

      if ((previous?.isAuthenticated != true) &&
          next.isAuthenticated &&
          next.user?.verified == true) {
        ref
            .read(globalUpcomingRacesProvider.notifier)
            .loadUpcomingRaces(onlyFuture: true);
      }
    });

    if (authState.isInitial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.isAuthenticated) {
      if (authState.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (authState.user != null && !authState.user!.verified) {
        return const EmailNotVerifiedScreen();
      }
      return const DashboardScreen();
    }

    return const HomeScreen();
  }
}