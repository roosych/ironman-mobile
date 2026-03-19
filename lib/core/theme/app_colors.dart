import 'package:flutter/material.dart';

/// Цветовая палитра приложения (LIGHT + RED)
class AppColors {
  // 🔴 Акцент (было зелёным)
  static const Color ironmanRed = Color(0xFFE53935);

  // ⚪ Фоны (инверсия)
  static const Color ironmanBlack = Color(0xFFF5F5F5); // основной фон
  static const Color ironmanDarkGray = Color(0xFFFFFFFF); // карточки
  static const Color ironmanGray = Color(0xFFE0E0E0); // разделители
  static const Color ironmanLightGray = Color(0xFFCCCCCC); // бордеры

  // 📝 Текст
  static const Color ironmanWhite = Color(0xFF111111); // основной текст
  static const Color ironmanTextSecondary = Color(0xFF777777);

  // 🌈 Градиенты (красные)
  static const Color primaryGradientStart = Color(0xFFFF6F61);
  static const Color primaryGradientEnd = Color(0xFFE53935);
  static const Color primaryGradientShadow = Color(0xFFB71C1C);

  // 📦 Дополнительные
  static const Color resultsBackground = Color(0xFFFFFFFF);
  static const Color resultsBorder = Color(0xFFE0E0E0);

  static const Color resultsTextPrimary = Color(0xFF111111);
  static const Color resultsTextSecondary = Color(0xFF777777);
}