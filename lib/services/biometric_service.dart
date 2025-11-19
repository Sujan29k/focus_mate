import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometrics are supported on this device
  Future<bool> isSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      return isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types (fingerprint, face, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({required String reason}) async {
    try {
      // Check if biometrics are available
      final isAvailable = await isSupported();
      if (!isAvailable) {
        return false;
      }

      // Perform authentication (biometric-only)
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on PlatformException {
      // Handle platform-specific errors
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if device has enrolled biometrics
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final available = await getAvailableBiometrics();
      return canCheck && available.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
