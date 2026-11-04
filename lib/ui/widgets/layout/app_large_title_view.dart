import 'package:flutter/material.dart';

/// عنوانٌ كبير فوق المحتوى، ينكمش إلى شريطٍ عاديّ حين يمرّر القارئ.
///
/// يوضع **جسدَ** `Scaffold` بلا `appBar` — فيبقى للشاشة زرُّها العائم وشريطُها
/// السفليّ كما هما:
///
/// ```dart
/// Scaffold(
///   body: AppLargeTitleView(
///     title: LocaleKeys.orders.tr(),
///     actions: [IconButton(...)],
///     body: PaginationBuilder<OrdersCubit, Order>(...),
///   ),
/// )
/// ```
///
/// [body] قائمةٌ تمرّر **بالمتحكّم الأساسيّ** — `ListView` · `CustomScrollView`
/// بلا `controller` · `PaginatedListView` · `PaginationBuilder` (يكشف موضعه
/// وحده). وقائمةٌ بمتحكّمٍ خاصّ تمرّر، لكن العنوان لا ينكمش فوقها.
///
/// والانكماش يتبع الإصبع، لا مدّة له — فلا شيء يُطفأ مع «تقليل الحركة».
class AppLargeTitleView extends StatelessWidget {
  const AppLargeTitleView({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverAppBar.large(title: Text(title), actions: actions),
      ],
      body: body,
    );
  }
}
