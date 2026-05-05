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
      extensions: const <ThemeExtension<dynamic>>[AppThemeColors.light],
      textTheme: base.textTheme.apply(
        fontFamily: AppTypography.primaryFontFamily,
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      dividerColor: AppColors.borderDivider,
      cardColor: AppColors.surfaceCard,
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppColors.gray300,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
      ),
      inputDecorationTheme: const InputDecorationThemeData(
        hintStyle: TextStyle(color: AppColors.textMuted),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.brandSecondary,
        selectionColor: AppColors.indigo100,
        selectionHandleColor: AppColors.brandSecondary,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.gray900,
        contentTextStyle: TextStyle(color: AppColors.white),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.gray500;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.brandSecondary
              : AppColors.gray200;
        }),
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
        secondary: Color(0xFF818CF8),
        surface: Color(0xFF171B22),
        error: AppColors.stateDanger,
        onPrimary: AppColors.textInverse,
        onSecondary: AppColors.textInverse,
        onSurface: Color(0xFFF9FAFB),
        onError: AppColors.textInverse,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppThemeColors.dark.surfaceApp,
      extensions: const <ThemeExtension<dynamic>>[AppThemeColors.dark],
      textTheme: base.textTheme.apply(
        fontFamily: AppTypography.primaryFontFamily,
        bodyColor: AppThemeColors.dark.textPrimary,
        displayColor: AppThemeColors.dark.textPrimary,
      ),
      iconTheme: IconThemeData(color: AppThemeColors.dark.textSecondary),
      dividerColor: AppThemeColors.dark.borderDivider,
      cardColor: AppThemeColors.dark.surfaceCard,
      dialogTheme: DialogThemeData(
        backgroundColor: AppThemeColors.dark.surfaceCard,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppThemeColors.dark.surfaceCard,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppThemeColors.dark.borderDefault,
      ),
      listTileTheme: ListTileThemeData(
        textColor: AppThemeColors.dark.textPrimary,
        iconColor: AppThemeColors.dark.textSecondary,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        hintStyle: TextStyle(color: AppThemeColors.dark.textMuted),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppThemeColors.dark.brandSecondary,
        selectionColor: AppThemeColors.dark.brandSoft,
        selectionHandleColor: AppThemeColors.dark.brandSecondary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppThemeColors.dark.surfaceSubtle,
        contentTextStyle: TextStyle(color: AppThemeColors.dark.textPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppThemeColors.dark.textInverse
              : AppThemeColors.dark.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppThemeColors.dark.brandPrimary
              : AppThemeColors.dark.surfaceDisabled;
        }),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
  }
}
