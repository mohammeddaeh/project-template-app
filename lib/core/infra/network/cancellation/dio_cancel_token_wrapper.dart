import 'package:dio/dio.dart';
import 'package:app_template/core/foundation/domain/base_cancel_token.dart';

class DioCancelTokenWrapper implements BaseCancelToken {
  DioCancelTokenWrapper([CancelToken? token]) : _token = token ?? CancelToken();

  final CancelToken _token;

  CancelToken get raw => _token;

  @override
  bool get isCanceled => _token.isCancelled;

  @override
  void cancel([String? reason]) {
    if (!_token.isCancelled) {
      _token.cancel(reason);
    }
  }
}
