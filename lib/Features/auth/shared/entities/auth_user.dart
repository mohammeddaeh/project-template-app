import 'package:equatable/equatable.dart';

/// Where an account stands, beyond "exists".
///
/// Five states rather than a `bool isActive`, because refusing a login is not
/// one situation — and the difference is what the user must do next:
///
/// | state | what the user should do |
/// |---|---|
/// | [pendingApproval] | wait; an admin has not decided yet |
/// | [active] | nothing — sign in |
/// | [suspended] | contact someone; it is temporary |
/// | [rejected] | read the reason ([AuthUser.rejectionReason]) |
/// | [disabled] | nothing will help; the account is closed |
///
/// A single "login failed" message covers all five and helps in none of them.
/// See `login/domain/entities/login_entity.dart` for how the login repository
/// turns each into its own `Failure`.
///
/// **Adapt this to your API.** Projects without an approval workflow usually
/// need only `active` / `suspended` / `disabled`; deleting the other two is the
/// expected customisation, not a deviation.
enum AuthUserStatus {
  /// Registered; the email address is not yet proven. **First in the
  /// lifecycle** — before any approval step your project may add.
  ///
  /// An account in this state signs in successfully, deliberately: the code
  /// screen lives inside the app, so refusing the session would leave someone
  /// with an account they can neither use nor repair (the common case being a
  /// reinstall). The session unlocks nothing on its own.
  ///
  /// Keep this one even if you delete the rest — it is the only state the
  /// backend's `core/auth` participates in.
  pendingVerification,
  pendingApproval,
  active,
  suspended,
  rejected,
  disabled,
}

/// The signed-in user, as every slice of `auth/` sees them.
///
/// ## This class is meant to be edited
///
/// It is the one file here that mirrors **your** API's user shape, so it is
/// deliberately NOT kept in sync with any project built from this template.
/// Add the fields your server sends, delete the ones it does not. What is worth
/// keeping is the shape of the decisions: a typed [status] instead of booleans,
/// an explicit [rejectionReason] beside the state that needs it, and nullable
/// optional fields rather than empty strings standing in for absence.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phone,
    this.image,
    this.address,
    required this.isAdmin,
    this.mfaEnabled = false,
    // Defaults to true so that constructing an AuthUser without this field —
    // tests, fixtures, a payload from a server that predates verification —
    // never accidentally routes a real user into the code screen.
    this.emailVerified = true,
    this.emailVerifiedAt,
    this.status = AuthUserStatus.active,
    this.rejectionReason,
    required this.createdAt,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phone;

  /// Null when the user has no picture — **not** an empty string. An empty URL
  /// reaches an image widget as a request for "", which fails at runtime
  /// instead of falling back to initials.
  final String? image;
  final String? address;

  final bool isAdmin;

  /// ⚠️ **RESERVED — always `false`. MFA is not implemented in this template.**
  ///
  /// Present so the field exists when you add MFA, and annotated so nobody
  /// reads its presence as protection. Do **not** render it as an account
  /// security state: a screen that says "two-factor enabled" off this field
  /// tells the user they are protected when they are not.
  ///
  /// Before implementing, decide the factor first (TOTP / SMS / email) — each
  /// needs different columns, and a boolean is unlikely to be one of them.
  final bool mfaEnabled;

  /// Whether the email address has been proven.
  ///
  /// Unlike [mfaEnabled] this one is real and load-bearing: it is what routes
  /// the app to the verification screen. Sent by the server as its own field
  /// rather than derived from [emailVerifiedAt] here, so the client never
  /// restates a rule the server already answered.
  final bool emailVerified;

  /// When the address was proven, or null. Kept beside [emailVerified] because
  /// "when" answers questions "whether" cannot — how long an account went
  /// unverified, whether the proof predates an incident.
  final DateTime? emailVerifiedAt;

  final AuthUserStatus status;

  /// Only meaningful with [AuthUserStatus.rejected] — and the reason is the
  /// entire point of that state. "Your registration was rejected" without it
  /// leaves the user with nothing to act on.
  final String? rejectionReason;

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
    firstName: firstName,
    lastName: lastName,
    fullName: fullName,
    email: email,
    phone: phone,
    image: image,
    address: address,
    isAdmin: isAdmin,
    mfaEnabled: mfaEnabled,
    emailVerified: emailVerified ?? this.emailVerified,
    emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
    status: status ?? this.status,
    rejectionReason: rejectionReason,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    fullName,
    email,
    phone,
    image,
    address,
    isAdmin,
    mfaEnabled,
    emailVerified,
    emailVerifiedAt,
    status,
    rejectionReason,
    createdAt,
  ];
}
