import 'package:flutter/widgets.dart';

/// صنفُ الشاشة — **قياسٌ للمساحة المتاحة، لا لنوع الجهاز**.
///
/// الحدود مأخوذة من عرض النافذة لا من `shortestSide`، لأن ما يقرّر تخطيط
/// عمودٍ واحد أو عمودَين هو العرض الذي بين يدي التخطيط الآن: هاتفٌ مستلقٍ
/// (٨٠٠×٣٦٠) يملك عرضَ لوحٍ صغير ويستحقّ تخطيطَه، وإن بقي هاتفاً.
///
/// | الصنف | العرض | الأجهزة |
/// |---|---|---|
/// | [compact] | < ٣٦٠ | هواتف صغيرة (iPhone SE · شاشات ٣٢٠) |
/// | [medium] | ٣٦٠–٥٩٩ | أغلب الهواتف |
/// | [expanded] | ٦٠٠–٨٩٩ | لوحٌ ٧–٨ بوصة · هاتفٌ مستلقٍ · مطويٌّ مفتوح |
/// | [large] | ≥ ٩٠٠ | لوحٌ ١٠ بوصة فأكبر |
enum ScreenClass { compact, medium, expanded, large }

/// كلُّ رقمٍ يعتمد على مقاس الشاشة بالتطبيق — محسوباً مرّةً واحدة.
///
/// **لماذا صنفٌ واحد بدل `MediaQuery` بكل ملف:** الحساب المتفرّق ينتج قِيَماً
/// متضاربة لنفس الجهاز — شاشةٌ تحسب حشوتها `sw * 0.06` وأخرى `16` ثابتة،
/// فيختلف هامش الصفحتَين على نفس الهاتف بلا سببٍ يراه أحد. وأسوأ منه:
/// **النِّسَب من ارتفاع الشاشة** (`context.sh * 0.08`) لا تتقلّص مع الكيبورد،
/// فتُخرج أسفلَ المحتوى خارج الحدّ على الشاشات القصيرة — وهو عطلٌ وقع بشاشة
/// الدخول فعلاً.
///
/// القراءة: `context.screen` أو [ResponsiveScope.of].
@immutable
class ScreenMetrics {
  const ScreenMetrics({
    required this.width,
    required this.height,
    required this.screenClass,
    required this.isTablet,
    required this.isLandscape,
    required this.scale,
  });

  /// **الأساس: ٣٩٠** — عرض الهاتف المتوسّط الذي رُسمت عليه تصاميم الفيغما.
  /// كلُّ رقمٍ بالتصميم يُقرأ على أنه «صحيحٌ عند ٣٩٠»، و[scale] يحمله إلى غيره.
  static const double baselineWidth = 390;

  static const double compactMax = 360;
  static const double mediumMax = 600;
  static const double expandedMax = 900;

  /// حدُّ اللوح: ٦٠٠ على **أقصر ضلع** — المعيار الذي تستعمله أندرويد ذاتها
  /// (`sw600dp`). وأقصرُ ضلعٍ لا العرض، لأن الجهاز لا يصير هاتفاً بتدويره.
  static const double tabletShortestSide = 600;

  /// أدنى عرضٍ ينتقل عنده التنقّل من شريطٍ سفليّ إلى جانبيّ — راجع
  /// [usesSideNavigation]. وهو **٨٤٠**: حدُّ `Expanded` بأصناف نوافذ
  /// Material 3، لا حدُّ اللوح.
  static const double sideNavigationMinWidth = 840;

  final double width;
  final double height;
  final ScreenClass screenClass;

  /// جهازٌ لوحيّ فعلاً — بأي اتجاهٍ كان. راجع [tabletShortestSide].
  final bool isTablet;
  final bool isLandscape;

  /// معامل تكبير المسافات والمقاسات نسبةً إلى [baselineWidth].
  ///
  /// **مقيَّدٌ عمداً بين ٠٫٨٥ و١٫٠٥ للهواتف، وثابتٌ ١٫١٥ للألواح.** التناسب
  /// الحرّ (`width / 390`) يعطي اللوحَ ٢٫١ فيصير الزرُّ بارتفاع ١١٠ بكسل
  /// وأيقونةُ الشريط بحجم راحة اليد: تكبيرُ هاتفٍ لا تخطيطُ لوح. اللوح يكسب
  /// المساحةَ بالهوامش وحدِّ العرض ([formMaxWidth])، لا بتضخيم كل عنصر.
  final double scale;

  factory ScreenMetrics.fromSize(Size size) {
    final shortestSide = size.shortestSide;
    final isTablet = shortestSide >= tabletShortestSide;
    return ScreenMetrics(
      width: size.width,
      height: size.height,
      screenClass: _classify(size.width),
      isTablet: isTablet,
      isLandscape: size.width > size.height,
      scale: isTablet
          ? 1.15
          : (shortestSide / baselineWidth).clamp(0.85, 1.05).toDouble(),
    );
  }

  static ScreenClass _classify(double width) {
    if (width < compactMax) return ScreenClass.compact;
    if (width < mediumMax) return ScreenClass.medium;
    if (width < expandedMax) return ScreenClass.expanded;
    return ScreenClass.large;
  }

  bool get isCompact => screenClass == ScreenClass.compact;
  bool get isPhoneWidth =>
      screenClass == ScreenClass.compact || screenClass == ScreenClass.medium;

  /// هل يكون التنقّل **شريطاً جانبياً** بدل السفليّ؟
  ///
  /// **العرض ≥ ٨٤٠، لا ≥ ٦٠٠** — ولوحٌ عموديّ يبقى بشريطٍ سفليّ.
  ///
  /// كان الحدّ ٦٠٠ (أي: كلُّ لوحٍ بأي اتجاه)، وهو ما ينصّ عليه Material 3
  /// حرفياً لصنف `Medium`. لكنّ الحرفَ هنا يخالف الغرض:
  ///
  /// | الاتجاه | العرض | المحورُ الشحيح | ما يقتطعه الشريط |
  /// |---|---|---|---|
  /// | لوحٌ عموديّ | ٨٠٠ | **العرض** | الجانبيّ يأكل ٨٠ من ٨٠٠ = ١٠٪ من الشحيح |
  /// | لوحٌ أفقيّ | ١٢٨٠ | **الارتفاع** | السفليّ يأكل ٦٦ من ٨٠٠ = ٨٪ من الشحيح |
  ///
  /// أي أن كلَّ وضعٍ يريد الشريطَ على محوره **الوافر**: العموديُّ ارتفاعُه وافر
  /// فيأخذ السفليّ، والأفقيُّ عرضُه وافر فيأخذ الجانبيّ. والحدُّ ٦٠٠ كان يعطي
  /// العموديَّ عكسَ ما يحتاج.
  ///
  /// وسببان أخصُّ بهذا التطبيق:
  /// - ترويسات الشاشات **شرائطُ خضراء بعرضٍ كامل**، والجانبيُّ يقطعها.
  /// - تطبيقٌ ميدانيّ يُمسك باليدين؛ بالوضع العموديّ الإبهامُ يبلغ الأسفل لا
  ///   الجانب.
  ///
  /// و٨٤٠ ليس رقماً مخترعاً: هو حدُّ `Expanded` بأصناف نوافذ Material 3 —
  /// فاللوح العموديّ (٨٠٠) دونه، والأفقيّ (١٢٨٠) فوقه، بلا حالةٍ بينهما.
  bool get usesSideNavigation => width >= sideNavigationMinWidth;

  /// الهامش الأفقي للصفحة — مصدرٌ واحد لحشوة كل شاشة.
  double get gutter => switch (screenClass) {
    ScreenClass.compact => 16,
    ScreenClass.medium => 20,
    ScreenClass.expanded => 32,
    ScreenClass.large => 48,
  };

  /// أقصى عرضٍ لعمودِ **نموذج** (حقول وأزرار).
  ///
  /// حقلُ نصٍّ بعرض ١٢٠٠ بكسل ليس أسهل بل أصعب: العين تقطع مسافةً بين اللافتة
  /// وقيمتها، ويصير الزرُّ شريطاً عابراً للشاشة. الحدُّ يُبقيه بمقاسٍ مقروء
  /// ويترك المساحة هامشاً.
  double get formMaxWidth => isPhoneWidth ? double.infinity : 480;

  /// أقصى عرضٍ لعمودِ **قراءة أو قائمة** — أوسع من النموذج، وما يزال محدوداً.
  double get contentMaxWidth => isPhoneWidth ? double.infinity : 840;

  /// عدد الأعمدة لأي شبكة بطاقات.
  int get gridColumns => switch (screenClass) {
    ScreenClass.compact => 1,
    ScreenClass.medium => 2,
    ScreenClass.expanded => 3,
    ScreenClass.large => 4,
  };

  /// مسافةٌ من التصميم مضروبةً بـ[scale]، مقرَّبةً لبكسلٍ كامل.
  double space(double base) => (base * scale).roundToDouble();

  /// مقاسٌ من التصميم (قطر · ارتفاع · أيقونة) مضروباً بـ[scale].
  ///
  /// بلا تقريب: المقاسات تدخل حساباتٍ متداخلة (دائرةٌ بداخلها صورة)، والتقريب
  /// بكل خطوة يُراكم انحرافاً يكسر التوسيط.
  double size(double base) => base * scale;

  /// يختار قيمةً حسب صنف الشاشة، ويسقط لأقرب صنفٍ أصغر عند الغياب.
  ///
  /// ```dart
  /// final columns = context.screen.pick(compact: 1, expanded: 2, large: 3);
  /// ```
  T pick<T>({required T compact, T? medium, T? expanded, T? large}) {
    final m = medium ?? compact;
    final e = expanded ?? m;
    return switch (screenClass) {
      ScreenClass.compact => compact,
      ScreenClass.medium => m,
      ScreenClass.expanded => e,
      ScreenClass.large => large ?? e,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenMetrics &&
          other.width == width &&
          other.height == height &&
          other.screenClass == screenClass &&
          other.isTablet == isTablet &&
          other.isLandscape == isLandscape &&
          other.scale == scale;

  @override
  int get hashCode =>
      Object.hash(width, height, screenClass, isTablet, isLandscape, scale);
}
