import 'package:app_template/modules/token_inspector/domain/grant_facts.dart';
import 'package:app_template/modules/token_inspector/domain/token_reading.dart';

enum CheckVerdict {
  /// ✓
  pass,

  /// ✗
  fail,

  /// `?` — لا يُرصد بعد، أو لا يُرصد أبداً بلا تجربةٍ تُبطل الجلسة.
  unknown,

  /// يُعرض المرصود بلا حكم — لا قيمةَ متوقّعة يُقارن بها.
  info,
}

class InspectorCheck {
  const InspectorCheck({
    required this.name,
    required this.observed,
    required this.verdict,
    this.fix,
  });

  final String name;
  final String observed;
  final CheckVerdict verdict;

  /// أين يُصلَح بلوحة Keycloak — `null` حين لا شيء يُصلَح.
  final String? fix;
}

/// القيمُ المتوقّعة من `.env.<flavor>.json` — **كلُّها اختيارية**. غيابُ قيمة
/// يعني عرضَ المرصود بلا حكم، لا افتراضاً مخمَّناً.
class KeycloakExpectations {
  const KeycloakExpectations({
    this.accessLifespanSeconds,
    this.offlineIdleSeconds,
    this.offline,
  });

  final int? accessLifespanSeconds;
  final int? offlineIdleSeconds;
  final bool? offline;

  /// مفاتيح `.env.<flavor>.json` الغائبة — فحوصُها تعرض المرصود بلا حكم.
  List<String> get missingKeys => [
    if (accessLifespanSeconds == null) 'KEYCLOAK_EXPECT_ACCESS_LIFESPAN_S',
    if (offlineIdleSeconds == null) 'KEYCLOAK_EXPECT_OFFLINE_IDLE_S',
    if (offline == null) 'KEYCLOAK_EXPECT_OFFLINE',
  ];
}

/// فرقٌ أكبر من هذا بين `iat` وساعة الجهاز ⇒ الساعة خاطئة، والعدّادات تكذب.
const clockSkewTolerance = Duration(seconds: 30);

/// إعدادات الـrealm **مما يُرى بالردود وحدها** — دالّةٌ خالصة.
List<InspectorCheck> keycloakChecks(
  GrantFacts facts,
  KeycloakExpectations expect,
) {
  final offline = facts.refreshType == 'Offline';
  final scopeHasOffline =
      facts.scope?.split(' ').contains('offline_access') ?? false;

  return [
    _offlineAccess(facts, expect, offline: offline, inScope: scopeHasOffline),
    _accessLifespan(facts, expect),
    _refreshLifespan(facts, expect, offline: offline),
    _offlineMaxLimited(facts, offline: offline),
    _rotation(facts),
    const InspectorCheck(
      name: 'Revoke Refresh Token',
      observed: 'not observable without a test that kills the session',
      verdict: CheckVerdict.unknown,
      fix:
          'Realm settings → Tokens → Revoke Refresh Token (keep OFF: a lost '
          'refresh reply on a weak signal would sign the user out)',
    ),
    _clockSkew(facts),
  ];
}

InspectorCheck _offlineAccess(
  GrantFacts f,
  KeycloakExpectations e, {
  required bool offline,
  required bool inScope,
}) {
  final accepted = offline && inScope;
  final expected = e.offline;
  return InspectorCheck(
    name: 'offline_access accepted',
    observed:
        'scope ${inScope ? 'has' : 'lacks'} offline_access · '
        'refresh typ=${f.refreshType ?? '-'}',
    verdict: expected == null
        ? CheckVerdict.info
        : (accepted == expected ? CheckVerdict.pass : CheckVerdict.fail),
    fix:
        'Client → Client scopes → offline_access (Optional), and the '
        'offline_access role for the user; the token request must send '
        "scope 'openid offline_access'",
  );
}

InspectorCheck _accessLifespan(GrantFacts f, KeycloakExpectations e) {
  final seen = f.expiresIn;
  final expected = e.accessLifespanSeconds;
  return InspectorCheck(
    name: 'Access token lifespan',
    observed: seen == null
        ? 'expires_in not sent'
        : '${readableDuration(seen)}'
              '${expected == null ? '' : ' (expected ${readableDuration(expected)})'}',
    verdict: seen == null
        ? CheckVerdict.unknown
        : expected == null
        ? CheckVerdict.info
        : (seen == expected ? CheckVerdict.pass : CheckVerdict.fail),
    fix:
        'Realm settings → Tokens → Access Token Lifespan (a client value '
        'overrides it: Client → Advanced)',
  );
}

InspectorCheck _refreshLifespan(
  GrantFacts f,
  KeycloakExpectations e, {
  required bool offline,
}) {
  final seen = f.refreshExpiresIn;
  final type = f.refreshType ?? '-';
  final value = seen == null
      ? 'refresh_expires_in not sent'
      : seen == 0
      ? 'no expiry sent (0)'
      : readableDuration(seen);

  // `typ=Refresh`: العمرُ هنا هو `SSO Session Idle` — يموت بالخمول.
  if (type == 'Refresh') {
    return InspectorCheck(
      name: 'Refresh token lifespan',
      observed: '$value · typ=Refresh ⇒ this is SSO Session Idle',
      verdict: e.offline == true ? CheckVerdict.fail : CheckVerdict.info,
      fix: 'Realm settings → Sessions → SSO Session Idle / Max',
    );
  }

  final expected = e.offlineIdleSeconds;
  final comparable = offline && seen != null && seen > 0 && expected != null;
  return InspectorCheck(
    name: 'Refresh token lifespan',
    observed:
        '$value · typ=$type'
        '${expected == null ? '' : ' (expected idle ${readableDuration(expected)})'}',
    verdict: seen == null
        ? CheckVerdict.unknown
        : comparable
        ? (seen == expected ? CheckVerdict.pass : CheckVerdict.fail)
        : CheckVerdict.info,
    fix: 'Realm settings → Sessions → Offline Session Idle',
  );
}

InspectorCheck _offlineMaxLimited(GrantFacts f, {required bool offline}) {
  const fix = 'Realm settings → Sessions → Offline Session Max Limited';
  if (offline && !f.refreshHasExp) {
    return const InspectorCheck(
      name: 'Offline Session Max Limited',
      observed: 'offline token carries no exp ⇒ no absolute cap',
      verdict: CheckVerdict.pass,
      fix: fix,
    );
  }
  final advanced = f.refreshExpAdvanced;
  return InspectorCheck(
    name: 'Offline Session Max Limited',
    observed: switch (advanced) {
      null => 'needs one successful refresh to compare exp',
      true => 'refresh exp moved forward on renewal',
      false => 'refresh exp did NOT move ⇒ absolute cap reached',
    },
    verdict: switch (advanced) {
      null => CheckVerdict.unknown,
      true => CheckVerdict.pass,
      false => CheckVerdict.fail,
    },
    fix: fix,
  );
}

InspectorCheck _rotation(GrantFacts f) => InspectorCheck(
  name: 'Refresh token rotation',
  observed: switch (f.refreshRotated) {
    null => 'needs one successful refresh to compare',
    true => 'rotated on renewal',
    false => 'same refresh token reused',
  },
  verdict: f.refreshRotated == null ? CheckVerdict.unknown : CheckVerdict.info,
);

InspectorCheck _clockSkew(GrantFacts f) {
  final iat = f.accessIssuedAt;
  if (iat == null) {
    return const InspectorCheck(
      name: 'Device clock',
      observed: 'access token carries no iat',
      verdict: CheckVerdict.unknown,
    );
  }
  final skew = f.receivedAt.difference(iat).inSeconds;
  return InspectorCheck(
    name: 'Device clock',
    observed:
        'device ${skew >= 0 ? '+' : '-'}${readableDuration(skew.abs())} '
        'vs server iat',
    verdict: skew.abs() > clockSkewTolerance.inSeconds
        ? CheckVerdict.fail
        : CheckVerdict.pass,
    fix: 'Device settings → Date & time (automatic)',
  );
}
