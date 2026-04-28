// lib/widgets/sidebar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/auth_provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/providers/nav_provider.dart';
import 'package:schoolms_portal/utils/app_constants.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nav = context.watch<NavProvider>();
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.sidebarBg;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return Container(
      width: AppConstants.sidebarWidth,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── User profile section ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            color: isDark ? const Color(0xFF1A1A2E) : AppColors.background,
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 90,
                  height: 90,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primarySurface,
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://www.shutterstock.com/image-vector/default-avatar-photo-placeholder-grey-600nw-2007531536.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 40,
                        color: mutedColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Text(
                        auth.displayName,
                        style: AppTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.w600, color: textColor),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.displayEmail,
                        style: AppTextStyles.body.copyWith(color: mutedColor),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Divider(
                    color:
                        isDark ? const Color(0xFF2A2A4A) : AppColors.divider),
                const SizedBox(height: 4),
                // Profile & Logout buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SidebarActionButton(
                          icon: Icons.edit_outlined,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 38,
                        color: borderColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SidebarActionButton(
                          icon: Icons.logout,
                          color: AppColors.error,
                          onTap: () {
                            context.read<AuthProvider>().logout();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Navigation items ──────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    label: t['dashboard'] ?? 'Dashboard',
                    isActive: nav.currentPage == NavPage.dashboard,
                    onTap: () => nav.navigate(NavPage.dashboard),
                  ),
                  _NavItem(
                    icon: Icons.school_outlined,
                    label: t['students'] ?? 'Students',
                    isActive: nav.currentPage == NavPage.students,
                    onTap: () => nav.navigate(NavPage.students),
                  ),
                  _NavItem(
                    icon: Icons.person_outlined,
                    label: t['teachers'] ?? 'Teachers',
                    isActive: nav.currentPage == NavPage.teachers,
                    onTap: () => nav.navigate(NavPage.teachers),
                  ),
                  _NavItem(
                    icon: Icons.menu_book_outlined,
                    label: t['classes'] ?? 'Class & Subject',
                    isActive: nav.currentPage == NavPage.classSubject,
                    onTap: () => nav.navigate(NavPage.classSubject),
                  ),
                  _NavItem(
                    icon: Icons.bar_chart_outlined,
                    label: 'Reports',
                    isActive: nav.currentPage == NavPage.reports,
                    onTap: () => nav.navigate(NavPage.reports),
                  ),
                ],
              ),
            ),
          ),

          // ── Version ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Icon(Icons.refresh, size: 18, color: mutedColor),
                const SizedBox(width: 8),
                Text(AppConstants.appVersion,
                    style: AppTextStyles.body.copyWith(color: mutedColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SidebarActionButton({
    required this.icon,
    this.color = AppColors.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
          color: bgColor,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hoverColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.02);
    final activeBg = isDark ? const Color(0xFF1A1A2E) : AppColors.background;
    final textColor = isDark ? Colors.white : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovering) {
          setState(() => isHovering = hovering);
        },
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: isHovering
                ? hoverColor
                : widget.isActive
                    ? activeBg
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 30,
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? AppColors.primaryLight
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Icon(
                widget.icon,
                size: 20,
                color: widget.isActive ? AppColors.primaryLight : textColor,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: AppTextStyles.body.copyWith(
                  color: widget.isActive ? AppColors.primaryLight : textColor,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
