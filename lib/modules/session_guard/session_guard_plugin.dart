import 'package:get_it/get_it.dart';

import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/session_guard/integration/session_guard_bootstrap.dart';

/// قفل جلسةٍ محلّي — بصمةٌ أو رقمٌ، لا تسجيل خروجٍ كامل — بعد خمولٍ أو عودةٍ
/// من الخلفية. راجع `lib/modules/session_guard/SETUP.md`.
///
/// ## التفعيل
/// 1. `AppFeatures.sessionGuard = true`
/// 2. لا شيء آخر — `ModulesBootstrap.initializeAll()` ينادي هذا تلقائياً،
///    و`SessionGuardGate` بالقشرة يسأل الـDI عن حالته.
///
/// ## الإطفاء
/// اترك العلَم `false`. `initialize` يعود فوراً، ولا شيء يُسجَّل — و
/// `SessionGuardGate` يعرض ابنه مباشرةً بلا حتى بناء cubit. **صفر أثر**، نفس
/// عقد كل موديول آخر بالقالب.
abstract final class SessionGuardPlugin {
  static bool _initialized = false;

  static const String _tag = 'SESSION_GUARD';

  static Future<void> initialize(GetIt di) async {
    if (_initialized) return;
    if (!AppFeatures.sessionGuard) {
      LogService.debug(
        'SessionGuardPlugin disabled (AppFeatures.sessionGuard=false).',
        tag: _tag,
      );
      return;
    }

    LogService.debug('SessionGuardPlugin initializing...', tag: _tag);
    registerSessionGuard(di);

    _initialized = true;
    LogService.debug('SessionGuardPlugin ready.', tag: _tag);
  }

  /// لإعادة التهيئة بالاختبارات فقط.
  static void reset() => _initialized = false;
}
