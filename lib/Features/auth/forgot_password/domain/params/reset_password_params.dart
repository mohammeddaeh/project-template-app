import 'package:app_template/core/foundation/domain/use_case_params.dart';

class ResetPasswordParams extends UseCaseParams {
  const ResetPasswordParams({
    required this.email,
    required this.token,
    required this.newPassword,
  }) : super();

  final String email;
  final String token;
  final String newPassword;
}
