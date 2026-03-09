import '../services/auth_service.dart';

class CredentialManager {
  static final CredentialManager instance = CredentialManager._internal();
  factory CredentialManager() => instance;
  CredentialManager._internal();

  final _authService = AuthService.instance;

  Future<bool> login(String employeeId, String password) async {
    return await _authService.authenticate(employeeId, password);
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<void> resetAllCredentials() async {
    await _authService.clearAll();
  }

  Future<void> setRememberMe(bool remember, String? employeeId, String? password) async {
    await _authService.setRememberMe(remember, employeeId, password);
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    return await _authService.getSavedCredentials();
  }
}

