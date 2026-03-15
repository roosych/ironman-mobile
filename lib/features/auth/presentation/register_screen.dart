import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:country_flags/country_flags.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/utils/alert_helper.dart';
import 'package:ironman_mobile/shared/data/countries.dart';
import 'package:ironman_mobile/shared/widgets/language_selector.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/core/theme/app_button_styles.dart';
import '../application/auth_notifier.dart';
import '../application/auth_state.dart';
import '../../policies/presentation/policy_screen.dart';

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
  Country? _selectedCountry;
  String? _countryError; // Ошибка валидации для поля страны
  bool _privacyPolicyAccepted = false; // Privacy policy checkbox state
  String? _lastShownError; // Защита от дублирования диалогов ошибок

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
    final localizations = AppLocalizations.of(context)!;

    // Очищаем предыдущие ошибки в начале валидации
    _lastShownError = null;

    // Проверяем все поля сразу, чтобы показать все ошибки одновременно
    bool hasErrors = false;

    // Проверяем, что страна выбрана
    if (_selectedCountry == null) {
      setState(() {
        _countryError = localizations.register_select_country;
      });
      hasErrors = true;
    } else {
      setState(() {
        _countryError = null;
      });
    }

    // Проверяем, что пользователь согласился с политикой конфиденциальности
    if (!_privacyPolicyAccepted) {
      final errorMessage = localizations.register_privacy_policy_required;
      // Проверяем, что эта ошибка еще не показывалась
      if (_lastShownError != errorMessage) {
        debugPrint('🚨 Register: Showing policy error: $errorMessage');
        _lastShownError = errorMessage;
        ErrorHandler.showError(context, errorMessage);
      }
      hasErrors = true;
    }

    // Проверяем стандартные поля формы
    if (!_formKey.currentState!.validate()) {
      hasErrors = true;
    }

    // Если есть ошибки, прекращаем выполнение
    if (hasErrors) return;

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
      debugPrint('🌍 Registration: Sending country code: ${_selectedCountry?.isoCode}');
      debugPrint('🌍 Registration: Selected country: ${_selectedCountry?.name}');

      ref
          .read(authProvider.notifier)
          .register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            passwordConfirmation: _confirmPasswordController.text,
            countryCode: _selectedCountry?.isoCode,
          );
    });
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showCountrySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountrySelector(
        onCountrySelected: (country) {
          setState(() {
            _selectedCountry = country;
            _countryError = null; // Очищаем ошибку при выборе страны
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final localizations = AppLocalizations.of(context)!;

    ref.listen<AuthState>(authProvider, (previous, next) {
      // Show error
      if (next.error != null &&
          next.error != previous?.error &&
          next.error != _lastShownError) {
        _lastShownError = next.error;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ErrorHandler.showError(context, next.error!);
        });
      }

      // Сбрасываем запомненную ошибку при успешном состоянии
      if (next.error == null) {
        _lastShownError = null;
      }

      // Show warning (informational message from server)
      if (next.warning != null && next.warning != previous?.warning) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          AlertHelper.showInfo(context, next.warning!);
        });
      }

      // Check if registration was successful
      if (previous?.isLoading == true &&
          next.isLoading == false &&
          next.error == null &&
          !next.isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _registrationSuccess = true;
          });
        });
      }
    });

    if (_registrationSuccess) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 120.r,
                      height: 120.r,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        size: 64.r,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    localizations.register_thank_you,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    localizations.register_success_message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: const Icon(Icons.mark_email_unread_outlined, color: Colors.amber, size: 18),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            localizations.register_confirm_email,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 48.h),
                  FilledButton(
                    onPressed: _goToLogin,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      localizations.register_success_sign_in,
                      style: TextStyle(
                        fontSize: 16.sp,
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
              onPressed: () => Navigator.of(context).pop(),
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
                        localizations.register_title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                                    size: 20.r,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return localizations.register_name_required;
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16.h),
                              // Country selector
                              GestureDetector(
                                onTap: authState.isLoading ? null : _showCountrySelector,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: localizations.register_select_country,
                                    errorText: _countryError,
                                    prefixIcon: HugeIcon(
                                      icon: HugeIcons.strokeRoundedLocation01,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      size: 20.r,
                                    ),
                                    suffixIcon: Icon(
                                      Icons.arrow_drop_down,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    enabled: !authState.isLoading,
                                  ),
                                  isEmpty: _selectedCountry == null,
                                  child: _selectedCountry != null
                                      ? SizedBox(
                                          height: 24.h,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(2.r),
                                                child: CountryFlag.fromCountryCode(
                                                  _selectedCountry!.isoCode,
                                                  height: 16,
                                                  width: 24,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: Text(
                                                  _selectedCountry!.name,
                                                  style: Theme.of(context).textTheme.bodyLarge,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : SizedBox(height: 24.h),
                                ),
                              ),
                              SizedBox(height: 16.h),
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    size: 20.r,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: HugeIcon(
                                      icon: _obscurePassword
                                          ? HugeIcons.strokeRoundedView
                                          : HugeIcons.strokeRoundedViewOff,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
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
                              SizedBox(height: 16.h),
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
                                    size: 20.r,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: HugeIcon(
                                      icon: _obscureConfirmPassword
                                          ? HugeIcons.strokeRoundedView
                                          : HugeIcons.strokeRoundedViewOff,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      size: 20.r,
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
                              SizedBox(height: 16.h),
                              // Privacy Policy Checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    value: _privacyPolicyAccepted,
                                    onChanged: authState.isLoading ? null : (value) {
                                      setState(() {
                                        _privacyPolicyAccepted = value ?? false;
                                      });
                                    },
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        children: [
                                          TextSpan(
                                            text: localizations.register_privacy_policy_agree,
                                          ),
                                          WidgetSpan(
                                            child: GestureDetector(
                                              onTap: authState.isLoading ? null : () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => const PolicyScreen(
                                                      initialType: 'privacy',
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                localizations.register_privacy_policy_link,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: AppColors.ironmanRed,
                                                  decoration: TextDecoration.underline,
                                                  decorationColor: AppColors.ironmanRed,
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
                              SizedBox(height: 24.h),
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
                                        text: localizations.register_button,
                                        onPressed: _register,
                                        borderRadius: 12.r,
                                        padding: EdgeInsets.symmetric(vertical: 16.h),
                                        textStyle: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Column(
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
      ),
    );
  }
}

class _CountrySelector extends StatefulWidget {
  final Function(Country) onCountrySelected;

  const _CountrySelector({
    required this.onCountrySelected,
  });

  @override
  State<_CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<_CountrySelector> {
  final _searchController = TextEditingController();
  List<Country> _filteredCountries = Countries.all;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Set new timer with 300ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.toLowerCase().trim();
      if (mounted) {
        setState(() {
          if (query.isEmpty) {
            _filteredCountries = Countries.all;
          } else {
            _filteredCountries = Countries.all
                .where((country) => country.name.toLowerCase().contains(query))
                .toList();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      height: 0.8.sh,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        border: Border.all(
          color: AppColors.ironmanGray,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.register_select_country,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                  ),
                ),
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 20.r,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: localizations.register_search_countries,
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      size: 20.r,
                      color: AppColors.ironmanTextSecondary,
                    ),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              size: 16.r,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16.h),
          // Countries list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemExtent: 72.h,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: CountryFlag.fromCountryCode(
                      country.isoCode,
                      height: 24,
                      width: 32,
                    ),
                  ),
                  title: Text(country.name),
                  onTap: () {
                    widget.onCountrySelected(country);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
