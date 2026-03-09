import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  final _secureStorage = const FlutterSecureStorage();

  // Storage keys
  static const String _rememberMeKey = 'remember_me';

  // Hardcoded valid credentials
  static const Map<String, String> _validCredentials = {
    'gokul.d@flame': 'flameapp3948\$',
    'praveen@flame': 'Nevarkisthebest123\$',
    'nikhil@flame': 'Nevarkisawesome123\$',
  };

  // Authenticate user
  Future<bool> authenticate(String employeeId, String password) async {
    return _validCredentials[employeeId] == password;
  }

  // Check if user exists (always true for hardcoded users)
  Future<bool> hasRegisteredUser() async {
    return true;
  }

  // Save remember me preference
  Future<void> setRememberMe(bool remember, String? employeeId, String? password) async {
    await _secureStorage.write(key: _rememberMeKey, value: remember.toString());

    if (remember && employeeId != null && password != null) {
      await _secureStorage.write(key: 'saved_employee_id', value: employeeId);
      await _secureStorage.write(key: 'saved_password', value: password);
    } else {
      await _secureStorage.delete(key: 'saved_employee_id');
      await _secureStorage.delete(key: 'saved_password');
    }
  }

  // Get remember me preference
  Future<bool> getRememberMe() async {
    final remember = await _secureStorage.read(key: _rememberMeKey);
    return remember == 'true';
  }

  // Get saved credentials (only if remember me is enabled)
  Future<Map<String, String>?> getSavedCredentials() async {
    final rememberMe = await getRememberMe();
    if (!rememberMe) return null;

    final employeeId = await _secureStorage.read(key: 'saved_employee_id');
    final password = await _secureStorage.read(key: 'saved_password');

    if (employeeId != null && password != null) {
      return {'employeeId': employeeId, 'password': password};
    }
    return null;
  }

  // Logout (clear saved credentials)
  Future<void> logout() async {
    await _secureStorage.delete(key: 'saved_employee_id');
    await _secureStorage.delete(key: 'saved_password');
    await _secureStorage.write(key: _rememberMeKey, value: 'false');
  }

  // Clear all data (for testing/reset)
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}

