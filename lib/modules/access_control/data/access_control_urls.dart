/// مسارات `modules/access_control/` — **بجوار الموديول لا بـ`ApiUrls`**.
///
/// **والقاعدة عامّة**: `ApiUrls` يجيب على «ما الذي يطلبه هذا التطبيق؟»، وخلطُ
/// مسارات موديولٍ **اختياريٍّ قد يكون مطفأً** به يجعل الجوابَ يحمل ما لا
/// يُنادى — والوسمُ بتعليقٍ يُقرأ حين يُبحث عنه، لا حين يُتصفَّح.
///
/// فمن يُشعل الموديول يجد مساراتِه بجواره، ومن يُطفئه لا يراها أصلاً.
/// راجع `readme/31_MODULE_PERMISSIONS.md`.
abstract class AccessControlUrls {
  /// The caller's own resolved permissions. **Any signed-in account may call
  /// it** — needing a permission to discover your permissions is a circle with
  /// no entry point.
  static const String authzMe = '/authz/me';

  /// Every permission the server declares, grouped by resource. Requires
  /// `roles.view`.
  ///
  /// The roles screen is built entirely from this response — a feature guarded
  /// server-side needs **no** Dart change to appear in it.
  static const String authzCatalog = '/authz/catalog';

  static const String authzRoles = '/authz/roles';
  static String authzRole(int id) => '/authz/roles/$id';
  static String authzRolePermissions(int id) => '/authz/roles/$id/permissions';
  static String authzUserAccess(int userId) => '/authz/users/$userId/access';
  static String authzUserRoles(int userId) => '/authz/users/$userId/roles';
  static String authzUserOverrides(int userId) =>
      '/authz/users/$userId/overrides';
}
