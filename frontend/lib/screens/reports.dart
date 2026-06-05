// lib/screens/reports.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/utils/app_constants.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ?? AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white54 : AppColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: AppColors.primaryLight, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['school_reports'] ?? 'School Reports',
                    style: AppTextStyles.heading2.copyWith(color: textColor),
                  ),
                  Text(
                    t['reports_subtitle'] ?? 'School data reports and summaries',
                    style: AppTextStyles.body.copyWith(color: mutedColor),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Under Development illustration centered in remaining space
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Illustration
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.primary.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A2E) : AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.construction_rounded,
                        color: AppColors.primaryLight,
                        size: 32,
                      ),
                    ),
                    // Small gear top-right
                    Positioned(
                      top: 8, right: 10,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF16213E) : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Icon(Icons.settings_rounded, size: 16, color: isDark ? Colors.white38 : AppColors.textMuted),
                      ),
                    ),
                    // Small chart bottom-left
                    Positioned(
                      bottom: 8, left: 10,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF16213E) : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Icon(Icons.insert_chart_outlined_rounded, size: 16, color: isDark ? Colors.white38 : AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  t['under_development'] ?? 'Under Development',
                  style: AppTextStyles.heading2.copyWith(color: textColor, fontSize: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  t['under_development_subtitle'] ?? 'We\'re working on this feature. Stay tuned!',
                  style: AppTextStyles.body.copyWith(color: mutedColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
