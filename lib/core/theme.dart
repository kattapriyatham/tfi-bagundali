import "package:flutter/material.dart";

abstract final class AppColors {
  static const ivory = Color(0xFFFAF7ED);
  static const sand = Color(0xFFEADCC8);
  static const charcoal = Color(0xFF1A1A1A);
  static const cinemaRed = Color(0xFFC63B2B);
  static const mustard = Color(0xFFF4C542);
  static const teal = Color(0xFF2E6F73);
}

ThemeData appTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.cinemaRed,
      primary: AppColors.cinemaRed,
      surface: AppColors.ivory,
    ),
    scaffoldBackgroundColor: AppColors.ivory,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.charcoal,
      displayColor: AppColors.charcoal,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.cinemaRed,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
