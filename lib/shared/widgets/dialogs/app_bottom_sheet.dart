import 'package:flutter/material.dart';
import 'package:app_template/presentation/extensions/screen_sizes_extensions.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

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

    final screenHeight = MediaQuery.sizeOf(context).height;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: dismissOnTapOutside,
      enableDrag: true,
      showDragHandle: false,
      useSafeArea: true,
      constraints: BoxConstraints(maxHeight: screenHeight * maxHeightFraction),
      builder: (_) => _AppBottomSheetContent(
        title: title,
        titleWidget: titleWidget,
        isScrollable: isScrollable,
        showDivider: showDivider,
        contentPadding: contentPadding,
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
    this.contentPadding,
  });

  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final bool isScrollable;
  final bool showDivider;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = contentPadding ??
        EdgeInsets.fromLTRB(24, 0, 24, 24 + context.bottomPadding);

    final body = Column(
      mainAxisSize: isScrollable ? MainAxisSize.max : MainAxisSize.min,
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
          Expanded(
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
      child: body,
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
