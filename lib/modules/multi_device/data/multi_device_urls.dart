/// مسارات `modules/multi_device/` — **بجوار الموديول لا بـ`ApiUrls`**.
///
/// نفسُ قاعدة `AccessControlUrls`: موديولٌ اختياريٌّ يملك مساراتِه.
/// ⚠️ **وهي تفترض أن الجلسات عند باكِّك** — مشروعٌ يستوثق من مزوّدٍ خارجيّ
/// (Keycloak · Auth0) تُدار جلساتُه هناك، وهذا الموديول لا يخدمه.
abstract class MultiDeviceUrls {
  /// The account's own devices. The token is never returned — only its digest
  /// is stored, and only its holder ever saw the plaintext.
  static const String sessions = '/auth/sessions';
  static String session(dynamic id) => '/auth/sessions/$id';
  static const String revokeOtherSessions = '/auth/sessions/revoke-others';
}
