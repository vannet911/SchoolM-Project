// lib/screens/main_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/providers/nav_provider.dart';
import 'package:schoolms_portal/widgets/sidebar.dart';
import 'package:schoolms_portal/widgets/top_bar.dart';
import 'package:schoolms_portal/utils/app_constants.dart';
import 'package:schoolms_portal/screens/dashboard.dart';
import 'package:schoolms_portal/screens/students.dart';
import 'package:schoolms_portal/screens/teachers.dart';
import 'package:schoolms_portal/screens/class_subject.dart';
import 'package:schoolms_portal/screens/profile.dart';
import 'package:schoolms_portal/screens/reports.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;

    return Scaffold(
      backgroundColor: bgColor,
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
                  title: t[nav.pageTitleKey] ?? nav.pageTitleKey,
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
        return const ReportsScreen();
      case NavPage.profile:
        return const ProfileScreen();
    }
  }
}
