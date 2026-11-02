import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/token_inspector/domain/inspector_event.dart';
import 'package:app_template/modules/token_inspector/integration/inspector_recorder.dart';

export 'package:app_template/modules/token_inspector/presentation/token_inspector_panel.dart'
    show TokenInspectorPanel;

/// **ما تناديه من الكود** — أداةُ مطوّر لرؤية التوكن على الشاشة بلا كونسول.
///
/// الأحداث التلقائية (إقلاع · دخول · `401` · تجديد · تأجيل · رفض) تصل بلا
/// سطرٍ منك. وهذا لما تريد أن تضيفه أنت:
///
/// ```dart
/// TokenInspector.mark('Opened orders', ['Filter: today']);
/// TokenInspector.snapshot('before upload');   // ما بالتخزين الآن
/// const TokenInspectorPanel()                 // البطاقة الحيّة داخل أي شاشة
/// ```
///
/// ## لا يُرى بنسخة الإنتاج — حتى لو نُسي العلَم مُشعَلاً
///
/// [enabled] ثابتٌ يحسبه المصرِّف: `release` + flavor `prod` ⇒ `false`. فكلُّ
/// نداءٍ يعود من سطره الأول، و[TokenInspectorPanel] يرسم لا شيء، والموديول لا
/// يُقلع أصلاً. و`build_apk.dart` يعدّد كلَّ نداءٍ تركتَه قبل بناء إصدار —
/// اقرأ `SETUP.md`.
abstract final class TokenInspector {
  static const bool enabled =
      AppFeatures.tokenInspector && !(kReleaseMode && Env.flavor == 'prod');

  /// حدثٌ بعنوانك — [details] أسطرٌ بشكل `Label: value`.
  ///
  /// ⚠️ **لا تمرّر توكناً** — السجلّ يُحفظ على الجهاز ويُعرض. للتوكن [snapshot].
  static void mark(String title, [List<String> details = const []]) {
    if (!enabled) return;
    _recorder?.record(InspectorEventKind.info, title, details: details);
  }

  /// ما بالتخزين الآن، ببصمته وعمره — تحت عنوان [label].
  static void snapshot(String label) {
    if (!enabled) return;
    final recorder = _recorder;
    if (recorder == null) return;
    unawaited(() async {
      final (access, refresh) = await recorder.storedTokens();
      recorder.record(
        InspectorEventKind.info,
        'Snapshot — $label',
        details: [
          'Access: ${recorder.summary(access)}',
          if (refresh != null) 'Refresh: ${recorder.summary(refresh)}',
        ],
      );
    }());
  }

  /// `null` حتى يُقلع الموديول، أو حين لا يُقلع أبداً.
  static InspectorRecorder? get _recorder =>
      getIt.isRegistered<InspectorRecorder>()
      ? getIt<InspectorRecorder>()
      : null;
}
