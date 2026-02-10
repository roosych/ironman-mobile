import 'package:flutter/material.dart';

/// Цветовая палитра приложения
class AppColors {
  // Основные цвета Ironman
  static const Color ironmanRed = Color.fromARGB(255, 35, 129, 201);
  static const Color ironmanBlack = Color(0xFF0e0f10);
  static const Color ironmanDarkGray = Color(0xFF141516);
  static const Color ironmanGray = Color(0xFF18191b);
  static const Color ironmanLightGray = Color(0xFF3A3A3A);
  static const Color ironmanWhite = Color(0xFFFFFFFF);
  static const Color ironmanTextSecondary = Color(0xFFB0B0B0);

  // Градиентные цвета для активных элементов и кнопок
  static const Color primaryGradientStart = Color(0xFF5BA3F8);
  static const Color primaryGradientEnd = Color(0xFF2E6FCC);
  static const Color primaryGradientShadow = Color(0xFF2E6FCC);

  // Дополнительные цвета
  static const Color resultsBackground = Color(0xFFEEEEEC);
  static const Color resultsBorder = Color(0xFF2A2A2A); // ironmanGray для рамок
  static const Color resultsTextPrimary = Color(
    0xFF0D0D0D,
  ); // ironmanBlack для основного текста
  static const Color resultsTextSecondary = Color(
    0xFF6A6A6A,
  ); // Мягкий серый для даты/локации
}
