import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import '../../../shared/utils/alert_helper.dart';
import '../../../shared/utils/error_handler.dart';
import '../../../core/theme/app_button_styles.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../settings/application/theme_notifier.dart';
import '../application/auth_notifier.dart';

class EmailNotVerifiedScreen extends ConsumerStatefulWidget {
  const EmailNotVerifiedScreen({super.key});

  @override
  ConsumerState<EmailNotVerifiedScreen> createState() => _EmailNotVerifiedScreenState();
}

class _EmailNotVerifiedScreenState extends ConsumerState<EmailNotVerifiedScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isLoggingOut = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    debugPrint('🚀 EmailNotVerified: Starting timer with 40 seconds');
    _remainingSeconds = 40;
    _timer?.cancel();
    setState(() {}); // Перерисовываем UI сразу после установки таймера

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
            debugPrint('⏰ EmailNotVerified: Timer countdown: $_remainingSeconds seconds');
          } else {
            debugPrint('✅ EmailNotVerified: Timer finished');
            _timer?.cancel();
            _timer = null;
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _resendEmail() {
    debugPrint('📧 EmailNotVerified: Button pressed');
    if (_remainingSeconds > 0) {
      debugPrint('❌ EmailNotVerified: Button blocked, timer still running: $_remainingSeconds seconds');
      return;
    }

    debugPrint('🚀 EmailNotVerified: Starting resend process');

    // Запускаем таймер сразу после нажатия (синхронно)
    _startTimer();

    // Отправляем письмо в фоне без блокировки UI
    _sendEmailInBackground();
  }

  Future<void> _sendEmailInBackground() async {
    try {
      await ref.read(authProvider.notifier).resendEmailVerification();
      // Убираем alert с успехом, письмо отправляется тихо в фоне
    } catch (e) {
      if (mounted) {
        // Fallback для неизвестных ошибок
        final errorMessage = e.toString();
        if (errorMessage.contains('404') || errorMessage.contains('not found')) {
          AlertHelper.showError(context, 'Функция повторной отправки временно недоступна');
        } else if (errorMessage.contains('429') || errorMessage.contains('too many')) {
          AlertHelper.showError(context, 'Слишком много запросов. Попробуйте позже');
        } else {
          ErrorHandler.showError(context, e);
        }
      }
    }
  }

  Widget _buildResendButton(AppLocalizations localizations) {
    debugPrint('🔄 EmailNotVerified: Building button, remainingSeconds: $_remainingSeconds');
    if (_remainingSeconds > 0) {
      debugPrint('⏰ EmailNotVerified: Showing timer button with $_remainingSeconds seconds');
      return Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.grey.withValues(alpha: 0.3),
        ),
        child: Center(
          child: Text(
            '$_remainingSeconds',
            style: TextStyle(
              fontSize: 18.sp,
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
    return AppButtonStyles.gradientElevatedButton(
      text: localizations.email_not_verified_resend,
      onPressed: _resendEmail,
      borderRadius: 12.r,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      textStyle: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: Colors.white,
      ),
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedRefresh,
        color: Colors.white,
        size: 20.r,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userEmail = authState.user?.email ?? '';
    final localizations = AppLocalizations.of(context)!;

    debugPrint('🏗️ EmailNotVerified: Building screen, _isLoggingOut: $_isLoggingOut, authState.isLoading: ${authState.isLoading}');

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: HugeIcon(
                  icon: ref.watch(themeModeProvider) == ThemeMode.dark
                      ? HugeIcons.strokeRoundedSun01
                      : HugeIcons.strokeRoundedMoon02,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24.r,
                ),
                onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
              ),
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
                            fontSize: 20.sp,
                            letterSpacing: 1,
                          ),
                    ),
                    SizedBox(height: 16.h),
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
                    SizedBox(height: 48.h),
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
                            Text(
                              localizations.email_not_verified_no_email,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: 16.h),
                            _buildResendButton(localizations),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    OutlinedButton(
                      onPressed: _isLoggingOut
                          ? null
                          : () async {
                              setState(() {
                                _isLoggingOut = true;
                              });
                              await ref.read(authProvider.notifier).logout();
                              if (mounted) {
                                setState(() {
                                  _isLoggingOut = false;
                                });
                              }
                            },
                      child: _isLoggingOut
                          ? SizedBox(
                              height: 20.r,
                              width: 20.r,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
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
        if (_isLoggingOut)
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
