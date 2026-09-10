import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/contracts/network_origin.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/features/auth/logout/data/datasources/logout_remote_datasource.dart';
import 'package:app_template/features/auth/logout/domain/repositories/logout_repository.dart';
import 'package:app_template/features/auth/shared/current_user_repository.dart';
import 'package:app_template/core/infra/session/account_data_cleaner.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LogoutRepository)
class LogoutRepositoryImpl extends BaseRepository implements LogoutRepository {
  LogoutRepositoryImpl(
    this._remoteDataSource,
    this._sessionRepository,
    this._currentUserRepository,
    this._accountDataCleaner,
    HandleBodyResponse handler,
  ) : super(handler);

  final LogoutRemoteDataSource _remoteDataSource;
  final SessionRepository _sessionRepository;
  final CurrentUserRepository _currentUserRepository;
  final AccountDataCleaner _accountDataCleaner;

  @override
  Future<Either<Failure, void>> logout() =>
      // **وسمُ المنفذ: الخروج** — راجع `NetworkOrigin`.
      NetworkOrigin.run(NetworkOrigin.auth, () => handle(() async {
        final res = await _remoteDataSource.logout();
        if (res.error == null) {
          _sessionRepository.clearSession();
          _currentUserRepository.clear();
          // **خروجٌ متعمَّد ⇒ يُمحى كلُّ ما يخصّ الحساب** — لا الجلسةُ وحدها.
          // وبلا هذا السطر يرى الداخلُ التالي صفوفَ سلفه وصورَه، **ويُدفع
          // طابورُ الأول بتوكن الثاني**: إسنادُ عملٍ إلى من لم يعمله.
          await _accountDataCleaner.clearForSignOut();
          return const Right(null);
        }
        return Left(BusinessFailure(
          statusCode: res.error?.code ?? 400,
          serverMessage: res.message.isNotEmpty ? res.message : null,
        ));
      }));
}
