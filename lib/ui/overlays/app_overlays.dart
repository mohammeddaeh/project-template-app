import 'package:flutter/widgets.dart';

/// طبقةٌ فوق كل المسارات يضيفها موديول — تُبنى بسياقها هي، تحت `ResponsiveScope`.
///
/// [navigatorKey] للموجّه: الطبقة **فوق** الـ`Navigator`، فما تفتحه (ورقة ·
/// حوار · toast) يُفتح بسياقٍ تحته.
typedef AppOverlayBuilder =
    Widget Function(
      BuildContext context,
      GlobalKey<NavigatorState> navigatorKey,
      Widget child,
    );

/// **نقطةُ التركيب بـ`MaterialApp.builder` — يسجّل فيها الموديول طبقته، فلا
/// يعرفه `app.dart`.**
///
/// بلاها، موديولٌ يحتاج أن يرسم فوق كل الشاشات (زرٌّ عائم · شريط حالة) لا
/// يملك إلا تعديل `app.dart` باستيراده — فتعرف النواةُ الموديول، ويبقى سطرُه
/// هناك حين يُطفأ.
///
/// ```dart
/// // داخل `initialize` الموديول — قبل `runApp`، فـ`ModulesBootstrap.ready`
/// // يُنتظر بـ`StartupResolver.resolve`:
/// AppOverlays.register((context, navigatorKey, child) =>
///     MyOverlay(navigatorKey: navigatorKey, child: child));
/// ```
///
/// **والترتيب ترتيبُ التسجيل**: الأوّل أقربُ إلى المحتوى، والأخير فوق الجميع.
abstract final class AppOverlays {
  static final List<AppOverlayBuilder> _builders = [];

  static void register(AppOverlayBuilder builder) => _builders.add(builder);

  /// لإعادة التهيئة بالاختبارات فقط.
  static void reset() => _builders.clear();
}

/// يلفّ [child] بكل طبقةٍ سُجّلت — ويعيده كما هو حين لا شيء.
class AppOverlayHost extends StatelessWidget {
  const AppOverlayHost({
    required this.navigatorKey,
    required this.child,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var wrapped = child;
    for (final builder in AppOverlays._builders) {
      wrapped = builder(context, navigatorKey, wrapped);
    }
    return wrapped;
  }
}
