import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/indicators/app_progress.dart';
import 'package:app_template/ui/widgets/media/playback_bar.dart';

/// Plays one video file or `https` URL — the picture at its own shape, a
/// tap on it to play or pause, and the [PlaybackBar] under it.
///
/// Draws nothing when `kit_video` is not installed. Each player owns its
/// platform player and releases it when it leaves the tree.
class AppVideoPlayer extends StatefulWidget {
  const AppVideoPlayer({super.key, required this.source});

  final String source;

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayback? _player;
  StreamSubscription<PlaybackState>? _sub;
  PlaybackState _state = const PlaybackState(
    position: Duration.zero,
    playing: false,
  );
  VideoInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (!getIt.isRegistered<VideoPlayback>()) return;
    final player = getIt<VideoPlayback>();
    _player = player;
    _sub = player.states.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    unawaited(_open());
  }

  @override
  void didUpdateWidget(AppVideoPlayer old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source) unawaited(_open());
  }

  Future<void> _open() async {
    setState(() => _loading = true);
    final info = await _player?.open(widget.source);
    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_player?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    if (player == null) return const SizedBox.shrink();
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    final info = _info;
    final ratio = (info?.aspectRatio ?? 0) > 0 ? info!.aspectRatio : 16 / 9;

    final Widget picture;
    if (_loading) {
      picture = const AppProgress.circular(centered: true);
    } else if (info == null) {
      picture = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, color: colors.textMuted),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.videoCannotPlay.tr(),
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    } else {
      picture = GestureDetector(
        onTap: _state.playing ? player.pause : player.play,
        child: Stack(
          fit: StackFit.expand,
          children: [
            player.surface,
            if (!_state.playing)
              Center(
                child: DecoratedBox(
                  // A card disc, not a scrim: its icon stays readable over
                  // any frame and in both themes.
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 40,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppRadius.mdRadius,
          child: ColoredBox(
            color: colors.bgElevated,
            child: AspectRatio(aspectRatio: ratio, child: picture),
          ),
        ),
        if (info != null)
          PlaybackBar(
            state: _state,
            length: info.duration,
            onPlay: player.play,
            onPause: player.pause,
            onSeek: player.seek,
          ),
      ],
    );
  }
}
