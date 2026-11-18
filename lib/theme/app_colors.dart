// lib/theme/app_colors.dart
//
// The one place for the app's colours. Change a value here and every
// customer screen follows.

import 'app_text.dart';

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Primary background — pure white.
  static const Color bg = Color(0xFFFFFFFF);

  /// Cards / containers — off-white.
  static const Color surface = Color(0xFFFAFAFA);

  /// Primary text & icons — deep black.
  static const Color text = Color(0xFF000000);

  /// Secondary text — muted grey.
  static const Color muted = Color(0xFF8E8E8E);

  /// Dividers & borders — subtle light grey.
  static const Color border = Color(0xFFDBDBDB);

  /// Accent / primary action. Swap for [gold] to get the salon-gold look.
  static const Color accent = blue;
  static const Color blue = Color(0xFF0095F6);
  static const Color gold = Color(0xFFC5A059);

  /// Very light tint of the accent, for selected chips / info boxes.
  static const Color accentSoft = Color(
    0xFFE6F4FE,
  ); // ~10% accent on white — update with accent

  /// Errors / destructive actions.
  static const Color danger = Color(0xFFED4956);
}

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        surface: AppColors.bg,
        onSurface: AppColors.text,
        outline: AppColors.border,
        outlineVariant: AppColors.border,
        error: AppColors.danger,
      );

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.border),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily:
        AppFonts.body, // Inter everywhere; headings use AppFonts.heading
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    dividerColor: AppColors.border,
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(color: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    textTheme: buildAppTextTheme(ThemeData.light().textTheme, AppColors.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.muted),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.text,
      contentTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        color: Colors.white,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.accent
            : AppColors.border,
      ),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
