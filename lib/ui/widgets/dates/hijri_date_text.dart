import 'package:flutter/widgets.dart';
import 'package:app_template/core/foundation/utils/hijri_date_extension.dart';
import 'package:app_template/ui/extensions/extensions.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// يعرض [date] بالتقويم الهجري — مثال: «١٥ رجب ١٤٤٦» بالعربية، أو
/// «15 Rajab 1446» بالإنكليزية. يتبع لغة الواجهة تلقائياً (`context.isAr`
/// يسجّل الاعتماد على اللغة — يُعاد رسمه عند تبديلها بلا أي سطرٍ إضافي).
class HijriDateText extends StatelessWidget {
  const HijriDateText(this.date, {this.style, super.key});

  final DateTime date;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final language = context.isAr ? 'ar' : 'en';
    return Text(
      date.toHijriString(language: language),
      style: style ?? context.textTheme.bodyMedium,
    );
  }
}
