import 'package:dio/dio.dart';

import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/modules/in_app_updates/domain/app_update_settings.dart';

class AppUpdateSettingsApi {
  const AppUpdateSettingsApi(this._dio);

  static const path = '/api/v1/settings';

  final Dio _dio;

  Future<AppUpdateSettings> fetch() async {
    final response = await _dio.get<dynamic>('${Env.baseUrl}$path');
    final body = response.data;
    if (body is! Map || body['data'] is! List) {
      throw const FormatException('unexpected settings response');
    }
    return AppUpdateSettings.fromEntries(body['data'] as List<dynamic>);
  }
}
