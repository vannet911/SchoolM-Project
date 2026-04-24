// lib/widgets/top_bar.dart
import 'package:flutter/material.dart';
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
    return Container(
      height: AppConstants.topBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (showMenuIcon) ...[
            InkWell(
              onTap: onMenuTap,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.menu, size: 20, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(title, style: AppTextStyles.heading3),
          const Spacer(),
          // Info icon
          _TopBarIconButton(
            icon: Icons.info_outline,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          // Settings icon
          _TopBarIconButton(
            icon: Icons.settings_outlined,
            onTap: () {},
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          color: AppColors.white,
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
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
    return InkWell(
      onTap: () {
        // Language dropdown
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // UK Flag emoji
            const Text('🇬🇧', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(_selected, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_up, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
