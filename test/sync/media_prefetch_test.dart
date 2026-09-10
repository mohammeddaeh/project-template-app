import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/modules/sync/config/sync_settings.dart';
import 'package:app_template/modules/sync/config/sync_mode.dart';
import 'package:app_template/modules/sync/domain/media_prefetch_status.dart';

/// **تنزيلُ الصور والملفّات — وسياستُه معكوسةٌ عن الرفع بقصد.**
///
/// والعطلُ الذي وُجد له: السحبُ ينزّل **الصفوف** وحدها، وحقولُ الملفّات تنزل
/// مسارَ تخزينٍ نصّاً لا بايتات. فمن حمّل بياناته بالمكتب ومضى إلى الميدان يجد
/// المرفقات **سطراً يُقرأ ولا يُرى**، ولا شيء بالشاشة قال ذلك.
void main() {
  test('media waits for Wi-Fi by default — the push does not', () {
    const settings = SyncSettings(
      mode: SyncMode.active,
      syncEnabled: true,
      wifiOnly: false,
      periodicIntervalSeconds: null,
    );

    // **والافتراضان معكوسان لأن السؤالين معكوسان**: الدفعُ حمولتُه كتابةُ
    // مستخدمٍ لا تصل الخادمَ إن لم تُرفع، والسحبُ حمولتُه ملفّاتٌ يملكها الخادم
    // أصلاً وتأخيرُها ساعةً لا يُضيّع شيئاً.
    expect(settings.wifiOnly, isFalse, reason: 'pushing must not wait');
    expect(settings.mediaWifiOnly, isTrue, reason: 'downloading may wait');
  });

  test('mobile-data permission starts withheld, and is the user\'s to give', () {
    const settings = SyncSettings(
      mode: SyncMode.active,
      syncEnabled: true,
      wifiOnly: false,
      periodicIntervalSeconds: null,
    );

    expect(settings.mediaOverMobileApproved, isFalse);
  });

  test('stopping is a state that is broadcast, not an empty screen', () {
    // «هل نزلت الصور؟» سؤالٌ يُسأل قبل الخروج إلى الميدان، وشاشةٌ تسكت عنه
    // تُقرأ «لا أعرف».
    expect(MediaPrefetchPhase.values, contains(MediaPrefetchPhase.complete));
    expect(
      MediaPrefetchPhase.values,
      contains(MediaPrefetchPhase.waitingForWifi),
    );
  });

  test('a snapshot on mobile data says so — a dead button is worse than none', () {
    const onMobile = MediaPrefetchSnapshot(
      phase: MediaPrefetchPhase.waitingForWifi,
      remaining: 80,
      onMobileData: true,
    );
    const noNetwork = MediaPrefetchSnapshot(
      phase: MediaPrefetchPhase.waitingForWifi,
      remaining: 80,
    );

    // `onMobileData` هي الحَكَمُ على رسم الزرّ لا لونُ الحالة: من لا شبكةَ له
    // يُعطى خبراً بلا فعل، ومن على بيانات الجوّال يُعطى سؤالاً بجوابين.
    expect(onMobile.onMobileData, isTrue);
    expect(noNetwork.onMobileData, isFalse);
  });

  test('the catalogue belongs to the feature, the manager only downloads', () {
    // `modules → features ❌`: الموديول لا يعرف أين تسكن مساراتُ الشريحة.
    final contract = File(
      'lib/modules/sync/domain/sync_media_catalog.dart',
    ).readAsStringSync();

    expect(contract, contains('abstract class SyncMediaCatalog'));
    expect(
      contract,
      contains('targets()'),
      reason: 'the feature answers where its files are',
    );
  });

  test('no catalogue registered means the phase is a no-op, not a throw', () {
    final src = File(
      'lib/modules/sync/engine/media_prefetch_manager.dart',
    ).readAsStringSync();

    // `getAll` ترمي على الفراغ — ومشروعٌ بلا جردٍ كان سيُسقط ذيلَ كل دورة.
    expect(src, contains('allOf<SyncMediaCatalog>().isEmpty'));
    expect(src.contains('getAll<SyncMediaCatalog>()'), isFalse);
  });

  test('the engine runs it outside the lock, and after the stamp', () {
    final engine = File(
      'lib/modules/sync/engine/sync_engine.dart',
    ).readAsStringSync();

    final stampAt = engine.indexOf('_cycleStamp.markSuccess()');
    final releaseAt = engine.indexOf('_syncLock.release()', stampAt);
    // **النداءُ لا التعريف**: `_processMediaDownloads()` يظهر مرّتين، وتعريفُ
    // الدالّة يقع بعد الإفراج كذلك — فقياسٌ على الاسم وحده يمرّ بلا نداءٍ أصلاً.
    final mediaAt = engine.indexOf('await _processMediaDownloads();', stampAt);

    // وحبسُه تحت القفل كان يعني أن صفّاً يحفظه المستخدم الآن ينتظر مئةَ
    // ميغابايتٍ تنزل قبل أن يُدفع — نقيضُ «الدفعُ أوّلاً».
    expect(stampAt, greaterThan(-1));
    expect(mediaAt, greaterThan(-1), reason: 'the phase is never called');
    expect(mediaAt, greaterThan(releaseAt), reason: 'must run after release');
  });
}
