import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/domain/no_params.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/verify_email/domain/repositories/verify_email_repository.dart';

/// [NoParams] because the server identifies the account from the session — the
/// address is not a client-supplied value here, which is what stops this from
/// being a way to mail a code to somebody else's inbox.
@injectable
class ResendVerificationUseCase
    extends BaseUseCase<Either<Failure, void>, NoParams> {
  ResendVerificationUseCase(this._repository);

  final VerifyEmailRepository _repository;

  @override
  Future<Either<Failure, void>> call(covariant NoParams params) =>
      _repository.resendVerification();
}
