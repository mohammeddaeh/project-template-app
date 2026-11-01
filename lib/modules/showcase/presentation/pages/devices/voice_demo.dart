import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/modules/showcase/presentation/pages/devices/kit_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `kit_voice` — dictation into a field and reading text aloud, on the
/// device's own engines.
class VoiceDemo extends StatefulWidget {
  const VoiceDemo({super.key});

  @override
  State<VoiceDemo> createState() => _VoiceDemoState();
}

class _VoiceDemoState extends State<VoiceDemo> {
  final _field = TextEditingController();
  final _heard = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    _heard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitNotice(kit: 'voice', installed: getIt.isRegistered<SpeechInput>()),
        DemoPlayground(
          call: 'CustomTextField',
          knobs: const [
            BoolKnob('dictation', initial: true),
            NumberKnob(
              'maxLines',
              initial: 3,
              min: 1,
              max: 6,
              integer: true,
              apiDefault: 1,
            ),
          ],
          trailingCode: const ['controller: _controller'],
          builder: (context, k) => CustomTextField(
            controller: _field,
            dictation: k('dictation'),
            maxLines: k<double>('maxLines').round(),
            labelText: LocaleKeys.showcaseVoiceFieldLabel.tr(),
          ),
        ),
        // The button alone — for a field that is not a CustomTextField, or a
        // search bar that only shows what was heard.
        DemoBlock(
          code: 'DictationButton(controller: _controller)',
          child: Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _heard,
                  builder: (context, value, _) => Text(
                    value.text.isEmpty
                        ? LocaleKeys.showcaseVoiceFieldLabel.tr()
                        : value.text,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: value.text.isEmpty
                          ? context.colors.textMuted
                          : context.colors.textPrimary,
                    ),
                  ),
                ),
              ),
              DictationButton(controller: _heard),
            ],
          ),
        ),
        DemoPlayground(
          call: 'SpeakButton',
          knobs: [
            TextKnob(
              'text',
              initial: LocaleKeys.showcaseVoiceSample.tr(),
              required: true,
            ),
            ChoiceKnob<String?>('languageCode', const {
              'null': null,
              "'ar'": 'ar',
              "'en'": 'en',
            }, apiDefaultCode: 'null'),
          ],
          builder: (context, k) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: SpeakButton(
              text: k('text'),
              languageCode: k('languageCode'),
            ),
          ),
        ),
      ],
    );
  }
}
