import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// Renders both kinds of refusal this module produces.
///
/// A **[message]** has already been through `FailureUiMapper` in the cubit —
/// this module never formats its own error text, so a 413 reaches the user
/// carrying the server's own "42 000 rows; the limit is 50 000" rather than
/// something generic they cannot act on.
///
/// A **[code]** covers the two problems that are not failures at all: the
/// server does not offer this resource, or does not accept imports for it.
/// Those are disagreements between what this build expects and what the
/// descriptor says, and naming them beats a spinner that never resolves.
class TransferFailureView extends StatelessWidget {
  const TransferFailureView({this.message, this.code, this.onRetry, super.key});

  final String? message;
  final String? code;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    if (code != null) {
      return ErrorStateWidget(
        messageKey: switch (code) {
          'unknown_resource' => LocaleKeys.transferUnknownResource,
          'no_format' => LocaleKeys.transferNoFormat,
          'import_unsupported' => LocaleKeys.importUnsupported,
          _ => LocaleKeys.error,
        },
        // No retry for these: the descriptor will say the same thing next time.
        // A retry button that cannot change the outcome trains people to
        // distrust every retry button.
        onRetry: null,
      );
    }

    return ErrorStateWidget(
      // `messageKey` receives an already-translated string, matching
      // `ActiveDevicesScreen`. `.tr()` on a value that is not a key returns it
      // unchanged, which is what makes the two uses compatible.
      messageKey: (message?.isNotEmpty ?? false) ? message! : LocaleKeys.error,
      onRetry: onRetry,
    );
  }
}
