import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Design reference size for fixed-size / scaled UIs
  static const double designWidth = 390.0;
  static const double designHeight = 844.0;

  // === Primary Colors ===
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color darkGreen = Color(0xFF059669);
  static const Color lightGreen = Color(0xFFD1FAE5);
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color forestGreen = Color(0xFF228B22);
  static const Color terracotta = Color(0xFFE2725B);

  // === Accent Colors ===
  static const Color darkBlue = Color(0xFF1E3A8A);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color orange = Color(0xFFF97316);
  static const Color yellow = Color(0xFFFBBF24);
  static const Color red = Color(0xFFEF4444);

  // === Stat Card Colors ===
  static const Color stepsYellow = Color(0xFFFEF3C7);
  static const Color caloriesOrange = Color(0xFFFED7AA);
  static const Color sleepBlue = Color(0xFFDBEAFE);
  static const Color waterCyan = Color(0xFFCFFAFE);

  // === Grayscale ===
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMedium = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color bgLight = Color(0xFFF9FAFB);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color lightGrey = Color(0xFFD3D3D3);
  static const Color mediumGrey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF4A4A4A); // Add this line
  static const Color lightBeige = Color(0xFFF5F5DC); // Add this line

  // === Spacing ===
  static const double paddingLarge = 24.0;
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;

  // === Borders ===
  static const Color border = divider;

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: darkGreen,
        surface: bgCard,
        error: red,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: textDark,
          fontWeight: FontWeight.w700,
          fontSize: 26,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: textDark,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          color: textDark,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: textDark,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: textDark,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: textDark,
          fontSize: 15,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: textMedium,
          fontSize: 13,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: textLight,
          fontSize: 12,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: textDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.inter(
          color: textLight,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
      ),
    );
  }

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: bgCard,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ],
  );

  static BoxDecoration cardDecorationWithColor(Color color) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  // === Text Styles ===
  static TextStyle get headline => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textDark,
  );

  static TextStyle get subtitle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textMedium,
  );

  static TextStyle get bodyText => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textDark,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textMedium,
  );

  static TextStyle get button => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

// --- small helper: Color.withValues(alpha: 0.5) as used by UI code ---
extension ColorHelpers on Color {
  /// Helper used across the project: .withValues(alpha: 0.5) -> withOpacity(0.5)
  Color withValues({double alpha = 1}) => withOpacity(alpha);
}