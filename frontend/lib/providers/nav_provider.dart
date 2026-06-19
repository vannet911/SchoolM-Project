// lib/providers/nav_provider.dart
import 'package:flutter/material.dart';

enum NavPage { dashboard, students, teachers, classSubject, timetable, attendance, reports, profile }

class NavProvider extends ChangeNotifier {
  NavPage _currentPage = NavPage.dashboard;
  NavPage? _previousPage;
  bool _sidebarCollapsed = false;

  NavPage get currentPage => _currentPage;
  bool get sidebarCollapsed => _sidebarCollapsed;

  void navigate(NavPage page) {
    _currentPage = page;
    notifyListeners();
  }

  void navigateToProfile() {
    _previousPage = _currentPage;
    _currentPage = NavPage.profile;
    notifyListeners();
  }

  void goBack() {
    _currentPage = _previousPage ?? NavPage.dashboard;
    _previousPage = null;
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
      case NavPage.timetable: return 'timetable';
      case NavPage.attendance: return 'attendance';
      case NavPage.reports: return 'reports';
      case NavPage.profile: return 'profile';
    }
  }
}
