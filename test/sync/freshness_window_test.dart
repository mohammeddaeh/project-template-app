import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/platform/lifecycle/app_lifecycle_service.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/sync/config/sync_mode.dart';
import 'package:app_template/modules/sync/config/sync_settings.dart';
import 'package:app_template/modules/sync/config/sync_settings_store.dart';
import 'package:app_template/modules/sync/data/sync_cursor_store.dart';
import 'package:app_template/modules/sync/data/sync_cycle_stamp.dart';
import 'package:app_template/modules/sync/data/sync_database.dart';
import 'package:app_template/modules/sync/data/sync_operations_log.dart';
import 'package:app_template/modules/sync/domain/sync_queue_signal.dart';
import 'package:app_template/modules/sync/engine/sync_backoff_policy.dart';
import 'package:app_template/modules/sync/engine/sync_conflict_resolver.dart';
import 'package:app_template/modules/sync/engine/sync_engine.dart';
import 'package:app_template/modules/sync/integration/sync_controller.dart';
import 'package:app_template/modules/sync/integration/sync_gate.dart';
import 'package:app_template/modules/sync/integration/sync_lock.dart';
import 'package:app_template/modules/sync/validation/sync_contract_migrator.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/sync/domain/sync_entity_store.dart';
import 'package:app_template/modules/sync/domain/sync_queue_repository.dart';
import 'package:app_template/modules/sync/validation/sync_contract_validator.dart';

/// **لفتةُ المستخدم — والنافذةُ التي تمنعها من أن تصير استطلاعاً.**
///
/// وقفلُ المزامنة يمنع **التداخل** لا **التكرار**: مستخدمٌ يتنقّل بين التبويبات
/// عشر مرّات بدقيقة كان سيُنتج عشرَ دوراتٍ متتابعة، كلُّ واحدةٍ نداءُ شبكةٍ على
/// بيانات الجوّال.
class _CountingEngine extends SyncEngine {
  _CountingEngine(super.a, super.b, super.c, super.d, super.e, super.f,
      super.g, super.h, super.i, super.j, super.k, super.l);

  int cycles = 0;

  @override
  Future<void> runPendingJobs({int batchSize = 20}) async => cycles++;
}

class _OpenGate implements SyncGate {
  @override
  Future<bool> allows({String context = 'cycle'}) async => true;
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('SyncGate.${i.memberName} touched');
}

class _FixedSettings implements SyncSettingsStore {
  @override
  Future<SyncSettings> getSettings() async => const SyncSettings(
    mode: SyncMode.active,
    syncEnabled: true,
    wifiOnly: false,
    periodicIntervalSeconds: null,
  );
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Lifecycle implements AppLifecycleService {
  final _controller = StreamController<AppLifecycleState>.broadcast();
  @override
  Stream<AppLifecycleState> get stateStream => _controller.stream;
  void resume() => _controller.add(AppLifecycleState.resumed);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Silent implements LogDelegate {
  const _Silent();
  @override
  void info(String m, {String? tag}) {}
  @override
  void warning(String m, {String? tag}) {}
  @override
  void debug(String m, {String? tag}) {}
  @override
  void error(String m, {String? tag, Object? error, StackTrace? stackTrace}) {}
}

void main() {
  // `init()` يشترك بـ`onConnectivityChanged` وهي قناةُ منصّة.
  TestWidgetsFlutterBinding.ensureInitialized();
  late _CountingEngine engine;
  late _Lifecycle lifecycle;
  late SyncController controller;

  setUp(() {
    LogService.setDelegate(const _Silent());
    final db = SyncDatabase();
    final di = GetIt.asNewInstance();
    final settings = _FixedSettings();
    final migrator = SyncContractMigrator(di);

    engine = _CountingEngine(
      settings,
      _UnusedQueue(),
      _UnusedStore(),
      SyncBackoffPolicy(),
      di,
      migrator,
      SyncContractValidator(di, _UnusedQueue(), migrator),
      SyncConflictResolver(),
      SyncLock(_UnusedStorage()),
      SyncOperationsLog(db),
      SyncCycleStamp(db),
      SyncCursorStore(db),
    );
    lifecycle = _Lifecycle();
    controller = SyncController(
      settings,
      Connectivity(),
      engine,
      _OpenGate(),
      SyncQueueSignal(),
      lifecycle,
    );
  });

  test('the first check runs a cycle', () async {
    await controller.checkIfStale();
    expect(engine.cycles, 1);
  });

  test('a second check inside the window does NOT', () async {
    await controller.checkIfStale();
    await controller.checkIfStale();
    await controller.checkIfStale();

    // ثلاثُ لفتاتٍ خلال ثوانٍ = نداءٌ واحد.
    expect(engine.cycles, 1);
  });

  test('a manual sync also refreshes the stamp', () async {
    // كلُّ مسارٍ يُشغّل دورةً يمرّ بـ`_runCycleNow` — فالختمُ لا يُنسى بأحدها،
    // وإلا صار زرُّ «مزامنة الآن» يترك النافذةَ مفتوحةً للفتةٍ تليه.
    await controller.triggerManualSync();
    await controller.checkIfStale();

    expect(engine.cycles, 1);
  });

  test('coming back to the foreground checks', () async {
    await controller.init();
    lifecycle.resume();
    await Future<void>.delayed(Duration.zero);

    expect(engine.cycles, greaterThanOrEqualTo(1));
    await controller.dispose();
  });

  test('the window is long enough to survive tab-hopping', () {
    expect(
      SyncController.freshnessWindow,
      greaterThanOrEqualTo(const Duration(seconds: 30)),
      reason: 'a window of a second or two is a poll with extra steps',
    );
  });
}

/// المحرّكُ يُبنى ولا يُستدعى: [_CountingEngine] يعدّ ويعود. ولمسُ أيٍّ من
/// هؤلاء يرمي بدل أن يُجيب بصمت — فالادّعاء مفروضٌ لا موصوف.
class _UnusedQueue implements SyncQueueRepository {
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('SyncQueueRepository touched');
}

class _UnusedStore implements SyncEntityStore {
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('SyncEntityStore touched');
}

class _UnusedStorage implements StorageService {
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('StorageService touched');
}
