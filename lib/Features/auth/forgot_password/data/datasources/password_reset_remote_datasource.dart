import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/Features/auth/forgot_password/data/datasources/password_reset_api_service.dart';
import 'package:app_template/Features/auth/forgot_password/data/dtos/request_reset_dto.dart';
import 'package:app_template/Features/auth/forgot_password/data/dtos/reset_password_dto.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PasswordResetRemoteDataSource {
  PasswordResetRemoteDataSource(this._apiService);

  final PasswordResetApiService _apiService;

  Future<ApiResponse<void>> requestReset(String email) async {
    final response = await _apiService.requestReset(
      RequestResetDto(email: email),
    );
    return _envelope(response.data);
  }

  Future<ApiResponse<void>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final response = await _apiService.resetPassword(
      ResetPasswordDto(email: email, token: token, newPassword: newPassword),
    );
    return _envelope(response.data);
  }

  /// Both endpoints return the bare envelope with no `data` payload, so one
  /// reader serves both.
  ///
  /// Built by hand rather than through `ApiResponse.fromJson` for the same
  /// reason as every other datasource here: this API sends `status` as a
  /// **bool**, and `fromJson` casts it to `String` and throws `ParseFailure` —
  /// which would surface as "something went wrong" on a request that
  /// succeeded.
  ApiResponse<void> _envelope(dynamic raw) {
    final json = raw as Map<String, dynamic>;
    final ok = json['status'] as bool? ?? false;
    final message = json['message'] as String? ?? '';

    if (!ok) {
      return ApiResponse<void>(
        status: 'error',
        message: message,
        data: null,
        error: ApiError(
          code: json['code'] as int? ?? 400,
          message: message,
          data: json['data'] as Map<String, dynamic>?,
        ),
      );
    }

    return ApiResponse<void>(
      status: 'success',
      message: message,
      data: null,
      error: null,
    );
  }
}
