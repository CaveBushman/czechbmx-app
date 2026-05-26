import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();

  static const _kEnabled = 'biometric_enabled';
  static final _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  /// Whether the device supports biometrics (fingerprint / Face ID).
  static Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Whether the user has opted in to biometric unlock.
  static Future<bool> isEnabled() async {
    try {
      final val = await _storage.read(key: _kEnabled);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Save the user's preference.
  static Future<void> setEnabled(bool value) async {
    await _storage.write(key: _kEnabled, value: value.toString());
  }

  /// Prompt the user for biometric authentication.
  /// Returns true on success.
  static Future<bool> authenticate(String localizedReason) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
