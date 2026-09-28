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
/// ```
class AppBottomSheet {
  AppBottomSheet._();

  /// يُظهر bottom sheet ويُرجع القيمة المُمرَّرة لـ [Navigator.pop].
  ///
  /// [maxHeightFraction] — نسبة ارتفاع الشاشة القصوى (0.0 – 1.0)، الافتراضي 0.9.
  /// [showDivider] — خط فاصل بين العنوان والمحتوى.
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
  }) {
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
      // قيد يُبنى مرة واحدة عند الفتح لا يعرف شيئاً عن الكيبورد: كان السقف
      // `screenHeight * 0.9` محسوباً من شاشة **لا تنكمش** حين يظهر، فتدّعي
      // الورقة ارتفاعاً ثلثه السفلي مرسوم تحته. السقف صار يُحسب مع كل إطار من
      // `MediaQuery` الخاص بالمحتوى، فينكمش معه.
      constraints: BoxConstraints(maxWidth: maxWidth),
      builder: (_) => _AppBottomSheetContent(
        title: title,
        titleWidget: titleWidget,
        isScrollable: isScrollable,
        showDivider: showDivider,
        contentPadding: contentPadding,
        maxHeightFraction: maxHeightFraction,
        child: child,
      ),
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
  });

  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final bool isScrollable;
  final bool showDivider;
  final double maxHeightFraction;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    // **ارتفاع الكيبورد يدخل الحشوة، لا `viewPadding`.**
    //
    // كانت الحشوة `24 + context.bottomPadding` — وهذا شريط إيماءات النظام، لا
    // الكيبورد. والأسوأ أن `SafeArea` تحت هذا الودجت تقرأ `padding.bottom`
    // التي **تهبط إلى صفر** أثناء فتح الكيبورد، فيختفي آخر حقل خلفه: حقل السعر
    // بآخر الورقة يُكتب فيه أعمى. يُقرأ هنا لا في `show()` — القيمة تتغيّر مع
    // كل إطار من ظهور الكيبورد، و`show()` تُنفَّذ مرة واحدة.
    final keyboardInset = context.keyboardInset;
    final effectivePadding =
        (contentPadding ?? EdgeInsets.fromLTRB(24, 0, 24, 24 + context.bottomPadding))
            .copyWith(bottom: (contentPadding?.bottom ?? (24 + context.bottomPadding)) + keyboardInset);

    final body = Column(
      // **دائماً `min`.**
      //
      // كانت `max` مع `Expanded` داخل قيد فضفاض، فتتمدّد الورقة إلى السقف مهما
      // كان محتواها: ورقةٌ فيها سطران تُفتح بطول قائمة كاملة. والأسوأ أن مدى
      // التمرير يصير **صفراً** (المحتوى = الورقة)، فحتى السحب لا يرفع حقلاً
      // اختفى خلف الكيبورد — لا رفع ولا تمرير.
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle
        const _DragHandle(),

        // العنوان + فاصل اختياري
        if (title != null || titleWidget != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: titleWidget ??
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
            Divider(
              height: 24,
              thickness: 1,
              color: context.colors.dividerSubtle,
            )
          else
            const SizedBox(height: 20),
        ],

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
          Padding(
            padding: effectivePadding,
            child: child,
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
            color: context.colors.dividerSubtle,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
