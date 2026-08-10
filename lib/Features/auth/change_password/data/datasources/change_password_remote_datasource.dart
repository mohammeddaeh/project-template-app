import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/Features/auth/change_password/data/datasources/change_password_api_service.dart';
import 'package:app_template/Features/auth/change_password/data/dtos/change_password_dto.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ChangePasswordRemoteDataSource {
  ChangePasswordRemoteDataSource(this._apiService);

  final ChangePasswordApiService _apiService;

  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiService.changePassword(
      ChangePasswordDto(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );

    final json = response.data as Map<String, dynamic>;
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
