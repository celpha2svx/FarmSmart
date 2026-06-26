import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand - Green (agriculture)
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);

  // Accent - Earth/Warm
  static const Color accent = Color(0xFFF57C00);
  static const Color accentLight = Color(0xFFFFB74D);

  // Status
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF1E88E5);

  // Risk levels (for pest/drought)
  static const Color riskHigh = Color(0xFFD32F2F);
  static const Color riskMedium = Color(0xFFF57C00);
  static const Color riskLow = Color(0xFFFBC02D);
  static const Color riskNone = Color(0xFF43A047);

  // Soil moisture
  static const Color soilWet = Color(0xFF1565C0);
  static const Color soilMoist = Color(0xFF42A5F5);
  static const Color soilDry = Color(0xFFFFA726);
  static const Color soilCritical = Color(0xFFD84315);

  // Neutral
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);
}
