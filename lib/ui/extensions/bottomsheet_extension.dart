import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:app_template/ui/extensions/screen_sizes_extensions.dart';

enum AppBottomSheetSize {
  wrapContent(1.0),
  compact(0.42),
  half(0.5),
  large(0.72),
  full(0.92);

  const AppBottomSheetSize(this.maxHeightRatio);
  final double maxHeightRatio;
}

class BaseBottomSheetConfig {
  const BaseBottomSheetConfig({
    this.horizontalPadding = 24,
    this.bottomPadding = 24,
    this.titleBottomSpacing = 20,
    this.topLineHeight = 4,
    this.topLineWidth = 40,
    this.topLineTopPadding = 12,
    this.topLineBottomPadding = 20,
  });

  final double horizontalPadding;

  final double bottomPadding;

  final double titleBottomSpacing;

  final double topLineHeight;

  final double topLineWidth;
  final double topLineTopPadding;
  final double topLineBottomPadding;

  static const BaseBottomSheetConfig standard = BaseBottomSheetConfig();

  static const BaseBottomSheetConfig compact = BaseBottomSheetConfig(
    horizontalPadding: 20,
    bottomPadding: 16,
    titleBottomSpacing: 12,
    topLineBottomPadding: 16,
  );
}

extension ShowAppBottomSheet on BuildContext {
  void showAppBottomSheet({
    String? title,
    Widget? titleWidget,
    Widget? child,
    List<Widget>? actions,
    AppBottomSheetSize size = AppBottomSheetSize.large,
    double? maxHeightRatio,
    BaseBottomSheetConfig? config,
    EdgeInsets? padding,
    double? bottomPadding,
    bool isScrollable = true,
    bool showTopLine = true,
    bool dismissOnTapOutside = true,
  }) {
    assert(child != null || (actions != null && actions.isNotEmpty));
    FocusManager.instance.primaryFocus?.unfocus();

    final ratio = maxHeightRatio ?? size.maxHeightRatio;

    final sheet = BaseBottomSheet(
      maxHeightRatio: ratio,
      title: title,
      titleWidget: titleWidget,
      actions: actions,
      config: config ?? BaseBottomSheetConfig.standard,
      padding: padding,
      bottomPadding: bottomPadding,
      isScrollable: isScrollable,
      showTopLine: showTopLine,
      child: child,
    );

    showModalBottomSheet<void>(
      context: this,
      isScrollControlled: true,
      isDismissible: dismissOnTapOutside,
      enableDrag: true,
      showDragHandle: false,
      useSafeArea: true,
      // الارتفاع يُقيَّد داخل [BaseBottomSheet] — قيدٌ يُبنى هنا مرة واحدة لا
      // يرى الكيبورد، ولا ينكمش معه. (وكان `double.infinity` مع `ratio >= 1.0`
      // يعني ورقة بلا سقف إطلاقاً.)
      builder: (_) => sheet,
    );
  }
}

class BaseBottomSheet extends StatelessWidget {
  BaseBottomSheet({
    super.key,
    this.title,
    this.titleWidget,
    this.child,
    this.actions,
    this.actionsAlignment = CrossAxisAlignment.stretch,
    this.config = BaseBottomSheetConfig.standard,
    this.padding,
    this.isScrollable = true,
    this.bottomPadding,
    this.showTopLine = true,
    this.maxHeightRatio = 0.9,
  }) : assert(
         child == null || actions == null,
         'لا تستخدم child و actions معاً.',
       ),
       assert(
         child != null || (actions != null && actions.isNotEmpty),
         'قدّم إما child أو قائمة actions غير فارغة.',
       );

  final String? title;
  final Widget? titleWidget;
  final Widget? child;
  final List<Widget>? actions;
  final CrossAxisAlignment actionsAlignment;
  final BaseBottomSheetConfig config;
  final EdgeInsets? padding;
  final bool isScrollable;
  final double? bottomPadding;
  final bool showTopLine;

  /// **سقف** الارتفاع كنسبة من الشاشة (ناقصاً الكيبورد) — لا ارتفاعاً مطلوباً.
  final double maxHeightRatio;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final effectiveBottom = bottomPadding ?? config.bottomPadding;
    // الكيبورد يدخل الحشوة — نفس علّة `AppBottomSheet`: `bottomPadding` شريط
    // إيماءات، و`SafeArea` تحته تهبط لصفر وقت الكتابة.
    final keyboardInset = context.keyboardInset;
    final effectivePadding =
        (padding ??
                EdgeInsets.fromLTRB(
                  config.horizontalPadding,
                  0,
                  config.horizontalPadding,
                  effectiveBottom + context.bottomPadding,
                ))
            .copyWith(
              bottom:
                  (padding?.bottom ?? (effectiveBottom + context.bottomPadding)) + keyboardInset,
            );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: actionsAlignment,
      children: [
        if (title != null || titleWidget != null) ...[
          Padding(
            padding: EdgeInsets.only(bottom: config.titleBottomSpacing),
            child:
                titleWidget ??
                Text(
                  title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
          ),
        ],
        if (child != null) child! else ...(actions ?? const []),
      ],
    );

    final body = isScrollable
        ? SingleChildScrollView(padding: effectivePadding, child: content)
        : Padding(padding: effectivePadding, child: content);

    final columnChildren = <Widget>[
      if (showTopLine) _TopLine(parentContext: context, config: config),
      // `Flexible(loose)` لا `Expanded`، و`min` لا `max`: الورقة بمقاس محتواها،
      // والتمرير لا يعمل إلا فوق السقف.
      if (isScrollable) Flexible(fit: FlexFit.loose, child: body) else body,
    ];

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: (context.sh - keyboardInset) * maxHeightRatio.clamp(0.1, 0.95),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: columnChildren,
        ),
      ),
    );
  }
}

class _TopLine extends StatelessWidget {
  const _TopLine({required this.parentContext, required this.config});

  final BuildContext parentContext;
  final BaseBottomSheetConfig config;

  @override
  Widget build(BuildContext context) {
    final colors = parentContext.colors;
    return Padding(
      padding: EdgeInsets.only(
        top: config.topLineTopPadding,
        bottom: config.topLineBottomPadding,
      ),
      child: Center(
        child: Container(
          width: config.topLineWidth,
          height: config.topLineHeight,
          decoration: BoxDecoration(
            color: colors.dividerSubtle,
            borderRadius: BorderRadius.circular(config.topLineHeight / 2),
          ),
        ),
      ),
    );
  }
}
