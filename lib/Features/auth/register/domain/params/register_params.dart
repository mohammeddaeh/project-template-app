import 'package:app_template/core/foundation/domain/use_case_params.dart';

class RegisterParams extends UseCaseParams {
  const RegisterParams({
    required this.email,
    required this.password,
    this.fullName,
  }) : super();

  final String email;
  final String password;

  /// Optional on the wire and optional here. The server's column is nullable
  /// and a project that identifies people by email never fills it — asking for
  /// it as a required field would be this client inventing a rule.
  final String? fullName;
}
