import 'package:flutter/widgets.dart';

/// مدّة وcurve الحركة — قرارٌ موحَّد لكل micro-interaction بدل قيمةٍ مكتوبة
/// يدوياً بكل ودجة.
abstract final class AppMotion {
  AppMotion._();

  /// ضغطة زر، تبديل chip — تفاعلٌ فوريّ يحتاج ردّاً أسرع من إدراكه كتأخير.
  static const Duration fast = Duration(milliseconds: 150);

  /// انتقال داخل نفس الشاشة — فتح/طيّ قسم، ظهور حالة جديدة.
  static const Duration base = Duration(milliseconds: 250);

  /// كشف عنصرٍ كبير — ورقة سفلية، لافتة تملأ عرض الشاشة.
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve fastCurve = Curves.easeOut;
  static const Curve baseCurve = Curves.easeInOutCubic;
  static const Curve slowCurve = Curves.easeOutCubic;

  /// دخول احتفالي — أيقونة نجاح، ظهور عنصر يستحق لفت نظر. لا يُستعمل للخروج.
  static const Curve emphasizedCurve = Curves.easeOutBack;

  /// نسبة تصغير الابن أثناء الضغط — رد فعل لمسي لأي عنصرٍ قابل للنقر.
  static const double pressedScale = 0.97;

  /// تأخير قبل تنفيذ إجراء بعد كتابة حيّة — حقل بحث أو فلترة.
  static const Duration debounce = Duration(milliseconds: 300);

  /// الفاصل بين عنصرٍ وتاليه بظهورٍ متتالٍ (قائمة · ترحيب).
  static const Duration stagger = Duration(milliseconds: 45);

  /// أقصى عدد عناصر يتأخّر ظهورُها في دفعةٍ واحدة — العنصر التاسع يظهر مع
  /// الثامن، فلا ينتظر القارئ عموداً فارغاً يمتلئ خلفه.
  static const int staggerCap = 8;

  /// المدد **كما يجب أن تُستعمل الآن**: صفرٌ حين فعّل المستخدم «تقليل الحركة»
  /// بالنظام (`MediaQuery.disableAnimations`). كل حركةٍ تُبنى بشاشة أو ودجة
  /// تأخذ مدّتها من هنا لا من الثوابت أعلاه مباشرةً.
  static MotionValues of(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true
      ? MotionValues.reduced
      : MotionValues.standard;
}

/// مددُ الحركة بعد احترام «تقليل الحركة» — راجع [AppMotion.of].
class MotionValues {
  const MotionValues._({
    required this.fast,
    required this.base,
    required this.slow,
    required this.stagger,
  });

  static const standard = MotionValues._(
    fast: AppMotion.fast,
    base: AppMotion.base,
    slow: AppMotion.slow,
    stagger: AppMotion.stagger,
  );

  static const reduced = MotionValues._(
    fast: Duration.zero,
    base: Duration.zero,
    slow: Duration.zero,
    stagger: Duration.zero,
  );

  final Duration fast;
  final Duration base;
  final Duration slow;
  final Duration stagger;

  /// هل الحركة مطفأة بطلب المستخدم؟ ما لا مدّةَ له (اهتزاز · عدّاد) يُتخطّى كلّه.
  bool get isReduced => identical(this, reduced);
}
