import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Стили кнопок приложения
class AppButtonStyles {
  /// Основной градиентный стиль для кнопок и активных элементов
  static BoxDecoration primaryGradientDecoration({
    double borderRadius = 10,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryGradientStart,
          AppColors.primaryGradientEnd,
        ],
      ),
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: AppColors.primaryGradientShadow.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  /// Стиль кнопки с градиентом
  static Widget primaryGradientButton({
    required String text,
    required VoidCallback onPressed,
    double borderRadius = 10,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    TextStyle? textStyle,
    bool withShadow = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: primaryGradientDecoration(
            borderRadius: borderRadius,
            withShadow: withShadow,
          ),
          child: Text(
            text,
            style: textStyle ??
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Стиль для активного элемента таба или навигации
  static Color get activeElementColor => AppColors.primaryGradientEnd;

  /// Градиент для фона активных элементов
  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryGradientStart,
          AppColors.primaryGradientEnd,
        ],
      );

  /// Стиль для ElevatedButton с градиентом
  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );

  /// Wrapper для ElevatedButton с градиентным фоном
  static Widget gradientElevatedButton({
    required String text,
    required VoidCallback? onPressed,
    EdgeInsets? padding,
    double borderRadius = 10,
    TextStyle? textStyle,
  }) {
    return Container(
      decoration: onPressed != null
          ? primaryGradientDecoration(borderRadius: borderRadius)
          : BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: Colors.grey,
            ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          text,
          style: textStyle ??
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
        ),
      ),
    );
  }

  /// Стиль для OutlinedButton с градиентной рамкой
  static Widget gradientOutlinedButton({
    required String text,
    required VoidCallback? onPressed,
    required Widget icon,
    EdgeInsets? padding,
    double borderRadius = 10,
    TextStyle? textStyle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientShadow.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(2), // Thickness of gradient border
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius - 2),
          color: AppColors.ironmanBlack,
        ),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon,
          label: Text(text),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: BorderSide.none,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius - 2),
            ),
          ),
        ),
      ),
    );
  }
}