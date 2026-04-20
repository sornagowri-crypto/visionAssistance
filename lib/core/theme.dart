// ─────────────────────────────────────────────────────────────────────────────
// theme.dart — High-contrast accessible theme
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kColorBackground,

    // ── Color Scheme ──────────────────────────────────────────────────────────
    colorScheme: const ColorScheme.dark(
      background:   kColorBackground,
      surface:      kColorSurface,
      primary:      kColorPrimary,
      onPrimary:    Colors.black,
      secondary:    kColorAccent,
      onSecondary:  Colors.black,
      error:        kColorError,
      onError:      Colors.black,
      onBackground: kColorTextPrimary,
      onSurface:    kColorTextPrimary,
    ),

    // ── Typography ────────────────────────────────────────────────────────────
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: kFontSizeHero,
        fontWeight: FontWeight.w900,
        color: kColorTextPrimary,
        letterSpacing: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: kFontSizeTitle,
        fontWeight: FontWeight.w700,
        color: kColorTextPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: kFontSizeBody,
        fontWeight: FontWeight.w400,
        color: kColorTextPrimary,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: kFontSizeCaption,
        color: kColorTextSecondary,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: kFontSizeBody,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        letterSpacing: 1.5,
      ),
    ),

    // ── AppBar ────────────────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: kColorBackground,
      foregroundColor: kColorTextPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: kFontSizeTitle,
        fontWeight: FontWeight.w700,
        color: kColorPrimary,
        letterSpacing: 1.1,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    // ── Elevated Button ───────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kColorPrimary,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        textStyle: const TextStyle(
          fontSize: kFontSizeBody,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        elevation: 4,
      ),
    ),

    // ── OutlinedButton ────────────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kColorTextPrimary,
        minimumSize: const Size(double.infinity, 64),
        side: const BorderSide(color: kColorDivider, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        textStyle: const TextStyle(
          fontSize: kFontSizeCaption,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // ── Card ──────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: kColorCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        side: const BorderSide(color: kColorDivider, width: 1),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: kPadding,
        vertical: 8,
      ),
    ),

    // ── Divider ───────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: kColorDivider,
      thickness: 1,
    ),

    // ── SnackBar ──────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kColorCard,
      contentTextStyle: const TextStyle(
        color: kColorTextPrimary,
        fontSize: kFontSizeCaption,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Icon ──────────────────────────────────────────────────────────────────
    iconTheme: const IconThemeData(
      color: kColorTextPrimary,
      size: 28,
    ),
  );
}
