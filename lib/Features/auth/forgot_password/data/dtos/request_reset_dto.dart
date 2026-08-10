/// Step 1 of a password reset: "send me a code".
class RequestResetDto {
  const RequestResetDto({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}
