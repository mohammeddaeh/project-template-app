import 'dart:async';

import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/notification_center/data/notification_center_store.dart';
import 'package:app_template/modules/notification_center/domain/notification_center_item.dart';

part 'notification_center_state.dart';

/// Reads from [NotificationCenterStore] and re-emits on every change —
/// including changes written by [NotificationCenterListener] while this
/// cubit's screen is not even open, since both hold the same store instance
/// (a `@lazySingleton` — see `integration/notification_center_bootstrap.dart`).
class NotificationCenterCubit extends SafeCubit<NotificationCenterState> {
  NotificationCenterCubit(this._store) : super(const NotificationCenterLoading()) {
    _subscription = _store.changes.listen(_onItemsChanged);
    _onItemsChanged(_store.items);
  }

  final NotificationCenterStore _store;
  late final StreamSubscription<List<NotificationCenterItem>> _subscription;
  final _persistFailureController = StreamController<void>.broadcast();

  /// الشاشة تشترك هنا لتعرض `context.feedback.error(...)` — حالة الـcubit
  /// (`Loading`/`Loaded`) تبقى بيانات القائمة وحدها، وهذا حدثٌ عابرٌ منفصل
  /// عنها. راجع [_guardPersist]: القائمة بالذاكرة تُحدَّث دوماً (تفاؤلياً) حتى
  /// لو فشلت الكتابة على القرص — فبلا هذا البث كانت ضغطة «تعليم الكل مقروء»
  /// أو «مسح الكل» تبدو ناجحة، بينما التغيير يضيع عند إعادة تشغيل التطبيق
  /// بصمتٍ تام.
  Stream<void> get persistFailures => _persistFailureController.stream;

  void _onItemsChanged(List<NotificationCenterItem> items) =>
      emit(NotificationCenterLoaded(items: items));

  Future<void> markRead(String id) => _guardPersist(() => _store.markRead(id));

  Future<void> markAllRead() => _guardPersist(_store.markAllRead);

  Future<void> clearAll() => _guardPersist(_store.clearAll);

  Future<void> _guardPersist(Future<void> Function() action) async {
    try {
      await action();
    } catch (e, st) {
      LogService.error(
        'NotificationCenterCubit persist error',
        tag: 'NOTIFICATION_CENTER',
        error: e,
        stackTrace: st,
      );
      _persistFailureController.add(null);
    }
  }

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    unawaited(_persistFailureController.close());
    return super.close();
  }
}
