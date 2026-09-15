abstract final class NotificationCenterConfig {
  /// Oldest items are dropped past this count. Unbounded growth here means
  /// unbounded `writeStringList` payload size on every single notification —
  /// this is local storage, not a paginated inbox.
  static const int maxStored = 200;
}
