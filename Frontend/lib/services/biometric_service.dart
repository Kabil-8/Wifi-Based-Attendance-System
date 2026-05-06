import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      bool canCheck = await _auth.canCheckBiometrics;
      bool supported = await _auth.isDeviceSupported();

      if (!canCheck || !supported) {
        return false;
      }

      bool didAuth = await _auth.authenticate(
        localizedReason: 'Authenticate to mark attendance',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuth;

    } catch (e) {
      print("Biometric error: $e");
      return false;
    }
  }
}
