# Credential Management Guide

## Overview

The FLAME app uses **secure, encrypted storage** with **password hashing** to protect user credentials on the device.

## Security Features

1. **Password Hashing**: Passwords are hashed using SHA-256 before storage
2. **Encrypted Storage**: Credentials stored using `flutter_secure_storage`
   - Android: Uses EncryptedSharedPreferences
   - iOS: Uses Keychain
   - Windows/Linux: Uses platform-specific secure storage
3. **Remember Me**: Optional feature to save login credentials securely

## First-Time Setup

On first launch, the app will show **"Create Account"** screen:
1. Enter your desired Employee ID
2. Enter your desired Password
3. Check "Remember me" if you want auto-login
4. Click "Create Account"

Your credentials are now securely stored on the device.

## Changing Credentials Programmatically

### Method 1: Using CredentialManager (Recommended)

```dart
import 'package:flame/utils/credential_manager.dart';

// Register new user
await CredentialManager.instance.registerNewUser('newEmployeeId', 'newPassword');

// Change password
bool success = await CredentialManager.instance.changePassword('oldPassword', 'newPassword');

// Check if user exists
bool hasUser = await CredentialManager.instance.hasUser();

// Get employee ID
String? employeeId = await CredentialManager.instance.getEmployeeId();

// Reset all credentials (WARNING: User will need to register again)
await CredentialManager.instance.resetAllCredentials();
```

### Method 2: Using AuthService Directly

```dart
import 'package:flame/services/auth_service.dart';

// Register user
await AuthService.instance.registerUser('employeeId', 'password');

// Authenticate
bool isValid = await AuthService.instance.authenticate('employeeId', 'password');

// Change password
bool changed = await AuthService.instance.changePassword('oldPass', 'newPass');
```

## Resetting Credentials

### Option 1: Through Code

Add this to your settings page or debug menu:

```dart
ElevatedButton(
  onPressed: () async {
    await CredentialManager.instance.resetAllCredentials();
    // Navigate back to login
    Navigator.pushReplacementNamed(context, '/login');
  },
  child: Text('Reset Credentials'),
)
```

### Option 2: Clear App Data

- **Android**: Settings → Apps → FLAME → Storage → Clear Data
- **iOS**: Uninstall and reinstall the app
- **Windows**: Delete app data folder

## Testing Different Credentials

For testing, you can use the Flutter DevTools or add a debug function:

```dart
// In your main.dart or a debug screen
Future<void> setupTestCredentials() async {
  await AuthService.instance.clearAll();
  await AuthService.instance.registerUser('testUser', 'testPass123');
  print('Test credentials created: testUser / testPass123');
}
```

## Security Best Practices

1. **Never hardcode passwords** in source code
2. **Use strong passwords** (min 8 characters, mix of letters/numbers/symbols)
3. **Don't share credentials** in version control
4. **Regularly update passwords** for production use
5. **Enable "Remember Me" only on trusted devices**

## How Password Hashing Works

```dart
// User enters: "myPassword123"
// Stored in secure storage: "ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f"
// Original password is NEVER stored
```

Even if someone accesses the secure storage, they cannot retrieve the original password.

## Troubleshooting

### "Invalid credentials" on first launch
- The app is in first-time setup mode
- Any credentials you enter will be registered

### Forgot password
- Currently requires app data reset
- Future update: Add password recovery via email/security questions

### Remember Me not working
- Check if secure storage permissions are granted
- Try clearing app data and re-registering

## API Reference

See `lib/services/auth_service.dart` for full API documentation.
See `lib/utils/credential_manager.dart` for helper utilities.

