import 'package:flutter/foundation.dart';

import 'auth_service.dart';

class AuthState extends ChangeNotifier {
  final AuthService authService;

  AuthState(this.authService);

  bool loading = false;
  String? error;

  Future<void> signIn(String email, String password, {String? fcmToken}) async {
    _setLoading(true);
    try {
      await authService.signIn(
        email: email,
        password: password,
        fcmToken: fcmToken,
      );
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> signUp(
    String email,
    String password,
    String displayName, {
    String? fcmToken,
  }) async {
    _setLoading(true);
    try {
      await authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
        fcmToken: fcmToken,
      );
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    loading = value;
    notifyListeners();
  }
}
