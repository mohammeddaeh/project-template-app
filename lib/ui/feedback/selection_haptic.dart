import 'package:get_it/get_it.dart';

import 'package:app_template/core/platform/haptics/haptic_service.dart';

/// اهتزازُ «تغيّر الاختيار» — لودجةٍ تبدّل قيمةً بلمسة (chip · radio · تبويب ·
/// ثيم). يُنادى حين **تتغيّر** القيمة، لا عند كل لمسة.
///
/// لا شيء حين `AppFeatures.haptics` مطفأ: الخدمة غير مسجَّلة. وما يهتزّ مع
/// رسالةٍ للمستخدم يأتي من `context.feedback.*` وحده.
void selectionHaptic() {
  if (GetIt.I.isRegistered<HapticService>()) {
    GetIt.I<HapticService>().selection();
  }
}
