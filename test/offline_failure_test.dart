import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/shared/widgets/states/failure_state_view.dart';

/// Which failures are the reader's to fix — and the failure mode here is that
/// **nothing looks wrong**.
///
/// Get this predicate wrong and `FailureStateView` falls back to the red server
/// -error panel, which is exactly what every list in this app rendered before
/// the widget existed: losing the network mid-scroll produced "something went
/// wrong", identical to a 500, with no wifi icon, no "check your connection",
/// and nothing to distinguish the one cause the reader can actually act on.
/// No exception, no log, no visible defect — the list simply stops being
/// useful, and `lib/CLAUDE.md`'s rule that offline gets `NoInternetWidget` is
/// silently unenforced again.
///
/// So each case is pinned **with its opposite**. Proving that
/// `NoInternetFailure` reads as offline proves nothing on its own — a function
/// returning `true` for everything passes it, and that function would tell
/// someone staring at a 500 to check their wifi.
void main() {
  group('FailureStateView.isOffline — what the reader can fix', () {
    test('no network is offline', () {
      expect(FailureStateView.isOffline(const NoInternetFailure()), isTrue);
    });

    test('a rejected certificate is offline too — it is a captive portal', () {
      // Grouped deliberately: in practice this is hotel/café wifi answering the
      // TLS handshake itself. To the person holding the phone that IS "the
      // internet is not working", and the fix is the same one. Rendering it as
      // a security error sends them to look for a problem that is not there.
      expect(FailureStateView.isOffline(const BadCertificateFailure()), isTrue);
    });

    test('a server refusal is NOT offline', () {
      // The counterpart that makes the two above mean something. The request
      // reached the server and the server answered — telling the reader to
      // check their connection is a confident wrong answer.
      expect(
        FailureStateView.isOffline(const ServerFailure(statusCode: 500)),
        isFalse,
      );
      expect(
        FailureStateView.isOffline(const BusinessFailure(statusCode: 409)),
        isFalse,
      );
      expect(
        FailureStateView.isOffline(const ForbiddenFailure()),
        isFalse,
      );
    });

    test('a timeout is NOT offline — the link exists, it is slow', () {
      // The tempting one to fold in, and the reason this test exists: a timeout
      // on a working connection told to "check your connection" sends the
      // reader to toggle a radio that is already on, while the real answer is
      // simply to wait or retry.
      expect(FailureStateView.isOffline(const TimeoutFailure()), isFalse);
    });

    test('a local failure is NOT offline', () {
      expect(FailureStateView.isOffline(const CacheFailure()), isFalse);
      expect(FailureStateView.isOffline(const UnknownFailure()), isFalse);
    });

    // The newest and sharpest version of this test's whole point. Both of these
    // arrive at the app through the SAME Dio exception as a genuine outage, and
    // both are the server's fault — so sweeping them in here would show the
    // wifi icon and "check your connection" to a reader whose connection is
    // provably fine. That is the exact wrong-culprit bug the pair was split to
    // end, re-created one layer higher.
    test('a closed or overloaded server is NOT offline', () {
      expect(
        FailureStateView.isOffline(const ServerUnreachableFailure()),
        isFalse,
        reason: 'the device is online — saying otherwise sends the reader to '
            'fight a router that is working',
      );
      expect(
        FailureStateView.isOffline(
          const ServiceUnavailableFailure(statusCode: 503),
        ),
        isFalse,
      );
    });
  });
}
