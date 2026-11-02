import 'package:flutter_test/flutter_test.dart';
import 'package:kit_contracts/kit_contracts.dart';
import 'package:kit_system/src/quick_actions_shortcuts.dart';
import 'package:quick_actions/quick_actions.dart';

/// Captures the launch handler; the platform is never reached.
class _Actions extends Fake implements QuickActions {
  QuickActionHandler? handler;
  List<ShortcutItem> items = const [];

  @override
  Future<void> initialize(QuickActionHandler handler) async =>
      this.handler = handler;

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) async =>
      this.items = items;
}

void main() {
  test('a cold-start launch waits for the first listener', () async {
    final actions = _Actions();
    final shortcuts = QuickActionsShortcuts(actions);
    await Future<void>.delayed(Duration.zero);

    actions.handler!('/welcome'); // before anyone listens
    expect(await shortcuts.launches.first, '/welcome');
  });

  test('a launch while listening arrives at once', () async {
    final actions = _Actions();
    final shortcuts = QuickActionsShortcuts(actions);
    await Future<void>.delayed(Duration.zero);
    final got = <String>[];
    final sub = shortcuts.launches.listen(got.add);
    actions.handler!('/a');
    actions.handler!('/b');
    await Future<void>.delayed(Duration.zero);
    expect(got, ['/a', '/b']);
    await sub.cancel();
  });

  test('a cold start delivered twice is one launch', () async {
    // Android hands the launch over on initialise and again via onNewIntent.
    final actions = _Actions();
    final shortcuts = QuickActionsShortcuts(actions);
    await Future<void>.delayed(Duration.zero);
    final got = <String>[];
    final sub = shortcuts.launches.listen(got.add);
    actions.handler!('/welcome');
    actions.handler!('/welcome');
    actions.handler!('/orders');
    await Future<void>.delayed(Duration.zero);
    expect(got, ['/welcome', '/orders']);
    await sub.cancel();
  });

  test('a shortcut is its path, title and icon', () async {
    final actions = _Actions();
    final shortcuts = QuickActionsShortcuts(actions);
    await shortcuts.setShortcuts(const [
      AppShortcut(path: '/orders/new', title: 'New order', icon: 'ic_add'),
    ]);
    final item = actions.items.single;
    expect(item.type, '/orders/new');
    expect(item.localizedTitle, 'New order');
    expect(item.icon, 'ic_add');
  });
}
