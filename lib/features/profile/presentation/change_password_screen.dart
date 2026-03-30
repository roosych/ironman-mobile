import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../l10n/app_localizations.dart';
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

    // Simple call - errors will be handled by ref.listen
    await ref
        .read(changePasswordProvider.notifier)
        .changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          newPasswordConfirmation: _confirmPasswordController.text,
        );
  }


  Future<void> _showDeleteAccountDialog() async {
    final localizations = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      localizations.delete_account_confirm_title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22.sp,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 24.r,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Description
              Text(
                localizations.delete_account_confirm_description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 24.h),
              // Delete button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    textStyle: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(localizations.delete_account_confirm_button),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      // Implement actual delete account functionality
      debugPrint('Delete account confirmed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordProvider);
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Listen for state changes
    ref.listen(changePasswordProvider, (previous, next) {
      // Handle success message
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        ref.read(changePasswordProvider.notifier).clearSuccessMessage();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          AlertHelper.showSuccess(context, next.successMessage!).catchError((error) {
            debugPrint('Error showing success alert: $error');
          });
          // Clear form and navigate back after a short delay
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted && context.mounted) {
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              Navigator.of(context).pop();
            }
          });
        });
      }

      // Handle error message
      if (next.error != null && previous?.error != next.error) {
        String errorMessage = next.error!;
        if (errorMessage.toLowerCase().contains('current') ||
            errorMessage.toLowerCase().contains('incorrect') ||
            errorMessage.toLowerCase().contains('wrong') ||
            (errorMessage.toLowerCase().contains('password') &&
             errorMessage.toLowerCase().contains('invalid'))) {
          errorMessage = localizations.change_password_current_incorrect;
        }
        ref.read(changePasswordProvider.notifier).clearError();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          AlertHelper.showError(
            context,
            errorMessage,
            buttonText: localizations.error_ok,
          ).catchError((error) {
            debugPrint('Error showing error alert: $error');
          });
        });
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24.r,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            localizations.profile_security,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              // First Card - Change Password Section
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide.none,
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title
                        Text(
                          localizations.change_password_title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20.sp,
                              ),
                        ),
                        SizedBox(height: 20.h),

                        // Current password field
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrentPassword,
                          enabled: !state.isLoading,
                          decoration: InputDecoration(
                            labelText: localizations.change_password_current,
                            prefixIcon: HugeIcon(
                              icon: HugeIcons.strokeRoundedLockPassword,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              size: 20.r,
                            ),
                            suffixIcon: IconButton(
                              icon: HugeIcon(
                                icon: _obscureCurrentPassword
                                    ? HugeIcons.strokeRoundedView
                                    : HugeIcons.strokeRoundedViewOff,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                size: 20.r,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureCurrentPassword =
                                      !_obscureCurrentPassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations
                                  .change_password_current_required;
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),

                        // New password field
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          enabled: !state.isLoading,
                          decoration: InputDecoration(
                            labelText: localizations.change_password_new,
                            prefixIcon: HugeIcon(
                              icon: HugeIcons.strokeRoundedLockPassword,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              size: 20.r,
                            ),
                            suffixIcon: IconButton(
                              icon: HugeIcon(
                                icon: _obscureNewPassword
                                    ? HugeIcons.strokeRoundedView
                                    : HugeIcons.strokeRoundedViewOff,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                size: 20.r,
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
                              return localizations
                                  .change_password_same_as_current;
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),

                        // Confirm password field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          enabled: !state.isLoading,
                          decoration: InputDecoration(
                            labelText: localizations.change_password_confirm,
                            prefixIcon: HugeIcon(
                              icon: HugeIcons.strokeRoundedLockPassword,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              size: 20.r,
                            ),
                            suffixIcon: IconButton(
                              icon: HugeIcon(
                                icon: _obscureConfirmPassword
                                    ? HugeIcons.strokeRoundedView
                                    : HugeIcons.strokeRoundedViewOff,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                size: 20.r,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _changePassword(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations
                                  .change_password_confirm_required;
                            }
                            if (value != _newPasswordController.text) {
                              return localizations.change_password_mismatch;
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),

                        // Change password button
                        SizedBox(
                          width: double.infinity,
                          child: state.isLoading
                              ? Container(
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  decoration:
                                      AppButtonStyles.primaryGradientDecoration(
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
                                  text: localizations.change_password_button,
                                  onPressed: _changePassword,
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
              ),
              SizedBox(height: 16.h),

              // Second Card - Delete Account Section
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide.none,
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Warning text
                      Text(
                        localizations.delete_account_warning,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Delete account button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _showDeleteAccountDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            localizations.delete_account_button,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
