/// Body of `POST /api/v1/account/register` — mirrors `registerBodySchema`.
class RegisterRequestDto {
  const RegisterRequestDto({
    required this.email,
    required this.password,
    this.fullName,
  });

  final String email;
  final String password;
  final String? fullName;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        // Omitted rather than sent as null: zod's `.optional()` accepts an
        // absent key and rejects an explicit null.
        if (fullName != null && fullName!.trim().isNotEmpty)
          'full_name': fullName!.trim(),
      };
}
