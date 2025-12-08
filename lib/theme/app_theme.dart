import 'package:flutter/material.dart';
import 'custom_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        surface: const Color(0xFFF3F1F1),
        onSurface: const Color(0xFF000000),
        surfaceContainerHighest: const Color(0xFFE7E0EC),
        brightness: Brightness.light,
      ),
      extensions: const <ThemeExtension<dynamic>>[customColorsLight],
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        surface: const Color(0xFF1E1E1E),
        onSurface: const Color(0xFFFFFFFF),
        surfaceContainerHighest: const Color(0xFF2C2C2C),
        brightness: Brightness.dark,
      ),
      extensions: const <ThemeExtension<dynamic>>[customColorsDark],
    );
  }
}
