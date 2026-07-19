import 'package:app_template/core/platform/biometrics/biometrics_service.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:local_auth/local_auth.dart';

/// [BiometricsService] implementation backed by `local_auth`.
///
/// Registered manually in `di/injection_module.dart`.
class BiometricsServiceImpl implements BiometricsService {
  BiometricsServiceImpl() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (e) {
      LogService.warning('BiometricsService.isAvailable failed: $e', tag: 'BIO');
      return false;
    }
  }

  @override
  Future<bool> isEnrolled() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (e) {
      LogService.warning('BiometricsService.isEnrolled failed: $e', tag: 'BIO');
      return false;
    }
  }

  @override
  Future<bool> authenticate(String localizedReason) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
    } catch (e) {
      LogService.error('BiometricsService.authenticate failed: $e', tag: 'BIO');
      return false;
    }
  }
}
