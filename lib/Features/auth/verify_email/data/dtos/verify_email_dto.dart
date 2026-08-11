/// "Here is the code you emailed me."
///
/// No email field, unlike the password-reset step: this endpoint is
/// authenticated, so the server already knows whose address is being proven.
/// Sending it would be an editable value the server must then ignore, which is
/// worse than not sending it.
class VerifyEmailDto {
  const VerifyEmailDto({required this.code});

  final String code;

  Map<String, dynamic> toJson() => {'code': code};
}
