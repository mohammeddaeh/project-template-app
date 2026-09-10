import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:app_template/core/platform/connectivity/connectivity_service.dart';
import 'package:app_template/core/platform/lifecycle/app_lifecycle_service.dart';

import '../config/sync_mode.dart';
import '../config/sync_settings_store.dart';
import '../domain/sync_queue_signal.dart';
import '../engine/sync_engine.dart';
import 'sync_gate.dart';

/// Triggers [SyncEngine.runPendingJobs] when:
/// - **عملٌ يدخل الطابور** — `SyncQueueSignal`، والكاتب يُعلن ولا يُسأل.
/// - Network connectivity is restored.
/// - A periodic timer fires.
/// - Caller invokes [triggerManualSync].
/// - **لفتةُ المستخدم** — عودةُ التطبيق إلى المقدّمة، أو ضغطةُ تبويبٍ يقرأ
///   بيانات. راجع [checkIfStale].
///
/// ✅ Uses [ConnectivityService.isOnline] (template abstraction) instead of
///    raw `internet_connection_checker` to stay within the platform layer contract.
class SyncController {
  SyncController(
    this._settingsStore,
    this._connectivity,
    this._syncEngine,
    this._gate,
    this._queueSignal,
    this._lifecycle,
  );

  final SyncSettingsStore _settingsStore;
  final Connectivity _connectivity;
  final SyncEngine _syncEngine;
  final SyncGate _gate;
  final SyncQueueSignal _queueSignal;
  /// **اختياريةٌ بقصد**: تُسجَّل تحت `AppFeatures.appLifecycle` وحده، ومشروعٌ
  /// يُطفئه لا يملك الخدمة أصلاً. وحقنُها إلزامياً كان يجعل الموديولَ يسقط
  /// لعلَمٍ **لا شأنَ له به** — و`null` تعني «لا مُطلِقَ بالعودة»، لا خطأً.
  final AppLifecycleService? _lifecycle;

  StreamSubscription<AppLifecycleState>? _resumeSubscription;

  /// متى بدأت آخرُ دورةٍ **جرت فعلاً** — لا آخرُ محاولةٍ رُفضت.
  ///
  /// وبالذاكرة لا بالقرص بقصد: إقلاعُ التطبيق يُطلق دورتَه بنفسه، فختمٌ يعيش
  /// بعد الإقلاع كان سيُسكت أوّلَ تشييكٍ بجلسةٍ جديدة.
  DateTime? _lastCycleAt;

  /// كم تبقى حصيلةُ آخر دورةٍ «طازجة» — راجع [checkIfStale].
  ///
  /// تسعون ثانية: أطولُ من تنقّلٍ عصبيٍّ بين التبويبات، وأقصرُ من أن يفوت
  /// المستخدمَ تغيُّرٌ يهمّه.
  static const freshnessWindow = Duration(seconds: 90);

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<void>? _queueSubscription;
  Timer? _periodicTimer;

  /// **ثلاثُ ثوانٍ من الهدوء، لا لحظةُ الحدث.**
  ///
  /// و`onConnectivityChanged` يُطلق مع **كل** تبدّل: انتقالٌ من واي‑فاي إلى
  /// بيانات الهاتف يُطلق حدثين، والمرورُ بجوار نقطة وصولٍ ضعيفة يُطلق سلسلة.
  /// وكلُّ حدثٍ كان يبدأ دورةً كاملة — فتُخفق على وصلةٍ لم تستقرّ، ويرتفع
  /// `retry_count` لصفوفٍ لا عيب فيها.
  ///
  /// وهي **نفسُها** نافذةُ خنق الطابور: حفظُ استمارةٍ واحدة يكتب السجلَّ
  /// وأبناءَه ومرفقاتِه — عشرةَ صفوفٍ خلال أجزاء من الثانية. وبلا تجميعها تصير
  /// عشرَ دوراتٍ متتابعة، تسعٌ منها تجد القفل مأخوذاً وتنصرف.
  static const _stabilityWindow = Duration(seconds: 3);

  Timer? _stabilityTimer;

  Future<void> init() async {
    await _bindConnectivity();
    _bindQueue();
    _bindResume();
    await _setupPeriodic();
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _queueSubscription?.cancel();
    await _resumeSubscription?.cancel();
    _periodicTimer?.cancel();
    _stabilityTimer?.cancel();
  }

  /// **دخولُ عملٍ الطابور يُطلق دورة** — وهو المُطلِق الذي كان ناقصاً.
  void _bindQueue() {
    _queueSubscription?.cancel();
    _queueSubscription = _queueSignal.stream.listen((_) => _scheduleSoon());
  }

  /// كلُّ نداءٍ جديد يُلغي انتظارَ سابقه ويبدأ العدّ من جديد — فسلسلةٌ متلاحقة
  /// تُنتج **محاولةً واحدة** بعد أن تهدأ، لا محاولةً لكل ذبذبة.
  void _scheduleSoon() {
    _stabilityTimer?.cancel();
    _stabilityTimer = Timer(_stabilityWindow, () async {
      if (await _canSyncNow()) {
        await _runCycleNow();
      }
    });
  }

  Future<void> triggerManualSync() async {
    if (await _canSyncNow()) {
      await _runCycleNow();
    }
  }

  /// **لفتةُ المستخدم** — المُطلِقُ الذي يكشف تغيُّراً وقع **عند الخادم**.
  ///
  /// ## ولماذا لزم أصلاً
  ///
  /// المُطلِقاتُ الأخرى تُطلق كلُّها بحدثٍ يقع **بالجهاز**: شبكةٌ تبدّلت، أو
  /// كتابةٌ حُفظت، أو زرٌّ ضُغط. ولا واحدَ منها يقع حين يتغيّر شيءٌ عند الخادم —
  /// فجهازٌ متّصلٌ ساكن لا يجد ما يُنزل تغييراً وقع الآن، ويبقى ما يعرضه قديماً
  /// حتى تقع مصادفةٌ من غيرها.
  ///
  /// ويُنادى من موضعين:
  ///
  /// | الموضع | لماذا هو الموضع |
  /// |---|---|
  /// | عودةُ التطبيق إلى المقدّمة | **الأشيَع**: يُخرج المستخدم هاتفَه فيفتح على الشاشة نفسِها — فلا ضغطةَ تقع. موصولٌ هنا بـ[_bindResume] |
  /// | ضغطةُ تبويبٍ يقرأ بيانات | من فتح قائمةً يسأل عن حالتها الآن. **يناديه المشروع** من `NavItem.onSelected` أو ما يقابله |
  ///
  /// ## ونافذةُ الطزاجة ليست تحسيناً
  ///
  /// قفلُ المزامنة يمنع **التداخل** لا **التكرار**: مستخدمٌ يتنقّل بين
  /// التبويبات عشر مرّات بدقيقة كان سيُنتج عشرَ دوراتٍ متتابعة، كلُّ واحدةٍ
  /// منها نداءُ شبكةٍ على بيانات الجوّال.
  ///
  /// **ولا يُعيد سببَ منع** خلافاً لـ[triggerManualSync]: من ضغط تبويباً لم
  /// يطلب مزامنةً، فلا لافتةَ تُعرض له ولا رسالة.
  Future<void> checkIfStale() async {
    final last = _lastCycleAt;
    if (last != null && DateTime.now().difference(last) < freshnessWindow) {
      return;
    }
    if (!await _canSyncNow()) return;
    await _runCycleNow();
  }

  /// كلُّ مسارٍ يُشغّل دورةً يمرّ من هنا — فالختمُ لا يُنسى بأحدها.
  Future<void> _runCycleNow() async {
    _lastCycleAt = DateTime.now();
    await _syncEngine.runPendingJobs();
  }

  void _bindResume() {
    final lifecycle = _lifecycle;
    if (lifecycle == null) return;
    _resumeSubscription?.cancel();
    _resumeSubscription = lifecycle.stateStream.listen((state) {
      if (state == AppLifecycleState.resumed) unawaited(checkIfStale());
    });
  }

  Future<void> _bindConnectivity() async {
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((_) => _scheduleSoon());
  }

  Future<void> _setupPeriodic() async {
    _periodicTimer?.cancel();
    final settings = await _settingsStore.getSettings();
    final seconds = settings.periodicIntervalSeconds;
    if (settings.mode != SyncMode.active ||
        !settings.syncEnabled ||
        seconds == null ||
        seconds <= 0) {
      return;
    }
    _periodicTimer = Timer.periodic(Duration(seconds: seconds), (_) async {
      if (await _canSyncNow()) {
        await _runCycleNow();
      }
    });
  }

  /// Delegates to [SyncGate], which asks more than connectivity — and says why
  /// when it refuses. See that class for what it checks and what it does not.
  Future<bool> _canSyncNow() => _gate.allows();
}
