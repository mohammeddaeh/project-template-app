import 'package:flutter/material.dart';

import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// جسدُ نموذجٍ من شاشات الحساب: يمرَّر، ويُغلق الكيبورد بلمسةٍ خارجه، وعرضُه
/// عرضُ نموذجٍ على اللوح (`ContentWidth.form`).
///
/// **التمريرُ عريضٌ والنموذجُ وحده محدود**: لمسةُ سحبٍ على هامش اللوح تمرّر
/// الشاشة كما تمرّرها لمسةٌ على الحقول.
class AuthFormBody extends StatelessWidget {
  const AuthFormBody({super.key, required this.padding, required this.child});

  final EdgeInsetsGeometry padding;

  /// الـ`Form` نفسه.
  final Widget child;

  @override
  Widget build(BuildContext context) => KeyboardDismissWidget(
    child: SingleChildScrollView(
      padding: padding,
      child: ResponsiveContentBox(
        width: ContentWidth.form,
        horizontalPadding: false,
        child: child,
      ),
    ),
  );
}
