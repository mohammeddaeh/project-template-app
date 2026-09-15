import 'package:get_it/get_it.dart';

import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/notification_center/integration/notification_center_bootstrap.dart';

/// تجميع الإشعارات الواردة داخل شاشة واحدة، بحالة مقروء/غير مقروء — طبقةٌ فوق
/// `modules/push_notifications` الموجود، لا بديلاً عنه. راجع
/// `lib/modules/notification_center/SETUP.md`.
///
/// ## التفعيل
/// 1. `AppFeatures.pushNotifications = true` (المصدر — بلا هذا لا شيء يصل)
/// 2. `AppFeatures.notificationCenter = true`
/// 3. لا شيء آخر — `ModulesBootstrap.initializeAll()` ينادي هذا تلقائياً.
///
/// ## الإطفاء
/// اترك العلَم `false`. `initialize` يعود فوراً، ولا شيء يُسجَّل. **صفر أثر**،
/// نفس عقد كل موديول آخر بالقالب.
abstract final class NotificationCenterPlugin {
  static bool _initialized = false;

  static const String _tag = 'NOTIFICATION_CENTER';

  static Future<void> initialize(GetIt di) async {
    if (_initialized) return;
    if (!AppFeatures.notificationCenter) {
      LogService.debug(
        'NotificationCenterPlugin disabled (AppFeatures.notificationCenter=false).',
        tag: _tag,
      );
      return;
    }

    LogService.debug('NotificationCenterPlugin initializing...', tag: _tag);
    await registerNotificationCenter(di);

    _initialized = true;
    LogService.debug('NotificationCenterPlugin ready.', tag: _tag);
  }

  /// لإعادة التهيئة بالاختبارات فقط.
  static void reset() => _initialized = false;
}
