import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/wrappers/error_boundary.dart';

/// `ErrorWidget.builder` قبل `install()` — يُستعاد بعد كل اختبار كي لا يسرّب
/// حالةً بين الاختبارات، ولا بين هذا الملف وملفات أخرى بنفس العملية.
void main() {
  late ErrorWidgetBuilder originalBuilder;
  final details = FlutterErrorDetails(exception: Exception('boom كسر البناء'));

  setUp(() => originalBuilder = ErrorWidget.builder);
  tearDown(() => ErrorWidget.builder = originalBuilder);

  Widget host(Widget child) => MaterialApp(
    theme: AppThemeData.light(const Locale('ar'), AppFonts.available.first),
    home: Scaffold(body: child),
  );

  test('install() replaces ErrorWidget.builder, and is idempotent', () {
    ErrorBoundary.install();
    final afterFirst = ErrorWidget.builder;
    expect(afterFirst, isNot(same(originalBuilder)));

    // نداءٌ ثانٍ لا يُعيد التركيب — نفس المرجع بالضبط.
    ErrorBoundary.install();
    expect(ErrorWidget.builder, same(afterFirst));
  });

  testWidgets(
    'debug branch shows the real exception, never the release message',
    (tester) async {
      await tester.pumpWidget(
        host(ErrorFallback(details: details, debugOverride: true)),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('boom'), findsOneWidget);
    },
  );

  // ولا اختبار ودجةٍ لفرع الإصدار (`debug: false`): يبني `AppText` الذي
  // ينادي `.tr()`، ويحتاج شجرةَ `EasyLocalization` حيّة — وهي بهذا المستودع
  // تُهيَّئ بـ`SharedPreferences` عبر قناة منصّة لا مِحاكاة لها بالاختبارات
  // (نفس القيد الذي يجعل كل ملفّات `test/` الأخرى تتجنّب تركيب
  // `EasyLocalization` كاملةً — لا سابقة واحدة له بالمستودع). فمُحاولةً حقيقية
  // عُلِّقت فعلاً بلا نهاية (>180 ثانية) قبل هذا القرار.
  //
  // فالقياسُ هنا على الكود لا على الودجة المرسومة — تماماً كـ
  // `theme_switcher_test.dart`: نتحقّق أن الفرع الصحيح هو من يحمل مفتاح
  // الترجمة، ونثق بأن `AppText`/`.tr()` مُختبَران بمكانهما الخاص.
  test('the release branch is wired to LocaleKeys.unknownError in source', () {
    final src = File(
      'lib/ui/widgets/wrappers/error_boundary.dart',
    ).readAsStringSync();
    final elseBranch = src.substring(src.indexOf('else'));
    expect(elseBranch, contains('LocaleKeys.unknownError'));
    expect(
      elseBranch.contains('exceptionAsString'),
      isFalse,
      reason: 'the release branch must never reference the raw exception',
    );
  });
}
