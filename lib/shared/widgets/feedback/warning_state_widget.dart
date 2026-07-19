import 'package:flutter/material.dart';
import 'package:app_template/shared/widgets/states/app_state_widget.dart';

/// حالة التحذير (inline — ليست toast).
/// Wrapper حول [AppStateWidget] للتوافق مع الكود القديم.
/// للاستخدام الجديد: `AppStateWidget(type: AppStateType.warning, ...)`
class WarningStateWidget extends StatelessWidget {
  const WarningStateWidget({
    super.key,
    required this.messageKey,
    this.icon = Icons.warning_amber_rounded,
  });

  final String messageKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppStateWidget(
        type: AppStateType.warning,
        titleKey: messageKey,
        icon: icon,
      );
}
