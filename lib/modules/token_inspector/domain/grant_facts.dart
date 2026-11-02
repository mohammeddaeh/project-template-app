import 'dart:convert';

import 'package:app_template/core/foundation/contracts/auth_session_observer.dart';
import 'package:app_template/modules/token_inspector/domain/token_reading.dart';

/// ما رُصد من آخر ردٍّ لنقطة الاعتماد — **وقائعُ بلا توكن**، فتُحفظ وتبقى بعد
/// إغلاق التطبيق، ومنها تُحسب فحوص Keycloak.
class GrantFacts {
  const GrantFacts({
    required this.receivedAt,
    required this.keycloak,
    this.expiresIn,
    this.refreshExpiresIn,
    this.scope,
    this.refreshType,
    this.refreshExpiresAt,
    this.refreshHasExp = false,
    this.accessIssuedAt,
    this.refreshExpAdvanced,
    this.refreshRotated,
  });

  /// من ردٍّ جديد — و[previous] آخرُ ما رُصد، يُقارن به بعد تجديد.
  ///
  /// [renewal] `false` للدخول: لا قديمَ يُقارن به، فتبقى المقارنتان `null`.
  factory GrantFacts.from(
    TokenGrant grant, {
    required bool renewal,
    String? oldRefresh,
    GrantFacts? previous,
  }) {
    final access = TokenReading.of(grant.accessToken);
    final refresh = TokenReading.of(grant.refreshToken);
    final old = TokenReading.of(oldRefresh);

    bool? advanced;
    bool? rotated;
    if (renewal && refresh.isPresent) {
      final oldExp = old.expiresAt ?? previous?.refreshExpiresAt;
      final newExp = refresh.expiresAt;
      if (oldExp != null && newExp != null) advanced = newExp.isAfter(oldExp);
      if (old.isPresent) rotated = old.fingerprint != refresh.fingerprint;
    }

    return GrantFacts(
      receivedAt: grant.receivedAt,
      keycloak: access.isKeycloak || refresh.isKeycloak,
      expiresIn: grant.expiresIn,
      refreshExpiresIn: grant.refreshExpiresIn,
      scope: grant.scope,
      refreshType: refresh.type,
      refreshExpiresAt: refresh.expiresAt,
      refreshHasExp: refresh.expiresAt != null,
      accessIssuedAt: access.issuedAt,
      refreshExpAdvanced: advanced,
      refreshRotated: rotated,
    );
  }

  final DateTime receivedAt;
  final bool keycloak;
  final int? expiresIn;
  final int? refreshExpiresIn;
  final String? scope;
  final String? refreshType;
  final DateTime? refreshExpiresAt;
  final bool refreshHasExp;
  final DateTime? accessIssuedAt;

  /// بعد تجديد: هل تقدّم `exp` الـrefresh الجديد عن القديم؟
  final bool? refreshExpAdvanced;

  /// بعد تجديد: هل تبدّلت بصمة الـrefresh؟
  final bool? refreshRotated;

  String encode() => jsonEncode({
    'receivedAt': receivedAt.toIso8601String(),
    'keycloak': keycloak,
    'expiresIn': expiresIn,
    'refreshExpiresIn': refreshExpiresIn,
    'scope': scope,
    'refreshType': refreshType,
    'refreshExpiresAt': refreshExpiresAt?.toIso8601String(),
    'refreshHasExp': refreshHasExp,
    'accessIssuedAt': accessIssuedAt?.toIso8601String(),
    'refreshExpAdvanced': refreshExpAdvanced,
    'refreshRotated': refreshRotated,
  });

  static GrantFacts? tryDecode(String? raw) {
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      DateTime? at(Object? v) => v is String ? DateTime.parse(v) : null;
      return GrantFacts(
        receivedAt: DateTime.parse(j['receivedAt'] as String),
        keycloak: j['keycloak'] as bool? ?? false,
        expiresIn: j['expiresIn'] as int?,
        refreshExpiresIn: j['refreshExpiresIn'] as int?,
        scope: j['scope'] as String?,
        refreshType: j['refreshType'] as String?,
        refreshExpiresAt: at(j['refreshExpiresAt']),
        refreshHasExp: j['refreshHasExp'] as bool? ?? false,
        accessIssuedAt: at(j['accessIssuedAt']),
        refreshExpAdvanced: j['refreshExpAdvanced'] as bool?,
        refreshRotated: j['refreshRotated'] as bool?,
      );
    } on Object {
      return null;
    }
  }
}
