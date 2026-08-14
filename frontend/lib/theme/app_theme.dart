import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green,
        primary: AppColors.green,
        secondary: AppColors.amber,
        surface: AppColors.paper,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.ink),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.ink),
        titleMedium: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
        bodyMedium: TextStyle(color: AppColors.ink),
        bodySmall: TextStyle(color: AppColors.sub),
        labelSmall: TextStyle(color: AppColors.sub, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      dividerColor: AppColors.line,
      cardColor: AppColors.paper,
    );
  }
}
