import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/platform/connectivity/network_state.dart';
import 'package:app_template/core/platform/connectivity/network_state_monitor.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';
import 'package:app_template/ui/state/sync/offline_ux_cubit.dart';

/// The offline banner follows the injected monitor — and an `unknown` state
/// (before the monitor's first check lands) is not read as offline.
void main() {
  late _FakeMonitor monitor;
  late OfflineUxCubit cubit;

  setUp(() {
    monitor = _FakeMonitor();
    cubit = OfflineUxCubit(monitor, _FakeQueue());
  });

  tearDown(() => cubit.close());

  test('an unknown start does not show the device as offline', () async {
    await cubit.init();
    await pumpEventQueue();
    expect(cubit.state, isA<ConnectivityUnknownState>());

    monitor.emit(NetworkState.online);
    await pumpEventQueue();
    expect(cubit.state, isA<PendingChangesState>());
  });

  test('a real offline answer shows offline', () async {
    await cubit.init();
    await pumpEventQueue();
    monitor.emit(NetworkState.offline);
    await pumpEventQueue();
    expect(cubit.state, isA<OfflineState>());
  });

  test('refresh before the first answer leaves the state alone', () async {
    await cubit.refresh();
    expect(cubit.state, isA<ConnectivityUnknownState>());
  });
}

class _FakeMonitor implements NetworkStateMonitor {
  final _controller = StreamController<NetworkState>.broadcast();

  @override
  NetworkState currentState = NetworkState.unknown;

  void emit(NetworkState state) {
    currentState = state;
    _controller.add(state);
  }

  @override
  Stream<NetworkState> get stateStream async* {
    yield currentState;
    yield* _controller.stream;
  }

  @override
  void dispose() => _controller.close();
}

class _FakeQueue implements SyncQueueRepository {
  @override
  Future<int> countPendingJobs() async => 2;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
