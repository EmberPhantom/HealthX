import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFD4FF00); // Neon Lime
  static const Color secondary = Color(0xFF121212); // Off-Black
  static const Color tertiary = Color(0xFFFFFFFF); // White
  static const Color neutral = Color(0xFF666666); // Medium Grey
  
  static const Color background = Color(0xFFF7F7F7); // Light Grey scaffold BG
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF121212);
  static const Color textSecondary = Color(0xFF666666);
  static const Color border = Color(0xFFE0E0E0);
  
  // Status/Alert Colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFD32F2F);

  // Tracker accent colors — used across steps/sleep/water/glucose/vitals cards
  static const Color stepsAccent  = Color(0xFF10B981);
  static const Color sleepAccent  = Color(0xFF6366F1);
  static const Color waterAccent  = Color(0xFF3B82F6);
  static const Color glucoseAccent = Color(0xFFF59E0B);
  static const Color vitalsAccent  = Color(0xFFEF4444);
  static const Color rewardsAccent = Color(0xFFFFAB00);
}
