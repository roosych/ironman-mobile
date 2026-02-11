import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../shared/utils/alert_helper.dart';
import '../../auth/application/auth_notifier.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../application/profile_selection_notifier.dart';

class ProfileSelectionScreen extends ConsumerStatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  ConsumerState<ProfileSelectionScreen> createState() =>
      _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState
    extends ConsumerState<ProfileSelectionScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  String? _validationError;

  // Регулярное выражение для валидации кода: ^[1-9A-HJ-NP-Za-hj-np-z]{6}$
  // Без 0, O, I, L
  static final RegExp _codePattern = RegExp(r'^[1-9A-HJ-NP-Za-hj-np-z]{6}$');

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.profile_selection_code_required;
    }

    // Приводим к верхнему регистру для проверки
    final upperValue = value.toUpperCase();

    if (upperValue.length != 6) {
      return AppLocalizations.of(context)!.profile_selection_code_length;
    }

    if (!_codePattern.hasMatch(upperValue)) {
      return AppLocalizations.of(context)!.profile_selection_code_invalid;
    }

    return null;
  }

  Future<void> _handleLinkProfile() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _validationError = _validateCode(_codeController.text);
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    final notifier = ref.read(profileSelectionProvider.notifier);
    // Захватываем localizations перед async операцией
    final localizations = AppLocalizations.of(context)!;

    // Приводим код к верхнему регистру
    final code = _codeController.text.toUpperCase();
    final updatedUser = await notifier.linkProfile(code);

    if (updatedUser != null && mounted) {
      // Очищаем поле ввода
      _codeController.clear();

      // Обновляем пользователя в authProvider и сохраняем в хранилище
      debugPrint('=== ProfileSelection: Updating user after link ===');
      debugPrint('Updated user ID: ${updatedUser.id}');
      debugPrint('Updated user profile: ${updatedUser.profile}');
      if (updatedUser.profile is Map<String, dynamic>) {
        final profile = updatedUser.profile as Map<String, dynamic>;
        debugPrint('Profile ID: ${profile['id']}');
      }

      await ref.read(authProvider.notifier).updateUser(updatedUser);

      // Показываем сообщение об успехе
      if (mounted) {
        AlertHelper.showSuccess(context, localizations.profile_selection_link_success);
      }

      // Перенаправляем на главный экран после успешного присоединения профиля
      // Используем глобальный navigatorKey для гарантированной навигации
      debugPrint(
        '=== ProfileSelection: Scheduling navigation to Dashboard ===',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('=== ProfileSelection: PostFrameCallback executed ===');
        final navigator = navigatorKey.currentState;
        debugPrint('Navigator state: ${navigator != null ? "EXISTS" : "NULL"}');
        if (navigator != null) {
          debugPrint('=== ProfileSelection: Navigating to Dashboard ===');
          try {
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (route) => false, // Удаляем все предыдущие маршруты
            );
            debugPrint('=== ProfileSelection: Navigation completed ===');
          } catch (e) {
            debugPrint('=== ProfileSelection: Navigation error: $e ===');
          }
        } else {
          debugPrint(
            '=== ProfileSelection: Navigator is NULL, cannot navigate ===',
          );
        }
      });
    } else if (mounted) {
      // Ошибка уже обработана в notifier, она будет показана в UI
    }
  }

  Future<void> _handleCreateProfile() async {
    final notifier = ref.read(profileSelectionProvider.notifier);
    // Захватываем localizations перед async операцией
    final localizations = AppLocalizations.of(context)!;
    final updatedUser = await notifier.createProfile(role: 'athlete');

    if (updatedUser != null && mounted) {
      // Обновляем пользователя в authProvider и сохраняем в хранилище
      debugPrint('=== ProfileSelection: Updating user after create ===');
      debugPrint('Updated user ID: ${updatedUser.id}');
      debugPrint('Updated user profile: ${updatedUser.profile}');
      if (updatedUser.profile is Map<String, dynamic>) {
        final profile = updatedUser.profile as Map<String, dynamic>;
        debugPrint('Profile ID: ${profile['id']}');
      }

      await ref.read(authProvider.notifier).updateUser(updatedUser);

      // Показываем сообщение об успехе
      if (mounted) {
        AlertHelper.showSuccess(context, localizations.profile_selection_create_success);
      }

      // Перенаправляем на главный экран после успешного создания профиля
      // Используем глобальный navigatorKey для гарантированной навигации
      debugPrint(
        '=== ProfileSelection: Scheduling navigation to Dashboard ===',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('=== ProfileSelection: PostFrameCallback executed ===');
        final navigator = navigatorKey.currentState;
        debugPrint('Navigator state: ${navigator != null ? "EXISTS" : "NULL"}');
        if (navigator != null) {
          debugPrint('=== ProfileSelection: Navigating to Dashboard ===');
          try {
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (route) => false, // Удаляем все предыдущие маршруты
            );
            debugPrint('=== ProfileSelection: Navigation completed ===');
          } catch (e) {
            debugPrint('=== ProfileSelection: Navigation error: $e ===');
          }
        } else {
          debugPrint(
            '=== ProfileSelection: Navigator is NULL, cannot navigate ===',
          );
        }
      });
    } else if (mounted) {
      // Ошибка уже обработана в notifier, она будет показана в UI
    }
  }

  void _handleLogout() {
    ref.read(authProvider.notifier).logout();
  }

  /// Получает локализованное сообщение об ошибке по ключу
  String _getLocalizedError(String? errorKey, AppLocalizations localizations) {
    if (errorKey == null) {
      return localizations.profile_selection_error_server;
    }

    // Проверяем, является ли ошибка ключом локализации
    switch (errorKey) {
      case 'profile_selection_error_code_not_found':
        return localizations.profile_selection_error_code_not_found;
      case 'profile_selection_error_code_already_used':
        return localizations.profile_selection_error_code_already_used;
      case 'profile_selection_error_code_already_linked':
        return localizations.profile_selection_error_code_already_linked;
      case 'profile_selection_error_profile_already_exists':
        return localizations.profile_selection_error_profile_already_exists;
      case 'profile_selection_error_network':
        return localizations.profile_selection_error_network;
      case 'profile_selection_error_server':
        return localizations.profile_selection_error_server;
      case 'profile_selection_error_already_linked':
        return localizations.profile_selection_error_already_linked;
      default:
        // Если это не ключ локализации, возвращаем как есть
        return errorKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSelectionProvider);
    final authState = ref.watch(authProvider);
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);


    return GestureDetector(
      onTap: () {
        // Скрываем клавиатуру при клике вне поля ввода
        FocusScope.of(context).unfocus();
      },
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              title: Text(
                localizations.profile_selection_title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: (state.isProcessing || authState.isLoading)
                      ? null
                      : _handleLogout,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedLogout01,
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  tooltip: localizations.profile_selection_logout,
                ),
              ],
            ),
            body: state.isProcessing
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Текст о вводе кода
                          Text(
                            localizations.profile_selection_code_text,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Поле ввода кода
                          TextFormField(
                            controller: _codeController,
                            focusNode: _codeFocusNode,
                            enabled: !state.isProcessing,
                            decoration: InputDecoration(
                              labelText:
                                  localizations.profile_selection_code_label,
                              hintText:
                                  localizations.profile_selection_code_hint,
                              suffixIcon: _codeController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _codeController.clear();
                                        _codeFocusNode.unfocus();
                                        setState(() {
                                          // Очищаем ошибку валидации при очистке поля
                                          _validationError = null;
                                        });
                                        // Очищаем ошибку из notifier при очистке поля
                                        ref
                                            .read(
                                              profileSelectionProvider.notifier,
                                            )
                                            .clearError();
                                      },
                                    )
                                  : null,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 6,
                            inputFormatters: [
                              // Разрешаем только допустимые символы (без 0, O, I, L)
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[1-9A-HJ-NP-Za-hj-np-z]'),
                              ),
                            ],
                            validator: _validateCode,
                            onChanged: (value) {
                              // Автоматически приводим к верхнему регистру
                              if (value.isNotEmpty) {
                                final upperValue = value.toUpperCase();
                                if (upperValue != value) {
                                  _codeController.value = TextEditingValue(
                                    text: upperValue,
                                    selection: TextSelection.collapsed(
                                      offset: upperValue.length,
                                    ),
                                  );
                                }
                              }
                              setState(() {
                                // Очищаем ошибку валидации при вводе символов
                                _validationError = null;
                              });
                              // Очищаем ошибку из notifier при вводе символов
                              ref
                                  .read(profileSelectionProvider.notifier)
                                  .clearError();
                              // Обновляем UI для показа/скрытия кнопки очистки и изменения цвета
                            },
                            onFieldSubmitted: (_) => _handleLinkProfile(),
                          ),
                          // Текст ошибки валидации или ошибки из notifier
                          if (_validationError != null ||
                              state.error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _validationError ??
                                  _getLocalizedError(
                                    state.error,
                                    localizations,
                                  ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Кнопка привязки профиля
                          FilledButton(
                            onPressed: state.isProcessing
                                ? null
                                : _handleLinkProfile,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 48),
                              backgroundColor: _codeController.text.length == 6
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.surfaceContainerHighest,
                              foregroundColor: _codeController.text.length == 6
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                              side: BorderSide(
                                color: _codeController.text.length == 6
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              localizations.profile_selection_link_button,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Разделитель
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  localizations.profile_selection_or,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Кнопка создания нового профиля
                          FilledButton(
                            onPressed: state.isProcessing
                                ? null
                                : _handleCreateProfile,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              localizations.profile_selection_create_new,
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
          // Overlay с лоадером при выходе
          if (authState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
