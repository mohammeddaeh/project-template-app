/// Body of `POST /api/v1/account/login` — mirrors `loginBodySchema`.
class LoginRequestDto {
  const LoginRequestDto({
    required this.email,
    required this.password,
    this.deviceInfo,
  });

  final String email;
  final String password;

  /// Human-readable label for the session this sign-in opens, e.g.
  /// `Samsung SM-G991B · android · v1.2.0`. See [DeviceLabelService].
  ///
  /// Optional on the wire: the server falls back to the `User-Agent` header,
  /// which for a Dio client reads `Dart/3.9 (dart:io)` — technically a device
  /// name and useless to the person reading it.
  final String? deviceInfo;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        // Omitted rather than sent as null: zod's `.optional()` accepts an
        // absent key and rejects an explicit null, so sending one would fail
        // validation on a field nobody asked for.
        if (deviceInfo != null && deviceInfo!.isNotEmpty)
          'device_info': deviceInfo,
      };
}
