import 'package:flutter/material.dart';
import 'package:app_template/shared/widgets/states/app_state_widget.dart';

/// حالة المعلومة التوجيهية (inline — ليست toast).
/// Wrapper حول [AppStateWidget] للتوافق مع الكود القديم.
/// للاستخدام الجديد: `AppStateWidget(type: AppStateType.info, ...)`
class InfoStateWidget extends StatelessWidget {
  const InfoStateWidget({
    super.key,
    required this.messageKey,
    this.icon = Icons.info_outline_rounded,
  });

  final String messageKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppStateWidget(
        type: AppStateType.info,
        titleKey: messageKey,
        icon: icon,
      );
}
