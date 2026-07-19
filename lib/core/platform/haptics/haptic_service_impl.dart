import 'package:flutter/services.dart';
import 'package:app_template/core/platform/haptics/haptic_service.dart';

/// Flutter's built-in [HapticFeedback] wrapped behind [HapticService].
///
/// No external packages — zero cost when [AppFeatures.haptics] is `false`
/// since this class is never instantiated.
class HapticServiceImpl implements HapticService {
  const HapticServiceImpl();

  @override
  void light() => HapticFeedback.lightImpact();

  @override
  void medium() => HapticFeedback.mediumImpact();

  @override
  void heavy() => HapticFeedback.heavyImpact();

  @override
  void selection() => HapticFeedback.selectionClick();
}
