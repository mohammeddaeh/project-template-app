import 'package:app_template/core/foundation/domain/use_case_params.dart';

class RequestResetParams extends UseCaseParams {
  const RequestResetParams({required this.email}) : super();

  final String email;
}
