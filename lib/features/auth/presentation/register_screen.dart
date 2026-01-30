import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/utils/alert_helper.dart';
import '../application/auth_notifier.dart';
import '../application/auth_state.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _registrationSuccess = false;
  Timer? _debounceTimer;
  DateTime? _lastRegisterAttempt;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;

    // Debounce: предотвращаем множественные нажатия
    final now = DateTime.now();
    if (_lastRegisterAttempt != null) {
      final timeSinceLastAttempt = now.difference(_lastRegisterAttempt!);
      if (timeSinceLastAttempt < const Duration(milliseconds: 500)) {
        return; // Игнорируем слишком частые нажатия
      }
    }
    _lastRegisterAttempt = now;

    // Отменяем предыдущий таймер, если есть
    _debounceTimer?.cancel();

    // Устанавливаем новый таймер для debounce
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(authProvider.notifier)
          .register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            passwordConfirmation: _confirmPasswordController.text,
          );
    });
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final localizations = AppLocalizations.of(context)!;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ErrorHandler.showError(context, next.error!);
      }

      // Show warning (informational message from server)
      if (next.warning != null && next.warning != previous?.warning) {
        AlertHelper.showInfo(context, next.warning!);
      }

      // Listen for logout
      if (next.isUnauthenticated && previous?.isUnauthenticated != true) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }

      // Check if registration was successful
      // Проверяем успешную регистрацию по завершению загрузки без ошибки
      // Пользователь не аутентифицируется после регистрации, поэтому проверяем только isLoading и error
      if (previous?.isLoading == true &&
          next.isLoading == false &&
          next.error == null &&
          !next.isAuthenticated) {
        setState(() {
          _registrationSuccess = true;
        });
      }
    });

    if (_registrationSuccess) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        size: 64,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    localizations.register_thank_you,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.register_success_message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 48),
                  FilledButton(
                    onPressed: _goToLogin,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      localizations.register_success_sign_in,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(),
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
                          width: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizations.register_title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                enabled: !authState.isLoading,
                                decoration: InputDecoration(
                                  labelText: localizations.register_name,
                                  prefixIcon: HugeIcon(
                                    icon: HugeIcons.strokeRoundedUser,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return localizations.register_name_required;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !authState.isLoading,
                                decoration: InputDecoration(
                                  labelText: localizations.login_email,
                                  prefixIcon: HugeIcon(
                                    icon: HugeIcons.strokeRoundedMail01,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: HugeIcon(
                                      icon: _obscurePassword
                                          ? HugeIcons.strokeRoundedView
                                          : HugeIcons.strokeRoundedViewOff,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
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
                                    return localizations
                                        .login_password_required;
                                  }
                                  if (value.length < 6) {
                                    return localizations
                                        .register_password_min_length;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                enabled: !authState.isLoading,
                                decoration: InputDecoration(
                                  labelText:
                                      localizations.register_confirm_password,
                                  prefixIcon: HugeIcon(
                                    icon: HugeIcons.strokeRoundedLockPassword,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: HugeIcon(
                                      icon: _obscureConfirmPassword
                                          ? HugeIcons.strokeRoundedView
                                          : HugeIcons.strokeRoundedViewOff,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return localizations
                                        .register_confirm_password_required;
                                  }
                                  if (value != _passwordController.text) {
                                    return localizations
                                        .register_passwords_not_match;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : _register,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        localizations.register_button,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
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
                            localizations.register_already_have_account,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: authState.isLoading
                                ? null
                                : () {
                                    Navigator.pop(context);
                                  },
                            child: Text(localizations.register_sign_in),
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
        // Overlay с лоадером при выходе
        if (authState.isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
