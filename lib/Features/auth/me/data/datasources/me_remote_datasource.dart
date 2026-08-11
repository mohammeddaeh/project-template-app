import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/Features/auth/me/data/datasources/me_api_service.dart';
import 'package:app_template/Features/auth/me/data/models/current_user_model.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';

@lazySingleton
class MeRemoteDataSource {
  MeRemoteDataSource(this._apiService);

  final MeApiService _apiService;

  Future<ApiResponse<AuthUser>> getCurrentUser() async {
    final response = await _apiService.getCurrentUser();
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

    // `data` IS the account — there is no wrapper key. See currentUserFromJson.
    final dataJson = json['data'] as Map<String, dynamic>?;
    return ApiResponse<AuthUser>(
      status: 'success',
      message: message,
      data: dataJson != null ? currentUserFromJson(dataJson) : null,
      error: null,
    );
  }
}
