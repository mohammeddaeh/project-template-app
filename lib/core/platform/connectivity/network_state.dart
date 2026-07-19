/// Represents the device's current network reachability state.
///
/// - [online]  — at least one non-none interface is active.
/// - [offline] — no active interface (ConnectivityResult.none).
/// - [unknown] — state has not been determined yet (initial).
enum NetworkState {
  online,
  offline,
  unknown;

  bool get isOnline => this == NetworkState.online;
  bool get isOffline => this == NetworkState.offline;
  bool get isUnknown => this == NetworkState.unknown;
}
