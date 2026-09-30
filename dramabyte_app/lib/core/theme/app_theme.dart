import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/core/constants/app_sizes.dart';
import 'package:dramabyte_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppTheme {
  static ThemeData get light => _theme(
    brightness: Brightness.light,
    background: AppColors.backgroundLight,
    surface: AppColors.surfaceLight,
    divider: AppColors.dividerLight,
  );

  static ThemeData get dark => _theme(
    brightness: Brightness.dark,
    background: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    divider: AppColors.dividerDark,
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color divider,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: surface,
      error: AppColors.error,
    );
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      dividerColor: divider,
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        headlineLarge: AppTextStyles.headlineLarge,
        titleLarge: AppTextStyles.titleLarge,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: background,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
