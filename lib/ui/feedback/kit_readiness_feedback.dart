import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/permissions/kit_readiness.dart';
import 'package:app_template/core/platform/permissions/permissions_service.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/feedback_config.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/feedback/feedback_type.dart';

/// Says why a device kit's capability did not start — after `ensureKitReady`.
///
/// A permanent refusal carries a button to the system settings: it is the only
/// place the answer can change, and a message alone leaves the user hunting.
/// The three keys are the caller's — "dictation needs…" and "recording
/// needs…" are different sentences.
void showKitReadiness(
  BuildContext context,
  KitReadiness readiness, {
  required String deniedKey,
  required String blockedKey,
  required String unsupportedKey,
}) {
  switch (readiness) {
    case KitReadiness.blocked:
      context.feedback.show(
        FeedbackConfig(
          type: FeedbackType.warning,
          message: blockedKey.tr(),
          action: FeedbackAction(
            label: LocaleKeys.kitOpenSettings.tr(),
            onTap: () => getIt<PermissionsService>().openSettings(),
          ),
        ),
      );
    case KitReadiness.denied:
      context.feedback.warning(deniedKey.tr());
    case KitReadiness.unsupported:
      context.feedback.warning(unsupportedKey.tr());
    case KitReadiness.ready:
      break;
  }
}
