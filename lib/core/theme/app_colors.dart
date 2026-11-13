import 'package:flutter/material.dart';

abstract class AppColors {
  // Light
  static const lightBackground = Color(0xFFFAFAFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF0F1115);
  static const lightTextSecondary = Color(0xFF5A5A6A);
  static const lightHint = Color(0xFF9A9AB0);

  // Dark — matches original #1A1A2E navy
  static const darkBackground = Color(0xFF0F0F1E);
  static const darkSurface = Color(0xFF1A1A2E);
  static const darkCard = Color(0xFF1A1A2E);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFB8B8CC);
  static const darkHint = Color(0xFF8888A0);

  static const accent = Color.fromARGB(255, 104, 4, 210);
  static const accentSoft = Color(0xFFFFF0F3);
}
