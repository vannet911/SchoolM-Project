// lib/screens/main_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/nav_provider.dart';
import 'package:schoolms_portal/widgets/sidebar.dart';
import 'package:schoolms_portal/widgets/top_bar.dart';
import 'package:schoolms_portal/utils/app_constants.dart';
import 'package:schoolms_portal/screens/dashboard.dart';
import 'package:schoolms_portal/screens/students.dart';
import 'package:schoolms_portal/screens/teachers.dart';
import 'package:schoolms_portal/screens/class_subject.dart';


class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────────
          const Sidebar(),

          // ── Main area ─────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                TopBar(
                  title: nav.pageTitle,
                  showMenuIcon: true,
                  onMenuTap: () => nav.toggleSidebar(),
                ),
                // Content
                Expanded(
                  child: _buildPage(nav.currentPage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(NavPage page) {
    switch (page) {
      case NavPage.dashboard:
        return const DashboardScreen();
      case NavPage.students:
        return const StudentsScreen();
      case NavPage.teachers:
        return const TeachersScreen();
      case NavPage.classSubject:
        return const ClassSubjectScreen();
      case NavPage.reports:
        return const _ReportsPlaceholder();
    }
  }
}

class _ReportsPlaceholder extends StatelessWidget {
  const _ReportsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Reports', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text('Coming soon...', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
