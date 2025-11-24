import 'package:flutter/material.dart';

/// Minimal AuthService used by the role-based login screen for demo purposes.
/// This implementation is intentionally simple — replace with your real auth
/// logic and Firestore/REST calls as required.
class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (email.isNotEmpty && password.isNotEmpty) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
