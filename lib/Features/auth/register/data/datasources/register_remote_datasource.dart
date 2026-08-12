import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/Features/auth/register/data/datasources/register_api_service.dart';
import 'package:app_template/Features/auth/register/data/dtos/register_request_dto.dart';
import 'package:app_template/Features/auth/register/domain/params/register_params.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/Features/auth/shared/models/auth_user_model.dart';

@lazySingleton
class RegisterRemoteDataSource {
  RegisterRemoteDataSource(this._apiService);

  final RegisterApiService _apiService;

  Future<ApiResponse<AuthUser>> register(RegisterParams params) async {
    final response = await _apiService.register(
      RegisterRequestDto(
        email: params.email,
        password: params.password,
        fullName: params.fullName,
      ),
    );

    final json = response.data as Map<String, dynamic>;
    final statusBool = json['status'] as bool? ?? false;
    final message = json['message'] as String? ?? '';
    final code = json['code'] as int? ?? 400;

    if (!statusBool) {
      return ApiResponse<AuthUser>(
        status: 'error',
        message: message,
        data: null,
        error: ApiError(code: code, message: message),
      );
    }

    // `data` IS the account — same root-level shape as `GET /account/me`, and
    // unlike login there is no wrapper object and no token.
    final dataJson = json['data'] as Map<String, dynamic>?;
    return ApiResponse<AuthUser>(
      status: 'success',
      message: message,
      data: dataJson != null
          ? AuthUserModel.fromJson(dataJson).toEntity()
          : null,
      error: null,
    );
  }
}
