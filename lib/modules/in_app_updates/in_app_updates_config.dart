/// ما يضبطه المشروع — مكانٌ واحد.
abstract final class InAppUpdatesConfig {
  /// رقم التطبيق بـApp Store (App Store Connect ← App Information).
  ///
  /// يُستعمل على iOS حين لا يحمل الخادم `app_download_url`: بدونهما لا رابطَ
  /// يُفتح، فيظهر الحوار ولا يذهب «حدّث الآن» إلى شيء.
  static const String? iosAppId = null;
}
