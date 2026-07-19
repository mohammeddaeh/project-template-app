import 'package:connectivity_plus/connectivity_plus.dart';

/// One-shot connectivity check — no DI required, call anywhere.
///
/// For reactive monitoring (stream), use [NetworkStateMonitor].
///
/// Usage:
/// ```dart
/// if (!await ConnectivityService.isOnline()) {
///   return Left(const NoInternetFailure());
/// }
/// ```
abstract final class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity = Connectivity();

  /// Returns `true` if the device has at least one active network interface.
  ///
  /// Note: an active link does not guarantee server reachability.
  static Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// Inverse of [isOnline].
  static Future<bool> isOffline() async => !await isOnline();
}
