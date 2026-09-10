import 'package:app_template/core/foundation/domain/use_case_params.dart';

class ChangePasswordParams extends UseCaseParams {
  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  }) : super();

  final String currentPassword;
  final String newPassword;
}
