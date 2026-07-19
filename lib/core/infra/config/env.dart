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

  /// يُستدعى مرة واحدة في main() لتسجيل الإعدادات الحالية
  static void init() {
    log('flavor=$flavor | baseUrl=$baseUrl', name: 'Env');
  }
}
