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
import 'package:schoolms_portal/screens/timetable.dart';
import 'package:schoolms_portal/screens/attendance.dart';
import 'package:schoolms_portal/screens/reports.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const double _mobileBreakpoint = 600.0;
  static const double _desktopBreakpoint = 1024.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _mobileBreakpoint;
    final isTablet = width >= _mobileBreakpoint && width < _desktopBreakpoint;

    final nav = context.watch<NavProvider>();
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;

    // ── Mobile: sidebar in a Drawer ───────────────────────────
    if (isMobile) {
      return Scaffold(
        backgroundColor: bgColor,
        drawer: const Sidebar(forceCollapsed: false),
        body: Builder(
          builder: (ctx) => Column(
            children: [
              TopBar(
                title: t[nav.pageTitleKey] ?? nav.pageTitleKey,
                showMenuIcon: true,
                onMenuTap: () => Scaffold.of(ctx).openDrawer(),
              ),
              Expanded(child: _buildPage(nav.currentPage)),
            ],
          ),
        ),
      );
    }

    // ── Tablet: always-collapsed icon sidebar ─────────────────
    if (isTablet) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Row(
          children: [
            const Sidebar(forceCollapsed: true),
            Expanded(
              child: Column(
                children: [
                  TopBar(
                    title: t[nav.pageTitleKey] ?? nav.pageTitleKey,
                    showMenuIcon: false,
                  ),
                  Expanded(child: _buildPage(nav.currentPage)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Desktop: full sidebar with toggle ─────────────────────
    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              children: [
                TopBar(
                  title: t[nav.pageTitleKey] ?? nav.pageTitleKey,
                  showMenuIcon: true,
                  onMenuTap: () => nav.toggleSidebar(),
                ),
                Expanded(child: _buildPage(nav.currentPage)),
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
      case NavPage.timetable:
        return const TimetableScreen();
      case NavPage.attendance:
        return const AttendanceScreen();
      case NavPage.reports:
        return const ReportsScreen();
      case NavPage.profile:
        return const ProfileScreen();
    }
  }
}
