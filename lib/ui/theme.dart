import 'package:flutter/material.dart';

/// Токены оформления: тёмный ретро-стиль — синий пластик и латунные фишки.
class AppPalette {
  const AppPalette._();

  static const Color background = Color(0xFF16233C);
  static const Color surface = Color(0xFF1B2A47);
  static const Color surfaceHigh = Color(0xFF243656);

  /// Латунный акцент.
  static const Color accent = Color(0xFFE8B84B);
  static const Color onAccent = Color(0xFF16233C);

  static const Color text = Color(0xFFFFF3D6);
  static const Color textSoft = Color(0xB3E8F0FF);
  static const Color chipFill = Color(0x22000000);
  static const Color chipBorder = Color(0x33E8B84B);
  static const Color buttonFill = Color(0x1AE8B84B);
  static const Color disabled = Color(0x55E8F0FF);

  /// Пластина поля.
  static const Color plateTop = Color(0xFF2B5D8A);
  static const Color plateBottom = Color(0xFF14344F);
  static const Color plateEdge = Color(0xFF0E2640);
  static const Color socket = Color(0xFF0C2038);
  static const Color socketRim = Color(0x3FFFFFFF);

  /// Фишки-«гвоздики» (латунь).
  static const Color pegLight = Color(0xFFFFFAE0);
  static const Color pegMain = Color(0xFFEFD493);
  static const Color pegDeep = Color(0xFFC49A45);
  static const Color pegRim = Color(0xFF8E6717);
  static const Color pegShadow = Color(0x66000000);

  /// Подсветка ходов.
  static const Color highlight = Color(0xFF6FD8A6);
  static const Color highlightSoft = Color(0x806FD8A6);
  static const Color capture = Color(0xFFFF8A6B);
  static const Color hint = Color(0xFF7CC4FF);

  static ThemeData theme() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6),
        labelLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.4),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: surface),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: chipBorder),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) =>
              s.contains(WidgetState.selected) ? accent : textSoft,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) =>
              s.contains(WidgetState.selected) ? chipBorder : chipFill,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
