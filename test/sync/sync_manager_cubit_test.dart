import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';
import 'package:app_template/ui/state/sync/sync_manager_cubit.dart';

/// يتحكّم فيما يُعيده `triggerManualSync` — بلا بناء `SyncController` حقيقيّة
/// (تحتاج ستّ تبعيّات، أغلبها اتصالٌ ومستمعو دورة حياة).
class _FakeSyncController implements SyncController {
  SyncBlockReason? nextResult;

  @override
  Future<SyncBlockReason?> triggerManualSync() async => nextResult;

  @override
  Future<void> init() async {}
  @override
  Future<void> dispose() async {}
  @override
  Future<void> checkIfStale() async {}

  // لا مُطلِقَ تلقائيّاً بهذا الفاهم — يكفي stream فارغ لن يُبثّ منه شيء.
  @override
  Stream<Failure> get errorStream => const Stream.empty();
}

class _FakeQueueRepository implements SyncQueueRepository {
  int pendingCount = 0;

  @override
  Future<int> countPendingJobs() async => pendingCount;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('SyncQueueRepository.${invocation.memberName} unexpected');
}

/// `triggerManualSync` كانت تُعيد `void` — فرفضٌ (بلا شبكة، بلا جلسة، ينتظر
/// واي‑فاي) وإكمالٌ فعليّ كانا لا يُفرَّقان هنا: كلاهما يُنتج `SyncSuccess`.
/// هذا هو الاختبار الذي كان سيفشل قبل الإصلاح.
void main() {
  late _FakeSyncController controller;
  late _FakeQueueRepository queue;
  late SyncManagerCubit cubit;

  setUp(() {
    controller = _FakeSyncController();
    queue = _FakeQueueRepository();
    cubit = SyncManagerCubit(controller, queue);
  });

  tearDown(() => cubit.close());

  test('a completed cycle emits SyncSuccess with the pending count', () async {
    controller.nextResult = null;
    queue.pendingCount = 3;

    await cubit.triggerSync();

    final state = cubit.state;
    expect(state, isA<SyncSuccess>());
    expect((state as SyncSuccess).pendingCount, 3);
  });

  test('a blocked cycle emits SyncBlocked, never SyncSuccess', () async {
    controller.nextResult = SyncBlockReason.noSession;

    await cubit.triggerSync();

    final state = cubit.state;
    expect(state, isA<SyncBlocked>());
    expect((state as SyncBlocked).reason, SyncBlockReason.noSession);
  });

  for (final reason in SyncBlockReason.values) {
    test('every SyncBlockReason ($reason) surfaces as SyncBlocked', () async {
      controller.nextResult = reason;
      await cubit.triggerSync();
      expect(cubit.state, isA<SyncBlocked>());
    });
  }

  test('a second trigger while running is ignored', () async {
    controller.nextResult = null;
    final first = cubit.triggerSync();
    // الحالة تصير `SyncRunning` فوراً — قبل أي `await` — فمحاولةٌ ثانية الآن
    // يجب أن تُرفض بصمت.
    expect(cubit.state, isA<SyncRunning>());
    await cubit.triggerSync();
    await first;
  });
}
