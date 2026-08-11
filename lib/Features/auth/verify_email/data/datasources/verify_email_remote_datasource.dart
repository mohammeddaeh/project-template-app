import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/Features/auth/verify_email/data/datasources/verify_email_api_service.dart';
import 'package:app_template/Features/auth/verify_email/data/dtos/verify_email_dto.dart';
import 'package:app_template/Features/auth/verify_email/data/models/verified_account_model.dart';

@lazySingleton
class VerifyEmailRemoteDataSource {
  VerifyEmailRemoteDataSource(this._apiService);

  final VerifyEmailApiService _apiService;

  Future<ApiResponse<VerifiedAccountModel>> verifyEmail(String code) async {
    final response = await _apiService.verifyEmail(VerifyEmailDto(code: code));
    return _envelope(
      response.data,
      (json) => VerifiedAccountModel.fromJson(json),
    );
  }

  Future<ApiResponse<void>> resendVerification() async {
    final response = await _apiService.resendVerification();
    return _envelope<void>(response.data, null);
  }

  /// Reads the shared envelope.
  ///
  /// Built by hand rather than through `ApiResponse.fromJson` for the same
  /// reason as every other datasource here: this API sends `status` as a
  /// **bool**, and `fromJson` casts it to `String` and throws `ParseFailure` —
  /// which would surface as "something went wrong" on a request that succeeded.
  ///
  /// [parse] is null for endpoints that carry no payload, so one reader serves
  /// both calls instead of two near-identical ones.
  ApiResponse<T> _envelope<T>(
    dynamic raw,
    T Function(Map<String, dynamic>)? parse,
  ) {
    final json = raw as Map<String, dynamic>;
    final ok = json['status'] as bool? ?? false;
    final message = json['message'] as String? ?? '';

    if (!ok) {
      return ApiResponse<T>(
        status: 'error',
        message: message,
        data: null,
        error: ApiError(
          code: json['code'] as int? ?? 400,
          message: message,
          // Carries `message_key`, which is how the screen tells a cooldown
          // (`verification_resend_cooldown`) from an already-verified account
          // (`verification_already_verified`) without matching translated prose.
          data: json['data'] as Map<String, dynamic>?,
        ),
      );
    }

    final payload = json['data'] as Map<String, dynamic>?;
    return ApiResponse<T>(
      status: 'success',
      message: message,
      data: parse != null && payload != null ? parse(payload) : null,
      error: null,
    );
  }
}
