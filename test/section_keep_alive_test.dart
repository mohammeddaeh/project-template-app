import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A self-loading section inside a `ListView` must not refetch on every scroll.
///
/// `ListView` disposes children that leave the cache extent and rebuilds them on
/// the way back, so anything loading in `initState` (or in `BlocProvider.create`)
/// runs again — reported live on the profile screen, where scrolling down and
/// back refetched the assignments every time.
///
/// The two cases are asserted TOGETHER because only the pair is meaningful: the
/// second proves the ListView really does dispose here, so a passing first case
/// cannot be an artefact of the child never leaving the viewport.
void main() {
  testWidgets('AutomaticKeepAliveClientMixin stops the refetch', (tester) async {
    final withKeepAlive = await _loadsAfterScrollRoundTrip(tester, keepAlive: true);
    expect(
      withKeepAlive,
      1,
      reason:
          'A kept-alive section must load once per visit. More than one means '
          'every scroll pass costs a request, flickers loaded content back to a '
          'spinner, and discards whatever the reader had expanded.',
    );
  });

  testWidgets('and without it the refetch is real, not hypothetical', (
    tester,
  ) async {
    final withoutKeepAlive = await _loadsAfterScrollRoundTrip(
      tester,
      keepAlive: false,
    );
    expect(
      withoutKeepAlive,
      greaterThan(1),
      reason:
          'If this ever reads 1, the ListView stopped disposing off-screen '
          'children and the test above proves nothing.',
    );
  });
}

Future<int> _loadsAfterScrollRoundTrip(
  WidgetTester tester, {
  required bool keepAlive,
}) async {
  var loads = 0;
  final controller = ScrollController();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          controller: controller,
          children: [
            _SelfLoadingSection(keepAlive: keepAlive, onLoad: () => loads++),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    ),
  );

  controller.jumpTo(1900);
  await tester.pump();
  controller.jumpTo(0);
  await tester.pump();

  return loads;
}

class _SelfLoadingSection extends StatefulWidget {
  const _SelfLoadingSection({required this.keepAlive, required this.onLoad});

  final bool keepAlive;
  final VoidCallback onLoad;

  @override
  State<_SelfLoadingSection> createState() => _SelfLoadingSectionState();
}

class _SelfLoadingSectionState extends State<_SelfLoadingSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void initState() {
    super.initState();
    widget.onLoad();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const SizedBox(height: 300);
  }
}
