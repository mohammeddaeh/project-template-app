import 'package:flutter/material.dart';
import 'package:app_template/shared/widgets/states/app_state_widget.dart';

/// حالة القائمة الفارغة.
/// Wrapper حول [AppStateWidget] للتوافق مع الكود القديم.
/// للاستخدام الجديد: `AppStateWidget(type: AppStateType.empty, ...)`
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.titleKey,
    this.descriptionKey,
    this.icon = Icons.inbox_outlined,
    this.iconSize = 64,
    this.onAction,
    this.actionLabelKey,
  });

  final String titleKey;
  final String? descriptionKey;
  final IconData icon;
  final double iconSize;
  final VoidCallback? onAction;
  final String? actionLabelKey;

  @override
  Widget build(BuildContext context) => AppStateWidget(
        type: AppStateType.empty,
        titleKey: titleKey,
        descriptionKey: descriptionKey,
        icon: icon,
        iconSize: iconSize,
        onAction: onAction,
        actionLabelKey: actionLabelKey,
      );
}
