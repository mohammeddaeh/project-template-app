import 'package:app_template/core/foundation/domain/use_case_params.dart';

class VerifyEmailParams extends UseCaseParams {
  const VerifyEmailParams({required this.code}) : super();

  final String code;
}
