/// Notification importance level — maps to Android channel importance
/// and iOS presentation options.
///
/// Library mapping is handled inside the adapter — callers use this enum only.
enum NotificationImportance {
  /// Silent, no sound or vibration.
  low,

  /// Default sound and vibration.
  normal,

  /// Higher priority, may appear as heads-up notification.
  high,

  /// Urgent — always shows as heads-up.
  max,
}
