import 'package:flutter/material.dart';
import 'package:fmf_design_system/src/tokens/fmf_colors.dart';
import 'package:fmf_design_system/src/tokens/fmf_typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: FmfColors.brandAccent,
      brightness: Brightness.light,
      primary: FmfColors.brandPrimary,
      secondary: FmfColors.brandAccent,
      surface: FmfColors.brandSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: FmfTypography.textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: const CardThemeData(elevation: 0),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
        ),
      ),
    );
  }

  // TODO: Implement full dark theme tokens in next design iteration
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: FmfColors.brandAccent,
        brightness: Brightness.dark,
        primary: FmfColors.brandAccent,
      ),
      textTheme: FmfTypography.textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
