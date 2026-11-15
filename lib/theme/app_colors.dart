import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF161629);
  static const Color accentPurple = Color(0xFF9B5DE5);
  static const Color accentPink = Color(0xFFF15BB5);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9494B8);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, accentPink],
  );

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}
