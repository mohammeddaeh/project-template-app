import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// A speaker that reads [text] aloud; a second tap stops it.
///
/// Draws nothing when `kit_voice` is not installed. Reads in [languageCode] —
/// the text's own language, which is not always the app's: an English quote
/// on an Arabic screen. Defaults to the app's language.
class SpeakButton extends StatefulWidget {
  const SpeakButton({super.key, required this.text, this.languageCode});

  final String text;
  final String? languageCode;

  @override
  State<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<SpeakButton> {
  bool _speaking = false;

  @override
  void dispose() {
    if (_speaking) unawaited(getIt<SpeechOutput>().stop());
    super.dispose();
  }

  Future<void> _toggle() async {
    final output = getIt<SpeechOutput>();
    if (_speaking) return output.stop();
    setState(() => _speaking = true);
    final outcome = await output.speak(
      widget.text,
      languageCode: widget.languageCode ?? context.locale.languageCode,
    );
    if (!mounted) return;
    setState(() => _speaking = false);
    switch (outcome) {
      case SpeakOutcome.noVoice:
        context.feedback.warning(LocaleKeys.voiceNoVoice.tr());
      case SpeakOutcome.failed:
        context.feedback.warning(LocaleKeys.voiceReadFailed.tr());
      case SpeakOutcome.done || SpeakOutcome.stopped:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<SpeechOutput>()) return const SizedBox.shrink();
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    return IconButton(
      tooltip: (_speaking ? LocaleKeys.voiceStopReading : LocaleKeys.voiceRead)
          .tr(),
      onPressed: widget.text.trim().isEmpty ? null : _toggle,
      icon: AnimatedSwitcher(
        duration: AppMotion.of(context).fast,
        child: Icon(
          _speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
          key: ValueKey(_speaking),
          color: _speaking ? colors.primary : colors.textMuted,
        ),
      ),
    );
  }
}
