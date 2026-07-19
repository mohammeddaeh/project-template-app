/// Abstract contract for launching external URLs and deep-links.
///
/// Implemented by [UrlLauncherServiceImpl] (url_launcher package).
/// Mock this in tests — never mock url_launcher directly.
///
/// Usage:
/// ```dart
/// final _launcher = getIt<UrlLauncherService>();
///
/// await _launcher.launch('https://example.com');
/// await _launcher.phone('+966500000000');
/// await _launcher.email('hello@example.com');
/// await _launcher.whatsapp('+966500000000');
/// ```
abstract interface class UrlLauncherService {
  /// Launches any URL in the default external browser.
  /// Returns `false` if the URL cannot be handled.
  Future<bool> launch(String url);

  /// Opens the dialer with [phoneNumber] pre-filled.
  Future<bool> phone(String phoneNumber);

  /// Opens the default mail app with [email] pre-filled.
  Future<bool> email(String email);

  /// Opens WhatsApp chat with [phoneNumber] (international format, no +).
  Future<bool> whatsapp(String phoneNumber);

  /// Opens a Telegram profile/channel by [usernameOrId].
  Future<bool> telegram(String usernameOrId);
}
