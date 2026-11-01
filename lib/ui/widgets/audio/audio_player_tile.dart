import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/foundation/formatting/app_formats.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// Plays one audio file or `https` URL — play/pause, a seek bar, and the
/// position against the length.
///
/// Draws nothing when `kit_audio` is not installed. Each tile owns its player
/// and releases it when it leaves the tree, so a list of notes holds no more
/// players than it shows.
class AudioPlayerTile extends StatefulWidget {
  const AudioPlayerTile({super.key, required this.source});

  final String source;

  @override
  State<AudioPlayerTile> createState() => _AudioPlayerTileState();
}

class _AudioPlayerTileState extends State<AudioPlayerTile> {
  AudioPlayback? _player;
  StreamSubscription<PlaybackState>? _sub;
  PlaybackState _state = const PlaybackState(
    position: Duration.zero,
    playing: false,
  );
  Duration? _length;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (!getIt.isRegistered<AudioPlayback>()) return;
    final player = getIt<AudioPlayback>();
    _player = player;
    _sub = player.states.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    unawaited(_open());
  }

  @override
  void didUpdateWidget(AudioPlayerTile old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source) unawaited(_open());
  }

  Future<void> _open() async {
    final length = await _player?.open(widget.source);
    if (!mounted) return;
    setState(() {
      _length = length;
      _failed = length == null;
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
    if (_failed) {
      return Row(
        children: [
          Icon(Icons.music_off_outlined, color: colors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              LocaleKeys.audioCannotPlay.tr(),
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      );
    }
    // The length may be unknown at first (a fresh recording's header) and is
    // never shorter than where playback already is.
    final reported = _state.duration ?? _length ?? Duration.zero;
    final position = _state.completed ? reported : _state.position;
    final length = position > reported ? position : reported;
    final known = reported > Duration.zero;
    final max = length.inMilliseconds.toDouble();
    final playing = _state.playing;
    return Row(
      children: [
        IconButton(
          tooltip: (playing ? LocaleKeys.audioPause : LocaleKeys.audioPlay)
              .tr(),
          onPressed: _length == null
              ? null
              : () => playing ? player.pause() : player.play(),
          icon: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: colors.primary,
          ),
        ),
        Expanded(
          child: Slider(
            value: known ? position.inMilliseconds.clamp(0, max).toDouble() : 0,
            max: known ? max : 1,
            onChanged: !known
                ? null
                : (v) => player.seek(Duration(milliseconds: v.round())),
          ),
        ),
        Text(
          known
              ? '${AppNumberFormats.elapsed.apply(position.inSeconds)} / '
                    '${AppNumberFormats.elapsed.apply(length.inSeconds)}'
              : AppNumberFormats.elapsed.apply(position.inSeconds),
          // "position / length" — RTL would swap the two around the slash.
          textDirection: TextDirection.ltr,
          style: context.textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
