import 'package:flutter/material.dart';

/// Gaming Lounge Color Palette
class AppColors {
  // Backgrounds & Surface (Gaming Dark)
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceLight = Color(0xFF21262D);
  static const Color cardBg = Color(0xFF181E29);
  static const Color cardBorder = Color(0xFF30363D);

  // Brand & Neon Accents
  static const Color primaryNeon = Color(0xFF7C3AED); // Electric Violet / Purple
  static const Color primaryLight = Color(0xFF9333EA);
  static const Color primaryDark = Color(0xFF6D28D9);
  static const Color cyanAccent = Color(0xFF06B6D4); // Neon Cyan
  static const Color blueAccent = Color(0xFF3B82F6); // Cyber Blue

  // Status Colors
  static const Color occupied = Color(0xFFEF4444); // Neon Crimson / Busy
  static const Color available = Color(0xFF10B981); // Emerald / Free
  static const Color warning = Color(0xFFF59E0B); // Amber / Attention
  static const Color info = Color(0xFF38BDF8); // Sky / Info

  // Text Colors
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textDark = Color(0xFF111827);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient occupiedGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient availableGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0x227C3AED), Color(0x0506B6D4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
