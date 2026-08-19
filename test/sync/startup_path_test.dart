import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/sync/config/sync_settings_store.dart';
import 'package:app_template/modules/sync/integration/sync_bootstrap.dart';

/// Walks the startup path `SyncSDK.initialize` takes, in its order.
///
/// ## Why this is not covered by the tests that already exist
///
/// `sync_bootstrap_safety_test.dart` exercises `SyncContractValidator` against a
/// hand-built container, and `feature_contract_registration_test.dart` proves the
/// generated contract registration is discoverable. Both start *after* the step
/// this file checks: `registerSyncCore` runs first, and `_applyConfig` resolves
/// `SyncSettingsStore` before the validator is ever consulted.
///
/// Nothing had walked that stretch, which is why what it finds had survived.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetIt di;

  setUp(() async {
    di = GetIt.asNewInstance()..enableRegisteringMultipleInstancesOfOneType();
    LogService.setDelegate(const _SilentLogDelegate());

    // Mirrors what `getIt.init()` does for a `@preResolve` binding: await the
    // future once, then register the value synchronously.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    di.registerLazySingleton<SharedPreferences>(() => prefs);
  });

  tearDown(() async {
    LogService.setDelegate(const _SilentLogDelegate());
    await di.reset();
  });

  test('registerSyncCore completes without resolving anything', () async {
    // Every binding it makes is lazy, so registration itself must not need the
    // app's graph. This is the part of the path that works.
    await expectLater(registerSyncCore(di), completes);

    expect(di.isRegistered<SyncSettingsStore>(), isTrue);
  });

  test('SyncSettingsStore resolves — the first thing SyncSDK.initialize needs', () async {
    await registerSyncCore(di);

    // `SyncSDK.initialize` order:
    //   await registerSyncCore(di);
    //   await _applyConfig(di, config);   ← `di<SyncSettingsStore>()`, right here
    //   await di<SyncLock>().releaseIfStale();
    //   validator.validatePreInitialization();
    //
    // So this resolution is the first gate on the whole startup path. Nothing
    // downstream — contract discovery, the engine, the decorators — is reached
    // if it throws.
    //
    // The container mirrors the real one: `injection_module.dart` pre-resolves
    // SharedPreferences during `getIt.init()`, which `preResolve: true` turns
    // into a plain synchronous singleton holding the resolved instance
    // (injectable `get_it_helper.dart:227-235`). Registering it the same way
    // here — resolved value, synchronous binding — is the shape the app has.
    //
    // Before that registration existed this threw, and the throw was swallowed
    // by the try/catch in `SyncSDK.initialize`: the module logged an error and
    // disabled itself, so `AppFeatures.offlineSync = true` produced an app that
    // ran fully online with no crash and no red test.
    expect(di.isRegistered<SharedPreferences>(), isTrue);

    expect(
      () => di<SyncSettingsStore>(),
      returnsNormally,
      reason:
          'SharedPrefsSyncSettingsStore asks the container for SharedPreferences '
          '(sync_bootstrap.dart:75). If this throws, the registration in '
          'injection_module.dart is gone or is no longer @preResolve.',
    );
    expect(di<SyncSettingsStore>(), isA<SharedPrefsSyncSettingsStore>());
  });

  test('production DI pre-resolves SharedPreferences before ModulesBootstrap', () {
    // The behavioural test above describes the shape; this checks the app really
    // has it. `preResolve: true` matters as much as the registration: without
    // it injectable emits `registerLazySingletonAsync`, and the synchronous
    // `getIt()` in sync_bootstrap.dart:75 would fail on "not ready yet" instead.
    //
    // Ordering needs no separate assertion — this runs inside `getIt.init()`,
    // which `configureInjection` awaits before `ModulesBootstrap.initializeAll`.
    final generated =
        File('lib/core/di/injection.config.dart').readAsStringSync();

    expect(
      RegExp(
        r'await gh\.lazySingletonAsync<_i\d+\.SharedPreferences>\('
        r'\s*\(\) => injectableModule\.sharedPreferences,'
        r'\s*preResolve: true,',
      ).hasMatch(generated),
      isTrue,
      reason: 'SharedPreferences is not pre-resolved in the generated DI.',
    );
  });

  test('the generated DI registers every notes sync adapter under its abstract type', () {
    // Source-level, because constructing these needs Dio and a Retrofit service
    // apiece. What matters for discovery is the *type they are bound to* —
    // `getAll<T>()` and `isRegistered<T>()` both key on it, and a missing `as:`
    // is invisible everywhere else.
    final generated =
        File('lib/core/di/injection.config.dart').readAsStringSync();

    for (final binding in const {
      'SyncFeatureContractBase': 'NotesFeatureContract',
      'SyncExecutor': 'NotesSyncExecutor',
      'SyncPullExecutor': 'NotesSyncPullExecutor',
      'SyncRepositoryDecorator': 'NotesSyncRepositoryDecorator',
      'AttachmentUploadTarget': 'NotesAttachmentUploadTarget',
    }.entries) {
      expect(
        RegExp(
          'lazySingleton<_i\\d+\\.${binding.key}>\\('
          '\\s*\\(\\) =>\\s*(const )?_i\\d+\\.${binding.value}\\(',
        ).hasMatch(generated),
        isTrue,
        reason: '${binding.value} is not registered as ${binding.key}. '
            'The module resolves it by the abstract type and will not find it.',
      );
    }
  });
}

class _SilentLogDelegate implements LogDelegate {
  const _SilentLogDelegate();

  @override
  void warning(String message, {String? tag}) {}
  @override
  void info(String message, {String? tag}) {}
  @override
  void debug(String message, {String? tag}) {}
  @override
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
