import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/core/foundation/contracts/network_origin.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/features/auth/login/data/datasources/auth_remote_datasource.dart';
import 'package:app_template/features/auth/login/domain/entities/login_entity.dart';
import 'package:app_template/features/auth/login/domain/params/login_params.dart';
import 'package:app_template/features/auth/login/domain/repositories/login_repository.dart';
import 'package:app_template/features/auth/shared/current_user_repository.dart';
import 'package:app_template/core/infra/session/account_data_cleaner.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LoginRepository)
class LoginRepositoryImpl extends BaseRepository implements LoginRepository {
  LoginRepositoryImpl(
    this._dataSource,
    this._sessionRepository,
    this._currentUserRepository,
    this._accountDataCleaner,
    HandleBodyResponse handler,
  ) : super(handler);

  final AuthRemoteDataSource _dataSource;
  final SessionRepository _sessionRepository;
  final CurrentUserRepository _currentUserRepository;
  final AccountDataCleaner _accountDataCleaner;

  @override
  Future<Either<Failure, LoginEntity>> login(LoginParams params) =>
      // **وسمُ المنفذ: الدخول** — استثناءٌ بحكم التعريف، ويُعلَن ليُميَّز عن
      // طلبٍ نسي وسمَه. راجع `NetworkOrigin`.
      NetworkOrigin.run(NetworkOrigin.auth, () => handle(() async {
        final res = await _dataSource.login(params);

        if (res.error != null) {
          return Left(_mapLoginError(res.error!, res.message));
        }

        if (res.data == null) {
          return const Left(BusinessFailure(statusCode: 400));
        }

        final entity = res.data!.toEntity();

        // **قبل كل شيء: هل هذا الجهاز يحمل بيانات حسابٍ آخر؟**
        //
        // ويقع **قبل** حفظ التوكن ونشر المستخدم عمداً: مسحٌ بعدهما يترك نافذةً
        // تُقرأ فيها صفوفُ السابق بهوية اللاحق — وأسوأُ منها أن محرّك المزامنة
        // قد يدفع طابورَ السابق بتوكن اللاحق، فيصل الخادمَ عملُ موظّفٍ باسم
        // زميله.
        //
        // ولا يكفي المسحُ عند الخروج وحده: التطبيق قد يُقتل، أو تنتهي الجلسة
        // فيُترك، أو يُسلَّم الجهاز مفتوحاً — وبكلٍّ منها لا يمرّ أحدٌ بمسار
        // الخروج إطلاقاً.
        await _accountDataCleaner.clearIfAccountChanged(entity.user.email);

        // Token first: `setCurrentUser` persists asynchronously, and a user
        // snapshot on disk without the credential that justifies it is the one
        // ordering that can survive a crash in a misleading state.
        await _sessionRepository.saveToken(entity.token);
        _currentUserRepository.setCurrentUser(entity.user);
        return Right(entity);
      }));

  /// Turns a refusal into the failure that names it.
  ///
  /// **Branches on `data.account_status`, never on the message text** — that is
  /// translated prose which changes with any rewording, so a branch matching it
  /// breaks silently in whichever language nobody tested. The server sends the
  /// discriminator for exactly this reason
  /// (`account-store.impl.ts` → `canSignIn`).
  ///
  /// `disabled` is the only value `backend_template` emits today. The `_` arm
  /// is not dead code: it is what a status this client has not learned yet
  /// falls into, and it must be a refusal rather than a crash. To add one —
  /// e.g. `suspended` — give it a branch in `canSignIn` first, then here.
  /// `LoginPendingApprovalFailure`, `LoginRejectedFailure` and
  /// `LoginSuspendedFailure` are already defined in `failure.dart` for that.
  Failure _mapLoginError(ApiError error, String message) {
    if (error.code == 401) {
      return LoginFailure(serverMessage: message);
    }

    if (error.code == 403) {
      final accountStatus = error.data?['account_status'] as String?;
      return switch (accountStatus) {
        'disabled' => LoginDisabledFailure(serverMessage: message),
        _ => ForbiddenFailure(serverMessage: message),
      };
    }

    return BusinessFailure(
      statusCode: error.code ?? 400,
      serverMessage: message.isNotEmpty ? message : null,
    );
  }
}
