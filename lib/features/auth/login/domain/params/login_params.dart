import 'package:app_template/core/foundation/domain/use_case_params.dart';

class LoginParams extends UseCaseParams {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  }) : super();
}
