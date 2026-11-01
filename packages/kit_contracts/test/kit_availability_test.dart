import 'package:kit_contracts/kit_contracts.dart';
import 'package:test/test.dart';

void main() {
  test('an availability is answered exhaustively', () {
    String describe(KitAvailability a) => switch (a) {
      KitReady() => 'ready',
      KitNeedsPermission(:final permission) => 'needs ${permission.name}',
      KitUnsupported() => 'unsupported',
    };

    expect(describe(const KitReady()), 'ready');
    expect(
      describe(const KitNeedsPermission(KitPermission.microphone)),
      'needs microphone',
    );
    expect(describe(const KitUnsupported()), 'unsupported');
  });
}
