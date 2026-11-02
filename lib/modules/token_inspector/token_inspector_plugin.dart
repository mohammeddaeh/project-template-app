import 'package:get_it/get_it.dart';

import 'package:app_template/core/foundation/contracts/auth_session_observer.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/token_inspector/data/inspector_store.dart';
import 'package:app_template/modules/token_inspector/integration/inspector_recorder.dart';
import 'package:app_template/modules/token_inspector/integration/inspector_session_observer.dart';
import 'package:app_template/modules/token_inspector/presentation/token_inspector_overlay.dart';
import 'package:app_template/modules/token_inspector/token_inspector.dart';
import 'package:app_template/ui/overlays/app_overlays.dart';

/// أداةُ مطوّر: تتبّعُ التوكن على الشاشة. راجع `lib/modules/token_inspector/SETUP.md`.
///
/// ## التفعيل
/// 1. `AppFeatures.tokenInspector = true`
/// 2. لا شيء آخر — `ModulesBootstrap.initializeAll()` ينادي هذا، فيعلّق مستمعَه
///    على [AuthSessionRelay]، ويسجّل طبقته بـ[AppOverlays].
///
/// ## الإطفاء
/// اترك العلَم `false` — أو ابنِ `release` بـflavor `prod`: [TokenInspector.enabled]
/// `false` بالحالتين، فلا يُسجَّل شيء ولا يُرسم شيء. **صفر أثر**.
abstract final class TokenInspectorPlugin {
  static bool _initialized = false;

  static const String _tag = 'TOKEN-INSPECTOR';

  static Future<void> initialize(GetIt di) async {
    if (_initialized) return;
    if (!TokenInspector.enabled) {
      LogService.debug(
        'TokenInspectorPlugin disabled (flag off, or a prod release build).',
        tag: _tag,
      );
      return;
    }

    final recorder = InspectorRecorder(
      InspectorStore(di<StorageService>()),
      di<SecureStorageService>(),
    );
    di.registerSingleton<InspectorRecorder>(recorder);
    await recorder.restore();

    di<AuthSessionRelay>().attach(InspectorSessionObserver(recorder));
    AppOverlays.register(
      (context, navigatorKey, child) => TokenInspectorOverlay(
        recorder: recorder,
        navigatorKey: navigatorKey,
        child: child,
      ),
    );

    _initialized = true;
    LogService.debug('TokenInspectorPlugin ready.', tag: _tag);
  }

  /// لإعادة التهيئة بالاختبارات فقط.
  static void reset() => _initialized = false;
}
