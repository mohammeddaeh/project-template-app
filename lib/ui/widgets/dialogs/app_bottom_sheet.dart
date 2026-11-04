import 'package:flutter/material.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/extensions/screen_sizes_extensions.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// Bottom sheet موحّد — نمط static show() يُرجع `Future<T?>`.
///
/// ```dart
/// // بسيط
/// AppBottomSheet.show(
///   context,
///   title: 'اختر الحالة',
///   child: StatusPickerWidget(),
/// );
///
/// // مع انتظار نتيجة
/// final selected = await AppBottomSheet.show<String>(
///   context,
///   title: 'الفلاتر',
///   showDivider: true,
///   child: FilterWidget(onSelect: (v) => Navigator.pop(context, v)),
/// );
///
/// // غير قابل للتمرير (محتوى ثابت الارتفاع)
/// AppBottomSheet.show(
///   context,
///   isScrollable: false,
///   maxHeightFraction: 0.5,
///   child: ConfirmActionsWidget(),
/// );
///
/// // ارتفاعات توقّف: تُفتح بـ٤٠٪ وتُسحب إلى ٩٠٪، وتحت الأولى تُغلق
/// AppBottomSheet.show(
///   context,
///   detents: const [0.4, 0.9],
///   child: LongListWidget(),
/// );
/// ```
class AppBottomSheet {
  AppBottomSheet._();

  /// يُظهر bottom sheet ويُرجع القيمة المُمرَّرة لـ [Navigator.pop].
  ///
  /// [maxHeightFraction] — نسبة ارتفاع الشاشة القصوى (0.0 – 1.0)، الافتراضي 0.9.
  /// [showDivider] — خط فاصل بين العنوان والمحتوى.
  /// [detents] — ارتفاعاتٌ تقف عندها الورقة حين تُفلت (نِسَبٌ تصاعدية من
  /// ارتفاع الشاشة): تُفتح بأولاها، ولا تعلو آخرَها، وما تحت الأولى يُغلقها.
  /// معها يُتجاهل [maxHeightFraction] و[isScrollable]: الورقةُ كلُّها تُسحب.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    Widget? titleWidget,
    bool isScrollable = true,
    bool showDivider = false,
    double maxHeightFraction = 0.9,
    bool dismissOnTapOutside = true,
    EdgeInsets? contentPadding,
    List<double>? detents,
  }) {
    assert(
      detents == null ||
          (detents.isNotEmpty &&
              detents.first > 0 &&
              detents.last <= 1 &&
              [
                for (var i = 1; i < detents.length; i++)
                  detents[i] > detents[i - 1],
              ].every((up) => up)),
      'AppBottomSheet: detents ascend within (0, 1]',
    );
    FocusManager.instance.primaryFocus?.unfocus();

    // **عرضٌ محدود وموسَّط على اللوح.**
    //
    // ورقةٌ سفلية تعبر ١٢٨٠ بكسل ليست ورقةً بل شريطٌ يقطع الشاشة: زرّاها
    // يفترقان بعرض راحتَي يد، وعنوانُها الموسَّط يبعد عن كليهما. و٦٤٠ هو ما
    // تنصّ عليه Material 3 للورقة على الشاشات الكبيرة.
    //
    // و`showModalBottomSheet` يوسّط تلقائياً أي ورقةٍ قيدُها أضيق من الشاشة
    // (`Align(bottomCenter)` داخل `BottomSheet`) — فلا حاجة إلى لفٍّ إضافي.
    final maxWidth = ResponsiveScope.of(context).isPhoneWidth
        ? double.infinity
        : 640.0;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: dismissOnTapOutside,
      enableDrag: true,
      showDragHandle: false,
      useSafeArea: true,
      // **العرض وحده هنا؛ الارتفاع داخل الـbuilder.**
      //
      // قيد يُبنى مرة واحدة عند الفتح لا يعرف شيئاً عن الكيبورد: سقفٌ
      // `screenHeight * 0.9` محسوبٌ من شاشة **لا تنكمش** حين يظهر يجعل الورقة
      // تدّعي ارتفاعاً ثلثه السفلي مرسوم تحته. فالسقف يُحسب مع كل إطار من
      // `MediaQuery` الخاص بالمحتوى، فينكمش معه.
      constraints: BoxConstraints(maxWidth: maxWidth),
      builder: (_) {
        final sheet = _AppBottomSheetContent(
          title: title,
          titleWidget: titleWidget,
          isScrollable: isScrollable,
          showDivider: showDivider,
          contentPadding: contentPadding,
          maxHeightFraction: maxHeightFraction,
          child: child,
        );
        return detents == null
            ? sheet
            : _DetentSheet(detents: detents, sheet: sheet);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content
// ─────────────────────────────────────────────────────────────────────────────

class _AppBottomSheetContent extends StatelessWidget {
  const _AppBottomSheetContent({
    required this.child,
    this.title,
    this.titleWidget,
    required this.isScrollable,
    required this.showDivider,
    required this.maxHeightFraction,
    this.contentPadding,
    this.scrollController,
  });

  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final bool isScrollable;
  final bool showDivider;
  final double maxHeightFraction;
  final EdgeInsets? contentPadding;

  /// من [DraggableScrollableSheet] حين تُفتح بارتفاعات توقّف.
  final ScrollController? scrollController;

  _AppBottomSheetContent scrolledBy(ScrollController controller) =>
      _AppBottomSheetContent(
        title: title,
        titleWidget: titleWidget,
        isScrollable: isScrollable,
        showDivider: showDivider,
        maxHeightFraction: maxHeightFraction,
        contentPadding: contentPadding,
        scrollController: controller,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    // **ارتفاع الكيبورد يدخل الحشوة، لا `viewPadding`.**
    //
    // `context.bottomPadding` وحده شريط إيماءات النظام، لا الكيبورد. والأسوأ أن `SafeArea` تحت هذا الودجت تقرأ `padding.bottom`
    // التي **تهبط إلى صفر** أثناء فتح الكيبورد، فيختفي آخر حقل خلفه: حقل السعر
    // بآخر الورقة يُكتب فيه أعمى. يُقرأ هنا لا في `show()` — القيمة تتغيّر مع
    // كل إطار من ظهور الكيبورد، و`show()` تُنفَّذ مرة واحدة.
    final keyboardInset = context.keyboardInset;
    final effectivePadding =
        (contentPadding ??
                EdgeInsets.fromLTRB(24, 0, 24, 24 + context.bottomPadding))
            .copyWith(
              bottom:
                  (contentPadding?.bottom ?? (24 + context.bottomPadding)) +
                  keyboardInset,
            );

    final header = <Widget>[
      // Drag handle
      const _DragHandle(),

      // العنوان + فاصل اختياري
      if (title != null || titleWidget != null) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child:
              titleWidget ??
              Text(
                title!,
                style: context.textTheme.titleLarge?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
        ),
        if (showDivider)
          Divider(height: 24, thickness: 1, color: context.colors.dividerSubtle)
        else
          const SizedBox(height: 20),
      ],
    ];

    final controller = scrollController;
    if (controller != null) {
      // **الورقةُ كلُّها بالتمرير، المقبضُ معها**: سحبُ أيِّ موضعٍ يغيّر
      // ارتفاعها، وخارج التمرير يحرّك المسارَ نفسه لا الورقة.
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: controller,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...header,
              Padding(padding: effectivePadding, child: child),
            ],
          ),
        ),
      );
    }

    final body = Column(
      // **دائماً `min`.**
      //
      // `max` مع `Expanded` داخل قيد فضفاض تمدّ الورقة إلى السقف مهما كان
      // محتواها: ورقةٌ فيها سطران تُفتح بطول قائمة كاملة. والأسوأ أن مدى
      // التمرير يصير **صفراً** (المحتوى = الورقة)، فحتى السحب لا يرفع حقلاً
      // اختفى خلف الكيبورد — لا رفع ولا تمرير.
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...header,

        // المحتوى
        if (isScrollable)
          // `Flexible(loose)` لا `Expanded`: يأخذ مقاس المحتوى، ولا يُشغَّل
          // التمرير إلا حين يتجاوزه السقف. السقف حدٌّ أعلى، لا ارتفاعٌ مطلوب.
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              padding: effectivePadding,
              child: child,
            ),
          )
        else
          // Loose too: the content keeps its own height, and still learns the
          // sheet's ceiling — a camera square or an image can shrink to fit a
          // short screen instead of overflowing it.
          Flexible(
            fit: FlexFit.loose,
            child: Padding(padding: effectivePadding, child: child),
          ),
      ],
    );

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        // السقف يُحسب من الشاشة **ناقص الكيبورد**، فلا يبقى جزء من الورقة
        // مرسوماً تحته حين يطول المحتوى.
        constraints: BoxConstraints(
          maxHeight: (context.sh - keyboardInset) * maxHeightFraction,
        ),
        child: body,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detents
// ─────────────────────────────────────────────────────────────────────────────

/// ورقةٌ تقف عند [detents] — وأدنى توقّفٍ صفرٌ يُغلقها.
///
/// `minChildSize: 0` لا الأولى: سحبٌ تحتها يجد ما يقف عنده، فإفلاتٌ قرب
/// القاع يكمل إلى الصفر ويُغلق، وقربَ الأولى يعود إليها.
class _DetentSheet extends StatefulWidget {
  const _DetentSheet({required this.detents, required this.sheet});

  final List<double> detents;
  final _AppBottomSheetContent sheet;

  @override
  State<_DetentSheet> createState() => _DetentSheetState();
}

class _DetentSheetState extends State<_DetentSheet> {
  bool _closing = false;

  bool _onExtent(DraggableScrollableNotification n) {
    if (!_closing && n.extent <= 0.001) {
      _closing = true;
      Navigator.of(context).pop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detents;
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: _onExtent,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: d.first,
        minChildSize: 0,
        maxChildSize: d.last,
        snap: true,
        snapSizes: d.sublist(0, d.length - 1),
        builder: (_, controller) => widget.sheet.scrolledBy(controller),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drag handle
// ─────────────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.colors.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
