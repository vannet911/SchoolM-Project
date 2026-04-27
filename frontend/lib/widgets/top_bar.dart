// lib/widgets/top_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/theme_provider.dart';
import 'package:schoolms_portal/utils/app_constants.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showMenuIcon;
  final VoidCallback? onMenuTap;

  const TopBar({
    super.key,
    required this.title,
    this.showMenuIcon = true,
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppConstants.topBarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final iconColor = isDark ? Colors.white : AppColors.textPrimary;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Container(
      height: AppConstants.topBarHeight,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (showMenuIcon) ...[
            InkWell(
              onTap: onMenuTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.menu, size: 20, color: iconColor),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(title, style: AppTextStyles.heading3.copyWith(color: textColor)),
          const Spacer(),
          // Info icon
          _TopBarIconButton(
            icon: Icons.info_outline,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          // Settings icon - Theme toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return _TopBarIconButton(
                icon: themeProvider.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                onTap: () => themeProvider.toggleTheme(),
              );
            },
          ),
          const SizedBox(width: 12),
          // Language selector
          _LanguageSelector(),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final iconColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
          color: bgColor,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _LanguageSelector extends StatefulWidget {
  @override
  State<_LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<_LanguageSelector> {
  String _selected = 'English';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final iconColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return InkWell(
      onTap: () {
        // Language dropdown
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
          color: bgColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // UK Flag emoji
            const Text('🇬🇧', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(_selected,
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w500, color: textColor)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_up, size: 16, color: iconColor),
          ],
        ),
      ),
    );
  }
}
