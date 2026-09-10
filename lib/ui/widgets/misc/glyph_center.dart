import 'package:flutter/material.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';

/// يضع **حبر** النص في وسط الصندوق، لا صندوقَ سطره.
///
/// `Alignment.center` و`Center` و`CircleAvatar` كلها تركّز *صندوق السطر* الذي
/// يبنيه الخط، لا الشكلَ المرسوم داخله. والخط العربي يبني صندوقاً علويَّ الثقل
/// عمداً — صعودٌ طويل للتشكيل ونزولٌ قصير — فالنص العربي يملؤه فيبدو مركزيّاً،
/// بينما الأرقام واللاتيني بلا نوازل فيتجمّع حبرها في نصفه الأعلى وتبدو مرتفعة.
/// المقدار مقيسٌ لا مقدَّر، ومشتقّ من جداول الخط نفسه في
/// [AppFonts.opticalCenterCorrectionFor] — وهذه الودجة مستهلكه الوحيد.
///
/// ```dart
/// Container(
///   width: 28,
///   height: 28,
///   alignment: Alignment.center,
///   decoration: const BoxDecoration(shape: BoxShape.circle),
///   child: GlyphCenter(child: Text('$number', style: context.textTheme.headlineSmall)),
/// )
/// ```
///
/// **لِمَ إزاحةُ رسمٍ لا خاصيّةُ نمط:** لا شيء في `TextStyle` يصلح هذا. `height`
/// و`leadingDistribution` و`StrutStyle` توزّع الـ`leading` حول نسبة
/// الصعود/النزول ولا تغيّر النسبة، فالإزاحة ثابتة تحتها جميعاً. ولذلك
/// [Transform.translate]: يزيح الرسم وحده ويترك المقاس كما هو، فلا يتحرّك شيء
/// حول الشارة.
///
/// **وحدُّها:** تُستعمل داخل صندوقٍ **مقاسُه ثابت** — دائرة أو مربّع أو صفٌّ ذو
/// `height`. وفي صندوقٍ يلتصق بالنص (`Column` بلا ارتفاع مثلاً) لا موضعَ يُزاح
/// إليه، فالإزاحة تدفع الحبر خارج حدوده.
///
/// **ولا تلفّ بها نصّاً عربيّاً:** العربي منحرفٌ 1.25% فقط، وإزاحتُه 14% تكسره.
/// هذه للأرقام واللاتيني وحدهما — ولمزيجٍ يغلب عليه الرقم مثل `1/0` و`92%`.
class GlyphCenter extends StatelessWidget {
  const GlyphCenter({required this.child, super.key});

  /// النص المراد توسيطه. مكتوبٌ [Text] لا [Widget] عمداً: الإزاحة تُقاس بـ
  /// `fontSize`، وهذا النوع وحده يتيح قراءتها من `style` الابن.
  final Text child;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = DefaultTextStyle.of(context).style;
    final TextStyle style = child.style == null
        ? base
        : base.merge(child.style);

    final String? family = style.fontFamily;
    if (family == null) return child;

    final double correction = AppFonts.opticalCenterCorrectionFor(family);
    if (correction == 0) return child;

    // بمقياس المستخدم لا بالقيمة الخام: الإزاحة كسرٌ من الحجم المرسوم فعلاً،
    // فلو كبّر النظام الخطّ ولم تكبر معه عادت الأرقام ترتفع تدريجياً.
    final double fontSize = MediaQuery.textScalerOf(
      context,
    ).scale(style.fontSize ?? 14);

    return Transform.translate(
      offset: Offset(0, correction * fontSize),
      child: child,
    );
  }
}
