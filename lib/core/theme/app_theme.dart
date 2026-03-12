import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(useMaterial3: true);
    final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppPalette.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.primary,
        surface: Colors.white,
      ),
      textTheme: textTheme,
    );
  }
}
