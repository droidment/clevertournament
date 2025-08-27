import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: Color(0xFF7CC6FE),
            secondary: Color(0xFFBDE0FE),
            surface: Color(0xFF101418),
            surfaceContainerHighest: Color(0xFF161B20),
          )
        : const ColorScheme.light(
            primary: Color(0xFF0066CC),
            secondary: Color(0xFF5DB8FF),
            surface: Color(0xFFF7F9FC),
            surfaceContainerHighest: Color(0xFFFFFFFF),
          );

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardTheme(
        shape: roundedShape,
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: roundedShape,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: roundedShape,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: roundedShape,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: roundedShape,
      ),
    );
  }
}

