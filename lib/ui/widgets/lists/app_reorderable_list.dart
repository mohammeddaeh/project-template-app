import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/platform/haptics/haptic_service.dart';
import 'package:app_template/ui/theme/app_elevation.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// **قائمةٌ تُرتَّب بالسحب** — غلافُ `ReorderableListView.builder`.
///
/// ```dart
/// AppReorderableList<Task>(
///   items: tasks,
///   itemKey: (t) => t.id,
///   itemBuilder: (context, task, index) => AppListTile(titleText: task.title),
///   onReorder: (from, to) => setState(() => tasks.insert(to, tasks.removeAt(from))),
/// )
/// ```
///
/// ما يحمله فوق الإطار:
/// - **[onReorder] يستلم الموضعَ النهائيّ.** الإطار يعطي، حين يُسحب صفٌّ إلى
///   الأسفل، موضعاً يزيد واحداً (يُحسب قبل حذف الصفّ من مكانه) — وكلُّ مستدعٍ
///   يطرح الواحد بيده أو ينساه. هنا يُطرح مرّةً، فـ`insert(to, removeAt(from))`
///   صحيحٌ كما هو.
/// - **المقبض** ([handle]): `true` ⇐ أيقونة سحبٍ بنهاية الصفّ تبدأ السحبَ فوراً،
///   والصفّ نفسه يبقى حرّاً للنقر والتمرير. `false` ⇐ ضغطةٌ مطوّلة على الصفّ كلّه.
/// - **الصفّ المرفوع** بظلٍّ وتكبيرٍ طفيف من الثيم، بمنحنى `AppMotion` — ومع
///   «تقليل الحركة» يظهر مرفوعاً بلا انتقال.
/// - **اهتزازٌ خفيف عند الالتقاط** حين تكون `HapticService` مسجَّلة
///   (`AppFeatures.haptics`)، ولا شيء حين لا تكون.
///
/// داخل صفحةٍ تتمرّر بنفسها: `shrinkWrap: true` و`NeverScrollableScrollPhysics()`.
class AppReorderableList<T> extends StatelessWidget {
  const AppReorderableList({
    required this.items,
    required this.itemKey,
    required this.itemBuilder,
    required this.onReorder,
    this.handle = false,
    this.shrinkWrap = false,
    this.physics,
    super.key,
  });

  final List<T> items;

  /// هويّةُ العنصر الثابتة (معرّفه) — بها يتبع الإطارُ الصفَّ أثناء السحب.
  final Object Function(T item) itemKey;

  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// `from` موضعُ العنصر قبل السحب، و`to` موضعُه **بعد** النقل — جاهزٌ لـ
  /// `list.insert(to, list.removeAt(from))`. لا يُنادى حين يعود العنصر لمكانه.
  final void Function(int from, int to) onReorder;

  /// مقبضُ سحبٍ بنهاية كل صفّ بدل الضغطة المطوّلة.
  final bool handle;

  final bool shrinkWrap;
  final ScrollPhysics? physics;

  void _onReorder(int oldIndex, int newIndex) {
    final to = newIndex > oldIndex ? newIndex - 1 : newIndex;
    if (to == oldIndex) return;
    onReorder(oldIndex, to);
  }

  void _onPickUp(int _) {
    if (GetIt.I.isRegistered<HapticService>()) {
      GetIt.I<HapticService>().selection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      itemCount: items.length,
      shrinkWrap: shrinkWrap,
      physics: physics,
      // المقبض والضغطة المطوّلة يُبنيان هنا — مقبضُ الإطار الافتراضي يظهر على
      // سطح المكتب وحده، فيختلف السلوك بين المنصّات.
      buildDefaultDragHandles: false,
      onReorder: _onReorder,
      onReorderStart: _onPickUp,
      proxyDecorator: (child, index, animation) =>
          _LiftedRow(animation: animation, child: child),
      itemBuilder: (context, index) {
        final item = items[index];
        final row = itemBuilder(context, item, index);
        return KeyedSubtree(
          key: ValueKey<Object>(itemKey(item)),
          child: handle
              ? Row(
                  children: [
                    Expanded(child: row),
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.screen.space(12),
                          vertical: context.screen.space(8),
                        ),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          color: context.colors.iconSubtle,
                        ),
                      ),
                    ),
                  ],
                )
              : ReorderableDelayedDragStartListener(index: index, child: row),
        );
      },
    );
  }
}

/// الصفّ أثناء سحبه — يرتفع بظلٍّ ويكبر قليلاً.
class _LiftedRow extends StatelessWidget {
  const _LiftedRow({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  /// تكبيرُ الصفّ المرفوع — يكفي ليُرى منفصلاً عن جيرانه.
  static const double _liftScale = 1.02;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lifted = AppElevation.md(colors.shadowColor);
    final reduced = AppMotion.of(context).isReduced;
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.baseCurve,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = reduced ? 1.0 : curved.value;
        return Transform.scale(
          scale: lerpDouble(1, _liftScale, t)!,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdRadius,
              boxShadow: BoxShadow.lerpList(AppElevation.none, lifted, t),
            ),
            child: child,
          ),
        );
      },
      // الصفّ المسحوب يُرسم بطبقةٍ فوق الصفحة بلا Material فوقه.
      child: Material(
        color: colors.bgElevated,
        borderRadius: AppRadius.mdRadius,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
