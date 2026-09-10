import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/modules/sync/data/sync_cursor_store.dart';
import 'package:app_template/modules/sync/data/sync_database.dart';
import 'package:app_template/modules/sync/domain/sync_hydration.dart';
import 'package:app_template/modules/sync/engine/sync_pull_executor.dart';

/// **«فارغ» جوابان لا جواب** — وهذا ما يفرّق بينهما.
///
/// والخلطُ بينهما عطلٌ صامت بالاتجاهين: أوف‑لاين يرى المستخدم شاشةَ خطأ حيث يجب
/// أن يرى «لا توجد عناصر»، وأونلاين يعمل كلُّ شيء **ويُرسَل طلبٌ بكل فتحةِ شاشة**
/// بتطبيقٍ وُجد ليقرأ من الجهاز.
class _FakeCursors extends SyncCursorStore {
  // نفسُ نمط `_MemoryCursorStore` بـ`pull_merge_test`: القاعدةُ تُبنى ولا
  // تُفتح — كلُّ نداءٍ يمرّ بـ[read] أدناه، فلا sqflite ولا قناةَ منصّة.
  _FakeCursors(this._answers) : super(SyncDatabase());

  final Map<String, SyncCursor Function()> _answers;

  @override
  Future<SyncCursor> read(String entityName) async {
    final answer = _answers[entityName];
    if (answer == null) return const SyncCursor();
    return answer();
  }
}


void main() {
  test('a written cursor means the entity was pulled at least once', () async {
    final hydration = SyncHydration(
      _FakeCursors({'notes': () => const SyncCursor(updatedSince: '2026-01-01')}),
    );

    expect(await hydration.isHydrated('notes'), isTrue);
  });

  test('a beginning cursor means it was never pulled', () async {
    final hydration = SyncHydration(
      _FakeCursors({'notes': () => const SyncCursor()}),
    );

    // ولا يُعرض فراغٌ هنا — تُسأل الشبكة.
    expect(await hydration.isHydrated('notes'), isFalse);
  });

  test('an unreadable store reads as NOT hydrated', () async {
    final hydration = SyncHydration(
      _FakeCursors({'notes': () => throw StateError('db is gone')}),
    );

    // قاعدةٌ لا تُقرأ لا يجوز أن تُقنع المغلِّف بأن الفراغَ الذي يراه صادق.
    // وأسوأُ ما تفعله `false` أن تُرسل طلباً زائداً — والبديلُ أن يُعرض
    // «لا توجد عناصر» لأبٍ فيه ثمانون.
    expect(await hydration.isHydrated('notes'), isFalse);
  });

  test('hydration is per entity, never shared', () async {
    final hydration = SyncHydration(
      _FakeCursors({
        'notes': () => const SyncCursor(updatedSince: '2026-01-01'),
        'tasks': () => const SyncCursor(),
      }),
    );

    expect(await hydration.isHydrated('notes'), isTrue);
    expect(await hydration.isHydrated('tasks'), isFalse);
  });
}
