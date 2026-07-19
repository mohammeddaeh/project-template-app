import 'base_cancel_token.dart';
import 'use_case_params.dart';

abstract class BaseUseCase<Result, Params extends UseCaseParams> {
  BaseCancelToken? _cancelToken;

  Future<Result> call(Params params);

  T resetCancelToken<T extends BaseCancelToken>(T token) {
    final current = _cancelToken;

    if (current == null) {
      _cancelToken = token;
    } else if (current is! T) {
      if (!current.isCanceled) {
        current.cancel('Replaced by new cancel token');
      }
      _cancelToken = token;
    }
    return _cancelToken as T;
  }

  void cancel([String reason = 'Request cancelled by user']) {
    final token = _cancelToken;
    if (token != null && !token.isCanceled) {
      token.cancel(reason);
    }
    _cancelToken = null;
  }
}
