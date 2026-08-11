import 'package:equatable/equatable.dart';

/// One place this account is currently signed in.
///
/// Mirrors `WireSession` on the server (`features/auth/dtos/auth.dto.ts`).
/// Notably absent, and absent by design:
///
/// - **The token.** It is stored only as a digest and only its holder ever saw
///   the plaintext, so there is nothing to carry here even if it were wanted.
/// - **`isPrimary`.** Removed with the seniority rule it served — see
///   [MultiDeviceConfig] for why "only the first device may revoke" fails in
///   the one situation revocation exists for.
class DeviceSession extends Equatable {
  const DeviceSession({
    required this.id,
    required this.createdAt,
    required this.lastActiveAt,
    required this.expiresAt,
    required this.isCurrent,
    required this.provider,
    this.deviceInfo,
  });

  final int id;

  /// The label this device reported at sign-in — e.g.
  /// `Samsung SM-G991B · android · v1.2.0`.
  ///
  /// Nullable because it is optional on the wire: a session opened by an older
  /// build, by curl, or with the multi-device module disabled has none. The UI
  /// names that case rather than rendering an empty row.
  ///
  /// **Never trusted for anything.** It is text the client chose, so two
  /// devices can claim the same name. `id` is the identity; this is the label.
  final String? deviceInfo;

  /// How this session was authenticated — `local` today, and where `google` or
  /// `keycloak` would appear. Recorded because "how did this device get in?" is
  /// the first question an incident review asks.
  final String provider;

  final DateTime createdAt;
  final DateTime lastActiveAt;

  /// Hard expiry, independent of activity. A session dies here even if used
  /// every minute — which is what bounds a token stolen from a device that
  /// keeps itself awake in the background.
  final DateTime expiresAt;

  /// True for the session making the request.
  ///
  /// Server-computed, not inferred locally by comparing tokens: the client
  /// holds a token and the server holds a digest, so only one of them can
  /// actually answer this.
  final bool isCurrent;

  @override
  List<Object?> get props => [
        id,
        deviceInfo,
        provider,
        createdAt,
        lastActiveAt,
        expiresAt,
        isCurrent,
      ];
}
