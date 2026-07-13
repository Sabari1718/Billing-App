import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthResult {
  final bool success;
  final String message;
  final bool notEnrolled;
  final bool noHardware;

  BiometricAuthResult({
    required this.success,
    required this.message,
    this.notEnrolled = false,
    this.noHardware = false,
  });
}

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Flag to avoid concurrent lifecycle loops and overlapping native dialog displays
  bool _isAuthenticating = false;

  // 1. Detect if biometrics can be checked on this device
  Future<bool> canCheckBiometrics() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      print('DEBUG [BiometricService]: canCheckBiometrics = $canCheck');
      return canCheck;
    } on PlatformException catch (e) {
      print('DEBUG [BiometricService]: canCheckBiometrics error = ${e.message}');
      return false;
    }
  }

  // 2. Detect if the device has biometric capabilities
  Future<bool> isDeviceSupported() async {
    try {
      final bool isSupported = await _localAuth.isDeviceSupported();
      print('DEBUG [BiometricService]: isDeviceSupported = $isSupported');
      return isSupported;
    } on PlatformException catch (e) {
      print('DEBUG [BiometricService]: isDeviceSupported error = ${e.message}');
      return false;
    }
  }

  // Unified helper for compatibility
  Future<bool> isHardwareSupported() async {
    final bool canCheck = await canCheckBiometrics();
    final bool isSupported = await isDeviceSupported();
    return canCheck || isSupported;
  }

  // 3. Detect if the user has enrolled any biometrics on their device
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final List<BiometricType> available = await getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException catch (_) {
      return false;
    }
  }

  // 4. Get list of supported/enrolled biometric types (fingerprint, face, iris)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> available = await _localAuth.getAvailableBiometrics();
      print('DEBUG [BiometricService]: availableBiometrics on device = $available');
      return available;
    } on PlatformException catch (e) {
      print('DEBUG [BiometricService]: getAvailableBiometrics error = ${e.message}');
      return <BiometricType>[];
    }
  }

  // 5. Helper method to map BiometricType to human readable string
  String getBiometricName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.iris:
        return 'Iris Scanning';
      case BiometricType.weak:
        return 'Weak Biometrics (Facial/Voice)';
      case BiometricType.strong:
        return 'Strong Biometrics';
    }
  }

  // 6. Perform the actual biometric hardware challenge using stickyAuth
  Future<BiometricAuthResult> authenticate({
    required String reason,
    bool biometricOnly = true,
  }) async {
    // Prevent concurrent/overlapping biometric prompts (Android lifecycle lock)
    if (_isAuthenticating) {
      print('DEBUG [BiometricService]: Prevented overlapping authenticate call.');
      return BiometricAuthResult(
        success: false,
        message: 'Biometric challenge is already in progress.',
      );
    }

    try {
      _isAuthenticating = true;

      // Verify general device support
      final supported = await isHardwareSupported();
      if (!supported) {
        _isAuthenticating = false;
        return BiometricAuthResult(
          success: false,
          message: 'Biometric hardware is not supported or available on this device.',
          noHardware: true,
        );
      }

      // Check enrolled credentials
      final enrolled = await hasEnrolledBiometrics();
      if (!enrolled) {
        _isAuthenticating = false;
        return BiometricAuthResult(
          success: false,
          message: 'No enrolled biometrics found. Please register your Fingerprint or Face ID in settings first.',
          notEnrolled: true,
        );
      }

      // Trigger native biometric dialog popup
      final bool success = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      _isAuthenticating = false;

      if (success) {
        return BiometricAuthResult(
          success: true,
          message: 'Biometric authentication successful!',
        );
      } else {
        return BiometricAuthResult(
          success: false,
          message: 'Authentication cancelled or rejected by user.',
        );
      }
    } on PlatformException catch (e) {
      _isAuthenticating = false;
      
      // Parse native exceptions to highly informative messages
      String errorMsg = 'Authentication failed: ${e.message}';
      bool notEnrolled = false;
      bool noHardware = false;

      switch (e.code) {
        case 'NotAvailable':
          errorMsg = 'Biometric security hardware is not supported or is disabled on this device.';
          noHardware = true;
          break;
        case 'NotEnrolled':
          errorMsg = 'No biometric credentials are enrolled. Please register your face or fingerprint in settings.';
          notEnrolled = true;
          break;
        case 'LockedOut':
          errorMsg = 'Too many failed biometric attempts. Biometrics are temporarily locked. Use phone PIN/Pattern to unlock.';
          break;
        case 'PermanentlyLockedOut':
          errorMsg = 'Biometrics permanently locked due to too many failures. Please unlock device via primary password.';
          break;
        case 'OtherOperatingSystem':
          errorMsg = 'Biometrics are not supported on this platform version.';
          noHardware = true;
          break;
      }

      return BiometricAuthResult(
        success: false,
        message: errorMsg,
        notEnrolled: notEnrolled,
        noHardware: noHardware,
      );
    }
  }
}
