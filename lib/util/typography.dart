import 'package:flutter/material.dart';

/// Shared text faces. The fallback asset contains Cyrillic code points only.
/// Icon fonts are intentionally independent from application typography.
abstract final class MiliTypography {
  static const bodyFamily = 'Noto Sans Georgian';
  static const capsFamily = bodyFamily;
  static const fallback = ['MILI Cyrillic'];

  static const regular = TextStyle(
    fontFamily: bodyFamily,
    fontFamilyFallback: fallback,
    fontWeight: FontWeight.w400,
  );
  static const bold = TextStyle(
    fontFamily: bodyFamily,
    fontFamilyFallback: fallback,
    fontWeight: FontWeight.w700,
  );
  static const italic = TextStyle(
    fontFamily: bodyFamily,
    fontFamilyFallback: fallback,
    fontStyle: FontStyle.italic,
  );
  static const heading = TextStyle(
    fontFamily: capsFamily,
    fontFamilyFallback: fallback,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
  );

  // Long names, form labels, prices and navigation retain regular letterforms.
  static const textTheme = TextTheme(
    displayLarge: heading,
    displayMedium: heading,
    displaySmall: heading,
    headlineLarge: heading,
    headlineMedium: heading,
    headlineSmall: heading,
    titleLarge: bold,
    titleMedium: bold,
    titleSmall: bold,
    bodyLarge: regular,
    bodyMedium: regular,
    bodySmall: regular,
    labelLarge: bold,
    labelMedium: regular,
    labelSmall: regular,
  );
}
