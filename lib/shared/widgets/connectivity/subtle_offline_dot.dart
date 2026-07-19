import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

/// نقطة حمراء صغيرة تظهر في الزاوية العلوية عند بدء انقطاع الاتصال.
/// تظهر قبل [OfflineBanner] بفترة قصيرة — يُستخدَم داخل [ConnectivityOverlay].
class SubtleOfflineDot extends StatelessWidget {
  const SubtleOfflineDot({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    return Positioned(
      top: top,
      right: 12,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: context.colors.stateError,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
