import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/Features/auth/me/data/datasources/me_api_service.dart';
import 'package:app_template/Features/auth/me/data/models/current_user_model.dart';

@lazySingleton
class MeRemoteDataSource {
  MeRemoteDataSource(this._apiService);

  final MeApiService _apiService;

  Future<ApiResponse<CurrentUserModel>> getCurrentUser() async {
    final response = await _apiService.getCurrentUser();
    final json = response.data as Map<String, dynamic>;
    final statusBool = json['status'] as bool? ?? false;
    final message = json['message'] as String? ?? '';
    final code = json['code'] as int? ?? 400;

    if (!statusBool) {
      return ApiResponse<CurrentUserModel>(
        status: 'error',
        message: message,
        data: null,
        error: ApiError(code: code, message: message),
      );
    }

    final dataJson = json['data'] as Map<String, dynamic>?;
    return ApiResponse<CurrentUserModel>(
      status: 'success',
      message: message,
      data: dataJson != null ? CurrentUserModel.fromJson(dataJson) : null,
      error: null,
    );
  }
}
