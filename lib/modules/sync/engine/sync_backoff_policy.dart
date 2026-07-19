import 'dart:math';


class SyncBackoffPolicy {
  int nextRetryAtMillis({
    required int retryCount,
    required int baseDelaySeconds,
    required int maxDelaySeconds,
  }) {
    final exp = pow(2, retryCount).toInt();
    final delay = (baseDelaySeconds * exp).clamp(baseDelaySeconds, maxDelaySeconds);
    return DateTime.now().millisecondsSinceEpoch + (delay * 1000);
  }
}
