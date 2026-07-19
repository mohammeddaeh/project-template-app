import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Verifies that the device has a stable and reachable internet connection —
/// not just an active network interface.
///
/// ## Why this exists
/// [ConnectivityService.isOnline] only confirms a network link (WiFi, mobile).
/// It cannot detect captive portals, routers with no uplink, or flaky
/// connections. [NetworkStabilityProbe] performs real outbound pings to confirm
/// reachability before any sensitive operation (sync, retry, auth).
///
/// ## Configuration
/// Adjust the static fields once at app startup (e.g. in `main.dart`) to tune
/// probe behaviour without touching call sites:
///
/// ```dart
/// NetworkStabilityProbe.pingCount = 3;
/// NetworkStabilityProbe.pingInterval = const Duration(seconds: 3);
/// NetworkStabilityProbe.minSuccesses = 2;
/// ```
///
/// ## Custom ping endpoint (optional)
/// By default the probe uses [InternetConnectionChecker] (pings well-known
/// public hosts). To use your own backend health endpoint instead:
///
/// ```dart
/// NetworkStabilityProbe.pingFn = () => getIt<Dio>()
///     .get('${Env().config.baseUrl}/health')
///     .then((r) => (r.statusCode ?? 0) < 400);
/// ```
///
/// ## Usage
/// ```dart
/// final stable = await NetworkStabilityProbe.verifyStableConnection();
/// if (!stable) return Left(const NoInternetFailure());
/// ```
abstract final class NetworkStabilityProbe {
  NetworkStabilityProbe._();

  // ── Configuration ─────────────────────────────────────────────────────────

  /// Number of ping attempts. Default: 3.
  static int pingCount = 3;

  /// Delay between consecutive pings. Default: 3 s.
  static Duration pingInterval = const Duration(seconds: 3);

  /// Minimum successful pings required to declare a stable connection.
  /// Must be ≤ [pingCount]. Default: 2.
  static int minSuccesses = 2;

  // ── Custom hook ───────────────────────────────────────────────────────────

  /// Optional custom ping function.
  ///
  /// If set, replaces the default [InternetConnectionChecker] probe.
  /// Assign once at startup — e.g. to hit your backend's `/health` endpoint.
  static Future<bool> Function()? pingFn;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns `true` when the connection is considered stable (at least
  /// [minSuccesses] out of [pingCount] pings succeed).
  ///
  /// Short-circuits early as soon as [minSuccesses] is reached.
  static Future<bool> verifyStableConnection() async {
    var successes = 0;

    for (var i = 0; i < pingCount; i++) {
      if (i > 0) await Future<void>.delayed(pingInterval);

      try {
        if (await _singlePing()) {
          successes++;
          if (successes >= minSuccesses) return true;
        }
      } catch (_) {
        // treat errors as failures — keep probing
      }
    }

    return successes >= minSuccesses;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static Future<bool> _singlePing() async {
    if (pingFn != null) return pingFn!();

    // Fast check: is there any network interface?
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) return false;

    // Real check: can we reach the internet?
    return InternetConnectionChecker.instance.hasConnection;
  }
}
