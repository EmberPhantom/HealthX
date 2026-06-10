/// Theme Extensions
/// Additional theme utilities and helpers

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

/// Text style extensions
extension TextStyleExt on TextStyle {
  /// Apply app primary color
  TextStyle get primary {
    return copyWith(color: AppTheme.primaryGreen);
  }

  /// Apply secondary color
  TextStyle get secondary {
    return copyWith(color: Colors.grey[700]);
  }

  /// Apply error color
  TextStyle get error {
    return copyWith(color: AppTheme.red);
  }

  /// Apply hint color
  TextStyle get hint {
    return copyWith(color: Colors.grey[500]);
  }

  /// Make text bold
  TextStyle get bold {
    return copyWith(fontWeight: FontWeight.w700);
  }

  /// Make text semi-bold
  TextStyle get semiBold {
    return copyWith(fontWeight: FontWeight.w600);
  }

  /// Make text medium
  TextStyle get medium {
    return copyWith(fontWeight: FontWeight.w500);
  }

  /// Make text white
  TextStyle get white {
    return copyWith(color: Colors.white);
  }

  /// Apply line height
  TextStyle lineHeight(double height) {
    return copyWith(height: height);
  }

  /// Apply letter spacing
  TextStyle letterSpaced(double spacing) {
    return copyWith(letterSpacing: spacing);
  }
}

/// Color extensions
extension ColorExt on Color {
  /// Get color with custom opacity
  Color opacity(double value) {
    return withOpacity(value);
  }

  /// Lighten color
  Color lighten([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    final newLight = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLight).toColor();
  }

  /// Darken color
  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    final newLight = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLight).toColor();
  }
}

/// Border radius extensions
extension BorderRadiusExt on BorderRadius {
  /// Get circular border radius
  static BorderRadius circular(double radius) {
    return BorderRadius.circular(radius);
  }

  /// Get only top border radius
  static BorderRadius top(double radius) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
  }

  /// Get only bottom border radius
  static BorderRadius bottom(double radius) {
    return BorderRadius.only(
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
  }
}

/// Box decoration helpers
class AppDecorations {
  /// Standard card decoration
  static BoxDecoration card({
    double borderRadius = 12,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 1,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Input field decoration
  static BoxDecoration inputField({
    double borderRadius = 10,
    Color? fillColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: fillColor ?? Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.grey[300]!,
        width: 1,
      ),
    );
  }

  /// Gradient decoration
  static BoxDecoration gradient({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors: colors,
      ),
    );
  }

  /// Shadow decoration
  static BoxDecoration shadow({
    Color? backgroundColor,
    double blurRadius = 8,
    double spreadRadius = 0,
    Offset offset = const Offset(0, 2),
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
          offset: offset,
        ),
      ],
    );
  }
}

/// Common spacing utilities
class AppSpacing {
  // Single spacing unit (4 pixels)
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Common border radius
class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
}

/// Input decoration builder
InputDecoration buildInputDecoration({
  String? label,
  String? hint,
  IconData? prefixIcon,
  Widget? suffixIcon,
  double borderRadius = 10,
  Color? fillColor,
  TextStyle? labelStyle,
  TextStyle? hintStyle,
}) {
  return InputDecoration(
    label: label != null
        ? Text(label)
        : null,
    hintText: hint,
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: AppTheme.primaryGreen)
        : null,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: fillColor ?? Colors.white,
    labelStyle: labelStyle ?? GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.grey[700],
    ),
    hintStyle: hintStyle ?? GoogleFonts.inter(
      fontSize: 13,
      color: Colors.grey[500],
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 12,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(
        color: AppTheme.primaryGreen,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: AppTheme.red, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: AppTheme.red, width: 1.5),
    ),
  );
}
