import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kit_contracts/kit_contracts.dart';
import 'package:kit_video/kit_video.dart';

void main() {
  test('every request is a new player', () {
    final getIt = GetIt.asNewInstance();
    registerVideoKit(getIt);
    expect(
      identical(getIt<VideoPlayback>(), getIt<VideoPlayback>()),
      isFalse,
      reason: 'a factory — each owner disposes its own',
    );
  });

  test(
    'a player with nothing open draws an empty box and plays nothing',
    () async {
      final getIt = GetIt.asNewInstance();
      registerVideoKit(getIt);
      final player = getIt<VideoPlayback>();
      expect(player.surface, isNotNull);
      await player.play();
      await player.dispose();
    },
  );
}
