import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/permissions/kit_readiness.dart';
import 'package:app_template/core/platform/permissions/permissions_service.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/feedback/kit_readiness_feedback.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// A microphone that writes what is said into [controller].
///
/// Draws nothing when `kit_voice` is not installed — a screen asks for
/// dictation and keeps working in a project without it. Usually reached
/// through `CustomTextField(dictation: true)` rather than placed by hand.
///
/// The words join what the field already holds; partial results replace each
/// other as they are heard, so the text grows while the user speaks. Listening
/// is in the app's language and ends at a pause or a second tap.
class DictationButton extends StatefulWidget {
  const DictationButton({super.key, required this.controller, this.onChanged});

  final TextEditingController controller;

  /// Called with the field's text after each change dictation makes — a
  /// programmatic change does not reach the field's own `onChanged`.
  final ValueChanged<String>? onChanged;

  @override
  State<DictationButton> createState() => _DictationButtonState();
}

class _DictationButtonState extends State<DictationButton> {
  StreamSubscription<SpeechEvent>? _session;
  bool _preparing = false;

  bool get _listening => _session != null;

  @override
  void dispose() {
    if (_listening) unawaited(getIt<SpeechInput>().stop());
    unawaited(_session?.cancel());
    super.dispose();
  }

  Future<void> _toggle() async {
    final input = getIt<SpeechInput>();
    if (_listening) return input.stop();
    if (_preparing) return;
    setState(() => _preparing = true);
    final readiness = await ensureKitReady(
      input.availability,
      getIt<PermissionsService>(),
    );
    if (!mounted) return;
    setState(() => _preparing = false);
    if (readiness != KitReadiness.ready) {
      return showKitReadiness(
        context,
        readiness,
        deniedKey: LocaleKeys.voiceMicDenied,
        blockedKey: LocaleKeys.voiceMicBlocked,
        unsupportedKey: LocaleKeys.voiceUnsupported,
      );
    }

    final base = widget.controller.text.trimRight();
    _session = input
        .listen(languageCode: context.locale.languageCode)
        .listen(
          (event) => switch (event) {
            SpeechHeard(:final text) => _write(base, text),
            SpeechFailed(:final reason) => _fail(reason),
          },
          onDone: () {
            if (mounted) setState(() => _session = null);
          },
        );
    setState(() {});
  }

  void _write(String base, String heard) {
    final text = [base, heard.trim()].where((s) => s.isNotEmpty).join(' ');
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onChanged?.call(text);
  }

  void _fail(SpeechFailure reason) {
    if (!mounted) return;
    context.feedback.warning(
      switch (reason) {
        SpeechFailure.noMatch => LocaleKeys.voiceNoMatch,
        SpeechFailure.network => LocaleKeys.voiceNetwork,
        SpeechFailure.busy => LocaleKeys.voiceBusy,
        SpeechFailure.language => LocaleKeys.voiceLanguage,
        SpeechFailure.unknown => LocaleKeys.voiceFailed,
      }.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<SpeechInput>()) return const SizedBox.shrink();
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    return IconButton(
      tooltip:
          (_listening ? LocaleKeys.voiceStopListening : LocaleKeys.voiceDictate)
              .tr(),
      onPressed: _preparing ? null : _toggle,
      icon: AnimatedSwitcher(
        duration: AppMotion.of(context).fast,
        child: Icon(
          _listening ? Icons.mic : Icons.mic_none_rounded,
          key: ValueKey(_listening),
          color: _listening ? colors.primary : colors.textMuted,
        ),
      ),
    );
  }
}
