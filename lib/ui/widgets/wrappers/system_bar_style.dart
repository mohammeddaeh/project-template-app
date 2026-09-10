import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// لون أيقونات شريط النظام — **اختياراً صريحاً، لا اشتقاقاً من الثيم وحده**.
///
/// الافتراضُ بالتطبيق (`app.dart`) يشتقّ اللون من الوضع: أيقونات **داكنة**
/// بالفاتح، **فاتحة** بالداكن. وهو صحيحٌ فوق صفحةٍ كريمية، وخاطئٌ تماماً فوق
/// أرضيةٍ لا تنقلب مع الوضع — شريطٌ علويٌّ بلون الهوية، أو شاشةُ دخولٍ مطليّة:
/// تبقى داكنةً ليلاً ونهاراً، فتصير الساعةُ والبطاريةُ
/// **سوداءَ على أخضر داكن** بالوضع الفاتح — وهو ما لا يُقرأ.
///
/// فهذه الودجة هي المخرج: تغلّف ما يقع تحت الشريط، وتقول ما لونُ الأيقونات
/// بكل وضع. وكونُها الأعمقَ تعليقاً فوق تلك البقعة يجعلها هي الرابحة على
/// الافتراض العام.
///
/// **وموضعُها يقرّر ما تحكمه.** فلَتر Flutter يقرأ التعليق مرّتين: عند وسط
/// شريط الحالة (أعلى الإطار) لألوان شريط الحالة، وعند وسط شريط التنقّل (أسفله)
/// لألوانه — ثم يمزج الجوابين. فتغليفُ الشريط العلوي وحده يبدّل الأعلى ويترك
/// الأسفلَ على الافتراض، وتغليفُ الشاشة كاملةً يبدّل الاثنين.
///
/// ```dart
/// // شاشةٌ أرضيتها داكنة في الوضعين:
/// const SystemBarStyle.lightIcons(child: …)
///
/// // أو اختيارٌ لكل وضعٍ على حدة:
/// SystemBarStyle(
///   onLightTheme: Brightness.light, // أيقونات بيضاء والثيم فاتح
///   onDarkTheme: null,              // والداكن يبقى على افتراضه
///   child: …,
/// )
/// ```
class SystemBarStyle extends StatelessWidget {
  const SystemBarStyle({
    required this.child,
    this.onLightTheme,
    this.onDarkTheme,
    super.key,
  });

  /// أيقوناتٌ فاتحة بالوضعين — لأرضيةٍ داكنة لا تنقلب.
  const SystemBarStyle.lightIcons({required Widget child, Key? key})
    : this(
        child: child,
        onLightTheme: Brightness.light,
        onDarkTheme: Brightness.light,
        key: key,
      );

  /// أيقوناتٌ داكنة بالوضعين — لأرضيةٍ فاتحة لا تنقلب.
  const SystemBarStyle.darkIcons({required Widget child, Key? key})
    : this(
        child: child,
        onLightTheme: Brightness.dark,
        onDarkTheme: Brightness.dark,
        key: key,
      );

  final Widget child;

  /// لون الأيقونات حين يكون ثيم التطبيق **فاتحاً**. `null` ⇒ الافتراض (داكنة).
  final Brightness? onLightTheme;

  /// لون الأيقونات حين يكون ثيم التطبيق **داكناً**. `null` ⇒ الافتراض (فاتحة).
  final Brightness? onDarkTheme;

  /// النمط الكامل لوضعٍ بعينه — ومصدرُ الافتراض العام بـ`app.dart` أيضاً.
  ///
  /// تمريرُ `null` للتجاوزين يعيد **حرفياً** ما كان `app.dart` يبنيه يدوياً:
  /// شريطان شفّافان، وأيقوناتٌ معكوسةُ الوضع.
  static SystemUiOverlayStyle resolve(
    Brightness themeBrightness, {
    Brightness? onLightTheme,
    Brightness? onDarkTheme,
  }) {
    final isDark = themeBrightness == Brightness.dark;
    final icons =
        (isDark ? onDarkTheme : onLightTheme) ??
        (isDark ? Brightness.light : Brightness.dark);
    final iconsAreLight = icons == Brightness.light;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      // iOS يقرأ سطوع **الخلفية**، وأندرويد سطوع **الأيقونات**. كلمتان
      // متعاكستان لطلبٍ واحد: حروفٌ شاحبة فوق أرضٍ داكنة.
      statusBarBrightness: iconsAreLight ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: icons,
      systemNavigationBarContrastEnforced: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: resolve(
        Theme.of(context).brightness,
        onLightTheme: onLightTheme,
        onDarkTheme: onDarkTheme,
      ),
      child: child,
    );
  }
}
