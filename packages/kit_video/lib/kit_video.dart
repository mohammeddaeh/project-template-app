/// Video playback — registered behind `kit_contracts`.
///
/// Installed with `dart run scripts/kit.dart add video`; the app never imports
/// this file — `lib/core/di/kits.g.dart` does.
library;

import 'package:get_it/get_it.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'src/video_player_playback.dart';

void registerVideoKit(GetIt getIt) {
  // A player per screen element — each owns its own and disposes it.
  getIt.registerFactory<VideoPlayback>(VideoPlayerPlayback.new);
}
