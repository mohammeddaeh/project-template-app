import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/core/foundation/formatting/app_formats.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// Play/pause, a seek bar and "position / length" — the one control row of
/// every player in the app, audio or video.
///
/// [length] is what the file stated when it opened; [state] carries what the
/// player learned since. An unknown length shows the position alone and keeps
/// the bar still — a fresh recording may not state it until it plays.
class PlaybackBar extends StatelessWidget {
  const PlaybackBar({
    super.key,
    required this.state,
    required this.onPlay,
    required this.onPause,
    required this.onSeek,
    this.length,
  });

  final PlaybackState state;
  final Duration? length;

  /// `null` disables the button — nothing loaded yet.
  final VoidCallback? onPlay;
  final VoidCallback onPause;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    // Never shorter than where playback already is.
    final reported = state.duration ?? length ?? Duration.zero;
    final position = state.completed ? reported : state.position;
    final total = position > reported ? position : reported;
    final known = reported > Duration.zero;
    final max = total.inMilliseconds.toDouble();
    final playing = state.playing;
    return Row(
      children: [
        IconButton(
          tooltip: (playing ? LocaleKeys.audioPause : LocaleKeys.audioPlay)
              .tr(),
          onPressed: onPlay == null ? null : (playing ? onPause : onPlay),
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
                : (v) => onSeek(Duration(milliseconds: v.round())),
          ),
        ),
        Text(
          known
              ? '${AppNumberFormats.elapsed.apply(position.inSeconds)} / '
                    '${AppNumberFormats.elapsed.apply(total.inSeconds)}'
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
