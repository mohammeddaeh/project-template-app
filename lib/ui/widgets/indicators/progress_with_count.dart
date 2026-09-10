import 'package:flutter/material.dart';

import 'package:app_template/ui/widgets/indicators/app_progress.dart';

/// شريط تقدّم بتدرّج ذهبي، وسطرُ عدٍّ تحته — «52 من 80 مقسم — 65%».
///
/// اليوم **غلافٌ رقيق** حول [AppProgress.linear] بنغمة [AppProgressTone.accent]:
/// التدرّج والاتجاه والقصّ الدفاعيّ وحركة القيمة كلها هناك. يبقى الاسم لأن
/// التصميم يسمّي هذا المركّب (شريط + عدّاد) ويعرضه بالمحاضر والمقاسم والمزامنة.
///
/// و[label] نصٌّ **جاهز** لا مفتاح: صياغته تختلف بكل شاشة وتحمل أرقاماً تُحقن.
class ProgressWithCount extends StatelessWidget {
  const ProgressWithCount({
    required this.progress,
    required this.label,
    this.height = 7,
    super.key,
  });

  /// `0.0`–`1.0`. تُقصّ داخل [AppProgress].
  final double progress;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) => AppProgress.linear(
    value: progress,
    tone: AppProgressTone.accent,
    height: height,
    label: label,
  );
}
