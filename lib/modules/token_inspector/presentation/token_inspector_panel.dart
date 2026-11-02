import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/token_inspector/integration/inspector_recorder.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/inspector_parts.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/keycloak_checks_card.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/live_session_card.dart';
import 'package:app_template/modules/token_inspector/token_inspector.dart';

/// **الجلسة الآن وفحوص Keycloak — داخل أي شاشة.**
///
/// ```dart
/// const TokenInspectorPanel()
/// ```
///
/// يرسم لا شيء حين [TokenInspector.enabled] `false` (العلَم مطفأ، أو نسخةُ
/// `prod` release) — فسطرٌ نُسي بشاشةٍ لا يراه المستخدم. و`build_apk.dart`
/// يعدّده قبل بناء إصدار ليُحذف.
///
/// كلُّه LTR: نصوصٌ إنكليزية، والسياق العربي يقلب ترتيب أسطرها.
class TokenInspectorPanel extends StatelessWidget {
  const TokenInspectorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    if (!TokenInspector.enabled || !getIt.isRegistered<InspectorRecorder>()) {
      return const SizedBox.shrink();
    }
    final recorder = getIt<InspectorRecorder>();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const InspectorSectionTitle('Session now'),
          LiveSessionCard(recorder: recorder),
          KeycloakChecksCard(recorder: recorder),
        ],
      ),
    );
  }
}
