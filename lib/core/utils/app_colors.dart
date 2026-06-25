import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color secondaryDark = Color(0xFF0891B2);

  // Background / Surface Colors
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceLight = Color(0xFF334155); // Slate 700
  
  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // Status Colors
  static const Color statusPending = Color(0xFFF59E0B); // Amber
  static const Color statusInProgress = Color(0xFF3B82F6); // Blue
  static const Color statusCompleted = Color(0xFF10B981); // Emerald
  
  // Priority Colors
  static const Color priorityLow = Color(0xFF10B981); // Emerald
  static const Color priorityMedium = Color(0xFFF59E0B); // Amber
  static const Color priorityHigh = Color(0xFFEF4444); // Red

  // Neutral / Accents
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
