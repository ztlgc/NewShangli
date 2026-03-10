import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandSecondary,
        surface: AppColors.surfaceCard,
        error: AppColors.stateDanger,
        onPrimary: AppColors.textInverse,
        onSecondary: AppColors.textInverse,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textInverse,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surfaceApp,
      textTheme: base.textTheme.apply(
        fontFamily: AppTypography.primaryFontFamily,
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.indigo500,
        secondary: AppColors.indigo600,
        surface: AppColors.gray800,
        error: AppColors.stateDanger,
        onPrimary: AppColors.textInverse,
        onSecondary: AppColors.textInverse,
        onSurface: AppColors.gray100,
        onError: AppColors.textInverse,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.gray900,
      textTheme: base.textTheme.apply(
        fontFamily: AppTypography.primaryFontFamily,
        bodyColor: AppColors.gray100,
        displayColor: AppColors.gray100,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
  }
}

