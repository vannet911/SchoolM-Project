// lib/utils/app_constants.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary green matching the screenshots
  static const Color primary = Color(0xFF3A6B35);
  static const Color primaryLight = Color(0xFF4E8C47);
  static const Color primaryDark = Color(0xFF2A4D26);
  static const Color primarySurface = Color(0xFFEBF3EA);

  // Background & Surfaces
  static const Color background = Color(0xFAF2F2F3);
  static const Color white = Color(0xFFFFFFFF);
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textLink = Color(0xFF3B82F6);

  // Stat card icon backgrounds
  static const Color studentIconBg = Color(0xFFE8F5E9);
  static const Color teacherIconBg = Color(0xFFE3F2FD);
  static const Color classIconBg = Color(0xFFFFF8E1);

  // Borders
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);

  // Status
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted,
  );
  static const TextStyle label = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
  );
  static const TextStyle statValue = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
}

class AppConstants {
  static const String apiBase = 'http://localhost:5000/api';
  static const String appName = 'SchoolMS Portal';
  static const String appSubtitle = 'School Management Portal';
  static const String appVersion = 'Version 1.0.0';
  static const String developerTag = '@vannet.developer';

  static const double sidebarWidth = 250.0;
  static const double rightPanelWidth = 300.0;
  static const double topBarHeight = 60.0;
  static const double cardRadius = 12.0;
  static const double pagePadding = 24.0;
}
