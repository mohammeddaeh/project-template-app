abstract class BaseCancelToken {
  bool get isCanceled;

  void cancel([String? reason]);
}

