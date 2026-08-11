import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/contracts/token_refresh_gateway.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/Features/auth/shared/current_user_repository.dart';
import 'package:app_template/core/infra/session/session_repository.dart';

/// Wakes [TokenRefreshInterceptor], which has been built and dormant since the
/// template was written.
///
/// ## What was missing, and what it cost
///
/// The interceptor is complete: on a 401 it refreshes, retries the original
/// request, and serialises concurrent 401s behind one refresh. But
/// [InjectableModule.dioInstance] only installs it when a [TokenRefreshGateway]
/// is registered, and none ever was — so every 401 fell through to
/// [AuthInterceptor], which cleared the session and ejected the user to the
/// login screen. A recoverable session and a dead one produced the same
/// outcome.
///
/// ## Why there is no separate refresh token
///
/// The contract's doc comment describes an access/refresh **pair**, which is
/// what stateless JWTs need: the access token cannot be revoked, so a second,
/// longer-lived credential exists to mint replacements. This backend issues an
/// **opaque server-side session token** instead — it is already revocable, and
/// `POST /auth/refresh` rotates that one token in place.
///
/// So there is one credential, not two, and it is the same one the request
/// carried. The interface is satisfied; only the mechanism differs.
///
/// ## Why a bare Dio
///
/// The shared Dio carries [TokenRefreshInterceptor] itself. Refreshing through
/// it would mean a 401 on the refresh call re-entering the interceptor that
/// issued it — a loop broken only by a flag that has to be right every time.
/// A client with no interceptors cannot recurse by construction; the cost is
/// setting the Authorization header by hand, once, here.
@Singleton(as: TokenRefreshGateway)
class TokenRefreshGatewayImpl implements TokenRefreshGateway {
  TokenRefreshGatewayImpl(this._sessionRepository, this._currentUserRepository);

  final SessionRepository _sessionRepository;
  final CurrentUserRepository _currentUserRepository;

  static const _tag = 'TOKEN-REFRESH';

  late final Dio _client = Dio(
    BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );

  @override
  Future<void> refresh() async {
    final token = _sessionRepository.getToken();
    if (token == null) {
      // Nothing to rotate. Thrown rather than returned quietly so the
      // interceptor takes its failure path and signals expiry, instead of
      // retrying the original request with the same absent credential.
      throw StateError('No session token to refresh');
    }

    final response = await _client.post<dynamic>(
      ApiUrls.refreshSession,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final json = response.data as Map<String, dynamic>?;
    final data = json?['data'] as Map<String, dynamic>?;
    final next = data?['token'] as String?;

    if (next == null || next.isEmpty) {
      throw StateError('Refresh response carried no token');
    }

    // Saved whether or not the server rotated. `rotated: false` means the token
    // was still young and came back unchanged — writing it again is a no-op,
    // and branching on the flag would be one more way for the stored credential
    // to drift from the one the server accepts.
    await _sessionRepository.saveToken(next);

    LogService.info(
      data?['rotated'] == true
          ? 'Session token rotated.'
          : 'Session extended; token unchanged.',
      tag: _tag,
    );
  }

  @override
  Future<void> onRefreshFailed() async {
    // Both are cleared, not just the token: leaving the cached user behind
    // would let the next launch restore a profile and permissions for a session
    // that no longer exists, and route past the login screen on that basis.
    _sessionRepository.clearSession();
    _currentUserRepository.clear();
    LogService.warning('Refresh failed — local session cleared.', tag: _tag);
  }
}
