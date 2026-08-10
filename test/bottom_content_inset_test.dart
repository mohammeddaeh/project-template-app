import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/presentation/extensions/screen_sizes_extensions.dart';

/// The one fact every tab screen depends on and none of them can check.
///
/// `MainShellScreen` uses `extendBody: true`, so its `NavigationBar` sits ON TOP
/// of the body. The only thing that knows the bar is there is the `padding`
/// Flutter injects into the body's `MediaQuery` — `viewPadding` does not change,
/// and a hard-coded number cannot know the bar's height.
///
/// This is asserted rather than read because the failure is silent: the screen
/// renders, scrolls, and simply never reveals its last widget. That is exactly
/// how `LogoutSection` stayed unreachable on the profile tab.
void main() {
  testWidgets(
    'bottomContentInset sees the navigation bar, viewPadding does not',
    (tester) async {
      const systemInset = 24.0;
      late double contentInset;
      late double viewPaddingInset;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: systemInset),
            viewPadding: EdgeInsets.only(bottom: systemInset),
          ),
          child: MaterialApp(
            home: Scaffold(
              extendBody: true,
              body: Builder(
                builder: (context) {
                  contentInset = context.bottomContentInset;
                  viewPaddingInset = context.bottomPadding;
                  return const SizedBox.expand();
                },
              ),
              bottomNavigationBar: const SizedBox(height: 80),
            ),
          ),
        ),
      );

      expect(
        contentInset,
        greaterThanOrEqualTo(80),
        reason:
            'bottomContentInset must cover the navigation bar. Anything less '
            'and a scrollable ends underneath it, with its last item '
            'permanently unreachable.',
      );

      // Measured, not assumed: the bar consumes the system inset, so the body
      // is told there is NO bottom view padding at all. `bottomPadding` is
      // therefore not merely short inside a tab — it is zero, and a screen
      // padded with it gets nothing whatsoever.
      expect(
        viewPaddingInset,
        0,
        reason:
            'viewPadding is fully blind inside a shell — this is the trap. A '
            'screen using it believes it has padded for the system and has in '
            'fact padded for nothing.',
      );
    },
  );

  testWidgets('outside a shell the two agree — no phantom gap', (tester) async {
    const systemInset = 24.0;
    late double contentInset;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(bottom: systemInset),
          viewPadding: EdgeInsets.only(bottom: systemInset),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                contentInset = context.bottomContentInset;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );

    // A pushed route has no navigation bar, so the padding must collapse back
    // to the system inset. A fixed filler would leave dead space here instead.
    expect(contentInset, systemInset);
  });
}
