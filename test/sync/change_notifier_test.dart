import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/modules/sync/domain/sync_change_notifier.dart';
import 'package:app_template/modules/sync/domain/sync_entity_store.dart';

/// The reactive read's failure modes — all of them silent.
///
/// A screen that stops updating raises nothing and logs nothing; it just shows
/// yesterday's data while everything reports success. And the opposite failure,
/// a notification loop, looks like a network problem rather than like the
/// feedback path it is.
void main() {
  group('SyncChangeNotifier', () {
    late SyncChangeNotifier notifier;

    setUp(() => notifier = SyncChangeNotifier());
    tearDown(() => notifier.dispose());

    test('a listener hears only its own entity', () async {
      final heard = <String>[];
      final sub = notifier.watch('notes').listen((_) => heard.add('notes'));

      notifier
        ..notify('notes')
        ..notify('tasks')
        ..notify('notes');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // A list refreshing because an unrelated entity synced is a re-read of a
      // whole page for nothing — free-looking, and not free on a field device.
      expect(heard, hasLength(2));
    });

    test('broadcast — two screens on the same entity both hear it', () async {
      var a = 0;
      var b = 0;
      final subA = notifier.watch('notes').listen((_) => a++);
      final subB = notifier.watch('notes').listen((_) => b++);

      notifier.notify('notes');
      await Future<void>.delayed(Duration.zero);
      await subA.cancel();
      await subB.cancel();

      expect(a, 1);
      expect(b, 1);
    });

    test('notifying after dispose is a no-op, not a crash', () async {
      await notifier.dispose();
      // The engine can outlive a screen by a few frames during teardown; a
      // write landing in that window must not take the app down.
      expect(() => notifier.notify('notes'), returnsNormally);
    });

    test('a cancelled listener stops hearing', () async {
      var count = 0;
      final sub = notifier.watch('notes').listen((_) => count++);
      await sub.cancel();

      notifier.notify('notes');
      await Future<void>.delayed(Duration.zero);

      expect(count, 0);
    });
  });

  group('SyncPageCursor', () {
    test('carries both halves — a timestamp alone cannot resume', () {
      const cursor = SyncPageCursor(updatedAt: 1755500000000, localId: 'abc');

      // `updated_at` is not unique. A page boundary inside a group of rows
      // sharing a millisecond either skips the rest of that group forever or
      // re-serves it on every page from there on; the id breaks the tie.
      expect(cursor.updatedAt, 1755500000000);
      expect(cursor.localId, 'abc');
    });
  });

  group('SyncTypedPage', () {
    test('a full page means there may be more', () {
      const page = SyncTypedPage<int>(items: [1, 2], hasMore: true);
      expect(page.hasMore, isTrue);
    });

    test('an empty page has no cursor to resume from', () {
      const page = SyncTypedPage<int>(items: [], hasMore: false);
      expect(page.nextCursor, isNull);
    });
  });
}
