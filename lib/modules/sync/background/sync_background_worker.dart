import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/sync/integration/sync_bootstrap.dart';
import 'package:app_template/modules/sync/integration/sync_controller.dart';

/// **رفعُ الطابور والتطبيقُ مغلق — أندرويد وحده.**
///
/// ## العطل الذي وُجد له
///
/// دورةُ المزامنة تعمل بمؤقّتٍ ومستمعِ اتصالٍ **داخل العملية**، فتتوقّف بتوقّف
/// التطبيق. وسيناريو الميدان يجعل ذلك مكلفاً:
///
/// > يملأ المدقّق سبعةَ مقاسم بمنطقةٍ بلا تغطية، ويحفظها مسوّدات، **ويُغلق
/// > التطبيق** ويركب سيارته. تمرّ التغطية بالطريق — ولا شيء يرفع. يصل المكتب
/// > بعد ساعتين، وشغلُه ما زال على جهازه، وهو يظنّه وصل.
///
/// ## ولماذا أندرويد وحده
///
/// `WorkManager` يعطي **ضماناتٍ حقيقية**: العملُ ينجو من إغلاق التطبيق ومن
/// إعادة تشغيل الجهاز، ويُقيَّد بتوفّر الشبكة، ويُعاد جدولتُه بنفسه.
///
/// و iOS لا يعطي ذلك: `BGTaskScheduler` **«أفضلُ جهد»** — النظام يقرّر متى
/// يُوقظ حسب عادات الاستعمال والبطارية، وقد لا يوقظ يوماً كاملاً. **ووعدٌ لا
/// يُوفى أسوأ من غيابه**: لافتةٌ تقول «سيكمل الرفع لاحقاً» تجعل المستخدم يُغلق
/// التطبيق واثقاً ويمضي. فيُقال له على iOS الحقيقةُ بدلاً منها — «أبقِ التطبيق
/// مفتوحاً» (`SyncKeepOpenNotice`).
///
/// ## ⚠️ والمَعزل الثاني يبني كلَّ شيءٍ من جديد
///
/// `WorkManager` يُشغّل [callbackDispatcher] بـ**isolate جديد بآلة Dart
/// نظيفة**: لا `getIt` مُهيّأ، ولا Hive مفتوح، ولا `Env`. فما يفعله
/// [_runCycle] ليس ترفاً — هو الحدُّ الأدنى الذي بدونه يرمي أوّلُ سطر.
///
/// **ولا `EasyLocalization` ولا ثيم ولا خطوط**: لا شاشةَ هنا، ولا نصَّ يُعرض.
/// وتحميلُها كان يضيف ثوانيَ إلى مهمّةٍ يقيس النظامُ زمنَها ويعاقب طولَها.
abstract final class SyncBackgroundWorker {
  /// اسمُ المهمّة الدورية — **ثابتٌ**، فإعادةُ الجدولة تستبدل ولا تُراكم.
  static const _periodicName = 'app.sync.periodic';
  static const _oneOffName = 'app.sync.oneoff';
  static const _tag = 'SYNC-BG';

  /// **أقلُّ ما يقبله أندرويد للمهمّة الدورية** — خمسَ عشرةَ دقيقة.
  ///
  /// وطلبُ أقلَّ منه لا يُخفق: النظام **يرفعه بصمت** إلى الربع ساعة. فكتابةُ
  /// الرقم الحقيقي هنا تمنع توقّعاً لا يتحقّق.
  static const _period = Duration(minutes: 15);

  static bool get isSupported => Platform.isAndroid;

  /// يُنادى من `main()` بعد `configureInjection` — ولا يفعل شيئاً على iOS.
  static Future<void> initialize() async {
    if (!isSupported) return;
    try {
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerPeriodicTask(
        _periodicName,
        _periodicName,
        frequency: _period,
        // **الشبكةُ شرطٌ يفرضه النظام لا نحن.** فحصُها بأنفسنا يعني إيقاظَ
        // الجهاز ليكتشف أنه بلا شبكة ثم ينام — والنظام يستطيع ألّا يوقظه أصلاً.
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
      LogService.info(
        'Background sync scheduled every ${_period.inMinutes} minutes.',
        tag: _tag,
      );
    } catch (error, stackTrace) {
      // **إخفاقُ الجدولة لا يمنع التطبيق من العمل.** الدورةُ داخل العملية
      // تبقى قائمة، وما يُفقد هو الرفع والتطبيقُ مغلق — وذلك حالُ iOS أصلاً.
      LogService.error(
        'Scheduling background sync failed — the in-process cycle still runs.',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// **يستعجل دورةً بالخلفية** — يُنادى بعد كتابةٍ محلّية.
  ///
  /// والدوريّةُ كلَّ ربع ساعة أبطأُ من أن تكون الجوابَ الوحيد: من حفظ مسوّدةً
  /// ثم أغلق التطبيق فوراً كان ينتظر خمسَ عشرةَ دقيقةً بلا سبب.
  static Future<void> requestOneOff() async {
    if (!isSupported) return;
    try {
      await Workmanager().registerOneOffTask(
        _oneOffName,
        _oneOffName,
        constraints: Constraints(networkType: NetworkType.connected),
        // **يُستبدل ولا يُراكم**: عشرُ حفظاتٍ متتالية كانت ستُدرج عشرَ مهمّات
        // تفعل الشيء نفسه.
        existingWorkPolicy: ExistingWorkPolicy.replace,
        initialDelay: const Duration(seconds: 10),
      );
    } catch (error) {
      LogService.warning(
        'One-off background sync not queued: $error',
        tag: _tag,
      );
    }
  }

  /// يُلغى عند الخروج — لا شيء يُرفع لحسابٍ غادر.
  static Future<void> cancelAll() async {
    if (!isSupported) return;
    try {
      await Workmanager().cancelAll();
    } catch (error) {
      LogService.warning(
        'Cancelling background sync failed: $error',
        tag: _tag,
      );
    }
  }
}

/// **نقطةُ دخول المَعزل الثاني** — و`@pragma` إلزاميّ.
///
/// بدونه يحذف مُصرِّفُ AOT هذه الدالّة لأنها بلا مستدعٍ بالكود، فتُخفق المهمّة
/// وقتَ التشغيل بـ«لا نقطةَ دخول» — على نسخة الإصدار وحدها، لا بالتطوير.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) => _runCycle(task));
}

/// دورةٌ واحدة بمَعزلٍ نظيف — **وتُعيد `false` ليُعاد جدولتُها**.
///
/// و`true` تعني «تمّ ولا تُعده». فإخفاقُ شبكةٍ عابر يُعيد `false` فيتولّى
/// `WorkManager` التراجعَ الأسّي بنفسه — وهو أدرى منّا: يعرف حالةَ البطارية
/// والشبكة وبقيّةَ ما ينتظر بالجهاز.
Future<bool> _runCycle(String task) async {
  // إلزاميّ قبل أي إضافةٍ تمرّ بقناة المنصّة — و`sqflite` و`secure_storage`
  // كلاهما كذلك.
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
    Env.init();
    await configureInjection(Env.flavor);
    await registerSyncCore(getIt);

    final controller = getIt<SyncController>();
    // **البوّابةُ تُسأل هنا كما تُسأل بالمقدّمة** — لا جلسة ⇒ لا دورة. وتوكنٌ
    // منتهٍ بالخلفية يُنتج 401 لكل صفّ، ويستهلك محاولاتِ عملٍ سليم حتى يموت.
    final reason = await controller.triggerManualSync();

    // **ومرفوضٌ ليس فاشلاً.** إعادةُ `false` تجعل `WorkManager` يتراجع أسّياً
    // على «لا جلسة» — وهي حالةٌ لا يُصلحها الانتظار بل دخولُ المستخدم. و`true`
    // تعني «تمّ ولا تُعده»، والدوريّةُ تعود بعد ربع ساعة على أي حال.
    //
    // والسببُ يُسجَّل باسمه إن رُفضت الدورة — لا يُلقى بعد أن صار متاحاً.
    if (reason != null) {
      LogService.debug(
        'Background cycle skipped — ${reason.name}.',
        tag: 'SYNC-BG',
      );
    }
    return true;
  } catch (error, stackTrace) {
    LogService.error(
      'Background cycle "$task" threw.',
      tag: 'SYNC-BG',
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  }
}
