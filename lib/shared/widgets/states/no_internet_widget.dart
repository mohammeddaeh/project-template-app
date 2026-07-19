import 'package:flutter/material.dart';
import 'package:app_template/shared/widgets/states/app_state_widget.dart';

/// حالة انقطاع الإنترنت.
/// Wrapper حول [AppStateWidget] للتوافق مع الكود القديم.
/// للاستخدام الجديد: `AppStateWidget(type: AppStateType.noInternet, ...)`
class NoInternetWidget extends StatelessWidget {
  const NoInternetWidget({
    super.key,
    this.messageKey = 'noInternet',
    this.onRetry,
    this.retryLabelKey = 'retry',
  });

  final String messageKey;
  final VoidCallback? onRetry;
  final String retryLabelKey;

  @override
  Widget build(BuildContext context) => AppStateWidget(
        type: AppStateType.noInternet,
        titleKey: messageKey,
        onAction: onRetry,
        actionLabelKey: onRetry != null ? retryLabelKey : null,
      );
}
