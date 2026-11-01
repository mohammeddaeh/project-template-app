import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/foundation/formatting/app_formats.dart';
import 'package:app_template/core/platform/permissions/kit_readiness.dart';
import 'package:app_template/core/platform/permissions/permissions_service.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/feedback/kit_readiness_feedback.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/indicators/app_progress.dart';
import 'package:app_template/ui/widgets/layout/app_button.dart';

/// Records a voice note: a button, then the running time and the input level,
/// with finish and discard.
///
/// Draws nothing when `kit_audio` is not installed.
///
/// ⚠️ [onRecorded] receives a **temporary** file. Copy it into private storage
/// at once — `PrivateFileIngestService.ingest` — as with a captured photo: the
/// system empties the temporary directory when space runs short, and a spoken
/// report cannot be spoken again the same way.
class VoiceNoteRecorder extends StatefulWidget {
  const VoiceNoteRecorder({super.key, required this.onRecorded});

  final ValueChanged<Recording> onRecorded;

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder> {
  final _clock = Stopwatch();
  Timer? _tick;
  StreamSubscription<double>? _levels;
  double _level = 0;
  bool _preparing = false;

  bool get _recording => _clock.isRunning;

  @override
  void dispose() {
    if (_recording) unawaited(getIt<AudioRecorder>().cancel());
    _tick?.cancel();
    unawaited(_levels?.cancel());
    super.dispose();
  }

  Future<void> _start() async {
    final recorder = getIt<AudioRecorder>();
    setState(() => _preparing = true);
    final readiness = await ensureKitReady(
      recorder.availability,
      getIt<PermissionsService>(),
    );
    if (!mounted) return;
    if (readiness != KitReadiness.ready) {
      setState(() => _preparing = false);
      return showKitReadiness(
        context,
        readiness,
        deniedKey: LocaleKeys.audioMicDenied,
        blockedKey: LocaleKeys.audioMicBlocked,
        unsupportedKey: LocaleKeys.audioUnsupported,
      );
    }
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    final started = await recorder.start(path);
    if (!mounted) return;
    setState(() => _preparing = false);
    if (!started) {
      context.feedback.warning(LocaleKeys.audioStartFailed.tr());
      return;
    }
    setState(() {
      _clock
        ..reset()
        ..start();
      _level = 0;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _levels = recorder.levels.listen((l) {
      if (mounted) setState(() => _level = l);
    });
  }

  Future<void> _finish() async {
    final recording = await getIt<AudioRecorder>().stop();
    _reset();
    if (!mounted) return;
    if (recording == null) {
      context.feedback.warning(LocaleKeys.audioEmpty.tr());
      return;
    }
    widget.onRecorded(recording);
  }

  Future<void> _discard() async {
    await getIt<AudioRecorder>().cancel();
    _reset();
  }

  void _reset() {
    _clock
      ..stop()
      ..reset();
    _tick?.cancel();
    unawaited(_levels?.cancel());
    _levels = null;
    if (mounted) setState(() => _level = 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<AudioRecorder>()) return const SizedBox.shrink();
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    if (!_recording) {
      return AppButton(
        text: LocaleKeys.audioRecord.tr(),
        variant: AppButtonVariant.tonal,
        leadingIcon: Icons.mic_none_rounded,
        isLoading: _preparing,
        onTap: _start,
      );
    }
    final colors = context.colors;
    return Row(
      children: [
        IconButton(
          tooltip: LocaleKeys.audioDiscard.tr(),
          onPressed: _discard,
          icon: Icon(Icons.delete_outline, color: colors.textMuted),
        ),
        Expanded(
          child: AppProgress.linear(
            value: _level,
            tone: AppProgressTone.danger,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppNumberFormats.elapsed.apply(_clock.elapsed.inSeconds),
            style: context.textTheme.labelLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        IconButton.filled(
          tooltip: LocaleKeys.audioStopRecording.tr(),
          onPressed: _finish,
          icon: const Icon(Icons.stop_rounded),
        ),
      ],
    );
  }
}
