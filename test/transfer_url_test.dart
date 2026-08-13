import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/modules/data_transfer/data/transfer_file_downloader.dart';

/// **The defect this file exists because of.**
///
/// `/export` and `/template` are the only routes in the app whose URL is built
/// by hand — the injected `Dio` carries no `baseUrl`, so retrofit's own path
/// resolution (which handles this correctly) is not involved.
///
/// The first version concatenated: `'${Env.baseUrl}$path'`. With
/// `BASE_URL=http://host/api/v1` that is right. With
/// `BASE_URL=http://host/api/v1/` — equally reasonable, and what one real
/// environment file had — it produces:
///
///     GET /api/v1//data-transfer/branches/template  →  404
///
/// The user is told "route not found" for an endpoint that is mounted and
/// working, and it reproduces only on the machines with the trailing slash. A
/// build-time `--dart-define` is exactly the kind of input nobody varies while
/// testing, which is why the join is a pure function with a test rather than an
/// expression inside a request.
void main() {
  group('joinBaseUrl', () {
    test('collapses the double slash a trailing-slash base would produce', () {
      expect(
        joinBaseUrl('http://10.0.2.2:3000/api/v1/', '/data-transfer/branches/template'),
        'http://10.0.2.2:3000/api/v1/data-transfer/branches/template',
      );
    });

    test('leaves a well-formed pair alone', () {
      expect(
        joinBaseUrl('http://10.0.2.2:3000/api/v1', '/data-transfer/branches/export'),
        'http://10.0.2.2:3000/api/v1/data-transfer/branches/export',
      );
    });

    test('adds the separator when the path has none', () {
      expect(joinBaseUrl('http://host/api/v1', 'health'), 'http://host/api/v1/health');
    });

    test('handles both halves being sloppy at once', () {
      expect(joinBaseUrl('http://host/api/v1/', 'health'), 'http://host/api/v1/health');
    });

    test('passes an already-absolute URL through untouched', () {
      // A caller handing over a full URL — a pre-signed download link, say —
      // must not have a base glued in front of it.
      const absolute = 'https://files.example.com/export.csv?sig=abc';
      expect(joinBaseUrl('http://host/api/v1', absolute), absolute);
    });

    test('survives an empty base without inventing a scheme', () {
      // `String.fromEnvironment('BASE_URL')` defaults to '' when the define is
      // missing. The result is a relative URL that fails loudly at the request,
      // rather than a malformed absolute one that fails somewhere stranger.
      expect(joinBaseUrl('', '/data-transfer/x/export'), '/data-transfer/x/export');
    });
  });
}
