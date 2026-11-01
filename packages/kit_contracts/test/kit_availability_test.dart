import 'package:kit_contracts/kit_contracts.dart';
import 'package:test/test.dart';

void main() {
  test('an availability is answered exhaustively', () {
    String describe(KitAvailability a) => switch (a) {
      KitReady() => 'ready',
      KitNeedsPermission(:final permissions) =>
        'needs ${permissions.map((p) => p.name).join('+')}',
      KitUnsupported() => 'unsupported',
    };

    expect(describe(const KitReady()), 'ready');
    expect(
      describe(
        const KitNeedsPermission([
          KitPermission.microphone,
          KitPermission.speechRecognition,
        ]),
      ),
      'needs microphone+speechRecognition',
    );
    expect(describe(const KitUnsupported()), 'unsupported');
  });
}
