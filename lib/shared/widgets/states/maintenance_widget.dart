import 'package:flutter/material.dart';
import 'package:app_template/shared/widgets/states/app_state_widget.dart';

/// حالة الصيانة.
/// Wrapper حول [AppStateWidget] للتوافق مع الكود القديم.
/// للاستخدام الجديد: `AppStateWidget(type: AppStateType.maintenance, ...)`
class MaintenanceWidget extends StatelessWidget {
  const MaintenanceWidget({
    super.key,
    this.titleKey = 'maintenance',
    this.descriptionKey,
    this.icon = Icons.construction_outlined,
  });

  final String titleKey;
  final String? descriptionKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppStateWidget(
        type: AppStateType.maintenance,
        titleKey: titleKey,
        descriptionKey: descriptionKey,
        icon: icon,
      );
}
