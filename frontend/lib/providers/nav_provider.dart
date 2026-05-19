// lib/providers/nav_provider.dart
import 'package:flutter/material.dart';

enum NavPage { dashboard, students, teachers, classSubject, reports }

class NavProvider extends ChangeNotifier {
  NavPage _currentPage = NavPage.dashboard;
  bool _sidebarCollapsed = false;

  NavPage get currentPage => _currentPage;
  bool get sidebarCollapsed => _sidebarCollapsed;

  void navigate(NavPage page) {
    _currentPage = page;
    notifyListeners();
  }

  void toggleSidebar() {
    _sidebarCollapsed = !_sidebarCollapsed;
    notifyListeners();
  }

  String get pageTitleKey {
    switch (_currentPage) {
      case NavPage.dashboard: return 'dashboard';
      case NavPage.students: return 'students';
      case NavPage.teachers: return 'teachers';
      case NavPage.classSubject: return 'class & subject';
      case NavPage.reports: return 'reports';
    }
  }
}
