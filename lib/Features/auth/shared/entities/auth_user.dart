import 'package:equatable/equatable.dart';

/// Where an account stands, beyond "exists".
///
/// **Three values, and they are exactly the three `backend_template` ships**
/// (`users.schema.ts` → `userStatusEnum`). That is the whole point: a client
/// enum with values no server ever sends is a set of branches nobody can reach
/// and nobody can test, and this file used to carry three of them
/// (`pending_approval`, `rejected`, `suspended`) inherited from an application
/// with an admin approval queue.
///
/// | state | what the user should do |
/// |---|---|
/// | [pendingVerification] | enter the code sent to their address |
/// | [active] | nothing — sign in |
/// | [disabled] | nothing will help; the account is closed |
///
/// ## Adding a state (the intended path)
///
/// Both halves move together, or the value arrives as a string the client
/// silently reads as [active]:
///
/// 1. `backend_template/src/features/account/schemas/users.schema.ts` — add it
///    to `userStatusEnum`, then `npm run db:generate && npm run db:migrate`.
/// 2. Same file's `canSignIn` in `account-store.impl.ts` — give it a branch, so
///    the 403 carries `data.account_status`.
/// 3. This enum + [authUserStatusFromWire] in `auth_user_model.dart`.
/// 4. `login_repository_impl.dart` `_mapLoginError` — map it to a [Failure].
enum AuthUserStatus {
  /// Registered; the email address is not yet proven. **First in the
  /// lifecycle.**
  ///
  /// An account in this state signs in successfully, deliberately: the code
  /// screen lives inside the app, so refusing the session would leave someone
  /// with an account they can neither use nor repair (the common case being a
  /// reinstall). The session unlocks nothing on its own.
  pendingVerification,

  /// The address is proven and the account may be used.
  active,

  /// Access revoked. The row survives so historical records keep their
  /// attribution — this is not a deletion.
  disabled,
}

/// The signed-in user, as every slice of `auth/` sees them.
///
/// ## This class mirrors `WireAccount` field for field
///
/// Seven fields, and they are the seven `GET /api/v1/account/me` returns
/// (`backend_template/src/features/account/dtos/account.dto.ts`). Nothing here
/// is aspirational: a field the server does not send is a field that arrives
/// empty on every single request, and the screen built on it reads as broken
/// rather than as unconfigured. This file previously carried eight such fields
/// — `first_name`, `last_name`, `phone`, `image`, `address`, `is_admin`,
/// `mfa_enabled`, `rejection_reason` — none of which any endpoint has ever
/// returned.
///
/// ## This class is still meant to be edited
///
/// It is the one file here deliberately NOT kept in sync with projects built
/// from this template. Adding a field is two coordinated edits, and they must
/// be made in this order:
///
/// 1. `backend_template` — column in `users.schema.ts`, accept it in
///    `account-store.impl.ts`, expose it in `WireAccount`/`toWireAccount` and
///    `accountResponseSchema` (the last one is what OpenAPI publishes).
/// 2. Here — the field, then in `auth_user_model.dart` its `fromJson`,
///    `toJson`, `fromEntity` and `toEntity`.
///
/// `test/wire_contract_test.dart` fails until both halves agree, which is the
/// only reason that ordering is enforceable rather than merely advised.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    // Defaults to true so that constructing an AuthUser without this field —
    // tests, fixtures, a payload from a server with verification switched off —
    // never accidentally routes a real user into the code screen.
    this.emailVerified = true,
    this.emailVerifiedAt,
    this.status = AuthUserStatus.active,
    required this.createdAt,
  });

  final int id;
  final String email;

  /// Null when the account has no human label — **not** an empty string.
  /// The server's column is nullable and a project that identifies people by
  /// email never fills it, so every display site must decide what to show;
  /// `''` would let that decision be skipped by accident.
  final String? fullName;

  /// Whether the email address has been proven.
  ///
  /// Load-bearing: it is what routes the app to the verification screen. Sent
  /// by the server as its own field rather than derived from [emailVerifiedAt]
  /// here, so the client never restates a rule the server already answered.
  final bool emailVerified;

  /// When the address was proven, or null. Kept beside [emailVerified] because
  /// "when" answers questions "whether" cannot — how long an account went
  /// unverified, whether the proof predates an incident.
  final DateTime? emailVerifiedAt;

  final AuthUserStatus status;

  final DateTime createdAt;

  /// Returns a copy with only the named fields replaced.
  ///
  /// Deliberately narrow — it covers the fields an endpoint hands back as a
  /// partial update (`POST /auth/verify-email` returns the new status and
  /// verification stamp, nothing else). A full copyWith would invite callers to
  /// synthesise a user the server never sent, which is how a client starts
  /// believing things the server does not.
  AuthUser copyWith({
    AuthUserStatus? status,
    bool? emailVerified,
    DateTime? emailVerifiedAt,
  }) => AuthUser(
    id: id,
    email: email,
    fullName: fullName,
    emailVerified: emailVerified ?? this.emailVerified,
    emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
    status: status ?? this.status,
    createdAt: createdAt,
  );

  /// What to show where a name belongs. Falls back to the address rather than
  /// to `''`, because a row reading "—" tells the user nothing about whose
  /// account they are looking at.
  String get displayName =>
      (fullName != null && fullName!.isNotEmpty) ? fullName! : email;

  /// First character for [AvatarWidget], guaranteed non-empty.
  String get initial => displayName[0].toUpperCase();

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    emailVerified,
    emailVerifiedAt,
    status,
    createdAt,
  ];
}
