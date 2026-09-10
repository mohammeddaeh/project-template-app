import 'dart:convert';

import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';

/// **آخرُ ردٍّ ناجح، يُعاد حين ترفض الشبكة.**
///
/// ```dart
/// final snapshot = OfflineSnapshot<AccountOverview>(
///   storage: storage,
///   key: PersistenceKeys.accountOverviewSnapshot,   // مفتاحُ مشروعك
///   encode: (o) => AccountOverviewModel.fromEntity(o).toJson(),
///   decode: (json) => AccountOverviewModel.fromJson(json).toEntity(),
///   tag: 'ACCOUNT',
/// );
/// ```
///
/// ## لماذا صنفٌ عام، ولماذا **الآن** لا قبل ذلك
///
/// قاعدة القالب أن يُنتظر المستهلك الثاني قبل التعميم (F21/R34). وقد بلغ
/// المستهلكون **ثلاثة بنفس اليوم** بمشروعٍ مبنيٍّ على هذا القالب، وثلاثةُ نسخٍ
/// متوازية من «اقرأ نصّاً، فُكّه، امنع الانهيار، سجّل» هي بالضبط ما يجعل
/// الرابعة تُكتب ناقصةً حارسَ الفكّ.
///
/// > ⬜ **وبالقالب لا مستهلكَ له بعد** — مسجَّلٌ بجرد «المبنيّ بلا مستهلك»
/// > (`readme/10_ARCHITECTURE.md`). وأولُ شاشةٍ تريد جواباً خارج التغطية بعد
/// > انقضاء الـTTL هي أولُ تطبيقٍ له.
///
/// ## وليس `RequestCacheInterceptor`
///
/// ذاك موجودٌ ومرتَّبٌ صحيحاً — **قبل** حارس الاتصال — لكنه مؤقَّت بـTTL: بعد
/// انقضائها يصير الجهاز خارج التغطية بلا جواب. وهذه اللقطة **لا تنتهي**: نسخةٌ
/// من الشهر الماضي أصدقُ وأنفعُ من شاشة «لا يوجد اتصال» لموظّفٍ يقف بموقعٍ لا
/// تغطية فيه. وذاك يخزّن ردَّ HTTP خاماً، وهذه تخزّن **ما استقرّ عليه المستودع
/// بعد ترشيحه** — وهو فرقٌ يهمّ: قائمةٌ تحفظ ما بقي بعد إسقاط ما عُولج
/// محلياً، لا ما أرسله الخادم.
///
/// ## وحدودُها صريحة
///
/// - **لقطةُ عرضٍ لا مصدرُ حقيقة.** لا يُكتب عليها ولا تُدفع؛ الكتابة المحلية
///   شأنُ `modules/sync` وحده.
/// - **لا تُمحى عند الخروج تلقائياً.** من يملك مفتاحاً يمسحه بنفسه عند تبديل
///   الحساب — و`StorageService.clear()` ممنوعة لمسح جزء (تمحو الثيم واللغة).
class OfflineSnapshot<T> {
  const OfflineSnapshot({
    required this.storage,
    required this.key,
    required this.encode,
    required this.decode,
    required this.tag,
  });

  final StorageService storage;
  final String key;

  /// إلى **مفاتيح الوايَر نفسها** لا شكلٍ ثانٍ: اللقطة تُقرأ بـ`fromJson`
  /// المستعملة مع الخادم، فتغييرُ مفتاحٍ بالباك يكسر الطرفين معاً بدل أن يترك
  /// اللقطة تُقرأ أصفاراً بصمت (R01).
  final Object? Function(T value) encode;

  final T Function(Map<String, dynamic> json) decode;

  /// وسمُ السجلّ — `RECORDS` · `REJECTIONS` · `ACCOUNT`.
  final String tag;

  Future<void> save(T value) async {
    try {
      await storage.writeString(key, jsonEncode(encode(value)));
    } catch (e) {
      // فشلُ الحفظ **لا يُفشل الطلب الناجح**: البيانات وصلت المستخدم بالفعل،
      // وكلُّ ما ضاع قدرةُ الجهاز على إعادتها بلا شبكة. يُسجَّل ولا يُرمى.
      LogService.warning('Could not save the "$key" snapshot: $e', tag: tag);
    }
  }

  /// `null` حين لا لقطة أو حين تعذّرت قراءتها.
  ///
  /// والحالتان تُعاملان سواءً **بعد تسجيل الثانية**: `catch (_) {}` هو ما حوّل
  /// عطل `RequestCacheInterceptor` إلى سلوكٍ بلا عَرَض لعمرٍ كامل — كاشٌ باردٌ
  /// أبداً، و`dart analyze` نظيف.
  Future<T?> read() async {
    final raw = await storage.readString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return decode(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      LogService.warning(
        'Unreadable "$key" snapshot — treated as absent: $e',
        tag: tag,
      );
      return null;
    }
  }

  Future<void> clear() => storage.delete(key);
}

/// لقطةُ **قائمة** — نفس العقد، وجذرُ الـJSON مصفوفة لا كائن.
///
/// صنفٌ ثانٍ لا وسيطٌ منطقيّ بالأول: `jsonDecode` يُعيد `List` هنا و`Map` هناك،
/// وتوحيدُهما كان يعني فحصَ نوعٍ عند كل قراءة بدل أن يحسمه المصرِّف.
class OfflineListSnapshot<T> {
  const OfflineListSnapshot({
    required this.storage,
    required this.key,
    required this.encode,
    required this.decode,
    required this.tag,
  });

  final StorageService storage;
  final String key;
  final Object? Function(T value) encode;
  final T Function(Map<String, dynamic> json) decode;
  final String tag;

  Future<void> save(List<T> values) async {
    try {
      await storage.writeString(
        key,
        jsonEncode([for (final value in values) encode(value)]),
      );
    } catch (e) {
      LogService.warning('Could not save the "$key" snapshot: $e', tag: tag);
    }
  }

  /// `null` — لا قائمةً فارغة — حين لا لقطة.
  ///
  /// **والفرق جوهري**: القائمة الفارغة جوابٌ صحيح («لا مرفوضات لديك») ويُعرض
  /// حالةً فارغة مطمئنة؛ وغيابُ اللقطة يعني «لا أعرف»، وعرضُه فراغاً يقول
  /// للموظّف إن شكاواه عولجت كلّها وهو لم يُسأل أصلاً.
  Future<List<T>?> read() async {
    final raw = await storage.readString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final rows = (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      return [for (final row in rows) decode(row)];
    } catch (e) {
      LogService.warning(
        'Unreadable "$key" snapshot — treated as absent: $e',
        tag: tag,
      );
      return null;
    }
  }

  Future<void> clear() => storage.delete(key);
}
