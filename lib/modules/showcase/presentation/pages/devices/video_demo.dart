import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/devices/kit_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `kit_video` — a clip from the network, and the control bar every player in
/// the app shares.
class VideoDemo extends StatelessWidget {
  const VideoDemo({super.key});

  /// The clip Flutter's own `video_player` example plays.
  static const _sample =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final caption = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textMuted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitNotice(kit: 'video', installed: getIt.isRegistered<VideoPlayback>()),
        DemoBlock(
          code: "AppVideoPlayer(source: 'https://…/butterfly.mp4')",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(LocaleKeys.showcaseVideoSample.tr(), style: caption),
              const SizedBox(height: 8),
              const AppVideoPlayer(source: _sample),
            ],
          ),
        ),
        DemoBlock(
          code: 'PlaybackBar(state: s, onPlay: …, onPause: …, onSeek: …)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(LocaleKeys.showcaseVideoBar.tr(), style: caption),
              const _SimulatedBar(),
            ],
          ),
        ),
      ],
    );
  }
}

/// A one-minute "player" made of a timer — the bar alone, as a custom player
/// would drive it.
class _SimulatedBar extends StatefulWidget {
  const _SimulatedBar();

  @override
  State<_SimulatedBar> createState() => _SimulatedBarState();
}

class _SimulatedBarState extends State<_SimulatedBar> {
  static const _length = Duration(minutes: 1);
  Duration _position = Duration.zero;
  Timer? _tick;

  bool get _playing => _tick != null;

  void _play() {
    if (_position >= _length) _position = Duration.zero;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _position += const Duration(seconds: 1);
        if (_position >= _length) _pause();
      });
    });
    setState(() {});
  }

  void _pause() {
    _tick?.cancel();
    _tick = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PlaybackBar(
    state: PlaybackState(
      position: _position,
      duration: _length,
      playing: _playing,
      completed: _position >= _length,
    ),
    onPlay: _play,
    onPause: _pause,
    onSeek: (p) => setState(() => _position = p),
  );
}
