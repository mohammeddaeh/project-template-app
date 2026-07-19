import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

@lazySingleton
class InternetCheckerInterceptor extends Interceptor {
  final InternetConnectionChecker _connectionChecker;
  final Connectivity _connectivity;

  InternetCheckerInterceptor(this._connectionChecker, this._connectivity);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return handler.reject(_noInternetException(options));
    }

    if (!await _connectionChecker.hasConnection) {
      return handler.reject(_noInternetException(options));
    }

    if (!handler.isCompleted) handler.next(options);
  }

  DioException _noInternetException(RequestOptions options) {
    return DioException(
      type: DioExceptionType.connectionError,
      requestOptions: options,
      error: const SocketException('No internet connection'),
      message: 'No internet connection',
    );
  }
}
