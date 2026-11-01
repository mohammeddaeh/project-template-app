import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/foundation/formatting/app_formats.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/devices/kit_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `kit_audio` — a voice note recorded, played back, and opened the way any
/// attachment is.
class AudioDemo extends StatefulWidget {
  const AudioDemo({super.key});

  @override
  State<AudioDemo> createState() => _AudioDemoState();
}

class _AudioDemoState extends State<AudioDemo> {
  Recording? _last;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final last = _last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitNotice(kit: 'audio', installed: getIt.isRegistered<AudioRecorder>()),
        DemoBlock(
          code:
              'VoiceNoteRecorder(\n'
              '  onRecorded: (r) => ingest(File(r.path)),\n'
              ')',
          child: VoiceNoteRecorder(
            onRecorded: (r) => setState(() => _last = r),
          ),
        ),
        DemoBlock(
          code: 'AudioPlayerTile(source: recording.path)',
          child: last == null
              ? Text(
                  LocaleKeys.showcaseAudioNone.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textMuted,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.showcaseAudioRecorded.tr(
                        args: [
                          AppNumberFormats.elapsed.apply(
                            last.duration.inSeconds,
                          ),
                        ],
                      ),
                      style: context.textTheme.bodySmall,
                    ),
                    AudioPlayerTile(source: last.path),
                  ],
                ),
        ),
        if (last != null)
          DemoBlock(
            code:
                'AttachmentPreview.open(context, photo: CapturedPhoto(\n'
                '  localPath: path,\n'
                '  mimeType: Recording.mimeType,\n'
                '))',
            child: AppButton(
              text: LocaleKeys.showcaseAudioOpenAttachment.tr(),
              variant: AppButtonVariant.outlined,
              leadingIcon: Icons.attach_file,
              onTap: () => AttachmentPreview.open(
                context,
                photo: CapturedPhoto(
                  localPath: last.path,
                  mimeType: Recording.mimeType,
                  label: 'voice_note.m4a',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
