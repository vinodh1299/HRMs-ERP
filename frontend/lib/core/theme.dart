import 'package:flutter/material.dart';

class AppTheme {
  // ── Core Brand Colors ───────────────────────────────────────────────────────
  static const Color primary     = Color(0xFF003471); // ACA Dark Blue
  static const Color primaryDark = Color(0xFF002254); // Deeper navy
  static const Color primaryMid  = Color(0xFF00438F); // Mid-blue
  static const Color secondary   = Color(0xFF00AEEF); // ACA Bright Blue
  static const Color secondaryLight = Color(0xFF33C1F5); // Lighter sky blue
  static const Color accent      = Color(0xFF981B1E); // ACA Cross Red
  static const Color accentLight = Color(0xFFC0292D); // Lighter red

  // ── Neutral Palette ─────────────────────────────────────────────────────────
  static const Color darkNeutral = Color(0xFF1F2937);
  static const Color bgLight     = Color(0xFFF0F4FB); // Blue-tinted page bg
  static const Color bgPage      = Color(0xFFEEF2F9); // Slightly deeper for contrast
  static const Color cardBg      = Colors.white;
  static const Color borderGrey  = Color(0xFFE2E8F0); // Slightly bluer grey
  static const Color borderLight = Color(0xFFEDF2F7);
  static const Color textDark    = Color(0xFF0F1729); // Richer dark text
  static const Color textBody    = Color(0xFF334155); // Body text
  static const Color textMuted   = Color(0xFF64748B); // Slate muted

  // ── Semantic Colors ──────────────────────────────────────────────────────────
  static const Color successGreen  = Color(0xFF059669);
  static const Color warningAmber  = Color(0xFFD97706);
  static const Color infoBlue      = Color(0xFF0284C7);
  static const Color errorRed      = Color(0xFFDC2626);

  // ── Sidebar Dark Theme ───────────────────────────────────────────────────────
  static const Color sidebarBg       = Color(0xFF001A3D); // Very deep navy
  static const Color sidebarBgLight  = Color(0xFF002459); // Panel bg
  static const Color sidebarText     = Color(0xFFCBD5E1); // Light slate
  static const Color sidebarMuted    = Color(0xFF64748B); // Muted in sidebar
  static const Color sidebarSelected = Color(0xFF00AEEF); // Bright blue highlight

  // ── Gradient Presets ────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryMid],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pageGradient = LinearGradient(
    colors: [Color(0xFFEEF2FB), Color(0xFFF5F8FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navGradient = LinearGradient(
    colors: [Color(0xFF001A3D), Color(0xFF002E6B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Box Shadow Presets ───────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primary.withOpacity(0.07),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: secondary.withOpacity(0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: primary.withOpacity(0.14),
      blurRadius: 28,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primary.withOpacity(0.30),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get accentButtonShadow => [
    BoxShadow(
      color: accent.withOpacity(0.30),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Decorations ─────────────────────────────────────────────────────────────
  static BoxDecoration glassDecoration({
    Color color = Colors.white,
    double opacity = 0.75,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: color.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.6),
        width: 1.5,
      ),
      boxShadow: cardShadow,
    );
  }

  static BoxDecoration cardDecoration({double radius = 16}) => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderGrey),
    boxShadow: cardShadow,
  );

  // ── Theme Data ───────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgLight,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        background: bgLight,
        surface: cardBg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      fontFamily: 'Inter',
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderGrey),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: borderGrey),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge:    TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18),
        titleMedium:   TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge:     TextStyle(color: textBody, fontSize: 15),
        bodyMedium:    TextStyle(color: textMuted, fontSize: 14),
      ),
    );
  }
}
