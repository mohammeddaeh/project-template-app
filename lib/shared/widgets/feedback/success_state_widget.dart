import 'package:flutter/material.dart';
import 'package:app_template/shared/widgets/states/app_state_widget.dart';

/// حالة النجاح الإيجابية (inline — ليست toast).
/// Wrapper حول [AppStateWidget] للتوافق مع الكود القديم.
/// للاستخدام الجديد: `AppStateWidget(type: AppStateType.success, ...)`
class SuccessStateWidget extends StatelessWidget {
  const SuccessStateWidget({
    super.key,
    required this.messageKey,
    this.icon = Icons.check_circle_outline,
  });

  final String messageKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppStateWidget(
    type: AppStateType.success,
    titleKey: messageKey,
    icon: icon,
  );
}
