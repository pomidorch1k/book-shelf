import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/reader_settings.dart';

class AppColors {
  static const burntSienna = Color(0xFFE97451);
  static const powderBlue = Color(0xFFB0E0E6);
  static const burntSiennaDark = Color(0xFFC45F3A);
  static const powderBlueDark = Color(0xFF8FC4CC);
  static const white = Color(0xFFFFFFFF);
  static const darkBg = Color(0xFF1E1410);
  static const darkSurface = Color(0xFF2D221C);
  static const sepiaBg = Color(0xFFF5E6D3);
  static const sepiaText = Color(0xFF4A3728);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.burntSienna,
        onPrimary: AppColors.white,
        secondary: AppColors.powderBlue,
        onSecondary: AppColors.burntSienna,
        surface: AppColors.white,
        onSurface: AppColors.burntSiennaDark,
        tertiary: AppColors.burntSiennaDark,
      ),
      scaffoldBackgroundColor: AppColors.white,
      cardColor: AppColors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.burntSienna,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.burntSienna,
        foregroundColor: AppColors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.powderBlue,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.burntSienna : AppColors.burntSienna.withValues(alpha: 0.55),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.burntSienna, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.burntSienna,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.burntSiennaDark,
        displayColor: AppColors.burntSiennaDark,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.powderBlue,
        onPrimary: AppColors.darkBg,
        secondary: AppColors.burntSienna,
        onSecondary: AppColors.powderBlue,
        surface: AppColors.darkSurface,
        onSurface: AppColors.powderBlue,
        tertiary: AppColors.burntSienna,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.powderBlue,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.burntSienna,
        foregroundColor: AppColors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.burntSienna,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.powderBlue : AppColors.powderBlue.withValues(alpha: 0.6),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.powderBlue, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.burntSienna,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.powderBlue,
        displayColor: AppColors.powderBlue,
      ),
    );
  }

  static ReaderTheme readerTheme(ReaderSettings settings, bool appIsDark) {
    switch (settings.readerTheme) {
      case ReaderThemePreset.dark:
        return const ReaderTheme(
          background: AppColors.darkBg,
          text: AppColors.powderBlue,
          accent: AppColors.burntSienna,
        );
      case ReaderThemePreset.sepia:
        return const ReaderTheme(
          background: AppColors.white,
          text: Color(0xFF4A3728),
          accent: AppColors.burntSienna,
        );
      case ReaderThemePreset.light:
        return const ReaderTheme(
          background: AppColors.white,
          text: Color(0xFF2D2D2D),
          accent: AppColors.burntSienna,
        );
    }
  }
}

class ReaderTheme {
  const ReaderTheme({
    required this.background,
    required this.text,
    required this.accent,
  });

  final Color background;
  final Color text;
  final Color accent;
}
