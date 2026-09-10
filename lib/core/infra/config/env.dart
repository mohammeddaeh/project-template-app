import 'dart:developer';

/// نقطة الوصول الوحيدة لإعدادات البيئة في كود Dart.
///
/// القيم تُحقن عند التشغيل عبر:
///   --dart-define=FLAVOR=dev
///   --dart-define-from-file=.env.dev.json
///
/// لا تحتاج تهيئة async — تعمل مباشرةً بعد إطلاق التطبيق.
abstract final class Env {
  /// الـ flavor الحالي: 'dev' | 'staging' | 'prod'
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'prod',
  );

  /// عنوان الـ API الخاص بهذه البيئة
  static const String baseUrl = String.fromEnvironment('BASE_URL');

  static bool get isDev     => flavor == 'dev';
  static bool get isStaging => flavor == 'staging';
  static bool get isProd    => flavor == 'prod';

  /// لاحقة قصيرة للعرض في FlavorBanner — فارغة في prod
  static String get label => switch (flavor) {
    'dev'     => 'Dev',
    'staging' => 'Test',
    _         => '',
  };

  /// **جردُ ما لا يعمل التطبيقُ بدونه** — أضِف إليه كلَّ مفتاحٍ تقرؤه بلا
  /// `defaultValue`، وإلا عاد غيابُه `''` يمضي بصمت.
  static const _required = <String, String>{'BASE_URL': baseUrl};

  /// **يُخفق عند الإقلاع، لا عند أول طلب.**
  ///
  /// ## العطل الذي وُلدت منه
  ///
  /// مفتاحٌ ناقصٌ بملف البيئة لا يُخفق شيئاً: `String.fromEnvironment` يردّ
  /// `''`، فيُبنى الطلبُ ويُرسَل ويُردَّ عليه — بنجاحٍ بروتوكوليٍّ تامّ غالباً،
  /// أو بخطأٍ **يتحدّث عن شيءٍ آخر**. فيُرسَل من يبحث إلى الخادم وإلى بيانات
  /// المستخدم، لا إلى السطر الناقص بالملف.
  ///
  /// ولا شيء بالمسار يكشفه: `dart analyze` نظيف، والاختباراتُ تمرّ (تحقن
  /// قيَمَها بنفسها)، والسجلُّ يطبع `baseUrl=` فارغاً بسطرٍ لا يقرؤه أحد.
  ///
  /// فالإخفاقُ هنا — **بسطرٍ يسمّي الملفَّ والمفتاح** — يختصر ساعةً إلى ثانية.
  static void init() {
    final missing = [
      for (final entry in _required.entries)
        if (entry.value.isEmpty) entry.key,
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'مفاتيح إعدادٍ ناقصة بـ.env.$flavor.json: ${missing.join(' · ')}\n'
        'أضِفها ثم أعد التشغيل **تشغيلاً كاملاً** — '
        '`--dart-define-from-file` تُقرأ وقت البناء لا وقت التشغيل، '
        'فـhot reload لا يلتقط التغيير.',
      );
    }
    log('flavor=$flavor | baseUrl=$baseUrl', name: 'Env');
  }
}
