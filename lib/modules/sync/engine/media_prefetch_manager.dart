import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/foundation/contracts/network_origin.dart';
import 'package:app_template/core/foundation/di/get_it_all_extension.dart';
import 'package:app_template/core/infra/files/server_file_cache.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

import '../config/sync_settings_store.dart';
import '../domain/media_prefetch_status.dart';
import '../domain/sync_media_catalog.dart';

/// **يُنزِّل ما تشير إليه الصفوف من صورٍ وملفّات — طورٌ بذيل دورة المزامنة.**
///
/// ## العطل الذي وُجد له
///
/// «تنزيل بياناتي» كان ينزّل **الصفوف** وحدها. وحقولُ الملفّات تنزل مسارَ
/// تخزينٍ نصّاً لا بايتات، و`ServerFileCache` لا يُنادى إلا بضغطة إصبع — فمن
/// حمّل بياناته بالمكتب ومضى إلى الميدان يجد صورةَ الهوية وعقدَ الإيجار
/// **سطراً يُقرأ ولا يُرى**، ولا شيء بالشاشة قال إن المرفقات لم تنزل. والصورةُ
/// بيتُ القصيد بتطبيقٍ مساحيّ: عليها مدارُ الرفض والقبول.
///
/// ## وأين يقع من الدورة، ولماذا آخراً
///
/// ```
/// دفعٌ ← سحبٌ ← تحديثٌ ← رفعُ ملفّات ← **تنزيلُ ملفّات**
/// ```
///
/// آخرَ الجميع بقصد. **والدفعُ قبله ليس ترتيباً بل شرطاً**: ما كتبه المستخدم
/// يغادر الجهازَ أوّلاً فلا يقف خلف مئةِ ميغابايتٍ نازلة. وهذا الطور **لا يكتب
/// صفّاً واحداً بالقاعدة** — يكتب بايتاتٍ بمجلَّده وحده — فلا سبيل إلى أن يمسّ
/// صفّاً كتبه صاحبُه ولم يُرفع بعد، ولا وظيفةً بالطابور.
///
/// ## وما ينزل هو **الناقص** لا الجرد
///
/// الجردُ يُسأل بكل دورة ([SyncMediaCatalog])، ثم يُطرح منه ما بالقرص
/// (`ServerFileCache.cached`) وما قال الخادمُ إنه ذهب (`ServerFileCache.isGone`).
/// فالباقي وحده يُطلب — **ولا دفترَ ثانٍ يقول «ماذا نزل»** يفترق يوماً عمّا
/// يملكه الجهاز فعلاً.
///
/// وهذا بعينه ما يجعل الاستئنافَ مجّانياً: انقطاعٌ بمنتصف المئة يترك سبعين
/// بالقرص، والجولةُ التالية تسأل عن الثلاثين وحدها. **ولا حالةَ تُصان بينهما.**
///
/// ## والسياسةُ Wi‑Fi وحده — بإذنٍ يُنقض
///
/// `SyncSettings.mediaWifiOnly` مُشعَلٌ افتراضياً، فيقف الطور على بيانات
/// الجوّال ويقول لماذا ([MediaPrefetchPhase.waitingForWifi] مع `onMobileData`).
/// والمستخدم يملك الجوابين: «نزّل الآن» ([approveMobileData]) أو «أجّل»
/// ([postpone]) — والثاني يُستأنف وحدَه بأوّل Wi‑Fi بلا أن يُسأل ثانيةً.
class MediaPrefetchManager {
  MediaPrefetchManager(
    this._getIt,
    this._cache,
    this._connectivity,
    this._settings,
    this._status,
  );

  final GetIt _getIt;
  final ServerFileCache _cache;
  final Connectivity _connectivity;
  final SyncSettingsStore _settings;
  final MediaPrefetchStatus _status;

  static const _tag = 'MEDIA-PREFETCH';

  /// جولةٌ واحدة بكل لحظة — الدورةُ الخلفية وزرُّ «نزّل الآن» قد يلتقيان.
  bool _running = false;

  /// «أجّل» أثناء الجولة — تُقرأ **بين ملفّين**، فيكتمل النازلُ ولا يُبتر.
  bool _postponed = false;

  bool get isRunning => _running;

  /// **كم ملفّاً ينقص الجهازَ — بلا تنزيل.**
  ///
  /// تُنادى بفتح تبويب المزامنة: اللقطة بالذاكرة تُصفَّر بكل إقلاع، ولافتةٌ
  /// تقرأ منها كانت ستختفي عن جهازٍ ينقصه ثمانون ملفاً لمجرّد أن التطبيق
  /// أُعيد فتحُه.
  Future<void> survey() async {
    if (_running) return;
    final pending = await _pending();
    if (pending == null) return;
    _status.emit(
      MediaPrefetchSnapshot(
        phase: pending.files == 0
            ? MediaPrefetchPhase.complete
            : MediaPrefetchPhase.incomplete,
        remaining: pending.files,
      ),
    );
  }

  /// **الجولة** — تُنادى بذيل كل دورة، ومن زرّ «نزّل الآن».
  ///
  /// [ignoreWifiRule] لضغطةٍ صريحة من المستخدم: من ضغط «نزّل الآن» وهو على
  /// بيانات الجوّال أجاب عن السؤال بنفسه، فلا يُسأل ثانيةً بنفس النقرة.
  Future<void> run({bool ignoreWifiRule = false}) async {
    if (_running) return;
    if (_getIt.allOf<SyncMediaCatalog>().isEmpty) return;

    _running = true;
    _postponed = false;
    try {
      await NetworkOrigin.run(NetworkOrigin.sync, () => _run(ignoreWifiRule));
    } catch (error, stackTrace) {
      // **لا يُسقط الدورة**: طورٌ بذيلها، وإخفاقُه يترك الصفوفَ كما نزلت.
      LogService.error(
        'Media prefetch failed — rows are on the device, their files are not.',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _running = false;
    }
  }

  /// **«أجّل»** — يوقف الجولة بين ملفّين، ويُسقط إذنَ بيانات الجوّال.
  ///
  /// وإسقاطُ الإذن جزءٌ من المعنى: من أجّل لا يريد أن تُستأنف الجولةُ نفسُها
  /// بعد ثوانٍ لأن إذناً قديماً ما زال مكتوباً.
  ///
  /// **و`onMobileData: false` بالبثّة الخارجة** — والجهازُ ما زال على بيانات
  /// الجوّال. الحقلُ يقول «هل القرارُ مفتوح؟» لا «أيّةُ شبكةٍ هذه»، وقد بُتّ
  /// للتوّ: بغيرها يُعاد السؤالُ نفسُه فوق الجواب، فيضغط المستخدم «أجّل» ولا
  /// يتبدّل أمامه حرف. والدورةُ التالية تسأل ثانيةً — وذاك موضعُ سؤالٍ آخر.
  Future<void> postpone() async {
    _postponed = true;
    await _settings.setMediaOverMobileApproved(false);
    if (_running) return; // الجولةُ الجارية تبثّ وقوفَها بنفسها.
    _status.emit(
      MediaPrefetchSnapshot(
        phase: MediaPrefetchPhase.waitingForWifi,
        remaining: _status.current.remaining,
      ),
    );
  }

  /// **«نزّل الآن على بيانات الجوّال»** — إذنٌ يبقى حتى يُنقض بـ[postpone].
  Future<void> approveMobileData() =>
      _settings.setMediaOverMobileApproved(true);

  // ── الجولة ────────────────────────────────────────────────────────────────

  Future<void> _run(bool ignoreWifiRule) async {
    final pending = await _pending();
    if (pending == null) return;

    if (pending.files == 0) {
      _status.emit(
        const MediaPrefetchSnapshot(phase: MediaPrefetchPhase.complete),
      );
      return;
    }

    if (!await _mayUseThisNetwork(ignoreWifiRule)) {
      final connected = await _hasNetwork();
      _status.emit(
        MediaPrefetchSnapshot(
          phase: connected
              ? MediaPrefetchPhase.waitingForWifi
              : MediaPrefetchPhase.offline,
          remaining: pending.files,
          // **والخيار يُعرض لمن يملكه وحده**: بلا شبكةٍ أصلاً، زرُّ «نزّل الآن»
          // وعدٌ لا يُنفَّذ.
          onMobileData: connected,
        ),
      );
      LogService.info(
        'Media prefetch is holding ${pending.files} file(s) — '
        '${connected ? 'mobile data, waiting for wifi' : 'offline'}.',
        tag: _tag,
      );
      return;
    }

    final total = pending.files;
    var done = 0;
    var settled = 0;
    var failed = 0;

    LogService.info('Media prefetch started — $total file(s).', tag: _tag);

    for (final target in pending.targets) {
      for (final path in target.paths) {
        if (_postponed) {
          _status.emit(
            MediaPrefetchSnapshot(
              phase: MediaPrefetchPhase.waitingForWifi,
              done: done,
              total: total,
              remaining: total - settled,
              failed: failed,
              // القرارُ بُتّ للتوّ — راجع [postpone].
            ),
          );
          LogService.info(
            'Media prefetch postponed — $done of $total done.',
            tag: _tag,
          );
          return;
        }

        final fetched = await _cache.fetch(path);
        done++;
        switch (fetched.outcome) {
          // **و`notFound` تُحسب واصلة**: الخادم قال إن الملفّ ذهب، وانتظارُه
          // بعدها انتظارُ ما لا يجيء — و`isGone` تمنع سؤاله بالجولة القادمة.
          case ServerFileOutcome.ok:
          case ServerFileOutcome.notFound:
            settled++;
          case ServerFileOutcome.failed:
            failed++;
          case ServerFileOutcome.offline:
            // انقطعت الشبكة بمنتصف الجولة — وما نزل بقي. ولا محاولةَ ثانية
            // الآن: عودةُ الاتصال تُطلق دورةً بنفسها.
            _status.emit(
              MediaPrefetchSnapshot(
                phase: MediaPrefetchPhase.offline,
                done: done,
                total: total,
                remaining: total - settled,
                failed: failed,
              ),
            );
            LogService.info(
              'Media prefetch stopped — the network went away after $done of '
              '$total.',
              tag: _tag,
            );
            return;
        }

        _status.emit(
          MediaPrefetchSnapshot(
            phase: MediaPrefetchPhase.running,
            done: done,
            total: total,
            remaining: total - settled,
            failed: failed,
            groupNumber: target.groupNumber,
            itemNumber: target.itemNumber,
          ),
        );
      }
    }

    final remaining = total - settled;
    _status.emit(
      MediaPrefetchSnapshot(
        phase: remaining == 0
            ? MediaPrefetchPhase.complete
            : MediaPrefetchPhase.incomplete,
        done: done,
        total: total,
        remaining: remaining,
        failed: failed,
      ),
    );
    LogService.info(
      'Media prefetch finished — $settled of $total settled, $failed failed.',
      tag: _tag,
    );
  }

  // ── الجرد ─────────────────────────────────────────────────────────────────

  /// **ما ينقص الجهازَ من الجرد** — و`null` حين لا جردَ يُقرأ أصلاً.
  Future<({List<SyncMediaTarget> targets, int files})?> _pending() async {
    final catalogs = _getIt.allOf<SyncMediaCatalog>().toList();
    if (catalogs.isEmpty) return null;

    final targets = <SyncMediaTarget>[];
    for (final catalog in catalogs) {
      try {
        targets.addAll(await catalog.targets());
      } catch (error, stackTrace) {
        // جردٌ يُخفق لا يُسقط البقيّة — وما لم يُجرد لم يُعدّ، فتبقى الحصيلة
        // ناقصةً بحقّ ولا تُقال «اكتمل».
        LogService.error(
          'Media catalog "${catalog.name}" failed — its files stay unlisted.',
          tag: _tag,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    final pending = <SyncMediaTarget>[];
    var files = 0;
    // **وبلا تكرار**: نفسُ المسار قد يُذكر بصفّين، وطلبُه مرّتين نداءٌ زائد
    // وعدّادٌ يقول أكثر ممّا ينقص.
    final seen = <String>{};
    for (final target in targets) {
      final missing = <String>[];
      for (final raw in target.paths) {
        final path = raw.trim();
        if (path.isEmpty || !seen.add(path)) continue;
        if (_cache.cached(path) != null) continue;
        if (_cache.isGone(path)) continue;
        missing.add(path);
      }
      if (missing.isEmpty) continue;
      files += missing.length;
      pending.add(
        SyncMediaTarget(
          ownerId: target.ownerId,
          paths: missing,
          groupNumber: target.groupNumber,
          itemNumber: target.itemNumber,
        ),
      );
    }
    return (targets: pending, files: files);
  }

  // ── الشبكة ────────────────────────────────────────────────────────────────

  Future<bool> _mayUseThisNetwork(bool ignoreWifiRule) async {
    if (ignoreWifiRule) return true;
    final settings = await _settings.getSettings();
    if (!settings.mediaWifiOnly) return true;
    if (settings.mediaOverMobileApproved) return true;
    return _onWifi();
  }

  /// **وشبكةُ الكيبل واي‑فاي بحكم السؤال**: المقصود «وصلةٌ لا تُحاسَب
  /// بالميغابايت»، لا الراديو بعينه — وجهازٌ بمرسى مكتبيّ يقع بها.
  Future<bool> _onWifi() async {
    final current = await _connectivity.checkConnectivity();
    return current.contains(ConnectivityResult.wifi) ||
        current.contains(ConnectivityResult.ethernet);
  }

  Future<bool> _hasNetwork() async {
    final current = await _connectivity.checkConnectivity();
    return current.any((result) => result != ConnectivityResult.none);
  }
}
