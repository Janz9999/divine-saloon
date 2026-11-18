// lib/theme/app_text.dart
//
// The app's typography, shared by the customer, worker and manager screens.
//
//  • Inter            — all body / UI text (set app-wide in buildAppTheme).
//  • Playfair Display — headings: screen titles, section titles, names.
//
// Both fonts are bundled in assets/fonts (see pubspec.yaml), so they work
// offline and look identical on iOS and Android.
//
// Usage:
//   • Normal text needs nothing — it picks up Inter from the theme.
//   • A heading:            style: heading(24)
//   • Inside a const style: TextStyle(fontFamily: AppFonts.heading, ...)
//   • Button `textStyle:`   must set fontFamily: AppFonts.body itself, because
//     Flutter uses a button's textStyle as-is instead of inheriting the theme.

import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const String body = 'Inter';
  static const String heading = 'Playfair Display';
}

/// Heading text (Playfair Display), the style used on the profile screens.
TextStyle heading(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w400,
  double height = 1.2,
}) => TextStyle(
  fontFamily: AppFonts.heading,
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);

/// Material text theme: Playfair Display for display / headline styles,
/// Inter for everything else (titles, body, labels, buttons).
TextTheme buildAppTextTheme(TextTheme base, Color textColor) {
  TextStyle? serif(TextStyle? s) =>
      s?.copyWith(fontFamily: AppFonts.heading, fontWeight: FontWeight.w400);

  final themed = base.apply(
    fontFamily: AppFonts.body,
    bodyColor: textColor,
    displayColor: textColor,
  );
  return themed.copyWith(
    displayLarge: serif(themed.displayLarge),
    displayMedium: serif(themed.displayMedium),
    displaySmall: serif(themed.displaySmall),
    headlineLarge: serif(themed.headlineLarge),
    headlineMedium: serif(themed.headlineMedium),
    headlineSmall: serif(themed.headlineSmall),
  );
}
