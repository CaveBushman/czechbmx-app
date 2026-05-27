import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();

  static final _auth = LocalAuthentication();

  /// Whether the device supports ANY auth method (biometrics, PIN, pattern, password).
  static Future<bool> canAuthenticate() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompt the user for biometric / PIN authentication.
  /// Returns true on success.
  static Future<bool> authenticate(String localizedReason) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
