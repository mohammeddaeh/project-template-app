import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/layout/app_list_tile.dart';
import 'package:app_template/ui/widgets/misc/shimmer_text.dart';
import 'package:app_template/ui/widgets/placeholders/skeleton_scope.dart';

/// **الهيكلُ هو الشاشةُ نفسُها، لا نسخةٌ ثانية منها.**
///
/// وما يُقاس هنا هو الفرق الذي يجعل ذلك صحيحاً: نفسُ الشجرة تُرسم بالحالتين،
/// والمتبدّلُ **ما يُلبَس** — البيانةُ وحدها، واللافتةُ تبقى مقروءة.
void main() {
  Widget host(Widget child, {required bool loading}) => MaterialApp(
    theme: AppThemeData.light(const Locale('en'), AppFonts.available.first),
    home: Scaffold(body: Skeletonized(enabled: loading, child: child)),
  );

  testWidgets('outside a skeleton, ShimmerText is a plain Text', (t) async {
    await t.pumpWidget(host(const ShimmerText('Damascus'), loading: false));

    expect(find.text('Damascus'), findsOneWidget);
  });

  testWidgets('inside a skeleton, the dynamic value is covered', (t) async {
    await t.pumpWidget(host(const ShimmerText('Damascus'), loading: true));

    // **النصُّ يبقى بالشجرة بقصد** — مقاسُه هو ما يملأ العظم، فلا تقفز الصفحة
    // حين يصل الجواب. وهذا نفسُه ما يجعل `find.text` يجده: المقيسُ ليس غيابَه
    // بل **أنه لا يُرسم** — `Opacity(0)` فوقه.
    expect(find.text('Damascus'), findsOneWidget);

    final painted = t.widget<Opacity>(
      find.ancestor(of: find.text('Damascus'), matching: find.byType(Opacity)),
    );
    expect(painted.opacity, 0, reason: 'the value is measured, not painted');
  });

  testWidgets('a fixed label is NOT covered, only the value is', (t) async {
    await t.pumpWidget(
      host(
        const AppListTile(titleKey: 'A fixed label', subtitleText: 'Damascus'),
        loading: true,
      ),
    );

    // اللافتةُ ليست داخل عظم — تُقرأ أثناء الانتظار كما تُقرأ بعده.
    expect(
      find.ancestor(
        of: find.text('A fixed label'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
      reason: 'a fixed label is known before the request and after it',
    );

    // والبيانةُ وحدها تُلبَس.
    expect(
      find.ancestor(of: find.text('Damascus'), matching: find.byType(Opacity)),
      findsWidgets,
    );
  });

  testWidgets('one wave for the whole tree — a single Skeletonized root', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const Column(
          children: [ShimmerText('a'), ShimmerText('b'), ShimmerText('c')],
        ),
        loading: true,
      ),
    );

    // لو ملك كلُّ عظمٍ وميضَه لبدأت المؤقّتات بلحظاتٍ مختلفة، فتُقرأ الشاشة
    // أشرطةً كلٌّ يومض وحده.
    expect(find.byType(Skeletonized), findsOneWidget);
  });
}
