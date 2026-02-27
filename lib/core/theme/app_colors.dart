import 'package:flutter/material.dart';

/// Цветовая палитра приложения
class AppColors {
  // Основные цвета Ironman
  static const Color ironmanRed = Color(0xFF2E7D32); // насыщенный зелёный акцент
  static const Color ironmanBlack = Color(0xFF0e0f10);
  static const Color ironmanDarkGray = Color(0xFF1A1A1A); // тёмный фон
  static const Color ironmanGray = Color(0xFF2C2C2C);     // средний серый
  static const Color ironmanLightGray = Color(0xFF555555); // светлый серый
  static const Color ironmanWhite = Color(0xFFFFFFFF);
  static const Color ironmanTextSecondary = Color(0xFFAAAAAA); // второстепенный текст

  // Градиентные цвета для активных элементов и кнопок
  static const Color primaryGradientStart = Color(0xFF4CAF50); // светлый зелёный
  static const Color primaryGradientEnd = Color(0xFF2E7D32);   // основной насыщенный зелёный
  static const Color primaryGradientShadow = Color(0xFF1B4D1B); // тёмная тень для глубины

  // Дополнительные цвета
  static const Color resultsBackground = Color(0xFF2C2C2C); // тёмный фон карточек
  static const Color resultsBorder = Color(0xFF3A3A3A);     // рамки
  static const Color resultsTextPrimary = Color(0xFFFFFFFF);
  static const Color resultsTextSecondary = Color(0xFFAAAAAA); // второстепенный текст
}