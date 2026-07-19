/// Haptic feedback abstraction — thin wrapper over Flutter's [HapticFeedback].
///
/// Registered automatically when [AppFeatures.haptics] is `true`.
/// Called by [BoundFeedback] so all `context.feedback.*` calls trigger
/// the matching haptic without any extra code in the UI layer.
///
/// ─── Direct usage (rare) ─────────────────────────────────────────────────────
/// ```dart
/// getIt<HapticService>().medium();    // e.g. custom action button
/// getIt<HapticService>().selection(); // e.g. picker scroll snap
/// ```
abstract interface class HapticService {
  /// Subtle — navigation tap, passive interaction, chip touch.
  void light();

  /// Moderate — confirm action, success feedback, list item tap.
  void medium();

  /// Strong — error, destructive action, important alert.
  void heavy();

  /// Fine-grain — scroll snap, picker change, radio/checkbox toggle.
  void selection();
}
