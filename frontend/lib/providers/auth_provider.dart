// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  String get displayName => _currentUser?['username'] ?? _currentUser?['firstName'] ?? 'Vannet SONY';
  String get displayEmail => _currentUser?['email'] ?? 'vannet.sony@gmail.com';

  final ApiService _api = ApiService();

  Future<void> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.login(email, password);
      if (result['token'] != null) {
        _api.setToken(result['token']);
      }
      _currentUser = result['user'] ?? {'email': email, 'username': email.split('@').first};
      _status = AuthStatus.authenticated;
    } catch (e) {
      // For demo: allow any login if API is offline
      if (e.toString().contains('Network error') || e.toString().contains('Connection refused')) {
        _currentUser = {
          'email': email,
          'username': email.split('@').first,
          'firstName': 'Vannet',
          'lastName': 'SONY',
        };
        _status = AuthStatus.authenticated;
      } else {
        _errorMessage = e.toString();
        _status = AuthStatus.error;
      }
    }
    notifyListeners();
  }

  void logout() {
    _api.clearToken();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
