import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/Features/auth/verify_email/domain/params/verify_email_params.dart';
import 'package:app_template/Features/auth/verify_email/domain/repositories/verify_email_repository.dart';

@injectable
class VerifyEmailUseCase
    extends BaseUseCase<Either<Failure, AuthUser>, VerifyEmailParams> {
  VerifyEmailUseCase(this._repository);

  final VerifyEmailRepository _repository;

  @override
  Future<Either<Failure, AuthUser>> call(covariant VerifyEmailParams params) =>
      _repository.verifyEmail(params.code);
}
