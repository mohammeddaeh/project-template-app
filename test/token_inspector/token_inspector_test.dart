import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/foundation/contracts/auth_session_observer.dart';
import 'package:app_template/modules/token_inspector/domain/grant_facts.dart';
import 'package:app_template/modules/token_inspector/domain/keycloak_checks.dart';
import 'package:app_template/modules/token_inspector/domain/token_reading.dart';

/// JWT بلا توقيعٍ صالح — القراءة لا تتحقّق من التوقيع، تقرأ الحمولة وحدها.
String _jwt(Map<String, dynamic> claims) {
  String part(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  // البصمة من آخر التوقيع — فتوقيعٌ يتبع الحمولة، وإلا تطابقت بصماتُ توكنين مختلفين.
  final body = part(claims);
  return '${part({'alg': 'none'})}.$body.$body';
}

int _epoch(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

const _iss = 'https://sso.example.com/realms/app';

void main() {
  final now = DateTime(2026, 11, 2, 10);

  group('TokenReading', () {
    test('an opaque token yields its fingerprint and nothing else', () {
      final r = TokenReading.of('opaque-session-token-abcdef');
      expect(r.format, TokenFormat.opaque);
      expect(r.fingerprint, '…abcdef');
      expect(r.summary(now), 'opaque · …abcdef');
    });

    test('the summary never carries the token itself', () {
      final token = _jwt({
        'typ': 'Offline',
        'iat': _epoch(now),
        'exp': _epoch(now.add(const Duration(days: 30))),
      });
      final summary = TokenReading.of(token).summary(now);
      expect(summary, isNot(contains(token)));
      expect(summary, startsWith('Offline · 30.0 d left'));
    });

    test('an issuer under /realms/ is read as Keycloak', () {
      expect(TokenReading.of(_jwt({'iss': _iss})).isKeycloak, isTrue);
      expect(TokenReading.of(_jwt({'iss': 'https://a.b'})).isKeycloak, isFalse);
    });
  });

  group('GrantFacts after a renewal', () {
    TokenGrant grant({required DateTime refreshExp, String suffix = 'a'}) =>
        TokenGrant(
          accessToken: _jwt({'iss': _iss, 'iat': _epoch(now)}),
          refreshToken: _jwt({
            'iss': _iss,
            'typ': 'Offline',
            'exp': _epoch(refreshExp),
            'n': suffix,
          }),
          receivedAt: now,
          scope: 'openid offline_access',
        );

    test('a refresh exp that moved forward passes Max Limited', () {
      final old = grant(refreshExp: now.add(const Duration(hours: 1)));
      final next = grant(
        refreshExp: now.add(const Duration(hours: 2)),
        suffix: 'b',
      );
      final facts = GrantFacts.from(
        next,
        renewal: true,
        oldRefresh: old.refreshToken,
      );
      expect(facts.refreshExpAdvanced, isTrue);
      expect(facts.refreshRotated, isTrue);
      final check = keycloakChecks(
        facts,
        const KeycloakExpectations(),
      ).firstWhere((c) => c.name == 'Offline Session Max Limited');
      expect(check.verdict, CheckVerdict.pass);
    });

    test('a refresh exp that did not move fails Max Limited', () {
      final exp = now.add(const Duration(hours: 1));
      final facts = GrantFacts.from(
        grant(refreshExp: exp, suffix: 'b'),
        renewal: true,
        oldRefresh: grant(refreshExp: exp).refreshToken,
      );
      final check = keycloakChecks(
        facts,
        const KeycloakExpectations(),
      ).firstWhere((c) => c.name == 'Offline Session Max Limited');
      expect(check.verdict, CheckVerdict.fail);
    });

    test('facts survive an encode/decode round trip', () {
      final facts = GrantFacts.from(
        grant(refreshExp: now.add(const Duration(hours: 1))),
        renewal: false,
      );
      final back = GrantFacts.tryDecode(facts.encode())!;
      expect(back.keycloak, isTrue);
      expect(back.refreshType, 'Offline');
      expect(back.scope, 'openid offline_access');
    });
  });

  group('keycloakChecks', () {
    GrantFacts facts({String? refreshType, int? expiresIn, DateTime? iat}) =>
        GrantFacts(
          receivedAt: now,
          keycloak: true,
          expiresIn: expiresIn,
          scope: refreshType == 'Offline' ? 'openid offline_access' : 'openid',
          refreshType: refreshType,
          accessIssuedAt: iat,
        );

    InspectorCheck named(List<InspectorCheck> checks, String name) =>
        checks.firstWhere((c) => c.name == name);

    test('no expectation ⇒ observed without a verdict', () {
      final checks = keycloakChecks(
        facts(refreshType: 'Refresh', expiresIn: 300),
        const KeycloakExpectations(),
      );
      expect(
        named(checks, 'offline_access accepted').verdict,
        CheckVerdict.info,
      );
      expect(named(checks, 'Access token lifespan').verdict, CheckVerdict.info);
    });

    test('a regular refresh fails when offline is expected', () {
      final checks = keycloakChecks(
        facts(refreshType: 'Refresh'),
        const KeycloakExpectations(offline: true),
      );
      expect(
        named(checks, 'offline_access accepted').verdict,
        CheckVerdict.fail,
      );
      expect(
        named(checks, 'Refresh token lifespan').verdict,
        CheckVerdict.fail,
      );
    });

    test('an access lifespan is compared with the expected one', () {
      const expect300 = KeycloakExpectations(accessLifespanSeconds: 300);
      expect(
        named(
          keycloakChecks(facts(expiresIn: 300), expect300),
          'Access token lifespan',
        ).verdict,
        CheckVerdict.pass,
      );
      expect(
        named(
          keycloakChecks(facts(expiresIn: 60), expect300),
          'Access token lifespan',
        ).verdict,
        CheckVerdict.fail,
      );
    });

    test('a device clock off by more than 30 s fails', () {
      final skewed = facts(iat: now.subtract(const Duration(minutes: 5)));
      final ok = facts(iat: now.subtract(const Duration(seconds: 3)));
      const none = KeycloakExpectations();
      expect(
        named(keycloakChecks(skewed, none), 'Device clock').verdict,
        CheckVerdict.fail,
      );
      expect(
        named(keycloakChecks(ok, none), 'Device clock').verdict,
        CheckVerdict.pass,
      );
    });

    test('Revoke Refresh Token is never guessed', () {
      expect(
        named(
          keycloakChecks(facts(), const KeycloakExpectations()),
          'Revoke Refresh Token',
        ).verdict,
        CheckVerdict.unknown,
      );
    });
  });

  test('the relay forwards to the observer attached after it was built', () {
    final relay = AuthSessionRelay();
    final seen = _Recording();
    // A reference taken before `attach` — the interceptor's situation.
    final AuthSessionObserver early = relay;
    relay.attach(seen);
    early.onRefreshDeferred('connectionError');
    expect(seen.deferred, ['connectionError']);
  });
}

class _Recording extends NoAuthSessionObserver {
  final deferred = <String>[];

  @override
  void onRefreshDeferred(String reason) => deferred.add(reason);
}
