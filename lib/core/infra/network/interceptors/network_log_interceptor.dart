import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// Network logging that stays readable — **one line per success, everything on
/// failure**.
///
/// ## Why this replaced the full-dump logger
///
/// The previous interceptor printed the complete request AND response — every
/// header, the whole body — for every call. A launch produced hundreds of
/// lines, and a real failure was two of them.
///
/// That is not a cosmetic complaint. Two `401`s fired on **every single app
/// launch** for as long as the startup translation warm-up existed, printing a
/// `[FAILURE-MAPPER] ❌` line each time. The signal was never missing; it was
/// unreadable. Nobody scrolls a 400-line wall looking for a red line they have
/// no reason to expect.
///
/// So the fix for a missed error was not more logging. It was less:
///
/// - **Success** → one line. `✅ GET /roles?page=1 · 200 · 142ms`
/// - **Failure** → the full picture, unabridged: method, URL, status, request
///   body, response body. This is the moment detail earns its cost.
/// - **Slow success** → same one line, but flagged, so a request that works and
///   takes four seconds is not invisible just because it succeeded.
///
/// ## Verbose mode
///
/// Set [verbose] when you need the old firehose for one debugging session — it
/// prints headers and bodies for successes too. It is a deliberate temporary
/// switch, not a default: leaving it on restores exactly the condition that hid
/// those `401`s.
///
/// ## Placement
/// Registered last in the interceptor chain so it observes the final outcome
/// after auth, retry and cache have had their say.
class NetworkLogInterceptor extends Interceptor {
  NetworkLogInterceptor({this.verbose = false, this.slowThreshold = const Duration(seconds: 2)});

  /// Print full headers/bodies on success too. Temporary debugging aid.
  final bool verbose;

  /// A success taking longer than this is still one line, but marked — silence
  /// about slowness is how a working-but-unusable endpoint stays unnoticed.
  final Duration slowThreshold;

  static const _tag = 'HTTP';
  static const _startKey = '_logStartedAt';

  /// Bodies are truncated in the log, not in the request. A 200 KB payload
  /// dumped in full is the same readability problem in a different costume.
  static const _maxBodyChars = 2000;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    if (verbose) {
      LogService.debug(
        '→ ${options.method} ${_target(options)}\n'
        'headers: ${_pretty(options.headers)}\n'
        'body: ${_body(options.data)}',
        tag: _tag,
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    final ms = _elapsedMs(options);
    final fromCache = response.headers.value('x-from-cache') == 'true';

    final line =
        '✅ ${options.method} ${_target(options)} · ${response.statusCode}'
        '${ms == null ? '' : ' · ${ms}ms'}'
        '${fromCache ? ' · cache' : ''}';

    if (ms != null && ms > slowThreshold.inMilliseconds) {
      LogService.warning('$line · SLOW', tag: _tag);
    } else {
      LogService.info(line, tag: _tag);
    }

    if (verbose) {
      LogService.debug('response: ${_body(response.data)}', tag: _tag);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final ms = _elapsedMs(options);
    final status = err.response?.statusCode;

    // Everything, in one block, so a failure never needs a second run to
    // diagnose — the whole reason the full dump existed in the first place.
    //
    // `cause` is printed IN the message, not only handed to `error:`. That side
    // channel is `dev.log`'s, and whether it reaches the terminal depends on the
    // console doing the reading — it did not, on 2026-08-10, when a device could
    // not reach the dev server and the whole log read `type: connectionError`
    // with no further word.
    //
    // And the word is the diagnosis. `type` says only "the socket never
    // delivered"; the OS string underneath says WHICH, and they have nothing in
    // common as fixes:
    //
    //   Connection refused   → host is up, nothing listening on that port
    //   No route to host     → wrong subnet, or a VPN swallowed the route
    //   Network unreachable  → the interface itself has no path
    //   Connection timed out → packets silently dropped, i.e. a firewall
    //
    // Losing that line turns a one-look answer into an afternoon.
    LogService.error(
      '❌ ${options.method} ${_target(options)}'
      '${status == null ? '' : ' · $status'}'
      '${ms == null ? '' : ' · ${ms}ms'}\n'
      'type: ${err.type.name}\n'
      'cause: ${_cause(err)}\n'
      'request headers: ${_pretty(_redact(options.headers))}\n'
      'request body: ${_body(options.data)}\n'
      'response: ${_body(err.response?.data)}',
      tag: _tag,
      error: err.message,
    );
    handler.next(err);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  /// The OS-level reason, from whichever of Dio's two fields is carrying it.
  ///
  /// Both are read because either can be the empty one: `message` is a summary
  /// Dio composes and sometimes leaves null, while `error` is the original
  /// exception — for a dead host that is the `SocketException` whose text names
  /// the actual failure. Reporting only one of them prints "null" exactly when
  /// something went wrong enough to need it.
  String _cause(DioException err) {
    final message = err.message?.trim();
    final underlying = err.error?.toString().trim();

    if (message != null && message.isNotEmpty) {
      // Skip the underlying copy when the summary already quotes it verbatim.
      if (underlying == null ||
          underlying.isEmpty ||
          message.contains(underlying)) {
        return message;
      }
      return '$message · $underlying';
    }

    if (underlying != null && underlying.isNotEmpty) return underlying;
    return '<none reported>';
  }

  int? _elapsedMs(RequestOptions options) {
    final started = options.extra[_startKey];
    if (started is! int) return null;
    return DateTime.now().millisecondsSinceEpoch - started;
  }

  /// Path + query only. The base URL is identical on every line and repeating
  /// it costs width that the path actually needs.
  static String _target(RequestOptions options) {
    final uri = options.uri;
    return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
  }

  /// The bearer token is the one header that must never reach a log file —
  /// logs get pasted into chats and issue trackers. Its presence is still
  /// reported, because "was this request authenticated?" is the first question
  /// a 401 raises.
  static Map<String, dynamic> _redact(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    for (final key in copy.keys.toList()) {
      if (key.toLowerCase() == 'authorization') {
        final value = copy[key]?.toString() ?? '';
        copy[key] = value.isEmpty ? '<empty>' : '<present, ${value.length} chars>';
      }
    }
    return copy;
  }

  static String _pretty(Map<String, dynamic> map) =>
      map.isEmpty ? '{}' : map.entries.map((e) => '${e.key}: ${e.value}').join(', ');

  static String _body(dynamic data) {
    if (data == null) return '<none>';
    String text;
    try {
      text = data is String ? data : jsonEncode(data);
    } catch (_) {
      text = data.toString();
    }
    if (text.length <= _maxBodyChars) return text;
    return '${text.substring(0, _maxBodyChars)}… (${text.length} chars total)';
  }
}
