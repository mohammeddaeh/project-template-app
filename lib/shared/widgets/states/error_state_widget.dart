import 'package:flutter/material.dart';
import 'package:app_template/shared/widgets/states/app_state_widget.dart';

/// حالة الخطأ.
/// Wrapper حول [AppStateWidget] للتوافق مع الكود القديم.
/// للاستخدام الجديد: `AppStateWidget(type: AppStateType.error, ...)`
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    required this.messageKey,
    this.onRetry,
    this.retryLabelKey = 'retry',
    this.icon = Icons.error_outline,
  });

  final String messageKey;
  final VoidCallback? onRetry;
  final String retryLabelKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppStateWidget(
        type: AppStateType.error,
        titleKey: messageKey,
        icon: icon,
        onAction: onRetry,
        actionLabelKey: onRetry != null ? retryLabelKey : null,
      );
}
