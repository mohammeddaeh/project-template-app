import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:app_template/modules/sync/config/sync_mode.dart';
import 'package:app_template/modules/sync/config/sync_settings.dart';
import 'package:app_template/modules/sync/config/sync_settings_store.dart';
import 'package:app_template/modules/sync/data/sync_cursor_store.dart';
import 'package:app_template/modules/sync/data/sync_database.dart';
import 'package:app_template/modules/sync/data/sync_operations_log.dart';
import 'package:app_template/modules/sync/domain/sync_entity_store.dart';
import 'package:app_template/modules/sync/domain/sync_queue_repository.dart';
import 'package:app_template/modules/sync/engine/sync_backoff_policy.dart';
import 'package:app_template/modules/sync/engine/sync_conflict_resolver.dart';
import 'package:app_template/modules/sync/engine/sync_engine.dart';
import 'package:app_template/modules/sync/integration/sync_controller.dart';
import 'package:app_template/modules/sync/integration/sync_gate.dart';
import 'package:app_template/modules/sync/integration/sync_lock.dart';
import 'package:app_template/modules/sync/sdk/sync_sdk_config.dart';
import 'package:app_template/modules/sync/validation/sync_contract_migrator.dart';
import 'package:app_template/modules/sync/validation/sync_contract_validator.dart';
import 'package:app_template/core/foundation/contracts/auth_network_gateway.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';

/// Guards the periodic sync timer against the defect that removed it silently.
///
/// ## What went wrong
///
/// `SyncSdkConfig.periodicIntervalSeconds` defaulted to `null`, and
/// `ModulesBootstrap` starts the module with `const SyncSdkConfig(enabled:
/// true)`. So the stored interval was `null`, and
/// `SyncController._setupPeriodic` returned at its `seconds == null` guard
/// **before reaching `Timer.periodic`**.
///
/// Nothing announced it. `init()` completed, the connectivity listener was
/// bound, no exception was thrown, no warning was logged, `dart analyze` was
/// clean and every test passed — the module just never synced on its own.
/// That is the shape this file exists to catch: a feature that is off while
/// everything reports success.
///
/// ## Why it observes `Timer.periodic` through a Zone
///
/// `SyncController` exposes no view of its timer, and waiting five minutes for
/// one to fire is not a test. A `Zone` that intercepts `createPeriodicTimer`
/// records the call and its duration without touching production code — the
/// controller runs exactly as it does in the app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// connectivity_plus reaches the platform over an EventChannel that has no
  /// implementation under `flutter test`. Left alone, `.listen()` in
  /// `_bindConnectivity` raises an async error before `_setupPeriodic` is ever
  /// reached — which would make this file test the wrong thing. The handler
  /// below emits nothing; it only lets the subscription succeed.
  const eventChannel = EventChannel('dev.fluttercommunity.plus/connectivity_status');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(eventChannel, _SilentStreamHandler());
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(eventChannel, null);
  });

  group('SyncSdkConfig — the layer that owns the default', () {
    test('the default configuration carries a usable interval', () {
      const config = SyncSdkConfig();

      expect(
        config.periodicIntervalSeconds,
        isNotNull,
        reason: 'A null default is what disabled periodic sync silently.',
      );
      expect(config.periodicIntervalSeconds, greaterThan(0));
      expect(
        config.periodicIntervalSeconds,
        SyncSdkConfig.defaultPeriodicIntervalSeconds,
      );
    });

    test('the shape ModulesBootstrap actually uses carries it too', () {
      // Verbatim from `modules_bootstrap.dart` — the call whose omitted
      // argument caused the defect.
      const config = SyncSdkConfig(enabled: true);

      expect(config.periodicIntervalSeconds, greaterThan(0));
    });

    test('an explicit null still disables the timer — the opt-out survives', () {
      // `SETUP.md` documents `null = disable timer`. Fixing the default must
      // not remove the choice, only stop it being made by accident.
      const config = SyncSdkConfig(periodicIntervalSeconds: null);

      expect(config.periodicIntervalSeconds, isNull);
    });
  });

  group('SyncController.init — what the settings actually produce', () {
    test('active + enabled + default interval installs a periodic timer', () async {
      final probe = await _runInit(
        SyncSettings(
          mode: SyncMode.active,
          syncEnabled: true,
          wifiOnly: false,
          periodicIntervalSeconds:
              SyncSdkConfig.defaultPeriodicIntervalSeconds,
        ),
      );

      expect(
        probe.periodicDurations,
        hasLength(1),
        reason: 'Timer.periodic was never created — periodic sync is off.',
      );
      expect(
        probe.periodicDurations.single,
        const Duration(seconds: SyncSdkConfig.defaultPeriodicIntervalSeconds),
      );
    });

    test('a null interval installs nothing — the documented opt-out', () async {
      final probe = await _runInit(
        const SyncSettings(
          mode: SyncMode.active,
          syncEnabled: true,
          wifiOnly: false,
          periodicIntervalSeconds: null,
        ),
      );

      expect(probe.periodicDurations, isEmpty);
    });

    test('syncEnabled = false installs nothing', () async {
      final probe = await _runInit(
        const SyncSettings(
          mode: SyncMode.active,
          syncEnabled: false,
          wifiOnly: false,
          periodicIntervalSeconds: 300,
        ),
      );

      expect(probe.periodicDurations, isEmpty);
    });

    test('a non-active mode installs nothing', () async {
      for (final mode in [SyncMode.passive, SyncMode.disabled]) {
        final probe = await _runInit(
          SyncSettings(
            mode: mode,
            syncEnabled: true,
            wifiOnly: false,
            periodicIntervalSeconds: 300,
          ),
        );

        expect(
          probe.periodicDurations,
          isEmpty,
          reason: 'mode=$mode must not schedule background work.',
        );
      }
    });
  });
}

/// Runs the real [SyncController.init] against [settings] and reports every
/// `Timer.periodic` it created.
Future<_TimerProbe> _runInit(SyncSettings settings) async {
  final probe = _TimerProbe();
  final controller = _buildController(settings);

  await runZoned(
    controller.init,
    zoneSpecification: ZoneSpecification(
      createPeriodicTimer: (self, parent, zone, duration, callback) {
        probe.periodicDurations.add(duration);
        // Still create it, so `dispose()` has something real to cancel.
        return parent.createPeriodicTimer(zone, duration, callback);
      },
    ),
  );

  await controller.dispose();
  return probe;
}

class _TimerProbe {
  final List<Duration> periodicDurations = [];
}

/// Builds a real [SyncController] with real collaborators.
///
/// The engine and gate are constructed, never invoked: `init()` only binds a
/// listener and reads settings, and both callbacks that would use them are
/// scheduled rather than run. The `noSuchMethod` fakes below make that a
/// claim the test enforces — touching one throws instead of quietly answering.
SyncController _buildController(SyncSettings settings) {
  final db = SyncDatabase();
  final di = GetIt.asNewInstance();
  final queue = _UnusedQueueRepository();
  final migrator = SyncContractMigrator(di);
  final settingsStore = _FixedSettingsStore(settings);
  final connectivity = Connectivity();

  final engine = SyncEngine(
    settingsStore,
    queue,
    _UnusedEntityStore(),
    SyncBackoffPolicy(),
    di,
    migrator,
    SyncContractValidator(di, queue, migrator),
    SyncConflictResolver(),
    SyncLock(_UnusedStorage()),
    SyncOperationsLog(db),
    SyncCursorStore(db),
  );

  return SyncController(
    settingsStore,
    connectivity,
    engine,
    SyncGate(settingsStore, connectivity, _UnusedSession(), _UnusedReachability()),
  );
}

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FixedSettingsStore implements SyncSettingsStore {
  _FixedSettingsStore(this._settings);

  final SyncSettings _settings;

  @override
  Future<SyncSettings> getSettings() async => _settings;

  @override
  Future<void> setMode(SyncMode mode) async {}

  @override
  Future<void> setSyncEnabled(bool value) async {}

  @override
  Future<void> setWifiOnly(bool value) async {}

  @override
  Future<void> setPeriodicIntervalSeconds(int? value) async {}
}

/// Answers nothing. Reached only if `init()` starts doing more than it should.
class _UnusedQueueRepository implements SyncQueueRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('SyncQueueRepository touched during init()');
}

class _UnusedEntityStore implements SyncEntityStore {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('SyncEntityStore touched during init()');
}

class _UnusedStorage implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('StorageService touched during init()');
}

class _UnusedSession implements AuthNetworkGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('AuthNetworkGateway touched during init()');
}

/// An EventChannel that accepts a listener and sends nothing.
class _SilentStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}

  @override
  void onCancel(Object? arguments) {}
}

/// Never consulted: `init()` binds a listener and reads settings; it does not
/// run a cycle, so the gate is never asked anything.
class _UnusedReachability implements InternetConnectionChecker {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('InternetConnectionChecker touched during init()');
}
