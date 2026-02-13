import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/shared/widgets/language_selector.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/core/theme/app_button_styles.dart';
import '../application/auth_notifier.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startTimer() {
    debugPrint('🚀 ResetPassword: Starting timer with 40 seconds');
    _remainingSeconds = 40;
    _timer?.cancel();
    setState(() {}); // Перерисовываем UI сразу после установки таймера

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
            debugPrint('⏰ ResetPassword: Timer countdown: $_remainingSeconds seconds');
          } else {
            debugPrint('✅ ResetPassword: Timer finished');
            _timer?.cancel();
            _timer = null;
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _resetPassword() {
    debugPrint('🔐 ResetPassword: Button pressed');
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ ResetPassword: Form validation failed');
      return;
    }

    if (_remainingSeconds > 0) {
      debugPrint('❌ ResetPassword: Button blocked, timer still running: $_remainingSeconds seconds');
      return;
    }

    debugPrint('🚀 ResetPassword: Starting reset process');

    // Запускаем таймер сразу после нажатия (синхронно)
    _startTimer();

    // Отправляем письмо в фоне без блокировки UI
    _sendResetEmailInBackground();
  }

  Future<void> _sendResetEmailInBackground() async {
    try {
      await ref.read(authProvider.notifier).forgotPassword(email: _emailController.text.trim());
      // Убираем success message - письмо отправляется тихо в фоне как в email verification
    } catch (e) {
      if (mounted) {
        // Fallback для неизвестных ошибок
        final errorMessage = e.toString();
        if (errorMessage.contains('404') || errorMessage.contains('not found')) {
          ErrorHandler.showError(context, 'Функция сброса пароля временно недоступна');
        } else if (errorMessage.contains('429') || errorMessage.contains('too many')) {
          ErrorHandler.showError(context, 'Слишком много запросов. Попробуйте позже');
        } else {
          ErrorHandler.showError(context, e);
        }
      }
    }
  }

  Widget _buildResetButton(AppLocalizations localizations) {
    debugPrint('🔄 ResetPassword: Building button, remainingSeconds: $_remainingSeconds');
    if (_remainingSeconds > 0) {
      debugPrint('⏰ ResetPassword: Showing timer button with $_remainingSeconds seconds');
      // Показываем таймер прямо в кнопке (неактивной)
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.withValues(alpha: 0.3),
        ),
        child: Center(
          child: Text(
            '$_remainingSeconds',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Обычная активная кнопка
    return AppButtonStyles.primaryGradientButton(
      text: localizations.reset_password_send_button,
      onPressed: _resetPassword,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Background image with gradient overlay
          Transform.rotate(
            angle: 3.14159, // 180 градусов (π радиан)
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5, // До середины экрана
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
                  child: const LanguageSelector(),
                ),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Description text above form
                      Text(
                        localizations.reset_password_description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Form card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
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
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: _buildResetButton(localizations),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Bottom text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            localizations.reset_password_remember,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(localizations.reset_password_sign_in),
                          ),
                        ],
                      ),
                    ],
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
