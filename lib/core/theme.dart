// // lib/core/theme.dart

 import 'package:flutter/material.dart';


class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'PlusJakartaSans',

    scaffoldBackgroundColor: const Color(0xFF0F131F),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFBEC2FF),
      secondary: Color(0xFFC2C1FF),

      surface: Color(0xFF1B1F2C),
      onSurface: Color(0xFFDFE2F3),

      onPrimary: Color(0xFF181E8B),
    ),
  );
}