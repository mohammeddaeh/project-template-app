import 'package:flutter/material.dart';

import 'package:app_template/ui/widgets/placeholders/skeleton_scope.dart';

/// بديلٌ لـ[Text] الخام لعرض **بيانةٍ ديناميكية** (اسم · رقم · أي نصٍّ من
/// الشبكة) — خارج [Skeletonized] يتصرّف تماماً مثل [Text]، وداخلها يرسم نفسَه
/// عظماً بمقاس النصّ نفسِه.
///
/// ```dart
/// ShimmerText(user.displayName, style: context.textTheme.displaySmall)
/// // نفسُ مكان Text(user.displayName, style: ...) حرفاً بحرف
/// ```
///
/// ✅ **والمقاسُ يُقاس بالتخطيط لا بـ`TextPainter` (2026-09-01)** — كانت
/// تقيس عرضَ النصّ بقلمٍ حرّ ثم ترسم شريطاً بذلك العرض، وهو **قياسٌ بلا
/// قيود**: نصٌّ داخل `Expanded` أطولُ من مكانه كان يُنتج شريطاً أعرضَ من
/// الصفّ فيفيض (`RenderFlex overflowed`)، ونصٌّ بسطرين يُقاس سطراً. و[Bone]
/// تُخطِّط `Text` الحقيقيّ بقيود أبيه الحقيقية ثم تملأ صندوقَه — فالمقاسُ هو
/// المقاسُ نفسُه، لا تقديرٌ له.
///
/// ⚠️ **ولا تُلفّ بها لافتةً ثابتة** — راجع [Bone].
class ShimmerText extends StatelessWidget {
  const ShimmerText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.textDirection,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) => Bone.text(
    child: Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      textDirection: textDirection,
    ),
  );
}
