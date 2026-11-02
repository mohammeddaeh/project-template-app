import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/modules/token_inspector/domain/keycloak_checks.dart';

/// ما يعدّله المشروع — **مكانٌ واحد**.
abstract final class TokenInspectorConfig {
  /// مفتاحُ الـaccess بـ`SecureStorageService` — تقرؤه بطاقة «Session now»
  /// ويُتحقّق منه بعد كل حفظ.
  static const String accessTokenKey = PersistenceKeys.token;

  /// مفتاحُ الـrefresh — `null` لخادمٍ باعتمادٍ واحد (توكن القالب المعتم).
  /// مشروعٌ بـKeycloak يضع مفتاحه هنا، فتظهر عدّادتُه وحكمُ `Offline`.
  static const String? refreshTokenKey = null;

  /// سقفُ السجلّ — الأقدم يسقط.
  static const int maxEvents = 150;

  /// ما يُتوقَّع من الـrealm — من `.env.<flavor>.json`، **وكلُّه اختياري**:
  /// المفتاح الغائب يعني عرض المرصود بلا حكم.
  ///
  /// ```json
  /// "KEYCLOAK_EXPECT_ACCESS_LIFESPAN_S": 300,
  /// "KEYCLOAK_EXPECT_OFFLINE_IDLE_S": 2592000,
  /// "KEYCLOAK_EXPECT_OFFLINE": true
  /// ```
  static const KeycloakExpectations expectations = KeycloakExpectations(
    accessLifespanSeconds:
        bool.hasEnvironment('KEYCLOAK_EXPECT_ACCESS_LIFESPAN_S')
        ? int.fromEnvironment('KEYCLOAK_EXPECT_ACCESS_LIFESPAN_S')
        : null,
    offlineIdleSeconds: bool.hasEnvironment('KEYCLOAK_EXPECT_OFFLINE_IDLE_S')
        ? int.fromEnvironment('KEYCLOAK_EXPECT_OFFLINE_IDLE_S')
        : null,
    offline: bool.hasEnvironment('KEYCLOAK_EXPECT_OFFLINE')
        ? bool.fromEnvironment('KEYCLOAK_EXPECT_OFFLINE')
        : null,
  );
}
