import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/widgets/language_selector.dart';
import '../application/auth_notifier.dart';
import '../application/auth_state.dart';
import 'email_not_verified_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'package:ironman_mobile/core/theme/app_button_styles.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  Timer? _debounceTimer;
  DateTime? _lastLoginAttempt;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    // Debounce: предотвращаем множественные нажатия
    final now = DateTime.now();
    if (_lastLoginAttempt != null) {
      final timeSinceLastAttempt = now.difference(_lastLoginAttempt!);
      if (timeSinceLastAttempt < const Duration(milliseconds: 500)) {
        return; // Игнорируем слишком частые нажатия
      }
    }
    _lastLoginAttempt = now;

    // Отменяем предыдущий таймер, если есть
    _debounceTimer?.cancel();

    // Устанавливаем новый таймер для debounce
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final localizations = AppLocalizations.of(context)!;

    ref.listen<AuthState>(authProvider, (previous, next) {
      // Show error
      if (next.error != null && next.error != previous?.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ErrorHandler.showError(context, next.error!);
        });
      }

      // ВАЖНО: Навигация после успешного логина
      // Проверяем, что пользователь стал аутентифицированным
      if (previous?.isAuthenticated != true &&
          next.isAuthenticated &&
          !next.isLoading &&
          !next.isInitial &&
          context.mounted) {
        // Определяем целевой экран на основе состояния пользователя
        Widget targetScreen;

        if (next.user != null && !next.user!.verified) {
          targetScreen = const EmailNotVerifiedScreen();
        } else {
          targetScreen = const DashboardScreen();
        }

        // Выполняем навигацию после отрисовки кадра
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => targetScreen),
            );
          }
        });
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background image with gradient overlay
          Transform.rotate(
            angle: 3.14159, // 180 градусов (π радиан)
            child: Container(
              height: 0.5.sh,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: Colors.white,
                  size: 24.r,
                ),
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: const LanguageSelector(),
                ),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.r),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          localizations.login_title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        SizedBox(height: 32.h),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            side: BorderSide.none,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(24.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !authState.isLoading,
                                  decoration: InputDecoration(
                                    labelText: localizations.login_email,
                                    prefixIcon: HugeIcon(
                                      icon: HugeIcons.strokeRoundedMail01,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      size: 20.r,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return localizations.login_email_required;
                                    }
                                    if (!value.contains('@')) {
                                      return localizations.login_email_invalid;
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16.h),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  enabled: !authState.isLoading,
                                  decoration: InputDecoration(
                                    labelText: localizations.login_password,
                                    prefixIcon: HugeIcon(
                                      icon: HugeIcons.strokeRoundedLockPassword,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      size: 20.r,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: HugeIcon(
                                        icon: _obscurePassword
                                            ? HugeIcons.strokeRoundedView
                                            : HugeIcons.strokeRoundedViewOff,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        size: 20.r,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return localizations.login_password_required;
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 8.h),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: authState.isLoading
                                        ? null
                                        : () {
                                            Navigator.pushNamed(
                                                context, '/reset-password');
                                          },
                                    child: Text(localizations.login_forgot_password),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                SizedBox(
                                  width: double.infinity,
                                  child: authState.isLoading
                                      ? Container(
                                          padding: EdgeInsets.symmetric(vertical: 16.h),
                                          decoration: AppButtonStyles.primaryGradientDecoration(
                                            borderRadius: 12.r,
                                          ),
                                          child: Center(
                                            child: SizedBox(
                                              height: 20.r,
                                              width: 20.r,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        )
                                      : AppButtonStyles.primaryGradientButton(
                                          text: localizations.login_button,
                                          onPressed: _login,
                                          borderRadius: 12.r,
                                          padding: EdgeInsets.symmetric(vertical: 16.h),
                                          textStyle: TextStyle(
                                            fontSize: 16.sp,
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
                        SizedBox(height: 24.h),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              localizations.login_no_account,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(context, '/register');
                                    },
                              child: Text(localizations.login_create_account),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
