/// The actions on the app's launcher icon — a long press shows them, a tap
/// opens the app at that page.
///
/// Provided by `kit_system`. A shortcut is a route path: the app hands each
/// launch to its router, through the same guards as a deep link.
abstract interface class AppShortcuts {
  /// Replaces the shortcuts. The launcher shows the first few (Android four,
  /// iOS four); an empty list removes them all.
  Future<void> setShortcuts(List<AppShortcut> shortcuts);

  /// The path of each shortcut tapped — including the one that launched the
  /// app, held until the first listener arrives.
  Stream<String> get launches;
}

final class AppShortcut {
  const AppShortcut({required this.path, required this.title, this.icon});

  /// Where the shortcut opens — `/settings`, `/orders/new`.
  final String path;

  /// Already translated: the launcher shows it as given.
  final String title;

  /// A native resource — an Android drawable, an iOS asset — or none.
  final String? icon;
}
