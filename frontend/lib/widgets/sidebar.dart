// lib/widgets/sidebar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/auth_provider.dart';
import 'package:schoolms_portal/providers/nav_provider.dart';
import 'package:schoolms_portal/utils/app_constants.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nav = context.watch<NavProvider>();

    return Container(
      width: AppConstants.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── User profile section ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            color: AppColors.background,
            // decoration: const BoxDecoration(
            //   border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            // ),
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
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://www.shutterstock.com/image-vector/default-avatar-photo-placeholder-grey-600nw-2007531536.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.textSecondary,
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
                        style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.displayEmail,
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Divider(color: AppColors.divider),
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
                        color: AppColors.border,
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
                    label: 'Dashboard',
                    isActive: nav.currentPage == NavPage.dashboard,
                    onTap: () => nav.navigate(NavPage.dashboard),
                  ),
                  _NavItem(
                    icon: Icons.school_outlined,
                    label: 'Students',
                    isActive: nav.currentPage == NavPage.students,
                    onTap: () => nav.navigate(NavPage.students),
                  ),
                  _NavItem(
                    icon: Icons.person_outlined,
                    label: 'Teachers',
                    isActive: nav.currentPage == NavPage.teachers,
                    onTap: () => nav.navigate(NavPage.teachers),
                  ),
                  _NavItem(
                    icon: Icons.menu_book_outlined,
                    label: 'Class & Subject',
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
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.refresh, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(AppConstants.appVersion, style: AppTextStyles.caption),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.white,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 13),
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
