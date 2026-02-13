import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E88E5), // Blue 600
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.notoSansTextTheme(),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
    ),
  );
}
