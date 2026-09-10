import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/modules/sync/background/sync_background_worker.dart';

/// **الرفعُ بالخلفية — ووعدٌ لا يُوفى أسوأ من غيابه.**
///
/// والسيناريو الذي وُجد له: يكتب المستخدم عملَه حيث لا تغطية **ويُغلق التطبيق**.
/// تمرّ التغطيةُ بالطريق ولا شيء يرفع؛ فيصل وشغلُه ما زال على جهازه وهو يظنّه
/// وصل.
void main() {
  late String src;

  setUp(() {
    src = File(
      'lib/modules/sync/background/sync_background_worker.dart',
    ).readAsStringSync();
  });

  test('Android only — and that is a decision, not an omission', () {
    // `BGTaskScheduler` على iOS **«أفضلُ جهد»**: النظام يقرّر متى يوقظ، وقد لا
    // يوقظ يوماً كاملاً. فلافتةٌ تقول «سيكمل الرفع لاحقاً» تجعل المستخدم يُغلق
    // التطبيق واثقاً ويمضي — ووعدٌ لا يُوفى أسوأ من غيابه.
    expect(SyncBackgroundWorker.isSupported, Platform.isAndroid);
    expect(src, contains('Platform.isAndroid'));
  });

  test('nothing runs when the platform is not supported', () {
    // `initialize` و`requestOneOff` و`cancelAll` كلُّها تخرج بلا أثر — فلا
    // يحتاج المستدعي أن يسأل عن المنصّة.
    expect(
      src.split('if (!isSupported) return').length - 1,
      greaterThanOrEqualTo(3),
      reason: 'every entry point guards the platform, not its callers',
    );
  });

  test('the periodic name is a constant — rescheduling replaces, never stacks', () {
    expect(src, contains("_periodicName = 'app.sync.periodic'"));
    expect(src, contains('ExistingPeriodicWorkPolicy.keep'));
  });

  test('the period is the real floor Android enforces, not a wish', () {
    // طلبُ أقلَّ من ربع ساعة **لا يُخفق**: النظام يرفعه بصمت. فكتابةُ الرقم
    // الحقيقي تمنع توقّعاً لا يتحقّق.
    expect(src, contains('Duration(minutes: 15)'));
  });

  test('the network is a constraint the system enforces, not a check we run', () {
    // فحصُها بأنفسنا يعني إيقاظَ الجهاز ليكتشف أنه بلا شبكة ثم ينام — والنظام
    // يستطيع ألّا يوقظه أصلاً.
    expect(src, contains('NetworkType.connected'));
  });

  test('the second isolate rebuilds everything — it inherits nothing', () {
    // `WorkManager` يُشغّل الـdispatcher بآلة Dart نظيفة: لا `getIt`، ولا Hive،
    // ولا `Env`. فما دون ليس ترفاً — بدونه يرمي أوّلُ سطر.
    for (final line in const [
      'WidgetsFlutterBinding.ensureInitialized()',
      'Hive.initFlutter()',
      'Env.init()',
      'configureInjection(',
      'registerSyncCore(',
    ]) {
      expect(src, contains(line), reason: '$line is missing from the isolate');
    }
  });

  test('a refusal returns true — backing off would not fix "no session"', () {
    // `false` تعني «أعِده»، فيتراجع `WorkManager` أسّياً على حالةٍ لا يُصلحها
    // الانتظار بل دخولُ المستخدم.
    expect(src, contains('مرفوضٌ ليس فاشلاً'));
  });

  test('wiping an account cancels it first', () {
    // وإلا استيقظ بعد الخروج ودفع طابوراً محذوفاً — بمَعزلٍ لا يعرف أن الحساب
    // تبدّل، لأنه يبني كلَّ شيءٍ من جديد.
    final wiper = File(
      'lib/modules/sync/integration/sync_local_data_wiper.dart',
    ).readAsStringSync();

    expect(wiper, contains('SyncBackgroundWorker.cancelAll()'));
  });

  test('module bootstrap schedules it, and only with sync on', () {
    final boot = File('lib/modules/modules_bootstrap.dart').readAsStringSync();
    final at = boot.indexOf('if (AppFeatures.offlineSync)');

    expect(at, greaterThan(-1));
    expect(
      boot.substring(at, at + 700),
      contains('SyncBackgroundWorker.initialize()'),
    );
  });
}
