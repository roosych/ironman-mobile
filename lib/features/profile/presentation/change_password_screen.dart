import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/error_handler.dart';
import '../../../shared/utils/alert_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_button_styles.dart';
import '../application/change_password_notifier.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(changePasswordProvider.notifier).changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          newPasswordConfirmation: _confirmPasswordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordProvider);
    final localizations = AppLocalizations.of(context)!;

    // Listen for state changes
    ref.listen(changePasswordProvider, (previous, next) {
      // Show success message (already localized from API)
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        AlertHelper.showSuccess(context, next.successMessage!);
        ref.read(changePasswordProvider.notifier).clearSuccessMessage();
        // Clear form and navigate back
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        Navigator.of(context).pop();
      }
      // Show error message
      if (next.error != null && previous?.error != next.error) {
        ErrorHandler.showError(context, next.error ?? localizations.change_password_error);
        ref.read(changePasswordProvider.notifier).clearError();
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            localizations.change_password_title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current password field
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  enabled: !state.isLoading,
                  decoration: InputDecoration(
                    labelText: localizations.change_password_current,
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedLockPassword,
                      color: AppColors.ironmanWhite,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: HugeIcon(
                        icon: _obscureCurrentPassword
                            ? HugeIcons.strokeRoundedView
                            : HugeIcons.strokeRoundedViewOff,
                        color: AppColors.ironmanWhite,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.change_password_current_required;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // New password field
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  enabled: !state.isLoading,
                  decoration: InputDecoration(
                    labelText: localizations.change_password_new,
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedLockPassword,
                      color: AppColors.ironmanWhite,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: HugeIcon(
                        icon: _obscureNewPassword
                            ? HugeIcons.strokeRoundedView
                            : HugeIcons.strokeRoundedViewOff,
                        color: AppColors.ironmanWhite,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                    validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.change_password_new_required;
                    }
                    if (value.length < 8) {
                      return localizations.change_password_min_length;
                    }
                    // Check if new password differs from current
                    if (value == _currentPasswordController.text) {
                      return localizations.change_password_same_as_current;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  enabled: !state.isLoading,
                  decoration: InputDecoration(
                    labelText: localizations.change_password_confirm,
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedLockPassword,
                      color: AppColors.ironmanWhite,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: HugeIcon(
                        icon: _obscureConfirmPassword
                            ? HugeIcons.strokeRoundedView
                            : HugeIcons.strokeRoundedViewOff,
                        color: AppColors.ironmanWhite,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _changePassword(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.change_password_confirm_required;
                    }
                    if (value != _newPasswordController.text) {
                      return localizations.change_password_mismatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Change password button
                SizedBox(
                  width: double.infinity,
                  child: state.isLoading
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
                          text: localizations.change_password_button,
                          onPressed: _changePassword,
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
      ),
    );
  }
}

