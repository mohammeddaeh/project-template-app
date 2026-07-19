import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

import 'network_state.dart';
import 'network_state_monitor.dart';

/// Concrete [NetworkStateMonitor] backed by `connectivity_plus`.
///
/// Registered as a lazy singleton so the platform stream subscription
/// is created once and shared across the app.
@LazySingleton(as: NetworkStateMonitor)
class NetworkStateMonitorImpl implements NetworkStateMonitor {
  NetworkStateMonitorImpl() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  final StreamController<NetworkState> _controller =
      StreamController<NetworkState>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  NetworkState _current = NetworkState.unknown;

  void _init() {
    _sub = _connectivity.onConnectivityChanged.listen(_onResults);
    _connectivity.checkConnectivity().then(_onResults);
  }

  void _onResults(List<ConnectivityResult> results) {
    final next = results.contains(ConnectivityResult.none)
        ? NetworkState.offline
        : NetworkState.online;

    if (next == _current) return;
    _current = next;
    _controller.add(_current);
  }

  @override
  NetworkState get currentState => _current;

  @override
  Stream<NetworkState> get stateStream async* {
    // Emit the current state immediately on subscription, then follow live.
    yield _current;
    yield* _controller.stream;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
