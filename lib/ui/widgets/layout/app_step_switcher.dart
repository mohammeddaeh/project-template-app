import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'package:app_template/ui/theme/app_motion.dart';

/// **خطواتٌ داخل شاشةٍ واحدة** — انتقال Material «shared axis» الأفقي.
///
/// ```dart
/// AppStepSwitcher(
///   step: state.step,           // 0 · 1 · 2 …
///   child: switch (state.step) { 0 => EmailStep(), _ => CodeStep() },
/// )
/// ```
///
/// التقدّم ينزلق باتجاه القراءة، والرجوع بعكسه — فيعرف المستخدم أنه تقدّم أو
/// رجع بلا أن يقرأ رقم الخطوة. والاتجاه يتبع لغة الواجهة (RTL ينعكس وحده).
///
/// لا يحفظ حالة الخطوة السابقة: ما يجب أن يبقى بين الخطوات مكانُه الـcubit.
class AppStepSwitcher extends StatefulWidget {
  const AppStepSwitcher({required this.step, required this.child, super.key});

  /// رقم الخطوة الحالية — تغيُّره يشغّل الانتقال، وزيادتُه تقدّمٌ ونقصُه رجوع.
  final int step;
  final Widget child;

  @override
  State<AppStepSwitcher> createState() => _AppStepSwitcherState();
}

class _AppStepSwitcherState extends State<AppStepSwitcher> {
  bool _reverse = false;

  @override
  void didUpdateWidget(AppStepSwitcher old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step) _reverse = widget.step < old.step;
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: AppMotion.of(context).slow,
      reverse: _reverse,
      transitionBuilder: (child, primary, secondary) => SharedAxisTransition(
        animation: primary,
        secondaryAnimation: secondary,
        transitionType: SharedAxisTransitionType.horizontal,
        fillColor: Colors.transparent,
        child: child,
      ),
      child: KeyedSubtree(key: ValueKey(widget.step), child: widget.child),
    );
  }
}
