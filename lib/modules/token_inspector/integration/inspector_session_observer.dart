import 'dart:async';

import 'package:app_template/core/foundation/contracts/auth_session_observer.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/token_inspector/domain/grant_facts.dart';
import 'package:app_template/modules/token_inspector/domain/inspector_event.dart';
import 'package:app_template/modules/token_inspector/domain/token_reading.dart';
import 'package:app_template/modules/token_inspector/integration/inspector_recorder.dart';

/// يترجم كل حدث جلسةٍ من النواة إلى بطاقةٍ بالسجلّ.
///
/// **كلُّ معالجٍ ملفوفٌ بـ[_guard]**: عقد [AuthSessionObserver] أنه لا يرمي،
/// فخطأٌ هنا يُسجَّل ولا يصل التجديدَ أبداً. والعمل غير المتزامن (قراءةُ
/// التخزين للتحقّق من الحفظ) يجري بلا انتظار.
class InspectorSessionObserver implements AuthSessionObserver {
  const InspectorSessionObserver(this._recorder);

  final InspectorRecorder _recorder;

  @override
  void onSessionRestored(String? access, String? refresh) => _guard(() async {
    if (access == null || access.isEmpty) {
      _recorder.record(InspectorEventKind.info, 'App opened — no session');
      return;
    }
    _recorder.printFull('RESTORE access', access);
    _recorder.printFull('RESTORE refresh', refresh);
    final (_, storedRefresh) = await _recorder.storedTokens();
    _recorder.record(
      InspectorEventKind.info,
      'App opened — session restored',
      details: [
        'Access: ${_recorder.summary(access)}',
        if ((refresh ?? storedRefresh) != null)
          'Refresh: ${_recorder.summary(refresh ?? storedRefresh)}',
      ],
    );
  });

  @override
  void onSignedIn(TokenGrant grant) => _guard(() async {
    _recorder.printFull('LOGIN access', grant.accessToken);
    _recorder.printFull('LOGIN refresh', grant.refreshToken);
    final saved = await _recorder.verifySaved(
      grant.accessToken,
      grant.refreshToken,
    );
    final facts = GrantFacts.from(grant, renewal: false);
    _recorder.updateFacts(facts);
    _recorder.record(
      InspectorEventKind.success,
      'Signed in',
      details: [
        'Access: ${_recorder.summary(grant.accessToken)}',
        if (grant.refreshToken != null)
          'Refresh: ${_recorder.summary(grant.refreshToken)}',
        ..._grantLines(grant),
        'Saved: $saved',
      ],
      notice:
          'Token: signed in · ${TokenReading.of(grant.refreshToken).type ?? 'session'}',
    );
  });

  @override
  void onRefreshStarted(
    String requestPath, {
    String? oldAccess,
    String? oldRefresh,
  }) => _guard(() async {
    _recorder.printFull('REFRESH old access', oldAccess);
    _recorder.printFull('REFRESH old refresh', oldRefresh);
    _recorder.record(
      InspectorEventKind.info,
      '401 — asking the server for a new token…',
      details: [
        'Request: $requestPath',
        'Old access: ${_recorder.summary(oldAccess)}',
        if (oldRefresh != null)
          'Using refresh: ${_recorder.summary(oldRefresh)}',
      ],
    );
  });

  @override
  void onRefreshSucceeded(
    TokenGrant grant, {
    String? oldAccess,
    String? oldRefresh,
  }) => _guard(() async {
    _recorder.printFull('REFRESH new access', grant.accessToken);
    _recorder.printFull('REFRESH new refresh', grant.refreshToken);
    final saved = await _recorder.verifySaved(
      grant.accessToken,
      grant.refreshToken,
    );
    final facts = GrantFacts.from(
      grant,
      renewal: true,
      oldRefresh: oldRefresh,
      previous: _recorder.facts.value,
    );
    _recorder.updateFacts(facts);
    _recorder.record(
      InspectorEventKind.success,
      'Token refreshed',
      details: [
        'Access: ${_change(oldAccess, grant.accessToken)}',
        'New access: ${_recorder.summary(grant.accessToken)}',
        if (grant.refreshToken != null) ...[
          'Refresh: ${_change(oldRefresh, grant.refreshToken)}',
          'New refresh: ${_recorder.summary(grant.refreshToken)}',
        ],
        if (facts.refreshExpAdvanced != null)
          'Refresh exp: ${facts.refreshExpAdvanced! ? 'moved forward ✓' : 'did NOT move ✗'}',
        ..._grantLines(grant),
        'Saved: $saved',
      ],
      notice: 'Token refreshed',
    );
  });

  @override
  void onRefreshDeferred(String reason) => _guard(() async {
    _recorder.record(
      InspectorEventKind.warning,
      'No network — session KEPT',
      details: ['Reason: $reason', 'Next request retries the refresh'],
    );
  });

  @override
  void onRefreshRefused(int? status, String? body, String requestPath) =>
      _guard(() async {
        final text = body ?? '-';
        _recorder.record(
          InspectorEventKind.error,
          'Server REFUSED — session cleared',
          details: [
            'Status: ${status ?? '-'}',
            'Request: $requestPath',
            'Reply: ${text.length > 300 ? '${text.substring(0, 300)}…' : text}',
          ],
          notice: 'Token refresh refused (${status ?? 'no status'})',
        );
      });

  @override
  void onUnauthorizedAfterRefresh(String requestPath) => _guard(() async {
    _recorder.record(
      InspectorEventKind.error,
      '401 again with the new token',
      details: ['Request: $requestPath'],
    );
  });

  /// `CHANGED …abc123 → …def456` · `same …abc123`.
  String _change(String? before, String? after) {
    if (before == null) return 'new ${fingerprintOf(after)}';
    return before == after
        ? 'same ${fingerprintOf(after)}'
        : 'CHANGED ${fingerprintOf(before)} → ${fingerprintOf(after)}';
  }

  /// ما أرسله الخادم مع الاعتماد — لا شيء لتوكنٍ معتم.
  List<String> _grantLines(TokenGrant g) => [
    if (g.expiresIn != null) 'expires_in: ${readableDuration(g.expiresIn!)}',
    if (g.refreshExpiresIn != null)
      'refresh_expires_in: ${g.refreshExpiresIn == 0 ? '0 (no cap)' : readableDuration(g.refreshExpiresIn!)}',
    if (g.scope != null) 'scope: ${g.scope}',
  ];

  void _guard(Future<void> Function() body) {
    unawaited(
      body().catchError((Object e, StackTrace st) {
        LogService.warning(
          'Token inspector failed to record an event: $e',
          tag: InspectorRecorder.tag,
        );
      }),
    );
  }
}
