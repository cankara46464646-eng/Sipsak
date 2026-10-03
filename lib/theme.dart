import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Şipşak renkleri: koyu zemin, flaş sarısı vurgu, polaroid kâğıdı.
class C {
  static const ink = Color(0xFF0E0E10);
  static const surface = Color(0xFF1A1A1F);
  static const surface2 = Color(0xFF26262D);
  static const line = Color(0xFF34343C);
  static const text = Color(0xFFF4F1EA);
  static const muted = Color(0xFFA9A6A0);
  static const dim = Color(0xFF8E8A84);
  static const flash = Color(0xFFFFD23F);
  static const flashDeep = Color(0xFF3D3410);
  static const paper = Color(0xFFF7F4EE);
  static const paperInk = Color(0xFF2A2622);
  static const paperMuted = Color(0xFF5E5850);
  static const danger = Color(0xFFFF8A7A);
}

TextStyle _font(String family, TextStyle base) {
  try {
    return GoogleFonts.getFont(family, textStyle: base);
  } catch (_) {
    return base;
  }
}

/// Başlık yazı tipi (Bricolage Grotesque).
TextStyle display(double size, {Color color = C.text, FontWeight weight = FontWeight.w800, double height = 1.05, double spacing = -0.5}) {
  return _font(
    'Bricolage Grotesque',
    TextStyle(fontSize: size, color: color, fontWeight: weight, height: height, letterSpacing: spacing),
  );
}

/// Gövde yazı tipi (DM Sans).
TextStyle body(double size, {Color color = C.text, FontWeight weight = FontWeight.w400, double height = 1.35, double spacing = 0}) {
  return _font(
    'DM Sans',
    TextStyle(fontSize: size, color: color, fontWeight: weight, height: height, letterSpacing: spacing),
  );
}

/// Sayaçlar için sabit genişlikli yazı tipi (DM Mono).
TextStyle mono(double size, {Color color = C.text, FontWeight weight = FontWeight.w500, double spacing = 0}) {
  return _font(
    'DM Mono',
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: C.ink,
    colorScheme: const ColorScheme.dark(
      primary: C.flash,
      onPrimary: C.ink,
      secondary: C.flash,
      onSecondary: C.ink,
      surface: C.surface,
      onSurface: C.text,
      error: C.danger,
    ),
  );
  TextTheme textTheme;
  try {
    textTheme = GoogleFonts.getTextTheme('DM Sans', base.textTheme);
  } catch (_) {
    textTheme = base.textTheme;
  }
  return base.copyWith(
    textTheme: textTheme.apply(bodyColor: C.text, displayColor: C.text),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.surface2,
      contentTextStyle: body(14, weight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface,
      hintStyle: body(16, color: C.dim),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: C.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: C.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: C.flash, width: 2),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.flash),
  );
}
