import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import '../../../shared/utils/alert_helper.dart';
import '../../../shared/utils/error_handler.dart';
import '../../../core/theme/app_button_styles.dart';
import '../application/auth_notifier.dart';

class EmailNotVerifiedScreen extends ConsumerStatefulWidget {
  const EmailNotVerifiedScreen({super.key});

  @override
  ConsumerState<EmailNotVerifiedScreen> createState() => _EmailNotVerifiedScreenState();
}

class _EmailNotVerifiedScreenState extends ConsumerState<EmailNotVerifiedScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isResendingEmail = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 40;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
            _timer = null;
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_isResendingEmail || _remainingSeconds > 0) return;

    setState(() {
      _isResendingEmail = true;
    });

    try {
      final message = await ref.read(authProvider.notifier).resendEmailVerification();
      if (mounted) {
        AlertHelper.showSuccess(context, message);
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        // Fallback для неизвестных ошибок
        final errorMessage = e.toString();
        if (errorMessage.contains('404') || errorMessage.contains('not found')) {
          AlertHelper.showError(context, 'Функция повторной отправки временно недоступна');
        } else if (errorMessage.contains('429') || errorMessage.contains('too many')) {
          AlertHelper.showError(context, 'Слишком много запросов. Попробуйте позже');
          _startTimer(); // Запускаем таймер даже при rate limit
        } else {
          ErrorHandler.showError(context, e);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResendingEmail = false;
        });
      }
    }
  }

  Widget _buildResendButton(AppLocalizations localizations) {
    if (_isResendingEmail) {
      // Показываем индикатор загрузки во время отправки
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: AppButtonStyles.primaryGradientDecoration(borderRadius: 12),
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
      );
    }

    if (_remainingSeconds > 0) {
      // Показываем таймер на заблокированной кнопке
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedClock01,
              color: Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '${localizations.email_not_verified_resend} (${_remainingSeconds}s)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Обычная активная кнопка
    return AppButtonStyles.gradientElevatedButton(
      text: localizations.email_not_verified_resend,
      onPressed: _resendEmail,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: Colors.white,
      ),
      icon: const HugeIcon(
        icon: HugeIcons.strokeRoundedRefresh,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userEmail = authState.user?.email ?? '';
    final localizations = AppLocalizations.of(context)!;


    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      localizations.email_not_verified_title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userEmail.isNotEmpty
                          ? '${localizations.email_not_verified_message}\n($userEmail)'
                          : localizations.email_not_verified_message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 48),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              localizations.email_not_verified_no_email,
                              textAlign: TextAlign.center,
                              style:
                                  Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                            ),
                            const SizedBox(height: 16),
                            _buildResendButton(localizations),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              ref.read(authProvider.notifier).logout();
                            },
                      child: Text(
                        localizations.email_not_verified_back_to_login,
                        style: const TextStyle(
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
        ),
        // Overlay с лоадером при выходе
        if (authState.isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
