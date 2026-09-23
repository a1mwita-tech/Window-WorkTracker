import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Apple Human Interface Guidelines-inspired palette:
/// system grays, accent blue, translucency-friendly surfaces.
class AppColors {
  static const accentBlue = Color(0xFF0A84FF);
  static const accentBlueLight = Color(0xFF007AFF);

  static const systemRed = Color(0xFFFF453A);
  static const systemYellow = Color(0xFFFFD60A);
  static const systemGreen = Color(0xFF32D74B);

  // Light mode system grays (Apple's gray scale)
  static const lightBg = Color(0xFFF2F2F7);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightGray1 = Color(0xFF8E8E93);
  static const lightGray5 = Color(0xFFE5E5EA);
  static const lightGray6 = Color(0xFFF2F2F7);
  static const lightSeparator = Color(0x33000000);
  static const lightLabel = Color(0xFF1C1C1E);
  static const lightSecondaryLabel = Color(0xFF6C6C70);

  // Dark mode
  static const darkBg = Color(0xFF000000);
  static const darkCard = Color(0xFF1C1C1E);
  static const darkGray1 = Color(0xFF8E8E93);
  static const darkGray5 = Color(0xFF2C2C2E);
  static const darkGray6 = Color(0xFF1C1C1E);
  static const darkSeparator = Color(0x33FFFFFF);
  static const darkLabel = Color(0xFFFFFFFF);
  static const darkSecondaryLabel = Color(0xFFAEAEB2);
}

class AppTheme {
  static bool get _isApple =>
      !kIsWeb && (Platform.isMacOS || Platform.isIOS);

  /// SF Pro is available as a private system font on Apple platforms
  /// without bundling (referenced via the '.SF Pro Text' family name).
  /// Everywhere else we fall back to Inter via google_fonts.
  static String? get _fontFamily => _isApple ? '.SF Pro Text' : null;

  static TextTheme _textTheme(Brightness brightness) {
    final base = _isApple
        ? Typography.blackCupertino
        : GoogleFonts.interTextTheme();
    final color =
        brightness == Brightness.dark ? AppColors.darkLabel : AppColors.lightLabel;
    return base.apply(
      fontFamily: _fontFamily,
      bodyColor: color,
      displayColor: color,
    );
  }

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final gray5 = isDark ? AppColors.darkGray5 : AppColors.lightGray5;
    final gray6 = isDark ? AppColors.darkGray6 : AppColors.lightGray6;
    final label = isDark ? AppColors.darkLabel : AppColors.lightLabel;
    final secondaryLabel =
        isDark ? AppColors.darkSecondaryLabel : AppColors.lightSecondaryLabel;
    final separator = isDark ? AppColors.darkSeparator : AppColors.lightSeparator;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accentBlue,
      onPrimary: Colors.white,
      secondary: AppColors.accentBlueLight,
      onSecondary: Colors.white,
      error: AppColors.systemRed,
      onError: Colors.white,
      surface: card,
      onSurface: label,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: colorScheme,
      textTheme: _textTheme(brightness),
      fontFamily: _fontFamily,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      dividerColor: separator,
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg.withValues(alpha: 0.72),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: label,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: label,
          letterSpacing: -0.4,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.accentBlue;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return label;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          side: BorderSide(color: separator),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: AppColors.accentBlue,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: gray6,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
        ),
        hintStyle: TextStyle(color: secondaryLabel),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: gray5,
        labelStyle: TextStyle(color: label, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
