/// Provides the current app locale code to infrastructure components.
///
/// Implemented at the infra level — allows [AuthInterceptor] to read
/// the active language without depending on BuildContext or routes.
abstract interface class LocaleProvider {
  String get languageCode;
}
