import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/features/settings/application/theme_notifier.dart';
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
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _step2 = false; // false = enter email, true = enter OTP + new password
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  // Prevent keyboard from opening on locale change
  late final FocusNode _emailFocusNode;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 40;
    _timer?.cancel();
    setState(() {});
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

  Future<void> _sendEmail() async {
    if (_remainingSeconds > 0) return;
    // Validate only on step 1 (form is mounted)
    if (!_step2 && !(_step1FormKey.currentState?.validate() ?? false)) return;

    _startTimer();
    try {
      await ref.read(authProvider.notifier).forgotPassword(email: _emailController.text.trim());
      if (mounted) {
        setState(() => _step2 = true);
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    }
  }

  Future<void> _resetPassword() async {
    if (!_step2FormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).resetPassword(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSendButton(AppLocalizations localizations) {
    if (_remainingSeconds > 0) {
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
          ),
        ),
      );
    }
    return AppButtonStyles.primaryGradientButton(
      text: localizations.reset_password_send_button,
      onPressed: _sendEmail,
      borderRadius: 12.r,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      textStyle: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStep1(AppLocalizations localizations) {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            autofocus: false,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: localizations.login_email,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedMail01,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20.r,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return localizations.login_email_required;
              if (!value.contains('@')) return localizations.login_email_invalid;
              return null;
            },
          ),
          SizedBox(height: 24.h),
          SizedBox(width: double.infinity, child: _buildSendButton(localizations)),
        ],
      ),
    );
  }

  Widget _buildStep2(AppLocalizations localizations) {
    final theme = Theme.of(context);
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // OTP field
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              labelText: localizations.reset_password_otp,
              filled: true,
              fillColor: theme.colorScheme.surface,
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedShieldKey,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20.r,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return localizations.reset_password_otp_required;
              return null;
            },
          ),
          SizedBox(height: 16.h),
          // New password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: localizations.change_password_new,
              filled: true,
              fillColor: theme.colorScheme.surface,
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedLockPassword,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20.r,
              ),
              suffixIcon: IconButton(
                icon: HugeIcon(
                  icon: _obscurePassword
                      ? HugeIcons.strokeRoundedView
                      : HugeIcons.strokeRoundedViewOff,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20.r,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return localizations.change_password_new_required;
              if (value.length < 8) return localizations.register_password_min_length;
              return null;
            },
          ),
          SizedBox(height: 16.h),
          // Confirm password
          TextFormField(
            controller: _passwordConfirmController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: localizations.change_password_confirm,
              filled: true,
              fillColor: theme.colorScheme.surface,
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedLockPassword,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20.r,
              ),
              suffixIcon: IconButton(
                icon: HugeIcon(
                  icon: _obscureConfirm
                      ? HugeIcons.strokeRoundedView
                      : HugeIcons.strokeRoundedViewOff,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20.r,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return localizations.change_password_confirm_required;
              if (value != _passwordController.text) return localizations.register_passwords_not_match;
              return null;
            },
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: AppButtonStyles.primaryGradientDecoration(borderRadius: 12.r),
                    child: Center(
                      child: SizedBox(
                        height: 20.r,
                        width: 20.r,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  )
                : AppButtonStyles.primaryGradientButton(
                    text: localizations.reset_password_confirm_button,
                    onPressed: _resetPassword,
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
          // Resend code
          if (_remainingSeconds > 0)
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Text(
                  '$_remainingSeconds',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _sendEmail,
              child: Text(localizations.reset_password_resend_button),
            ),
        ],
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
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24.r,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
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
            body: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          localizations.reset_password_description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                            child: _step2 ? _buildStep2(localizations) : _buildStep1(localizations),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Column(
                          children: [
                            Text(
                              localizations.reset_password_remember,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
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
          ),
        ],
      ),
    );
  }
}
