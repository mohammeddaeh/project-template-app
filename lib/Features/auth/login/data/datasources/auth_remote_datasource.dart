import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/core/platform/device/device_label_service.dart';
import 'package:app_template/Features/auth/login/data/datasources/auth_api_service.dart';
import 'package:app_template/Features/auth/login/data/dtos/login_request_dto.dart';
import 'package:app_template/Features/auth/login/data/models/login_model.dart';
import 'package:app_template/Features/auth/login/domain/params/login_params.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiService, this._deviceLabel);

  final AuthApiService _apiService;
  final DeviceLabelService _deviceLabel;

  Future<ApiResponse<LoginModel>> login(LoginParams params) async {
    final response = await _apiService.login(
      LoginRequestDto(
        email: params.email,
        password: params.password,
        // Resolved here rather than passed down from the screen: labelling the
        // session is a transport detail of this one request, and threading it
        // through params, cubit and use case would make every future caller
        // responsible for remembering it.
        deviceInfo: await _deviceLabel.label(),
      ),
    );
    final json = response.data as Map<String, dynamic>;
    final statusBool = json['status'] as bool? ?? false;
    final message = json['message'] as String? ?? '';
    final code = json['code'] as int? ?? 400;

    if (!statusBool) {
      return ApiResponse<LoginModel>(
        status: 'error',
        message: message,
        data: null,
        error: ApiError(
          code: code,
          message: message,
          data: json['data'] as Map<String, dynamic>?,
        ),
      );
    }

    // API returns status as bool — built manually to avoid ApiResponse.fromJson
    // casting json['status'] (bool) to String and throwing ParseFailure.
    final dataJson = json['data'] as Map<String, dynamic>?;
    return ApiResponse<LoginModel>(
      status: 'success',
      message: message,
      data: dataJson != null ? LoginModel.fromJson(dataJson) : null,
      error: null,
    );
  }
}
