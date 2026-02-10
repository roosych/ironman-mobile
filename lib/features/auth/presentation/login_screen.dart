import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/utils/alert_helper.dart';
import '../../settings/application/locale_notifier.dart';
import '../application/auth_notifier.dart';
import '../application/auth_state.dart';
import 'email_not_verified_screen.dart';
import '../../profile/presentation/profile_selection_screen.dart';
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
    final locale = ref.watch(localeProvider);
    final localizations = AppLocalizations.of(context)!;

    ref.listen<AuthState>(authProvider, (previous, next) {
      // Show error
      if (next.error != null && next.error != previous?.error) {
        ErrorHandler.showError(context, next.error!);
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
          // Проверяем наличие профиля
          bool hasProfile = false;
          if (next.user?.profile is Map<String, dynamic>) {
            final profile = next.user!.profile as Map<String, dynamic>;
            final profileId = profile['id'];
            hasProfile = profileId != null && profileId is int;
          }
          
          if (next.user != null && !hasProfile) {
            targetScreen = const ProfileSelectionScreen();
          } else {
            targetScreen = const DashboardScreen();
          }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _LanguageDropdown(
              currentLocale: locale,
              onLocaleChanged: (Locale newLocale) async {
                // Hide all current SnackBars before language change
                ScaffoldMessenger.of(context).clearSnackBars();
                
                await ref.read(localeProvider.notifier).setLocale(newLocale);
                
                // Wait for Flutter to rebuild with new locale
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      final updatedLocalizations = AppLocalizations.of(context);
                      if (updatedLocalizations != null) {
                        AlertHelper.showInfo(context, updatedLocalizations.settings_language_changed);
                      }
                    }
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Text(
                  //   'Sign in to your account',
                  //   textAlign: TextAlign.center,
                  //   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  //         color: Theme.of(context)
                  //             .colorScheme
                  //             .onSurface
                  //             .withValues(alpha: 0.6),
                  //       ),
                  // ),
                  const SizedBox(height: 48),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
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
                                size: 20,
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
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enabled: !authState.isLoading,
                            decoration: InputDecoration(
                              labelText: localizations.login_password,
                              prefixIcon: HugeIcon(
                                icon: HugeIcons.strokeRoundedLockPassword,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: HugeIcon(
                                  icon: _obscurePassword
                                      ? HugeIcons.strokeRoundedView
                                      : HugeIcons.strokeRoundedViewOff,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 20,
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
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: authState.isLoading
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
                                    text: localizations.login_button,
                                    onPressed: _login,
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  const _LanguageDropdown({
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  static String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'ru':
        return 'Русский';
      case 'az':
        return 'Azərbaycan';
      case 'en':
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Locale>(
      value: currentLocale,
      icon: const HugeIcon(
        icon: HugeIcons.strokeRoundedArrowDown01,
        size: 20,
        color: Colors.white70,
      ),
      underline: Container(),
      dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      items: const [
        Locale('az'),
        Locale('en'),
        Locale('ru'),
      ].map<DropdownMenuItem<Locale>>((Locale locale) {
        return DropdownMenuItem<Locale>(
          value: locale,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getLanguageName(locale),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (Locale? newLocale) {
        if (newLocale != null) {
          onLocaleChanged(newLocale);
        }
      },
    );
  }
}
