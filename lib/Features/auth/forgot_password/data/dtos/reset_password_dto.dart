/// Step 2 of a password reset: "here is the code and my new password".
///
/// [email] travels again rather than being held server-side against a session:
/// the user may finish this step on a different device from the one that asked
/// for the code, which is the common case when the code arrives by email.
class ResetPasswordDto {
  const ResetPasswordDto({
    required this.email,
    required this.token,
    required this.newPassword,
  });

  final String email;
  final String token;
  final String newPassword;

  Map<String, dynamic> toJson() => {
    'email': email,
    'token': token,
    'new_password': newPassword,
  };
}
