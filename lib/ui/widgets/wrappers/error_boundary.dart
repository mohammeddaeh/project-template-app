import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/misc/app_text.dart';

/// نقطة تركيب واحدة: [install] تُنادى مرّة من `main.dart` قبل `runApp`،
/// فتستبدل شاشة فلاتر الرمادية الافتراضية (`ErrorWidget.builder`) ببديلٍ
/// أهدأ حين ينهار `build()` لودجةٍ ما.
///
/// **والنطاق محدودٌ بسلوك فلاتر نفسِه لا بكودٍ هنا**: العنصر (`Element`) الذي
/// ينهار بناؤه هو وحده الذي يُستبدل بما يُعيده [ErrorWidget.builder] — لا
/// الشجرة كلّها ولا الشاشة المحيطة به. هذا افتراضيٌّ بفلاتر
/// (`Element.performRebuild` يلتقط الاستثناء لعنصره وحده)؛ وما يفعله هذا
/// الملف هو تجميل ذلك البديل، لا توسيع نطاقه أو تضييقه.
///
/// ⚠️ **ولا علاقة له بالإبلاغ عن الخطأ.** `FlutterError.onError` ينطلق بصرف
/// النظر عمّا يُرسم هنا — `modules/crash_reporting` إن كان مفعَّلاً يستقبل كل
/// خطأ كالمعتاد. هذا الملف عرضٌ فقط، لا تسجيل.
abstract final class ErrorBoundary {
  static bool _installed = false;

  /// آمنةٌ للنداء أكثر من مرّة — النداءات التالية لا تفعل شيئاً.
  static void install() {
    if (_installed) return;
    _installed = true;
    ErrorWidget.builder = (details) => ErrorFallback(details: details);
  }
}

/// الودجة التي يرسمها [ErrorBoundary.install]. صنفٌ عامٌّ (لا خاصّاً) لأمرين:
/// F21 بـ`check_structure.dart` يُلزم كلَّ ملفٍّ بـ`ui/widgets/` أن يُصدَّر من
/// الباريل، ولأن [debugOverride] يحتاج بابَ اختبارٍ مباشراً بلا الاعتماد على
/// [kDebugMode] الثابت (نفس نمط `SessionGuardCubit.lockAfter`).
class ErrorFallback extends StatelessWidget {
  const ErrorFallback({super.key, required this.details, bool? debugOverride})
    : debug = debugOverride ?? kDebugMode;

  final FlutterErrorDetails details;

  /// مكشوفةٌ للاختبار وحده — الفرع الحقيقي بالإنتاج يقرّر بـ[kDebugMode]
  /// دائماً؛ تمريرُ [debugOverride] بالمُنشئ يتيح اختبار الفرعين معاً بلا
  /// تلاعبٍ بذلك الثابت.
  final bool debug;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.error.withValues(alpha: 0.08),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: context.colors.error, size: 32),
              const SizedBox(height: 8),
              // نصّ الاستثناء الحقيقي بالتطوير وحده — لا يصل مستخدماً حقيقياً
              // أبداً، تماماً كسياسة `NetworkLogInterceptor._redact` الأخرى.
              if (debug)
                Text(
                  details.exceptionAsString(),
                  style: context.baseTextStyle.copyWith(
                    color: context.colors.error,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                )
              else
                const AppText(
                  LocaleKeys.unknownError,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
