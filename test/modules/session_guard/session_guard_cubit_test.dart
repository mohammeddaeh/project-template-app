import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/core/infra/session/auth_event_bus.dart';
import 'package:app_template/core/infra/session/session_guard_fresh_auth.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/core/platform/biometrics/biometrics_service.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';
import 'package:app_template/modules/session_guard/data/session_guard_pin_store.dart';
import 'package:app_template/modules/session_guard/presentation/cubits/session_guard_cubit.dart';
import 'package:app_template/modules/session_guard/session_guard_config.dart';

class _FakeSecureStorage implements SecureStorageService {
  final Map<String, String> _values = {};
  @override
  Future<void> write(String key, String value) async => _values[key] = value;
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<Map<String, String>> readAll() async => Map.of(_values);
  @override
  Future<void> delete(String key) async => _values.remove(key);
  @override
  Future<void> clear() async => _values.clear();
  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);
}

/// `clearSession()` مُلغِيَة (`late final`) ما لم يُغذَّ توكن — تسجّل بدل ذلك
/// إن نُوديت، وهو كل ما يحتاجه هذا الاختبار.
class _FakeSessionRepository extends SessionRepository {
  _FakeSessionRepository() : super(_FakeSecureStorage());

  bool clearSessionCalled = false;

  @override
  void clearSession() {
    clearSessionCalled = true;
  }
}

class _FakeBiometrics implements BiometricsService {
  _FakeBiometrics({this.available = true, this.enrolled = true, this.result = true});

  final bool available;
  final bool enrolled;
  final bool result;

  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<bool> isEnrolled() async => enrolled;
  @override
  Future<bool> authenticate(String localizedReason) async => result;
}

void main() {
  late _FakeSessionRepository sessionRepository;
  late SessionGuardPinStore pinStore;
  late SessionGuardFreshAuth freshAuth;
  late StreamController<AppLifecycleState> lifecycle;

  setUp(() {
    sessionRepository = _FakeSessionRepository();
    pinStore = SessionGuardPinStore(_FakeSecureStorage());
    freshAuth = SessionGuardFreshAuth();
    lifecycle = StreamController<AppLifecycleState>.broadcast();
    AuthEventBus.instance.resetSessionState();
  });

  tearDown(() => lifecycle.close());

  SessionGuardCubit build({
    BiometricsService? biometrics,
    Duration lockAfter = const Duration(milliseconds: 30),
  }) => SessionGuardCubit(
    pinStore,
    freshAuth,
    sessionRepository,
    lifecycleStream: lifecycle.stream,
    biometrics: biometrics,
    lockAfter: lockAfter,
  );

  group('أول تركيب', () {
    test('لا رقم مسجَّل بعد → needsSetup', () async {
      final cubit = build();
      await pumpEventQueue();
      expect(cubit.state, isA<SessionGuardNeedsSetup>());
      await cubit.close();
    });

    test('رقمٌ موجود وبلا إثبات حضورٍ حيّ → locked (الافتراض الآمن)', () async {
      await pinStore.setPin('4271');
      final cubit = build();
      await pumpEventQueue();
      expect(cubit.state, isA<SessionGuardLocked>());
      await cubit.close();
    });

    test('رقمٌ موجود ودخولٌ بكلمة مرور كُتبت للتوّ → unlocked مرّة واحدة', () async {
      await pinStore.setPin('4271');
      freshAuth.raise();
      final cubit = build();
      await pumpEventQueue();
      expect(cubit.state, isA<SessionGuardUnlocked>());
      await cubit.close();
    });

    test('الراية تُستهلَك — تركيبٌ ثانٍ لا يستفيد منها', () async {
      await pinStore.setPin('4271');
      freshAuth.raise();
      final first = build();
      await pumpEventQueue();
      await first.close();

      final second = build();
      await pumpEventQueue();
      expect(second.state, isA<SessionGuardLocked>());
      await second.close();
    });
  });

  group('دورة الحياة', () {
    test('خلفيةٌ أقصر من الحدّ ثم عودة — تبقى مفتوحة', () async {
      await pinStore.setPin('4271');
      freshAuth.raise();
      final cubit = build(lockAfter: const Duration(seconds: 30));
      await pumpEventQueue();
      expect(cubit.state, isA<SessionGuardUnlocked>());

      lifecycle.add(AppLifecycleState.paused);
      lifecycle.add(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(cubit.state, isA<SessionGuardUnlocked>());
      await cubit.close();
    });

    test('خلفيةٌ أطول من الحدّ ثم عودة — تُقفَل', () async {
      await pinStore.setPin('4271');
      freshAuth.raise();
      // حدٌّ صغيرٌ جداً هنا (لا `SessionGuardConfig.lockAfter` الحقيقي —
      // دقيقتان) كي لا ينتظر الاختبار مدّته الفعلية بكل تشغيل.
      final cubit = build(lockAfter: const Duration(milliseconds: 30));
      await pumpEventQueue();
      expect(cubit.state, isA<SessionGuardUnlocked>());

      lifecycle.add(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      lifecycle.add(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(cubit.state, isA<SessionGuardLocked>());
      await cubit.close();
    });
  });

  group('رقم القفل', () {
    test('رقمٌ صحيح يفتح الجلسة', () async {
      await pinStore.setPin('4271');
      final cubit = build();
      await pumpEventQueue();

      await cubit.verifyPin('4271');
      expect(cubit.state, isA<SessionGuardUnlocked>());
      await cubit.close();
    });

    test('رقمٌ خاطئ يبقيها مقفولة برسالة خطأ', () async {
      await pinStore.setPin('4271');
      final cubit = build();
      await pumpEventQueue();

      await cubit.verifyPin('0000');
      final state = cubit.state;
      expect(state, isA<SessionGuardLocked>());
      expect((state as SessionGuardLocked).wrongAttempt, isTrue);
      expect(sessionRepository.clearSessionCalled, isFalse);
      await cubit.close();
    });

    test(
      'تجاوز الحدّ الأقصى من المحاولات الخاطئة يمسح الجلسة تماماً — لا قفلاً إضافياً',
      () async {
        await pinStore.setPin('4271');
        final cubit = build();
        await pumpEventQueue();

        AuthEvent? emitted;
        final sub = AuthEventBus.instance.stream.listen((e) => emitted = e);

        for (var i = 0; i < SessionGuardConfig.maxWrongAttempts; i++) {
          await cubit.verifyPin('0000');
        }
        // بثُّ StreamController.add يُسلَّم بمهمّةٍ مصغَّرة (microtask) لا
        // فوراً — بلا هذا السطر يقرأ الاختبار `emitted` قبل أن يصل الحدث.
        await pumpEventQueue();

        expect(sessionRepository.clearSessionCalled, isTrue);
        expect(emitted, AuthEvent.sessionExpired);
        await sub.cancel();
        await cubit.close();
      },
    );
  });

  group('البصمة', () {
    test('canUseBiometrics false بلا خدمة مسجَّلة', () async {
      final cubit = build();
      expect(cubit.canUseBiometrics, isFalse);
      await cubit.close();
    });

    test('بصمة ناجحة تفتح الجلسة', () async {
      await pinStore.setPin('4271');
      final cubit = build(biometrics: _FakeBiometrics());
      await pumpEventQueue();

      final ok = await cubit.unlockWithBiometrics('reason');
      expect(ok, isTrue);
      expect(cubit.state, isA<SessionGuardUnlocked>());
      await cubit.close();
    });

    test('بصمة غير متاحة بالجهاز تعود false ولا تفتح شيئاً', () async {
      await pinStore.setPin('4271');
      final cubit = build(biometrics: _FakeBiometrics(available: false));
      await pumpEventQueue();

      final ok = await cubit.unlockWithBiometrics('reason');
      expect(ok, isFalse);
      expect(cubit.state, isA<SessionGuardLocked>());
      await cubit.close();
    });

    test('بصمة متاحة لكن غير مُسجَّلة بالجهاز تعود false كذلك', () async {
      await pinStore.setPin('4271');
      final cubit = build(biometrics: _FakeBiometrics(enrolled: false));
      await pumpEventQueue();

      final ok = await cubit.unlockWithBiometrics('reason');
      expect(ok, isFalse);
      expect(cubit.state, isA<SessionGuardLocked>());
      await cubit.close();
    });

    test('رفض المستخدم لطلب البصمة يعود false ويُبقي القفل', () async {
      await pinStore.setPin('4271');
      final cubit = build(biometrics: _FakeBiometrics(result: false));
      await pumpEventQueue();

      final ok = await cubit.unlockWithBiometrics('reason');
      expect(ok, isFalse);
      expect(cubit.state, isA<SessionGuardLocked>());
      await cubit.close();
    });
  });

  test('إعداد رقمٍ جديد يفتح الجلسة مباشرة', () async {
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state, isA<SessionGuardNeedsSetup>());

    await cubit.setPin('9999');
    expect(cubit.state, isA<SessionGuardUnlocked>());
    expect(await pinStore.verify('9999'), isTrue);
    await cubit.close();
  });
}
