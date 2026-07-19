import 'package:app_template/core/foundation/contracts/locale_provider.dart';
import 'package:injectable/injectable.dart';

/// Mutable locale holder for infrastructure components (e.g. [AuthInterceptor]).
///
/// Updated by the presentation layer (app.dart / locale change handler).
/// Falls back to 'ar' until explicitly set.
@LazySingleton(as: LocaleProvider)
class AppLocaleProvider implements LocaleProvider {
  String _languageCode = 'ar';

  @override
  String get languageCode => _languageCode;

  void setLanguage(String code) => _languageCode = code;
}
