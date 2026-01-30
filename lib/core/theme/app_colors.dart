import 'package:flutter/material.dart';

/// Цветовая палитра приложения
class AppColors {
  // Основные цвета Ironman
  static const Color ironmanRed = Color(0xFFE31837);
  static const Color ironmanBlack = Color(0xFF0D0D0D);
  static const Color ironmanDarkGray = Color(0xFF1A1A1A);
  static const Color ironmanGray = Color(0xFF2A2A2A);
  static const Color ironmanLightGray = Color(0xFF3A3A3A);
  static const Color ironmanWhite = Color(0xFFFFFFFF);
  static const Color ironmanTextSecondary = Color(0xFFB0B0B0);

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
