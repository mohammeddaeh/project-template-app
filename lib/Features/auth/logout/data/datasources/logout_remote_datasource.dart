import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/Features/auth/logout/data/datasources/logout_api_service.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class LogoutRemoteDataSource {
  LogoutRemoteDataSource(this._apiService);

  final LogoutApiService _apiService;

  Future<ApiResponse<bool>> logout() async {
    final response = await _apiService.logout();
    final json = response.data as Map<String, dynamic>;
    final statusBool = json['status'] as bool? ?? false;
    final message = json['message'] as String? ?? '';
    final code = json['code'] as int? ?? 400;

    if (!statusBool) {
      return ApiResponse<bool>(
        status: 'error',
        message: message,
        data: null,
        error: ApiError(code: code, message: message),
      );
    }
    return ApiResponse<bool>(
      status: 'success',
      message: message,
      data: true,
      error: null,
    );
  }
}
