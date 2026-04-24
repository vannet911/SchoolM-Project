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

  String get pageTitle {
    switch (_currentPage) {
      case NavPage.dashboard: return 'Dashboard';
      case NavPage.students: return 'Students';
      case NavPage.teachers: return 'Teachers';
      case NavPage.classSubject: return 'Class & Subject';
      case NavPage.reports: return 'Reports';
    }
  }
}
