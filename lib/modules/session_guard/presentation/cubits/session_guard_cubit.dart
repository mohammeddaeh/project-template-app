import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/infra/session/auth_event_bus.dart';
import 'package:app_template/core/infra/session/session_guard_fresh_auth.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/core/platform/biometrics/biometrics_service.dart';
import 'package:app_template/modules/session_guard/data/session_guard_pin_store.dart';
import 'package:app_template/modules/session_guard/session_guard_config.dart';

part 'session_guard_cubit.freezed.dart';
part 'session_guard_state.dart';

/// يقفل الجلسة عند العودة من خلفيةٍ طالت، ويفتحها ببصمةٍ أو رقمٍ محلّي —
/// **دون تسجيل خروجٍ كامل**. راجع `lib/modules/session_guard/SETUP.md`.
///
/// ## لماذا مقفولةٌ افتراضياً عند أوّل تركيب، لا مفتوحة
///
/// إقلاعٌ باردٌ يستعيد توكناً محفوظاً (`StartupResolver`) لا يثبت أن **صاحب
/// الحساب** هو من يحمل الجهاز الآن — يثبت فقط أن توكناً صالحاً محفوظ عليه.
/// فالافتراض الآمن قفلٌ حتى يُثبَت العكس، لا العكس.
///
/// **والاستثناء الوحيد**: دخولٌ بكلمة مرورٍ كُتبت للتوّ يرفع [SessionGuardFreshAuth]
/// — إثباتُ حضورٍ أقوى من أي قفلٍ محلّي، فلا داعي لمطالبة صاحبه به مرّتين
/// خلال ثوانٍ.
class SessionGuardCubit extends SafeCubit<SessionGuardState> {
  SessionGuardCubit(
    this._pinStore,
    this._freshAuth,
    this._sessionRepository, {
    required Stream<AppLifecycleState> lifecycleStream,
    BiometricsService? biometrics,
    Duration lockAfter = SessionGuardConfig.lockAfter,
  }) : _biometrics = biometrics,
       _lockAfter = lockAfter,
       super(const SessionGuardState.checking()) {
    _init();
    _lifecycleSub = lifecycleStream.listen(_onLifecycleChange);
  }

  final SessionGuardPinStore _pinStore;
  final SessionGuardFreshAuth _freshAuth;
  final SessionRepository _sessionRepository;
  final BiometricsService? _biometrics;

  /// معاملُ بناءٍ لا ثابتاً مباشراً — **لأجل الاختبار وحده**: اختبار القفل
  /// الحقيقي بمدّة `SessionGuardConfig.lockAfter` (دقيقتان) يعني انتظاراً
  /// حقيقياً بنفس الطول بكل تشغيل اختبار. الإنتاج يستعمل القيمة الافتراضية
  /// دوماً؛ لا مكان بالتطبيق يمرّر شيئاً آخر.
  final Duration _lockAfter;

  StreamSubscription<AppLifecycleState>? _lifecycleSub;
  DateTime? _backgroundedAt;
  int _wrongAttempts = 0;

  bool get canUseBiometrics => _biometrics != null;

  Future<void> _init() async {
    final hasPin = await _pinStore.hasPin();
    if (!hasPin) {
      emit(const SessionGuardState.needsSetup());
      return;
    }
    if (_freshAuth.take()) {
      emit(const SessionGuardState.unlocked());
      return;
    }
    emit(const SessionGuardState.locked());
  }

  void _onLifecycleChange(AppLifecycleState lifecycleState) {
    // متجاهَلةٌ أثناء الإعداد الأول: مقاطعةُ من يكتب رقمَه بحوارٍ عابر
    // (مثلاً لإذنٍ) بشاشة قفلٍ لا فائدة منها — لا رقم محفوظاً بعد أصلاً.
    if (state is SessionGuardNeedsSetup) return;

    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive) {
      _backgroundedAt ??= DateTime.now();
      return;
    }

    if (lifecycleState != AppLifecycleState.resumed) return;
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) return;
    if (state is SessionGuardLocked) return;

    if (DateTime.now().difference(backgroundedAt) >= _lockAfter) {
      emit(const SessionGuardState.locked());
    }
  }

  /// `false` فوراً إن كانت البصمة غير مسجَّلة بالـDI (العلَم `biometrics`
  /// مطفأ) أو غير متاحة/غير مُعدَّة بهذا الجهاز — بلا استثناء يُربك المستدعي.
  Future<bool> unlockWithBiometrics(String reason) async {
    final biometrics = _biometrics;
    if (biometrics == null) return false;
    if (!await biometrics.isAvailable() || !await biometrics.isEnrolled()) {
      return false;
    }
    final ok = await biometrics.authenticate(reason);
    if (ok) {
      _wrongAttempts = 0;
      emit(const SessionGuardState.unlocked());
    }
    return ok;
  }

  /// عند تجاوز [SessionGuardConfig.maxWrongAttempts] يمسح الجلسة تماماً
  /// ويُصدر [AuthEvent.sessionExpired] — **تسجيل خروجٍ حقيقي لا قفلٌ مؤقّت
  /// آخر**، لأن مساحة تخمين رقمٍ قصير لا تحتمل محاولاتٍ غير محدودة. راجع
  /// [SessionGuardConfig.maxWrongAttempts] لسبب هذا الاختيار تحديداً.
  Future<void> verifyPin(String pin) async {
    final ok = await _pinStore.verify(pin);
    if (ok) {
      _wrongAttempts = 0;
      emit(const SessionGuardState.unlocked());
      return;
    }

    _wrongAttempts++;
    if (_wrongAttempts >= SessionGuardConfig.maxWrongAttempts) {
      _sessionRepository.clearSession();
      AuthEventBus.instance.emit(AuthEvent.sessionExpired);
      return;
    }
    emit(const SessionGuardState.locked(wrongAttempt: true));
  }

  Future<void> setPin(String pin) async {
    await _pinStore.setPin(pin);
    _wrongAttempts = 0;
    emit(const SessionGuardState.unlocked());
  }

  @override
  Future<void> close() {
    unawaited(_lifecycleSub?.cancel());
    return super.close();
  }
}
