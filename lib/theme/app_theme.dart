import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const midnightBlue = Color(0xFF191970);
  static const peach = Color(0xFFFFE5B4);
  static const midnightBlueLight = Color(0xFF2A2A9E);
  static const peachDark = Color(0xFFE8C990);
  static const white = Color(0xFFFFFFFF);
  static const darkBg = Color(0xFF0D0D2B);
  static const darkSurface = Color(0xFF151540);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.midnightBlue,
        onPrimary: AppColors.peach,
        secondary: AppColors.peach,
        onSecondary: AppColors.midnightBlue,
        surface: AppColors.white,
        onSurface: AppColors.midnightBlue,
        tertiary: AppColors.midnightBlueLight,
      ),
      scaffoldBackgroundColor: AppColors.peach.withValues(alpha: 0.35),
      cardColor: AppColors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.midnightBlue,
        foregroundColor: AppColors.peach,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.midnightBlue,
        foregroundColor: AppColors.peach,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.peach,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.midnightBlue : AppColors.midnightBlue.withValues(alpha: 0.6),
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
          borderSide: const BorderSide(color: AppColors.midnightBlue, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.midnightBlue,
          foregroundColor: AppColors.peach,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.midnightBlue,
        displayColor: AppColors.midnightBlue,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.peach,
        onPrimary: AppColors.midnightBlue,
        secondary: AppColors.midnightBlueLight,
        onSecondary: AppColors.peach,
        surface: AppColors.darkSurface,
        onSurface: AppColors.peach,
        tertiary: AppColors.peachDark,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.peach,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.peach,
        foregroundColor: AppColors.midnightBlue,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.midnightBlue,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.peach : AppColors.peach.withValues(alpha: 0.6),
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
          borderSide: const BorderSide(color: AppColors.peach, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.peach,
          foregroundColor: AppColors.midnightBlue,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.peach,
        displayColor: AppColors.peach,
      ),
    );
  }

  static ReaderTheme readerTheme(bool isDark) {
    return isDark
        ? const ReaderTheme(
            background: AppColors.darkBg,
            text: AppColors.peach,
            accent: AppColors.midnightBlueLight,
          )
        : const ReaderTheme(
            background: Color(0xFFFFF8E8),
            text: AppColors.midnightBlue,
            accent: AppColors.midnightBlue,
          );
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
