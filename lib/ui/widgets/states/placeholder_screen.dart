import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/states/app_state_widget.dart';

/// شاشة تبويب لم تُبنَ بعد — **مقصودة، ومؤقّتة، ومكتوب عليها ذلك**.
///
/// القشرة تُبنى قبل الشرائح (P2) لأن التنقّل والجلسة والاتصال تُختبَر مرّة
/// واحدة لا مع كل شاشة. والتبويب الفارغ الصامت يُقرأ عطلاً: من يفتحه لا يعرف
/// أهو خطأٌ أم لم يأتِ دوره بعد.
///
/// يُحذف باستبدال جسد الشاشة، لا بحذف هذا الملف — مستهلكوه ثلاثة اليوم.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.titleKey,
    required this.icon,
    super.key,
  });

  final String titleKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — registers this element with EasyLocalization
    context.locale;
    return Scaffold(
      appBar: AppBar(title: Text(titleKey.tr())),
      backgroundColor: context.colors.bgPage,
      body: AppStateWidget(
        type: AppStateType.empty,
        icon: icon,
        titleKey: LocaleKeys.screenComingSoon,
        descriptionKey: LocaleKeys.screenComingSoonHint,
      ),
    );
  }
}
