import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> get isAvailable async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
